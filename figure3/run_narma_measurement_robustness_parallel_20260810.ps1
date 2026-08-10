param([int[]]$SeedIndices=(1..10),[int]$MaxParallel=5)
$ErrorActionPreference='Stop'
$workspace=Split-Path -Parent $PSScriptRoot
$matlab=(Get-Command matlab).Source
$logDir=Join-Path $PSScriptRoot 'measurement_robustness_logs_20260810'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$pending=[System.Collections.Generic.Queue[int]]::new()
foreach($id in $SeedIndices){if($id-lt1-or$id-gt10){throw "Seed outside plan: $id"};$pending.Enqueue($id)}
$running=@();$completed=@()
while($pending.Count-gt0-or$running.Count-gt0){
  while($pending.Count-gt0-and$running.Count-lt$MaxParallel){
    $id=$pending.Dequeue();$out=Join-Path $logDir ("seed{0:D2}.out.log"-f$id);$err=Join-Path $logDir ("seed{0:D2}.err.log"-f$id)
    if((Test-Path $out)-or(Test-Path $err)){throw "Collision guard for seed $id"}
    $batch="KERR_ROBUSTNESS_SEED_INDEX=$id; run(fullfile(pwd,'Figure 3','run_narma_measurement_robustness_seed_20260810.m'));"
    $p=Start-Process -FilePath $matlab -ArgumentList "-singleCompThread -batch `"$batch`"" -WorkingDirectory $workspace -WindowStyle Hidden -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
    $running+= [pscustomobject]@{Id=$id;Process=$p;Out=$out;Err=$err;Start=Get-Date};Write-Output "Started robustness seed $id as PID $($p.Id)."
  }
  Start-Sleep -Seconds 3;$still=@()
  foreach($r in $running){if($r.Process.HasExited){$r.Process.WaitForExit();$r.Process.Refresh();$code=$r.Process.ExitCode;if($null-eq$code){$last=Get-Content $r.Out -Tail 1;$code=[int](-not((Get-Item $r.Err).Length-eq0-and$last-match'PASS'))};$completed+=[pscustomobject]@{SeedIndex=$r.Id;ExitCode=$code;ElapsedMinutes=[math]::Round(((Get-Date)-$r.Start).TotalMinutes,2)};Write-Output "Finished robustness seed $($r.Id) with exit code $code."}else{$still+=$r}};$running=$still
}
$completed|Sort-Object SeedIndex|Export-Csv (Join-Path $logDir 'parallel_run_summary_20260810.csv') -NoTypeInformation
$failed=@($completed|Where-Object{$_.ExitCode-ne0});if($failed.Count){throw "Robustness failures: $($failed.SeedIndex -join ', ')"}
Write-Output "Measurement robustness parallel PASS for $($completed.Count) seeds."

