%% analyze_J_sweep_multiseed_20260720.m
% Consolidate the full J sweep and the fixed J=0 versus J=0.80 seed pairs.
% Seed offset 0 selected J=0.80; offsets 1--4 are independent checks.

clear;
close all;
clc;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

lowSweepFile = fullfile(scriptDir, ...
    'Fig3_KerrReservoir_NARMA10_Reproducible_JSweepFull_20260720_JSweep_summary.csv');
highSweepFile = fullfile(scriptDir, ...
    'Fig3_KerrReservoir_NARMA10_Reproducible_JSweepHighJFull_20260720_JSweep_summary.csv');

assert(isfile(lowSweepFile), 'Missing low-J sweep: %s', lowSweepFile);
assert(isfile(highSweepFile), 'Missing high-J extension: %s', highSweepFile);

Tlow = readtable(lowSweepFile);
Thigh = readtable(highSweepFile);
tol = 1e-12;

Tlinear = [Tlow(abs(Tlow.K) < tol,:); Thigh(abs(Thigh.K) < tol,:)];
Tkerr = Tlow(abs(Tlow.K + 1.62) < tol,:);
Tlinear = sortrows(Tlinear, 'J');
Tkerr = sortrows(Tkerr, 'J');
Tcombined = sortrows([Tlinear; Tkerr], {'K','J'});

combinedFile = fullfile(scriptDir, 'Fig3_JSweep_Combined_20260720.csv');
writetable(Tcombined, combinedFile);

seedOffsets = (0:4).';
datasetSeeds = nan(size(seedOffsets));
nSeeds = numel(seedOffsets);
valJ0 = nan(nSeeds,1);
testJ0 = nan(nSeeds,1);
r2J0 = nan(nSeeds,1);
valJ08 = nan(nSeeds,1);
testJ08 = nan(nSeeds,1);
r2J08 = nan(nSeeds,1);
inputOnlyNRMSE = nan(nSeeds,1);
maxAbsBetaJ0 = nan(nSeeds,1);
maxAbsXvirtJ0 = nan(nSeeds,1);
maxAbsBetaJ08 = nan(nSeeds,1);
maxAbsXvirtJ08 = nan(nSeeds,1);

for q = 1:nSeeds
    offset = seedOffsets(q);
    if offset == 0
        T0 = Tlinear;
        summaryMatFile = fullfile(scriptDir, ...
            'Fig3_KerrReservoir_NARMA10_Reproducible_JSweepHighJFull_20260720_summary.mat');
    else
        seedFile = fullfile(scriptDir, sprintf([ ...
            'Fig3_KerrReservoir_NARMA10_Reproducible_' ...
            'JTargetSeed%02d_20260720_JSweep_summary.csv'], offset));
        assert(isfile(seedFile), 'Missing targeted seed file: %s', seedFile);
        T0 = readtable(seedFile);
        summaryMatFile = fullfile(scriptDir, sprintf([ ...
            'Fig3_KerrReservoir_NARMA10_Reproducible_' ...
            'JTargetSeed%02d_20260720_summary.mat'], offset));
    end

    rowJ0 = find(abs(T0.K) < tol & abs(T0.J) < tol, 1);
    rowJ08 = find(abs(T0.K) < tol & abs(T0.J - 0.80) < tol, 1);
    assert(~isempty(rowJ0) && ~isempty(rowJ08), ...
        'Seed offset %d does not contain both J values.', offset);

    valJ0(q) = T0.valNRMSE(rowJ0);
    testJ0(q) = T0.testNRMSE(rowJ0);
    r2J0(q) = T0.R2true(rowJ0);
    maxAbsBetaJ0(q) = T0.maxAbsBeta(rowJ0);
    maxAbsXvirtJ0(q) = T0.maxAbsXvirt(rowJ0);
    valJ08(q) = T0.valNRMSE(rowJ08);
    testJ08(q) = T0.testNRMSE(rowJ08);
    r2J08(q) = T0.R2true(rowJ08);
    maxAbsBetaJ08(q) = T0.maxAbsBeta(rowJ08);
    maxAbsXvirtJ08(q) = T0.maxAbsXvirt(rowJ08);

    assert(isfile(summaryMatFile), 'Missing seed summary MAT: %s', summaryMatFile);
    seedSummary = load(summaryMatFile, 'results', 'datasetSeed');
    assert(isfield(seedSummary.results, 'inputOnly'), ...
        'Input-only baseline missing from %s.', summaryMatFile);
    assert(isfield(seedSummary, 'datasetSeed'), ...
        'Effective dataset seed missing from %s.', summaryMatFile);
    datasetSeeds(q) = seedSummary.datasetSeed;
    inputOnlyNRMSE(q) = seedSummary.results.inputOnly.NRMSE;
