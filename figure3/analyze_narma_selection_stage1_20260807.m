%% Aggregate the frozen validation-only K/J selection bank.

clear; clc; close all;
scriptDir = fileparts(mfilename('fullpath'));
configFile = fullfile(scriptDir, 'configs', ...
    'narma_revision_protocol_20260807.json');
protocol = jsondecode(fileread(configFile));
offsets = protocol.selection_offsets(:);
Kexpected = protocol.selection_stage_1.k_values(:);
Jexpected = protocol.selection_stage_1.j_values(:).';

nSeeds = numel(offsets);
nK = numel(Kexpected);
nJ = numel(Jexpected);
valNRMSE = nan(nSeeds, nK, nJ);
lambdaBest = nan(nSeeds, nK, nJ);
datasetSeeds = nan(nSeeds, 1);

for s = 1:nSeeds
    tag = sprintf('SelectionStage1Full_Index%02d_Offset%04d_20260807', ...
        s, offsets(s));
    prefix = fullfile(scriptDir, ...
        ['Fig3_KerrReservoir_NARMA10_Reproducible_' tag]);
    summaryFile = [prefix '_summary.mat'];
    csvFile = [prefix '_JSweep_summary.csv'];
    assert(isfile(summaryFile), 'Missing selection summary: %s', summaryFile);
    assert(isfile(csvFile), 'Missing selection CSV: %s', csvFile);

    S = load(summaryFile, 'cfg', 'datasetSeed', 'results');
    T = readtable(csvFile);
    assert(strcmp(S.cfg.protocolMode, 'selection') && ~S.cfg.evaluateTest);
    assert(S.cfg.seedOffset == offsets(s));
    assert(S.cfg.nPC == protocol.primary_endpoint.n_pc);
    assert(isequal(S.cfg.tapDelays(:), protocol.primary_endpoint.tap_delays(:)));
    assert(all(isnan(S.results.JSweep.NRMSE), 'all'));
    assert(all(isnan(T.testNRMSE)) && all(isnan(T.R2true)));
    assert(all(isfinite(T.valNRMSE)));
    assert(isequal(S.results.JSweep.K(:), Kexpected));
    assert(isequal(S.results.JSweep.J(:).', Jexpected));

    valNRMSE(s,:,:) = S.results.JSweep.valNRMSE;
    lambdaBest(s,:,:) = S.results.JSweep.lambdaBest;
    datasetSeeds(s) = S.datasetSeed;
end

selectionIndex = repelem((1:nSeeds).', nK*nJ);
seedOffset = repelem(offsets, nK*nJ);
datasetSeed = repelem(datasetSeeds, nK*nJ);
K = repmat(repelem(Kexpected, nJ), nSeeds, 1);
J = repmat(repmat(Jexpected(:), nK, 1), nSeeds, 1);
validationNRMSE = reshape(permute(valNRMSE, [3 2 1]), [], 1);
ridgeLambda = reshape(permute(lambdaBest, [3 2 1]), [], 1);
rawTable = table(selectionIndex, seedOffset, datasetSeed, K, J, ...
    validationNRMSE, ridgeLambda);
rawFile = fullfile(scriptDir, 'NARMASelectionStage1_Raw_20260807.csv');
writetable(rawTable, rawFile);

meanValidationNRMSE = nan(nK*nJ,1);
sdValidationNRMSE = nan(nK*nJ,1);
medianValidationNRMSE = nan(nK*nJ,1);
q25ValidationNRMSE = nan(nK*nJ,1);
q75ValidationNRMSE = nan(nK*nJ,1);
Ksummary = nan(nK*nJ,1);
Jsummary = nan(nK*nJ,1);
row = 0;
for q = 1:nK
    for m = 1:nJ
        row = row + 1;
        values = valNRMSE(:,q,m);
        Ksummary(row) = Kexpected(q);
        Jsummary(row) = Jexpected(m);
        meanValidationNRMSE(row) = mean(values);
        sdValidationNRMSE(row) = std(values,0);
        medianValidationNRMSE(row) = median(values);
        quartiles = prctile(values, [25 75]);
        q25ValidationNRMSE(row) = quartiles(1);
        q75ValidationNRMSE(row) = quartiles(2);
    end
end

summaryTable = table(Ksummary, Jsummary, meanValidationNRMSE, ...
    sdValidationNRMSE, medianValidationNRMSE, q25ValidationNRMSE, ...
    q75ValidationNRMSE);
summaryFile = fullfile(scriptDir, 'NARMASelectionStage1_Summary_20260807.csv');
writetable(summaryTable, summaryFile);

minimumMean = min(meanValidationNRMSE);
eligible = find(meanValidationNRMSE <= ...
    minimumMean + protocol.selection_rule.absolute_tie_tolerance);
tieTable = table(eligible, abs(Ksummary(eligible)), Jsummary(eligible), ...
    meanValidationNRMSE(eligible), 'VariableNames', ...
    {'row','absK','J','meanValidationNRMSE'});
tieTable = sortrows(tieTable, {'absK','J','meanValidationNRMSE'});
selectedRow = tieTable.row(1);

rankTable = table((1:height(summaryTable)).', meanValidationNRMSE, ...
    abs(Ksummary), Jsummary, 'VariableNames', {'row','mean','absK','J'});
rankTable = sortrows(rankTable, {'mean','absK','J'});
topRows = rankTable.row(1:min(2,height(rankTable)));

digest = java.security.MessageDigest.getInstance('SHA-256');
hashBytes = typecast(digest.digest(uint8(fileread(configFile))), 'uint8');
configHash = lower(reshape(dec2hex(hashBytes, 2).', 1, []));

selectionResult.status = 'stage_1_complete';
selectionResult.protocol_config_sha256 = configHash;
selectionResult.selection_seed_count = nSeeds;
selectionResult.test_metrics_evaluated = false;
selectionResult.selected.K = Ksummary(selectedRow);
selectionResult.selected.J = Jsummary(selectedRow);
selectionResult.selected.mean_validation_nrmse = meanValidationNRMSE(selectedRow);
selectionResult.selected.sd_validation_nrmse = sdValidationNRMSE(selectedRow);
selectionResult.tie_tolerance = protocol.selection_rule.absolute_tie_tolerance;
for k = 1:numel(topRows)
    selectionResult.stage_2_candidates(k).K = Ksummary(topRows(k));
    selectionResult.stage_2_candidates(k).J = Jsummary(topRows(k));
    selectionResult.stage_2_candidates(k).mean_validation_nrmse = ...
        meanValidationNRMSE(topRows(k));
end
jsonFile = fullfile(scriptDir, 'configs', ...
    'narma_selection_stage1_result_20260807.json');
fid = fopen(jsonFile, 'w');
assert(fid >= 0, 'Could not open stage-1 result JSON.');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', jsonencode(selectionResult, PrettyPrint=true));

fig = figure('Color','w','Units','inches','Position',[1 1 8.2 3.8]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
ax1 = nexttile;
imagesc(Jexpected, Kexpected, reshape(meanValidationNRMSE, [nJ nK]).');
axis xy;
xlabel('coupling $J$','Interpreter','latex');
ylabel('Kerr coefficient $K$','Interpreter','latex');
title('(a) Mean validation NRMSE','Interpreter','latex');
colorbar;
hold on;
plot(Jsummary(selectedRow), Ksummary(selectedRow), 'wp', ...
    'MarkerFaceColor','k','MarkerSize',11);
ax1.Toolbar.Visible = 'off';

ax2 = nexttile;
hold on;
colors = lines(nK*nJ);
for r = 1:(nK*nJ)
    q = find(Kexpected == Ksummary(r), 1);
    m = find(Jexpected == Jsummary(r), 1);
    x = r + 0.08*linspace(-1,1,nSeeds).';
    scatter(x, valNRMSE(:,q,m), 20, colors(r,:), 'filled', ...
        'MarkerFaceAlpha',0.65);
    plot([r-0.25 r+0.25], meanValidationNRMSE(r)*[1 1], ...
        'Color',colors(r,:), 'LineWidth',1.5);
end
xticks(1:(nK*nJ));
labels = compose('K=%g, J=%g', Ksummary, Jsummary);
xticklabels(labels);
xtickangle(45);
ylabel('validation NRMSE','Interpreter','latex');
title('(b) Selection realizations','Interpreter','latex');
grid on; box on;
ax2.Toolbar.Visible = 'off';
set(findall(fig,'-property','FontSize'),'FontSize',10.5);

pdfFile = fullfile(scriptDir, 'NARMASelectionStage1_20260807.pdf');
pngFile = fullfile(scriptDir, 'NARMASelectionStage1_20260807.png');
exportgraphics(fig, pdfFile, 'ContentType','vector');
exportgraphics(fig, pngFile, 'Resolution',300);
close(fig);

fprintf('NARMA10 selection stage 1 PASS: %d validation-only seeds.\n', nSeeds);
fprintf('Selected K = %.4g, J = %.4g, mean validation NRMSE = %.6f.\n', ...
    selectionResult.selected.K, selectionResult.selected.J, ...
    selectionResult.selected.mean_validation_nrmse);
fprintf('No test metrics were evaluated.\n');
