%% Combined minimal-architecture and phase-task result figure.

clear;close all;clc;scriptDir=fileparts(mfilename('fullpath'));
stage=readtable(fullfile(scriptDir,'MinimalArchitectureStageA_Summary_20260811.csv'));
narma=readtable(fullfile(scriptDir,'MinimalArchitectureFreshNARMA_Raw_20260811.csv'));
phase=readtable(fullfile(scriptDir,'PhaseChannelLocked_Raw_20260811.csv'));
equalFrequency=readtable(fullfile(scriptDir,'EqualFrequencyControl_Raw_20260812.csv'));
fullIQ=readtable(fullfile(scriptDir,'PhaseChannelFullIQ_Raw_20260812.csv'));

blue=[.12 .40 .72];red=[.83 .24 .18];orange=[.93 .60 .08];purple=[.45 .28 .68];gray=[.62 .64 .67];
fig=figure('Color','w','Visible','off','Units','inches','Position',[1 1 7.5 6.55]);
tiledlayout(2,2,'Padding','compact','TileSpacing','loose');
ax1=nexttile;hold(ax1,'on');box(ax1,'on');grid(ax1,'on');gains=unique(stage.inputGainScale).';colors=[blue;red;orange];
for q=1:numel(gains),rows=abs(stage.inputGainScale-gains(q))<1e-14;T=sortrows(stage(rows,:),'J');errorbar(ax1,T.J,T.meanValidationNRMSE,T.sdValidationNRMSE/sqrt(10),'-o','Color',colors(q,:),'LineWidth',1.4,'MarkerSize',5,'DisplayName',sprintf('$g=%.2f$',gains(q)));end
xlabel(ax1,'$J$','Interpreter','latex');ylabel(ax1,'validation NRMSE');title(ax1,'(a) Global deterministic selection','FontWeight','normal');legend(ax1,'Interpreter','latex','Location','southoutside','Orientation','horizontal','NumColumns',3,'Box','off','FontSize',10.5);
ax2=nexttile;hold(ax2,'on');box(ax2,'on');grid(ax2,'on');
for s=1:height(equalFrequency)
    plot(ax2,[1 2],[equalFrequency.span_J1(s) equalFrequency.degenerate_J1(s)],'-','Color',[.72 .80 .90],'LineWidth',.7,'HandleVisibility','off');
    plot(ax2,[1 2],[equalFrequency.span_J2(s) equalFrequency.degenerate_J2(s)],'-','Color',[.94 .77 .73],'LineWidth',.7,'HandleVisibility','off');
end
plot(ax2,1:2,[mean(equalFrequency.span_J1) mean(equalFrequency.degenerate_J1)],'-o','Color',blue,'LineWidth',1.7,'MarkerFaceColor','w','DisplayName','$J=0$');
plot(ax2,1:2,[mean(equalFrequency.span_J2) mean(equalFrequency.degenerate_J2)],'-s','Color',red,'LineWidth',1.7,'MarkerFaceColor','w','DisplayName','$J=0.65$');
xticks(ax2,1:2);xticklabels(ax2,{'nondegenerate','equal frequencies'});xtickangle(ax2,12);ylabel(ax2,'validation NRMSE');title(ax2,'(b) Deterministic spectral diversity','FontWeight','normal');legend(ax2,'Interpreter','latex','Location','southoutside','Orientation','horizontal','NumColumns',2,'Box','off','FontSize',10.5);
ax3=nexttile;hold(ax3,'on');box(ax3,'on');grid(ax3,'on');n=height(narma);for k=1:n,plot(ax3,[0 1],[narma.controlNRMSE(k) narma.coupledNRMSE(k)],'-','Color',[.80 .80 .80],'LineWidth',.7);end;scatter(ax3,zeros(n,1),narma.controlNRMSE,18,blue,'filled');scatter(ax3,ones(n,1),narma.coupledNRMSE,18,red,'filled');plot(ax3,[-.12 .12],mean(narma.controlNRMSE)*[1 1],'k-','LineWidth',1.8);plot(ax3,[.88 1.12],mean(narma.coupledNRMSE)*[1 1],'k-','LineWidth',1.8);xlim(ax3,[-.35 1.35]);xticks(ax3,[0 1]);xticklabels(ax3,{'$J=0$','$J=0.65$'});set(ax3,'TickLabelInterpreter','latex');ylabel(ax3,'test NRMSE');title(ax3,'(c) Fresh NARMA10 bank','FontWeight','normal');
ax4=nexttile;hold(ax4,'on');box(ax4,'on');grid(ax4,'on');values=[fullIQ.fullIQLinearNRMSE fullIQ.fullIQNVAR2NRMSE phase.nvar2NRMSE phase.J0NRMSE phase.coupledNRMSE];methodColors=[gray;.15 .58 .58;purple;blue;red];for m=1:5,scatter(ax4,m+.08*linspace(-1,1,height(phase)),values(:,m),14,methodColors(m,:),'filled','MarkerFaceAlpha',.38);plot(ax4,[m-.20 m+.20],mean(values(:,m))*[1 1],'-','Color',methodColors(m,:),'LineWidth',1.8);end;xticks(ax4,1:5);xticklabels(ax4,{'I/Q linear','I/Q NVAR2','phase NVAR2','$J=0$','$J=0.65$'});set(ax4,'TickLabelInterpreter','latex');xtickangle(ax4,20);ylabel(ax4,'test NRMSE');title(ax4,'(d) Phase-stream benchmark','FontWeight','normal');ylim(ax4,[.075 .29]);
set([ax1 ax2 ax3 ax4],'FontName','Arial','FontSize',11.5,'LineWidth',.9);
exportgraphics(fig,fullfile(scriptDir,'Figure6_MinimalArchitectureTasks_20260811.pdf'),'ContentType','vector');exportgraphics(fig,fullfile(scriptDir,'Figure6_MinimalArchitectureTasks_20260811.png'),'Resolution',300);close(fig);
fprintf('FIGURE_MINIMAL_PHASE_PASS\n');
