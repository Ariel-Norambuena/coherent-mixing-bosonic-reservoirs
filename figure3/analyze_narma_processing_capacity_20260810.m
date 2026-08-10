%% analyze_narma_processing_capacity_20260810.m
% Validation capacities from compact, train-fitted PCA states (no external taps).
clear; close all; clc;
scriptDir = fileparts(mfilename('fullpath'));
conditionIndices = [1 2 3 4];
labels = ["J=0, heterogeneous, both"; "J=.65, uniform G, detuning"; ...
    "J=.65, heterogeneous G, detuning"; "J=.65, heterogeneous, both"];
slugs = ["J0_Heterogeneous_Both"; "J065_UniformG_DetuningOnly"; ...
    "J065_HeterogeneousG_DetuningOnly"; "J065_Heterogeneous_Both"];
maxLinearLag=20; maxNonlinearLag=10; ridge=1e-6; nSeeds=10;
taskRows={}; cursor=0;
for q=1:numel(conditionIndices)
    c=conditionIndices(q);
    for seedIndex=1:nSeeds
        file=fullfile(scriptDir,sprintf(['Fig3_KerrReservoir_NARMA10_Reproducible_' ...
            'MechanismSelection_C%02d_%s_Index%02d_Offset%04d_20260810_summary.mat'], ...
            c,slugs(q),seedIndex,100+seedIndex));
        S=load(file,'cfg','uEnc','Zvirt');
        train=S.cfg.idxTrain(:); val=S.cfg.idxVal(:); u=S.uEnc(:);
        mu=mean(S.Zvirt(train,:),1); sigma=std(S.Zvirt(train,:),0,1); sigma(sigma<1e-12)=1;
        Z=(S.Zvirt-mu)./sigma; X=[ones(size(Z,1),1) Z];
        for lag=1:maxLinearLag
            target=circshift(u,lag); validTrain=train(train>lag); validVal=val(val>lag);
            cap=capacityScore(X,target,validTrain,validVal,ridge);
            cursor=cursor+1; taskRows(cursor,:)={seedIndex,c,labels(q),"linear",lag,0,cap}; %#ok<SAGROW>
        end
        for lag=1:maxNonlinearLag
            target=.5*(3*circshift(u,lag).^2-1); validTrain=train(train>lag); validVal=val(val>lag);
            cap=capacityScore(X,target,validTrain,validVal,ridge);
            cursor=cursor+1; taskRows(cursor,:)={seedIndex,c,labels(q),"quadratic",lag,lag,cap}; %#ok<SAGROW>
        end
        for a=1:maxNonlinearLag
            for b=a+1:maxNonlinearLag
                target=circshift(u,a).*circshift(u,b); validTrain=train(train>b); validVal=val(val>b);
                cap=capacityScore(X,target,validTrain,validVal,ridge);
                cursor=cursor+1; taskRows(cursor,:)={seedIndex,c,labels(q),"cross_product",a,b,cap}; %#ok<SAGROW>
            end
        end
    end
end
raw=cell2table(taskRows,'VariableNames',{'seedIndex','conditionIndex','condition','capacityType','lagA','lagB','capacity'});
writetable(raw,fullfile(scriptDir,'NARMAProcessingCapacity_Raw_20260810.csv'));
types=["linear" "quadratic" "cross_product"];
sumRows={}; cursor=0;
for q=1:numel(conditionIndices)
    for t=1:numel(types)
        seedTotals=zeros(nSeeds,1);
        for s=1:nSeeds
            R=raw(raw.conditionIndex==conditionIndices(q) & raw.seedIndex==s & raw.capacityType==types(t),:);
            seedTotals(s)=sum(R.capacity);
        end
        cursor=cursor+1; sumRows(cursor,:)={conditionIndices(q),labels(q),types(t), ...
            mean(seedTotals),std(seedTotals),median(seedTotals),quantile(seedTotals,.25),quantile(seedTotals,.75)}; %#ok<SAGROW>
    end
end
summary=cell2table(sumRows,'VariableNames',{'conditionIndex','condition','capacityType', ...
    'meanCapacity','sdCapacity','medianCapacity','q25Capacity','q75Capacity'});
writetable(summary,fullfile(scriptDir,'NARMAProcessingCapacity_Summary_20260810.csv'));

fig=figure('Color','w','Visible','off','Units','inches','Position',[1 1 7.2 3.25]);
tiledlayout(1,2,'Padding','compact','TileSpacing','compact'); colors=lines(numel(conditionIndices));
ax1=nexttile; hold(ax1,'on');
for q=1:numel(conditionIndices)
    means=zeros(maxLinearLag,1); sem=zeros(maxLinearLag,1);
    for lag=1:maxLinearLag
        R=raw(raw.conditionIndex==conditionIndices(q) & raw.capacityType=="linear" & raw.lagA==lag,:);
        means(lag)=mean(R.capacity); sem(lag)=std(R.capacity)/sqrt(height(R));
    end
    errorbar(ax1,1:maxLinearLag,means,sem,'-o','Color',colors(q,:),'MarkerSize',3,'LineWidth',1.1,'CapSize',3);
end
xlabel(ax1,'delay'); ylabel(ax1,'linear memory capacity'); title(ax1,'(a) Memory functions','FontWeight','normal');
legend(ax1,cellstr(labels),'Location','northeast','Box','off'); grid(ax1,'on'); box(ax1,'on');
ax2=nexttile; hold(ax2,'on');
M=zeros(numel(conditionIndices),numel(types)); E=M;
for q=1:numel(conditionIndices)
    for t=1:numel(types)
        R=summary(summary.conditionIndex==conditionIndices(q) & summary.capacityType==types(t),:);
        M(q,t)=R.meanCapacity; E(q,t)=R.sdCapacity;
    end
end
b=bar(ax2,M,'grouped');
for t=1:numel(types)
    x=b(t).XEndPoints; errorbar(ax2,x,M(:,t),E(:,t),'k.','LineWidth',1,'CapSize',4);
end
set(ax2,'XTick',1:numel(conditionIndices),'XTickLabel',string(conditionIndices));
xlabel(ax2,'ablation index'); ylabel(ax2,'summed capacity'); title(ax2,'(b) Nonlinear processing capacities','FontWeight','normal');
legend(ax2,{'linear','quadratic','cross product'},'Location','best','Box','off'); grid(ax2,'on'); box(ax2,'on');
set([ax1 ax2],'FontName','Arial','FontSize',9.5,'LineWidth',.8);
exportgraphics(fig,fullfile(scriptDir,'NARMAProcessingCapacity_20260810.pdf'),'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'NARMAProcessingCapacity_20260810.png'),'Resolution',300); close(fig);
fprintf('PROCESSING_CAPACITY_ANALYSIS_PASS rows=%d\n',height(raw));

function score=capacityScore(X,target,train,val,ridge)
    Xt=X(train,:); yt=target(train); Xv=X(val,:); yv=target(val);
    R=Xt.'*Xt + ridge*diag([0 ones(1,size(X,2)-1)]);
    weights=R\(Xt.'*yt); prediction=Xv*weights;
    score=max(0,1-sum((yv-prediction).^2)/sum((yv-mean(yv)).^2));
    if ~isfinite(score), score=0; end
end

