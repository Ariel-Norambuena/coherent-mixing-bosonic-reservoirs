%% Freeze global ridge choices for each classical method and budget.

clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
protocol = jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'narma_revision_protocol_20260807.json')));
nSeeds = numel(protocol.selection_offsets);
firstPrefix = fullfile(scriptDir,sprintf( ...
    'BaselineBudgetSelectionFull_Index%02d_Offset%04d_20260810',1, ...
    protocol.selection_offsets(1)));
firstFile = [firstPrefix '_summary.mat'];
assert(isfile(firstFile),'Missing first baseline-budget selection file.');
first = load(firstFile,'cfg','metadata','summaryTable', ...
    'validationCurves','actualCoefficients','inputOrder');
nMethods = numel(first.cfg.methods);
nBudgets = numel(first.cfg.budgets);
nLambda = numel(first.cfg.lambdaGrid);
curves = nan(nSeeds,nMethods,nBudgets,nLambda);

for s = 1:nSeeds
    prefix = fullfile(scriptDir,sprintf( ...
        'BaselineBudgetSelectionFull_Index%02d_Offset%04d_20260810',s, ...
        protocol.selection_offsets(s)));
    S = load([prefix '_summary.mat'],'cfg','metadata','validationCurves', ...
        'actualCoefficients','inputOrder');
    assert(strcmp(S.metadata.protocol_mode,'selection') && ...
        ~S.metadata.test_metrics_evaluated);
    assert(isequal(S.cfg.methods,first.cfg.methods) && ...
        isequal(S.cfg.budgets,first.cfg.budgets) && ...
        isequal(S.actualCoefficients,first.actualCoefficients) && ...
        isequal(S.inputOrder,first.inputOrder));
    curves(s,:,:,:) = S.validationCurves;
end
assert(all(isfinite(curves),'all'));

models = repmat(struct(),nMethods*nBudgets,1);
method = strings(nMethods*nBudgets,1);
requestedBudget = nan(nMethods*nBudgets,1);
actualBudget = nan(nMethods*nBudgets,1);
modelOrder = nan(nMethods*nBudgets,1);
ridgeLambda = nan(nMethods*nBudgets,1);
meanValidationNRMSE = nan(nMethods*nBudgets,1);
sdValidationNRMSE = nan(nMethods*nBudgets,1);
cursor = 0;
for m = 1:nMethods
    for b = 1:nBudgets
        cursor = cursor+1;
        meanCurve = squeeze(mean(curves(:,m,b,:),1));
        [meanValidationNRMSE(cursor),lambdaIndex] = min(meanCurve);
        seedValues = squeeze(curves(:,m,b,lambdaIndex));
        method(cursor) = first.cfg.methods{m};
        requestedBudget(cursor) = first.cfg.budgets(b);
        actualBudget(cursor) = first.actualCoefficients(m,b);
        modelOrder(cursor) = first.inputOrder(m,b);
        ridgeLambda(cursor) = first.cfg.lambdaGrid(lambdaIndex);
        sdValidationNRMSE(cursor) = std(seedValues);
        models(cursor).method = char(method(cursor));
        models(cursor).requested_budget = requestedBudget(cursor);
        models(cursor).actual_coefficients_including_bias = actualBudget(cursor);
        models(cursor).model_order = modelOrder(cursor);
        models(cursor).ridge_lambda = ridgeLambda(cursor);
        models(cursor).mean_validation_nrmse = meanValidationNRMSE(cursor);
        models(cursor).sd_validation_nrmse = sdValidationNRMSE(cursor);
    end
end
summary = table(method,requestedBudget,actualBudget,modelOrder,ridgeLambda, ...
    meanValidationNRMSE,sdValidationNRMSE);
writetable(summary,fullfile(scriptDir, ...
    'NARMABaselineBudgetSelection_Summary_20260810.csv'));
result.schema_version = 1;
result.status = 'baseline_budget_selection_complete';
result.test_metrics_evaluated = false;
result.selection_seed_count = nSeeds;
result.lambda_grid = first.cfg.lambdaGrid;
result.models = models;
outputFile = fullfile(scriptDir,'configs', ...
    'narma_baseline_budget_selected_20260810.json');
assert(~isfile(outputFile),'Collision guard: budget config already frozen.');
fid = fopen(outputFile,'w');assert(fid >= 0);
fprintf(fid,'%s\n',jsonencode(result,PrettyPrint=true));fclose(fid);
fprintf('BASELINE_BUDGET_AGGREGATE_PASS models=%d test=0\n',numel(models));
