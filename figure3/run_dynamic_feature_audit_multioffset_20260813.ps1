$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$jobs = @()

for ($taskIndex = 1; $taskIndex -le 20; $taskIndex++) {
    $command = "DYNAMIC_FEATURE_TASK_INDEX=$taskIndex; run('$(($scriptDir -replace '\\','/'))/run_dynamic_feature_audit_offset_20260813.m')"
    $jobs += Start-Job -ScriptBlock { param($cmd) matlab -batch $cmd } -ArgumentList $command
}

Wait-Job -Job $jobs | Out-Null
$failed = $false
foreach ($job in $jobs) {
    Receive-Job -Job $job
    if ($job.State -ne 'Completed') { $failed = $true }
}
Remove-Job -Job $jobs
if ($failed) { throw 'At least one dynamic-feature audit job failed.' }

matlab -batch "run('$(($scriptDir -replace '\\','/'))/analyze_dynamic_photon_kerr_multioffset_20260813.m')"
