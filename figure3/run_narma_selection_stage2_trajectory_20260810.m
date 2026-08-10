%% Run one cached stage-2 selection trajectory and its four readout variants.
% Set KERR_NARMA_STAGE2_TRAJECTORY_ID to a row of the generated trajectory
% plan. Optional KERR_NARMA_STAGE2_SMOKE=true uses the reduced dataset.

scriptDir = fileparts(mfilename('fullpath'));
trajectoryFile = fullfile(scriptDir, ...
    'NARMASelectionStage2_TrajectoryPlan_20260810.csv');
readoutFile = fullfile(scriptDir, ...
    'NARMASelectionStage2_ReadoutPlan_20260810.csv');
assert(isfile(trajectoryFile) && isfile(readoutFile), ...
    'Run plan_narma_stage2_cached_grid_20260810.m first.');

if ~exist('KERR_NARMA_STAGE2_TRAJECTORY_ID','var')
    error('Set KERR_NARMA_STAGE2_TRAJECTORY_ID to a trajectory-plan row.');
end
trajectoryId = KERR_NARMA_STAGE2_TRAJECTORY_ID;
if exist('KERR_NARMA_STAGE2_SMOKE','var')
    stage2Smoke = logical(KERR_NARMA_STAGE2_SMOKE);
else
    stage2Smoke = false;
end

trajectoryPlan = readtable(trajectoryFile, 'TextType','string');
readoutPlan = readtable(readoutFile, 'TextType','string');
assert(isscalar(trajectoryId) && isfinite(trajectoryId) && ...
    trajectoryId >= 1 && trajectoryId == floor(trajectoryId) && ...
    trajectoryId <= height(trajectoryPlan));
trajectory = trajectoryPlan(trajectoryId,:);
variantRows = readoutPlan(readoutPlan.readoutTrajectoryId == trajectoryId,:);
assert(height(variantRows) == 4);

readoutVariants = repmat(struct('label','','virtualNodeIdx',[], ...
    'tapDelays',[],'nPC',[]), height(variantRows), 1);
for q = 1:height(variantRows)
    readoutVariants(q).label = sprintf('V%d_Taps%d_PC%d', ...
        variantRows.actualVirtualSamples(q), variantRows.nDelayBlocks(q), ...
        variantRows.nPC(q));
    readoutVariants(q).virtualNodeIdx = parseIntegerList( ...
        variantRows.virtualNodeIdx(q));
    readoutVariants(q).tapDelays = parseIntegerList(variantRows.tapDelays(q));
    readoutVariants(q).nPC = variantRows.nPC(q);
end
unionNodes = parseIntegerList(trajectory.unionVirtualNodeIdx);

if stage2Smoke
    runKind = 'Smoke';
else
    runKind = 'Full';
end
outputTag = sprintf('SelectionStage2%s_Trajectory%03d_Offset%04d_20260810', ...
    runKind, trajectoryId, trajectory.seedOffset);
if stage2Smoke
    expectedPrefix = fullfile(scriptDir, ...
        ['Fig3_KerrReservoir_NARMA10_Reproducible_SMOKE_' outputTag]);
else
    expectedPrefix = fullfile(scriptDir, ...
        ['Fig3_KerrReservoir_NARMA10_Reproducible_' outputTag]);
end
if ~isempty(dir([expectedPrefix '*']))
    error('Collision guard: outputs already exist for %s.', outputTag);
end

KERR_NARMA_PROTOCOL_MODE = 'selection';
KERR_NARMA_SMOKE = stage2Smoke;
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS = true;
KERR_NARMA_SKIP_BASELINES = true;
KERR_NARMA_SEED_OFFSET = trajectory.seedOffset;
KERR_NARMA_BASE_K = trajectory.K;
KERR_NARMA_BASE_J = trajectory.J;
KERR_NARMA_BASE_FEATURE_MODE = 'linear_features';
KERR_NARMA_INPUT_GAIN_SCALE = trajectory.inputGainScale;
KERR_NARMA_STEPS_PER_SAMPLE = trajectory.stepsPerSample;
KERR_NARMA_VIRTUAL_NODE_IDX = unionNodes;
KERR_NARMA_NPC = readoutVariants(1).nPC;
KERR_NARMA_TAP_DELAYS = readoutVariants(1).tapDelays;
KERR_NARMA_READOUT_VARIANTS = readoutVariants;
KERR_NARMA_OUTPUT_TAG = outputTag;

run(fullfile(scriptDir, 'Fig3_KerrReservoir_NARMA10_Reproducible.m'));

assert(strcmp(cfg.protocolMode, 'selection') && ~cfg.evaluateTest);
assert(numel(results.readoutVariants.label) == 4);
assert(all(isfinite(results.readoutVariants.valNRMSE)));
assert(all(isnan(results.readoutVariants.testNRMSE)));
assert(all(results.readoutVariants.tappedFeatureDim <= 351));
fprintf('Stage-2 cached trajectory PASS (offset %d, prefix %s).\n', ...
    cfg.seedOffset, cfg.outputPrefix);

function values = parseIntegerList(text)
    values = str2double(split(string(text), ';')).';
    assert(all(isfinite(values)) && all(values == floor(values)));
end
