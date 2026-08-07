%% analyze_hardware_robustness_20260806.m
% Readout noise, quantization, and reduced-channel tests on Mackey-Glass h=48.

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end
cacheFile = fullfile(scriptDir, ...
    'Fig3_KerrReservoir_NARMA10_Reproducible_MGH48RawJ08_20260806_summary.mat');
assert(isfile(cacheFile),'Required J=0.8 raw-feature cache is missing.');
d = load(cacheFile,'cfg','yN','Xvirt');

cfg = d.cfg;
startIdx = cfg.washout+max([20,cfg.tapDelays])+1;
idxTrain = startIdx:(startIdx+cfg.numTrain-1);
idxVal = (idxTrain(end)+1):(idxTrain(end)+cfg.numVal);
idxTest = (idxVal(end)+1):(idxVal(end)+cfg.numTest);
nPC = 26;
lambdaGrid = logspace(-6,7,53);

category = strings(0,1);
level = zeros(0,1);
replicate = zeros(0,1);
rawFeatureDim = zeros(0,1);
valNRMSE = zeros(0,1);
testNRMSE = zeros(0,1);
R2true = zeros(0,1);

fprintf('Calibrating clean reference...\n');
clean = evaluateRawFeatures(d.Xvirt,d.yN,idxTrain,idxVal,idxTest, ...
    cfg.tapDelays,nPC,lambdaGrid);
[category,level,replicate,rawFeatureDim,valNRMSE,testNRMSE,R2true] = appendRow( ...
    category,level,replicate,rawFeatureDim,valNRMSE,testNRMSE,R2true, ...
    "clean",0,1,size(d.Xvirt,2),clean);

trainScale = std(d.Xvirt(idxTrain,:),0,1);
trainScale(trainScale<1e-12) = 1;
noiseFractions = [0.001 0.003 0.01 0.03 0.10];
numNoiseReplicates = 5;
for q = 1:numel(noiseFractions)
    for r = 1:numNoiseReplicates
        rng(81000+100*q+r);
        Xnoisy = d.Xvirt+noiseFractions(q)*randn(size(d.Xvirt)).*trainScale;
        Xnoisy = max(Xnoisy,0);
        result = evaluateRawFeatures(Xnoisy,d.yN,idxTrain,idxVal,idxTest, ...
            cfg.tapDelays,nPC,lambdaGrid);
        [category,level,replicate,rawFeatureDim,valNRMSE,testNRMSE,R2true] = appendRow( ...
            category,level,replicate,rawFeatureDim,valNRMSE,testNRMSE,R2true, ...
            "noise_fraction",noiseFractions(q),r,size(Xnoisy,2),result);
        fprintf('Noise %.3g rep %d: test NRMSE %.5f\n', ...
            noiseFractions(q),r,result.NRMSE);
        clear Xnoisy;
    end
end

bitDepths = [3 4 6 8 10 12];
for q = 1:numel(bitDepths)
    Xquant = quantizeByTrainingRange(d.Xvirt,idxTrain,bitDepths(q));
    result = evaluateRawFeatures(Xquant,d.yN,idxTrain,idxVal,idxTest, ...
        cfg.tapDelays,nPC,lambdaGrid);
    [category,level,replicate,rawFeatureDim,valNRMSE,testNRMSE,R2true] = appendRow( ...
        category,level,replicate,rawFeatureDim,valNRMSE,testNRMSE,R2true, ...
        "adc_bits",bitDepths(q),1,size(Xquant,2),result);
    fprintf('%d-bit quantization: test NRMSE %.5f\n',bitDepths(q),result.NRMSE);
    clear Xquant;
end

modeCounts = [3 6 9 12];
numChannelReplicates = 5;
for q = 1:numel(modeCounts)
    reps = numChannelReplicates;
    if modeCounts(q)==12
        reps = 1;
    end
    for r = 1:reps
        rng(91000+100*q+r);
        activeModes = sort(randperm(12,modeCounts(q)));
        Xreduced = selectIntensityChannels(d.Xvirt,activeModes);
        result = evaluateRawFeatures(Xreduced,d.yN,idxTrain,idxVal,idxTest, ...
            cfg.tapDelays,nPC,lambdaGrid);
        [category,level,replicate,rawFeatureDim,valNRMSE,testNRMSE,R2true] = appendRow( ...
            category,level,replicate,rawFeatureDim,valNRMSE,testNRMSE,R2true, ...
            "active_modes",modeCounts(q),r,size(Xreduced,2),result);
        fprintf('%d active modes rep %d: test NRMSE %.5f\n', ...
            modeCounts(q),r,result.NRMSE);
        clear Xreduced;
    end
