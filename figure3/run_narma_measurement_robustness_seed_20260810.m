%% run_narma_measurement_robustness_seed_20260810.m
% Paired measurement/readout robustness on clean selection-bank trajectories.

assert(exist('KERR_ROBUSTNESS_SEED_INDEX','var')==1, ...
    'Set KERR_ROBUSTNESS_SEED_INDEX to 1--10.');
seedIndex=KERR_ROBUSTNESS_SEED_INDEX;
assert(isscalar(seedIndex) && seedIndex==floor(seedIndex) && seedIndex>=1 && seedIndex<=10);
scriptDir=fileparts(mfilename('fullpath'));
conditionIndices=[1 4];
slugs=["J0_Heterogeneous_Both" "J065_Heterogeneous_Both"];
conditionLabels=["J=0" "J=0.65"];
rows={}; cursor=0; nReplicates=3;

for q=1:numel(conditionIndices)
    c=conditionIndices(q);
    file=fullfile(scriptDir,sprintf(['Fig3_KerrReservoir_NARMA10_Reproducible_' ...
        'MechanismSelection_C%02d_%s_Index%02d_Offset%04d_20260810_summary.mat'], ...
        c,slugs(q),seedIndex,100+seedIndex));
    assert(isfile(file),'Missing raw mechanism file: %s',file);
    S=load(file,'cfg','P','Xvirt','yN','results','pcaInfo');
    assert(isfield(S,'Xvirt'),'Robustness requires saved raw quadratures.');
    % Robustness is characterized on the validation bank.  Reuse the
    % lambda selected for this realization so that the independently
    % reconstructed clean pipeline must reproduce the saved central score.
    lambda=S.results.main.lambdaBest;
    clean=fitModel(S.Xvirt,S.yN,S.cfg,lambda,S.pcaInfo);
    cleanScore=evaluateModel(clean,S.Xvirt,S.yN,S.cfg.idxVal);
    fprintf('Clean reconstruction condition=%d seed=%d saved=%.12g rebuilt=%.12g delta=%.3e\n', ...
        c,seedIndex,S.results.main.valNRMSE,cleanScore, ...
        cleanScore-S.results.main.valNRMSE);
    assert(abs(cleanScore-S.results.main.valNRMSE)<1e-8, ...
        'Independent clean pipeline does not reproduce the central validation score.');
    cursor=cursor+1;
    rows(cursor,:)={seedIndex,c,conditionLabels(q),"clean",0,1,"zero_shot",lambda,cleanScore}; %#ok<SAGROW>

    specs={ ...
        "detector_snr_db",[40 30 20]; ...
        "shot_noise_photons",[1e5 1e4 1e3]; ...
        "quantization_bits",[12 8 6]; ...
        "correlated_noise_fraction",[0 .5 .9]; ...
        "retained_channel_fraction",[.75 .5 .25]; ...
        "gain_mismatch_sigma",[.01 .05 .10]; ...
        "sampling_jitter_fraction",[.01 .05 .10]; ...
        "failed_modes",[1 2 3]};
    for s=1:size(specs,1)
        perturbation=specs{s,1}; levels=specs{s,2};
        for level=levels
            for replicate=1:nReplicates
                rng(880000+10000*seedIndex+1000*q+100*s+10*find(levels==level,1)+replicate);
                Xp=perturbRaw(S.Xvirt,S.cfg,S.P,perturbation,level);
                zeroShot=evaluateModel(clean,Xp,S.yN,S.cfg.idxVal);
                cursor=cursor+1;
                rows(cursor,:)={seedIndex,c,conditionLabels(q),perturbation,level,replicate,"zero_shot",lambda,zeroShot};
                recalibrated=fitModel(Xp,S.yN,S.cfg,lambda,[]);
                recalScore=evaluateModel(recalibrated,Xp,S.yN,S.cfg.idxVal);
                cursor=cursor+1;
                rows(cursor,:)={seedIndex,c,conditionLabels(q),perturbation,level,replicate,"pca_readout_recalibrated",lambda,recalScore};
            end
        end
    end
end

T=cell2table(rows,'VariableNames',{'seedIndex','conditionIndex','condition', ...
    'perturbation','level','replicate','protocol','ridgeLambda','validationNRMSE'});
out=fullfile(scriptDir,sprintf('NARMAMeasurementRobustness_Index%02d_20260810.csv',seedIndex));
writetable(T,out);
fprintf('MEASUREMENT_ROBUSTNESS_PASS seed=%d rows=%d\n',seedIndex,height(T));

