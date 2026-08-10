param(
    [int[]]$TaskIndices = (1..80),
    [int]$MaxParallel = 8
)

$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$matlab = (Get-Command matlab).Source
$logDir = Join-Path $PSScriptRoot 'mechanism_ablation_logs_20260810'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
if ($MaxParallel -lt 1) { throw 'MaxParallel must be positive.' }

$pending = [System.Collections.Generic.Queue[int]]::new()
foreach ($id in $TaskIndices) {
    if ($id -lt 1 -or $id -gt 80) { throw "Mechanism task outside plan: $id" }
    $pending.Enqueue($id)
}

$running = @()
$completed = @()
while ($pending.Count -gt 0 -or $running.Count -gt 0) {
    while ($pending.Count -gt 0 -and $running.Count -lt $MaxParallel) {
        $id = $pending.Dequeue()
        $outLog = Join-Path $logDir ("task{0:D2}.out.log" -f $id)
        $errLog = Join-Path $logDir ("task{0:D2}.err.log" -f $id)
        if ((Test-Path -LiteralPath $outLog) -or (Test-Path -LiteralPath $errLog)) {
            throw "Collision guard: log already exists for mechanism task $id."
        }
        $batch = "KERR_MECHANISM_TASK_INDEX=$id; run(fullfile(pwd,'Figure 3','run_narma_mechanism_ablation_task_20260810.m'));"
        $arguments = "-singleCompThread -batch `"$batch`""
        $process = Start-Process -FilePath $matlab -ArgumentList $arguments `
            -WorkingDirectory $workspace -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput $outLog -RedirectStandardError $errLog
        $running += [pscustomobject]@{ Id=$id; Process=$process; OutLog=$outLog; ErrLog=$errLog; StartTime=Get-Date }
        Write-Output "Started mechanism task $id as PID $($process.Id)."
        Start-Sleep -Milliseconds 250
    }
    Start-Sleep -Seconds 3
    $stillRunning = @()
    foreach ($record in $running) {
        if ($record.Process.HasExited) {
            $record.Process.WaitForExit(); $record.Process.Refresh()
            $exitCode = $record.Process.ExitCode
            if ($null -eq $exitCode) {
                $errorBytes = (Get-Item -LiteralPath $record.ErrLog).Length
                $lastLine = Get-Content -LiteralPath $record.OutLog -Tail 1
                $exitCode = [int](-not ($errorBytes -eq 0 -and $lastLine -match 'PASS'))
            }
            $completed += [pscustomobject]@{ TaskIndex=$record.Id; ExitCode=$exitCode; ElapsedMinutes=[math]::Round(((Get-Date)-$record.StartTime).TotalMinutes,2); OutLog=$record.OutLog; ErrLog=$record.ErrLog }
            Write-Output "Finished mechanism task $($record.Id) with exit code $exitCode."
        } else { $stillRunning += $record }
    }
    $running = $stillRunning
}

$summaryFile = Join-Path $logDir 'parallel_run_summary_20260810.csv'
$completed | Sort-Object TaskIndex | Export-Csv -LiteralPath $summaryFile -NoTypeInformation -Encoding utf8
$failed = @($completed | Where-Object { $_.ExitCode -ne 0 })
if ($failed.Count -gt 0) { throw "Mechanism tasks failed: $($failed.TaskIndex -join ', ')" }
Write-Output "Mechanism ablation parallel PASS for $($completed.Count) tasks."

