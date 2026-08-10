%% run_narma_no_detuning_disorder_seed_20260810.m
assert(exist('KERR_NO_DISORDER_SEED_INDEX','var')==1,'Set seed index 1--10.');
seedIndex=KERR_NO_DISORDER_SEED_INDEX;assert(isscalar(seedIndex)&&seedIndex==floor(seedIndex)&&seedIndex>=1&&seedIndex<=10);
KERR_NARMA_PROTOCOL_MODE='selection';KERR_NARMA_SEED_OFFSET=100+seedIndex;
KERR_NARMA_BASE_K=0;KERR_NARMA_BASE_J=.65;KERR_NARMA_INPUT_GAIN_SCALE=1.25;
KERR_NARMA_STEPS_PER_SAMPLE=55;KERR_NARMA_VIRTUAL_NODE_IDX=[11 20 29 37 46 55];
KERR_NARMA_NPC=26;KERR_NARMA_TAP_DELAYS=[0 1 2 3 4 5 6 7 8 9 10 12 15];
KERR_NARMA_LAMBDA_GRID=logspace(-6,3,28);KERR_NARMA_BASE_FEATURE_MODE='linear_features';
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS=true;KERR_NARMA_SKIP_BASELINES=true;KERR_NARMA_DISABLE_PLOTS=true;
KERR_NARMA_SAVE_COMPACT_FEATURES=true;KERR_NARMA_DISABLE_STATIC_DISORDER=true;
KERR_NARMA_COPY_DETUNING_DISORDER=0;
KERR_NARMA_OUTPUT_TAG=sprintf('MechanismSelection_C09_J065_Both_NoDetuningDisorder_Index%02d_Offset%04d_20260810',seedIndex,100+seedIndex);
run(fullfile(fileparts(mfilename('fullpath')),'Fig3_KerrReservoir_NARMA10_Reproducible.m'));
assert(~cfg.staticDisorderEnabled&&cfg.copyDetuningDisorder==0&&isnan(results.main.NRMSE));
fprintf('NO_DETUNING_DISORDER_PASS output=%s valNRMSE=%.6f\n',cfg.outputPrefix,results.main.valNRMSE);

