%% Aggregate the full validation-only cached stage-2 architecture selection.

clear; clc; close all;
scriptDir = fileparts(mfilename('fullpath'));
trajectoryPlan = readtable(fullfile(scriptDir, ...
    'NARMASelectionStage2_TrajectoryPlan_20260810.csv'), 'TextType','string');
readoutPlan = readtable(fullfile(scriptDir, ...
    'NARMASelectionStage2_ReadoutPlan_20260810.csv'), 'TextType','string');
protocol = jsondecode(fileread(fullfile(scriptDir, 'configs', ...
    'narma_revision_protocol_20260807.json')));

nTrajectories = height(trajectoryPlan);
nVariants = height(readoutPlan);
assert(nTrajectories == 120 && nVariants == 480);

firstTrajectory = trajectoryPlan(1,:);
firstTag = sprintf('SelectionStage2Full_Trajectory%03d_Offset%04d_20260810', ...
    1, firstTrajectory.seedOffset);
firstSummaryFile = fullfile(scriptDir, ...
    ['Fig3_KerrReservoir_NARMA10_Reproducible_' firstTag '_summary.mat']);
assert(isfile(firstSummaryFile), 'Missing first stage-2 summary: %s', firstSummaryFile);
firstSummary = load(firstSummaryFile, 'cfg');
lambdaGrid = firstSummary.cfg.lambdaGrid(:);
nLambda = numel(lambdaGrid);

trajectoryId = nan(nVariants,1);
selectionIndex = nan(nVariants,1);
seedOffset = nan(nVariants,1);
datasetSeed = nan(nVariants,1);
K = nan(nVariants,1);
J = nan(nVariants,1);
inputGainScale = nan(nVariants,1);
stepsPerSample = nan(nVariants,1);
virtualSamples = nan(nVariants,1);
nDelayBlocks = nan(nVariants,1);
nPC = nan(nVariants,1);
readoutCoefficients = nan(nVariants,1);
validationNRMSE = nan(nVariants,1);
ridgeLambda = nan(nVariants,1);
validationCurves = nan(nVariants,nLambda);

cursor = 0;
for t = 1:nTrajectories
    trajectory = trajectoryPlan(t,:);
    tag = sprintf('SelectionStage2Full_Trajectory%03d_Offset%04d_20260810', ...
        t, trajectory.seedOffset);
    prefix = fullfile(scriptDir, ...
        ['Fig3_KerrReservoir_NARMA10_Reproducible_' tag]);
    summaryFile = [prefix '_summary.mat'];
    csvFile = [prefix '_ReadoutVariants_summary.csv'];
    assert(isfile(summaryFile), 'Missing stage-2 summary: %s', summaryFile);
    assert(isfile(csvFile), 'Missing stage-2 readout CSV: %s', csvFile);
    S = load(summaryFile, 'cfg', 'P', 'datasetSeed', 'results');
    C = readtable(csvFile, 'TextType','string');
    expected = readoutPlan(readoutPlan.readoutTrajectoryId == t,:);

    assert(strcmp(S.cfg.protocolMode, 'selection') && ~S.cfg.evaluateTest);
    assert(S.cfg.seedOffset == trajectory.seedOffset);
    assert(abs(S.P.K-trajectory.K) < 1e-14);
    assert(abs(S.P.J0-trajectory.J) < 1e-14);
    assert(abs(S.cfg.inputGainScale-trajectory.inputGainScale) < 1e-14);
    assert(S.cfg.stepsPerSample == trajectory.stepsPerSample);
    assert(height(C) == 4 && height(expected) == 4);
    assert(all(isfinite(C.valNRMSE)) && all(isnan(C.testNRMSE)));
    assert(all(isnan(C.R2true)) && all(isnan(C.R2corr)));
    assert(all(C.readoutCoefficients <= protocol.primary_endpoint.coefficient_budget));
    assert(isequal(C.nPCRequested, expected.nPC));
    assert(isequal(C.readoutCoefficients, ...
        expected.actualCoefficientsIncludingBias));
    assert(isequal(S.cfg.lambdaGrid(:), lambdaGrid));

    for q = 1:height(C)
        cursor = cursor + 1;
        trajectoryId(cursor) = t;
        selectionIndex(cursor) = trajectory.selectionIndex;
        seedOffset(cursor) = trajectory.seedOffset;
        datasetSeed(cursor) = S.datasetSeed;
        K(cursor) = trajectory.K;
        J(cursor) = trajectory.J;
        inputGainScale(cursor) = trajectory.inputGainScale;
        stepsPerSample(cursor) = trajectory.stepsPerSample;
        virtualSamples(cursor) = expected.actualVirtualSamples(q);
        nDelayBlocks(cursor) = expected.nDelayBlocks(q);
        nPC(cursor) = expected.nPC(q);
        readoutCoefficients(cursor) = expected.actualCoefficientsIncludingBias(q);
        validationNRMSE(cursor) = C.valNRMSE(q);
        ridgeLambda(cursor) = C.lambdaBest(q);
        curve = S.results.readoutVariants.readout{q}.valCurve(:).';
        assert(numel(curve) == size(validationCurves,2) && all(isfinite(curve)));
        validationCurves(cursor,:) = curve;
    end
