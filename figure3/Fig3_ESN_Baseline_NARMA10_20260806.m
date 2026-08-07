%% Fig3_ESN_Baseline_NARMA10_20260806.m
% Matched classical ESN baseline for the bosonic-reservoir NARMA10 protocol.

overrideSmoke = exist('KERR_ESN_SMOKE','var') && KERR_ESN_SMOKE;
if exist('KERR_ESN_OUTPUT_TAG','var')
    overrideTag = char(KERR_ESN_OUTPUT_TAG);
else
    overrideTag = 'Full_20260806';
end
clearvars -except overrideSmoke overrideTag;
close all;
clc;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end
assert(~isempty(overrideTag), 'KERR_ESN_OUTPUT_TAG must not be empty.');
outputPrefix = fullfile(scriptDir, ['Fig3_ESN_NARMA10_' overrideTag]);
existingOutputs = dir([outputPrefix '*']);
assert(isempty(existingOutputs), ...
    'Refusing to overwrite %d existing ESN output(s) for tag %s.', ...
    numel(existingOutputs), overrideTag);

cfg.numSamples = 22000;
cfg.washout = 2000;
cfg.numTrain = 12000;
cfg.numVal = 4000;
cfg.numTest = 3000;
cfg.nUnits = 350;
cfg.connectivity = 0.02;
cfg.biasScale = 0.20;
cfg.rhoGrid = [0.30 0.70 1.10];
cfg.leakGrid = [0.20 0.60 1.00];
cfg.inputScaleGrid = [0.10 0.50 1.00];
cfg.lambdaGrid = logspace(0,7,85);
cfg.seedOffsets = (0:4).';
cfg.datasetSeedBase = 132;
cfg.datasetSeedStride = 1009;
cfg.esnSeedBase = 700022;
cfg.esnSeedStride = 2003;

if overrideSmoke
    cfg.numSamples = 1200;
    cfg.washout = 100;
    cfg.numTrain = 500;
    cfg.numVal = 200;
    cfg.numTest = 200;
    cfg.nUnits = 40;
    cfg.connectivity = 0.15;
    cfg.rhoGrid = [0.50 0.90];
    cfg.leakGrid = [0.50 1.00];
    cfg.inputScaleGrid = [0.30 0.80];
    cfg.lambdaGrid = logspace(0,4,15);
    cfg.seedOffsets = (0:1).';
end

startIdx = cfg.washout + 20 + 1;
idxTrain = startIdx:(startIdx + cfg.numTrain - 1);
idxVal = (idxTrain(end)+1):(idxTrain(end)+cfg.numVal);
idxTest = (idxVal(end)+1):(idxVal(end)+cfg.numTest);
assert(idxTest(end) <= cfg.numSamples, 'Requested split exceeds dataset length.');

