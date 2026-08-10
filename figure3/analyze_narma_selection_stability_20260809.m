%% Stability diagnostics for the validation-only NARMA10 K/J selection bank.
% This analysis never reads or evaluates test metrics.

clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
rawFile = fullfile(scriptDir, 'NARMASelectionStage1_Raw_20260807.csv');
configFile = fullfile(scriptDir, 'configs', ...
    'narma_revision_protocol_20260807.json');
assert(isfile(rawFile) && isfile(configFile));
T = readtable(rawFile);
protocol = jsondecode(fileread(configFile));
assert(all(isfinite(T.validationNRMSE)));

seedIndices = unique(T.selectionIndex, 'stable');
configs = unique(T(:,{'K','J'}), 'rows', 'stable');
nSeeds = numel(seedIndices);
nConfigs = height(configs);
assert(nSeeds == numel(protocol.selection_offsets));
assert(height(T) == nSeeds*nConfigs);

validation = nan(nSeeds,nConfigs);
for s = 1:nSeeds
    for c = 1:nConfigs
        row = T.selectionIndex == seedIndices(s) & ...
            abs(T.K-configs.K(c)) < 1e-14 & abs(T.J-configs.J(c)) < 1e-14;
        assert(sum(row) == 1);
        validation(s,c) = T.validationNRMSE(row);
    end
end
assert(all(isfinite(validation), 'all'));

tieTolerance = protocol.selection_rule.absolute_tie_tolerance;
omittedSelectionIndex = seedIndices;
selectedK = nan(nSeeds,1);
selectedJ = nan(nSeeds,1);
selectedMeanValidationNRMSE = nan(nSeeds,1);
for s = 1:nSeeds
    keep = setdiff(1:nSeeds, s);
    means = mean(validation(keep,:),1).';
    winner = selectConfiguration(means, configs, tieTolerance);
    selectedK(s) = configs.K(winner);
    selectedJ(s) = configs.J(winner);
    selectedMeanValidationNRMSE(s) = means(winner);
end
looTable = table(omittedSelectionIndex, selectedK, selectedJ, ...
    selectedMeanValidationNRMSE);
looFile = fullfile(scriptDir, ...
    'NARMASelectionStage1_LeaveOneOut_20260809.csv');
writetable(looTable, looFile);

rng(20260809, 'twister');
nBootstrap = 10000;
bootstrapWinner = nan(nBootstrap,1);
for b = 1:nBootstrap
    sampled = randi(nSeeds, nSeeds, 1);
    means = mean(validation(sampled,:),1).';
    bootstrapWinner(b) = selectConfiguration(means, configs, tieTolerance);
end
selectionCount = accumarray(bootstrapWinner, 1, [nConfigs 1]);
selectionFraction = selectionCount/nBootstrap;
bootstrapTable = table(configs.K, configs.J, selectionCount, selectionFraction, ...
    'VariableNames', {'K','J','selectionCount','selectionFraction'});
bootstrapTable = sortrows(bootstrapTable, 'selectionFraction', 'descend');
bootstrapFile = fullfile(scriptDir, ...
    'NARMASelectionStage1_BootstrapWinners_20260809.csv');
writetable(bootstrapTable, bootstrapFile);

