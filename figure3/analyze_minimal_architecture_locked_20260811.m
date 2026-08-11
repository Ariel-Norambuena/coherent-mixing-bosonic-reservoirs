%% Analyze the fresh 30-pair NARMA10 bank for the minimal architecture.

clear;clc;close all;scriptDir=fileparts(mfilename('fullpath'));
lockedFile=fullfile(scriptDir,'configs','minimal_architecture_locked_config_20260811.json');
locked=jsondecode(fileread(lockedFile));n=numel(locked.locked_offsets);
control=nan(n,1);coupled=control;datasetSeed=control;
for k=1:n
    tag=sprintf('MinimalFreshNARMA_Index%02d_Offset%04d_20260811',k,locked.locked_offsets(k));
    prefix=fullfile(scriptDir,['Fig3_KerrReservoir_NARMA10_Reproducible_' tag]);
    C=readtable([prefix '_FeatureBudgetVariants_summary.csv'],'TextType','string','Delimiter',',');
    S=load([prefix '_summary.mat'],'datasetSeed','cfg');assert(height(C)==2&&S.cfg.evaluateTest);
    control(k)=C.testNRMSE(abs(C.J-locked.J_control)<1e-14);
    coupled(k)=C.testNRMSE(abs(C.J-locked.J_intervention)<1e-14);
    datasetSeed(k)=S.datasetSeed;
end
delta=control-coupled;stats=pairedStats(delta,20260811);
raw=table((1:n).',locked.locked_offsets(:),datasetSeed,control,coupled,delta, ...
    'VariableNames',{'pairIndex','seedOffset','datasetSeed','controlNRMSE','coupledNRMSE','improvement'});
writetable(raw,fullfile(scriptDir,'MinimalArchitectureFreshNARMA_Raw_20260811.csv'));
summary.metric='NRMSE';summary.pairs=n;summary.control_mean=mean(control);
summary.coupled_mean=mean(coupled);summary.mean_improvement=mean(delta);
summary.improved_pairs=sum(delta>0);summary.bootstrap_ci95=stats.ci;
summary.cohen_dz=stats.dz;summary.sign_flip_p=stats.p;
summary.config_sha256=sha256File(lockedFile);
fid=fopen(fullfile(scriptDir,'MinimalArchitectureFreshNARMA_Summary_20260811.json'),'w');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',jsonencode(summary,PrettyPrint=true));
fig=figure('Color','w','Units','inches','Position',[1 1 5.7 4.3]);hold on;
for k=1:n,plot([0 1],[control(k) coupled(k)],'-','Color',[.78 .78 .78],'LineWidth',.8);end
scatter(zeros(n,1),control,28,[0.12 0.38 0.72],'filled');scatter(ones(n,1),coupled,28,[0.82 0.22 0.18],'filled');
plot([-.12 .12],mean(control)*[1 1],'k-','LineWidth',2);plot([.88 1.12],mean(coupled)*[1 1],'k-','LineWidth',2);
xlim([-.35 1.35]);xticks([0 1]);xticklabels({'$J=0$','selected $J$'});set(gca,'TickLabelInterpreter','latex');ylabel('test NRMSE');title('Fresh-bank minimal architecture','Interpreter','latex');grid on;box on;set(findall(fig,'-property','FontSize'),'FontSize',11);
exportgraphics(fig,fullfile(scriptDir,'MinimalArchitectureFreshNARMA_20260811.pdf'),'ContentType','vector');exportgraphics(fig,fullfile(scriptDir,'MinimalArchitectureFreshNARMA_20260811.png'),'Resolution',300);close(fig);
fprintf('MINIMAL_LOCKED_ANALYSIS_PASS %d/%d mean_delta=%.6f CI=[%.6f %.6f]\n',sum(delta>0),n,mean(delta),stats.ci(1),stats.ci(2));

function out=pairedStats(delta,seed)
rng(seed);n=numel(delta);B=100000;idx=randi(n,n,B);boot=mean(delta(idx),1);out.ci=prctile(boot,[2.5 97.5]);out.dz=mean(delta)/std(delta);signs=2*(rand(n,B)>.5)-1;null=mean(delta.*signs,1);out.p=(1+sum(abs(null)>=abs(mean(delta))))/(B+1);
end
function digest=sha256File(path)
engine=java.security.MessageDigest.getInstance('SHA-256');fid=fopen(path,'rb');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));bytes=typecast(engine.digest(fread(fid,Inf,'*uint8')),'uint8');digest=lower(reshape(dec2hex(bytes,2).',1,[]));
end
