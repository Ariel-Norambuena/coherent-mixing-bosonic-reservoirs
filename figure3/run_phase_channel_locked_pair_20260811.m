%% One locked coherent phase-channel equalization pair.

assert(exist('PHASE_LOCKED_INDEX','var')==1,'Set PHASE_LOCKED_INDEX.');scriptDir=fileparts(mfilename('fullpath'));
lockedFile=fullfile(scriptDir,'configs','phase_channel_locked_config_20260811.json');checksumFile=[lockedFile '.sha256'];assert(isfile(lockedFile)&&isfile(checksumFile));tokens=split(strtrim(fileread(checksumFile)));assert(strcmp(char(tokens(1)),sha256File(lockedFile)));
locked=jsondecode(fileread(lockedFile));idx=PHASE_LOCKED_INDEX;assert(idx==floor(idx)&&idx>=1&&idx<=numel(locked.locked_offsets));offset=locked.locked_offsets(idx);
[uRaw,uEncoded,target]=make_phase_channel_dataset_20260811(22000,offset);tag=sprintf('PhaseLocked_Index%02d_Offset%04d_20260811',idx,offset);prefix=fullfile(scriptDir,['Fig3_KerrReservoir_NARMA10_Reproducible_' tag]);assert(isempty(dir([prefix '*'])),'Collision guard.');
variant=struct('label','Primary339','tapDelays',locked.tap_delays(:).','nPC',locked.n_pc,'lambdaGrid',1);lambdaMap=reshape([locked.ridge_lambda_control;locked.ridge_lambda_intervention],[2 1 1]);
KERR_NARMA_PROTOCOL_MODE='locked';KERR_NARMA_LOCKED_PAIR=true;KERR_NARMA_OUTPUT_TAG=tag;KERR_NARMA_SEED_OFFSET=offset;KERR_NARMA_BASE_K=locked.K;KERR_NARMA_BASE_J=locked.J_intervention;KERR_NARMA_INPUT_GAIN_SCALE=locked.input_gain_scale;
KERR_NARMA_STEPS_PER_SAMPLE=locked.steps_per_sample;KERR_NARMA_VIRTUAL_NODE_IDX=locked.virtual_node_indices(:).';KERR_NARMA_TAP_DELAYS=locked.tap_delays(:).';KERR_NARMA_NPC=locked.n_pc;KERR_NARMA_LAMBDA_GRID=locked.ridge_lambda_intervention;
KERR_NARMA_BASE_FEATURE_MODE='linear_features';KERR_NARMA_FEATURE_MODES={'linear_features'};KERR_NARMA_FEATURE_CASES=[locked.K locked.J_control;locked.K locked.J_intervention];KERR_NARMA_FEATURE_BUDGET_VARIANTS=variant;KERR_NARMA_FEATURE_BUDGET_LAMBDA_MAP=lambdaMap;KERR_NARMA_RUN_FEATURE_ABLATIONS=true;
KERR_NARMA_GDELTA_MODE='uniform';KERR_NARMA_GF_MODE='uniform';KERR_NARMA_INPUT_MODE='detuning+amplitude';KERR_NARMA_DISABLE_STATIC_DISORDER=true;KERR_NARMA_COPY_DISORDER_SCALE=0;KERR_NARMA_NUM_RESERVOIRS=locked.num_reservoirs;KERR_NARMA_INPUT_MASK=locked.input_mask(:);KERR_NARMA_INPUT_BIAS=locked.input_bias(:);
KERR_NARMA_CUSTOM_INPUT_RAW=uRaw;KERR_NARMA_CUSTOM_INPUT_ENCODED=uEncoded;KERR_NARMA_CUSTOM_TARGET=target;KERR_NARMA_TASK_LABEL='coherent phase-channel equalization';KERR_NARMA_SKIP_PHYSICAL_ABLATIONS=true;KERR_NARMA_SKIP_BASELINES=true;KERR_NARMA_DISABLE_PLOTS=true;
run(fullfile(scriptDir,'Fig3_KerrReservoir_NARMA10_Reproducible.m'));
scriptDir=fileparts(mfilename('fullpath'));locked=jsondecode(fileread(fullfile(scriptDir,'configs','phase_channel_locked_config_20260811.json')));idx=find(locked.locked_offsets==cfg.seedOffset);C=readtable([cfg.outputPrefix '_FeatureBudgetVariants_summary.csv'],'Delimiter',',');assert(height(C)==2&&all(isfinite(C.testNRMSE)));fprintf('PHASE_LOCKED_PAIR_PASS index=%d J0=%.6f coupled=%.6f\n',idx,C.testNRMSE(C.J==locked.J_control),C.testNRMSE(C.J==locked.J_intervention));
function digest=sha256File(path)
engine=java.security.MessageDigest.getInstance('SHA-256');fid=fopen(path,'rb');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));bytes=typecast(engine.digest(fread(fid,Inf,'*uint8')),'uint8');digest=lower(reshape(dec2hex(bytes,2).',1,[]));
end
