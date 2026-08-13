%% Regenerate the measurement-robustness figure from its archived summary.
clear; close all; clc;
scriptDir=fileparts(mfilename('fullpath'));
summary=readtable(fullfile(scriptDir, ...
    'NARMAMeasurementRobustness_Summary_20260810.csv'),'TextType','string');
assert(height(summary)==98 && all(isfinite(summary.medianNRMSE)));
show=["detector_snr_db" "quantization_bits" ...
    "retained_channel_fraction" "failed_modes"];
panelTitles=["Additive detector noise" "Digitizer resolution" ...
    "Available channels" "Failed resonator modes"];
xLabels=["Detector SNR (dB)" "Quantization (bits)" ...
    "Retained channel fraction" "Number of failed modes"];
shownConditions=[1 4];
fig=figure('Color','w','Visible','off','Units','inches','Position',[1 1 7.2 6.15]);
layout=tiledlayout(2,2,'Padding','compact','TileSpacing','loose');
colors=[.15 .38 .65;.78 .25 .18];
legendHandles=gobjects(4,1); legendAxis=gobjects(1);
for p=1:numel(show)
    ax=nexttile; hold(ax,'on');
    for c=1:2
        for protocolIndex=1:2
            protocols=["zero_shot" "pca_readout_recalibrated"];
            R=summary(summary.perturbation==show(p) & ...
                summary.conditionIndex==shownConditions(c) & ...
                summary.protocol==protocols(protocolIndex),:);
            [~,order]=sort(R.level); R=R(order,:);
            lower=R.medianNRMSE-R.q25NRMSE;
            upper=R.q75NRMSE-R.medianNRMSE;
            styles={'-','--'}; markers={'o','s'};
            h=errorbar(ax,R.level,R.medianNRMSE,lower,upper, ...
                styles{protocolIndex},'Marker',markers{protocolIndex}, ...
                'Color',colors(c,:),'MarkerFaceColor','w', ...
                'LineWidth',1.2,'CapSize',4);
            if p==1
                legendHandles((c-1)*2+protocolIndex)=h;
                legendAxis=ax;
            else
                h.HandleVisibility='off';
            end
        end
    end
    set(ax,'YScale','log'); xlabel(ax,xLabels(p));
    ylabel(ax,'Validation NRMSE');
    title(ax,sprintf('(%c) %s','a'+p-1,panelTitles(p)),'FontWeight','normal');
    grid(ax,'on'); box(ax,'on');
end
lgd=legend(legendAxis,legendHandles, ...
    {'J=0, fixed','J=0, recalibrated','J=0.65, fixed','J=0.65, recalibrated'}, ...
    'Orientation','horizontal','NumColumns',4,'Box','off','FontSize',10.5);
lgd.Layout.Tile='north';
set(findall(fig,'Type','axes'),'FontName','Arial','FontSize',11.5,'LineWidth',.9);
exportgraphics(fig,fullfile(scriptDir,'NARMAMeasurementRobustness_20260810.pdf'), ...
    'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'NARMAMeasurementRobustness_20260810.png'), ...
    'Resolution',300);
close(fig);
fprintf('ROBUSTNESS_TABLE_PLOT_PASS groups=%d\n',height(summary));
