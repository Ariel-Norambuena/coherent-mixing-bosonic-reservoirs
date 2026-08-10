%% analyze_narma_determinism_20260810.m
clear;clc;scriptDir=fileparts(mfilename('fullpath'));
A=load(fullfile(scriptDir,'Fig3_KerrReservoir_NARMA10_Reproducible_DeterminismReplicate1_20260810_summary.mat'), ...
    'uN','uEnc','yN','Zvirt','betaFinalAll','results');
B=load(fullfile(scriptDir,'Fig3_KerrReservoir_NARMA10_Reproducible_DeterminismReplicate2_20260810_summary.mat'), ...
    'uN','uEnc','yN','Zvirt','betaFinalAll','results');
maxInputDifference=max(abs(A.uN-B.uN)); maxTargetDifference=max(abs(A.yN-B.yN));
maxStateDifference=max(abs(A.betaFinalAll(:)-B.betaFinalAll(:)));
maxFeatureDifference=max(abs(A.Zvirt(:)-B.Zvirt(:)));
nrmseDifference=abs(A.results.main.valNRMSE-B.results.main.valNRMSE);
T=table(maxInputDifference,maxTargetDifference,maxStateDifference,maxFeatureDifference,nrmseDifference);
writetable(T,fullfile(scriptDir,'NARMASeedDeterminism_20260810.csv'));
assert(all(T{1,:}<=1e-12),'Repeated seeded runs differ beyond numerical tolerance.');
fprintf('SEED_DETERMINISM_ANALYSIS_PASS max_difference=%.3e\n',max(T{1,:}));

