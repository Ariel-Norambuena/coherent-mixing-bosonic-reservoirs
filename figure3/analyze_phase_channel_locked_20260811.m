%% Analyze locked coherent phase-channel equalization and digital baselines.

clear;clc;close all;scriptDir=fileparts(mfilename('fullpath'));
lockedFile=fullfile(scriptDir,'configs','phase_channel_locked_config_20260811.json');
locked=jsondecode(fileread(lockedFile));offsets=locked.locked_offsets(:).';n=numel(offsets);
methods=["direct phase";"linear taps";"NVAR2";"bosonic J=0";"bosonic coupled"];
nMethod=numel(methods);nrmse=nan(n,nMethod);ber=nrmse;
[idxTrain,~,idxTest]=splitIndices();
for k=1:n
    [u,~,target,received]=make_phase_channel_dataset_20260811(22000,offsets(k));
    tag=sprintf('PhaseLocked_Index%02d_Offset%04d_20260811',k,offsets(k));
    file=fullfile(scriptDir,['Fig3_KerrReservoir_NARMA10_Reproducible_' tag '_summary.mat']);
    assert(isfile(file),'Missing phase locked summary %d.',k);
    S=load(file,'results','cfg');assert(S.cfg.evaluateTest);
    budget=S.results.featureAblation.budgetVariants;assert(isequal(size(budget),[2 1]));
    R0=budget{1,1}.readout{1};RJ=budget{2,1}.readout{1};
    y=R0.Yte(:);assert(isequal(y,RJ.Yte(:))&&numel(y)==numel(idxTest));
    direct=sign(real(received(idxTest)));direct(direct==0)=1;
    Xlinear=phaseFeatures(u,false);linear=ridgePredict(Xlinear,target,idxTrain,idxTest,locked.linear_baseline_lambda);
    Xnvar=phaseFeatures(u,true);nvar=ridgePredict(Xnvar,target,idxTrain,idxTest,locked.nvar2_baseline_lambda);
    predictions={direct,linear,nvar,R0.Yhat(:),RJ.Yhat(:)};
    for m=1:nMethod
        pred=predictions{m};nrmse(k,m)=sqrt(mean((pred-y).^2))/std(y,1);
        decisions=ones(size(pred));decisions(pred<0)=-1;ber(k,m)=mean(decisions~=y);
    end
end

pairImprovement=nrmse(:,4)-nrmse(:,5);pairBer=ber(:,4)-ber(:,5);
nrmseStats=pairedStats(pairImprovement,20260812);berStats=pairedStats(pairBer,20260813);
nvarMinusJ0=nrmse(:,3)-nrmse(:,4);nvarStats=pairedStats(nvarMinusJ0,20260814);
raw=table((1:n).',offsets(:),nrmse(:,1),nrmse(:,2),nrmse(:,3),nrmse(:,4),nrmse(:,5), ...
    ber(:,1),ber(:,2),ber(:,3),ber(:,4),ber(:,5), ...
    'VariableNames',{'pairIndex','seedOffset','directNRMSE','linearNRMSE','nvar2NRMSE','J0NRMSE','coupledNRMSE','directBER','linearBER','nvar2BER','J0BER','coupledBER'});
writetable(raw,fullfile(scriptDir,'PhaseChannelLocked_Raw_20260811.csv'));
meanNRMSE=mean(nrmse,1).';sdNRMSE=std(nrmse,0,1).';meanBER=mean(ber,1).';sdBER=std(ber,0,1).';
summaryTable=table(methods,meanNRMSE,sdNRMSE,meanBER,sdBER);writetable(summaryTable,fullfile(scriptDir,'PhaseChannelLocked_Summary_20260811.csv'));
audit.pairs=n;audit.coupled_nrmse_improved=sum(pairImprovement>0);audit.mean_nrmse_improvement=mean(pairImprovement);audit.nrmse_bootstrap_ci95=nrmseStats.ci;audit.nrmse_sign_flip_p=nrmseStats.p;audit.coupled_ber_improved=sum(pairBer>0);audit.mean_ber_improvement=mean(pairBer);audit.ber_bootstrap_ci95=berStats.ci;audit.ber_sign_flip_p=berStats.p;audit.config_sha256=sha256File(lockedFile);
audit.J0_better_than_NVAR2_pairs=sum(nvarMinusJ0>0);audit.mean_NVAR2_minus_J0_nrmse=mean(nvarMinusJ0);audit.NVAR2_minus_J0_bootstrap_ci95=nvarStats.ci;audit.NVAR2_minus_J0_sign_flip_p=nvarStats.p;
fid=fopen(fullfile(scriptDir,'PhaseChannelLocked_Audit_20260811.json'),'w');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',jsonencode(audit,PrettyPrint=true));