function model=fitModel(X,y,cfg,lambda,pcaReference)
    train=cfg.idxTrain(:);
    if isempty(pcaReference)
        mu=mean(X(train,:),1); sigma=std(X(train,:),0,1); sigma(sigma<1e-12)=1;
        Xz=(X-mu)./sigma;
        [~,~,V]=svd(Xz(train,:),'econ'); V=V(:,1:min(cfg.nPC,size(V,2)));
    else
        mu=pcaReference.mu;
        sigma=pcaReference.sig;
        V=pcaReference.Vpc;
        Xz=(X-mu)./sigma;
    end
    Z=Xz*V; D=[ones(size(Z,1),1) addTaps(Z,cfg.tapDelays)];
    muD=mean(D(train,:),1); sigmaD=std(D(train,:),0,1); sigmaD(sigmaD<1e-12)=1;
    Dz=(D-muD)./sigmaD; Dz(:,1)=1;
    yMean=mean(y(train)); yStd=std(y(train),0); if yStd<1e-14, yStd=1; end
    yz=(y(train)-yMean)/yStd; Xt=Dz(train,:);
    gram=Xt.'*Xt; gram=0.5*(gram+gram.');
    [basis,eigenvalues]=eig(gram,'vector');
    eigenvalues=max(real(eigenvalues),0);
    projected=basis.'*(Xt.'*yz);
    weights=basis*(projected./(eigenvalues+lambda));
    model=struct('mu',mu,'sigma',sigma,'V',V,'muD',muD,'sigmaD',sigmaD, ...
        'weights',weights,'yMean',yMean,'yStd',yStd,'tapDelays',cfg.tapDelays);
end

function score=evaluateModel(model,X,y,index)
    Z=((X-model.mu)./model.sigma)*model.V;
    D=[ones(size(Z,1),1) addTaps(Z,model.tapDelays)];
    Dz=(D-model.muD)./model.sigmaD; Dz(:,1)=1;
    prediction=model.yMean+model.yStd*(Dz(index,:)*model.weights);
    score=sqrt(mean((y(index)-prediction).^2))/std(y(index),1);
end

function Xt=addTaps(X,delays)
    [n,d]=size(X); Xt=zeros(n,d*numel(delays));
    for k=1:numel(delays)
        lag=delays(k); cols=(k-1)*d+(1:d);
        if lag==0, Xt(:,cols)=X; else, Xt(lag+1:end,cols)=X(1:end-lag,:); end
    end
end

function Xp=perturbRaw(X,cfg,P,kind,level)
    train=cfg.idxTrain(:); Xp=X;
    channelMean=mean(X(train,:),1);
    switch kind
        case "detector_snr_db"
            signalRms=sqrt(mean(X(train,:).^2,1));
            noiseStd=signalRms/10^(level/20);
            Xp=X+randn(size(X)).*noiseStd;
        case "shot_noise_photons"
            signalRms=sqrt(mean(X(train,:).^2,1));
            noiseStd=signalRms/sqrt(2*level);
            Xp=X+randn(size(X)).*noiseStd;
        case "quantization_bits"
            lo=min(X(train,:),[],1); hi=max(X(train,:),[],1); span=max(hi-lo,eps);
            bins=2^level-1; Xp=lo+round((min(max(X,lo),hi)-lo)./span*bins)./bins.*span;
        case "correlated_noise_fraction"
            signalRms=sqrt(mean(X(train,:).^2,1)); noiseStd=signalRms/10^(30/20);
            common=randn(size(X,1),1);
            noise=sqrt(1-level)*randn(size(X))+sqrt(level)*common*ones(1,size(X,2));
            Xp=X+noise.*noiseStd;
        case "retained_channel_fraction"
            keepCount=max(1,round(level*size(X,2))); keep=randperm(size(X,2),keepCount);
            removed=setdiff(1:size(X,2),keep);
            Xp(:,removed)=repmat(channelMean(removed),size(X,1),1);
        case "gain_mismatch_sigma"
            gain=1+level*randn(1,size(X,2)); Xp=X.*gain;
        case "sampling_jitter_fraction"
            previous=[X(1,:);X(1:end-1,:)]; Xp=(1-level)*X+level*previous;
        case "failed_modes"
            failed=randperm(P.N,min(P.N,round(level)));
            localDim=2*P.N; blocksPerCopy=numel(cfg.virtualNodeIdx);
            cols=[];
            for copy=1:cfg.numReservoirs
                copyOffset=(copy-1)*blocksPerCopy*localDim;
                for block=1:blocksPerCopy
                    blockOffset=copyOffset+(block-1)*localDim;
                    cols=[cols blockOffset+failed blockOffset+P.N+failed]; %#ok<AGROW>
                end
            end
            Xp(:,cols)=repmat(channelMean(cols),size(X,1),1);
        otherwise
            error('Unknown perturbation %s',kind);
    end
    assert(all(isfinite(Xp(:))));
end
