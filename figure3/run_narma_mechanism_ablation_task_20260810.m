%% run_narma_mechanism_ablation_task_20260810.m
% Validation-only mechanism ablation on the frozen selection bank.

assert(exist('KERR_MECHANISM_TASK_INDEX','var') == 1, ...
    'Set KERR_MECHANISM_TASK_INDEX to an integer from 1 to 80.');
taskIndex = KERR_MECHANISM_TASK_INDEX;
assert(isscalar(taskIndex) && taskIndex == floor(taskIndex) && ...
    taskIndex >= 1 && taskIndex <= 80, 'Mechanism task index must be 1--80.');

nConditions = 8;
seedIndex = floor((taskIndex-1)/nConditions) + 1;
conditionIndex = mod(taskIndex-1,nConditions) + 1;
seedOffset = 100 + seedIndex;

labels = { ...
    'J0_Heterogeneous_Both', ...
    'J065_UniformG_DetuningOnly', ...
    'J065_HeterogeneousG_DetuningOnly', ...
    'J065_Heterogeneous_Both', ...
    'J065_Heterogeneous_Both_NoStaticDisorder', ...
    'J065_Heterogeneous_DriveOnly', ...
    'J065_UniformG_Both', ...
    'J065_Heterogeneous_Both_NoCopyDisorder'};

KERR_NARMA_PROTOCOL_MODE = 'selection';
KERR_NARMA_SEED_OFFSET = seedOffset;
KERR_NARMA_BASE_K = 0;
KERR_NARMA_BASE_J = 0.65;
KERR_NARMA_INPUT_GAIN_SCALE = 1.25;
KERR_NARMA_STEPS_PER_SAMPLE = 55;
KERR_NARMA_VIRTUAL_NODE_IDX = [11 20 29 37 46 55];
KERR_NARMA_NPC = 26;
KERR_NARMA_TAP_DELAYS = [0 1 2 3 4 5 6 7 8 9 10 12 15];
KERR_NARMA_LAMBDA_GRID = logspace(-6,3,28);
KERR_NARMA_BASE_FEATURE_MODE = 'linear_features';
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS = true;
KERR_NARMA_SKIP_BASELINES = true;
KERR_NARMA_DISABLE_PLOTS = true;
KERR_NARMA_SAVE_COMPACT_FEATURES = true;
KERR_NARMA_SAVE_RAW_FEATURES = ismember(conditionIndex,[1 4]);
KERR_NARMA_GDELTA_MODE = 'heterogeneous';
KERR_NARMA_GF_MODE = 'heterogeneous';
KERR_NARMA_INPUT_MODE = 'detuning+amplitude';
KERR_NARMA_DISABLE_STATIC_DISORDER = false;
KERR_NARMA_COPY_DISORDER_SCALE = 1;

switch conditionIndex
    case 1
        KERR_NARMA_BASE_J = 0;
    case 2
        KERR_NARMA_GDELTA_MODE = 'uniform';
        KERR_NARMA_GF_MODE = 'zero';
        KERR_NARMA_INPUT_MODE = 'detuning';
    case 3
        KERR_NARMA_GF_MODE = 'zero';
        KERR_NARMA_INPUT_MODE = 'detuning';
    case 4
        % Frozen coupled architecture.
    case 5
        KERR_NARMA_DISABLE_STATIC_DISORDER = true;
    case 6
        KERR_NARMA_GDELTA_MODE = 'zero';
        KERR_NARMA_INPUT_MODE = 'amplitude';
    case 7
        KERR_NARMA_GDELTA_MODE = 'uniform';
    case 8
        KERR_NARMA_COPY_DISORDER_SCALE = 0;
end

KERR_NARMA_OUTPUT_TAG = sprintf( ...
    'MechanismSelection_C%02d_%s_Index%02d_Offset%04d_20260810', ...
    conditionIndex, labels{conditionIndex}, seedIndex, seedOffset);
run(fullfile(fileparts(mfilename('fullpath')), ...
    'Fig3_KerrReservoir_NARMA10_Reproducible.m'));

assert(strcmp(cfg.protocolMode,'selection') && ~cfg.evaluateTest, ...
    'Mechanism ablation unexpectedly evaluated the test partition.');
assert(isnan(results.main.NRMSE), 'Selection-mode test NRMSE must be NaN.');
assert(size(Zvirt,2) == 26 && size(Xall,2) == 339, ...
    'Frozen feature/readout budget changed.');
fprintf('MECHANISM_TASK_PASS output=%s valNRMSE=%.6f\n', ...
    cfg.outputPrefix, results.main.valNRMSE);