fprintf('=== Matched ESN NARMA10 baseline ===\n');
fprintf('Units=%d | connectivity=%.3f | offsets=%s\n', ...
    cfg.nUnits,cfg.connectivity,mat2str(cfg.seedOffsets.'));

selectionOffset = cfg.seedOffsets(1);
[uSelection, ySelection, selectionDatasetSeed] = makeStableNarma10Dataset( ...
    cfg.numSamples,cfg.datasetSeedBase + cfg.datasetSeedStride*selectionOffset);
selectionEsnSeed = cfg.esnSeedBase + cfg.esnSeedStride*selectionOffset;
[Wunit,WinBias,WinInput] = makeESNWeights(cfg,selectionEsnSeed);

nGrid = numel(cfg.rhoGrid)*numel(cfg.leakGrid)*numel(cfg.inputScaleGrid);
rho = nan(nGrid,1);
leak = nan(nGrid,1);
inputScale = nan(nGrid,1);
lambdaBest = nan(nGrid,1);
valNRMSE = nan(nGrid,1);
gridIndex = 0;
bestVal = inf;
bestStates = [];
bestConfig = struct();

fprintf('Selecting ESN hyperparameters on seed offset %d (%d candidates)...\n', ...
    selectionOffset,nGrid);
for rhoValue = cfg.rhoGrid
    for leakValue = cfg.leakGrid
        for inputScaleValue = cfg.inputScaleGrid
            gridIndex = gridIndex + 1;
            states = simulateESN(uSelection,Wunit,WinBias,WinInput, ...
                rhoValue,leakValue,inputScaleValue);
            X = [ones(cfg.numSamples,1),states];
            validation = selectRidgeByValidation(X,ySelection,idxTrain,idxVal, ...
                cfg.lambdaGrid);
            rho(gridIndex) = rhoValue;
            leak(gridIndex) = leakValue;
            inputScale(gridIndex) = inputScaleValue;
            lambdaBest(gridIndex) = validation.lambdaBest;
            valNRMSE(gridIndex) = validation.valNRMSE;
            fprintf('  rho=%.2f leak=%.2f in=%.2f | val %.4f | lambda %.3g\n', ...
                rhoValue,leakValue,inputScaleValue,validation.valNRMSE, ...
                validation.lambdaBest);
            if validation.valNRMSE < bestVal
                bestVal = validation.valNRMSE;
                bestStates = states;
                bestConfig.rho = rhoValue;
                bestConfig.leak = leakValue;
                bestConfig.inputScale = inputScaleValue;
            end
        end
    end
end

Tgrid = table(rho,leak,inputScale,lambdaBest,valNRMSE);
gridFile = [outputPrefix '_selection_grid.csv'];
writetable(Tgrid,gridFile);

nSeeds = numel(cfg.seedOffsets);
datasetSeed = nan(nSeeds,1);
esnSeed = nan(nSeeds,1);
valSeed = nan(nSeeds,1);
testSeed = nan(nSeeds,1);
r2Seed = nan(nSeeds,1);
lambdaSeed = nan(nSeeds,1);
maxAbsState = nan(nSeeds,1);

for seedIndex = 1:nSeeds
    offset = cfg.seedOffsets(seedIndex);
    [u,y,datasetSeed(seedIndex)] = makeStableNarma10Dataset(cfg.numSamples, ...
        cfg.datasetSeedBase + cfg.datasetSeedStride*offset);
    esnSeed(seedIndex) = cfg.esnSeedBase + cfg.esnSeedStride*offset;
    if seedIndex == 1
        states = bestStates;
    else
        [Wunit,WinBias,WinInput] = makeESNWeights(cfg,esnSeed(seedIndex));
        states = simulateESN(u,Wunit,WinBias,WinInput,bestConfig.rho, ...
            bestConfig.leak,bestConfig.inputScale);
    end
    assert(all(isfinite(states(:))), 'Non-finite ESN state at offset %d.', offset);
    X = [ones(cfg.numSamples,1),states];
    result = trainValidateTestReadout(X,y,idxTrain,idxVal,idxTest,cfg.lambdaGrid);
    valSeed(seedIndex) = result.valNRMSE;
    testSeed(seedIndex) = result.NRMSE;
    r2Seed(seedIndex) = result.R2true;
    lambdaSeed(seedIndex) = result.lambdaBest;
    maxAbsState(seedIndex) = max(abs(states(:)));
    fprintf('Offset %d | dataset %d | test NRMSE %.4f | R2 %.4f\n', ...
        offset,datasetSeed(seedIndex),result.NRMSE,result.R2true);
end

Tseeds = table(cfg.seedOffsets,datasetSeed,esnSeed,valSeed,testSeed,r2Seed, ...
    lambdaSeed,maxAbsState, ...
    'VariableNames', {'seedOffset','datasetSeed','esnSeed','valNRMSE', ...
    'testNRMSE','R2true','lambdaBest','maxAbsState'});
seedFile = [outputPrefix '_seeds.csv'];
writetable(Tseeds,seedFile);

confirmationRows = cfg.seedOffsets > 0;
nConfirmation = sum(confirmationRows);
meanTest = mean(testSeed(confirmationRows));
sdTest = std(testSeed(confirmationRows),0);
meanR2 = mean(r2Seed(confirmationRows));
sdR2 = std(r2Seed(confirmationRows),0);

physicalFile = fullfile(scriptDir,'Fig3_CompactFeatures_MultiSeed_20260806.csv');
comparisonTable = table();
if isfile(physicalFile) && nConfirmation == 4
    physical = readtable(physicalFile,'TextType','string');
    linearNRMSE = nan(nConfirmation,1);
    numberNRMSE = nan(nConfirmation,1);
    esnNRMSE = testSeed(confirmationRows);
    confirmationOffsets = cfg.seedOffsets(confirmationRows);
    for q = 1:nConfirmation
        linearRow = physical.seedOffset == confirmationOffsets(q) & ...
            physical.featureMode == "linear_features";
        numberRow = physical.seedOffset == confirmationOffsets(q) & ...
            physical.featureMode == "number_features";
        assert(nnz(linearRow)==1 && nnz(numberRow)==1, ...
            'Physical compact row missing at offset %d.',confirmationOffsets(q));
        linearNRMSE(q) = physical.testNRMSE_J08(linearRow);
        numberNRMSE(q) = physical.testNRMSE_J08(numberRow);
    end
    physicalMinusESNLinear = linearNRMSE - esnNRMSE;
    physicalMinusESNNumber = numberNRMSE - esnNRMSE;
    comparisonTable = table(confirmationOffsets,datasetSeed(confirmationRows), ...
        esnNRMSE,linearNRMSE,numberNRMSE,physicalMinusESNLinear, ...
        physicalMinusESNNumber);
    writetable(comparisonTable,[outputPrefix '_paired_physical_comparison.csv']);
end

statsName = "offsets_1_to_4_confirmation";
Tstats = table(statsName,nConfirmation,meanTest,sdTest,meanR2,sdR2, ...
    bestConfig.rho,bestConfig.leak,bestConfig.inputScale,cfg.nUnits, ...
    'VariableNames', {'cohort','n','meanTestNRMSE','sdTestNRMSE', ...
    'meanR2true','sdR2true','rho','leak','inputScale','nUnits'});
statsFile = [outputPrefix '_stats.csv'];
writetable(Tstats,statsFile);

reportFile = [outputPrefix '_analysis.md'];
fid = fopen(reportFile,'w');
assert(fid >= 0,'Could not open ESN analysis report.');
cleanupFile = onCleanup(@() fclose(fid));
fprintf(fid,'# Matched ESN NARMA10 baseline\n\n');
fprintf(fid,'## Protocol\n\n');
fprintf(fid,['A sparse tanh echo-state network uses %d recurrent states, matching ' ...
    'the 350 retained physical-reservoir principal components. It uses the ' ...
    'same NARMA10 datasets, train/validation/test indices, and ridge grid. ' ...
    'Unlike the physical pipeline, the ESN receives no explicit tapped-delay ' ...
    'expansion, so its readout contains %d fitted features including bias. ' ...
    'Spectral radius, leak rate, and input scaling were selected only on ' ...
    'offset 0 and then fixed for offsets 1--4.\n\n'],cfg.nUnits,cfg.nUnits+1);
fprintf(fid,'Selected hyperparameters: `rho=%.2f`, `leak=%.2f`, `input scale=%.2f`.\n\n', ...
    bestConfig.rho,bestConfig.leak,bestConfig.inputScale);
fprintf(fid,'## Results\n\n');
fprintf(fid,['Across offsets 1--4, ESN test NRMSE is `%.4f +/- %.4f` and true ' ...
    'test R2 is `%.4f +/- %.4f` (mean +/- sample SD).\n\n'], ...
    meanTest,sdTest,meanR2,sdR2);
if ~isempty(comparisonTable)
    fprintf(fid,['On the same four datasets, the coupled physical quadrature ' ...
        'readout is `%.4f +/- %.4f` and compact number statistics are ' ...
        '`%.4f +/- %.4f`. Positive physical-minus-ESN values mean that the ' ...
        'ESN has lower error.\n\n'],mean(comparisonTable.linearNRMSE), ...
        std(comparisonTable.linearNRMSE,0),mean(comparisonTable.numberNRMSE), ...
        std(comparisonTable.numberNRMSE,0));
end
fprintf(fid,'## Interpretation boundary\n\n');
fprintf(fid,['This is a classical performance calibration, not a claim of ' ...
    'matched hardware cost or energy. The ESN and bosonic reservoir have the ' ...
    'same retained state dimension and data protocol, but different physical ' ...
    'dynamics and readout feature counts.\n']);
clear cleanupFile;

fig = figure('Color','w','Visible','off','Units','inches','Position',[1 1 5.2 3.2]);
hold on;
x = cfg.seedOffsets;
plot(x,testSeed,'-o','Color',[0.18 0.18 0.18],'MarkerFaceColor',[0.18 0.18 0.18], ...
    'LineWidth',1.2,'MarkerSize',5,'DisplayName','ESN');
if ~isempty(comparisonTable)
    plot(comparisonTable.confirmationOffsets,comparisonTable.linearNRMSE,'-s', ...
        'Color',[0.10 0.36 0.62],'MarkerFaceColor','w','LineWidth',1.1, ...
        'MarkerSize',5,'DisplayName','Bosonic quadratures');
    plot(comparisonTable.confirmationOffsets,comparisonTable.numberNRMSE,'-d', ...
        'Color',[0.12 0.52 0.36],'MarkerFaceColor','w','LineWidth',1.1, ...
        'MarkerSize',5,'DisplayName','Bosonic intensities');
end
xlabel('Seed offset');
ylabel('Test NRMSE','Interpreter','latex');
title('Matched classical ESN baseline','FontWeight','normal');
grid on;
box on;
legend('Location','best','Box','off');
set(gca,'FontName','Arial','FontSize',9,'LineWidth',0.8,'XTick',x);
try
    axtoolbar(gca,{});
catch
end
exportgraphics(fig,[outputPrefix '.pdf'],'ContentType','vector');
exportgraphics(fig,[outputPrefix '.png'],'Resolution',300);
close(fig);

save([outputPrefix '_summary.mat'],'cfg','bestConfig','Tgrid','Tseeds','Tstats', ...
    'comparisonTable','-v7.3');
fprintf('Saved ESN outputs with prefix %s\n',outputPrefix);

function [uEnc,y,usedSeed] = makeStableNarma10Dataset(numSamples,baseSeed)
for trial = 0:200
    usedSeed = baseSeed + trial;
    rng(usedSeed,'twister');
    u = 0.5*rand(numSamples,1);
    y = narma10(u);
    if all(isfinite(y)) && var(y,1)>1e-8 && max(abs(y))<10
        uEnc = 4*u-1;
        return;
    end
end
error('Could not generate a stable NARMA10 dataset.');
end

function y = narma10(u)
u = u(:);
y = zeros(numel(u),1);
for k = 11:(numel(u)-1)
    y(k+1) = 0.3*y(k)+0.05*y(k)*sum(y(k-9:k))+1.5*u(k-9)*u(k)+0.1;
end
end

function [Wunit,WinBias,WinInput] = makeESNWeights(cfg,seed)
rng(seed,'twister');
W = sprandn(cfg.nUnits,cfg.nUnits,cfg.connectivity);
spectralRadius = max(abs(eig(full(W))));
assert(isfinite(spectralRadius) && spectralRadius>1e-12, ...
    'Invalid ESN spectral radius.');
Wunit = W/spectralRadius;
WinBias = cfg.biasScale*(2*rand(cfg.nUnits,1)-1);
WinInput = 2*rand(cfg.nUnits,1)-1;
end

function states = simulateESN(u,Wunit,WinBias,WinInput,rho,leak,inputScale)
u = u(:);
nUnits = size(Wunit,1);
states = zeros(numel(u),nUnits);
x = zeros(nUnits,1);
W = rho*Wunit;
scaledInput = inputScale*WinInput;
for t = 1:numel(u)
    candidate = tanh(W*x+WinBias+scaledInput*u(t));
    x = (1-leak)*x+leak*candidate;
    states(t,:) = x.';
end
end

function validation = selectRidgeByValidation(X,y,idxTrain,idxVal,lambdaGrid)
[XZ,~,~] = standardizeByTrain(X,idxTrain);
Xtr = XZ(idxTrain,:).';
Xva = XZ(idxVal,:).';
YtrRaw = y(idxTrain).';
Yva = y(idxVal);
yMean = mean(YtrRaw);
yStd = std(YtrRaw,0,2);
if yStd<1e-14
    yStd = 1;
end
Ytr = (YtrRaw-yMean)/yStd;
[basis,eigenvalues,projectedTarget] = ridgeBasis(Xtr,Ytr);
valCurve = inf(numel(lambdaGrid),1);
for q = 1:numel(lambdaGrid)
    W = ridgeFromBasis(basis,eigenvalues,projectedTarget,lambdaGrid(q));
    prediction = yStd*(W*Xva).'+yMean;
    valCurve(q) = nrmse(Yva,prediction);
end
[validation.valNRMSE,bestIndex] = min(valCurve);
validation.lambdaBest = lambdaGrid(bestIndex);
validation.valCurve = valCurve;
end

function result = trainValidateTestReadout(X,y,idxTrain,idxVal,idxTest,lambdaGrid)
[XZ,~,~] = standardizeByTrain(X,idxTrain);
validation = selectRidgeByValidation(X,y,idxTrain,idxVal,lambdaGrid);
idxTrainVal = [idxTrain idxVal];
Xtv = XZ(idxTrainVal,:).';
Xte = XZ(idxTest,:).';
YtvRaw = y(idxTrainVal).';
Yte = y(idxTest);
yMean = mean(YtvRaw);
yStd = std(YtvRaw,0,2);
if yStd<1e-14
    yStd = 1;
end
Ytv = (YtvRaw-yMean)/yStd;
[basis,eigenvalues,projectedTarget] = ridgeBasis(Xtv,Ytv);
W = ridgeFromBasis(basis,eigenvalues,projectedTarget,validation.lambdaBest);
prediction = yStd*(W*Xte).'+yMean;
result.valNRMSE = validation.valNRMSE;
result.lambdaBest = validation.lambdaBest;
result.NRMSE = nrmse(Yte,prediction);
result.R2true = 1-sum((Yte-prediction).^2)/sum((Yte-mean(Yte)).^2);
end

function [basis,eigenvalues,projectedTarget] = ridgeBasis(X,Y)
gram = X*X.';
gram = 0.5*(gram+gram.');
[basis,eigenvalueMatrix] = eig(gram,'vector');
eigenvalues = max(real(eigenvalueMatrix),0);
projectedTarget = basis.'*(X*Y.');
end

function W = ridgeFromBasis(basis,eigenvalues,projectedTarget,lambda)
coefficients = projectedTarget./(eigenvalues+lambda);
W = (basis*coefficients).';
end

function [XZ,muX,sigX] = standardizeByTrain(X,idxTrain)
muX = mean(X(idxTrain,:),1);
sigX = std(X(idxTrain,:),0,1);
sigX(sigX<1e-12) = 1;
XZ = (X-muX)./sigX;
XZ(:,1) = 1;
end

function errorValue = nrmse(y,prediction)
y = y(:);
prediction = prediction(:);
assert(all(isfinite(y)) && all(isfinite(prediction)), ...
    'Non-finite target or prediction.');
errorValue = sqrt(mean((y-prediction).^2)/var(y,1));
end
