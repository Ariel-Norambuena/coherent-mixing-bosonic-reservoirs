%% analyze_mackey_glass_capacity_20260806.m
% Validation-only feature-budget selection for direct Mackey-Glass h=48.

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

fileJ0 = fullfile(scriptDir, ...
    'Fig3_KerrReservoir_NARMA10_Reproducible_MGH48RawJ0_20260806_summary.mat');
fileJ08 = fullfile(scriptDir, ...
    'Fig3_KerrReservoir_NARMA10_Reproducible_MGH48RawJ08_20260806_summary.mat');
assert(isfile(fileJ0) && isfile(fileJ08),'Required Mackey-Glass caches are missing.');

d0 = load(fileJ0,'cfg','uN','yN','Xvirt','pcaInfo','results');
d8 = load(fileJ08,'cfg','uN','yN','Xvirt','pcaInfo','results');
assert(isequal(d0.uN,d8.uN) && isequal(d0.yN,d8.yN), ...
    'Paired caches do not contain the same dataset.');
assert(isequal(d0.cfg.tapDelays,d8.cfg.tapDelays), ...
    'Paired caches do not contain the same delay set.');

cfg = d0.cfg;
startIdx = cfg.washout + max([20,cfg.tapDelays]) + 1;
idxTrain = startIdx:(startIdx+cfg.numTrain-1);
idxVal = (idxTrain(end)+1):(idxTrain(end)+cfg.numVal);
idxTest = (idxVal(end)+1):(idxVal(end)+cfg.numTest);

% Keep the tapped linear readout at or below the 351 coefficients used by
% the matched 350-state ESN (including its bias term).
nPCGrid = [5 10 20 26];
lambdaGrid = logspace(-6,7,53);
caseLabels = {'J=0','J=0.8'};
data = {d0,d8};
valNRMSE = nan(numel(nPCGrid),2);
lambdaBest = nan(numel(nPCGrid),2);

for c = 1:2
    fprintf('Projecting raw features for %s...\n',caseLabels{c});
    Zmax = projectCachedPCA(data{c}.Xvirt,data{c}.pcaInfo,max(nPCGrid));
    for q = 1:numel(nPCGrid)
        nPC = nPCGrid(q);
        X = [ones(cfg.numSamples,1),addTappedDelays(Zmax(:,1:nPC),cfg.tapDelays)];
        [valNRMSE(q,c),lambdaBest(q,c)] = selectByValidation( ...
            X,d0.yN,idxTrain,idxVal,lambdaGrid);
        fprintf('  %s | PCs=%3d | dim=%4d | val NRMSE=%.6f | lambda=%.3g\n', ...
            caseLabels{c},nPC,size(X,2),valNRMSE(q,c),lambdaBest(q,c));
        clear X;
    end
    clear Zmax;
end

meanVal = mean(valNRMSE,2);
[~,selectedIdx] = min(meanVal);
selectedNPC = nPCGrid(selectedIdx);
selectedDim = 1+selectedNPC*numel(cfg.tapDelays);
fprintf('Selected shared budget: %d PCs (%d tapped features).\n', ...
    selectedNPC,selectedDim);

selected = cell(2,1);
noTap = cell(2,1);
for c = 1:2
    Z = projectCachedPCA(data{c}.Xvirt,data{c}.pcaInfo,selectedNPC);
    Xtapped = [ones(cfg.numSamples,1),addTappedDelays(Z,cfg.tapDelays)];
    selected{c} = fitFinalTest(Xtapped,d0.yN,idxTrain,idxVal,idxTest, ...
        lambdaBest(selectedIdx,c));
    XnoTap = [ones(cfg.numSamples,1),Z];
    [~,lambdaNoTap] = selectByValidation(XnoTap,d0.yN,idxTrain,idxVal,lambdaGrid);
    noTap{c} = fitFinalTest(XnoTap,d0.yN,idxTrain,idxVal,idxTest,lambdaNoTap);
    clear Z Xtapped XnoTap;
end

inputOnlyNRMSE = d8.results.inputOnly.NRMSE;
featureDims = 1+nPCGrid(:)*numel(cfg.tapDelays);
selectionTable = table(nPCGrid(:),featureDims,valNRMSE(:,1),valNRMSE(:,2), ...
    meanVal,lambdaBest(:,1),lambdaBest(:,2), ...
    'VariableNames',{'nPC','tappedFeatureDim','valNRMSE_J0','valNRMSE_J08', ...
    'meanValNRMSE','lambda_J0','lambda_J08'});
writetable(selectionTable,fullfile(scriptDir, ...
    'Fig3_MackeyGlassH48_CapacitySelection_20260806.csv'));

method = {'input-only linear taps';'J=0 no reservoir taps'; ...
    'J=0.8 no reservoir taps';'J=0 selected tapped';'J=0.8 selected tapped'};
testNRMSE = [inputOnlyNRMSE;noTap{1}.NRMSE;noTap{2}.NRMSE; ...
    selected{1}.NRMSE;selected{2}.NRMSE];
R2true = [d8.results.inputOnly.R2true;noTap{1}.R2true;noTap{2}.R2true; ...
    selected{1}.R2true;selected{2}.R2true];
lambda = [d8.results.inputOnly.lambdaBest;noTap{1}.lambda;noTap{2}.lambda; ...
    selected{1}.lambda;selected{2}.lambda];
resultTable = table(method,testNRMSE,R2true,lambda, ...
    'VariableNames',{'method','testNRMSE','R2true','lambda'});
