%% Run one validation-only K/J selection realization from the frozen bank.
% Set KERR_NARMA_SELECTION_INDEX to an integer from 1 to 10. Test metrics are
% disabled by the called pipeline. KERR_NARMA_SELECTION_SMOKE may be set true
% to validate the launcher with reduced sizes.

scriptDir = fileparts(mfilename('fullpath'));
configFile = fullfile(scriptDir, 'configs', ...
    'narma_revision_protocol_20260807.json');
protocol = jsondecode(fileread(configFile));

if ~exist('KERR_NARMA_SELECTION_INDEX', 'var')
    error('Set KERR_NARMA_SELECTION_INDEX to an integer from 1 to %d.', ...
        numel(protocol.selection_offsets));
end
selectionIndex = KERR_NARMA_SELECTION_INDEX;
if ~isscalar(selectionIndex) || ~isfinite(selectionIndex) || ...
        selectionIndex < 1 || selectionIndex ~= floor(selectionIndex) || ...
        selectionIndex > numel(protocol.selection_offsets)
    error('KERR_NARMA_SELECTION_INDEX is outside the frozen selection bank.');
end

if exist('KERR_NARMA_SELECTION_SMOKE', 'var')
    selectionSmoke = logical(KERR_NARMA_SELECTION_SMOKE);
else
    selectionSmoke = false;
end
seedOffset = protocol.selection_offsets(selectionIndex);
if selectionSmoke
    runKind = 'Smoke';
else
    runKind = 'Full';
end
outputTag = sprintf('SelectionStage1%s_Index%02d_Offset%04d_20260807', ...
    runKind, selectionIndex, seedOffset);

if selectionSmoke
    expectedPrefix = fullfile(scriptDir, ...
        ['Fig3_KerrReservoir_NARMA10_Reproducible_SMOKE_' outputTag]);
else
    expectedPrefix = fullfile(scriptDir, ...
        ['Fig3_KerrReservoir_NARMA10_Reproducible_' outputTag]);
end
existing = dir([expectedPrefix '*']);
if ~isempty(existing)
    error('Collision guard: selection output already exists for %s.', outputTag);
end

KERR_NARMA_PROTOCOL_MODE = 'selection';
KERR_NARMA_SMOKE = selectionSmoke;
KERR_NARMA_RUN_JSWEEP = true;
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS = true;
KERR_NARMA_SKIP_BASELINES = true;
KERR_NARMA_SEED_OFFSET = seedOffset;
KERR_NARMA_BASE_K = protocol.selection_stage_1.k_values(1);
KERR_NARMA_BASE_J = 0.8;
KERR_NARMA_JLIST = protocol.selection_stage_1.j_values(:).';
KERR_NARMA_JSWEEP_KLIST = protocol.selection_stage_1.k_values(:).';
KERR_NARMA_BASE_FEATURE_MODE = protocol.primary_endpoint.feature_mode;
KERR_NARMA_NPC = protocol.primary_endpoint.n_pc;
KERR_NARMA_TAP_DELAYS = protocol.primary_endpoint.tap_delays(:).';
KERR_NARMA_STEPS_PER_SAMPLE = protocol.selection_stage_1.steps_per_sample(1);
KERR_NARMA_NUM_VIRTUAL = protocol.selection_stage_1.virtual_samples(1);
KERR_NARMA_INPUT_GAIN_SCALE = protocol.selection_stage_1.input_gain_scales(1);
KERR_NARMA_OUTPUT_TAG = outputTag;

run(fullfile(scriptDir, 'Fig3_KerrReservoir_NARMA10_Reproducible.m'));

assert(strcmp(cfg.protocolMode, 'selection') && ~cfg.evaluateTest);
assert(all(isnan(results.JSweep.NRMSE), 'all'));
assert(all(isfinite(results.JSweep.valNRMSE), 'all'));
protocolPost = jsondecode(fileread(fullfile(scriptDir, 'configs', ...
    'narma_revision_protocol_20260807.json')));
selectionIndexPost = find(protocolPost.selection_offsets == cfg.seedOffset, 1);
if cfg.smokeTest
    runKindPost = 'smoke';
else
    runKindPost = 'full';
end
fprintf('Selection stage-1 %s realization %d/%d PASS (offset %d).\n', ...
    runKindPost, selectionIndexPost, numel(protocolPost.selection_offsets), cfg.seedOffset);