end

copyWidth = size(d.Xvirt,2)/cfg.numReservoirs;
assert(copyWidth==floor(copyWidth),'Raw features do not divide into reservoir copies.');
for activeCount = 1:cfg.numReservoirs
    combinations = nchoosek(1:cfg.numReservoirs,activeCount);
    for r = 1:size(combinations,1)
        columns = zeros(1,activeCount*copyWidth);
        for k = 1:activeCount
            source = (combinations(r,k)-1)*copyWidth+(1:copyWidth);
            target = (k-1)*copyWidth+(1:copyWidth);
            columns(target) = source;
        end
        Xcopies = d.Xvirt(:,columns);
        result = evaluateRawFeatures(Xcopies,d.yN,idxTrain,idxVal,idxTest, ...
            cfg.tapDelays,nPC,lambdaGrid);
        [category,level,replicate,rawFeatureDim,valNRMSE,testNRMSE,R2true] = appendRow( ...
            category,level,replicate,rawFeatureDim,valNRMSE,testNRMSE,R2true, ...
            "active_copies",activeCount,r,size(Xcopies,2),result);
        fprintf('%d active copies combination %d: test NRMSE %.5f\n', ...
            activeCount,r,result.NRMSE);
        clear Xcopies;
    end
end

T = table(category,level,replicate,rawFeatureDim,valNRMSE,testNRMSE,R2true);
writetable(T,fullfile(scriptDir,'Fig3_HardwareRobustness_Raw_20260806.csv'));

summaryCategories = ["clean";"noise_fraction";"adc_bits";"active_modes";"active_copies"];
summaryLevel = zeros(0,1);
summaryCategory = strings(0,1);
meanTest = zeros(0,1);
sdTest = zeros(0,1);
minTest = zeros(0,1);
maxTest = zeros(0,1);
for c = 1:numel(summaryCategories)
    levels = unique(level(category==summaryCategories(c)));
    for q = 1:numel(levels)
        values = testNRMSE(category==summaryCategories(c) & level==levels(q));
        summaryCategory(end+1,1) = summaryCategories(c); %#ok<SAGROW>
        summaryLevel(end+1,1) = levels(q); %#ok<SAGROW>
        meanTest(end+1,1) = mean(values); %#ok<SAGROW>
        sdTest(end+1,1) = std(values,0); %#ok<SAGROW>
        minTest(end+1,1) = min(values); %#ok<SAGROW>
        maxTest(end+1,1) = max(values); %#ok<SAGROW>
    end
end
S = table(summaryCategory,summaryLevel,meanTest,sdTest,minTest,maxTest, ...
    'VariableNames',{'category','level','meanTestNRMSE','sdTestNRMSE', ...
    'minTestNRMSE','maxTestNRMSE'});
writetable(S,fullfile(scriptDir,'Fig3_HardwareRobustness_Summary_20260806.csv'));