end

absoluteGain = testJ0 - testJ08;
relativeGainPct = 100*absoluteGain./testJ0;
allImproved = testJ08 < testJ0;
Tseeds = table(seedOffsets, datasetSeeds, valJ0, testJ0, r2J0, ...
    valJ08, testJ08, r2J08, inputOnlyNRMSE, maxAbsBetaJ0, maxAbsXvirtJ0, ...
    maxAbsBetaJ08, maxAbsXvirtJ08, absoluteGain, relativeGainPct, allImproved, ...
    'VariableNames', {'seedOffset','datasetSeed','valNRMSE_J0', ...
    'testNRMSE_J0','R2true_J0','valNRMSE_J08','testNRMSE_J08', ...
    'R2true_J08','inputOnlyNRMSE','maxAbsBeta_J0','maxAbsXvirt_J0', ...
    'maxAbsBeta_J08','maxAbsXvirt_J08','absoluteNRMSEGain', ...
    'relativeGainPct','couplingImproved'});

seedFile = fullfile(scriptDir, 'Fig3_JSweep_MultiSeed_20260720.csv');
writetable(Tseeds, seedFile);

cohort = ["all_5_descriptive"; "offsets_1_to_4_confirmation"];
useRows = {true(nSeeds,1), seedOffsets > 0};
tcrit95 = [2.77644510519780; 3.18244630528426];
n = nan(2,1);
meanJ0 = nan(2,1);
sdJ0 = nan(2,1);
meanJ08 = nan(2,1);
sdJ08 = nan(2,1);
meanR2J0 = nan(2,1);
sdR2J0 = nan(2,1);
meanR2J08 = nan(2,1);
sdR2J08 = nan(2,1);
meanInputOnly = nan(2,1);
sdInputOnly = nan(2,1);
meanAbsoluteGain = nan(2,1);
sdAbsoluteGain = nan(2,1);
ci95GainLow = nan(2,1);
ci95GainHigh = nan(2,1);
meanRelativeGainPct = nan(2,1);
pairedT = nan(2,1);
pairedPTwoSided = nan(2,1);
allPairsImprove = false(2,1);

for q = 1:2
    keep = useRows{q};
    gains = absoluteGain(keep);
    n(q) = sum(keep);
    meanJ0(q) = mean(testJ0(keep));
    sdJ0(q) = std(testJ0(keep), 0);
    meanJ08(q) = mean(testJ08(keep));
    sdJ08(q) = std(testJ08(keep), 0);
    meanR2J0(q) = mean(r2J0(keep));
    sdR2J0(q) = std(r2J0(keep), 0);
    meanR2J08(q) = mean(r2J08(keep));
    sdR2J08(q) = std(r2J08(keep), 0);
    meanInputOnly(q) = mean(inputOnlyNRMSE(keep));
    sdInputOnly(q) = std(inputOnlyNRMSE(keep), 0);
    meanAbsoluteGain(q) = mean(gains);
    sdAbsoluteGain(q) = std(gains, 0);
    gainSE = sdAbsoluteGain(q)/sqrt(n(q));
    ci95GainLow(q) = meanAbsoluteGain(q) - tcrit95(q)*gainSE;
    ci95GainHigh(q) = meanAbsoluteGain(q) + tcrit95(q)*gainSE;
    meanRelativeGainPct(q) = mean(relativeGainPct(keep));
    pairedT(q) = meanAbsoluteGain(q)/gainSE;
    degreesFreedom = n(q) - 1;
    pairedPTwoSided(q) = betainc(degreesFreedom/(degreesFreedom + pairedT(q)^2), ...
        degreesFreedom/2, 0.5);
    allPairsImprove(q) = all(allImproved(keep));
end

Tstats = table(cohort, n, meanJ0, sdJ0, meanJ08, sdJ08, ...
    meanR2J0, sdR2J0, meanR2J08, sdR2J08, meanInputOnly, sdInputOnly, ...
    meanAbsoluteGain, sdAbsoluteGain, ci95GainLow, ci95GainHigh, ...
    meanRelativeGainPct, pairedT, pairedPTwoSided, allPairsImprove);
