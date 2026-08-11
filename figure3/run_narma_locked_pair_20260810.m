%% Execute one prospectively frozen locked NARMA10 pair and all budget variants.

clearvars -except KERR_NARMA_LOCKED_INDEX;
clc;
scriptDir = fileparts(mfilename('fullpath'));
lockedFile = fullfile(scriptDir,'configs','narma_locked_config_20260810.json');
comparisonFile = fullfile(scriptDir,'configs', ...
    'narma_locked_comparison_config_20260810.json');
checksumFile = [lockedFile '.sha256'];
comparisonChecksumFile = [comparisonFile '.sha256'];
assert(all(isfile({lockedFile,comparisonFile,checksumFile,comparisonChecksumFile})), ...
    'Frozen architecture and comparison configurations are required.');

expectedHash = firstChecksum(checksumFile);
expectedComparisonHash = firstChecksum(comparisonChecksumFile);
actualHash = sha256File(lockedFile);
actualComparisonHash = sha256File(comparisonFile);
assert(strcmp(actualHash,expectedHash) && ...
    strcmp(actualComparisonHash,expectedComparisonHash), ...
    'Frozen configuration checksum mismatch; refusing locked-test access.');
locked = jsondecode(fileread(lockedFile));
comparison = jsondecode(fileread(comparisonFile));
assert(strcmp(locked.status,'frozen_not_executed') && ...
    strcmp(comparison.status,'frozen_not_executed'));

assert(exist('KERR_NARMA_LOCKED_INDEX','var') == 1, ...
    'Set KERR_NARMA_LOCKED_INDEX to an integer from 1 to 30.');
lockedIndex = KERR_NARMA_LOCKED_INDEX;
assert(isscalar(lockedIndex) && isfinite(lockedIndex) && ...
    lockedIndex == floor(lockedIndex) && lockedIndex >= 1 && ...
    lockedIndex <= locked.paired_realizations,'Invalid locked-pair index.');
seedOffset = locked.locked_test_offsets(lockedIndex);
outputTag = sprintf('LockedTest_Index%02d_Offset%04d_20260810', ...
    lockedIndex,seedOffset);
outputPrefix = fullfile(scriptDir, ...
    ['Fig3_KerrReservoir_NARMA10_Reproducible_' outputTag]);
assert(isempty(dir([outputPrefix '*'])), ...
    'Collision guard: locked outputs already exist for index %d.',lockedIndex);

featureModes = cellstr(string(locked.feature_modes));
caseJ = [locked.J_control locked.J_intervention];
budgets = unique([comparison.physical_models.requested_budget],'stable');
nBudgets = numel(budgets);
budgetVariants = repmat(struct('label','','tapDelays',[], ...
    'nPC',[],'lambdaGrid',[]),nBudgets,1);
lambdaMap = nan(2,numel(featureModes),nBudgets);
for b = 1:nBudgets
    budgetVariants(b).label = sprintf('Budget%d',budgets(b));
    budgetVariants(b).tapDelays = locked.tap_delays(:).';
    matchingBudget = [comparison.physical_models.requested_budget] == budgets(b);
    selectedPC = unique([comparison.physical_models(matchingBudget).n_pc]);
    assert(isscalar(selectedPC));
    budgetVariants(b).nPC = selectedPC;
    budgetVariants(b).lambdaGrid = 1;
    for q = 1:2
        for m = 1:numel(featureModes)
            modelRows = matchingBudget & ...
                abs([comparison.physical_models.J]-caseJ(q)) < 1e-14 & ...
                strcmp({comparison.physical_models.feature_mode},featureModes{m});
            assert(sum(modelRows) == 1);
            lambdaMap(q,m,b) = comparison.physical_models(modelRows).ridge_lambda;
        end
    end
end
assert(all(isfinite(lambdaMap),'all'));

KERR_NARMA_PROTOCOL_MODE = 'locked';
KERR_NARMA_LOCKED_PAIR = true;
KERR_NARMA_OUTPUT_TAG = outputTag;
KERR_NARMA_SEED_OFFSET = seedOffset;
KERR_NARMA_BASE_K = locked.K;
KERR_NARMA_BASE_J = locked.J_intervention;
KERR_NARMA_INPUT_GAIN_SCALE = locked.input_gain_scale;
KERR_NARMA_STEPS_PER_SAMPLE = locked.steps_per_sample;
KERR_NARMA_VIRTUAL_NODE_IDX = locked.virtual_node_indices(:).';
KERR_NARMA_NUM_VIRTUAL = numel(KERR_NARMA_VIRTUAL_NODE_IDX);
KERR_NARMA_TAP_DELAYS = locked.tap_delays(:).';
KERR_NARMA_NPC = locked.n_pc;
KERR_NARMA_LAMBDA_GRID = locked.ridge_lambda;
KERR_NARMA_BASE_FEATURE_MODE = char(locked.primary_feature_mode);
KERR_NARMA_FEATURE_MODES = featureModes;
KERR_NARMA_FEATURE_CASES = [locked.K,locked.J_control; ...
    locked.K,locked.J_intervention];