gainK = [0; -0.02];
meanGain = nan(2,1);
sdGain = nan(2,1);
medianGain = nan(2,1);
ciLow = nan(2,1);
ciHigh = nan(2,1);
improvedCount = nan(2,1);
improvedFraction = nan(2,1);
exactSignFlipP = nan(2,1);
for q = 1:2
    uncoupled = validation(:, configIndex(configs, gainK(q), 0));
    coupled = validation(:, configIndex(configs, gainK(q), 0.65));
    difference = uncoupled-coupled;
    meanGain(q) = mean(difference);
    sdGain(q) = std(difference,0);
    medianGain(q) = median(difference);
    improvedCount(q) = sum(difference > 0);
    improvedFraction(q) = mean(difference > 0);
    sampled = randi(nSeeds, nSeeds, nBootstrap);
    bootstrapMeans = mean(difference(sampled),1);
    interval = prctile(bootstrapMeans, [2.5 97.5]);
    ciLow(q) = interval(1);
    ciHigh(q) = interval(2);

    signs = dec2bin(0:(2^nSeeds-1))-'0';
    signs(signs == 0) = -1;
    nullMeans = mean(signs.*difference.',2);
    exactSignFlipP(q) = mean(abs(nullMeans) >= abs(meanGain(q))-1e-15);
end
gainTable = table(gainK, meanGain, sdGain, medianGain, ciLow, ciHigh, ...
    improvedCount, improvedFraction, exactSignFlipP);
gainFile = fullfile(scriptDir, ...
    'NARMASelectionStage1_PairedValidationGain_20260809.csv');
writetable(gainTable, gainFile);

fullMeans = mean(validation,1).';
fullWinner = selectConfiguration(fullMeans, configs, tieTolerance);
looSameAsFull = mean(selectedK == configs.K(fullWinner) & ...
    selectedJ == configs.J(fullWinner));

mdFile = fullfile(scriptDir, ...
    'NARMASelectionStage1_Stability_20260809.md');
fid = fopen(mdFile, 'w');
assert(fid >= 0, 'Could not open stability report.');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# NARMA10 validation-selection stability\n\n');
fprintf(fid, 'Status: **PASS**\n\n');
fprintf(fid, ['This report uses only the ten-seed selection bank. It is a ' ...
    'hyperparameter-stability diagnostic, not confirmatory test evidence.\n\n']);
fprintf(fid, '## Leave-one-seed-out selection\n\n');
fprintf(fid, '- Full-bank winner: `K=%g`, `J=%g`.\n', ...
    configs.K(fullWinner), configs.J(fullWinner));
fprintf(fid, '- Same winner after omitting one seed: `%d/%d` (`%.1f%%`).\n\n', ...
    sum(selectedK == configs.K(fullWinner) & selectedJ == configs.J(fullWinner)), ...
    nSeeds, 100*looSameAsFull);
fprintf(fid, '## Seed-bootstrap winner frequencies\n\n');
for c = 1:height(bootstrapTable)
    fprintf(fid, '- `K=%g`, `J=%g`: `%.1f%%`.\n', bootstrapTable.K(c), ...
        bootstrapTable.J(c), 100*bootstrapTable.selectionFraction(c));
end
fprintf(fid, '\n## Paired validation gain for J=0.65 versus J=0\n\n');
for q = 1:height(gainTable)
    fprintf(fid, ['- `K=%g`: mean gain `%.6f`, median `%.6f`, percentile ' ...
        'bootstrap 95%% interval `[%.6f, %.6f]`, improved `%d/%d`, exact ' ...
        'sign-flip `p=%.4g`.\n'], gainTable.gainK(q), gainTable.meanGain(q), ...
        gainTable.medianGain(q), gainTable.ciLow(q), gainTable.ciHigh(q), ...
        gainTable.improvedCount(q), nSeeds, gainTable.exactSignFlipP(q));
end
fprintf(fid, ['\nThe sign-flip values are descriptive because these are selection ' ...
    'data. They must not be reported as locked-test inference.\n']);

fprintf('NARMA10 selection-stability analysis PASS.\n');
fprintf('Leave-one-out full winner frequency: %d/%d.\n', ...
    round(nSeeds*looSameAsFull), nSeeds);
fprintf('Report: %s\n', mdFile);

function index = selectConfiguration(means, configs, tolerance)
    eligible = find(means <= min(means)+tolerance);
    choices = table(eligible, abs(configs.K(eligible)), configs.J(eligible), ...
        means(eligible), 'VariableNames', {'index','absK','J','mean'});
    choices = sortrows(choices, {'absK','J','mean'});
    index = choices.index(1);
end

function index = configIndex(configs, K, J)
    index = find(abs(configs.K-K) < 1e-14 & abs(configs.J-J) < 1e-14, 1);
    assert(~isempty(index), 'Requested K/J configuration is missing.');
end
