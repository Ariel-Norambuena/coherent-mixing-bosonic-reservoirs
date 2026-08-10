%% Validation-only physical coefficient-budget curves for one selection seed.

clearvars -except KERR_PHYSICAL_BUDGET_SELECTION_INDEX KERR_PHYSICAL_BUDGET_SMOKE;
clc;
scriptDir = fileparts(mfilename('fullpath'));
protocol = jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'narma_revision_protocol_20260807.json')));
locked = jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'narma_locked_config_20260810.json')));
assert(exist('KERR_PHYSICAL_BUDGET_SELECTION_INDEX','var') == 1);
selectionIndex = KERR_PHYSICAL_BUDGET_SELECTION_INDEX;
assert(isscalar(selectionIndex) && selectionIndex == floor(selectionIndex) && ...
    selectionIndex >= 1 && selectionIndex <= numel(protocol.selection_offsets));
smoke = exist('KERR_PHYSICAL_BUDGET_SMOKE','var') == 1 && ...
    logical(KERR_PHYSICAL_BUDGET_SMOKE);
seedOffset = protocol.selection_offsets(selectionIndex);
budgets = protocol.budget_curve.budgets(:).';
if smoke
    budgets = budgets(1:2);
end
nTaps = numel(locked.tap_delays);
lambdaGrid = logspace(-6,6,37);
variants = repmat(struct('label','','tapDelays',[], ...
    'nPC',[],'lambdaGrid',[]),numel(budgets),1);
for q = 1:numel(budgets)
    variants(q).label = sprintf('Budget%d',budgets(q));
    variants(q).tapDelays = locked.tap_delays(:).';
    variants(q).nPC = floor((budgets(q)-1)/nTaps);
    variants(q).lambdaGrid = lambdaGrid;
end
if smoke
    runKind = 'SmokeV5';
else
    runKind = 'FullV2';
end
outputTag = sprintf('PhysicalBudgetSelection%s_Index%02d_Offset%04d_20260810', ...
    runKind,selectionIndex,seedOffset);
if smoke
    expectedPrefix = fullfile(scriptDir, ...
        ['Fig3_KerrReservoir_NARMA10_Reproducible_SMOKE_' outputTag]);
else
    expectedPrefix = fullfile(scriptDir, ...
        ['Fig3_KerrReservoir_NARMA10_Reproducible_' outputTag]);
end
assert(isempty(dir([expectedPrefix '*'])),'Collision guard for %s.',outputTag);

KERR_NARMA_PROTOCOL_MODE = 'selection';
KERR_NARMA_SMOKE = smoke;
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
KERR_NARMA_LAMBDA_GRID = lambdaGrid;
KERR_NARMA_BASE_FEATURE_MODE = char(locked.primary_feature_mode);
KERR_NARMA_FEATURE_MODES = cellstr(string(locked.feature_modes));
KERR_NARMA_FEATURE_CASES = [locked.K,locked.J_control; ...
    locked.K,locked.J_intervention];
KERR_NARMA_FEATURE_BUDGET_VARIANTS = variants;
KERR_NARMA_RUN_FEATURE_ABLATIONS = true;
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS = true;
KERR_NARMA_SKIP_BASELINES = true;
run(fullfile(scriptDir,'Fig3_KerrReservoir_NARMA10_Reproducible.m'));

csvFile = [cfg.outputPrefix '_FeatureBudgetVariants_summary.csv'];
assert(isfile(csvFile));
C = readtable(csvFile,'TextType','string','Delimiter',',');
expectedRows = size(results.featureAblation.budgetVariants,1)* ...
    size(results.featureAblation.budgetVariants,2)* ...
    numel(cfg.featureBudgetVariants);
assert(height(C) == expectedRows);
assert(all(isfinite(C.valNRMSE)) && all(isnan(C.testNRMSE)) && ...
    all(isnan(C.R2true)));
fprintf('PHYSICAL_BUDGET_SELECTION_PASS offset=%d rows=%d test=0\n', ...
    cfg.seedOffset,height(C));
