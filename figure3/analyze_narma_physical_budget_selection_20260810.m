%% Aggregate validation-only physical budget curves and freeze ridge choices.

clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
protocol = jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'narma_revision_protocol_20260807.json')));
locked = jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'narma_locked_config_20260810.json')));
nSeeds = numel(protocol.selection_offsets);
nCases = 2;
modes = cellstr(string(locked.feature_modes));
nModes = numel(modes);
budgets = protocol.budget_curve.budgets(:).';
nBudgets = numel(budgets);
lambdaGrid = logspace(-6,6,37);
nLambda = numel(lambdaGrid);
curves = nan(nSeeds,nCases,nModes,nBudgets,nLambda);
actualCoefficients = nan(nCases,nModes,nBudgets);
nPC = nan(nCases,nModes,nBudgets);

for s = 1:nSeeds
    offset = protocol.selection_offsets(s);
    prefix = fullfile(scriptDir,sprintf([ ...
        'Fig3_KerrReservoir_NARMA10_Reproducible_' ...
        'PhysicalBudgetSelectionFullV2_Index%02d_Offset%04d_20260810'],s,offset));
    summaryFile = [prefix '_summary.mat'];
    assert(isfile(summaryFile),'Missing physical budget seed %d.',s);
    S = load(summaryFile,'cfg','results');
    assert(strcmp(S.cfg.protocolMode,'selection') && ~S.cfg.evaluateTest);
    for q = 1:nCases
        for m = 1:nModes
            values = S.results.featureAblation.budgetVariants{q,m};
            assert(numel(values.label) == nBudgets);
            for b = 1:nBudgets
                readout = values.readout{b};
                assert(all(isfinite(readout.valCurve)) && isnan(readout.NRMSE));
                assert(isequal(S.cfg.featureBudgetVariants(b).lambdaGrid,lambdaGrid));
                curves(s,q,m,b,:) = readout.valCurve;
                if s == 1
                    actualCoefficients(q,m,b) = values.readoutCoefficients(b);
                    nPC(q,m,b) = values.nPCRetained(b);
                end
            end
        end
    end
end
assert(all(isfinite(curves),'all'));

nModels = nCases*nModes*nBudgets;
models = repmat(struct(),nModels,1);
physicalCase = strings(nModels,1);
featureMode = strings(nModels,1);
K = nan(nModels,1);
J = nan(nModels,1);
requestedBudget = nan(nModels,1);
actualBudget = nan(nModels,1);
retainedPC = nan(nModels,1);
ridgeLambda = nan(nModels,1);
meanValidationNRMSE = nan(nModels,1);
sdValidationNRMSE = nan(nModels,1);
cursor = 0;
caseJ = [locked.J_control locked.J_intervention];
for q = 1:nCases
    for m = 1:nModes
        for b = 1:nBudgets
            cursor = cursor+1;
            meanCurve = squeeze(mean(curves(:,q,m,b,:),1));
            [meanValidationNRMSE(cursor),lambdaIndex] = min(meanCurve);
            seedValues = squeeze(curves(:,q,m,b,lambdaIndex));
            physicalCase(cursor) = sprintf('J_%g',caseJ(q));
            featureMode(cursor) = modes{m};
            K(cursor) = locked.K;
            J(cursor) = caseJ(q);
            requestedBudget(cursor) = budgets(b);
            actualBudget(cursor) = actualCoefficients(q,m,b);
            retainedPC(cursor) = nPC(q,m,b);
            ridgeLambda(cursor) = lambdaGrid(lambdaIndex);
            sdValidationNRMSE(cursor) = std(seedValues);
            models(cursor).physical_case = char(physicalCase(cursor));
            models(cursor).feature_mode = char(featureMode(cursor));
            models(cursor).K = K(cursor);
            models(cursor).J = J(cursor);
            models(cursor).requested_budget = requestedBudget(cursor);
            models(cursor).actual_coefficients_including_bias = actualBudget(cursor);
            models(cursor).n_pc = retainedPC(cursor);
            models(cursor).tap_delays = locked.tap_delays;
            models(cursor).ridge_lambda = ridgeLambda(cursor);
            models(cursor).mean_validation_nrmse = meanValidationNRMSE(cursor);
            models(cursor).sd_validation_nrmse = sdValidationNRMSE(cursor);
        end
    end
end
summary = table(physicalCase,featureMode,K,J,requestedBudget,actualBudget, ...
    retainedPC,ridgeLambda,meanValidationNRMSE,sdValidationNRMSE);
writetable(summary,fullfile(scriptDir, ...
    'NARMAPhysicalBudgetSelection_Summary_20260810.csv'));
result.schema_version = 1;
result.status = 'physical_budget_selection_complete';
result.test_metrics_evaluated = false;
result.selection_seed_count = nSeeds;
result.models = models;
outputFile = fullfile(scriptDir,'configs', ...
    'narma_physical_budget_selected_20260810.json');
assert(~isfile(outputFile),'Collision guard: physical budget config exists.');
fid = fopen(outputFile,'w');assert(fid >= 0);
fprintf(fid,'%s\n',jsonencode(result,PrettyPrint=true));fclose(fid);
fprintf('PHYSICAL_BUDGET_AGGREGATE_PASS models=%d test=0\n',numel(models));
