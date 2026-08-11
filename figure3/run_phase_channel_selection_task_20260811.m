%% Validation-only ridge selection for coherent phase-channel equalization.

assert(exist('PHASE_SELECTION_TASK_INDEX','var')==1,'Set PHASE_SELECTION_TASK_INDEX.');
scriptDir=fileparts(mfilename('fullpath'));
protocol=jsondecode(fileread(fullfile(scriptDir,'configs','additional_benchmark_protocol_20260811.json')));
locked=jsondecode(fileread(fullfile(scriptDir,'configs','minimal_architecture_locked_config_20260811.json')));
offsets=protocol.phase_selection_offsets(:).';nSeed=numel(offsets);nCondition=2;
taskIndex=PHASE_SELECTION_TASK_INDEX;assert(taskIndex==floor(taskIndex)&&taskIndex>=1&&taskIndex<=nSeed*nCondition);
seedIndex=floor((taskIndex-1)/nCondition)+1;conditionIndex=mod(taskIndex-1,nCondition)+1;
Jvalues=[locked.J_control locked.J_intervention];J=Jvalues(conditionIndex);offset=offsets(seedIndex);
[uRaw,uEncoded,target]=make_phase_channel_dataset_20260811(22000,offset);
tag=sprintf('PhaseSelection_S%02d_C%02d_Offset%04d_20260811',seedIndex,conditionIndex,offset);
prefix=fullfile(scriptDir,['Fig3_KerrReservoir_NARMA10_Reproducible_' tag]);assert(isempty(dir([prefix '*'])),'Collision guard.');

KERR_NARMA_PROTOCOL_MODE='selection';KERR_NARMA_OUTPUT_TAG=tag;KERR_NARMA_SEED_OFFSET=offset;
KERR_NARMA_BASE_K=locked.K;KERR_NARMA_BASE_J=J;KERR_NARMA_INPUT_GAIN_SCALE=locked.input_gain_scale;
KERR_NARMA_STEPS_PER_SAMPLE=locked.steps_per_sample;KERR_NARMA_VIRTUAL_NODE_IDX=locked.virtual_node_indices(:).';
KERR_NARMA_TAP_DELAYS=locked.tap_delays(:).';KERR_NARMA_NPC=locked.n_pc;KERR_NARMA_LAMBDA_GRID=protocol.lambda_grid(:).';
KERR_NARMA_BASE_FEATURE_MODE='linear_features';KERR_NARMA_GDELTA_MODE='uniform';KERR_NARMA_GF_MODE='uniform';
KERR_NARMA_INPUT_MODE='detuning+amplitude';KERR_NARMA_DISABLE_STATIC_DISORDER=true;KERR_NARMA_COPY_DISORDER_SCALE=0;
KERR_NARMA_NUM_RESERVOIRS=locked.num_reservoirs;KERR_NARMA_INPUT_MASK=locked.input_mask(:);KERR_NARMA_INPUT_BIAS=locked.input_bias(:);
KERR_NARMA_CUSTOM_INPUT_RAW=uRaw;KERR_NARMA_CUSTOM_INPUT_ENCODED=uEncoded;KERR_NARMA_CUSTOM_TARGET=target;
KERR_NARMA_TASK_LABEL='coherent phase-channel equalization';KERR_NARMA_SKIP_PHYSICAL_ABLATIONS=true;
KERR_NARMA_SKIP_BASELINES=true;KERR_NARMA_DISABLE_PLOTS=true;
run(fullfile(scriptDir,'Fig3_KerrReservoir_NARMA10_Reproducible.m'));

scriptDir=fileparts(mfilename('fullpath'));protocol=jsondecode(fileread(fullfile(scriptDir,'configs','additional_benchmark_protocol_20260811.json')));
locked=jsondecode(fileread(fullfile(scriptDir,'configs','minimal_architecture_locked_config_20260811.json')));
seedIndex=find(protocol.phase_selection_offsets==cfg.seedOffset);conditionIndex=find(abs([locked.J_control locked.J_intervention]-P.J0)<1e-14);
taskIndex=(seedIndex-1)*2+conditionIndex;assert(~cfg.evaluateTest&&isnan(results.main.NRMSE));
fprintf('PHASE_SELECTION_PASS task=%d J=%.3f val=%.6f\n',taskIndex,P.J0,results.main.valNRMSE);

