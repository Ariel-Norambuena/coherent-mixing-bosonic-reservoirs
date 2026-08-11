%% Validation-only J/gain selection for a one-copy deterministic architecture.

assert(exist('MINIMAL_STAGE_A_TASK_INDEX','var') == 1, ...
    'Set MINIMAL_STAGE_A_TASK_INDEX before running this script.');
scriptDir = fileparts(mfilename('fullpath'));
protocol = jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'additional_benchmark_protocol_20260811.json')));

nSeed = numel(protocol.selection_offsets);
nJ = numel(protocol.J_grid);
nGain = numel(protocol.input_gain_grid);
nTasks = nSeed*nJ*nGain;
taskIndex = MINIMAL_STAGE_A_TASK_INDEX;
assert(isscalar(taskIndex) && taskIndex == floor(taskIndex) && ...
    taskIndex >= 1 && taskIndex <= nTasks,'Stage-A task index is invalid.');

configIndex = mod(taskIndex-1,nJ*nGain) + 1;
seedIndex = floor((taskIndex-1)/(nJ*nGain)) + 1;
jIndex = floor((configIndex-1)/nGain) + 1;
gainIndex = mod(configIndex-1,nGain) + 1;
seedOffset = protocol.selection_offsets(seedIndex);
J = protocol.J_grid(jIndex);
gain = protocol.input_gain_grid(gainIndex);
tag = sprintf('MinimalStageA_S%02d_J%02d_G%02d_Offset%04d_20260811', ...
    seedIndex,jIndex,gainIndex,seedOffset);
prefix = fullfile(scriptDir,['Fig3_KerrReservoir_NARMA10_Reproducible_' tag]);
assert(isempty(dir([prefix '*'])),'Collision guard for %s.',tag);

KERR_NARMA_PROTOCOL_MODE = 'selection';
KERR_NARMA_OUTPUT_TAG = tag;
KERR_NARMA_SEED_OFFSET = seedOffset;
KERR_NARMA_BASE_K = protocol.K;
KERR_NARMA_BASE_J = J;
KERR_NARMA_INPUT_GAIN_SCALE = gain;
KERR_NARMA_STEPS_PER_SAMPLE = protocol.steps_per_sample;
KERR_NARMA_VIRTUAL_NODE_IDX = protocol.virtual_node_indices(:).';
KERR_NARMA_TAP_DELAYS = protocol.tap_delays(:).';
KERR_NARMA_NPC = protocol.n_pc;
KERR_NARMA_LAMBDA_GRID = protocol.lambda_grid(:).';
KERR_NARMA_BASE_FEATURE_MODE = 'linear_features';
KERR_NARMA_GDELTA_MODE = 'uniform';
KERR_NARMA_GF_MODE = 'uniform';
KERR_NARMA_INPUT_MODE = 'detuning+amplitude';
KERR_NARMA_DISABLE_STATIC_DISORDER = true;
KERR_NARMA_COPY_DISORDER_SCALE = 0;
KERR_NARMA_NUM_RESERVOIRS = 1;
KERR_NARMA_INPUT_MASK = protocol.input_mask(:);
KERR_NARMA_INPUT_BIAS = protocol.input_bias(:);
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS = true;
KERR_NARMA_SKIP_BASELINES = true;
KERR_NARMA_DISABLE_PLOTS = true;
run(fullfile(scriptDir,'Fig3_KerrReservoir_NARMA10_Reproducible.m'));

scriptDir = fileparts(mfilename('fullpath'));
protocol = jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'additional_benchmark_protocol_20260811.json')));
seedIndex = find(protocol.selection_offsets == cfg.seedOffset);
jIndex = find(abs(protocol.J_grid-P.J0) < 1e-14);
gainIndex = find(abs(protocol.input_gain_grid-cfg.inputGainScale) < 1e-14);
assert(isscalar(seedIndex) && isscalar(jIndex) && isscalar(gainIndex));
taskIndex = (seedIndex-1)*numel(protocol.J_grid)* ...
    numel(protocol.input_gain_grid) + ...
    (jIndex-1)*numel(protocol.input_gain_grid) + gainIndex;
assert(strcmp(cfg.protocolMode,'selection') && ~cfg.evaluateTest);
assert(isnan(results.main.NRMSE) && numel(results.main.valCurve) == ...
    numel(protocol.lambda_grid));
fprintf('MINIMAL_STAGE_A_PASS task=%d val=%.6f\n',taskIndex,results.main.valNRMSE);
