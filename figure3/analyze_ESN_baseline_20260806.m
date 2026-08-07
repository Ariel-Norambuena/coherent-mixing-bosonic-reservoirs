%% analyze_ESN_baseline_20260806.m
% Pair the fixed-hyperparameter ESN baseline with compact bosonic results.

clear;
close all;
clc;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

esnFile = fullfile(scriptDir,'Fig3_ESN_NARMA10_Full_20260806_seeds.csv');
physicalFile = fullfile(scriptDir,'Fig3_CompactFeatures_MultiSeed_20260806.csv');
assert(isfile(esnFile),'Missing ESN seed table.');
assert(isfile(physicalFile),'Missing compact-feature seed table.');

esn = readtable(esnFile);
physical = readtable(physicalFile,'TextType','string');
offsets = (1:4).';
nSeeds = numel(offsets);
datasetSeed = nan(nSeeds,1);
esnNRMSE = nan(nSeeds,1);
quadratureNRMSE = nan(nSeeds,1);
numberNRMSE = nan(nSeeds,1);

for q = 1:nSeeds
    esnRow = esn.seedOffset == offsets(q);
    quadratureRow = physical.seedOffset == offsets(q) & ...
        physical.featureMode == "linear_features";
    numberRow = physical.seedOffset == offsets(q) & ...
        physical.featureMode == "number_features";
    assert(nnz(esnRow)==1 && nnz(quadratureRow)==1 && nnz(numberRow)==1, ...
        'Missing paired baseline row at offset %d.',offsets(q));
    datasetSeed(q) = esn.datasetSeed(esnRow);
    assert(datasetSeed(q)==physical.datasetSeed(quadratureRow) && ...
        datasetSeed(q)==physical.datasetSeed(numberRow), ...
        'Dataset seed mismatch at offset %d.',offsets(q));
    esnNRMSE(q) = esn.testNRMSE(esnRow);
    quadratureNRMSE(q) = physical.testNRMSE_J08(quadratureRow);
    numberNRMSE(q) = physical.testNRMSE_J08(numberRow);
end

quadratureMinusESN = quadratureNRMSE-esnNRMSE;
numberMinusESN = numberNRMSE-esnNRMSE;
Tpaired = table(offsets,datasetSeed,esnNRMSE,quadratureNRMSE,numberNRMSE, ...
    quadratureMinusESN,numberMinusESN, ...
    'VariableNames',{'seedOffset','datasetSeed','esnNRMSE', ...
    'quadratureNRMSE','numberNRMSE','quadratureMinusESN','numberMinusESN'});
pairedFile = fullfile(scriptDir,'Fig3_ESN_Baseline_Paired_20260806.csv');
writetable(Tpaired,pairedFile);

method = ["ESN";"Bosonic quadratures";"Bosonic number statistics"];
values = {esnNRMSE;quadratureNRMSE;numberNRMSE};
meanNRMSE = cellfun(@mean,values);
sdNRMSE = cellfun(@(x) std(x,0),values);

comparison = ["quadratures_minus_ESN";"number_statistics_minus_ESN"];
differences = {quadratureMinusESN;numberMinusESN};
meanDifference = cellfun(@mean,differences);
sdDifference = cellfun(@(x) std(x,0),differences);
tcrit95 = 3.18244630528426;
ci95Low = meanDifference-tcrit95*sdDifference/sqrt(nSeeds);
ci95High = meanDifference+tcrit95*sdDifference/sqrt(nSeeds);
pairedT = meanDifference./(sdDifference/sqrt(nSeeds));
pairedP = nan(2,1);
for q = 1:2
    pairedP(q) = betainc(3/(3+pairedT(q)^2),1.5,0.5);
end

TmethodStats = table(method,repmat(nSeeds,3,1),meanNRMSE,sdNRMSE, ...
    'VariableNames',{'method','n','meanTestNRMSE','sdTestNRMSE'});
TcomparisonStats = table(comparison,repmat(nSeeds,2,1),meanDifference, ...
    sdDifference,ci95Low,ci95High,pairedT,pairedP, ...
    'VariableNames',{'comparison','n','meanDifference','sdDifference', ...
    'ci95Low','ci95High','pairedT','pairedPTwoSided'});
writetable(TmethodStats,fullfile(scriptDir,'Fig3_ESN_Baseline_MethodStats_20260806.csv'));
writetable(TcomparisonStats,fullfile(scriptDir,'Fig3_ESN_Baseline_ComparisonStats_20260806.csv'));

reportFile = fullfile(scriptDir,'Fig3_ESN_Baseline_Comparison_20260806_analysis.md');
fid = fopen(reportFile,'w');
assert(fid>=0,'Could not open ESN comparison report.');
cleanupFile = onCleanup(@() fclose(fid));
fprintf(fid,'# Matched ESN comparison (2026-08-06)\n\n');
fprintf(fid,'## Protocol\n\n');
fprintf(fid,['The ESN has 350 recurrent tanh states, matching the number of ' ...
    'retained bosonic principal components. All methods use the same four ' ...
    'confirmation datasets and train/validation/test indices. ESN spectral ' ...
    'radius, leak, and input scaling were selected on offset 0 and fixed for ' ...
    'offsets 1--4. The ESN has no explicit tapped-delay expansion, whereas the ' ...
    'physical readout uses the manuscript delay set. This is therefore a ' ...
    'state-dimension calibration, not a hardware-cost equivalence.\n\n']);
