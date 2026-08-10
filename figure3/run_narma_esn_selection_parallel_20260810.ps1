param(
    [int[]]$SelectionIndices = (1..10),
    [int]$MaxParallel = 10
)

$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$matlab = (Get-Command matlab).Source
$logDir = Join-Path $PSScriptRoot 'esn_selection_logs_20260810'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$pending = [System.Collections.Generic.Queue[int]]::new()
foreach ($id in $SelectionIndices) {
    if ($id -lt 1 -or $id -gt 10) { throw "Invalid selection index $id." }
    $pending.Enqueue($id)
}
$running = @()
$completed = @()
while ($pending.Count -gt 0 -or $running.Count -gt 0) {
    while ($pending.Count -gt 0 -and $running.Count -lt $MaxParallel) {
        $id = $pending.Dequeue()
        $outLog = Join-Path $logDir ("esn_selection_index{0:D2}.out.log" -f $id)
        $errLog = Join-Path $logDir ("esn_selection_index{0:D2}.err.log" -f $id)
        if ((Test-Path $outLog) -or (Test-Path $errLog)) {
            throw "Collision guard: ESN log exists for index $id."
        }
        $batch = "KERR_ESN_SELECTION_INDEX=$id; run(fullfile(pwd,'Figure 3','run_narma_esn_selection_seed_20260810.m'));"
        $process = Start-Process -FilePath $matlab `
            -ArgumentList "-singleCompThread -batch `"$batch`"" `
            -WorkingDirectory $workspace -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput $outLog -RedirectStandardError $errLog
        $running += [pscustomobject]@{Id=$id;Process=$process;OutLog=$outLog;ErrLog=$errLog;StartTime=Get-Date}
        Write-Output "Started ESN selection index $id as PID $($process.Id)."
    }
    Start-Sleep -Seconds 3
    $stillRunning = @()
    foreach ($record in $running) {
        if ($record.Process.HasExited) {
            $record.Process.WaitForExit(); $record.Process.Refresh()
            $exitCode = $record.Process.ExitCode
            if ($null -eq $exitCode) {
                $ok = (Get-Item $record.ErrLog).Length -eq 0 -and `
                    (Get-Content $record.OutLog -Tail 1) -match 'PASS'
                $exitCode = [int](-not $ok)
            }
            $elapsed = ((Get-Date)-$record.StartTime).TotalMinutes
            $completed += [pscustomobject]@{SelectionIndex=$record.Id;ExitCode=$exitCode;ElapsedMinutes=[math]::Round($elapsed,2)}
            Write-Output "Finished ESN selection index $($record.Id) with exit code $exitCode."
        } else { $stillRunning += $record }
    }
    $running = $stillRunning
}
$summaryFile = Join-Path $logDir 'parallel_run_summary_20260810.csv'
$completed | Sort-Object SelectionIndex | Export-Csv $summaryFile -NoTypeInformation -Encoding utf8
$failed = @($completed | Where-Object {$_.ExitCode -ne 0})
if ($failed.Count) { throw "ESN selection failed: $($failed.SelectionIndex -join ', ')." }
Write-Output "ESN selection parallel run PASS for $($completed.Count) seeds."
