%% Plot the centered-feature photon and residual-Kerr audit.

clear;close all;clc;scriptDir=fileparts(mfilename('fullpath'));
T=readtable(fullfile(scriptDir,'DynamicPhotonKerrThermalAudit_20260812.csv'));
assert(height(T)==2 && all(isfinite(T.requiredPowerMedianPca_W)));
counts=[T.carrierEffectivePhotons T.medianRawDynamicEffectivePhotons ...
    T.medianPcaDynamicEffectivePhotons];
kerrLimitedPower=T.requiredPowerMedianPca_W.*(.1./T.kerrShiftOverKappa);

blue=[.14 .42 .70];red=[.82 .25 .18];gray=[.55 .57 .60];
fig=figure('Color','w','Visible','off','Units','inches','Position',[1 1 7.1 4.75]);
tiledlayout(1,2,'Padding','compact','TileSpacing','loose');
ax=nexttile;bars=bar(ax,counts);bars(1).FaceColor=gray;bars(2).FaceColor=blue;bars(3).FaceColor=red;
set(ax,'YScale','log');xticklabels(ax,{'$J=0$','$J=0.65$'});set(ax,'TickLabelInterpreter','latex');
ylabel(ax,'effective photons at reference power');title(ax,'(a) Carrier versus dynamic signal','FontWeight','normal');
grid(ax,'on');box(ax,'on');
legend(ax,bars,{'total occupation','centered raw','centered PCA'}, ...
    'Location','southoutside','Box','off','FontSize',10.2);
ax=nexttile;bars=bar(ax,[T.requiredPowerMedianPca_W kerrLimitedPower]);bars(1).FaceColor=red;bars(2).FaceColor=blue;
set(ax,'YScale','log');xticklabels(ax,{'$J=0$','$J=0.65$'});set(ax,'TickLabelInterpreter','latex');
ylabel(ax,'on-chip input power per ring (W)');title(ax,'(b) Precision and residual-Kerr scales','FontWeight','normal');
grid(ax,'on');box(ax,'on');
legend(ax,bars,{'precision extrapolation','$|K|\bar n/\kappa=0.1$ boundary'}, ...
    'Interpreter','latex','Location','southoutside','Box','off','FontSize',10.2);
set(findall(fig,'Type','axes'),'FontName','Arial','FontSize',11.5,'LineWidth',.9);
exportgraphics(fig,fullfile(scriptDir,'FigS_PhotonPrecision_20260811.pdf'),'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'FigS_PhotonPrecision_20260811.png'),'Resolution',300);close(fig);
fprintf('DYNAMIC_PHOTON_KERR_PLOT_PASS\n');
