%% Analyze the 30 prospectively frozen locked NARMA10 pairs without retuning.

clear; clc; close all;
scriptDir = fileparts(mfilename('fullpath'));
lockedFile = fullfile(scriptDir, 'configs', 'narma_locked_config_20260810.json');
locked = jsondecode(fileread(lockedFile));
comparisonFile = fullfile(scriptDir,'configs', ...
    'narma_locked_comparison_config_20260810.json');
comparison = jsondecode(fileread(comparisonFile));
nPairs = locked.paired_realizations;
modes = cellstr(string(locked.feature_modes));
nModes = numel(modes);
nRows = nPairs*2*nModes;

lockedIndex = nan(nRows,1);
seedOffset = nan(nRows,1);
featureMode = strings(nRows,1);
K = nan(nRows,1);
J = nan(nRows,1);
valNRMSE = nan(nRows,1);
testNRMSE = nan(nRows,1);
R2true = nan(nRows,1);
lambdaBest = nan(nRows,1);
cursor = 0;

for q = 1:nPairs
    offset = locked.locked_test_offsets(q);
    tag = sprintf('LockedTest_Index%02d_Offset%04d_20260810', q, offset);
    prefix = fullfile(scriptDir, ...
        ['Fig3_KerrReservoir_NARMA10_Reproducible_' tag]);
    csvFile = [prefix '_FeatureBudgetVariants_summary.csv'];
    manifestFile = [prefix '_manifest.json'];
    assert(isfile(csvFile) && isfile(manifestFile), ...
        'Missing locked outputs for index %d.', q);
    C = readtable(csvFile, 'TextType','string','Delimiter',',');
    C = C(C.variant == "Budget351",:);
    manifest = jsondecode(fileread(manifestFile));
    assert(height(C) == 2*nModes && manifest.locked_index == q && ...
        manifest.seed_offset == offset);
    assert(all(isfinite(C.testNRMSE)));
    for r = 1:height(C)
        modelRows = [comparison.physical_models.requested_budget] == 351 & ...
            abs([comparison.physical_models.J]-C.J(r)) < 1e-14 & ...
            strcmp({comparison.physical_models.feature_mode},char(C.featureMode(r)));
        expectedLambda = comparison.physical_models(modelRows).ridge_lambda;
        lambdaTolerance = 1e-12*max(1,abs(expectedLambda));
        assert(sum(modelRows) == 1 && ...
            abs(C.lambdaBest(r)-expectedLambda) <= lambdaTolerance);
    end
    for r = 1:height(C)
        cursor = cursor + 1;
        lockedIndex(cursor) = q;
        seedOffset(cursor) = offset;
        featureMode(cursor) = C.featureMode(r);
        K(cursor) = C.K(r);
        J(cursor) = C.J(r);
        valNRMSE(cursor) = C.valNRMSE(r);
        testNRMSE(cursor) = C.testNRMSE(r);
        R2true(cursor) = C.R2true(r);
        lambdaBest(cursor) = C.lambdaBest(r);
    end
end
assert(cursor == nRows);

raw = table(lockedIndex, seedOffset, featureMode, K, J, valNRMSE, ...
    testNRMSE, R2true, lambdaBest);
writetable(raw, fullfile(scriptDir, 'NARMALockedPairs_Raw_20260810.csv'));

rng(20260810, 'twister');
nBoot = locked.bootstrap_resamples;
nPermutation = 100000;
stats = repmat(struct(), nModes, 1);
summaryRows = cell(nModes,1);
controlByMode = nan(nPairs,nModes);
interventionByMode = nan(nPairs,nModes);

