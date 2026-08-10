%% Finalize a complete locked output whose post-run manifest is absent.

clearvars -except KERR_NARMA_LOCKED_INDEX;
clc;
assert(exist('KERR_NARMA_LOCKED_INDEX','var') == 1);
lockedIndex = KERR_NARMA_LOCKED_INDEX;
scriptDir = fileparts(mfilename('fullpath'));
lockedFile = fullfile(scriptDir,'configs','narma_locked_config_20260810.json');
comparisonFile = fullfile(scriptDir,'configs', ...
    'narma_locked_comparison_config_20260810.json');
locked = jsondecode(fileread(lockedFile));
assert(isscalar(lockedIndex) && lockedIndex == floor(lockedIndex) && ...
    lockedIndex >= 1 && lockedIndex <= locked.paired_realizations);
seedOffset = locked.locked_test_offsets(lockedIndex);
prefix = fullfile(scriptDir,sprintf([ ...
    'Fig3_KerrReservoir_NARMA10_Reproducible_' ...
    'LockedTest_Index%02d_Offset%04d_20260810'],lockedIndex,seedOffset));
summaryFile = [prefix '_summary.mat'];
featureFile = [prefix '_FeatureAblations_summary.csv'];
budgetFile = [prefix '_FeatureBudgetVariants_summary.csv'];
manifestFile = [prefix '_manifest.json'];
assert(isfile(summaryFile) && isfile(featureFile) && isfile(budgetFile));
assert(~isfile(manifestFile),'Manifest already exists; refusing overwrite.');
S = load(summaryFile,'cfg','P','datasetSeed');
C = readtable(featureFile,'TextType','string','Delimiter',',');
B = readtable(budgetFile,'TextType','string','Delimiter',',');
assert(strcmp(S.cfg.protocolMode,'locked') && S.cfg.evaluateTest && ...
    S.cfg.seedOffset == seedOffset && height(C) == 4 && height(B) == 28);
assert(all(isfinite(C.testNRMSE)) && all(isfinite(B.testNRMSE)) && ...
    all(isfinite(B.R2true)));
expectedLambda = reshape(permute(S.cfg.featureBudgetLambdaMap,[3 2 1]),[],1);
lambdaError = max(abs(B.lambdaBest-expectedLambda));
assert(lambdaError <= 1e-12*max(1,max(abs(expectedLambda))));
manifest.schema_version = 1;
manifest.status = 'locked_pair_complete';
manifest.locked_index = lockedIndex;
manifest.seed_offset = seedOffset;
manifest.dataset_seed = S.datasetSeed;
manifest.locked_config_sha256 = sha256File(lockedFile);
manifest.comparison_config_sha256 = sha256File(comparisonFile);
manifest.summary_sha256 = sha256File(summaryFile);
manifest.feature_csv_sha256 = sha256File(featureFile);
manifest.feature_budget_csv_sha256 = sha256File(budgetFile);
manifest.completed_date = char(datetime('now','Format','yyyy-MM-dd''T''HH:mm:ssXXX'));
manifest.recovered_postrun_audit = true;
manifest.recovery_reason = ...
    'original absolute lambda tolerance was stricter than CSV roundoff';
fid = fopen(manifestFile,'w');assert(fid >= 0);
fprintf(fid,'%s\n',jsonencode(manifest,PrettyPrint=true));fclose(fid);
fprintf('LOCKED_MANIFEST_RECOVERY_PASS index=%d lambda_error=%.3e\n', ...
    lockedIndex,lambdaError);

function digest = sha256File(path)
    engine=java.security.MessageDigest.getInstance('SHA-256');
    fid=fopen(path,'rb');assert(fid>=0);cleanup=onCleanup(@() fclose(fid));
    data=fread(fid,Inf,'*uint8');bytes=typecast(engine.digest(data),'uint8');
    digest=lower(reshape(dec2hex(bytes,2).',1,[]));
end
