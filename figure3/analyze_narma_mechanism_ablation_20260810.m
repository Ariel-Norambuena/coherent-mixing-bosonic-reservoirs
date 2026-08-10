%% analyze_narma_mechanism_ablation_20260810.m
clear; close all; clc;
scriptDir = fileparts(mfilename('fullpath'));
labels = ["J0 heterogeneous, both"; "J=.65 uniform G, detuning"; ...
    "J=.65 heterogeneous G, detuning"; "J=.65 heterogeneous, both"; ...
    "J=.65 both, no base-frequency disorder"; "J=.65 drive only"; ...
    "J=.65 uniform G, both"; "J=.65 both, no copy disorder"; ...
    "J=.65 both, no detuning disorder"];
slugs = ["J0_Heterogeneous_Both"; "J065_UniformG_DetuningOnly"; ...
    "J065_HeterogeneousG_DetuningOnly"; "J065_Heterogeneous_Both"; ...
    "J065_Heterogeneous_Both_NoStaticDisorder"; "J065_Heterogeneous_DriveOnly"; ...
    "J065_UniformG_Both"; "J065_Heterogeneous_Both_NoCopyDisorder"; ...
    "J065_Both_NoDetuningDisorder"];
nSeeds = 10; nConditions = numel(labels);
rows = cell(nSeeds*nConditions,11); cursor = 0;
for seedIndex = 1:nSeeds
    for conditionIndex = 1:nConditions
        pattern = sprintf(['Fig3_KerrReservoir_NARMA10_Reproducible_' ...
            'MechanismSelection_C%02d_%s_Index%02d_Offset%04d_20260810_summary.mat'], ...
            conditionIndex, slugs(conditionIndex), seedIndex, 100+seedIndex);
        file = fullfile(scriptDir,pattern);
        assert(isfile(file),'Missing mechanism result: %s',file);
        S = load(file,'cfg','P','results','pcaInfo');
        assert(strcmp(S.cfg.protocolMode,'selection') && isnan(S.results.main.NRMSE));
        H0 = diag(S.P.Delta0) + S.P.J;
        G = diag(S.P.gDelta);
        commutator = H0*G-G*H0;
        normalizedCommutator = norm(commutator,'fro') / ...
            max(eps,norm(H0,'fro')*norm(G,'fro'));
        singularValues = S.pcaInfo.singularValues(:);
        varianceWeights = singularValues.^2/sum(singularValues.^2);
        effectiveRank = exp(-sum(varianceWeights.*log(varianceWeights+eps)));
        participationRatio = 1/sum(varianceWeights.^2);
        conditionNumber = singularValues(1)/max(singularValues(end),eps);
        cursor = cursor+1;
        rows(cursor,:) = {seedIndex,conditionIndex,labels(conditionIndex), ...
            S.P.J0,S.cfg.encodingGDeltaMode,S.cfg.inputMode, ...
            S.cfg.staticDisorderEnabled,S.results.main.valNRMSE, ...
            normalizedCommutator,effectiveRank,conditionNumber};
    end
end
raw = cell2table(rows,'VariableNames',{'seedIndex','conditionIndex','condition', ...
    'J','gDeltaMode','inputMode','staticDisorderEnabled','validationNRMSE', ...
    'normalizedCommutator','effectiveRank','conditionNumber'});
writetable(raw,fullfile(scriptDir,'NARMAMechanismAblation_Raw_20260810.csv'));

summaryRows = cell(nConditions,10);
for c = 1:nConditions
    R = raw(raw.conditionIndex==c,:);
    summaryRows(c,:) = {c,labels(c),mean(R.validationNRMSE),std(R.validationNRMSE), ...
        median(R.validationNRMSE),quantile(R.validationNRMSE,.25), ...
        quantile(R.validationNRMSE,.75),mean(R.normalizedCommutator), ...
        mean(R.effectiveRank),mean(log10(R.conditionNumber))};
end
summary = cell2table(summaryRows,'VariableNames',{'conditionIndex','condition', ...
    'meanValidationNRMSE','sdValidationNRMSE','medianValidationNRMSE', ...
    'q25ValidationNRMSE','q75ValidationNRMSE','meanNormalizedCommutator', ...
    'meanEffectiveRank','meanLog10ConditionNumber'});
writetable(summary,fullfile(scriptDir,'NARMAMechanismAblation_Summary_20260810.csv'));

colors = lines(nConditions);
fig = figure('Color','w','Visible','off','Units','inches','Position',[1 1 7.2 4.1]);
ax1=axes(fig,'Position',[.31 .13 .31 .80]); hold(ax1,'on');
for c=1:nConditions
    R=raw(raw.conditionIndex==c,:);
    y=c+linspace(-.12,.12,height(R)).';
    plot(ax1,R.validationNRMSE,y,'o','Color',colors(c,:),'MarkerFaceColor','w','MarkerSize',4);
    errorbar(ax1,mean(R.validationNRMSE),c,0,0,std(R.validationNRMSE),std(R.validationNRMSE), ...
        's','Color',colors(c,:), ...
        'MarkerFaceColor',colors(c,:),'LineWidth',1.2,'CapSize',7);
end
set(ax1,'YTick',1:nConditions,'YTickLabel',labels,'YDir','reverse');
xlabel(ax1,'validation NRMSE');
title(ax1,'(a) Equal-budget ablations','FontWeight','normal'); grid(ax1,'on'); box(ax1,'on');
ax2=axes(fig,'Position',[.70 .16 .24 .74]); hold(ax2,'on');
scatter(ax2,raw.normalizedCommutator,raw.effectiveRank,32,raw.validationNRMSE,'filled');
xlabel(ax2,'normalized commutator norm'); ylabel(ax2,'retained-spectrum rank');
title(ax2,'(b) Rank diagnostic','FontWeight','normal');
cb=colorbar(ax2); cb.Label.String='validation NRMSE'; grid(ax2,'on'); box(ax2,'on');
set([ax1 ax2],'FontName','Arial','FontSize',9,'LineWidth',.8);
exportgraphics(fig,fullfile(scriptDir,'NARMAMechanismAblation_20260810.pdf'),'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'NARMAMechanismAblation_20260810.png'),'Resolution',300);
close(fig);
fprintf('MECHANISM_ABLATION_ANALYSIS_PASS rows=%d\n',height(raw));
