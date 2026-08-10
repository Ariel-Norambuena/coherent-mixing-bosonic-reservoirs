%% Validation-only coefficient-budget curves for classical NARMA10 baselines.

clearvars -except KERR_BASELINE_BUDGET_SELECTION_INDEX KERR_BASELINE_BUDGET_SMOKE;
clc;
scriptDir = fileparts(mfilename('fullpath'));
protocolFile = fullfile(scriptDir,'configs','narma_revision_protocol_20260807.json');
lockedFile = fullfile(scriptDir,'configs','narma_locked_config_20260810.json');
esnFile = fullfile(scriptDir,'configs','narma_esn_selected_20260810.json');
assert(isfile(protocolFile) && isfile(lockedFile) && isfile(esnFile), ...
    'Physical and ESN selection must be frozen first.');
protocol = jsondecode(fileread(protocolFile));
locked = jsondecode(fileread(lockedFile));
esn = jsondecode(fileread(esnFile));
assert(exist('KERR_BASELINE_BUDGET_SELECTION_INDEX','var') == 1);
selectionIndex = KERR_BASELINE_BUDGET_SELECTION_INDEX;
assert(isscalar(selectionIndex) && selectionIndex == floor(selectionIndex) && ...
    selectionIndex >= 1 && selectionIndex <= numel(protocol.selection_offsets));
smoke = exist('KERR_BASELINE_BUDGET_SMOKE','var') == 1 && ...
    logical(KERR_BASELINE_BUDGET_SMOKE);
seedOffset = protocol.selection_offsets(selectionIndex);

cfg.numSamples = 22000;
cfg.washout = 2000;
cfg.numTrain = 12000;
cfg.numVal = 4000;
cfg.tapDelays = locked.tap_delays(:).';
cfg.budgets = protocol.budget_curve.budgets(:).';
cfg.lambdaGrid = logspace(-6,6,37);
cfg.methods = {'input_delays','nvar_degree_2','nvar_degree_3','tapped_esn'};
if smoke
    cfg.numSamples = 900;
    cfg.washout = 80;
    cfg.numTrain = 300;
    cfg.numVal = 150;
    cfg.tapDelays = [0 1 2];
    cfg.budgets = [13 25];
    cfg.lambdaGrid = logspace(-4,4,13);
end
startIdx = cfg.washout+max([20 cfg.tapDelays])+1;
idxTrain = startIdx:(startIdx+cfg.numTrain-1);
idxVal = (idxTrain(end)+1):(idxTrain(end)+cfg.numVal);
assert(idxVal(end) <= cfg.numSamples);

if smoke
    runKind = 'Smoke';
else
    runKind = 'Full';
end
tag = sprintf('BaselineBudgetSelection%s_Index%02d_Offset%04d_20260810', ...
    runKind,selectionIndex,seedOffset);
outputPrefix = fullfile(scriptDir,tag);
assert(isempty(dir([outputPrefix '*'])),'Collision guard for %s.',tag);

[u,y,datasetSeed] = makeStableNarma10Dataset(cfg.numSamples,132+1009*seedOffset);
esnCfg.nUnits = esn.n_units_simulated;
esnCfg.biasScale = 0.20;
if smoke
    esnCfg.nUnits = 8;
end
[Wunit,WinBias,WinInput] = makeESNWeights(esnCfg,700022+2003*seedOffset, ...
    esn.sparsity);
states = simulateESN(u,Wunit,WinBias,WinInput,esn.rho,esn.leak, ...
    esn.input_scale);
states = standardizeByTrain(states,idxTrain,false);

nMethods = numel(cfg.methods);
nBudgets = numel(cfg.budgets);
nLambda = numel(cfg.lambdaGrid);
validationCurves = nan(nMethods,nBudgets,nLambda);
actualCoefficients = nan(nMethods,nBudgets);
inputOrder = nan(nMethods,nBudgets);

