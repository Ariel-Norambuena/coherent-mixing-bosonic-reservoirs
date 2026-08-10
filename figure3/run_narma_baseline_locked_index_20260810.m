%% Evaluate all frozen classical budget models on one locked NARMA10 seed.

clearvars -except KERR_BASELINE_LOCKED_INDEX;
clc;
scriptDir = fileparts(mfilename('fullpath'));
lockedFile = fullfile(scriptDir,'configs','narma_locked_config_20260810.json');
esnFile = fullfile(scriptDir,'configs','narma_esn_selected_20260810.json');
budgetFile = fullfile(scriptDir,'configs','narma_baseline_budget_selected_20260810.json');
physicalBudgetFile = fullfile(scriptDir,'configs','narma_physical_budget_selected_20260810.json');
comparisonFile = fullfile(scriptDir,'configs','narma_locked_comparison_config_20260810.json');
assert(isfile(lockedFile) && isfile(esnFile) && isfile(budgetFile) && ...
    isfile(physicalBudgetFile) && isfile(comparisonFile) && ...
    isfile([comparisonFile '.sha256']), ...
    'All physical and classical selections must be frozen before locked test.');
locked = jsondecode(fileread(lockedFile));
esn = jsondecode(fileread(esnFile));
budgetSelection = jsondecode(fileread(budgetFile));
comparisonHash = sha256File(comparisonFile);
checksumTokens = split(strtrim(fileread([comparisonFile '.sha256'])));
assert(strcmp(comparisonHash,char(checksumTokens(1))), ...
    'Locked comparison checksum mismatch.');
assert(exist('KERR_BASELINE_LOCKED_INDEX','var') == 1);
lockedIndex = KERR_BASELINE_LOCKED_INDEX;
assert(isscalar(lockedIndex) && lockedIndex == floor(lockedIndex) && ...
    lockedIndex >= 1 && lockedIndex <= locked.paired_realizations);
seedOffset = locked.locked_test_offsets(lockedIndex);
tag = sprintf('BaselineLockedTest_Index%02d_Offset%04d_20260810', ...
    lockedIndex,seedOffset);
outputPrefix = fullfile(scriptDir,tag);
assert(isempty(dir([outputPrefix '*'])),'Collision guard for %s.',tag);

cfg.numSamples = 22000;
cfg.washout = 2000;
cfg.numTrain = 12000;
cfg.numVal = 4000;
cfg.numTest = 3000;
cfg.tapDelays = locked.tap_delays(:).';
startIdx = cfg.washout+max([20 cfg.tapDelays])+1;
idxTrain = startIdx:(startIdx+cfg.numTrain-1);
idxVal = (idxTrain(end)+1):(idxTrain(end)+cfg.numVal);
idxTest = (idxVal(end)+1):(idxVal(end)+cfg.numTest);
assert(idxTest(end) <= cfg.numSamples);

[u,y,datasetSeed] = makeStableNarma10Dataset(cfg.numSamples,132+1009*seedOffset);
esnCfg.nUnits = esn.n_units_simulated;
esnCfg.biasScale = 0.20;
[Wunit,WinBias,WinInput] = makeESNWeights(esnCfg,700022+2003*seedOffset, ...
    esn.sparsity);
states = simulateESN(u,Wunit,WinBias,WinInput,esn.rho,esn.leak, ...
    esn.input_scale);
states = standardizeByTrain(states,idxTrain,false);

models = budgetSelection.models;
nModels = numel(models);
method = strings(nModels,1);
requestedBudget = nan(nModels,1);
actualCoefficients = nan(nModels,1);
modelOrder = nan(nModels,1);
ridgeLambda = nan(nModels,1);
testNRMSE = nan(nModels,1);
R2true = nan(nModels,1);
for q = 1:nModels
    model = models(q);
    method(q) = string(model.method);
    requestedBudget(q) = model.requested_budget;
    actualCoefficients(q) = model.actual_coefficients_including_bias;
    modelOrder(q) = model.model_order;
    ridgeLambda(q) = model.ridge_lambda;
    switch char(method(q))
        case 'input_delays'
            features = lagMatrix(u,model.model_order);
        case 'nvar_degree_2'
            features = makeNVARFeatures(u,model.model_order,2);
        case 'nvar_degree_3'
            features = makeNVARFeatures(u,model.model_order,3);
        case 'tapped_esn'
            features = addTappedDelays(states(:,1:model.model_order), ...
                cfg.tapDelays);
        otherwise
            error('Unknown locked baseline method %s.',method(q));
    end
    X = [ones(cfg.numSamples,1),features];
    assert(size(X,2) == actualCoefficients(q));
    result = trainFixedRidgeTest(X,y,idxTrain,idxVal,idxTest,ridgeLambda(q));
    testNRMSE(q) = result.NRMSE;
    R2true(q) = result.R2true;
    clear features X;
end
assert(all(isfinite(testNRMSE)) && all(isfinite(R2true)));
T = table(repmat(lockedIndex,nModels,1),repmat(seedOffset,nModels,1), ...
    repmat(datasetSeed,nModels,1),method,requestedBudget,actualCoefficients, ...
    modelOrder,ridgeLambda,testNRMSE,R2true, ...
    'VariableNames',{'lockedIndex','seedOffset','datasetSeed','method', ...
    'requestedBudget','actualCoefficients','modelOrder','ridgeLambda', ...
    'testNRMSE','R2true'});
