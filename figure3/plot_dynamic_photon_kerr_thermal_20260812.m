%% Plot the multi-offset centered-feature photon and residual-Kerr audit.

clear;close all;clc;scriptDir=fileparts(mfilename('fullpath'));
raw=readtable(fullfile(scriptDir,'DynamicPhotonKerrMultiOffset_Raw_20260813.csv'));
assert(height(raw)==20 && numel(unique(raw.offset))==10);
Jvalues=[0 .65];nGroups=numel(Jvalues);

countVars={'carrierEffectivePhotons','medianRawEffectivePhotons', ...
    'medianPcaEffectivePhotons'};
powerVars={'requiredPowerMedianPca_W','kerrBoundaryPower_W'};
countMedian=nan(nGroups,numel(countVars));countLo=countMedian;countHi=countMedian;
powerMedian=nan(nGroups,numel(powerVars));powerLo=powerMedian;powerHi=powerMedian;
for c=1:nGroups
    rows=abs(raw.J-Jvalues(c))<1e-14;
    assert(sum(rows)==10 && isequal(raw.offset(rows),(101:110).'));
    for v=1:numel(countVars)
        values=raw.(countVars{v})(rows);
        countMedian(c,v)=median(values);countLo(c,v)=prctile(values,2.5);
        countHi(c,v)=prctile(values,97.5);
    end
    for v=1:numel(powerVars)
        values=raw.(powerVars{v})(rows);
        powerMedian(c,v)=median(values);powerLo(c,v)=prctile(values,2.5);
        powerHi(c,v)=prctile(values,97.5);
    end
end

blue=[.14 .42 .70];red=[.82 .25 .18];gray=[.55 .57 .60];
fig=figure('Color','w','Visible','off','Units','inches','Position',[1 1 7.1 4.9]);
tiledlayout(1,2,'Padding','compact','TileSpacing','loose');
ax=nexttile;bars=bar(ax,countMedian);hold(ax,'on');
bars(1).FaceColor=gray;bars(2).FaceColor=blue;bars(3).FaceColor=red;
for v=1:numel(bars)
    errorbar(ax,bars(v).XEndPoints,countMedian(:,v), ...
        countMedian(:,v)-countLo(:,v),countHi(:,v)-countMedian(:,v), ...
        'k.','LineWidth',1.0,'CapSize',4,'HandleVisibility','off');
end
set(ax,'YScale','log');xticklabels(ax,{'$J=0$','$J=0.65$'});
set(ax,'TickLabelInterpreter','latex');
ylabel(ax,'effective photons at reference power');
title(ax,'(a) Carrier versus dynamic signal','FontWeight','normal');
grid(ax,'on');box(ax,'on');
legend(ax,bars,{'total occupation','centered raw','centered PCA'}, ...
    'Location','southoutside','Box','off','FontSize',10.2);

ax=nexttile;bars=bar(ax,powerMedian);hold(ax,'on');
bars(1).FaceColor=red;bars(2).FaceColor=blue;
for v=1:numel(bars)
    errorbar(ax,bars(v).XEndPoints,powerMedian(:,v), ...
        powerMedian(:,v)-powerLo(:,v),powerHi(:,v)-powerMedian(:,v), ...
        'k.','LineWidth',1.0,'CapSize',4,'HandleVisibility','off');
end
set(ax,'YScale','log');xticklabels(ax,{'$J=0$','$J=0.65$'});
set(ax,'TickLabelInterpreter','latex');
ylabel(ax,'on-chip input power per ring (W)');
title(ax,'(b) Precision and residual-Kerr scales','FontWeight','normal');
grid(ax,'on');box(ax,'on');
legend(ax,bars,{'precision extrapolation','$|K|\bar n/\kappa=0.1$ boundary'}, ...
    'Interpreter','latex','Location','southoutside','Box','off','FontSize',10.2);
set(findall(fig,'Type','axes'),'FontName','Arial','FontSize',11.5,'LineWidth',.9);
exportgraphics(fig,fullfile(scriptDir,'FigS_PhotonPrecision_20260811.pdf'), ...
    'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'FigS_PhotonPrecision_20260811.png'), ...
    'Resolution',300);close(fig);
fprintf('DYNAMIC_PHOTON_KERR_PLOT_PASS offsets=%d\n',numel(unique(raw.offset)));