for m = 1:nMethods
    for b = 1:nBudgets
        budget = cfg.budgets(b);
        switch cfg.methods{m}
            case 'input_delays'
                order = budget-1;
                features = lagMatrix(u,order);
                inputOrder(m,b) = order;
            case 'nvar_degree_2'
                order = largestNVAROrder(budget,2);
                features = makeNVARFeatures(u,order,2);
                inputOrder(m,b) = order;
            case 'nvar_degree_3'
                order = largestNVAROrder(budget,3);
                features = makeNVARFeatures(u,order,3);
                inputOrder(m,b) = order;
            case 'tapped_esn'
                nMeasured = floor((budget-1)/numel(cfg.tapDelays));
                nMeasured = min(nMeasured,size(states,2));
                assert(nMeasured >= 1);
                features = addTappedDelays(states(:,1:nMeasured),cfg.tapDelays);
                inputOrder(m,b) = nMeasured;
            otherwise
                error('Unknown baseline method.');
        end
        X = [ones(cfg.numSamples,1),features];
        actualCoefficients(m,b) = size(X,2);
        assert(actualCoefficients(m,b) <= budget);
        validation = ridgeValidationCurve(X,y,idxTrain,idxVal,cfg.lambdaGrid);
        validationCurves(m,b,:) = validation.valCurve;
        clear features X;
    end
end
assert(all(isfinite(validationCurves),'all'));

method = strings(nMethods*nBudgets,1);
requestedBudget = nan(nMethods*nBudgets,1);
actualBudget = nan(nMethods*nBudgets,1);
modelOrder = nan(nMethods*nBudgets,1);
valNRMSE = nan(nMethods*nBudgets,1);
lambdaBest = nan(nMethods*nBudgets,1);
cursor = 0;
for m = 1:nMethods
    for b = 1:nBudgets
        cursor = cursor+1;
        curve = squeeze(validationCurves(m,b,:));
        [valNRMSE(cursor),lambdaIndex] = min(curve);
        method(cursor) = cfg.methods{m};
        requestedBudget(cursor) = cfg.budgets(b);
        actualBudget(cursor) = actualCoefficients(m,b);
        modelOrder(cursor) = inputOrder(m,b);
        lambdaBest(cursor) = cfg.lambdaGrid(lambdaIndex);
    end
end
summaryTable = table(method,requestedBudget,actualBudget,modelOrder, ...
    valNRMSE,lambdaBest);
writetable(summaryTable,[outputPrefix '_summary.csv']);
metadata.protocol_mode = 'selection';
metadata.test_metrics_evaluated = false;
metadata.selection_index = selectionIndex;
metadata.seed_offset = seedOffset;
metadata.dataset_seed = datasetSeed;
save([outputPrefix '_summary.mat'],'cfg','metadata','summaryTable', ...
    'validationCurves','actualCoefficients','inputOrder','-v7.3');
fprintf('BASELINE_BUDGET_SELECTION_PASS index=%d offset=%d rows=%d test=0\n', ...
    selectionIndex,seedOffset,height(summaryTable));

function [uEnc,y,usedSeed] = makeStableNarma10Dataset(numSamples,baseSeed)
    for trial = 0:200
        usedSeed = baseSeed+trial;
        rng(usedSeed,'twister');
        uRaw = 0.5*rand(numSamples,1);
        y = zeros(numSamples,1);
        for k = 11:(numSamples-1)
            y(k+1) = 0.3*y(k)+0.05*y(k)*sum(y(k-9:k))+ ...
                1.5*uRaw(k-9)*uRaw(k)+0.1;
        end
        if all(isfinite(y)) && var(y,1)>1e-8 && max(abs(y))<10
            uEnc = 4*uRaw-1;
            return;
        end
    end
    error('Could not generate a stable NARMA10 dataset.');
end

function [Wunit,WinBias,WinInput] = makeESNWeights(cfg,seed,sparsity)
    rng(seed+round(1e5*sparsity),'twister');
    W = sprandn(cfg.nUnits,cfg.nUnits,sparsity);
    spectralRadius = max(abs(eig(full(W))));
    assert(isfinite(spectralRadius) && spectralRadius>1e-12);
    Wunit = W/spectralRadius;
    WinBias = cfg.biasScale*(2*rand(cfg.nUnits,1)-1);
    WinInput = 2*rand(cfg.nUnits,1)-1;
