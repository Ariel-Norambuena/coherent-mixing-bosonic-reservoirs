function test_stage2_cached_direct_equivalence_20260810
% Verify that a readout extracted from union-node states equals a direct run.

scriptDir = fileparts(mfilename('fullpath'));
unionPrefix = fullfile(scriptDir, ...
    ['Fig3_KerrReservoir_NARMA10_Reproducible_SMOKE_' ...
    'SelectionStage2Smoke_Trajectory001_Offset0101_20260810']);
unionFile = [unionPrefix '_summary.mat'];
assert(isfile(unionFile), ...
    'Run the cached stage-2 trajectory-1 smoke before this test.');
U0 = load(unionFile, 'cfg', 'P');
definition = U0.cfg.readoutVariants(1);

directTag = 'Stage2DirectEquivalenceSmoke_Trajectory001_V6T11_20260810';
directPrefix = fullfile(scriptDir, ...
    ['Fig3_KerrReservoir_NARMA10_Reproducible_SMOKE_' directTag]);
directFile = [directPrefix '_summary.mat'];
if ~isfile(directFile)
    KERR_NARMA_PROTOCOL_MODE = 'selection'; %#ok<NASGU>
    KERR_NARMA_SMOKE = true; %#ok<NASGU>
    KERR_NARMA_SKIP_PHYSICAL_ABLATIONS = true; %#ok<NASGU>
    KERR_NARMA_SKIP_BASELINES = true; %#ok<NASGU>
    KERR_NARMA_SEED_OFFSET = U0.cfg.seedOffset; %#ok<NASGU>
    KERR_NARMA_BASE_K = U0.P.K; %#ok<NASGU>
    KERR_NARMA_BASE_J = U0.P.J0; %#ok<NASGU>
    KERR_NARMA_BASE_FEATURE_MODE = U0.cfg.featureMode; %#ok<NASGU>
    KERR_NARMA_INPUT_GAIN_SCALE = U0.cfg.inputGainScale; %#ok<NASGU>
    KERR_NARMA_STEPS_PER_SAMPLE = U0.cfg.stepsPerSample; %#ok<NASGU>
    KERR_NARMA_VIRTUAL_NODE_IDX = definition.virtualNodeIdx; %#ok<NASGU>
    KERR_NARMA_NPC = definition.nPC; %#ok<NASGU>
    KERR_NARMA_TAP_DELAYS = definition.tapDelays; %#ok<NASGU>
    KERR_NARMA_OUTPUT_TAG = directTag; %#ok<NASGU>
    run(fullfile(scriptDir, 'Fig3_KerrReservoir_NARMA10_Reproducible.m'));
    scriptDir = fileparts(mfilename('fullpath'));
    directTag = char(overrideOutputTag);
    directPrefix = fullfile(scriptDir, ...
        ['Fig3_KerrReservoir_NARMA10_Reproducible_SMOKE_' directTag]);
    directFile = [directPrefix '_summary.mat'];
    unionPrefix = fullfile(scriptDir, ...
        ['Fig3_KerrReservoir_NARMA10_Reproducible_SMOKE_' ...
        'SelectionStage2Smoke_Trajectory001_Offset0101_20260810']);
    unionFile = [unionPrefix '_summary.mat'];
end

U = load(unionFile, 'cfg', 'results');
D = load(directFile, 'cfg', 'results');
cached = U.results.readoutVariants.readout{1};
direct = D.results.main;

assert(strcmp(U.cfg.protocolMode, 'selection') && ~U.cfg.evaluateTest);
assert(strcmp(D.cfg.protocolMode, 'selection') && ~D.cfg.evaluateTest);
assert(isequal(U.cfg.readoutVariants(1).virtualNodeIdx, D.cfg.virtualNodeIdx));
assert(isequal(U.cfg.readoutVariants(1).tapDelays, D.cfg.tapDelays));
assert(U.cfg.readoutVariants(1).nPC == D.cfg.nPC);

valCurveError = max(abs(cached.valCurve-direct.valCurve));
valNRMSEError = abs(cached.valNRMSE-direct.valNRMSE);
lambdaError = abs(cached.lambdaBest-direct.lambdaBest);
assert(valCurveError < 1e-12);
assert(valNRMSEError < 1e-12);
assert(lambdaError < 1e-12);
assert(isnan(cached.NRMSE) && isnan(direct.NRMSE));
assert(isempty(cached.Yte) && isempty(direct.Yte));

reportFile = fullfile(scriptDir, ...
    'NARMASelectionStage2_CacheEquivalence_20260810.md');
fid = fopen(reportFile, 'w');
assert(fid >= 0, 'Could not open equivalence report.');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Stage-2 cached/direct equivalence\n\n');
fprintf(fid, 'Status: **PASS**\n\n');
fprintf(fid, '- Variant: `%s`.\n', string(U.cfg.readoutVariants(1).label));
fprintf(fid, '- Validation-curve maximum absolute difference: `%.3g`.\n', ...
    valCurveError);
fprintf(fid, '- Validation-NRMSE absolute difference: `%.3g`.\n', ...
    valNRMSEError);
fprintf(fid, '- Selected-lambda absolute difference: `%.3g`.\n', lambdaError);
fprintf(fid, '- Test metrics evaluated: `false`.\n');
fprintf(fid, ['\nThe direct run and the subset extracted from union-node states are ' ...
    'numerically identical for the tested readout.\n']);

fprintf('Stage-2 cached/direct equivalence PASS.\n');
fprintf('Report: %s\n', reportFile);
end
