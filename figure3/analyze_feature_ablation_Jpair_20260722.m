%% analyze_feature_ablation_Jpair_20260722.m
% Consolidate paper-grade feature-block ablations at K=0 for J=0 and J=0.8.

clear;
close all;
clc;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

prefixJ0 = fullfile(scriptDir, ...
    'Fig3_KerrReservoir_NARMA10_Reproducible_FeatureAblationK0J00Full_20260722');
prefixJ08 = fullfile(scriptDir, ...
    'Fig3_KerrReservoir_NARMA10_Reproducible_FeatureAblationK0J08Full_20260722');
csvJ0 = [prefixJ0 '_FeatureAblations_summary.csv'];
csvJ08 = [prefixJ08 '_FeatureAblations_summary.csv'];
matJ0 = [prefixJ0 '_summary.mat'];
matJ08 = [prefixJ08 '_summary.mat'];

requiredFiles = {csvJ0, csvJ08, matJ0, matJ08};
for q = 1:numel(requiredFiles)
    assert(isfile(requiredFiles{q}), 'Missing required file: %s', requiredFiles{q});
end

T0 = readtable(csvJ0, 'TextType','string');
T08 = readtable(csvJ08, 'TextType','string');
modes = ["linear_features"; "number_features"; "number_nonlinear"; ...
    "phase_coherence"; "all_features"];
labels = ["Quadratures"; "Number statistics"; "Nonlinear number"; ...
    "Phase/coherence"; "All observables"];
nModes = numel(modes);

assert(height(T0) == nModes && height(T08) == nModes, ...
    'Expected exactly five feature rows per physical case.');
assert(all(abs(T0.K) < 1e-12) && all(abs(T0.J) < 1e-12), ...
    'The J=0 table contains an unexpected physical case.');
assert(all(abs(T08.K) < 1e-12) && all(abs(T08.J - 0.8) < 1e-12), ...
    'The J=0.8 table contains an unexpected physical case.');

valJ0 = nan(nModes,1);
testJ0 = nan(nModes,1);
r2J0 = nan(nModes,1);
lambdaJ0 = nan(nModes,1);
valJ08 = nan(nModes,1);
testJ08 = nan(nModes,1);
r2J08 = nan(nModes,1);
lambdaJ08 = nan(nModes,1);
rawFeatureDim = nan(nModes,1);

for q = 1:nModes
    row0 = find(T0.featureMode == modes(q));
    row08 = find(T08.featureMode == modes(q));
    assert(isscalar(row0) && isscalar(row08), ...
        'Feature mode %s must appear once in each table.', modes(q));
    valJ0(q) = T0.valNRMSE(row0);
    testJ0(q) = T0.testNRMSE(row0);
    r2J0(q) = T0.R2true(row0);
    lambdaJ0(q) = T0.lambdaBest(row0);
    valJ08(q) = T08.valNRMSE(row08);
    testJ08(q) = T08.testNRMSE(row08);
    r2J08(q) = T08.R2true(row08);
    lambdaJ08(q) = T08.lambdaBest(row08);
    rawFeatureDim(q) = T0.rawFeatureDim(row0);
    assert(rawFeatureDim(q) == T08.rawFeatureDim(row08), ...
        'Raw dimension differs across J for mode %s.', modes(q));
end

allMetrics = [valJ0; testJ0; r2J0; lambdaJ0; valJ08; testJ08; r2J08; lambdaJ08];
assert(all(isfinite(allMetrics)), 'A feature-ablation metric is NaN or Inf.');

S0 = load(matJ0, 'results', 'datasetSeed', 'cfg', 'P');
S08 = load(matJ08, 'results', 'datasetSeed', 'cfg', 'P');
assert(S0.datasetSeed == S08.datasetSeed, 'The two cases used different datasets.');
assert(isfield(S0.results, 'inputOnly') && isfield(S08.results, 'inputOnly'), ...
    'Input-only baseline missing from a summary MAT file.');
inputOnlyJ0 = S0.results.inputOnly.NRMSE;
inputOnlyJ08 = S08.results.inputOnly.NRMSE;
assert(abs(inputOnlyJ0 - inputOnlyJ08) < 1e-12, ...
    'Input-only baselines differ despite a paired protocol.');
inputOnlyNRMSE = 0.5*(inputOnlyJ0 + inputOnlyJ08);

allIndex = find(modes == "all_features");
assert(abs(testJ0(allIndex) - S0.results.main.NRMSE) < 1e-12, ...
    'J=0 all-features row does not match the main result.');
assert(abs(testJ08(allIndex) - S08.results.main.NRMSE) < 1e-12, ...
    'J=0.8 all-features row does not match the main result.');