end
assert(cursor == nVariants);

rawTable = table(trajectoryId, selectionIndex, seedOffset, datasetSeed, K, J, ...
    inputGainScale, stepsPerSample, virtualSamples, nDelayBlocks, nPC, ...
    readoutCoefficients, validationNRMSE, ridgeLambda);
rawFile = fullfile(scriptDir, 'NARMASelectionStage2_Raw_20260810.csv');
writetable(rawTable, rawFile);

configColumns = {'K','J','inputGainScale','stepsPerSample','virtualSamples', ...
    'nDelayBlocks','nPC','readoutCoefficients'};
configs = unique(rawTable(:,configColumns), 'rows', 'stable');
seedIndices = unique(rawTable.selectionIndex, 'stable');
nSeeds = numel(seedIndices);
nConfigs = height(configs);
assert(nSeeds == 10 && nConfigs == 48);

validation = nan(nSeeds,nConfigs);
curveBySeedConfig = nan(nSeeds,nConfigs,size(validationCurves,2));
for s = 1:nSeeds
    for c = 1:nConfigs
        rows = rawTable.selectionIndex == seedIndices(s) & ...
            abs(rawTable.K-configs.K(c)) < 1e-14 & ...
            abs(rawTable.J-configs.J(c)) < 1e-14 & ...
            abs(rawTable.inputGainScale-configs.inputGainScale(c)) < 1e-14 & ...
            rawTable.stepsPerSample == configs.stepsPerSample(c) & ...
            rawTable.virtualSamples == configs.virtualSamples(c) & ...
            rawTable.nDelayBlocks == configs.nDelayBlocks(c);
        assert(sum(rows) == 1);
        rawRow = find(rows);
        curveBySeedConfig(s,c,:) = validationCurves(rawRow,:);
    end
end
assert(all(isfinite(curveBySeedConfig), 'all'));

globalLambdaIndex = nan(nConfigs,1);
globalLambda = nan(nConfigs,1);
for c = 1:nConfigs
    meanCurve = squeeze(mean(curveBySeedConfig(:,c,:),1));
    [~,globalLambdaIndex(c)] = min(meanCurve);
    globalLambda(c) = lambdaGrid(globalLambdaIndex(c));
    validation(:,c) = curveBySeedConfig(:,c,globalLambdaIndex(c));
end
assert(all(isfinite(validation), 'all'));

meanValidationNRMSE = mean(validation,1).';
sdValidationNRMSE = std(validation,0,1).';
medianValidationNRMSE = median(validation,1).';
q25ValidationNRMSE = prctile(validation,25,1).';
q75ValidationNRMSE = prctile(validation,75,1).';
summaryTable = [configs table(globalLambda, meanValidationNRMSE, sdValidationNRMSE, ...
    medianValidationNRMSE, q25ValidationNRMSE, q75ValidationNRMSE)];
summaryFile = fullfile(scriptDir, 'NARMASelectionStage2_Summary_20260810.csv');
writetable(summaryTable, summaryFile);

tolerance = protocol.selection_rule.absolute_tie_tolerance;
eligible = find(meanValidationNRMSE <= min(meanValidationNRMSE)+tolerance);
choices = table(eligible, configs.readoutCoefficients(eligible), ...
    configs.virtualSamples(eligible), abs(configs.K(eligible)), ...
    configs.J(eligible), meanValidationNRMSE(eligible), ...
    'VariableNames', {'row','coefficients','virtualSamples','absK','J','mean'});
choices = sortrows(choices, ...
    {'coefficients','virtualSamples','absK','J','mean'});
selectedRow = choices.row(1);

