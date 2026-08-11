param([int]$MaxWorkers = 10)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$jobs = @()

for ($task = 1; $task -le 20; $task++) {
    while (($jobs | Where-Object State -eq 'Running').Count -ge $MaxWorkers) {
        $done = Wait-Job -Job $jobs -Any
        Receive-Job -Job $done
        Remove-Job -Job $done
        $jobs = @($jobs | Where-Object Id -ne $done.Id)
    }
    $command = "EQUAL_FREQUENCY_TASK_INDEX=$task; run('$(($scriptDir -replace '\\','/'))/run_equal_frequency_control_task_20260812.m')"
    $jobs += Start-Job -ScriptBlock { param($cmd) matlab -batch $cmd } -ArgumentList $command
}

if ($jobs.Count -gt 0) {
    Wait-Job -Job $jobs | Out-Null
    Receive-Job -Job $jobs
    Remove-Job -Job $jobs
}

matlab -batch "run('$(($scriptDir -replace '\\','/'))/analyze_equal_frequency_control_20260812.m')"
