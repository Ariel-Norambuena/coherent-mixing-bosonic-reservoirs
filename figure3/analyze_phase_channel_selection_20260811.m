%% Select global ridge values for the phase task and its digital baselines.

clear;clc;close all;scriptDir=fileparts(mfilename('fullpath'));
protocolPath=fullfile(scriptDir,'configs','additional_benchmark_protocol_20260811.json');
minimalPath=fullfile(scriptDir,'configs','minimal_architecture_locked_config_20260811.json');
protocol=jsondecode(fileread(protocolPath));minimal=jsondecode(fileread(minimalPath));
offsets=protocol.phase_selection_offsets(:).';lambdaGrid=protocol.lambda_grid(:);nSeed=numel(offsets);
Jvalues=[minimal.J_control minimal.J_intervention];curves=nan(nSeed,2,numel(lambdaGrid));
for s=1:nSeed
    for c=1:2
        tag=sprintf('PhaseSelection_S%02d_C%02d_Offset%04d_20260811',s,c,offsets(s));
        file=fullfile(scriptDir,['Fig3_KerrReservoir_NARMA10_Reproducible_' tag '_summary.mat']);assert(isfile(file),'Missing %s.',file);
        S=load(file,'cfg','P','results');assert(~S.cfg.evaluateTest&&abs(S.P.J0-Jvalues(c))<1e-14);
        curves(s,c,:)=S.results.main.valCurve(:);
    end
end
reservoirLambda=nan(2,1);reservoirMean=reservoirLambda;reservoirSd=reservoirLambda;
for c=1:2
    meanCurve=squeeze(mean(curves(:,c,:),1));[~,idx]=min(meanCurve);reservoirLambda(c)=lambdaGrid(idx);
    vals=squeeze(curves(:,c,idx));reservoirMean(c)=mean(vals);reservoirSd(c)=std(vals);
end

baselineCurves=nan(nSeed,2,numel(lambdaGrid));
for s=1:nSeed
    [u,~,y]=make_phase_channel_dataset_20260811(22000,offsets(s));
    [idxTrain,idxVal]=splitIndices();
    for model=1:2
        X=phaseFeatures(u,model==2);baselineCurves(s,model,:)=ridgeCurve(X,y,idxTrain,idxVal,lambdaGrid);
    end
end
baselineLambda=nan(2,1);baselineMean=baselineLambda;baselineSd=baselineLambda;
for model=1:2
    meanCurve=squeeze(mean(baselineCurves(:,model,:),1));[~,idx]=min(meanCurve);baselineLambda(model)=lambdaGrid(idx);
    vals=squeeze(baselineCurves(:,model,idx));baselineMean(model)=mean(vals);baselineSd(model)=std(vals);
end

locked.schema_version=1;locked.status='frozen_not_executed';locked.created_date='2026-08-11';
locked.protocol_sha256=sha256File(protocolPath);locked.minimal_architecture_sha256=sha256File(minimalPath);
locked.selection_offsets=offsets;locked.locked_offsets=protocol.phase_locked_offsets(:).';
locked.J_control=minimal.J_control;locked.J_intervention=minimal.J_intervention;locked.K=minimal.K;
locked.input_gain_scale=minimal.input_gain_scale;locked.num_reservoirs=minimal.num_reservoirs;
locked.steps_per_sample=minimal.steps_per_sample;locked.virtual_node_indices=minimal.virtual_node_indices(:).';
locked.tap_delays=minimal.tap_delays(:).';locked.n_pc=minimal.n_pc;locked.input_mask=minimal.input_mask(:);locked.input_bias=minimal.input_bias(:);
locked.ridge_lambda_control=reservoirLambda(1);locked.ridge_lambda_intervention=reservoirLambda(2);
locked.linear_baseline_lambda=baselineLambda(1);locked.nvar2_baseline_lambda=baselineLambda(2);
locked.linear_baseline_delays=0:24;locked.nvar2_baseline_delays=0:24;
locked.channel.taps_real=real([1.00;0.58*exp(1i*.72);0.34*exp(-1i*1.05);0.21*exp(1i*1.41);0.12*exp(-1i*.38)]/norm([1.00;0.58*exp(1i*.72);0.34*exp(-1i*1.05);0.21*exp(1i*1.41);0.12*exp(-1i*.38)]));
locked.channel.taps_imag=imag([1.00;0.58*exp(1i*.72);0.34*exp(-1i*1.05);0.21*exp(1i*1.41);0.12*exp(-1i*.38)]/norm([1.00;0.58*exp(1i*.72);0.34*exp(-1i*1.05);0.21*exp(1i*1.41);0.12*exp(-1i*.38)]));
locked.channel.gamma=0.42;locked.channel.snr_db=24;locked.channel.decision_delay=2;
locked.selection_validation_mean=[reservoirMean(:);baselineMean(:)];
lockedFile=fullfile(scriptDir,'configs','phase_channel_locked_config_20260811.json');writeFrozenJson(lockedFile,locked);

