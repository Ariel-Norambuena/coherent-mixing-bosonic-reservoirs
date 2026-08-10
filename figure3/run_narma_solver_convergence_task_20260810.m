%% run_narma_solver_convergence_task_20260810.m
assert(exist('KERR_CONVERGENCE_TASK_INDEX','var')==1,'Set convergence task 1--4.');
task=KERR_CONVERGENCE_TASK_INDEX; assert(isscalar(task)&&task==floor(task)&&task>=1&&task<=4);
coupled=task>2; refined=mod(task,2)==0;
seedOffset=101; maskSeed=900+3001*seedOffset;
rng(maskSeed); baseMask=2*rand(55,1)-1; baseBias=.15*(2*rand(55,1)-1);

KERR_NARMA_PROTOCOL_MODE='selection'; KERR_NARMA_SEED_OFFSET=seedOffset;
KERR_NARMA_BASE_K=0; KERR_NARMA_BASE_J=.65*coupled;
KERR_NARMA_INPUT_GAIN_SCALE=1.25; KERR_NARMA_NPC=26;
KERR_NARMA_TAP_DELAYS=[0 1 2 3 4 5 6 7 8 9 10 12 15];
KERR_NARMA_BASE_FEATURE_MODE='linear_features';
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS=true; KERR_NARMA_SKIP_BASELINES=true;
KERR_NARMA_DISABLE_PLOTS=true; KERR_NARMA_SAVE_COMPACT_FEATURES=true;
if coupled, KERR_NARMA_LAMBDA_GRID=1e-4; else, KERR_NARMA_LAMBDA_GRID=.01; end
if refined
    KERR_NARMA_STEPS_PER_SAMPLE=110; KERR_NARMA_DT=.00625;
    KERR_NARMA_VIRTUAL_NODE_IDX=[22 40 58 74 92 110];
    KERR_NARMA_INPUT_MASK=repelem(baseMask,2);
    KERR_NARMA_INPUT_BIAS=repelem(baseBias,2);
    resolution='Refined';
else
    KERR_NARMA_STEPS_PER_SAMPLE=55; KERR_NARMA_DT=.0125;
    KERR_NARMA_VIRTUAL_NODE_IDX=[11 20 29 37 46 55];
    KERR_NARMA_INPUT_MASK=baseMask; KERR_NARMA_INPUT_BIAS=baseBias;
    resolution='Coarse';
end
KERR_NARMA_OUTPUT_TAG=sprintf('SolverConvergence_J%03d_%s_20260810',round(100*KERR_NARMA_BASE_J),resolution);
run(fullfile(fileparts(mfilename('fullpath')),'Fig3_KerrReservoir_NARMA10_Reproducible.m'));
assert(strcmp(cfg.protocolMode,'selection')&&isnan(results.main.NRMSE));
fprintf('SOLVER_CONVERGENCE_TASK_PASS output=%s valNRMSE=%.6f\n',cfg.outputPrefix,results.main.valNRMSE);

