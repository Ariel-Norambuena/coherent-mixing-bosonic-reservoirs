%% Combined minimal-architecture and phase-task result figure.

clear;close all;clc;scriptDir=fileparts(mfilename('fullpath'));
stage=readtable(fullfile(scriptDir,'MinimalArchitectureStageA_Summary_20260811.csv'));
copySummary=readtable(fullfile(scriptDir,'MinimalArchitectureCopySelection_20260811.csv'));
copyRaw=readtable(fullfile(scriptDir,'MinimalArchitectureCopySelection_Raw_20260811.csv'));
narma=readtable(fullfile(scriptDir,'MinimalArchitectureFreshNARMA_Raw_20260811.csv'));
phase=readtable(fullfile(scriptDir,'PhaseChannelLocked_Raw_20260811.csv'));
copyValues=nan(10,3);
for c=1:3
    rows=copyRaw.copies==c;
    values=sortrows(copyRaw(rows,:), 'selectionIndex');
    assert(height(values)==10);
    copyValues(:,c)=values.validationNRMSE;
end

blue=[.12 .40 .72];red=[.83 .24 .18];orange=[.93 .60 .08];purple=[.45 .28 .68];gray=[.62 .64 .67];
fig=figure('Color','w','Visible','off','Units','inches','Position',[1 1 7.5 6.0]);
tiledlayout(2,2,'Padding','compact','TileSpacing','compact');
ax1=nexttile;hold(ax1,'on');box(ax1,'on');grid(ax1,'on');gains=unique(stage.inputGainScale).';colors=[blue;red;orange];
for q=1:numel(gains),rows=abs(stage.inputGainScale-gains(q))<1e-14;T=sortrows(stage(rows,:),'J');errorbar(ax1,T.J,T.meanValidationNRMSE,T.sdValidationNRMSE/sqrt(10),'-o','Color',colors(q,:),'LineWidth',1.4,'MarkerSize',5,'DisplayName',sprintf('$g=%.2f$',gains(q)));end
xlabel(ax1,'$J$','Interpreter','latex');ylabel(ax1,'validation NRMSE');title(ax1,'(a) Global deterministic selection','FontWeight','normal');legend(ax1,'Interpreter','latex','Location','northeast','Box','off');
ax2=nexttile;hold(ax2,'on');box(ax2,'on');grid(ax2,'on');for s=1:10,plot(ax2,1:3,copyValues(s,:),'-','Color',[.78 .78 .78],'LineWidth',.8);end;errorbar(ax2,copySummary.copies,copySummary.meanValidationNRMSE,copySummary.sdValidationNRMSE/sqrt(10),'-o','Color',blue,'LineWidth',1.6,'MarkerSize',6);xticks(ax2,1:3);xlabel(ax2,'deterministic copies');ylabel(ax2,'validation NRMSE');title(ax2,'(b) Exact copy redundancy','FontWeight','normal');
ax3=nexttile;hold(ax3,'on');box(ax3,'on');grid(ax3,'on');n=height(narma);for k=1:n,plot(ax3,[0 1],[narma.controlNRMSE(k) narma.coupledNRMSE(k)],'-','Color',[.80 .80 .80],'LineWidth',.7);end;scatter(ax3,zeros(n,1),narma.controlNRMSE,18,blue,'filled');scatter(ax3,ones(n,1),narma.coupledNRMSE,18,red,'filled');plot(ax3,[-.12 .12],mean(narma.controlNRMSE)*[1 1],'k-','LineWidth',1.8);plot(ax3,[.88 1.12],mean(narma.coupledNRMSE)*[1 1],'k-','LineWidth',1.8);xlim(ax3,[-.35 1.35]);xticks(ax3,[0 1]);xticklabels(ax3,{'$J=0$','$J=0.65$'});set(ax3,'TickLabelInterpreter','latex');ylabel(ax3,'test NRMSE');title(ax3,'(c) Fresh NARMA10 bank','FontWeight','normal');
ax4=nexttile;hold(ax4,'on');box(ax4,'on');grid(ax4,'on');values=[phase.linearNRMSE phase.nvar2NRMSE phase.J0NRMSE phase.coupledNRMSE];methodColors=[gray;purple;blue;red];for m=1:4,scatter(ax4,m+.08*linspace(-1,1,height(phase)),values(:,m),14,methodColors(m,:),'filled','MarkerFaceAlpha',.38);plot(ax4,[m-.20 m+.20],mean(values(:,m))*[1 1],'-','Color',methodColors(m,:),'LineWidth',1.8);end;xticks(ax4,1:4);xticklabels(ax4,{'linear','NVAR2','$J=0$','$J=0.65$'});set(ax4,'TickLabelInterpreter','latex');xtickangle(ax4,18);ylabel(ax4,'test NRMSE');title(ax4,'(d) Coherent phase equalization','FontWeight','normal');ylim(ax4,[.20 .73]);
set([ax1 ax2 ax3 ax4],'FontName','Arial','FontSize',10.5,'LineWidth',.8);
exportgraphics(fig,fullfile(scriptDir,'Figure6_MinimalArchitectureTasks_20260811.pdf'),'ContentType','vector');exportgraphics(fig,fullfile(scriptDir,'Figure6_MinimalArchitectureTasks_20260811.png'),'Resolution',300);close(fig);
fprintf('FIGURE_MINIMAL_PHASE_PASS\n');
