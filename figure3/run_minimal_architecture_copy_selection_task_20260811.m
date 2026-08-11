%% Validation-only one-, two-, and three-copy comparison at the selected J/gain.

assert(exist('MINIMAL_COPY_TASK_INDEX','var') == 1, ...
    'Set MINIMAL_COPY_TASK_INDEX before running this script.');
scriptDir = fileparts(mfilename('fullpath'));
protocol = jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'additional_benchmark_protocol_20260811.json')));
stageA = jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'minimal_architecture_stage_a_result_20260811.json')));
nSeed = numel(protocol.selection_offsets);
nCopy = numel(protocol.copy_grid);
nTasks = nSeed*nCopy;
taskIndex = MINIMAL_COPY_TASK_INDEX;
assert(taskIndex==floor(taskIndex) && taskIndex>=1 && taskIndex<=nTasks);
seedIndex = floor((taskIndex-1)/nCopy)+1;
copyIndex = mod(taskIndex-1,nCopy)+1;
seedOffset = protocol.selection_offsets(seedIndex);
nCopies = protocol.copy_grid(copyIndex);
tag = sprintf('MinimalCopy_S%02d_C%02d_Offset%04d_20260811', ...
    seedIndex,nCopies,seedOffset);
prefix = fullfile(scriptDir,['Fig3_KerrReservoir_NARMA10_Reproducible_' tag]);
assert(isempty(dir([prefix '*'])),'Collision guard for %s.',tag);

KERR_NARMA_PROTOCOL_MODE='selection';
KERR_NARMA_OUTPUT_TAG=tag;
KERR_NARMA_SEED_OFFSET=seedOffset;
KERR_NARMA_BASE_K=protocol.K;
KERR_NARMA_BASE_J=stageA.selected.J;
KERR_NARMA_INPUT_GAIN_SCALE=stageA.selected.input_gain_scale;
KERR_NARMA_STEPS_PER_SAMPLE=protocol.steps_per_sample;
KERR_NARMA_VIRTUAL_NODE_IDX=protocol.virtual_node_indices(:).';
KERR_NARMA_TAP_DELAYS=protocol.tap_delays(:).';
KERR_NARMA_NPC=protocol.n_pc;
KERR_NARMA_LAMBDA_GRID=protocol.lambda_grid(:).';
KERR_NARMA_BASE_FEATURE_MODE='linear_features';
KERR_NARMA_GDELTA_MODE='uniform'; KERR_NARMA_GF_MODE='uniform';
KERR_NARMA_INPUT_MODE='detuning+amplitude';
KERR_NARMA_DISABLE_STATIC_DISORDER=true;
KERR_NARMA_COPY_DISORDER_SCALE=0;
KERR_NARMA_NUM_RESERVOIRS=nCopies;
KERR_NARMA_INPUT_MASK=protocol.input_mask(:);
KERR_NARMA_INPUT_BIAS=protocol.input_bias(:);
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS=true;
KERR_NARMA_SKIP_BASELINES=true;
KERR_NARMA_DISABLE_PLOTS=true;
run(fullfile(scriptDir,'Fig3_KerrReservoir_NARMA10_Reproducible.m'));

scriptDir=fileparts(mfilename('fullpath'));
protocol=jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'additional_benchmark_protocol_20260811.json')));
stageA=jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'minimal_architecture_stage_a_result_20260811.json')));
seedIndex=find(protocol.selection_offsets==cfg.seedOffset);
copyIndex=find(protocol.copy_grid==cfg.numReservoirs);
taskIndex=(seedIndex-1)*numel(protocol.copy_grid)+copyIndex;
assert(isnan(results.main.NRMSE) && ~cfg.evaluateTest);
fprintf('MINIMAL_COPY_PASS task=%d copies=%d val=%.6f\n', ...
    taskIndex,cfg.numReservoirs,results.main.valNRMSE);

