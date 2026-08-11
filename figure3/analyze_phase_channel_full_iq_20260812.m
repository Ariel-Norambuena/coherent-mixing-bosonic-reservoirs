%% Reviewer-triggered full-I/Q digital baselines for the phase-stream task.
% Ridge values are selected on offsets 201--210 and evaluated once on the
% previously locked offsets 4001--4030. No reservoir trajectory is rerun.

clear;clc;close all;scriptDir=fileparts(mfilename('fullpath'));
protocol=jsondecode(fileread(fullfile(scriptDir,'configs', ...
    'additional_benchmark_protocol_20260811.json')));
lambdaGrid=protocol.lambda_grid(:);selectionOffsets=protocol.phase_selection_offsets(:).';
lockedOffsets=protocol.phase_locked_offsets(:).';models=["full-I/Q linear";"full-I/Q NVAR2"];
coefficientCount=[51;1326];selectionCurves=nan(numel(selectionOffsets),2,numel(lambdaGrid));

for s=1:numel(selectionOffsets)
    [~,~,target,received]=make_phase_channel_dataset_20260811(22000,selectionOffsets(s));
    [idxTrain,idxVal,~]=splitIndices();
    L=iqLagFeatures(received);
    for model=1:2
        if model==1,X=L;else,X=quadraticFeatures(L);end
        selectionCurves(s,model,:)=ridgeCurveFast(X,target,idxTrain,idxVal,lambdaGrid);
        clear X
    end
end

selectedLambda=nan(2,1);meanValidationNRMSE=selectedLambda;sdValidationNRMSE=selectedLambda;
for model=1:2
    meanCurve=squeeze(mean(selectionCurves(:,model,:),1));[~,idx]=min(meanCurve);
    selectedLambda(model)=lambdaGrid(idx);vals=squeeze(selectionCurves(:,model,idx));
    meanValidationNRMSE(model)=mean(vals);sdValidationNRMSE(model)=std(vals);
end
selectionTable=table(models,coefficientCount,selectedLambda,meanValidationNRMSE,sdValidationNRMSE);
writetable(selectionTable,fullfile(scriptDir,'PhaseChannelFullIQ_Selection_20260812.csv'));

n=numel(lockedOffsets);nrmse=nan(n,2);ber=nrmse;evm=nrmse;
[idxTrain,~,idxTest]=splitIndices();
for s=1:n
    [~,~,target,received]=make_phase_channel_dataset_20260811(22000,lockedOffsets(s));
    L=iqLagFeatures(received);
    for model=1:2
        if model==1,X=L;else,X=quadraticFeatures(L);end
        pred=ridgePredict(X,target,idxTrain,idxTest,selectedLambda(model));
        y=target(idxTest);err=pred-y;nrmse(s,model)=sqrt(mean(err.^2))/std(y,1);
        evm(s,model)=sqrt(mean(err.^2));decision=ones(size(pred));decision(pred<0)=-1;
        ber(s,model)=mean(decision~=y);clear X pred
    end
end
raw=table((1:n).',lockedOffsets(:),nrmse(:,1),nrmse(:,2),ber(:,1),ber(:,2), ...
    evm(:,1),evm(:,2),'VariableNames',{'pairIndex','seedOffset','fullIQLinearNRMSE', ...
    'fullIQNVAR2NRMSE','fullIQLinearBER','fullIQNVAR2BER','fullIQLinearEVM','fullIQNVAR2EVM'});
writetable(raw,fullfile(scriptDir,'PhaseChannelFullIQ_Raw_20260812.csv'));
meanTestNRMSE=mean(nrmse,1).';sdTestNRMSE=std(nrmse,0,1).';
meanBER=mean(ber,1).';sdBER=std(ber,0,1).';meanEVM=mean(evm,1).';sdEVM=std(evm,0,1).';
summaryTable=table(models,coefficientCount,selectedLambda,meanTestNRMSE,sdTestNRMSE, ...
    meanBER,sdBER,meanEVM,sdEVM);
writetable(summaryTable,fullfile(scriptDir,'PhaseChannelFullIQ_Summary_20260812.csv'));

