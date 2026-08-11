param(
    [int[]]$TaskIndices = (1..20),
    [int]$MaxParallel = 10
)

$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$matlab = (Get-Command matlab).Source
$logDir = Join-Path $PSScriptRoot 'phase_selection_logs_20260811'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$pending = [System.Collections.Generic.Queue[int]]::new()
foreach ($id in $TaskIndices) {
    if ($id -lt 1 -or $id -gt 20) { throw "Bad task $id" }
    $pending.Enqueue($id)
}
$running = @()
$done = @()
while ($pending.Count -gt 0 -or $running.Count -gt 0) {
    while ($pending.Count -gt 0 -and $running.Count -lt $MaxParallel) {
        $id = $pending.Dequeue()
        $out = Join-Path $logDir ("task{0:D2}.out.log" -f $id)
        $err = Join-Path $logDir ("task{0:D2}.err.log" -f $id)
        if ((Test-Path $out) -or (Test-Path $err)) { throw "Collision $id" }
        $batch = "PHASE_SELECTION_TASK_INDEX=$id; run(fullfile(pwd,'Figure 3','run_phase_channel_selection_task_20260811.m'));"
        $p = Start-Process -FilePath $matlab `
            -ArgumentList "-singleCompThread -batch `"$batch`"" `
            -WorkingDirectory $workspace -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput $out -RedirectStandardError $err
        $running += [pscustomobject]@{Id=$id;Process=$p;Start=Get-Date;Out=$out;Err=$err}
        Start-Sleep -Milliseconds 200
    }
    Start-Sleep -Seconds 2
    $next = @()
    foreach ($r in $running) {
        if ($r.Process.HasExited) {
            $r.Process.WaitForExit(); $r.Process.Refresh()
            $code = $r.Process.ExitCode
            if ($null -eq $code) {
                $code = [int](-not ((Get-Content $r.Out -Tail 1) -match 'PASS'))
            }
            $done += [pscustomobject]@{TaskIndex=$r.Id;ExitCode=$code;ElapsedMinutes=[math]::Round(((Get-Date)-$r.Start).TotalMinutes,2);OutLog=$r.Out;ErrLog=$r.Err}
        } else { $next += $r }
    }
    $running = $next
}
$done | Sort-Object TaskIndex | Export-Csv (Join-Path $logDir 'parallel_run_summary_20260811.csv') -NoTypeInformation -Encoding utf8
$failed = @($done | Where-Object {$_.ExitCode -ne 0})
if ($failed.Count) { throw "Failures: $($failed.TaskIndex -join ', ')" }
Write-Output "PHASE_SELECTION_PARALLEL_PASS tasks=$($done.Count)"