statsCsvFile = fullfile(scriptDir, 'Fig3_JSweep_MultiSeed_20260720_stats.csv');
writetable(Tstats, statsCsvFile);

fprintf('\n=== Fixed coupling comparison ===\n');
disp(Tseeds);
fprintf('All five (descriptive): J=0 %.4f +/- %.4f; J=0.8 %.4f +/- %.4f.\n', ...
    meanJ0(1), sdJ0(1), meanJ08(1), sdJ08(1));
fprintf('All five true R2: J=0 %.4f +/- %.4f; J=0.8 %.4f +/- %.4f.\n', ...
    meanR2J0(1), sdR2J0(1), meanR2J08(1), sdR2J08(1));
fprintf('All-five input-only baseline: %.4f +/- %.4f.\n', ...
    meanInputOnly(1), sdInputOnly(1));
fprintf('Independent offsets 1--4: mean gain %.4f (95%% paired t CI %.4f to %.4f), p=%.4g.\n', ...
    meanAbsoluteGain(2), ci95GainLow(2), ci95GainHigh(2), pairedPTwoSided(2));

reportFile = fullfile(scriptDir, 'Fig3_JSweep_MultiSeed_20260720_analysis.md');
fid = fopen(reportFile, 'w');
assert(fid >= 0, 'Could not open analysis report for writing.');
cleanupFile = onCleanup(@() fclose(fid));
fprintf(fid, '# NARMA10 coherent-coupling analysis (2026-07-20)\n\n');
fprintf(fid, '## Protocol\n\n');
fprintf(fid, ['The K=0 coupling value J=0.80 was selected from seed offset 0 after ' ...
    'a sweep over J=0--1.10. It was then held fixed for offsets 1--4. Within ' ...
    'each offset, J=0 and J=0.80 share the NARMA input, mask, disorder, split, ' ...
    'PCA dimension, and ridge-selection protocol.\n\n']);
fprintf(fid, '## Results\n\n');
fprintf(fid, ['Across all five displayed pairs, mean test NRMSE was %.4f +/- %.4f ' ...
    'for J=0 and %.4f +/- %.4f for J=0.80 (sample SD). The input-only tapped ' ...
    'baseline was %.4f +/- %.4f, and all %d/%d coupling pairs improved.\n\n'], ...
    meanJ0(1), sdJ0(1), meanJ08(1), sdJ08(1), meanInputOnly(1), ...
    sdInputOnly(1), sum(allImproved), nSeeds);
fprintf(fid, ['Mean true test R2 was %.4f +/- %.4f at J=0 and %.4f +/- %.4f ' ...
    'at J=0.80.\n\n'], meanR2J0(1), sdR2J0(1), meanR2J08(1), sdR2J08(1));
fprintf(fid, ['For the four independent confirmation offsets, the mean absolute ' ...
    'NRMSE reduction was %.4f (95%% paired t interval %.4f to %.4f), corresponding ' ...
    'to a mean relative reduction of %.2f%%. The paired t statistic was %.3f ' ...
    '(two-sided p=%.4g).\n\n'], meanAbsoluteGain(2), ci95GainLow(2), ...
    ci95GainHigh(2), meanRelativeGainPct(2), pairedT(2), pairedPTwoSided(2));
fprintf(fid, ['Across the five runs, max |beta| ranged from %.3g to %.3g at J=0 ' ...
    'and from %.3g to %.3g at J=0.80. The corresponding maximum raw-feature ' ...
    'magnitudes ranged from %.3g to %.3g and from %.3g to %.3g, respectively. ' ...
    'These finite-value diagnostics are consistent with coupling suppressing ' ...
    'isolated near-resonant responses, but they do not by themselves prove the ' ...
    'mechanism of the NRMSE gain.\n\n'], min(maxAbsBetaJ0), max(maxAbsBetaJ0), ...
    min(maxAbsBetaJ08), max(maxAbsBetaJ08), min(maxAbsXvirtJ0), ...
    max(maxAbsXvirtJ0), min(maxAbsXvirtJ08), max(maxAbsXvirtJ08));
fprintf(fid, '## Interpretation boundary\n\n');
fprintf(fid, ['This comparison supports coherent intermode coupling as a useful ' ...
    'resource for NARMA10 in the tested architecture. It does not establish ' ...
    'quantum advantage, universality, or Kerr-enhanced temporal prediction. At ' ...
    'K=0 there is no amplitude-dependent Kerr term; nonlinear input-output ' ...
    'processing can still arise from input-dependent coefficients and nonlinear ' ...
    'measured observables. The synchronization role of Kerr is a ' ...
    'separate claim supported by the response and locking maps.\n']);
