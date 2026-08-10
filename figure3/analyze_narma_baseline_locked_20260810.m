%% Aggregate all 30 locked classical budget evaluations.

clear; clc; close all;
scriptDir = fileparts(mfilename('fullpath'));
locked = jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'narma_locked_config_20260810.json')));
budgetSelection = jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'narma_baseline_budget_selected_20260810.json')));
nPairs = locked.paired_realizations;
nModels = numel(budgetSelection.models);
allRows = cell(nPairs,1);
for q = 1:nPairs
    offset = locked.locked_test_offsets(q);
    prefix = fullfile(scriptDir,sprintf( ...
        'BaselineLockedTest_Index%02d_Offset%04d_20260810',q,offset));
    csvFile = [prefix '_results.csv'];
    manifestFile = [prefix '_manifest.json'];
    assert(isfile(csvFile) && isfile(manifestFile), ...
        'Missing locked classical result %d.',q);
    T = readtable(csvFile,'TextType','string');
    manifest = jsondecode(fileread(manifestFile));
    assert(height(T) == nModels && manifest.locked_index == q && ...
        manifest.seed_offset == offset);
    allRows{q} = T;
end
raw = vertcat(allRows{:});
assert(height(raw) == nPairs*nModels && all(isfinite(raw.testNRMSE)));
writetable(raw,fullfile(scriptDir,'NARMABaselineLocked_Raw_20260810.csv'));

methodNames = unique(raw.method,'stable');
budgets = unique(raw.requestedBudget,'stable');
nMethods = numel(methodNames);
nBudgets = numel(budgets);
nStats = nMethods*nBudgets;
method = strings(nStats,1);
requestedBudget = nan(nStats,1);
actualCoefficients = nan(nStats,1);
meanTestNRMSE = nan(nStats,1);
sdTestNRMSE = nan(nStats,1);
medianTestNRMSE = nan(nStats,1);
q25TestNRMSE = nan(nStats,1);
q75TestNRMSE = nan(nStats,1);
meanCI95Low = nan(nStats,1);
meanCI95High = nan(nStats,1);
medianCI95Low = nan(nStats,1);
medianCI95High = nan(nStats,1);
rng(20260810,'twister');
nBoot = 10000;
cursor = 0;
for m = 1:nMethods
    for b = 1:nBudgets
        cursor = cursor+1;
        rows = raw.method == methodNames(m) & raw.requestedBudget == budgets(b);
        values = raw.testNRMSE(rows);
        assert(numel(values) == nPairs);
        indices = randi(nPairs,nBoot,nPairs);
        bootMean = mean(values(indices),2);
        bootMedian = median(values(indices),2);
        method(cursor) = methodNames(m);
        requestedBudget(cursor) = budgets(b);
        actualCoefficients(cursor) = unique(raw.actualCoefficients(rows));
        meanTestNRMSE(cursor) = mean(values);
        sdTestNRMSE(cursor) = std(values);
        medianTestNRMSE(cursor) = median(values);
        q25TestNRMSE(cursor) = prctile(values,25);
        q75TestNRMSE(cursor) = prctile(values,75);
        meanCI = prctile(bootMean,[2.5 97.5]);
        medianCI = prctile(bootMedian,[2.5 97.5]);
        meanCI95Low(cursor) = meanCI(1);
        meanCI95High(cursor) = meanCI(2);
        medianCI95Low(cursor) = medianCI(1);
        medianCI95High(cursor) = medianCI(2);
    end
end
stats = table(method,requestedBudget,actualCoefficients,meanTestNRMSE, ...
    sdTestNRMSE,medianTestNRMSE,q25TestNRMSE,q75TestNRMSE, ...
    meanCI95Low,meanCI95High,medianCI95Low,medianCI95High);
writetable(stats,fullfile(scriptDir,'NARMABaselineLocked_Statistics_20260810.csv'));

result.schema_version = 1;
result.status = 'baseline_locked_test_complete';
result.n_locked_seeds = nPairs;
result.bootstrap_resamples = nBoot;
result.statistics = table2struct(stats);
resultFile = fullfile(scriptDir,'configs','narma_baseline_locked_result_20260810.json');
fid = fopen(resultFile,'w');assert(fid >= 0);
fprintf(fid,'%s\n',jsonencode(result,PrettyPrint=true));fclose(fid);

colors = [0.18 0.39 0.66;0.20 0.58 0.43;0.72 0.32 0.18;0.45 0.31 0.68];
fig = figure('Color','w','Visible','off','Units','inches','Position',[1 1 6.8 4.2]);
ax = axes(fig);hold(ax,'on');
for m = 1:nMethods
    methodRows = raw.method == methodNames(m);
    for q = 1:nPairs
        seedRows = methodRows & raw.lockedIndex == q;
        seedTable = sortrows(raw(seedRows,:),'requestedBudget');
        plot(ax,seedTable.actualCoefficients,seedTable.testNRMSE,'-', ...
            'Color',0.88+0.12*colors(m,:),'LineWidth',0.45, ...
            'HandleVisibility','off');
    end
    statRows = stats.method == methodNames(m);
    statTable = sortrows(stats(statRows,:),'requestedBudget');
    errorbar(ax,statTable.actualCoefficients,statTable.medianTestNRMSE, ...
        statTable.medianTestNRMSE-statTable.q25TestNRMSE, ...
        statTable.q75TestNRMSE-statTable.medianTestNRMSE,'-o', ...
        'Color',colors(m,:),'MarkerFaceColor','w','LineWidth',1.5, ...
        'MarkerSize',5,'DisplayName',strrep(char(methodNames(m)),'_',' '));
end
set(ax,'XScale','log','FontSize',11,'LineWidth',0.9,'TickLabelInterpreter','latex');
xlabel(ax,'trained coefficients including bias','Interpreter','latex');
ylabel(ax,'test NRMSE','Interpreter','latex');
grid(ax,'on');box(ax,'on');
legend(ax,'Location','best','Box','off','Interpreter','none');
exportgraphics(fig,fullfile(scriptDir,'NARMABaselineLocked_20260810.pdf'), ...
    'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'NARMABaselineLocked_20260810.png'), ...
    'Resolution',300);
close(fig);
fprintf('BASELINE_LOCKED_ANALYSIS_PASS seeds=%d models=%d\n',nPairs,nModels);
