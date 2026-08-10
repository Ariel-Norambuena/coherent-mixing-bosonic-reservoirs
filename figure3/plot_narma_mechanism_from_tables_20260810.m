%% Regenerate the mechanism-ablation figure from archived tables.
clear; close all; clc;
scriptDir = fileparts(mfilename('fullpath'));
raw = readtable(fullfile(scriptDir,'NARMAMechanismAblation_Raw_20260810.csv'), ...
    'TextType','string');
summary = readtable(fullfile(scriptDir, ...
    'NARMAMechanismAblation_Summary_20260810.csv'),'TextType','string');
assert(height(raw)==90 && height(summary)==9 && ...
    all(isfinite(raw.validationNRMSE)));
labels = summary.condition;
nConditions = height(summary);
colors = lines(nConditions);

fig = figure('Color','w','Visible','off','Units','inches', ...
    'Position',[1 1 7.2 4.1]);
ax1=axes(fig,'Position',[.31 .13 .31 .80]); hold(ax1,'on');
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
ax2=axes(fig,'Position',[.70 .16 .24 .74]); hold(ax2,'on');
scatter(ax2,raw.normalizedCommutator,raw.effectiveRank,32, ...
    raw.validationNRMSE,'filled');
xlabel(ax2,'normalized commutator norm'); ylabel(ax2,'retained-spectrum rank');
title(ax2,'(b) Rank diagnostic','FontWeight','normal');
cb=colorbar(ax2); cb.Label.String='validation NRMSE';
grid(ax2,'on'); box(ax2,'on');
set([ax1 ax2],'FontName','Arial','FontSize',9,'LineWidth',.8);
exportgraphics(fig,fullfile(scriptDir,'NARMAMechanismAblation_20260810.pdf'), ...
    'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'NARMAMechanismAblation_20260810.png'), ...
    'Resolution',300);
close(fig);
fprintf('MECHANISM_TABLE_PLOT_PASS rows=%d\n',height(raw));