method=["bosonic J=0";"bosonic coupled";"linear taps";"NVAR2"];meanValidationNRMSE=[reservoirMean;baselineMean];sdValidationNRMSE=[reservoirSd;baselineSd];ridgeLambda=[reservoirLambda;baselineLambda];
writetable(table(method,meanValidationNRMSE,sdValidationNRMSE,ridgeLambda),fullfile(scriptDir,'PhaseChannelSelectionSummary_20260811.csv'));
fprintf('PHASE_SELECTION_ANALYSIS_PASS J0=%.5f coupled=%.5f linear=%.5f NVAR2=%.5f\n',meanValidationNRMSE);

function [idxTrain,idxVal]=splitIndices()
start=2000+20+1;idxTrain=start:(start+12000-1);idxVal=(idxTrain(end)+1):(idxTrain(end)+4000);
end
function X=phaseFeatures(u,quadratic)
delays=0:24;T=numel(u);L=zeros(T,numel(delays));for d=delays,L(:,d+1)=[zeros(d,1);u(1:end-d)];end
if ~quadratic,X=L;return;end
n=size(L,2);Q=zeros(T,n*(n+1)/2);q=0;for a=1:n,for b=a:n,q=q+1;Q(:,q)=L(:,a).*L(:,b);end,end;X=[L Q];
end
function curve=ridgeCurve(X,y,idxTrain,idxVal,lambdaGrid)
mu=mean(X(idxTrain,:),1);sig=std(X(idxTrain,:),0,1);sig(sig<1e-12)=1;Xs=(X-mu)./sig;A=[ones(numel(idxTrain),1) Xs(idxTrain,:)];V=[ones(numel(idxVal),1) Xs(idxVal,:)];G=A'*A;b=A'*y(idxTrain);R=eye(size(G));R(1,1)=0;curve=nan(numel(lambdaGrid),1);den=std(y(idxVal),1);for k=1:numel(lambdaGrid),w=(G+lambdaGrid(k)*R)\b;curve(k)=sqrt(mean((V*w-y(idxVal)).^2))/den;end
end
function writeFrozenJson(path,value)
text=[jsonencode(value,PrettyPrint=true) newline];if isfile(path),assert(strcmp(fileread(path),text),'Frozen phase config differs.');else,fid=fopen(path,'w');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));fprintf(fid,'%s',text);end;hash=sha256File(path);checksum=sprintf('%s  %s\n',hash,string(extractAfter(path,filesep)));checksumPath=[path '.sha256'];if isfile(checksumPath),assert(strcmp(fileread(checksumPath),checksum));else,fid=fopen(checksumPath,'w');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));fprintf(fid,'%s',checksum);end
end
function digest=sha256File(path)
engine=java.security.MessageDigest.getInstance('SHA-256');fid=fopen(path,'rb');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));bytes=typecast(engine.digest(fread(fid,Inf,'*uint8')),'uint8');digest=lower(reshape(dec2hex(bytes,2).',1,[]));
end