csvFile = [outputPrefix '_results.csv'];
writetable(T,csvFile);
manifest.schema_version = 1;
manifest.status = 'baseline_locked_test_complete';
manifest.locked_index = lockedIndex;
manifest.seed_offset = seedOffset;
manifest.locked_config_sha256 = sha256File(lockedFile);
manifest.esn_config_sha256 = sha256File(esnFile);
manifest.baseline_budget_config_sha256 = sha256File(budgetFile);
manifest.physical_budget_config_sha256 = sha256File(physicalBudgetFile);
manifest.comparison_config_sha256 = comparisonHash;
manifest.results_csv_sha256 = sha256File(csvFile);
manifestFile = [outputPrefix '_manifest.json'];
fid = fopen(manifestFile,'w');assert(fid >= 0);
fprintf(fid,'%s\n',jsonencode(manifest,PrettyPrint=true));fclose(fid);
fprintf('BASELINE_LOCKED_PASS index=%d offset=%d models=%d\n', ...
    lockedIndex,seedOffset,nModels);

function [uEnc,y,usedSeed] = makeStableNarma10Dataset(numSamples,baseSeed)
    for trial = 0:200
        usedSeed = baseSeed+trial;rng(usedSeed,'twister');uRaw = 0.5*rand(numSamples,1);
        y = zeros(numSamples,1);
        for k = 11:(numSamples-1)
            y(k+1)=0.3*y(k)+0.05*y(k)*sum(y(k-9:k))+1.5*uRaw(k-9)*uRaw(k)+0.1;
        end
        if all(isfinite(y)) && var(y,1)>1e-8 && max(abs(y))<10
            uEnc=4*uRaw-1;return;
        end
    end
    error('Could not generate stable NARMA10 dataset.');
end

function [Wunit,WinBias,WinInput] = makeESNWeights(cfg,seed,sparsity)
    rng(seed+round(1e5*sparsity),'twister');W=sprandn(cfg.nUnits,cfg.nUnits,sparsity);
    radius=max(abs(eig(full(W))));assert(isfinite(radius)&&radius>1e-12);Wunit=W/radius;
    WinBias=cfg.biasScale*(2*rand(cfg.nUnits,1)-1);WinInput=2*rand(cfg.nUnits,1)-1;
end

function states = simulateESN(u,Wunit,WinBias,WinInput,rho,leak,inputScale)
    nUnits=size(Wunit,1);states=zeros(numel(u),nUnits);state=zeros(nUnits,1);
    W=rho*Wunit;scaledInput=inputScale*WinInput;
    for t=1:numel(u)
        candidate=tanh(W*state+WinBias+scaledInput*u(t));
        state=(1-leak)*state+leak*candidate;states(t,:)=state.';
    end
end

function lagged = lagMatrix(u,order)
    lagged=zeros(numel(u),order);
    for d=0:(order-1),lagged((d+1):end,d+1)=u(1:(end-d));end
end

function features = makeNVARFeatures(u,order,degree)
    linear=lagMatrix(u,order);nTerms=order+nchoosek(order+1,2);
    if degree==3,nTerms=nTerms+nchoosek(order+2,3);end
    features=zeros(numel(u),nTerms);features(:,1:order)=linear;cursor=order;
    for i=1:order,for j=i:order,cursor=cursor+1;features(:,cursor)=linear(:,i).*linear(:,j);end,end
    if degree==3
        for i=1:order,for j=i:order,for k=j:order,cursor=cursor+1;features(:,cursor)=linear(:,i).*linear(:,j).*linear(:,k);end,end,end
    end
    assert(cursor==nTerms);
end

function tapped = addTappedDelays(X,delays)
    [nSamples,nFeatures]=size(X);tapped=zeros(nSamples,nFeatures*numel(delays));
    for q=1:numel(delays),d=delays(q);cols=(q-1)*nFeatures+(1:nFeatures);if d==0,tapped(:,cols)=X;else,tapped((d+1):end,cols)=X(1:(end-d),:);end,end
end

function X = standardizeByTrain(X,idxTrain,hasBias)
    mu=mean(X(idxTrain,:),1);sigma=std(X(idxTrain,:),0,1);sigma(sigma<1e-12)=1;X=(X-mu)./sigma;
    if hasBias,X(:,1)=1;end
end

function result = trainFixedRidgeTest(X,y,idxTrain,idxVal,idxTest,lambda)
    X=standardizeByTrain(X,idxTrain,true);idxTrainVal=[idxTrain idxVal];
    Xtv=X(idxTrainVal,:).';Xte=X(idxTest,:).';yRaw=y(idxTrainVal).';
    yMean=mean(yRaw);yStd=std(yRaw,0,2);if yStd<1e-14,yStd=1;end
    yScaled=(yRaw-yMean)/yStd;beta=ridgeReadoutStable(Xtv,yScaled,lambda);
    prediction=yStd*(beta*Xte).'+yMean;target=y(idxTest);
    result.NRMSE=sqrt(mean((target-prediction).^2)/var(target,1));
    result.R2true=1-sum((target-prediction).^2)/sum((target-mean(target)).^2);
end

function W = ridgeReadoutStable(X,Y,lambda)
    [D,M]=size(X);
    if D>=M,G=X.'*X;A=G+lambda*eye(M,'like',G);B=Y.';C=solveSPD(A,B);W=C.'*X.';
    else,G=X*X.';A=G+lambda*eye(D,'like',G);B=X*Y.';C=solveSPD(A,B);W=C.';end
end

function C = solveSPD(A,B)
    A=0.5*(A+A.');[R,p]=chol(A,'lower');if p==0,C=R'\(R\B);else,C=A\B;end
end

function digest = sha256File(path)
    engine=java.security.MessageDigest.getInstance('SHA-256');
    bytes=typecast(engine.digest(uint8(fileread(path))),'uint8');
    digest=lower(reshape(dec2hex(bytes,2).',1,[]));
end