writetable(resultTable,fullfile(scriptDir, ...
    'Fig3_MackeyGlassH48_CapacityControlled_20260806.csv'));

fig = figure('Color','w','Name','Mackey-Glass capacity-controlled benchmark');
set(fig,'Units','inches','Position',[1 1 7.2 3.7]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');

nexttile; hold on; box on;
plot(nPCGrid,valNRMSE(:,1),'o-','LineWidth',1.4,'DisplayName','$J=0$');
plot(nPCGrid,valNRMSE(:,2),'s-','LineWidth',1.4,'DisplayName','$J=0.8$');
plot(nPCGrid,meanVal,'d--','LineWidth',1.2,'DisplayName','mean');
xline(selectedNPC,':','LineWidth',1.1,'HandleVisibility','off');
xlabel('retained PCs','Interpreter','latex');
ylabel('validation NRMSE','Interpreter','latex');
title('(a) Capacity selection','Interpreter','latex');
legend('Interpreter','latex','Location','best');
set(gca,'FontSize',10.5,'TickLabelInterpreter','latex');

nexttile; hold on; box on;
bar(1,inputOnlyNRMSE,0.52,'FaceColor',[.55 .55 .55], ...
    'HandleVisibility','off');
b0 = bar([2 3]-0.18,[noTap{1}.NRMSE selected{1}.NRMSE],0.32, ...
    'FaceColor',[.20 .45 .75],'DisplayName','$J=0$');
b8 = bar([2 3]+0.18,[noTap{2}.NRMSE selected{2}.NRMSE],0.32, ...
    'FaceColor',[.15 .65 .45],'DisplayName','$J=0.8$');
set(gca,'XTick',1:3,'XTickLabel',{'input only','no taps','tapped'}, ...
    'TickLabelInterpreter','none','FontSize',10.5,'XLim',[0.5 3.5]);
ylabel('test NRMSE','Interpreter','latex');
title(sprintf('(b) Test at %d PCs',selectedNPC),'Interpreter','latex');
legend([b0 b8],'Interpreter','latex','Location','northeast');

nexttile; hold on; box on;
traceN = min(240,numel(selected{1}.Yte));
plot(selected{1}.Yte(1:traceN),'k','LineWidth',1.25,'DisplayName','target');
plot(selected{1}.Yhat(1:traceN),'--','LineWidth',1.05,'DisplayName','$J=0$');
plot(selected{2}.Yhat(1:traceN),':','LineWidth',1.25,'DisplayName','$J=0.8$');
xlabel('test sample','Interpreter','latex');
ylabel('$x(t+48)$','Interpreter','latex');
title('(c) Direct forecast','Interpreter','latex');
legend('Interpreter','latex','Location','best');
set(gca,'FontSize',10.5,'TickLabelInterpreter','latex');

exportgraphics(fig,fullfile(scriptDir, ...
    'Fig3_MackeyGlassH48_CapacityControlled_20260806.pdf'),'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir, ...
    'Fig3_MackeyGlassH48_CapacityControlled_20260806.png'),'Resolution',300);

reportFile = fullfile(scriptDir, ...
    'Fig3_MackeyGlassH48_CapacityControlled_20260806_analysis.md');
fid = fopen(reportFile,'w');
assert(fid>0,'Could not open analysis report for writing.');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'# Capacity-controlled Mackey-Glass h=48 analysis\n\n');
fprintf(fid,'- Selection used validation NRMSE only and a shared PC budget.\n');
fprintf(fid,'- Candidate readouts were capped at 351 coefficients to match the 350-state ESN plus bias.\n');
fprintf(fid,'- Selected budget: %d PCs, %d tapped readout features.\n', ...
    selectedNPC,selectedDim);
fprintf(fid,'- J=0: validation NRMSE %.6f, test NRMSE %.6f, R2 %.6f.\n', ...
    valNRMSE(selectedIdx,1),selected{1}.NRMSE,selected{1}.R2true);
fprintf(fid,'- J=0.8: validation NRMSE %.6f, test NRMSE %.6f, R2 %.6f.\n', ...
    valNRMSE(selectedIdx,2),selected{2}.NRMSE,selected{2}.R2true);
fprintf(fid,'- Input-only linear tapped baseline test NRMSE: %.6f.\n',inputOnlyNRMSE);
fprintf(fid,'- The test set was evaluated only after selecting the shared capacity.\n');
fprintf(fid,'- This benchmark establishes nonlinear temporal prediction; it is not used to claim that coupling improves every task.\n');
clear cleanup;

fprintf('Capacity-controlled Mackey-Glass analysis complete.\n');
fprintf('J=0 test NRMSE %.6f | J=0.8 test NRMSE %.6f | input-only %.6f\n', ...
    selected{1}.NRMSE,selected{2}.NRMSE,inputOnlyNRMSE);

function Z = projectCachedPCA(X,pcaInfo,nPC)
    assert(nPC<=size(pcaInfo.Vpc,2),'Requested more PCs than cached.');
    Xz = (X-pcaInfo.mu)./pcaInfo.sig;
    Z = Xz*pcaInfo.Vpc(:,1:nPC);
    assert(all(isfinite(Z(:))),'Non-finite PCA projection.');
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
    result.NRMSE = nrmse(yte,yhat);
    result.R2true = 1-sum((yte-yhat).^2)/sum((yte-mean(yte)).^2);
    result.Yte = yte;
    result.Yhat = yhat;
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