oldRaw=readtable(fullfile(scriptDir,'PhaseChannelLocked_Raw_20260811.csv'));
assert(isequal(oldRaw.seedOffset,lockedOffsets(:)));
deltaPhaseNvarMinusFullIqNvar=oldRaw.nvar2NRMSE-nrmse(:,2);
deltaJ0MinusFullIqNvar=oldRaw.J0NRMSE-nrmse(:,2);
audit.analysis='reviewer-triggered post-review baseline';audit.selection_offsets=selectionOffsets;
audit.locked_offsets=lockedOffsets;audit.full_iq_nvar_better_than_phase_nvar_pairs=sum(deltaPhaseNvarMinusFullIqNvar>0);
audit.mean_phase_nvar_minus_full_iq_nvar=mean(deltaPhaseNvarMinusFullIqNvar);
audit.full_iq_nvar_better_than_bosonic_J0_pairs=sum(deltaJ0MinusFullIqNvar>0);
audit.mean_bosonic_J0_minus_full_iq_nvar=mean(deltaJ0MinusFullIqNvar);
fid=fopen(fullfile(scriptDir,'PhaseChannelFullIQ_Audit_20260812.json'),'w');assert(fid>=0);
cleanup=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',jsonencode(audit,PrettyPrint=true));

allValues=[oldRaw.nvar2NRMSE,nrmse(:,1),nrmse(:,2),oldRaw.J0NRMSE,oldRaw.coupledNRMSE];
labels={'phase NVAR2','I/Q linear','I/Q NVAR2','$J=0$','coupled'};
colors=[.46 .30 .66;.22 .58 .68;.12 .42 .58;.18 .38 .70;.84 .25 .18];
fig=figure('Color','w','Visible','off','Units','inches','Position',[1 1 7.2 3.6]);
ax=axes(fig);hold(ax,'on');box(ax,'on');grid(ax,'on');
for m=1:5
    scatter(ax,m+.09*linspace(-1,1,n),allValues(:,m),18,colors(m,:),'filled', ...
        'MarkerFaceAlpha',.40);plot(ax,[m-.22 m+.22],mean(allValues(:,m))*[1 1], ...
        '-','Color',colors(m,:),'LineWidth',2);
end
xticks(ax,1:5);xticklabels(ax,labels);set(ax,'TickLabelInterpreter','latex', ...
    'FontName','Arial','FontSize',11,'LineWidth',.8);xtickangle(ax,15);
ylabel(ax,'locked-test NRMSE');title(ax,'Phase-only task and full-I/Q audit','FontWeight','normal');
exportgraphics(fig,fullfile(scriptDir,'PhaseChannelFullIQ_20260812.pdf'),'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'PhaseChannelFullIQ_20260812.png'),'Resolution',300);close(fig);
fprintf(['PHASE_FULL_IQ_PASS linear=%.6f NVAR2=%.6f phaseNVARminusIQ=%.6f ' ...
    'J0minusIQ=%.6f\n'],meanTestNRMSE,mean(deltaPhaseNvarMinusFullIqNvar),mean(deltaJ0MinusFullIqNvar));

function [idxTrain,idxVal,idxTest]=splitIndices()
start=2021;idxTrain=start:(start+12000-1);idxVal=(idxTrain(end)+1):(idxTrain(end)+4000);idxTest=(idxVal(end)+1):(idxVal(end)+3000);
end
function L=iqLagFeatures(received)
delays=0:24;T=numel(received);L=zeros(T,2*numel(delays));
for k=1:numel(delays),d=delays(k);z=[zeros(d,1);received(1:end-d)];L(:,2*k-1)=real(z);L(:,2*k)=imag(z);end
end
function X=quadraticFeatures(L)
n=size(L,2);T=size(L,1);Q=zeros(T,n*(n+1)/2);q=0;
for a=1:n,for b=a:n,q=q+1;Q(:,q)=L(:,a).*L(:,b);end,end;X=[L Q];
end
function curve=ridgeCurveFast(X,y,idxTrain,idxVal,lambdaGrid)
mu=mean(X(idxTrain,:),1);sig=std(X(idxTrain,:),0,1);sig(sig<1e-12)=1;
A=(X(idxTrain,:)-mu)./sig;V=(X(idxVal,:)-mu)./sig;ym=mean(y(idxTrain));yc=y(idxTrain)-ym;
G=A'*A;G=(G+G')/2;b=A'*yc;[Q,d]=eig(G,'vector');d=max(real(d),0);qb=Q'*b;
curve=nan(numel(lambdaGrid),1);den=std(y(idxVal),1);
for k=1:numel(lambdaGrid),w=Q*(qb./(d+lambdaGrid(k)));pred=ym+V*w;curve(k)=sqrt(mean((pred-y(idxVal)).^2))/den;end
end
function pred=ridgePredict(X,y,idxTrain,idxTest,lambda)
mu=mean(X(idxTrain,:),1);sig=std(X(idxTrain,:),0,1);sig(sig<1e-12)=1;
A=(X(idxTrain,:)-mu)./sig;T=(X(idxTest,:)-mu)./sig;ym=mean(y(idxTrain));yc=y(idxTrain)-ym;
G=A'*A;G=(G+G')/2;w=(G+lambda*eye(size(G)))\(A'*yc);pred=ym+T*w;
end