fig = figure('Color','w','Name','Readout robustness');
set(fig,'Units','inches','Position',[1 1 7.2 5.2]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

nexttile; hold on; box on;
noisePct = 100*noiseFractions;
[noiseMean,noiseSD] = groupedStats(T,"noise_fraction",noiseFractions);
errorbar(noisePct,noiseMean,noiseSD,'o-','LineWidth',1.35,'CapSize',5);
yline(clean.NRMSE,':','clean','LabelHorizontalAlignment','left');
xlabel('readout noise (\% of channel SD)','Interpreter','latex');
ylabel('test NRMSE','Interpreter','latex');
title('(a) Additive readout noise','Interpreter','latex');
set(gca,'FontSize',10.5,'TickLabelInterpreter','latex');

nexttile; hold on; box on;
quantMean = groupedStats(T,"adc_bits",bitDepths);
plot(bitDepths,quantMean,'s-','LineWidth',1.35);
yline(clean.NRMSE,':','clean','LabelHorizontalAlignment','left');
xlabel('intensity resolution (bits)','Interpreter','latex');
ylabel('test NRMSE','Interpreter','latex');
title('(b) Uniform quantization','Interpreter','latex');
set(gca,'FontSize',10.5,'TickLabelInterpreter','latex');

nexttile; hold on; box on;
[channelMean,channelSD] = groupedStats(T,"active_modes",modeCounts);
errorbar(modeCounts,channelMean,channelSD,'d-','LineWidth',1.35,'CapSize',5);
yline(clean.NRMSE,':','clean','LabelHorizontalAlignment','left');
xlabel('measured modes per virtual node','Interpreter','latex');
ylabel('test NRMSE','Interpreter','latex');
title('(c) Reduced channel count','Interpreter','latex');
set(gca,'FontSize',10.5,'TickLabelInterpreter','latex','XTick',modeCounts);

nexttile; hold on; box on;
copyCounts = 1:cfg.numReservoirs;
[copyMean,copySD] = groupedStats(T,"active_copies",copyCounts);
errorbar(copyCounts,copyMean,copySD,'^-','LineWidth',1.35,'CapSize',5);
yline(clean.NRMSE,':','clean','LabelHorizontalAlignment','left');
xlabel('active disordered copies','Interpreter','latex');
ylabel('test NRMSE','Interpreter','latex');
title('(d) Fabrication-realization ensemble','Interpreter','latex');
set(gca,'FontSize',10.5,'TickLabelInterpreter','latex','XTick',copyCounts);

exportgraphics(fig,fullfile(scriptDir,'Fig3_HardwareRobustness_20260806.pdf'), ...
    'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'Fig3_HardwareRobustness_20260806.png'), ...
    'Resolution',300);

reportFile = fullfile(scriptDir,'Fig3_HardwareRobustness_20260806_analysis.md');
fid = fopen(reportFile,'w');
assert(fid>0,'Could not open robustness report.');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'# Hardware-oriented robustness analysis\n\n');
fprintf(fid,'- Task: Mackey-Glass h=48, K=0, J=0.8, 26 PCs and 339 tapped coefficients.\n');
fprintf(fid,'- Clean test NRMSE: %.6f.\n',clean.NRMSE);
fprintf(fid,'- Noise is iid Gaussian per raw intensity channel and scaled by its training SD.\n');
fprintf(fid,'- Quantizer ranges are calibrated on training data only; later samples are clipped to those ranges.\n');
fprintf(fid,'- Reduced-channel tests keep random oscillator subsets and recompute mean, variance, and maximum from measured channels.\n');
fprintf(fid,['- Copy subsets probe independent implemented realizations with detuning SD %.3f model units (%.2f kappa), ' ...
    '%.1f%% mask, %.1f%% drive, and 4%% coupling disorder.\n'], ...
    cfg.copyDetuningDisorder,cfg.copyDetuningDisorder/0.120, ...
    100*cfg.copyMaskDisorder,100*cfg.copyDriveDisorder);
fprintf(fid,'- Each perturbed condition recalibrates PCA and ridge without using the test target.\n');
clear cleanup;

fprintf('Hardware robustness analysis complete. Clean NRMSE %.6f.\n',clean.NRMSE);

function result = evaluateRawFeatures(Xraw,y,idxTrain,idxVal,idxTest,delays,nPC,lambdaGrid)
    Z = fitProjectPCA(Xraw,idxTrain,nPC);
    X = [ones(size(Z,1),1),addTappedDelays(Z,delays)];
    [bestVal,lambda] = selectByValidation(X,y,idxTrain,idxVal,lambdaGrid);
    result = fitFinalTest(X,y,idxTrain,idxVal,idxTest,lambda);
    result.valNRMSE = bestVal;
end

