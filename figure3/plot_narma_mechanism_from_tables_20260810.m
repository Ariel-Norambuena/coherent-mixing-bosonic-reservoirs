%% Regenerate the mechanism-ablation figure from archived tables.
clear; close all; clc;
scriptDir = fileparts(mfilename('fullpath'));
raw = readtable(fullfile(scriptDir,'NARMAMechanismAblation_Raw_20260810.csv'), ...
    'TextType','string');
summary = readtable(fullfile(scriptDir, ...
    'NARMAMechanismAblation_Summary_20260810.csv'),'TextType','string');
assert(height(raw)==90 && height(summary)==9 && ...
    all(isfinite(raw.validationNRMSE)));
labels = {
    'J=0; het. G; both'
    'J=.65; uniform G; detuning'
    'J=.65; het. G; detuning'
    'J=.65; het. G; both'
    'J=.65; both; no freq. disorder'
    'J=.65; drive only'
    'J=.65; uniform G; both'
    'J=.65; both; no copy disorder'
    'J=.65; both; no det. disorder'
    };
nConditions = height(summary);
colors = lines(nConditions);

fig = figure('Color','w','Visible','off','Units','inches', ...
    'Position',[1 1 7.2 4.45]);
ax1=axes(fig,'Position',[.37 .14 .27 .78]); hold(ax1,'on');
for c=1:nConditions
    R=raw(raw.conditionIndex==c,:);
    y=c+linspace(-.12,.12,height(R)).';
    plot(ax1,R.validationNRMSE,y,'o','Color',colors(c,:), ...
        'MarkerFaceColor','w','MarkerSize',4);
    errorbar(ax1,mean(R.validationNRMSE),c,0,0,std(R.validationNRMSE), ...
        std(R.validationNRMSE),'s','Color',colors(c,:), ...
        'MarkerFaceColor',colors(c,:),'LineWidth',1.2,'CapSize',7);
end
set(ax1,'YTick',1:nConditions,'YTickLabel',labels,'YDir','reverse');
xlabel(ax1,'validation NRMSE');
title(ax1,'(a) Equal-budget ablations','FontWeight','normal');
grid(ax1,'on'); box(ax1,'on');
ax2=axes(fig,'Position',[.71 .17 .22 .72]); hold(ax2,'on');
scatter(ax2,raw.normalizedCommutator,raw.effectiveRank,32, ...
    raw.validationNRMSE,'filled');
xlabel(ax2,'normalized commutator'); ylabel(ax2,'retained-spectrum rank');
title(ax2,'(b) Rank diagnostic','FontWeight','normal');
cb=colorbar(ax2); cb.Label.String='validation NRMSE';
grid(ax2,'on'); box(ax2,'on');
set([ax1 ax2],'FontName','Arial','FontSize',11.5,'LineWidth',.9);
set(cb,'FontName','Arial','FontSize',10.5,'LineWidth',.8);
cb.Label.FontSize = 11.5;
exportgraphics(fig,fullfile(scriptDir,'NARMAMechanismAblation_20260810.pdf'), ...
    'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'NARMAMechanismAblation_20260810.png'), ...
    'Resolution',300);
close(fig);
fprintf('MECHANISM_TABLE_PLOT_PASS rows=%d\n',height(raw));