looSelected = nan(nSeeds,1);
for s = 1:nSeeds
    means = mean(validation(setdiff(1:nSeeds,s),:),1).';
    eligibleLoo = find(means <= min(means)+tolerance);
    candidates = table(eligibleLoo, configs.readoutCoefficients(eligibleLoo), ...
        configs.virtualSamples(eligibleLoo), abs(configs.K(eligibleLoo)), ...
        configs.J(eligibleLoo), means(eligibleLoo), ...
        'VariableNames', {'row','coefficients','virtualSamples','absK','J','mean'});
    candidates = sortrows(candidates, ...
        {'coefficients','virtualSamples','absK','J','mean'});
    looSelected(s) = candidates.row(1);
end
looWinnerFraction = mean(looSelected == selectedRow);

result.status = 'stage_2_complete';
result.test_metrics_evaluated = false;
result.selection_seed_count = nSeeds;
result.tie_tolerance = tolerance;
result.leave_one_out_winner_fraction = looWinnerFraction;
result.selected.K = configs.K(selectedRow);
result.selected.J = configs.J(selectedRow);
result.selected.input_gain_scale = configs.inputGainScale(selectedRow);
result.selected.steps_per_sample = configs.stepsPerSample(selectedRow);
result.selected.virtual_samples = configs.virtualSamples(selectedRow);
result.selected.n_delay_blocks = configs.nDelayBlocks(selectedRow);
result.selected.n_pc = configs.nPC(selectedRow);
result.selected.readout_coefficients_including_bias = ...
    configs.readoutCoefficients(selectedRow);
result.selected.ridge_lambda = globalLambda(selectedRow);
result.selected.mean_validation_nrmse = meanValidationNRMSE(selectedRow);
result.selected.sd_validation_nrmse = sdValidationNRMSE(selectedRow);
resultFile = fullfile(scriptDir, 'configs', ...
    'narma_selection_stage2_result_20260810.json');
fid = fopen(resultFile, 'w');
assert(fid >= 0, 'Could not open stage-2 result JSON.');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', jsonencode(result, PrettyPrint=true));

ranked = sortrows(summaryTable, ...
    {'meanValidationNRMSE','readoutCoefficients','virtualSamples'});
top = ranked(1:12,:);
fig = figure('Color','w','Units','inches','Position',[1 1 8.2 4.3]);
hold on;
for c = 1:height(top)
    original = find(abs(configs.K-top.K(c)) < 1e-14 & ...
        abs(configs.J-top.J(c)) < 1e-14 & ...
        abs(configs.inputGainScale-top.inputGainScale(c)) < 1e-14 & ...
        configs.stepsPerSample == top.stepsPerSample(c) & ...
        configs.virtualSamples == top.virtualSamples(c) & ...
        configs.nDelayBlocks == top.nDelayBlocks(c), 1);
    scatter(c+0.08*linspace(-1,1,nSeeds), validation(:,original), 22, ...
        'filled','MarkerFaceAlpha',0.55);
    plot([c-0.25 c+0.25], top.meanValidationNRMSE(c)*[1 1], ...
        'k-','LineWidth',1.4);
end
labels = compose('K=%g, g=%g, s=%d, v=%d, t=%d', top.K, ...
    top.inputGainScale, top.stepsPerSample, top.virtualSamples, top.nDelayBlocks);
xticks(1:height(top));
xticklabels(labels);
xtickangle(55);
ylabel('validation NRMSE','Interpreter','latex');
title('Stage-2 validation-only architecture selection','Interpreter','latex');
grid on; box on;
ax = gca; ax.Toolbar.Visible = 'off';
set(findall(fig,'-property','FontSize'),'FontSize',10.5);
exportgraphics(fig, fullfile(scriptDir,'NARMASelectionStage2_20260810.pdf'), ...
    'ContentType','vector');
exportgraphics(fig, fullfile(scriptDir,'NARMASelectionStage2_20260810.png'), ...
    'Resolution',300);
close(fig);

fprintf('Stage-2 architecture selection PASS: %d seeds, %d configurations.\n', ...
    nSeeds, nConfigs);
fprintf(['Selected K=%g, J=%g, gain=%.3g, steps=%d, virtual=%d, taps=%d, ' ...
    'PCs=%d, coefficients=%d.\n'], result.selected.K, result.selected.J, ...
    result.selected.input_gain_scale, result.selected.steps_per_sample, ...
    result.selected.virtual_samples, result.selected.n_delay_blocks, ...
    result.selected.n_pc, result.selected.readout_coefficients_including_bias);
fprintf('Mean validation NRMSE %.6f | test metrics evaluated: false.\n', ...
    result.selected.mean_validation_nrmse);
