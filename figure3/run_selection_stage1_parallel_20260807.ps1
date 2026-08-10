param(
    [int[]]$SelectionIndices = (2..10),
    [int]$MaxParallel = 9
)

$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$matlab = (Get-Command matlab).Source
$logDir = Join-Path $PSScriptRoot 'selection_logs_20260807'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

if ($MaxParallel -lt 1) {
    throw 'MaxParallel must be positive.'
}

$pending = [System.Collections.Generic.Queue[int]]::new()
foreach ($index in $SelectionIndices) {
    if ($index -lt 1 -or $index -gt 10) {
        throw "Selection index outside frozen bank: $index"
    }
    $pending.Enqueue($index)
}

$running = @()
$completed = @()

while ($pending.Count -gt 0 -or $running.Count -gt 0) {
    while ($pending.Count -gt 0 -and $running.Count -lt $MaxParallel) {
        $index = $pending.Dequeue()
        $outLog = Join-Path $logDir ("selection_stage1_index{0:D2}.out.log" -f $index)
        $errLog = Join-Path $logDir ("selection_stage1_index{0:D2}.err.log" -f $index)
        if ((Test-Path -LiteralPath $outLog) -or (Test-Path -LiteralPath $errLog)) {
            throw "Collision guard: log already exists for selection index $index."
        }

        $batch = "KERR_NARMA_SELECTION_INDEX=$index; run(fullfile(pwd,'Figure 3','run_narma_selection_stage1_20260807.m'));"
        $arguments = "-singleCompThread -batch `"$batch`""
        $process = Start-Process -FilePath $matlab -ArgumentList $arguments `
            -WorkingDirectory $workspace -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput $outLog -RedirectStandardError $errLog
        $running += [pscustomobject]@{
            Index = $index
            Process = $process
            OutLog = $outLog
            ErrLog = $errLog
            StartTime = Get-Date
        }
        Write-Output "Started selection index $index as PID $($process.Id)."
        Start-Sleep -Milliseconds 500
    }

    Start-Sleep -Seconds 5
    $stillRunning = @()
    foreach ($record in $running) {
        if ($record.Process.HasExited) {
            $record.Process.WaitForExit()
            $record.Process.Refresh()
            $exitCode = $record.Process.ExitCode
            if ($null -eq $exitCode) {
                $errorBytes = (Get-Item -LiteralPath $record.ErrLog).Length
                $lastLine = Get-Content -LiteralPath $record.OutLog -Tail 1
                if ($errorBytes -eq 0 -and $lastLine -match 'PASS') {
                    $exitCode = 0
                }
                else {
                    $exitCode = 1
                }
            }
            $elapsed = (Get-Date) - $record.StartTime
            $completed += [pscustomobject]@{
                Index = $record.Index
                ExitCode = $exitCode
                ElapsedMinutes = [math]::Round($elapsed.TotalMinutes, 2)
                OutLog = $record.OutLog
                ErrLog = $record.ErrLog
            }
            Write-Output "Finished selection index $($record.Index) with exit code $exitCode."
        }
        else {
            $stillRunning += $record
        }
    }
    $running = $stillRunning
}

$summaryFile = Join-Path $logDir 'parallel_run_summary_20260807.csv'
$completed | Sort-Object Index | Export-Csv -LiteralPath $summaryFile -NoTypeInformation -Encoding utf8
$failed = @($completed | Where-Object { $_.ExitCode -ne 0 })
if ($failed.Count -gt 0) {
    $failedIndices = ($failed.Index -join ', ')
    throw "Selection stage-1 parallel run failed for indices: $failedIndices"
}

Write-Output "Selection stage-1 parallel run PASS for $($completed.Count) indices."
Write-Output "Summary: $summaryFile"