for m = 1:nModes
    mode = string(modes{m});
    control = nan(nPairs,1);
    intervention = nan(nPairs,1);
    for q = 1:nPairs
        common = raw.lockedIndex == q & raw.featureMode == mode;
        rowControl = common & abs(raw.J-locked.J_control) < 1e-14;
        rowIntervention = common & abs(raw.J-locked.J_intervention) < 1e-14;
        assert(sum(rowControl) == 1 && sum(rowIntervention) == 1);
        control(q) = raw.testNRMSE(rowControl);
        intervention(q) = raw.testNRMSE(rowIntervention);
    end
    difference = control-intervention;
    bootIndex = randi(nPairs,nBoot,nPairs);
    bootMean = mean(difference(bootIndex),2);
    bootMedian = median(difference(bootIndex),2);
    signs = 2*(rand(nPermutation,nPairs) >= 0.5)-1;
    permutedMean = mean(signs.*difference.',2);
    permutationP = (1+sum(abs(permutedMean) >= abs(mean(difference)))) / ...
        (nPermutation+1);
    nonzero = difference(abs(difference) > eps(max(abs(difference))));
    nNonzero = numel(nonzero);
    nPositive = sum(nonzero > 0);
    lowerTail = min(nPositive,nNonzero-nPositive);
    signProbability = 0;
    for k = 0:lowerTail
        signProbability = signProbability+nchoosek(nNonzero,k)/2^nNonzero;
    end
    signTestP = min(1,2*signProbability);

    stats(m).feature_mode = modes{m};
    stats(m).n_pairs = nPairs;
    stats(m).control_mean = mean(control);
    stats(m).control_sd = std(control);
    stats(m).control_median = median(control);
    stats(m).control_iqr = iqr(control);
    stats(m).intervention_mean = mean(intervention);
    stats(m).intervention_sd = std(intervention);
    stats(m).intervention_median = median(intervention);
    stats(m).intervention_iqr = iqr(intervention);
    stats(m).paired_difference_mean = mean(difference);
    stats(m).paired_difference_mean_ci95 = prctile(bootMean,[2.5 97.5]);
    stats(m).paired_difference_median = median(difference);
    stats(m).paired_difference_median_ci95 = prctile(bootMedian,[2.5 97.5]);
    stats(m).cohen_dz = mean(difference)/std(difference);
    stats(m).improvement_fraction = mean(difference > 0);
    stats(m).permutation_p_two_sided = permutationP;
    stats(m).sign_test_p_two_sided = signTestP;
    stats(m).minimum_improvement_fraction_met = ...
        stats(m).improvement_fraction >= locked.minimum_improvement_fraction;
    summaryRows{m} = stats(m);
    controlByMode(:,m) = control;
    interventionByMode(:,m) = intervention;
end

result.schema_version = 1;
result.status = 'locked_test_complete';
result.analysis_date = '2026-08-10';
result.locked_config_sha256 = sha256File(lockedFile);
result.comparison_config_sha256 = sha256File(comparisonFile);
result.no_retuning = true;
result.requested_coefficient_budget = 351;
result.bootstrap_resamples = nBoot;
result.permutation_resamples = nPermutation;
result.primary_feature_mode = locked.primary_feature_mode;
result.secondary_feature_mode = locked.secondary_feature_mode;
result.statistics = stats;
resultFile = fullfile(scriptDir, 'configs', ...
    'narma_locked_test_result_20260810.json');
fid = fopen(resultFile, 'w');
assert(fid >= 0, 'Could not write locked-test result.');
fprintf(fid, '%s\n', jsonencode(result, PrettyPrint=true));
fclose(fid);

summaryTable = struct2table(vertcat(summaryRows{:}));
writetable(summaryTable, fullfile(scriptDir, ...
    'NARMALockedPairs_Statistics_20260810.csv'));

fig = figure('Color','w','Units','inches','Position',[1 1 7.2 3.35]);
layout = tiledlayout(1,nModes,'TileSpacing','compact','Padding','compact');
for m = 1:nModes
    ax = nexttile(layout,m);
    hold(ax,'on');
    for q = 1:nPairs
        plot(ax,[1 2],[controlByMode(q,m),interventionByMode(q,m)], ...
            '-', 'Color',[0.72 0.72 0.72], 'LineWidth',0.65);
    end
    scatter(ax,ones(nPairs,1),controlByMode(:,m),24,[0.18 0.39 0.66], ...
        'filled','MarkerFaceAlpha',0.78);
    scatter(ax,2*ones(nPairs,1),interventionByMode(:,m),24,[0.78 0.25 0.20], ...
        'filled','MarkerFaceAlpha',0.78);
    plot(ax,[1 2],[mean(controlByMode(:,m)),mean(interventionByMode(:,m))], ...
        '-o','Color','k','LineWidth',2,'MarkerFaceColor','w','MarkerSize',7);
    xlim(ax,[0.72 2.28]);
    xticks(ax,[1 2]);
    xticklabels(ax,{'J = 0','J = J^*'});
    ylabel(ax,'Test NRMSE');
    displayTitles={'quadrature readout','intensity readout'};
    title(ax,displayTitles{m},'FontWeight','normal');
    grid(ax,'on');
    ax.FontSize = 10;
    ax.LineWidth = 0.9;
end
exportgraphics(fig, fullfile(scriptDir,'NARMALockedPairs_20260810.pdf'), ...
    'ContentType','vector');
exportgraphics(fig, fullfile(scriptDir,'NARMALockedPairs_20260810.png'), ...
    'Resolution',300);
fprintf('LOCKED_ANALYSIS_PASS n=%d modes=%d\n', nPairs, nModes);

function digest = sha256File(path)
    engine = java.security.MessageDigest.getInstance('SHA-256');
    bytes = typecast(engine.digest(uint8(fileread(path))), 'uint8');
    digest = lower(reshape(dec2hex(bytes,2).',1,[]));
end
