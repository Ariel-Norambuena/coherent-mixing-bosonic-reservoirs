%% Aggregate validation-only ESN hyperparameter selection across ten seeds.

clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
protocol = jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'narma_revision_protocol_20260807.json')));
nSeeds = numel(protocol.selection_offsets);
firstPrefix = fullfile(scriptDir,sprintf( ...
    'ESNSelectionFull_Index%02d_Offset%04d_20260810',1, ...
    protocol.selection_offsets(1)));
firstSummaryFile = [firstPrefix '_summary.mat'];
assert(isfile(firstSummaryFile),'Missing first ESN selection seed.');
first = load(firstSummaryFile,'cfg','metadata','candidateTable');
candidateTable = first.candidateTable(:,1:5);
lambdaGrid = first.cfg.lambdaGrid(:).';
allCurves = nan(nSeeds,height(candidateTable),numel(lambdaGrid));

for s = 1:nSeeds
    offset = protocol.selection_offsets(s);
    prefix = fullfile(scriptDir,sprintf( ...
        'ESNSelectionFull_Index%02d_Offset%04d_20260810',s,offset));
    summaryFile = [prefix '_summary.mat'];
    assert(isfile(summaryFile),'Missing ESN selection seed %d.',s);
    S = load(summaryFile,'cfg','metadata','candidateTable','valCurves');
    assert(strcmp(S.metadata.protocol_mode,'selection') && ...
        ~S.metadata.test_metrics_evaluated && S.metadata.seed_offset == offset);
    assert(isequal(S.candidateTable(:,1:5),candidateTable));
    assert(isequal(S.cfg.lambdaGrid(:).',lambdaGrid));
    allCurves(s,:,:) = S.valCurves;
end
assert(all(isfinite(allCurves),'all'));
meanCurve = squeeze(mean(allCurves,1));
[bestPerCandidate,bestLambdaIndex] = min(meanCurve,[],2);
[selectedMeanValidation,selectedCandidate] = min(bestPerCandidate);
selectedLambda = lambdaGrid(bestLambdaIndex(selectedCandidate));
seedValidation = squeeze(allCurves(:,selectedCandidate, ...
    bestLambdaIndex(selectedCandidate)));

looCandidate = nan(nSeeds,1);
for s = 1:nSeeds
    looMean = squeeze(mean(allCurves(setdiff(1:nSeeds,s),:,:),1));
    [looBestPerCandidate,~] = min(looMean,[],2);
    [~,looCandidate(s)] = min(looBestPerCandidate);
end

summary = candidateTable;
summary.globalLambda = lambdaGrid(bestLambdaIndex).';
summary.meanValidationNRMSE = bestPerCandidate;
writetable(summary,fullfile(scriptDir,'NARMAESNSelection_Summary_20260810.csv'));

selected = candidateTable(selectedCandidate,:);
result.schema_version = 1;
result.status = 'esn_selection_complete';
result.test_metrics_evaluated = false;
result.selection_seed_count = nSeeds;
result.n_units_simulated = S.cfg.nUnits;
result.tap_delays = S.cfg.tapDelays;
result.primary_measured_states = S.cfg.primaryPC;
result.readout_coefficients_including_bias = ...
    S.metadata.readout_coefficients_including_bias;
result.rho = selected.rho;
result.leak = selected.leak;
result.input_scale = selected.inputScale;
result.sparsity = selected.sparsity;
result.ridge_lambda = selectedLambda;
result.mean_validation_nrmse = selectedMeanValidation;
result.sd_validation_nrmse = std(seedValidation);
result.leave_one_out_winner_fraction = mean(looCandidate == selectedCandidate);
outputFile = fullfile(scriptDir,'configs','narma_esn_selected_20260810.json');
assert(~isfile(outputFile),'Collision guard: ESN selection is already frozen.');
fid = fopen(outputFile,'w');
assert(fid >= 0);
fprintf(fid,'%s\n',jsonencode(result,PrettyPrint=true));
fclose(fid);
fprintf(['ESN_SELECTION_AGGREGATE_PASS rho=%.3g leak=%.3g input=%.3g ' ...
    'sparsity=%.3g lambda=%.3g val=%.6f\n'],result.rho,result.leak, ...
    result.input_scale,result.sparsity,result.ridge_lambda, ...
    result.mean_validation_nrmse);
