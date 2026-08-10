$ErrorActionPreference='Stop'
$workspace=Split-Path -Parent $PSScriptRoot;$matlab=(Get-Command matlab).Source
$logDir=Join-Path $PSScriptRoot 'revision_verification_logs_20260810';New-Item -ItemType Directory -Force -Path $logDir|Out-Null
$tasks=@(
  @{Name='convergence1';Batch="KERR_CONVERGENCE_TASK_INDEX=1;run(fullfile(pwd,'Figure 3','run_narma_solver_convergence_task_20260810.m'));"},
  @{Name='convergence2';Batch="KERR_CONVERGENCE_TASK_INDEX=2;run(fullfile(pwd,'Figure 3','run_narma_solver_convergence_task_20260810.m'));"},
  @{Name='convergence3';Batch="KERR_CONVERGENCE_TASK_INDEX=3;run(fullfile(pwd,'Figure 3','run_narma_solver_convergence_task_20260810.m'));"},
  @{Name='convergence4';Batch="KERR_CONVERGENCE_TASK_INDEX=4;run(fullfile(pwd,'Figure 3','run_narma_solver_convergence_task_20260810.m'));"},
  @{Name='determinism1';Batch="KERR_DETERMINISM_REPLICATE=1;run(fullfile(pwd,'Figure 3','run_narma_determinism_task_20260810.m'));"},
  @{Name='determinism2';Batch="KERR_DETERMINISM_REPLICATE=2;run(fullfile(pwd,'Figure 3','run_narma_determinism_task_20260810.m'));"}
)
$running=@();foreach($t in $tasks){$out=Join-Path $logDir "$($t.Name).out.log";$err=Join-Path $logDir "$($t.Name).err.log";if((Test-Path $out)-or(Test-Path $err)){throw "Collision guard: $($t.Name)"};$p=Start-Process $matlab -ArgumentList "-singleCompThread -batch `"$($t.Batch)`"" -WorkingDirectory $workspace -WindowStyle Hidden -PassThru -RedirectStandardOutput $out -RedirectStandardError $err;$running+=[pscustomobject]@{Name=$t.Name;Process=$p;Out=$out;Err=$err}}
$failed=@();foreach($r in $running){$r.Process.WaitForExit();$r.Process.Refresh();if($r.Process.ExitCode-ne0){$failed+=$r.Name}}
if($failed.Count){throw "Verification tasks failed: $($failed -join ', ')"};Write-Output 'REVISION_VERIFICATION_PARALLEL_PASS'

