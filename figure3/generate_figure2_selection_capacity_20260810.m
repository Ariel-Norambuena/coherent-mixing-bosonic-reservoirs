%% generate_figure2_selection_capacity_20260810.m
clear;close all;clc;scriptDir=fileparts(mfilename('fullpath'));
S1=readtable(fullfile(scriptDir,'NARMASelectionStage1_Summary_20260807.csv'));
S2=readtable(fullfile(scriptDir,'NARMASelectionStage2_Summary_20260810.csv'));
C=readtable(fullfile(scriptDir,'NARMAProcessingCapacity_Summary_20260810.csv'),'TextType','string');
fig=figure('Color','w','Visible','off','Units','inches','Position',[1 1 7.2 5.1]);
tiledlayout(2,2,'Padding','compact','TileSpacing','compact');

ax1=nexttile;Kvals=unique(S1.Ksummary,'stable');Jvals=unique(S1.Jsummary,'stable');M=nan(numel(Kvals),numel(Jvals));
for i=1:numel(Kvals)
    for j=1:numel(Jvals)
        r=S1.Ksummary==Kvals(i)&S1.Jsummary==Jvals(j);M(i,j)=S1.meanValidationNRMSE(r);
    end
end
imagesc(ax1,M);set(ax1,'YDir','normal','XTick',1:numel(Jvals),'XTickLabel',string(Jvals), ...
    'YTick',1:numel(Kvals),'YTickLabel',string(Kvals));colormap(ax1,'parula');colorbar(ax1);
xlabel(ax1,'coherent hopping J');ylabel(ax1,'Kerr coefficient K');title(ax1,'(a) Validation-only physical selection','FontWeight','normal');
hold(ax1,'on');plot(ax1,find(abs(Jvals-.65)<1e-12),find(abs(Kvals)<1e-12),'p','MarkerSize',13,'MarkerFaceColor','w','MarkerEdgeColor','k');
for i=1:numel(Kvals),for j=1:numel(Jvals),text(ax1,j,i,sprintf('%.3f',M(i,j)),'HorizontalAlignment','center','Color','w','FontWeight','bold','FontSize',8);end,end

ax2=nexttile;R=S2(S2.K==0&S2.J==.65&S2.virtualSamples==6&S2.nDelayBlocks==13,:);
gains=unique(R.inputGainScale,'stable');steps=unique(R.stepsPerSample,'stable');M2=nan(numel(gains),numel(steps));
for i=1:numel(gains),for j=1:numel(steps),row=R.inputGainScale==gains(i)&R.stepsPerSample==steps(j);M2(i,j)=R.meanValidationNRMSE(row);end,end
imagesc(ax2,M2);set(ax2,'YDir','normal','XTick',1:numel(steps),'XTickLabel',string(steps), ...
    'YTick',1:numel(gains),'YTickLabel',string(gains));colormap(ax2,'parula');colorbar(ax2);
xlabel(ax2,'integration steps per symbol');ylabel(ax2,'input-gain scale');title(ax2,'(b) Stage-two refinement','FontWeight','normal');
hold(ax2,'on');plot(ax2,find(steps==55),find(abs(gains-1.25)<1e-12),'p','MarkerSize',13,'MarkerFaceColor','w','MarkerEdgeColor','k');
for i=1:numel(gains),for j=1:numel(steps),text(ax2,j,i,sprintf('%.3f',M2(i,j)),'HorizontalAlignment','center','Color','w','FontWeight','bold','FontSize',8);end,end

ax3=nexttile([1 2]);conditions=unique(C.conditionIndex,'stable');linear=zeros(numel(conditions),1);linearErr=linear;cross=linear;crossErr=linear;
for q=1:numel(conditions)
    r=C.conditionIndex==conditions(q)&C.capacityType=="linear";linear(q)=C.meanCapacity(r);linearErr(q)=C.sdCapacity(r);
    r=C.conditionIndex==conditions(q)&C.capacityType=="cross_product";cross(q)=C.meanCapacity(r);crossErr(q)=C.sdCapacity(r);
end
yyaxis(ax3,'left');b=bar(ax3,conditions,linear,.60,'FaceColor',[.16 .43 .70],'EdgeColor','none');hold(ax3,'on');errorbar(ax3,conditions,linear,linearErr,'k.','LineWidth',1,'CapSize',5);ylabel(ax3,'summed linear-memory capacity');
yyaxis(ax3,'right');crossLine=errorbar(ax3,conditions,cross,crossErr,'-o','Color',[.80 .31 .14],'MarkerFaceColor','w','LineWidth',1.3,'CapSize',5);ylabel(ax3,'summed cross-product capacity');
set(ax3,'XTick',conditions,'XTickLabel',{'J=0, hetero, both','J=.65, uniform G, detuning','J=.65, hetero G, detuning','J=.65, hetero, both'});xtickangle(ax3,12);
xlabel(ax3,'untapped physical-state condition');title(ax3,'(c) Coupling extends linear memory without increasing product capacity','FontWeight','normal');grid(ax3,'on');box(ax3,'on');
legend(ax3,[b crossLine],{'linear memory','cross products'},'Location','northwest','Box','off');
set([ax1 ax2 ax3],'FontName','Arial','FontSize',9.2,'LineWidth',.8);
exportgraphics(fig,fullfile(scriptDir,'Figure2_SelectionCapacity_20260810.pdf'),'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'Figure2_SelectionCapacity_20260810.png'),'Resolution',300);close(fig);
fprintf('FIGURE2_SELECTION_CAPACITY_PASS\n');