referenceFile = fullfile(scriptDir, 'Fig3_JSweep_Combined_20260720.csv');
if isfile(referenceFile)
    Tref = readtable(referenceFile);
    refJ0 = find(abs(Tref.K) < 1e-12 & abs(Tref.J) < 1e-12, 1);
    refJ08 = find(abs(Tref.K) < 1e-12 & abs(Tref.J - 0.8) < 1e-12, 1);
    assert(~isempty(refJ0) && ~isempty(refJ08), ...
        'The reference J sweep lacks J=0 or J=0.8 at K=0.');
    assert(abs(Tref.testNRMSE(refJ0) - testJ0(allIndex)) < 1e-10 && ...
        abs(Tref.testNRMSE(refJ08) - testJ08(allIndex)) < 1e-10, ...
        'All-features rerun does not reproduce the prior J sweep.');
end

absoluteGain = testJ0 - testJ08;
relativeGainPct = 100*absoluteGain./testJ0;
couplingImproved = absoluteGain > 0;
Tcombined = table(modes, labels, rawFeatureDim, valJ0, testJ0, r2J0, ...
    lambdaJ0, valJ08, testJ08, r2J08, lambdaJ08, absoluteGain, ...
    relativeGainPct, couplingImproved, ...
    'VariableNames', {'featureMode','featureLabel','rawFeatureDim', ...
    'valNRMSE_J0','testNRMSE_J0','R2true_J0','lambdaBest_J0', ...
    'valNRMSE_J08','testNRMSE_J08','R2true_J08','lambdaBest_J08', ...
    'absoluteNRMSEGain','relativeGainPct','couplingImproved'});

combinedFile = fullfile(scriptDir, 'Fig3_FeatureAblation_JPair_20260722.csv');
writetable(Tcombined, combinedFile);

[bestJ0, bestJ0Index] = min(testJ0);
[bestJ08, bestJ08Index] = min(testJ08);
[largestGain, largestGainIndex] = max(absoluteGain);

fprintf('\n=== K=0 feature-block coupling diagnostic ===\n');
disp(Tcombined);
fprintf('Input-only tapped baseline: %.4f\n', inputOnlyNRMSE);
fprintf('Best J=0 block: %s (%.4f)\n', labels(bestJ0Index), bestJ0);
fprintf('Best J=0.8 block: %s (%.4f)\n', labels(bestJ08Index), bestJ08);
fprintf('Largest coupling gain: %s, %.4f (%.1f%%)\n', ...
    labels(largestGainIndex), largestGain, relativeGainPct(largestGainIndex));

reportFile = fullfile(scriptDir, 'Fig3_FeatureAblation_JPair_20260722_analysis.md');
fid = fopen(reportFile, 'w');
assert(fid >= 0, 'Could not open analysis report for writing.');
cleanupFile = onCleanup(@() fclose(fid));
fprintf(fid, '# NARMA10 feature-block coupling diagnostic (2026-07-22)\n\n');
fprintf(fid, '## Protocol\n\n');
fprintf(fid, ['Paper-grade runs compare K=0, J=0 with K=0, J=0.80 on dataset ' ...
    'seed %d. The cases share the input, masks, reservoir and copy disorder, ' ...
    'split, PCA dimension, tapped delays, and ridge grid. Each feature block ' ...
    'receives its own train-fitted PCA projection and validation-selected ridge ' ...
    'readout. Cached complex trajectories are reused across blocks; a smoke test ' ...
    'verified exact equality with direct feature-by-feature simulation.\n\n'], ...
    S0.datasetSeed);
fprintf(fid, '## Results\n\n');
fprintf(fid, ['The input-only tapped baseline is %.4f. At J=0, the best block is ' ...
    '%s with test NRMSE %.4f. At J=0.80, the best block is %s with %.4f. ' ...
    'Finite coupling improves %d/%d blocks. The largest absolute reduction is ' ...
    '%.4f (%.1f%%) for %s.\n\n'], inputOnlyNRMSE, labels(bestJ0Index), ...
    bestJ0, labels(bestJ08Index), bestJ08, sum(couplingImproved), nModes, ...
    largestGain, relativeGainPct(largestGainIndex), labels(largestGainIndex));
fprintf(fid, ['Quadrature-only test NRMSE changes from %.4f to %.4f, while the ' ...
    'all-observables result changes from %.4f to %.4f. Thus the coupling ' ...
    'diagnostic can distinguish a gain already visible in directly measured ' ...
    'field quadratures from gains that require nonlinear number or phase/coherence ' ...
    'post-processing.\n\n'], testJ0(1), testJ08(1), ...
    testJ0(allIndex), testJ08(allIndex));
