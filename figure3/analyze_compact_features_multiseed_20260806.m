%% analyze_compact_features_multiseed_20260806.m
% Consolidate selection and four independent compact-feature confirmations.

clear;
close all;
clc;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

selectionFile = fullfile(scriptDir, 'Fig3_FeatureAblation_JPair_20260722.csv');
assert(isfile(selectionFile), 'Missing selection feature table: %s', selectionFile);
selection = readtable(selectionFile, 'TextType','string');

seedOffsets = (0:4).';
nSeeds = numel(seedOffsets);
modes = ["linear_features"; "number_features"];
labels = ["Quadratures"; "Number statistics"];
nModes = numel(modes);

datasetSeed = nan(nSeeds,1);
testJ0 = nan(nSeeds,nModes);
testJ08 = nan(nSeeds,nModes);
r2J0 = nan(nSeeds,nModes);
r2J08 = nan(nSeeds,nModes);
rawFeatureDim = nan(nSeeds,nModes);

datasetSeed(1) = 132;
for modeIndex = 1:nModes
    row = find(selection.featureMode == modes(modeIndex));
    assert(isscalar(row), 'Selection row missing for %s.', modes(modeIndex));
    testJ0(1,modeIndex) = selection.testNRMSE_J0(row);
    testJ08(1,modeIndex) = selection.testNRMSE_J08(row);
    r2J0(1,modeIndex) = selection.R2true_J0(row);
    r2J08(1,modeIndex) = selection.R2true_J08(row);
    rawFeatureDim(1,modeIndex) = selection.rawFeatureDim(row);
end

for seedIndex = 2:nSeeds
    offset = seedOffsets(seedIndex);
    prefix = fullfile(scriptDir, sprintf([ ...
        'Fig3_KerrReservoir_NARMA10_Reproducible_' ...
        'CompactFeaturesSeed%02d_20260806'], offset));
    csvFile = [prefix '_FeatureAblations_summary.csv'];
    matFile = [prefix '_summary.mat'];
    assert(isfile(csvFile), 'Missing compact-feature CSV: %s', csvFile);
    assert(isfile(matFile), 'Missing compact-feature MAT: %s', matFile);

    seedTable = readtable(csvFile, 'TextType','string');
    assert(height(seedTable) == 4, 'Expected four rows in %s.', csvFile);
    summary = load(matFile, 'datasetSeed');
    datasetSeed(seedIndex) = summary.datasetSeed;

    for modeIndex = 1:nModes
        modeRows = seedTable.featureMode == modes(modeIndex);
        rowJ0 = find(modeRows & abs(seedTable.J) < 1e-12);
        rowJ08 = find(modeRows & abs(seedTable.J - 0.80) < 1e-12);
        assert(isscalar(rowJ0) && isscalar(rowJ08), ...
            'Expected one paired row for %s at offset %d.', modes(modeIndex), offset);
        testJ0(seedIndex,modeIndex) = seedTable.testNRMSE(rowJ0);
        testJ08(seedIndex,modeIndex) = seedTable.testNRMSE(rowJ08);
        r2J0(seedIndex,modeIndex) = seedTable.R2true(rowJ0);
        r2J08(seedIndex,modeIndex) = seedTable.R2true(rowJ08);
        rawFeatureDim(seedIndex,modeIndex) = seedTable.rawFeatureDim(rowJ0);
        assert(rawFeatureDim(seedIndex,modeIndex) == seedTable.rawFeatureDim(rowJ08), ...
            'Raw feature dimension changes within offset %d.', offset);
    end
end

assert(all(isfinite([datasetSeed; testJ0(:); testJ08(:); r2J0(:); r2J08(:)])), ...
    'A compact-feature metric is NaN or Inf.');
assert(all(rawFeatureDim(:,1) == 720) && all(rawFeatureDim(:,2) == 450), ...
    'Unexpected compact-feature dimension.');