fig=figure('Color','w','Units','inches','Position',[1 1 8.2 4.2]);
tl=tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');colors=[.35 .35 .35;.20 .55 .72;.45 .28 .68;.15 .38 .70;.84 .24 .18];
nexttile;hold on;for m=1:nMethod,scatter(m+.10*linspace(-1,1,n),nrmse(:,m),18,colors(m,:),'filled','MarkerFaceAlpha',.42);plot([m-.22 m+.22],meanNRMSE(m)*[1 1],'-','Color',colors(m,:),'LineWidth',2);end;xticks(1:nMethod);xticklabels({'direct','linear','NVAR2','$J=0$','coupled'});set(gca,'TickLabelInterpreter','latex');xtickangle(20);ylabel('test NRMSE');title('(a) Phase-channel regression','Interpreter','latex');grid on;box on;
nexttile;hold on;for m=1:nMethod,scatter(m+.10*linspace(-1,1,n),ber(:,m),18,colors(m,:),'filled','MarkerFaceAlpha',.42);plot([m-.22 m+.22],meanBER(m)*[1 1],'-','Color',colors(m,:),'LineWidth',2);end;xticks(1:nMethod);xticklabels({'direct','linear','NVAR2','$J=0$','coupled'});set(gca,'TickLabelInterpreter','latex');xtickangle(20);ylabel('bit-error rate');title('(b) Symbol recovery','Interpreter','latex');grid on;box on;
title(tl,'Coherent BPSK phase-channel equalization','Interpreter','latex');set(findall(fig,'-property','FontSize'),'FontSize',11);
exportgraphics(fig,fullfile(scriptDir,'PhaseChannelLocked_20260811.pdf'),'ContentType','vector');exportgraphics(fig,fullfile(scriptDir,'PhaseChannelLocked_20260811.png'),'Resolution',300);close(fig);
fprintf(['PHASE_LOCKED_ANALYSIS_PASS coupling %d/%d delta=%.6f ' ...
    'J0_vs_NVAR2 %d/%d delta=%.6f BER %d/%d delta=%.6f\n'], ...
    sum(pairImprovement>0),n,mean(pairImprovement),sum(nvarMinusJ0>0),n, ...
    mean(nvarMinusJ0),sum(pairBer>0),n,mean(pairBer));

function [idxTrain,idxVal,idxTest]=splitIndices()
start=2000+20+1;idxTrain=start:(start+12000-1);idxVal=(idxTrain(end)+1):(idxTrain(end)+4000);idxTest=(idxVal(end)+1):(idxVal(end)+3000);
end
function X=phaseFeatures(u,quadratic)
delays=0:24;T=numel(u);L=zeros(T,numel(delays));for d=delays,L(:,d+1)=[zeros(d,1);u(1:end-d)];end;if~quadratic,X=L;return;end;n=size(L,2);Q=zeros(T,n*(n+1)/2);q=0;for a=1:n,for b=a:n,q=q+1;Q(:,q)=L(:,a).*L(:,b);end,end;X=[L Q];
end
function yhat=ridgePredict(X,y,idxTrain,idxTest,lambda)
mu=mean(X(idxTrain,:),1);sig=std(X(idxTrain,:),0,1);sig(sig<1e-12)=1;Xs=(X-mu)./sig;A=[ones(numel(idxTrain),1) Xs(idxTrain,:)];T=[ones(numel(idxTest),1) Xs(idxTest,:)];G=A'*A;R=eye(size(G));R(1,1)=0;w=(G+lambda*R)\(A'*y(idxTrain));yhat=T*w;
end
function out=pairedStats(delta,seed)
rng(seed);n=numel(delta);B=100000;idx=randi(n,n,B);out.ci=prctile(mean(delta(idx),1),[2.5 97.5]);signs=2*(rand(n,B)>.5)-1;null=mean(delta.*signs,1);out.p=(1+sum(abs(null)>=abs(mean(delta))))/(B+1);
end
function digest=sha256File(path)
engine=java.security.MessageDigest.getInstance('SHA-256');fid=fopen(path,'rb');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));bytes=typecast(engine.digest(fread(fid,Inf,'*uint8')),'uint8');digest=lower(reshape(dec2hex(bytes,2).',1,[]));
end
