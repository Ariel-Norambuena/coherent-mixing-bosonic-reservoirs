param(
    [int[]]$TaskIndices = (1..120),
    [int]$MaxParallel = 12
)

$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$matlab = (Get-Command matlab).Source
$logDir = Join-Path $PSScriptRoot 'minimal_stage_a_logs_20260811'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
if ($MaxParallel -lt 1) { throw 'MaxParallel must be positive.' }

$pending = [System.Collections.Generic.Queue[int]]::new()
foreach ($id in $TaskIndices) {
    if ($id -lt 1 -or $id -gt 120) { throw "Task outside stage-A plan: $id" }
    $pending.Enqueue($id)
}
$running = @(); $completed = @()
while ($pending.Count -gt 0 -or $running.Count -gt 0) {
    while ($pending.Count -gt 0 -and $running.Count -lt $MaxParallel) {
        $id = $pending.Dequeue()
        $outLog = Join-Path $logDir ("task{0:D3}.out.log" -f $id)
        $errLog = Join-Path $logDir ("task{0:D3}.err.log" -f $id)
        if ((Test-Path -LiteralPath $outLog) -or (Test-Path -LiteralPath $errLog)) {
            throw "Collision guard for stage-A task $id."
        }
        $batch = "MINIMAL_STAGE_A_TASK_INDEX=$id; run(fullfile(pwd,'Figure 3','run_minimal_architecture_selection_stage_a_task_20260811.m'));"
        $p = Start-Process -FilePath $matlab -ArgumentList "-singleCompThread -batch `"$batch`"" `
            -WorkingDirectory $workspace -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput $outLog -RedirectStandardError $errLog
        $running += [pscustomobject]@{Id=$id;Process=$p;Start=Get-Date;Out=$outLog;Err=$errLog}
        Start-Sleep -Milliseconds 200
    }
    Start-Sleep -Seconds 2
    $next = @()
    foreach ($r in $running) {
        if ($r.Process.HasExited) {
            $r.Process.WaitForExit(); $r.Process.Refresh()
            $code = $r.Process.ExitCode
            if ($null -eq $code) {
                $last = Get-Content -LiteralPath $r.Out -Tail 1
                $code = [int](-not ($last -match 'PASS'))
            }
            $completed += [pscustomobject]@{TaskIndex=$r.Id;ExitCode=$code;ElapsedMinutes=[math]::Round(((Get-Date)-$r.Start).TotalMinutes,2);OutLog=$r.Out;ErrLog=$r.Err}
        } else { $next += $r }
    }
    $running = $next
}
$completed | Sort-Object TaskIndex | Export-Csv -LiteralPath (Join-Path $logDir 'parallel_run_summary_20260811.csv') -NoTypeInformation -Encoding utf8
$failed = @($completed | Where-Object {$_.ExitCode -ne 0})
if ($failed.Count) { throw "Stage-A failures: $($failed.TaskIndex -join ', ')" }
Write-Output "MINIMAL_STAGE_A_PARALLEL_PASS tasks=$($completed.Count)"