function Z = fitProjectPCA(X,idxTrain,nPC)
    mu = mean(X(idxTrain,:),1);
    sig = std(X(idxTrain,:),0,1);
    sig(sig<1e-12) = 1;
    Xz = (X-mu)./sig;
    covariance = Xz(idxTrain,:).'*Xz(idxTrain,:);
    covariance = 0.5*(covariance+covariance.');
    [V,L] = eig(covariance,'vector');
    [~,order] = sort(real(L),'descend');
    retained = min(nPC,size(V,2));
    Z = Xz*V(:,order(1:retained));
end

function Xq = quantizeByTrainingRange(X,idxTrain,bits)
    lo = min(X(idxTrain,:),[],1);
    hi = max(X(idxTrain,:),[],1);
    span = hi-lo;
    span(span<1e-12) = 1;
    levels = 2^bits-1;
    normalized = min(max((X-lo)./span,0),1);
    Xq = lo+round(levels*normalized).*span/levels;
end

function Xout = selectIntensityChannels(X,activeModes)
    blockWidth = 15;
    assert(mod(size(X,2),blockWidth)==0,'Unexpected number-feature layout.');
    numBlocks = size(X,2)/blockWidth;
    outputWidth = numel(activeModes)+3;
    Xout = zeros(size(X,1),numBlocks*outputWidth);
    for block = 1:numBlocks
        source = (block-1)*blockWidth+activeModes;
        n = X(:,source);
        target = (block-1)*outputWidth+(1:outputWidth);
        Xout(:,target) = [n,mean(n,2),var(n,1,2),max(n,[],2)];
    end
end

function [category,level,replicate,rawDim,val,test,r2] = appendRow( ...
        category,level,replicate,rawDim,val,test,r2,newCategory,newLevel,newRep,newDim,result)
    category(end+1,1) = newCategory;
    level(end+1,1) = newLevel;
    replicate(end+1,1) = newRep;
    rawDim(end+1,1) = newDim;
    val(end+1,1) = result.valNRMSE;
    test(end+1,1) = result.NRMSE;
    r2(end+1,1) = result.R2true;
end

function [means,sds] = groupedStats(T,categoryName,levels)
    means = nan(size(levels));
    sds = nan(size(levels));
    for q = 1:numel(levels)
        values = T.testNRMSE(T.category==categoryName & T.level==levels(q));
        means(q) = mean(values);
        sds(q) = std(values,0);
    end
end

function Xt = addTappedDelays(X,delays)
    [numSamples,numFeatures] = size(X);
    Xt = zeros(numSamples,numFeatures*numel(delays));
    for q = 1:numel(delays)
        d = delays(q);
        cols = (q-1)*numFeatures+(1:numFeatures);
        if d==0
            Xt(:,cols) = X;
        else
            Xt((d+1):end,cols) = X(1:(end-d),:);
        end
    end
end

function [bestVal,bestLambda] = selectByValidation(X,y,idxTrain,idxVal,lambdaGrid)
    Xz = standardizeFeatures(X,idxTrain);
    Xtr = Xz(idxTrain,:).';
    Xva = Xz(idxVal,:).';
    ytrRaw = y(idxTrain).';
    yva = y(idxVal);
    yMean = mean(ytrRaw);
    yStd = std(ytrRaw,0,2);
    ytr = (ytrRaw-yMean)/yStd;
    gram = Xtr*Xtr.';
    gram = 0.5*(gram+gram.');
    [Q,L] = eig(gram,'vector');
    L = max(real(L),0);
    projection = (ytr*Xtr.')*Q;
    scores = inf(numel(lambdaGrid),1);
    for k = 1:numel(lambdaGrid)
        W = (projection./(L.'+lambdaGrid(k)))*Q.';
        yhat = yStd*(W*Xva).'+yMean;
        scores(k) = nrmse(yva,yhat);
    end
    [bestVal,idx] = min(scores);
    bestLambda = lambdaGrid(idx);
end

function result = fitFinalTest(X,y,idxTrain,idxVal,idxTest,lambda)
    Xz = standardizeFeatures(X,idxTrain);
    idxTrainVal = [idxTrain idxVal];
    Xtv = Xz(idxTrainVal,:).';
    Xte = Xz(idxTest,:).';
    ytvRaw = y(idxTrainVal).';
    yte = y(idxTest);
    yMean = mean(ytvRaw);
    yStd = std(ytvRaw,0,2);
    ytv = (ytvRaw-yMean)/yStd;
    gram = Xtv*Xtv.';
    W = (ytv*Xtv.')/(0.5*(gram+gram.')+lambda*eye(size(gram),'like',gram));
    yhat = yStd*(W*Xte).'+yMean;
    result.lambda = lambda;
    result.valNRMSE = nan;
    result.NRMSE = nrmse(yte,yhat);
    result.R2true = 1-sum((yte-yhat).^2)/sum((yte-mean(yte)).^2);
end

function Xz = standardizeFeatures(X,idxTrain)
    mu = mean(X(idxTrain,:),1);
    sig = std(X(idxTrain,:),0,1);
    sig(sig<1e-12) = 1;
    Xz = (X-mu)./sig;
    Xz(:,1) = 1;
end

function value = nrmse(y,yhat)
    y = y(:);
    yhat = yhat(:);
    value = sqrt(mean((y-yhat).^2)/var(y,1));
end
