%% Save raw minimal-architecture quadratures for one condition and offset.

assert(exist('DYNAMIC_FEATURE_TASK_INDEX','var') == 1, ...
    'Set DYNAMIC_FEATURE_TASK_INDEX before running this script.');
scriptDir=fileparts(mfilename('fullpath'));
protocol=jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'additional_benchmark_protocol_20260811.json')));
minimal=jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'minimal_architecture_locked_config_20260811.json')));
taskIndex=DYNAMIC_FEATURE_TASK_INDEX;assert(ismember(taskIndex,1:20));
conditionIndex=mod(taskIndex-1,2)+1;
offsetIndex=floor((taskIndex-1)/2)+1;offset=100+offsetIndex;
Jvalues=[minimal.J_control minimal.J_intervention];J=Jvalues(conditionIndex);
tag=sprintf('DynamicPhotonAudit_C%02d_Offset%04d_20260812', ...
    conditionIndex,offset);
prefix=fullfile(scriptDir,['Fig3_KerrReservoir_NARMA10_Reproducible_' tag]);
outputFile=[prefix '_summary.mat'];
if isfile(outputFile)
    fprintf('DYNAMIC_FEATURE_AUDIT_REUSE condition=%d offset=%d\n', ...
        conditionIndex,offset);
    return
end

KERR_NARMA_PROTOCOL_MODE='selection';KERR_NARMA_OUTPUT_TAG=tag;
KERR_NARMA_SEED_OFFSET=offset;KERR_NARMA_BASE_K=minimal.K;
KERR_NARMA_BASE_J=J;
KERR_NARMA_INPUT_GAIN_SCALE=minimal.input_gain_scale;
KERR_NARMA_STEPS_PER_SAMPLE=minimal.steps_per_sample;
KERR_NARMA_VIRTUAL_NODE_IDX=minimal.virtual_node_indices(:).';
KERR_NARMA_TAP_DELAYS=minimal.tap_delays(:).';KERR_NARMA_NPC=minimal.n_pc;
KERR_NARMA_LAMBDA_GRID=protocol.lambda_grid(:).';
KERR_NARMA_BASE_FEATURE_MODE='linear_features';
KERR_NARMA_GDELTA_MODE='uniform';KERR_NARMA_GF_MODE='uniform';
KERR_NARMA_INPUT_MODE='detuning+amplitude';
KERR_NARMA_DISABLE_STATIC_DISORDER=true;
KERR_NARMA_COPY_DISORDER_SCALE=0;KERR_NARMA_NUM_RESERVOIRS=1;
KERR_NARMA_INPUT_MASK=minimal.input_mask(:);
KERR_NARMA_INPUT_BIAS=minimal.input_bias(:);
KERR_NARMA_SAVE_RAW_FEATURES=true;KERR_NARMA_SKIP_PHYSICAL_ABLATIONS=true;
KERR_NARMA_SKIP_BASELINES=true;KERR_NARMA_DISABLE_PLOTS=true;
run(fullfile(scriptDir,'Fig3_KerrReservoir_NARMA10_Reproducible.m'));
assert(exist('Xvirt','var')==1 && isequal(size(Xvirt),[22000 144]));
fprintf('DYNAMIC_FEATURE_AUDIT_PASS J=%.2f offset=%d raw=%dx%d\n', ...
    P.J0,cfg.seedOffset,size(Xvirt,1),size(Xvirt,2));
