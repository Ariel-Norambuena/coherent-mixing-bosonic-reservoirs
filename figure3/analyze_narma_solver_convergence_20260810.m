%% analyze_narma_solver_convergence_20260810.m
clear;clc;scriptDir=fileparts(mfilename('fullpath')); rows=cell(2,8);
for q=1:2
    J=[0 .65]; jtag=[0 65];
    coarse=load(fullfile(scriptDir,sprintf(['Fig3_KerrReservoir_NARMA10_Reproducible_' ...
        'SolverConvergence_J%03d_Coarse_20260810_summary.mat'],jtag(q))), ...
        'cfg','results','betaFinalAll');
    fine=load(fullfile(scriptDir,sprintf(['Fig3_KerrReservoir_NARMA10_Reproducible_' ...
        'SolverConvergence_J%03d_Refined_20260810_summary.mat'],jtag(q))), ...
        'cfg','results','betaFinalAll');
    assert(abs(coarse.cfg.dt*coarse.cfg.stepsPerSample-fine.cfg.dt*fine.cfg.stepsPerSample)<1e-14);
    maxAbsDifference=max(abs(coarse.betaFinalAll(:)-fine.betaFinalAll(:)));
    relativeStateDifference=maxAbsDifference/max(1,max(abs(fine.betaFinalAll(:))));
    nrmseDifference=abs(coarse.results.main.valNRMSE-fine.results.main.valNRMSE);
    rows(q,:)={J(q),coarse.cfg.dt,fine.cfg.dt,coarse.results.main.valNRMSE, ...
        fine.results.main.valNRMSE,nrmseDifference,maxAbsDifference,relativeStateDifference};
end
T=cell2table(rows,'VariableNames',{'J','coarseDt','refinedDt','coarseValidationNRMSE', ...
    'refinedValidationNRMSE','absoluteNRMSEDifference','maxAbsStateDifference','relativeStateDifference'});
writetable(T,fullfile(scriptDir,'NARMASolverConvergence_20260810.csv'));
assert(all(T.absoluteNRMSEDifference<5e-3),'NRMSE did not converge within the predefined tolerance.');
fprintf('SOLVER_CONVERGENCE_ANALYSIS_PASS max_nrmse_delta=%.3e\n',max(T.absoluteNRMSEDifference));

