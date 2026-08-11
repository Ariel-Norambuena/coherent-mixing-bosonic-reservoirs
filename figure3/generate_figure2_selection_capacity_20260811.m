%% generate_figure2_selection_capacity_20260811.m
% Kerr-free validation selection and delay-resolved accessible memory.

clear; close all; clc;
scriptDir = fileparts(mfilename('fullpath'));
S1 = readtable(fullfile(scriptDir,'NARMASelectionStage1_Summary_20260807.csv'));
S2 = readtable(fullfile(scriptDir,'NARMASelectionStage2_Summary_20260810.csv'));
C = readtable(fullfile(scriptDir,'NARMAProcessingCapacity_Raw_20260810.csv'), ...
    'TextType','string');

blue = [.13 .42 .70]; red = [.79 .28 .17]; dark = [.18 .18 .20];
fig = figure('Color','w','Visible','off','Units','inches', ...
    'Position',[1 1 7.2 5.15]);
tiledlayout(2,2,'Padding','compact','TileSpacing','compact');

% (a) Only the prespecified Kerr-free J slice is shown.
ax1 = nexttile; hold(ax1,'on'); box(ax1,'on'); grid(ax1,'on');
R1 = sortrows(S1(abs(S1.Ksummary)<1e-14,:),'Jsummary');
errorbar(ax1,R1.Jsummary,R1.meanValidationNRMSE,R1.sdValidationNRMSE, ...
    'o-','Color',blue,'MarkerFaceColor','w','LineWidth',1.4,'CapSize',5);
scatter(ax1,.65,R1.meanValidationNRMSE(abs(R1.Jsummary-.65)<1e-12), ...
    70,'p','MarkerFaceColor',red,'MarkerEdgeColor',dark);
xlabel(ax1,'coherent hopping $J$','Interpreter','latex');
ylabel(ax1,'validation NRMSE');
title(ax1,'(a) Kerr-free coupling selection','FontWeight','normal');
text(ax1,.05,max(R1.meanValidationNRMSE)+.004, ...
    '$J/\kappa=0,\ 5.42,\ 6.67,\ 7.92$', ...
    'Interpreter','latex','FontSize',8.3,'Color',dark);

% (b) Stage-two validation refinement, unchanged from the frozen protocol.
ax2 = nexttile;
R2 = S2(S2.K==0&S2.J==.65&S2.virtualSamples==6&S2.nDelayBlocks==13,:);
gains = unique(R2.inputGainScale,'stable');
steps = unique(R2.stepsPerSample,'stable');
M2 = nan(numel(gains),numel(steps));
for i = 1:numel(gains)
    for j = 1:numel(steps)
        row = R2.inputGainScale==gains(i)&R2.stepsPerSample==steps(j);
        M2(i,j) = R2.meanValidationNRMSE(row);
    end
end
imagesc(ax2,M2); set(ax2,'YDir','normal','XTick',1:numel(steps), ...
    'XTickLabel',string(steps),'YTick',1:numel(gains), ...
    'YTickLabel',string(gains));
colormap(ax2,'parula'); colorbar(ax2);
xlabel(ax2,'integration steps per symbol'); ylabel(ax2,'input-gain scale');
title(ax2,'(b) Validation refinement','FontWeight','normal');
hold(ax2,'on');
plot(ax2,find(steps==55),find(abs(gains-1.25)<1e-12),'p', ...
    'MarkerSize',13,'MarkerFaceColor','w','MarkerEdgeColor','k');
for i = 1:numel(gains)
    for j = 1:numel(steps)
        text(ax2,j,i,sprintf('%.3f',M2(i,j)),'HorizontalAlignment','center', ...
            'Color','w','FontWeight','bold','FontSize',8);
    end
end

% (c) Delay-resolved capacity from untapped physical states.
ax3 = nexttile([1 2]); hold(ax3,'on'); box(ax3,'on'); grid(ax3,'on');
conditions = [1 4]; labels = ["J=0" "J=0.65"];
colors = [dark; blue];
summaryRows = [];
for q = 1:numel(conditions)
    rows = C(C.conditionIndex==conditions(q)&C.capacityType=="linear",:);
    lags = unique(rows.lagA,'sorted');
    meanCap = nan(numel(lags),1); sdCap = meanCap; semCap = meanCap;
    for k = 1:numel(lags)
        values = rows.capacity(rows.lagA==lags(k));
        meanCap(k) = mean(values); sdCap(k) = std(values,0);
        semCap(k) = sdCap(k)/sqrt(numel(values));
    end
    errorbar(ax3,lags,meanCap,semCap,'o-','Color',colors(q,:), ...
        'MarkerFaceColor','w','LineWidth',1.35,'CapSize',3, ...
        'DisplayName',labels(q));
    tq = table(repmat(conditions(q),numel(lags),1), ...
        repmat(labels(q),numel(lags),1),lags,meanCap,sdCap,semCap, ...
        'VariableNames',{'conditionIndex','condition','lag','meanCapacity', ...
        'sdCapacity','semCapacity'});
    summaryRows = [summaryRows; tq]; %#ok<AGROW>
end
yyaxis(ax3,'right');
lagGuide = (1:20)'; kappaTs = .120*(55*.0125);
plot(ax3,lagGuide,exp(-kappaTs*lagGuide),'--','Color',red, ...
    'LineWidth',1.2,'DisplayName','$e^{-\kappa T_s\tau}$');
ylabel(ax3,'normalized energy envelope'); ylim(ax3,[0 1]);
yyaxis(ax3,'left');
xlabel(ax3,'input delay $\tau$ (symbols)','Interpreter','latex');
ylabel(ax3,'linear-memory capacity $C_1(\tau)$','Interpreter','latex');
title(ax3,['(c) Hopping redistributes readout-accessible memory within the ' ...
    'same loss envelope'],'FontWeight','normal');
legend(ax3,'Interpreter','latex','Location','northeast','Box','off');
xlim(ax3,[1 20]);

set([ax1 ax2 ax3],'FontName','Arial','FontSize',9.5,'LineWidth',.8);
writetable(summaryRows,fullfile(scriptDir,'NARMALinearMemoryByLag_20260811.csv'));
exportgraphics(fig,fullfile(scriptDir,'Figure2_KerrFreeSelectionMemory_20260811.pdf'), ...
    'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'Figure2_KerrFreeSelectionMemory_20260811.png'), ...
    'Resolution',300);
close(fig);
fprintf('FIGURE2_KERRFREE_SELECTION_MEMORY_PASS\n');
