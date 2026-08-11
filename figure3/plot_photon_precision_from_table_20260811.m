%% Regenerate the coherent-receiver photon-scaling figure from compact data.

clear; close all; clc;
scriptDir=fileparts(mfilename('fullpath'));
data=readtable(fullfile(scriptDir,'PhotonPrecisionMapping_20260811.csv'), ...
    'TextType','string');
assert(height(data)==6 && numel(unique(data.conditionIndex))==2);
assert(all(isfinite(data.effectiveDetectedPhotons)) && ...
    all(isfinite(data.meanValidationNRMSE)) && ...
    all(isfinite(data.sdValidationNRMSE)));

blue=[.13 .42 .70]; dark=[.20 .20 .20];
conditionIndices=[1 4]; colors=[dark;blue]; markers=['o' 's'];
fig=figure('Color','w','Visible','off','Units','inches', ...
    'Position',[1 1 6.9 3.4]);
ax=axes(fig);hold(ax,'on');box(ax,'on');grid(ax,'on');
for q=1:2
    rows=data(data.conditionIndex==conditionIndices(q),:);
    rows=sortrows(rows,'effectiveDetectedPhotons');
    errorbar(ax,rows.effectiveDetectedPhotons,rows.meanValidationNRMSE, ...
        rows.sdValidationNRMSE/sqrt(30),[markers(q) '-'], ...
        'Color',colors(q,:),'MarkerFaceColor','w','LineWidth',1.35, ...
        'CapSize',4,'DisplayName',char(rows.condition(1)));
end
set(ax,'XScale','log','FontName','Arial','FontSize',10,'LineWidth',.8);
xlabel(ax,'effective detected signal photons per standardized feature');
ylabel(ax,'validation NRMSE after recalibration');
title(ax,'Coherent-receiver photon scaling','FontWeight','normal');
legend(ax,'Location','northeast','Box','off');
exportgraphics(fig,fullfile(scriptDir,'FigS_PhotonPrecision_20260811.pdf'), ...
    'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'FigS_PhotonPrecision_20260811.png'), ...
    'Resolution',300);
close(fig);
fprintf('PHOTON_PRECISION_TABLE_PLOT_PASS\n');
