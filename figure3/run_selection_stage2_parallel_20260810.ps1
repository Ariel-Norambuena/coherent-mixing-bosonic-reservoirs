param(
    [int[]]$TrajectoryIds = (1..120),
    [int]$MaxParallel = 12
)

$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$matlab = (Get-Command matlab).Source
$logDir = Join-Path $PSScriptRoot 'selection_stage2_logs_20260810'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

if ($MaxParallel -lt 1) {
    throw 'MaxParallel must be positive.'
}

$pending = [System.Collections.Generic.Queue[int]]::new()
foreach ($id in $TrajectoryIds) {
    if ($id -lt 1 -or $id -gt 120) {
        throw "Trajectory id outside frozen stage-2 plan: $id"
    }
    $pending.Enqueue($id)
}

$running = @()
$completed = @()
while ($pending.Count -gt 0 -or $running.Count -gt 0) {
    while ($pending.Count -gt 0 -and $running.Count -lt $MaxParallel) {
        $id = $pending.Dequeue()
        $outLog = Join-Path $logDir ("stage2_trajectory{0:D3}.out.log" -f $id)
        $errLog = Join-Path $logDir ("stage2_trajectory{0:D3}.err.log" -f $id)
        if ((Test-Path -LiteralPath $outLog) -or (Test-Path -LiteralPath $errLog)) {
            throw "Collision guard: log already exists for trajectory $id."
        }
        $batch = "KERR_NARMA_STAGE2_TRAJECTORY_ID=$id; run(fullfile(pwd,'Figure 3','run_narma_selection_stage2_trajectory_20260810.m'));"
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
        Write-Output "Started stage-2 trajectory $id as PID $($process.Id)."
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
                if ($errorBytes -eq 0 -and $lastLine -match 'PASS') {
                    $exitCode = 0
                }
                else {
                    $exitCode = 1
                }
            }
            $elapsed = (Get-Date) - $record.StartTime
            $completed += [pscustomobject]@{
                TrajectoryId = $record.Id
                ExitCode = $exitCode
                ElapsedMinutes = [math]::Round($elapsed.TotalMinutes, 2)
                OutLog = $record.OutLog
                ErrLog = $record.ErrLog
            }
            Write-Output "Finished stage-2 trajectory $($record.Id) with exit code $exitCode."
        }
        else {
            $stillRunning += $record
        }
    }
    $running = $stillRunning
}

$summaryFile = Join-Path $logDir 'parallel_run_summary_20260810.csv'
$completed | Sort-Object TrajectoryId | Export-Csv -LiteralPath $summaryFile `
    -NoTypeInformation -Encoding utf8
$failed = @($completed | Where-Object { $_.ExitCode -ne 0 })
if ($failed.Count -gt 0) {
    throw "Stage-2 trajectories failed: $($failed.TrajectoryId -join ', ')"
}
Write-Output "Stage-2 parallel run PASS for $($completed.Count) trajectories."
Write-Output "Summary: $summaryFile"
