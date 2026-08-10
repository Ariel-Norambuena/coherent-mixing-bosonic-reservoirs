%% Validation-only ESN hyperparameter selection for one frozen selection seed.

clearvars -except KERR_ESN_SELECTION_INDEX KERR_ESN_SELECTION_SMOKE;
clc;
scriptDir = fileparts(mfilename('fullpath'));
lockedFile = fullfile(scriptDir,'configs','narma_locked_config_20260810.json');
protocolFile = fullfile(scriptDir,'configs','narma_revision_protocol_20260807.json');
assert(isfile(lockedFile) && isfile(protocolFile), ...
    'Freeze the physical architecture before selecting the classical baseline.');
locked = jsondecode(fileread(lockedFile));
protocol = jsondecode(fileread(protocolFile));
assert(exist('KERR_ESN_SELECTION_INDEX','var') == 1);
selectionIndex = KERR_ESN_SELECTION_INDEX;
assert(isscalar(selectionIndex) && selectionIndex == floor(selectionIndex) && ...
    selectionIndex >= 1 && selectionIndex <= numel(protocol.selection_offsets));
smoke = exist('KERR_ESN_SELECTION_SMOKE','var') == 1 && ...
    logical(KERR_ESN_SELECTION_SMOKE);
seedOffset = protocol.selection_offsets(selectionIndex);

cfg.numSamples = 22000;
cfg.washout = 2000;
cfg.numTrain = 12000;
cfg.numVal = 4000;
cfg.tapDelays = locked.tap_delays(:).';
cfg.primaryPC = locked.n_pc;
cfg.maxBudget = max(protocol.budget_curve.budgets);
cfg.nUnits = max(cfg.primaryPC, ...
    floor((cfg.maxBudget-1)/numel(cfg.tapDelays)));
cfg.biasScale = 0.20;
cfg.rhoGrid = [0.4 0.8 1.2];
cfg.leakGrid = [0.2 0.6 1.0];
cfg.inputScaleGrid = [0.1 0.5 1.0];
cfg.sparsityGrid = [0.03 0.10];
cfg.lambdaGrid = logspace(-6,6,37);
if smoke
    cfg.numSamples = 900;
    cfg.washout = 80;
    cfg.numTrain = 300;
    cfg.numVal = 150;
    cfg.tapDelays = [0 1 2];
    cfg.primaryPC = 4;
    cfg.nUnits = 8;
    cfg.rhoGrid = [0.6 1.0];
    cfg.leakGrid = [0.5 1.0];
    cfg.inputScaleGrid = 0.5;
    cfg.sparsityGrid = 0.25;
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
tag = sprintf('ESNSelection%s_Index%02d_Offset%04d_20260810', ...
    runKind,selectionIndex,seedOffset);
outputPrefix = fullfile(scriptDir,tag);
assert(isempty(dir([outputPrefix '*'])),'Collision guard for %s.',tag);

[u,y,datasetSeed] = makeStableNarma10Dataset(cfg.numSamples,132+1009*seedOffset);
esnSeed = 700022+2003*seedOffset;
nCandidates = numel(cfg.rhoGrid)*numel(cfg.leakGrid)* ...
    numel(cfg.inputScaleGrid)*numel(cfg.sparsityGrid);
rho = nan(nCandidates,1);
leak = nan(nCandidates,1);
inputScale = nan(nCandidates,1);
sparsity = nan(nCandidates,1);
valNRMSE = nan(nCandidates,1);
lambdaBest = nan(nCandidates,1);
maxAbsState = nan(nCandidates,1);
valCurves = nan(nCandidates,numel(cfg.lambdaGrid));
cursor = 0;

for sparsityValue = cfg.sparsityGrid
    [Wunit,WinBias,WinInput] = makeESNWeights(cfg,esnSeed,sparsityValue);
    for rhoValue = cfg.rhoGrid
        for leakValue = cfg.leakGrid
            for inputScaleValue = cfg.inputScaleGrid
                cursor = cursor+1;
                states = simulateESN(u,Wunit,WinBias,WinInput,rhoValue, ...
                    leakValue,inputScaleValue);
                measured = states(:,1:cfg.primaryPC);
                measured = standardizeStateByTrain(measured,idxTrain);
                X = [ones(cfg.numSamples,1), ...
                    addTappedDelays(measured,cfg.tapDelays)];
                validation = ridgeValidationCurve(X,y,idxTrain,idxVal, ...
                    cfg.lambdaGrid);
                rho(cursor) = rhoValue;
                leak(cursor) = leakValue;
                inputScale(cursor) = inputScaleValue;
                sparsity(cursor) = sparsityValue;
                valNRMSE(cursor) = validation.valNRMSE;
                lambdaBest(cursor) = validation.lambdaBest;
                maxAbsState(cursor) = max(abs(states(:)));
                valCurves(cursor,:) = validation.valCurve(:).';
            end
        end
    end
end
assert(cursor == nCandidates && all(isfinite(valCurves),'all'));
candidateTable = table((1:nCandidates).',rho,leak,inputScale,sparsity, ...
    valNRMSE,lambdaBest,maxAbsState, ...
    'VariableNames',{'candidate','rho','leak','inputScale','sparsity', ...
    'valNRMSE','lambdaBest','maxAbsState'});
writetable(candidateTable,[outputPrefix '_candidates.csv']);
metadata.protocol_mode = 'selection';
metadata.test_metrics_evaluated = false;
metadata.selection_index = selectionIndex;
metadata.seed_offset = seedOffset;
metadata.dataset_seed = datasetSeed;
metadata.esn_seed = esnSeed;
metadata.readout_coefficients_including_bias = ...
    1+cfg.primaryPC*numel(cfg.tapDelays);
save([outputPrefix '_summary.mat'],'cfg','metadata','candidateTable', ...
    'valCurves','-v7.3');
fprintf('ESN_SELECTION_PASS index=%d offset=%d candidates=%d test=0\n', ...
    selectionIndex,seedOffset,nCandidates);

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

function standardized = standardizeStateByTrain(states,idxTrain)
    mu = mean(states(idxTrain,:),1);
    sigma = std(states(idxTrain,:),0,1);
    sigma(sigma<1e-12) = 1;
    standardized = (states-mu)./sigma;
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

function validation = ridgeValidationCurve(X,y,idxTrain,idxVal,lambdaGrid)
    mu = mean(X(idxTrain,:),1);
    sigma = std(X(idxTrain,:),0,1);
    sigma(sigma<1e-12) = 1;
    X = (X-mu)./sigma;
    X(:,1) = 1;
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
    [validation.valNRMSE,bestIndex] = min(valCurve);
    validation.lambdaBest = lambdaGrid(bestIndex);
    validation.valCurve = valCurve;
end