KERR_NARMA_FEATURE_BUDGET_VARIANTS = budgetVariants;
KERR_NARMA_FEATURE_BUDGET_LAMBDA_MAP = lambdaMap;
KERR_NARMA_RUN_FEATURE_ABLATIONS = true;
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS = true;
KERR_NARMA_SKIP_BASELINES = true;
run(fullfile(scriptDir,'Fig3_KerrReservoir_NARMA10_Reproducible.m'));

% The central script deliberately clears the caller workspace. Reconstruct
% the immutable audit context from cfg and the frozen files.
scriptDir = fileparts(mfilename('fullpath'));
lockedFile = fullfile(scriptDir,'configs','narma_locked_config_20260810.json');
comparisonFile = fullfile(scriptDir,'configs', ...
    'narma_locked_comparison_config_20260810.json');
locked = jsondecode(fileread(lockedFile));
actualHash = sha256File(lockedFile);
actualComparisonHash = sha256File(comparisonFile);
outputPrefix = cfg.outputPrefix;
seedOffset = cfg.seedOffset;
lockedIndex = find(locked.locked_test_offsets == seedOffset);
assert(isscalar(lockedIndex));

summaryFile = [outputPrefix '_summary.mat'];
featureFile = [outputPrefix '_FeatureAblations_summary.csv'];
budgetFile = [outputPrefix '_FeatureBudgetVariants_summary.csv'];
assert(isfile(summaryFile) && isfile(featureFile) && isfile(budgetFile), ...
    'Locked run did not produce every required output.');
S = load(summaryFile,'cfg','P','datasetSeed');
C = readtable(featureFile,'TextType','string','Delimiter',',');
B = readtable(budgetFile,'TextType','string','Delimiter',',');
assert(strcmp(S.cfg.protocolMode,'locked') && S.cfg.evaluateTest);
assert(S.cfg.seedOffset == seedOffset && abs(S.P.K-locked.K) < 1e-14);
assert(abs(S.P.J0-locked.J_intervention) < 1e-14);
assert(isequal(S.cfg.virtualNodeIdx(:).',locked.virtual_node_indices(:).'));
assert(isequal(S.cfg.tapDelays(:).',locked.tap_delays(:).'));
assert(S.cfg.nPC == locked.n_pc && height(C) == 4 && height(B) == 28);
assert(all(isfinite(C.testNRMSE)) && all(isfinite(B.testNRMSE)) && ...
    all(isfinite(B.R2true)));
expectedBudgetLambda = reshape(permute(S.cfg.featureBudgetLambdaMap,[3 2 1]),[],1);
lambdaError = max(abs(B.lambdaBest-expectedBudgetLambda));
assert(lambdaError <= 1e-12*max(1,max(abs(expectedBudgetLambda))));

manifest.schema_version = 1;
manifest.status = 'locked_pair_complete';
manifest.locked_index = lockedIndex;
manifest.seed_offset = seedOffset;
manifest.dataset_seed = S.datasetSeed;
manifest.locked_config_sha256 = actualHash;
manifest.comparison_config_sha256 = actualComparisonHash;
manifest.summary_sha256 = sha256File(summaryFile);
manifest.feature_csv_sha256 = sha256File(featureFile);
manifest.feature_budget_csv_sha256 = sha256File(budgetFile);
manifest.completed_date = char(datetime('now','Format','yyyy-MM-dd''T''HH:mm:ssXXX'));
manifestFile = [outputPrefix '_manifest.json'];
fid = fopen(manifestFile,'w');
assert(fid >= 0,'Could not create locked-pair manifest.');
fprintf(fid,'%s\n',jsonencode(manifest,PrettyPrint=true));fclose(fid);
fprintf('LOCKED_PAIR_PASS index=%d offset=%d architecture=%s comparison=%s\n', ...
    lockedIndex,seedOffset,actualHash,actualComparisonHash);

function hash = firstChecksum(path)
    tokens = split(strtrim(fileread(path)));
    hash = char(tokens(1));
end

function digest = sha256File(path)
    engine = java.security.MessageDigest.getInstance('SHA-256');
    fid = fopen(path,'rb');assert(fid >= 0,'Could not hash %s.',path);
    cleanup = onCleanup(@() fclose(fid));
    data = fread(fid,Inf,'*uint8');
    bytes = typecast(engine.digest(data),'uint8');
    digest = lower(reshape(dec2hex(bytes,2).',1,[]));
end
