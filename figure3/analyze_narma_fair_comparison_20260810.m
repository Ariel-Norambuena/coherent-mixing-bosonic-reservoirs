%% analyze_narma_fair_comparison_20260810.m
% Locked-test NRMSE versus total trained readout coefficients.
clear; close all; clc; scriptDir=fileparts(mfilename('fullpath'));
physicalParts=cell(30,1);
for q=1:30
    file=fullfile(scriptDir,sprintf(['Fig3_KerrReservoir_NARMA10_Reproducible_' ...
        'LockedTest_Index%02d_Offset%04d_20260810_FeatureBudgetVariants_summary.csv'],q,1000+q));
    assert(isfile(file)); T=readtable(file,'TextType','string','Delimiter',',');
    T.lockedIndex=repmat(q,height(T),1); physicalParts{q}=T;
end
physical=vertcat(physicalParts{:});
assert(height(physical)==30*28 && all(isfinite(physical.testNRMSE)));
writetable(physical,fullfile(scriptDir,'NARMAFairComparison_PhysicalRaw_20260810.csv'));

baseline=readtable(fullfile(scriptDir,'NARMABaselineLocked_Raw_20260810.csv'),'TextType','string');
assert(height(baseline)==30*28 && all(isfinite(baseline.testNRMSE)));

groups=findgroups(physical.featureMode,physical.J,physical.variant,physical.readoutCoefficients);
featureMode=splitapply(@(x)x(1),physical.featureMode,groups); J=splitapply(@(x)x(1),physical.J,groups);
variant=splitapply(@(x)x(1),physical.variant,groups); coefficients=splitapply(@(x)x(1),physical.readoutCoefficients,groups);
meanNRMSE=splitapply(@mean,physical.testNRMSE,groups); sdNRMSE=splitapply(@std,physical.testNRMSE,groups);
medianNRMSE=splitapply(@median,physical.testNRMSE,groups); n=splitapply(@numel,physical.testNRMSE,groups);
ciHalfWidth=1.96*sdNRMSE./sqrt(n);
physicalSummary=table(featureMode,J,variant,coefficients,n,meanNRMSE,sdNRMSE,medianNRMSE,ciHalfWidth);
writetable(physicalSummary,fullfile(scriptDir,'NARMAFairComparison_PhysicalSummary_20260810.csv'));

baselineStats=readtable(fullfile(scriptDir,'NARMABaselineLocked_Statistics_20260810.csv'),'TextType','string');
fig=figure('Color','w','Visible','off','Units','inches','Position',[1 1 7.2 3.6]);
tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
colors=struct('j0',[.18 .39 .66],'j65',[.78 .25 .20],'esn',[.43 .27 .70], ...
    'nvar2',[.12 .55 .36],'nvar3',[.76 .42 .16],'input',[.35 .35 .35]);

ax1=nexttile; hold(ax1,'on');
plotPhysical(ax1,physicalSummary,"linear_features",0,colors.j0,'o-','bosonic q., J=0');
plotPhysical(ax1,physicalSummary,"linear_features",.65,colors.j65,'s-','bosonic q., J=0.65');
plotBaseline(ax1,baselineStats,"tapped_esn",colors.esn,'^-','tapped ESN');
plotBaseline(ax1,baselineStats,"nvar_degree_2",colors.nvar2,'d-','NVAR-2');
plotBaseline(ax1,baselineStats,"nvar_degree_3",colors.nvar3,'v--','NVAR-3');
plotBaseline(ax1,baselineStats,"input_delays",colors.input,'x--','input delays');
set(ax1,'XScale','log'); xlim(ax1,[45 2300]); ylim(ax1,[0.04 .88]);
xlabel(ax1,'trained coefficients including bias'); ylabel(ax1,'test NRMSE');
title(ax1,'(a) Equal-readout comparison','FontWeight','normal');
legend(ax1,'Location','southoutside','Orientation','horizontal', ...
    'NumColumns',2,'Box','off','FontSize',6.5);
grid(ax1,'on'); box(ax1,'on');

ax2=nexttile; hold(ax2,'on');
plotPhysical(ax2,physicalSummary,"number_features",0,colors.j0,'o-','intensity, J=0');
plotPhysical(ax2,physicalSummary,"number_features",.65,colors.j65,'s-','intensity, J=0.65');
plotPhysical(ax2,physicalSummary,"linear_features",0,colors.esn,'^-','quadratures, J=0');
plotPhysical(ax2,physicalSummary,"linear_features",.65,colors.nvar2,'d-','quadratures, J=0.65');
set(ax2,'XScale','log'); xlim(ax2,[45 2300]); ylim(ax2,[0.24 .44]);
xlabel(ax2,'trained coefficients including bias'); ylabel(ax2,'test NRMSE');
title(ax2,'(b) Observable dependence','FontWeight','normal');
legend(ax2,'Location','southoutside','Orientation','horizontal', ...
    'NumColumns',2,'Box','off','FontSize',6.5);
grid(ax2,'on'); box(ax2,'on');
set([ax1 ax2],'FontName','Arial','FontSize',9.5,'LineWidth',.8);
exportgraphics(fig,fullfile(scriptDir,'NARMAFairComparison_20260810.pdf'),'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'NARMAFairComparison_20260810.png'),'Resolution',300); close(fig);
fprintf('FAIR_COMPARISON_ANALYSIS_PASS physical=%d classical=%d\n',height(physical),height(baseline));

function plotPhysical(ax,T,mode,Jvalue,color,style,label)
    R=T(T.featureMode==mode & abs(T.J-Jvalue)<1e-12,:); [~,order]=sort(R.coefficients);R=R(order,:);
    errorbar(ax,R.coefficients,R.meanNRMSE,R.ciHalfWidth,style,'Color',color, ...
        'MarkerFaceColor','w','MarkerSize',5,'LineWidth',1.3,'CapSize',4,'DisplayName',label);
end

function plotBaseline(ax,T,method,color,style,label)
    R=T(T.method==method,:); [~,order]=sort(R.actualCoefficients);R=R(order,:);
    ci=(R.meanCI95High-R.meanCI95Low)/2;
    errorbar(ax,R.actualCoefficients,R.meanTestNRMSE,ci,style,'Color',color, ...
        'MarkerFaceColor','w','MarkerSize',5,'LineWidth',1.15,'CapSize',4,'DisplayName',label);
end
