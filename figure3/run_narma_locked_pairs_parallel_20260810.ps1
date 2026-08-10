param(
    [int[]]$LockedIndices = (1..30),
    [int]$MaxParallel = 12
)

$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$matlab = (Get-Command matlab).Source
$logDir = Join-Path $PSScriptRoot 'locked_test_logs_20260810'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

if ($MaxParallel -lt 1) {
    throw 'MaxParallel must be positive.'
}

$pending = [System.Collections.Generic.Queue[int]]::new()
foreach ($id in $LockedIndices) {
    if ($id -lt 1 -or $id -gt 30) {
        throw "Locked index outside frozen plan: $id"
    }
    $pending.Enqueue($id)
}

$running = @()
$completed = @()
while ($pending.Count -gt 0 -or $running.Count -gt 0) {
    while ($pending.Count -gt 0 -and $running.Count -lt $MaxParallel) {
        $id = $pending.Dequeue()
        $outLog = Join-Path $logDir ("locked_index{0:D2}.out.log" -f $id)
        $errLog = Join-Path $logDir ("locked_index{0:D2}.err.log" -f $id)
        if ((Test-Path -LiteralPath $outLog) -or (Test-Path -LiteralPath $errLog)) {
            throw "Collision guard: log already exists for locked index $id."
        }
        $batch = "KERR_NARMA_LOCKED_INDEX=$id; run(fullfile(pwd,'Figure 3','run_narma_locked_pair_20260810.m'));"
        $arguments = "-singleCompThread -batch `"$batch`""
        $process = Start-Process -FilePath $matlab -ArgumentList $arguments `
            -WorkingDirectory $workspace -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput $outLog -RedirectStandardError $errLog
        $running += [pscustomobject]@{
            Id = $id
            Process = $process
            OutLog = $outLog
            ErrLog = $errLog
            StartTime = Get-Date
        }
        Write-Output "Started locked index $id as PID $($process.Id)."
        Start-Sleep -Milliseconds 300
    }

    Start-Sleep -Seconds 3
    $stillRunning = @()
    foreach ($record in $running) {
        if ($record.Process.HasExited) {
            $record.Process.WaitForExit()
            $record.Process.Refresh()
            $exitCode = $record.Process.ExitCode
            if ($null -eq $exitCode) {
                $errorBytes = (Get-Item -LiteralPath $record.ErrLog).Length
                $lastLine = Get-Content -LiteralPath $record.OutLog -Tail 1
                $exitCode = [int](-not ($errorBytes -eq 0 -and $lastLine -match 'PASS'))
            }
            $elapsed = (Get-Date) - $record.StartTime
            $completed += [pscustomobject]@{
                LockedIndex = $record.Id
                ExitCode = $exitCode
                ElapsedMinutes = [math]::Round($elapsed.TotalMinutes, 2)
                OutLog = $record.OutLog
                ErrLog = $record.ErrLog
            }
            Write-Output "Finished locked index $($record.Id) with exit code $exitCode."
        }
        else {
            $stillRunning += $record
        }
    }
    $running = $stillRunning
}

$summaryFile = Join-Path $logDir 'parallel_run_summary_20260810.csv'
$completed | Sort-Object LockedIndex | Export-Csv -LiteralPath $summaryFile `
    -NoTypeInformation -Encoding utf8
$failed = @($completed | Where-Object { $_.ExitCode -ne 0 })
if ($failed.Count -gt 0) {
    throw "Locked pairs failed: $($failed.LockedIndex -join ', ')"
}
Write-Output "Locked-pair parallel run PASS for $($completed.Count) pairs."
Write-Output "Summary: $summaryFile"
