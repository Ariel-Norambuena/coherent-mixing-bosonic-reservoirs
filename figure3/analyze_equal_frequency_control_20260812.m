%% Compare a deterministic frequency span with an exactly degenerate network.

clear;clc;scriptDir=fileparts(mfilename('fullpath'));
protocol=jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'additional_benchmark_protocol_20260811.json')));
minimal=jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'minimal_architecture_locked_config_20260811.json')));
offsets=protocol.selection_offsets(:).';lambdaGrid=protocol.lambda_grid(:);
Jvalues=[minimal.J_control minimal.J_intervention];n=numel(offsets);
spanCurves=nan(n,2,numel(lambdaGrid));degenerateCurves=spanCurves;

for s=1:n
    for c=1:2
        jIndex=find(abs(protocol.J_grid-Jvalues(c))<1e-14);
        gainIndex=find(abs(protocol.input_gain_grid-minimal.input_gain_scale)<1e-14);
        spanTag=sprintf('MinimalStageA_S%02d_J%02d_G%02d_Offset%04d_20260811', ...
            s,jIndex,gainIndex,offsets(s));
        degTag=sprintf('EqualFrequencyValidation_S%02d_C%02d_Offset%04d_20260812', ...
            s,c,offsets(s));
        A=load(fullfile(scriptDir,['Fig3_KerrReservoir_NARMA10_Reproducible_' spanTag '_summary.mat']),'results','P');
        B=load(fullfile(scriptDir,['Fig3_KerrReservoir_NARMA10_Reproducible_' degTag '_summary.mat']),'results','P','cfg');
        assert(all(B.P.Delta0==0) && B.cfg.staticDetuningExplicitlyOverridden);
        spanCurves(s,c,:)=A.results.main.valCurve(:);
        degenerateCurves(s,c,:)=B.results.main.valCurve(:);
    end
end

architecture=["deterministic span";"equal frequencies";"deterministic span";"equal frequencies"];
J=[Jvalues(1);Jvalues(1);Jvalues(2);Jvalues(2)];
meanValidationNRMSE=nan(4,1);sdValidationNRMSE=meanValidationNRMSE;ridgeLambda=meanValidationNRMSE;
row=0;
for c=1:2
    for a=1:2
        row=row+1;if a==1,C=spanCurves(:,c,:);else,C=degenerateCurves(:,c,:);end
        meanCurve=squeeze(mean(C,1));[~,idx]=min(meanCurve);vals=squeeze(C(:,1,idx));
        meanValidationNRMSE(row)=mean(vals);sdValidationNRMSE(row)=std(vals);ridgeLambda(row)=lambdaGrid(idx);
    end
end
T=table(architecture,J,meanValidationNRMSE,sdValidationNRMSE,ridgeLambda);
writetable(T,fullfile(scriptDir,'EqualFrequencyControl_Summary_20260812.csv'));

raw=table(offsets(:),'VariableNames',{'seedOffset'});
for c=1:2
    spanIdx=find(lambdaGrid==ridgeLambda(2*c-1));degIdx=find(lambdaGrid==ridgeLambda(2*c));
    raw.(sprintf('span_J%d',c))=squeeze(spanCurves(:,c,spanIdx));
    raw.(sprintf('degenerate_J%d',c))=squeeze(degenerateCurves(:,c,degIdx));
end
writetable(raw,fullfile(scriptDir,'EqualFrequencyControl_Raw_20260812.csv'));
fprintf(['EQUAL_FREQUENCY_ANALYSIS_PASS span J0=%.6f deg J0=%.6f ' ...
    'span coupled=%.6f deg coupled=%.6f\n'],meanValidationNRMSE);
