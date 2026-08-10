param([int[]]$SelectionIndices=(1..10),[int]$MaxParallel=10)
$ErrorActionPreference='Stop'
$workspace=Split-Path -Parent $PSScriptRoot
$matlab=(Get-Command matlab).Source
$logDir=Join-Path $PSScriptRoot 'baseline_budget_selection_logs_20260810'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$pending=[System.Collections.Generic.Queue[int]]::new()
foreach($id in $SelectionIndices){if($id -lt 1 -or $id -gt 10){throw "Invalid index $id"};$pending.Enqueue($id)}
$running=@();$completed=@()
while($pending.Count -gt 0 -or $running.Count -gt 0){
  while($pending.Count -gt 0 -and $running.Count -lt $MaxParallel){
    $id=$pending.Dequeue();$out=Join-Path $logDir ("budget_index{0:D2}.out.log" -f $id);$err=Join-Path $logDir ("budget_index{0:D2}.err.log" -f $id)
    if((Test-Path $out)-or(Test-Path $err)){throw "Collision guard for index $id"}
    $batch="KERR_BASELINE_BUDGET_SELECTION_INDEX=$id; run(fullfile(pwd,'Figure 3','run_narma_baseline_budget_selection_seed_20260810.m'));"
    $p=Start-Process -FilePath $matlab -ArgumentList "-singleCompThread -batch `"$batch`"" -WorkingDirectory $workspace -WindowStyle Hidden -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
    $running += [pscustomobject]@{Id=$id;Process=$p;Out=$out;Err=$err;Start=Get-Date};Write-Output "Started baseline budget index $id as PID $($p.Id)."
  }
  Start-Sleep -Seconds 3;$still=@()
  foreach($r in $running){if($r.Process.HasExited){$r.Process.WaitForExit();$r.Process.Refresh();$code=$r.Process.ExitCode;if($null -eq $code){$ok=(Get-Item $r.Err).Length -eq 0 -and (Get-Content $r.Out -Tail 1)-match 'PASS';$code=[int](-not $ok)};$completed += [pscustomobject]@{SelectionIndex=$r.Id;ExitCode=$code;ElapsedMinutes=[math]::Round(((Get-Date)-$r.Start).TotalMinutes,2)};Write-Output "Finished baseline budget index $($r.Id) with exit code $code."}else{$still += $r}}
  $running=$still
}
$summary=Join-Path $logDir 'parallel_run_summary_20260810.csv';$completed|Sort-Object SelectionIndex|Export-Csv $summary -NoTypeInformation -Encoding utf8
$failed=@($completed|Where-Object {$_.ExitCode -ne 0});if($failed.Count){throw "Baseline budget failed: $($failed.SelectionIndex -join ', ')"}
Write-Output "Baseline budget selection PASS for $($completed.Count) seeds."
