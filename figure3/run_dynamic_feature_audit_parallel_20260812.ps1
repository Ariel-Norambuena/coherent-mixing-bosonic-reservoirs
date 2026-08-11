$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$jobs = @()
for ($task = 1; $task -le 2; $task++) {
    $command = "DYNAMIC_FEATURE_TASK_INDEX=$task; run('$(($scriptDir -replace '\\','/'))/run_dynamic_feature_audit_task_20260812.m')"
    $jobs += Start-Job -ScriptBlock { param($cmd) matlab -batch $cmd } -ArgumentList $command
}
Wait-Job -Job $jobs | Out-Null
Receive-Job -Job $jobs
Remove-Job -Job $jobs
matlab -batch "run('$(($scriptDir -replace '\\','/'))/analyze_dynamic_photon_kerr_thermal_20260812.m')"