end

function states = simulateESN(u,Wunit,WinBias,WinInput,rho,leak,inputScale)
    nUnits = size(Wunit,1);
    states = zeros(numel(u),nUnits);
    state = zeros(nUnits,1);
    W = rho*Wunit;
    scaledInput = inputScale*WinInput;
    for t = 1:numel(u)
        candidate = tanh(W*state+WinBias+scaledInput*u(t));
        state = (1-leak)*state+leak*candidate;
        states(t,:) = state.';
    end
end

function lagged = lagMatrix(u,order)
    nSamples = numel(u);
    lagged = zeros(nSamples,order);
    for d = 0:(order-1)
        lagged((d+1):end,d+1) = u(1:(end-d));
    end
end

function order = largestNVAROrder(budget,degree)
    order = 1;
    while nvarCoefficientCount(order+1,degree) <= budget
        order = order+1;
    end
end

function count = nvarCoefficientCount(order,degree)
    count = 1+order+nchoosek(order+1,2);
    if degree == 3
        count = count+nchoosek(order+2,3);
    end
end

function features = makeNVARFeatures(u,order,degree)
    linear = lagMatrix(u,order);
    nTerms = nvarCoefficientCount(order,degree)-1;
    features = zeros(numel(u),nTerms);
    features(:,1:order) = linear;
    cursor = order;
    for i = 1:order
        for j = i:order
            cursor = cursor+1;
            features(:,cursor) = linear(:,i).*linear(:,j);
        end
    end
    if degree == 3
        for i = 1:order
            for j = i:order
                for k = j:order
                    cursor = cursor+1;
                    features(:,cursor) = linear(:,i).*linear(:,j).*linear(:,k);
                end
            end
        end
    end
    assert(cursor == nTerms);
end

function tapped = addTappedDelays(X,delays)
    [nSamples,nFeatures] = size(X);
    tapped = zeros(nSamples,nFeatures*numel(delays));
    for q = 1:numel(delays)
        d = delays(q);
        columns = (q-1)*nFeatures+(1:nFeatures);
        if d == 0
            tapped(:,columns) = X;
        else
            tapped((d+1):end,columns) = X(1:(end-d),:);
        end
    end
end

function X = standardizeByTrain(X,idxTrain,hasBias)
    mu = mean(X(idxTrain,:),1);
    sigma = std(X(idxTrain,:),0,1);
    sigma(sigma<1e-12) = 1;
    X = (X-mu)./sigma;
    if hasBias
        X(:,1) = 1;
    end
end

function validation = ridgeValidationCurve(X,y,idxTrain,idxVal,lambdaGrid)
    X = standardizeByTrain(X,idxTrain,true);
    Xtr = X(idxTrain,:).';
    Xva = X(idxVal,:).';
    yTrainRaw = y(idxTrain).';
    yMean = mean(yTrainRaw);
    yStd = std(yTrainRaw,0,2);
    if yStd < 1e-14
        yStd = 1;
    end
    yTrain = (yTrainRaw-yMean)/yStd;
    gram = Xtr*Xtr.';
    gram = 0.5*(gram+gram.');
    [basis,eigenvalues] = eig(gram,'vector');
    eigenvalues = max(real(eigenvalues),0);
    projectedTarget = basis.'*(Xtr*yTrain.');
    valCurve = nan(numel(lambdaGrid),1);
    for q = 1:numel(lambdaGrid)
        beta = (basis*(projectedTarget./(eigenvalues+lambdaGrid(q)))).';
        prediction = yStd*(beta*Xva).'+yMean;
        valCurve(q) = sqrt(mean((y(idxVal)-prediction).^2)/var(y(idxVal),1));
    end
    validation.valCurve = valCurve;
end