fprintf(fid,'## Results\n\n');
for q = 1:3
    fprintf(fid,'- %s: test NRMSE `%.4f +/- %.4f`.\n', ...
        method(q),meanNRMSE(q),sdNRMSE(q));
end
fprintf(fid,['\nBosonic quadrature minus ESN NRMSE has mean `%.4f`, 95%% paired ' ...
    'interval `[%.4f, %.4f]`, and `p=%.4g`. Number statistics minus ESN has ' ...
    'mean `%.4f`, interval `[%.4f, %.4f]`, and `p=%.4g`. Negative values ' ...
    'favor the bosonic reservoir. Both intervals include zero.\n\n'], ...
    meanDifference(1),ci95Low(1),ci95High(1),pairedP(1), ...
    meanDifference(2),ci95Low(2),ci95High(2),pairedP(2));
fprintf(fid,'## Interpretation boundary\n\n');
fprintf(fid,['The coupled bosonic intensity readout has the lowest mean error ' ...
    'and much smaller sample SD in this four-dataset comparison, but the paired ' ...
    'difference from the ESN is not statistically resolved. One ESN realization ' ...
    'outperforms both physical readouts, while three do not. The appropriate ' ...
    'claim is comparable performance with lower observed variability, not ' ...
    'superiority over classical reservoir computing.\n']);
clear cleanupFile;

colors = [0.18 0.18 0.18;0.10 0.36 0.62;0.12 0.52 0.36];
fig = figure('Color','w','Visible','off','Units','inches','Position',[1 1 7.2 3.7]);
tiles = tiledlayout(fig,1,2,'Padding','compact','TileSpacing','compact');

ax1 = nexttile(tiles,1);
hold(ax1,'on');
plot(ax1,offsets,esnNRMSE,'-o','Color',colors(1,:), ...
    'MarkerFaceColor',colors(1,:),'LineWidth',1.2,'MarkerSize',5);
plot(ax1,offsets,quadratureNRMSE,'-s','Color',colors(2,:), ...
    'MarkerFaceColor','w','LineWidth',1.2,'MarkerSize',5);
plot(ax1,offsets,numberNRMSE,'-d','Color',colors(3,:), ...
    'MarkerFaceColor','w','LineWidth',1.2,'MarkerSize',5);
xlabel(ax1,'Seed offset');
ylabel(ax1,'Test NRMSE','Interpreter','latex');
title(ax1,'(a) Paired datasets','FontWeight','normal');
legend(ax1,{'ESN','Bosonic quadratures','Bosonic intensities'}, ...
    'Location','northwest','Box','off','NumColumns',1);
set(ax1,'XTick',offsets);
ylim(ax1,[0.18 0.39]);
grid(ax1,'on');
box(ax1,'on');

ax2 = nexttile(tiles,2);
hold(ax2,'on');
xMethods = (1:3).';
for methodIndex = 1:3
    xJitter = xMethods(methodIndex)+linspace(-0.06,0.06,nSeeds).';
    scatter(ax2,xJitter,values{methodIndex},24,colors(methodIndex,:), ...
        'filled','MarkerFaceAlpha',0.78,'HandleVisibility','off');
end
errorbar(ax2,xMethods,meanNRMSE,sdNRMSE,'k','LineStyle','none', ...
    'LineWidth',1.4,'CapSize',8,'Marker','diamond','MarkerFaceColor','w', ...
    'MarkerSize',6);
set(ax2,'XTick',xMethods,'XTickLabel',{'ESN','Quadratures','Intensities'});
xtickangle(ax2,18);
ylabel(ax2,'Test NRMSE','Interpreter','latex');
title(ax2,'(b) Confirmation distribution','FontWeight','normal');
xlim(ax2,[0.6 3.4]);
ylim(ax2,[0.18 0.39]);
grid(ax2,'on');
box(ax2,'on');

set([ax1 ax2],'FontName','Arial','FontSize',11,'LineWidth',0.8);
try
    axtoolbar(ax1,{});
    axtoolbar(ax2,{});
catch
end
pdfFile = fullfile(scriptDir,'Fig3_ESN_Baseline_Comparison_20260806.pdf');
pngFile = fullfile(scriptDir,'Fig3_ESN_Baseline_Comparison_20260806.png');
exportgraphics(fig,pdfFile,'ContentType','vector');
exportgraphics(fig,pngFile,'Resolution',300);
close(fig);

fprintf('\n=== ESN baseline comparison ===\n');
disp(TmethodStats);
disp(TcomparisonStats);
fprintf('Saved %s\n',pairedFile);
fprintf('Saved %s\n',reportFile);
fprintf('Saved %s and %s\n',pdfFile,pngFile);