fprintf(fid, '## Interpretation boundary\n\n');
fprintf(fid, ['The feature-block comparison is descriptive for the selection ' ...
    'realization and should not be assigned a feature-specific p-value. The ' ...
    'all-observables J=0 versus J=0.80 advantage has separate confirmation on ' ...
    'four independently reseeded pairs. These data support coherent multimode ' ...
    'mixing as a resource in this pipeline; they do not establish quantum ' ...
    'advantage or a causal role for Kerr-induced synchronization cells.\n']);
clear cleanupFile;

blue = [0.10 0.36 0.62];
red = [0.72 0.22 0.20];
dark = [0.18 0.18 0.18];
lightGray = [0.68 0.68 0.68];
x = (1:nModes).';
shortLabels = {'Quadratures','Number stats.','Nonlinear number', ...
    'Phase/coh.','All'};

fig = figure('Color','w', 'Visible','off', 'Units','inches', ...
    'Position',[1 1 7.2 3.30]);
tiles = tiledlayout(fig, 1, 2, 'Padding','compact', 'TileSpacing','compact');

ax1 = nexttile(tiles, 1);
hold(ax1, 'on');
plot(ax1, x, testJ0, '-o', 'Color',dark, 'MarkerFaceColor','w', ...
    'MarkerSize',5, 'LineWidth',1.35);
plot(ax1, x, testJ08, '-s', 'Color',blue, 'MarkerFaceColor',blue, ...
    'MarkerSize',5, 'LineWidth',1.35);
yline(ax1, inputOnlyNRMSE, '--', 'Color',red, 'LineWidth',1.0);
set(ax1, 'XTick',x, 'XTickLabel',shortLabels);
xtickangle(ax1, 22);
xlim(ax1, [0.65 nModes+0.35]);
yValues = [testJ0; testJ08; inputOnlyNRMSE];
yMargin = max(0.02, 0.08*(max(yValues)-min(yValues)));
ylim(ax1, [max(0,min(yValues)-yMargin), max(yValues)+yMargin]);
ylabel(ax1, 'Test NRMSE', 'Interpreter','latex');
title(ax1, '(a) Observable-block performance', 'FontWeight','normal');
legend(ax1, {'$J=0$','$J=0.80$','input-only'}, ...
    'Interpreter','latex', 'Location','best', 'Box','off');
grid(ax1, 'on');
box(ax1, 'on');

ax2 = nexttile(tiles, 2);
hold(ax2, 'on');
b = bar(ax2, x, absoluteGain, 0.68, 'FaceColor','flat', ...
    'EdgeColor','none');
colors = repmat(blue, nModes, 1);
colors(~couplingImproved,:) = repmat(red, sum(~couplingImproved), 1);
b.CData = colors;
yline(ax2, 0, '-', 'Color',lightGray, 'LineWidth',0.9);
set(ax2, 'XTick',x, 'XTickLabel',shortLabels);
xtickangle(ax2, 22);
xlim(ax2, [0.45 nModes+0.55]);
yExtent = max(abs(absoluteGain));
if yExtent < 1e-12
    yExtent = 0.01;
end
ylim(ax2, [-1.30*yExtent, 1.30*yExtent]);
for q = 1:nModes
    if absoluteGain(q) >= 0
        verticalAlignment = 'bottom';
        yText = absoluteGain(q) + 0.04*yExtent;
    else
        verticalAlignment = 'top';
        yText = absoluteGain(q) - 0.04*yExtent;
    end
    text(ax2, x(q), yText, sprintf('%.3f', absoluteGain(q)), ...
        'HorizontalAlignment','center', 'VerticalAlignment',verticalAlignment, ...
        'FontSize',7.5);
end
ylabel(ax2, '$\mathrm{NRMSE}_{J=0}-\mathrm{NRMSE}_{J=0.8}$', ...
    'Interpreter','latex');
title(ax2, '(b) Coupling gain by block', 'FontWeight','normal');
grid(ax2, 'on');
box(ax2, 'on');

set([ax1 ax2], 'FontName','Arial', 'FontSize',8.5, 'LineWidth',0.8);
try
    axtoolbar(ax1, {});
    axtoolbar(ax2, {});
catch
end

pdfFile = fullfile(scriptDir, 'Fig3_FeatureAblation_JPair_20260722.pdf');
pngFile = fullfile(scriptDir, 'Fig3_FeatureAblation_JPair_20260722.png');
exportgraphics(fig, pdfFile, 'ContentType','vector');
exportgraphics(fig, pngFile, 'Resolution',300);
close(fig);

fprintf('Saved %s\n', combinedFile);
fprintf('Saved %s\n', reportFile);
fprintf('Saved %s and %s\n', pdfFile, pngFile);