clear cleanupFile;

blue = [0.10 0.36 0.62];
red = [0.72 0.22 0.20];
gray = [0.70 0.70 0.70];
dark = [0.12 0.12 0.12];

fig = figure('Color','w', 'Units','inches', 'Position',[1 1 7.2 3.7]);
tiles = tiledlayout(fig, 1, 2, 'Padding','compact', 'TileSpacing','compact');

ax1 = nexttile(tiles, 1);
hold(ax1, 'on');
plot(ax1, Tlinear.J, Tlinear.testNRMSE, '-o', 'Color',blue, ...
    'MarkerFaceColor',blue, 'MarkerSize',4.5, 'LineWidth',1.4);
plot(ax1, Tkerr.J, Tkerr.testNRMSE, '-s', 'Color',red, ...
    'MarkerFaceColor','w', 'MarkerSize',4.5, 'LineWidth',1.4);
xline(ax1, 0.80, ':', 'Color',[0.35 0.35 0.35], 'LineWidth',1.0, ...
    'HandleVisibility','off');
xlabel(ax1, 'Coherent coupling, $J$', 'Interpreter','latex');
ylabel(ax1, 'Test NRMSE', 'Interpreter','latex');
title(ax1, '(a) Coupling sweep', 'FontWeight','normal');
legend(ax1, {'$K=0$','$K=-1.62$'}, 'Interpreter','latex', ...
    'Location','northeast', 'Box','off');
xlim(ax1, [0 1.12]);
ylim(ax1, [0.23 0.38]);
grid(ax1, 'on');
box(ax1, 'on');

ax2 = nexttile(tiles, 2);
hold(ax2, 'on');
for q = 2:nSeeds
    plot(ax2, [1 2], [testJ0(q) testJ08(q)], '-', 'Color',gray, ...
        'LineWidth',0.9, 'HandleVisibility','off');
end
selectionHandle = plot(ax2, [1 2], [testJ0(1) testJ08(1)], '--o', ...
    'Color',red, 'MarkerFaceColor','w', 'MarkerSize',4.5, 'LineWidth',1.1);
scatter(ax2, ones(nSeeds-1,1), testJ0(2:end), 30, dark, 'filled', ...
    'MarkerFaceAlpha',0.85, 'HandleVisibility','off');
scatter(ax2, 2*ones(nSeeds-1,1), testJ08(2:end), 30, blue, 'filled', ...
    'MarkerFaceAlpha',0.85, 'HandleVisibility','off');
confirmationHandle = errorbar(ax2, [1 2], [meanJ0(2) meanJ08(2)], ...
    [sdJ0(2) sdJ08(2)], ...
    'k-', 'LineWidth',1.6, 'CapSize',8, 'Marker','diamond', ...
    'MarkerFaceColor','w', 'MarkerSize',6);
set(ax2, 'XTick',[1 2], 'XTickLabel',{'$J=0$','$J=0.80$'}, ...
    'TickLabelInterpreter','latex');
xlim(ax2, [0.65 2.35]);
ylim(ax2, [0.23 0.34]);
ylabel(ax2, 'Test NRMSE', 'Interpreter','latex');
title(ax2, '(b) Fixed-$J$ confirmation', 'Interpreter','latex', ...
    'FontWeight','normal');
legend(ax2, [selectionHandle confirmationHandle], ...
    {'selection run','confirmation mean $\pm$ SD'}, ...
    'Interpreter','latex', 'Location','southwest', 'Box','off');
grid(ax2, 'on');
box(ax2, 'on');

set([ax1 ax2], 'FontName','Arial', 'FontSize',11, 'LineWidth',0.8);

pdfFile = fullfile(scriptDir, 'Fig3_JSweep_MultiSeed_20260720.pdf');
pngFile = fullfile(scriptDir, 'Fig3_JSweep_MultiSeed_20260720.png');
exportgraphics(fig, pdfFile, 'ContentType','vector');
exportgraphics(fig, pngFile, 'Resolution',300);
close(fig);

fprintf('Saved %s\n', combinedFile);
fprintf('Saved %s\n', seedFile);
fprintf('Saved %s\n', statsCsvFile);
fprintf('Saved %s\n', reportFile);
fprintf('Saved %s and %s\n', pdfFile, pngFile);
