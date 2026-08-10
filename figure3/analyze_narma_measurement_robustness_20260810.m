%% analyze_narma_measurement_robustness_20260810.m
clear; close all; clc; scriptDir=fileparts(mfilename('fullpath'));
parts=cell(10,1); for s=1:10, file=fullfile(scriptDir,sprintf('NARMAMeasurementRobustness_Index%02d_20260810.csv',s)); assert(isfile(file)); parts{s}=readtable(file,'TextType','string'); end
raw=vertcat(parts{:}); writetable(raw,fullfile(scriptDir,'NARMAMeasurementRobustness_Raw_20260810.csv'));
groups=findgroups(raw.conditionIndex,raw.condition,raw.perturbation,raw.level,raw.protocol);
conditionIndex=splitapply(@(x)x(1),raw.conditionIndex,groups);
condition=splitapply(@(x)x(1),raw.condition,groups); perturbation=splitapply(@(x)x(1),raw.perturbation,groups);
level=splitapply(@(x)x(1),raw.level,groups); protocol=splitapply(@(x)x(1),raw.protocol,groups);
n=splitapply(@numel,raw.validationNRMSE,groups); meanNRMSE=splitapply(@mean,raw.validationNRMSE,groups);
sdNRMSE=splitapply(@std,raw.validationNRMSE,groups); medianNRMSE=splitapply(@median,raw.validationNRMSE,groups);
q25NRMSE=splitapply(@(x)quantile(x,.25),raw.validationNRMSE,groups); q75NRMSE=splitapply(@(x)quantile(x,.75),raw.validationNRMSE,groups);
summary=table(conditionIndex,condition,perturbation,level,protocol,n,meanNRMSE,sdNRMSE,medianNRMSE,q25NRMSE,q75NRMSE);
writetable(summary,fullfile(scriptDir,'NARMAMeasurementRobustness_Summary_20260810.csv'));

show=["detector_snr_db" "quantization_bits" "retained_channel_fraction" "failed_modes"];
panelTitles=["Additive detector noise" "Digitizer resolution" "Available channels" "Failed resonator modes"];
xLabels=["Detector SNR (dB)" "Quantization (bits)" "Retained channel fraction" "Number of failed modes"];
shownConditions=[1 4];
fig=figure('Color','w','Visible','off','Units','inches','Position',[1 1 7.2 5.8]);
tiledlayout(2,2,'Padding','compact','TileSpacing','compact'); colors=[.15 .38 .65;.78 .25 .18];
for p=1:numel(show)
    ax=nexttile;hold(ax,'on');
    for c=1:2
        for protocolIndex=1:2
            protocols=["zero_shot" "pca_readout_recalibrated"];
            R=summary(summary.perturbation==show(p)&summary.conditionIndex==shownConditions(c)&summary.protocol==protocols(protocolIndex),:);
            [~,order]=sort(R.level);R=R(order,:);
            lower=R.medianNRMSE-R.q25NRMSE; upper=R.q75NRMSE-R.medianNRMSE;
            styles={'-','--'}; markers={'o','s'};
            errorbar(ax,R.level,R.medianNRMSE,lower,upper,styles{protocolIndex}, ...
                'Marker',markers{protocolIndex},'Color',colors(c,:), ...
                'MarkerFaceColor','w','LineWidth',1.2,'CapSize',4);
        end
    end
    set(ax,'YScale','log');
    xlabel(ax,xLabels(p));ylabel(ax,'Validation NRMSE');
    title(ax,sprintf('(%c) %s','c'+p-1,panelTitles(p)),'FontWeight','normal');
    grid(ax,'on');box(ax,'on');
    if p==1
        legend(ax,{'J=0, zero-shot','J=0, recalibrated', ...
            'J=0.65, zero-shot','J=0.65, recalibrated'}, ...
            'Location','southwest','Box','off','FontSize',7.5);
    end
end
set(findall(fig,'Type','axes'),'FontName','Arial','FontSize',10,'LineWidth',.8);
exportgraphics(fig,fullfile(scriptDir,'NARMAMeasurementRobustness_20260810.pdf'),'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'NARMAMeasurementRobustness_20260810.png'),'Resolution',300);close(fig);
fprintf('MEASUREMENT_ROBUSTNESS_ANALYSIS_PASS rows=%d groups=%d\n',height(raw),height(summary));
