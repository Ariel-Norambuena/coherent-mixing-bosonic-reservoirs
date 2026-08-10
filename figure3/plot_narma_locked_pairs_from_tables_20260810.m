%% Regenerate the locked-pair figure from the archived seed-level table.
clear; close all; clc;
scriptDir = fileparts(mfilename('fullpath'));
raw = readtable(fullfile(scriptDir, 'NARMALockedPairs_Raw_20260810.csv'), ...
    'TextType', 'string');
modes = ["linear_features", "number_features"];
titles = {'quadrature readout', 'intensity readout'};
nPairs = numel(unique(raw.lockedIndex));
assert(nPairs == 30 && all(isfinite(raw.testNRMSE)));

fig = figure('Color','w','Visible','off','Units','inches', ...
    'Position',[1 1 7.2 3.35]);
layout = tiledlayout(1,numel(modes),'TileSpacing','compact','Padding','compact');
for m = 1:numel(modes)
    R = raw(raw.featureMode == modes(m),:);
    control = nan(nPairs,1);
    intervention = nan(nPairs,1);
    for q = 1:nPairs
        Q = R(R.lockedIndex == q,:);
        [~,order] = sort(Q.J);
        Q = Q(order,:);
        assert(height(Q) == 2);
        control(q) = Q.testNRMSE(1);
        intervention(q) = Q.testNRMSE(2);
    end
    ax = nexttile(layout,m); hold(ax,'on');
    for q = 1:nPairs
        plot(ax,[1 2],[control(q),intervention(q)],'-', ...
            'Color',[0.72 0.72 0.72],'LineWidth',0.65);
    end
    scatter(ax,ones(nPairs,1),control,24,[0.18 0.39 0.66], ...
        'filled','MarkerFaceAlpha',0.78);
    scatter(ax,2*ones(nPairs,1),intervention,24,[0.78 0.25 0.20], ...
        'filled','MarkerFaceAlpha',0.78);
    plot(ax,[1 2],[mean(control),mean(intervention)],'-o','Color','k', ...
        'LineWidth',2,'MarkerFaceColor','w','MarkerSize',7);
    xlim(ax,[0.72 2.28]); xticks(ax,[1 2]);
    xticklabels(ax,{'J = 0','J = J^*'});
    ylabel(ax,'Test NRMSE'); title(ax,titles{m},'FontWeight','normal');
    grid(ax,'on'); ax.FontSize=10; ax.LineWidth=0.9;
end
exportgraphics(fig,fullfile(scriptDir,'NARMALockedPairs_20260810.pdf'), ...
    'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'NARMALockedPairs_20260810.png'), ...
    'Resolution',300);
close(fig);
fprintf('LOCKED_TABLE_PLOT_PASS n=%d modes=%d\n',nPairs,numel(modes));