absoluteGain = testJ0 - testJ08;
relativeGainPct = 100*absoluteGain./testJ0;
couplingImproved = absoluteGain > 0;
assert(all(couplingImproved(:)), 'At least one compact-feature pair did not improve.');

seedOffsetLong = repelem(seedOffsets,nModes);
datasetSeedLong = repelem(datasetSeed,nModes);
featureMode = repmat(modes,nSeeds,1);
featureLabel = repmat(labels,nSeeds,1);
cohort = repmat("confirmation",nSeeds*nModes,1);
cohort(seedOffsetLong == 0) = "selection";
rawFeatureDimLong = reshape(rawFeatureDim.',[],1);
testJ0Long = reshape(testJ0.',[],1);
testJ08Long = reshape(testJ08.',[],1);
r2J0Long = reshape(r2J0.',[],1);
r2J08Long = reshape(r2J08.',[],1);
absoluteGainLong = reshape(absoluteGain.',[],1);
relativeGainPctLong = reshape(relativeGainPct.',[],1);
couplingImprovedLong = reshape(couplingImproved.',[],1);

Tlong = table(seedOffsetLong,datasetSeedLong,cohort,featureMode,featureLabel, ...
    rawFeatureDimLong,testJ0Long,testJ08Long,r2J0Long,r2J08Long, ...
    absoluteGainLong,relativeGainPctLong,couplingImprovedLong, ...
    'VariableNames', {'seedOffset','datasetSeed','cohort','featureMode', ...
    'featureLabel','rawFeatureDim','testNRMSE_J0','testNRMSE_J08', ...
    'R2true_J0','R2true_J08','absoluteNRMSEGain','relativeGainPct', ...
    'couplingImproved'});
longFile = fullfile(scriptDir, 'Fig3_CompactFeatures_MultiSeed_20260806.csv');
writetable(Tlong,longFile);

confirmationRows = seedOffsets > 0;
comparison = ["coupling_quadratures"; "coupling_number_statistics"; ...
    "number_vs_quadratures_at_J08"];
n = repmat(sum(confirmationRows),3,1);
meanLeft = nan(3,1);
sdLeft = nan(3,1);
meanRight = nan(3,1);
sdRight = nan(3,1);
meanDifference = nan(3,1);
sdDifference = nan(3,1);
ci95DifferenceLow = nan(3,1);
ci95DifferenceHigh = nan(3,1);
pairedT = nan(3,1);
pairedPTwoSided = nan(3,1);
allDifferencesPositive = false(3,1);
tcrit95 = 3.18244630528426;

leftValues = {
    testJ0(confirmationRows,1)
    testJ0(confirmationRows,2)
    testJ08(confirmationRows,1)
    };
rightValues = {
    testJ08(confirmationRows,1)
    testJ08(confirmationRows,2)
    testJ08(confirmationRows,2)
    };

for comparisonIndex = 1:3
    left = leftValues{comparisonIndex};
    right = rightValues{comparisonIndex};
    difference = left - right;
    meanLeft(comparisonIndex) = mean(left);
    sdLeft(comparisonIndex) = std(left,0);
    meanRight(comparisonIndex) = mean(right);
    sdRight(comparisonIndex) = std(right,0);
    meanDifference(comparisonIndex) = mean(difference);
    sdDifference(comparisonIndex) = std(difference,0);
    differenceSE = sdDifference(comparisonIndex)/sqrt(n(comparisonIndex));
    ci95DifferenceLow(comparisonIndex) = ...
        meanDifference(comparisonIndex) - tcrit95*differenceSE;
    ci95DifferenceHigh(comparisonIndex) = ...
        meanDifference(comparisonIndex) + tcrit95*differenceSE;
    pairedT(comparisonIndex) = meanDifference(comparisonIndex)/differenceSE;
    degreesFreedom = n(comparisonIndex)-1;
    pairedPTwoSided(comparisonIndex) = betainc( ...
        degreesFreedom/(degreesFreedom + pairedT(comparisonIndex)^2), ...
        degreesFreedom/2,0.5);
    allDifferencesPositive(comparisonIndex) = all(difference > 0);
end

Tstats = table(comparison,n,meanLeft,sdLeft,meanRight,sdRight, ...
    meanDifference,sdDifference,ci95DifferenceLow,ci95DifferenceHigh, ...
    pairedT,pairedPTwoSided,allDifferencesPositive);
statsFile = fullfile(scriptDir, 'Fig3_CompactFeatures_MultiSeed_20260806_stats.csv');
writetable(Tstats,statsFile);

reportFile = fullfile(scriptDir, 'Fig3_CompactFeatures_MultiSeed_20260806_analysis.md');
fid = fopen(reportFile,'w');
assert(fid >= 0, 'Could not open compact-feature report.');
cleanupFile = onCleanup(@() fclose(fid));
fprintf(fid,'# NARMA10 compact-feature multi-seed analysis (2026-08-06)\n\n');
fprintf(fid,'## Protocol\n\n');
fprintf(fid,['Seed offset 0 is the selection realization. Offsets 1--4 are ' ...
    'independent confirmations with `K=0` and `J=0.80` fixed in advance. ' ...
    'Within each seed and feature block, the `J=0` and `J=0.80` cases share ' ...
    'the dataset, mask, disorder schedule, split, PCA dimension, delays, and ' ...
    'ridge grid. Each feature block receives an independent train-only PCA ' ...
    'projection and validation-selected readout.\n\n']);
fprintf(fid,'## Confirmation results\n\n');
fprintf(fid,['Quadrature test NRMSE changes from `%.4f +/- %.4f` to ' ...
    '`%.4f +/- %.4f` (mean +/- sample SD). The mean paired gain is `%.4f`, ' ...
    'with 95%% interval `[%.4f, %.4f]` and two-sided `p=%.4g`; all four ' ...
    'pairs improve.\n\n'],meanLeft(1),sdLeft(1),meanRight(1),sdRight(1), ...
    meanDifference(1),ci95DifferenceLow(1),ci95DifferenceHigh(1), ...
    pairedPTwoSided(1));
fprintf(fid,['Number-statistics test NRMSE changes from `%.4f +/- %.4f` to ' ...
    '`%.4f +/- %.4f`. The mean paired gain is `%.4f`, with 95%% interval ' ...
    '`[%.4f, %.4f]` and two-sided `p=%.4g`; all four pairs improve.\n\n'], ...
    meanLeft(2),sdLeft(2),meanRight(2),sdRight(2),meanDifference(2), ...
    ci95DifferenceLow(2),ci95DifferenceHigh(2),pairedPTwoSided(2));
fprintf(fid,['At `J=0.80`, number statistics outperform quadratures in all ' ...
    'four confirmation realizations. The mean paired NRMSE advantage is ' ...
    '`%.4f`, with 95%% interval `[%.4f, %.4f]` and two-sided `p=%.4g`.\n\n'], ...
    meanDifference(3),ci95DifferenceLow(3),ci95DifferenceHigh(3), ...
    pairedPTwoSided(3));
fprintf(fid,'## Interpretation boundary\n\n');
fprintf(fid,['The confirmation cohort supports two separate claims in this ' ...
    'fixed NARMA10 pipeline: coherent coupling improves performance even when ' ...
    'only quadratures are measured, and compact intensity statistics provide ' ...
    'a reproducible improvement over quadratures at the coupled point. The ' ...
    'comparison does not establish quantum advantage, universality, or a ' ...
    'necessary role for Kerr dynamics.\n']);
clear cleanupFile;

selectionModes = string(selection.featureLabel);
xSelection = (1:height(selection)).';
shortLabels = {'Quadratures','Number stats.','Nonlinear number','Phase/coh.','All'};
blue = [0.10 0.36 0.62];
green = [0.12 0.52 0.36];
red = [0.72 0.22 0.20];
gray = [0.70 0.70 0.70];
dark = [0.12 0.12 0.12];

fig = figure('Color','w','Visible','off','Units','inches', ...
    'Position',[1 1 7.2 3.8]);
tiles = tiledlayout(fig,1,3,'Padding','compact','TileSpacing','compact');

ax1 = nexttile(tiles,1);
hold(ax1,'on');
plot(ax1,xSelection,selection.testNRMSE_J0,'-o','Color',dark, ...
    'MarkerFaceColor','w','MarkerSize',4.5,'LineWidth',1.2);
plot(ax1,xSelection,selection.testNRMSE_J08,'-s','Color',blue, ...
    'MarkerFaceColor',blue,'MarkerSize',4.5,'LineWidth',1.2);
set(ax1,'XTick',xSelection,'XTickLabel',shortLabels);
xtickangle(ax1,28);
xlim(ax1,[0.65 height(selection)+0.35]);
ylim(ax1,[0.22 0.35]);
ylabel(ax1,'Test NRMSE','Interpreter','latex');
title(ax1,'(a) Selection ablation','FontWeight','normal');
legend(ax1,{'$J=0$','$J=0.80$'},'Interpreter','latex', ...
    'Location','southwest','Box','off');
grid(ax1,'on');
box(ax1,'on');

plotConfirmationPanel(nexttile(tiles,2),testJ0(confirmationRows,1), ...
    testJ08(confirmationRows,1),blue,'(b) Quadratures',gray,dark);
plotConfirmationPanel(nexttile(tiles,3),testJ0(confirmationRows,2), ...
    testJ08(confirmationRows,2),green,'(c) Number statistics',gray,dark);

allAxes = findall(fig,'Type','axes');
set(allAxes,'FontName','Arial','FontSize',10.5,'LineWidth',0.8);
for axisIndex = 1:numel(allAxes)
    try
        axtoolbar(allAxes(axisIndex),{});
    catch
    end
end

pdfFile = fullfile(scriptDir,'Fig3_FeatureAblation_MultiSeed_20260806.pdf');
pngFile = fullfile(scriptDir,'Fig3_FeatureAblation_MultiSeed_20260806.png');
exportgraphics(fig,pdfFile,'ContentType','vector');
exportgraphics(fig,pngFile,'Resolution',300);
close(fig);

fprintf('\n=== Compact-feature confirmation statistics ===\n');
disp(Tstats);
fprintf('Saved %s\n',longFile);
fprintf('Saved %s\n',statsFile);
fprintf('Saved %s\n',reportFile);
fprintf('Saved %s and %s\n',pdfFile,pngFile);

function plotConfirmationPanel(ax,j0,j08,accent,titleText,gray,dark)
hold(ax,'on');
nPairs = numel(j0);
for pairIndex = 1:nPairs
    plot(ax,[1 2],[j0(pairIndex) j08(pairIndex)],'-','Color',gray, ...
        'LineWidth',0.9,'HandleVisibility','off');
end
scatter(ax,ones(nPairs,1),j0,25,dark,'filled','HandleVisibility','off');
scatter(ax,2*ones(nPairs,1),j08,25,accent,'filled','HandleVisibility','off');
errorbar(ax,[1 2],[mean(j0) mean(j08)],[std(j0,0) std(j08,0)], ...
    'k-','LineWidth',1.5,'CapSize',7,'Marker','diamond', ...
    'MarkerFaceColor','w','MarkerSize',5.5);
set(ax,'XTick',[1 2],'XTickLabel',{'$J=0$','$J=0.80$'}, ...
    'TickLabelInterpreter','latex');
xlim(ax,[0.75 2.25]);
ylim(ax,[0.22 0.35]);
title(ax,titleText,'FontWeight','normal');
grid(ax,'on');
box(ax,'on');
end
