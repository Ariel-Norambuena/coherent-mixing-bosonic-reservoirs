%% analyze_photon_precision_mapping_20260811.m
% Translate the archived photon-scaled robustness sweep into an explicit,
% assumption-conditioned coherent-detection power scale. No trajectories are
% rerun and no locked-test data enter this diagnostic.

clear; close all; clc;
scriptDir = fileparts(mfilename('fullpath'));
R = readtable(fullfile(scriptDir,'NARMAMeasurementRobustness_Summary_20260810.csv'), ...
    'TextType','string');

% Illustrative receiver assumptions. The 1/2 factor is the heterodyne 3 dB
% penalty relative to a single-quadrature homodyne receiver.
loadedLinewidthHz = 8e6;
kappaNormalized = .120;
frequencyUnitRad = 2*pi*loadedLinewidthHz/kappaNormalized;
kappaExternal = .5*2*pi*loadedLinewidthHz;
etaDetection = .50;
heterodynePenalty = .50;
dtPhysical = .0125/frequencyUnitRad;
virtualIndices = [11 20 29 37 46 55];
integrationTime = min(diff(virtualIndices))*dtPhysical;
referencePowerPerRing = .224e-9;

conditionIndices = [1 4];
conditionLabels = ["J=0" "J=0.65"];
slugs = ["J0_Heterogeneous_Both" "J065_Heterogeneous_Both"];
meanPhotonNumber = nan(2,1);
sdPhotonNumber = nan(2,1);

for q = 1:2
    perSeed = nan(10,1);
    for seedIndex = 1:10
        file = fullfile(scriptDir,sprintf(['Fig3_KerrReservoir_NARMA10_Reproducible_' ...
            'MechanismSelection_C%02d_%s_Index%02d_Offset%04d_20260810_summary.mat'], ...
            conditionIndices(q),slugs(q),seedIndex,100+seedIndex));
        assert(isfile(file),'Missing archived selection state: %s',file);
        S = load(file,'Xvirt','cfg','P');
        assert(S.P.N==12 && S.cfg.numReservoirs==3);
        blockWidth = 2*S.P.N;
        nBlocks = size(S.Xvirt,2)/blockWidth;
        assert(abs(nBlocks-round(nBlocks))<1e-12);
        train = S.cfg.idxTrain(:);
        nSum = 0; nCount = 0;
        for block = 1:nBlocks
            cols = (block-1)*blockWidth+(1:blockWidth);
            xb = S.Xvirt(train,cols);
            photons = xb(:,1:S.P.N).^2+xb(:,S.P.N+(1:S.P.N)).^2;
            nSum = nSum+sum(photons,'all');
            nCount = nCount+numel(photons);
        end
        perSeed(seedIndex) = nSum/nCount;
    end
    meanPhotonNumber(q) = mean(perSeed);
    sdPhotonNumber(q) = std(perSeed,0);
end

rows = R(R.perturbation=="shot_noise_photons" & ...
    R.protocol=="pca_readout_recalibrated",:);
rows = sortrows(rows,{'conditionIndex','level'});
output = table();
for q = 1:2
    rq = rows(rows.conditionIndex==conditionIndices(q),:);
    effectiveBase = heterodynePenalty*etaDetection*kappaExternal* ...
        meanPhotonNumber(q)*integrationTime;
    scaleFactor = rq.level/effectiveBase;
    tq = table(repmat(conditionIndices(q),height(rq),1), ...
        repmat(conditionLabels(q),height(rq),1),rq.level, ...
        rq.meanNRMSE,rq.sdNRMSE,repmat(meanPhotonNumber(q),height(rq),1), ...
        repmat(sdPhotonNumber(q),height(rq),1), ...
        repmat(effectiveBase,height(rq),1),scaleFactor, ...
        referencePowerPerRing*scaleFactor, ...
        'VariableNames',{'conditionIndex','condition', ...
        'effectiveDetectedPhotons','meanValidationNRMSE','sdValidationNRMSE', ...
        'meanIntracavityPhotons','sdIntracavityPhotons', ...
        'referenceEffectivePhotonsPerSample','requiredOpticalScale', ...
        'estimatedInputPowerPerRing_W'});
    output = [output; tq]; %#ok<AGROW>
end
writetable(output,fullfile(scriptDir,'PhotonPrecisionMapping_20260811.csv'));

blue = [.13 .42 .70]; dark = [.20 .20 .20];
fig = figure('Color','w','Visible','off','Units','inches','Position',[1 1 6.9 3.4]);
ax = axes(fig); hold(ax,'on'); box(ax,'on'); grid(ax,'on');
colors = [dark; blue]; markers = ['o' 's'];
for q = 1:2
    tq = output(output.conditionIndex==conditionIndices(q),:);
    sem = tq.sdValidationNRMSE/sqrt(30);
    errorbar(ax,tq.effectiveDetectedPhotons,tq.meanValidationNRMSE,sem, ...
        [markers(q) '-'],'Color',colors(q,:),'MarkerFaceColor','w', ...
        'LineWidth',1.35,'CapSize',4,'DisplayName',conditionLabels(q));
end
set(ax,'XScale','log','FontName','Arial','FontSize',10,'LineWidth',.8);
xlabel(ax,'effective detected signal photons per standardized feature');
ylabel(ax,'validation NRMSE after recalibration');
title(ax,'Coherent-receiver photon scaling', ...
    'FontWeight','normal');
legend(ax,'Location','northeast','Box','off');
exportgraphics(fig,fullfile(scriptDir,'FigS_PhotonPrecision_20260811.pdf'), ...
    'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'FigS_PhotonPrecision_20260811.png'), ...
    'Resolution',300);
close(fig);

fid = fopen(fullfile(scriptDir,'PhotonPrecisionMappingAudit_20260811.md'),'w');
assert(fid>=0); cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'# Photon-precision mapping audit\n\n');
fprintf(fid,['This diagnostic reinterprets the archived validation-only ' ...
    'photon-scaled noise sweep. It does not rerun trajectories and is not a ' ...
    'receiver measurement.\n\n']);
fprintf(fid,'- Loaded linewidth: `%.3g MHz`; external coupling fraction: `0.5`.\n', ...
    loadedLinewidthHz/1e6);
fprintf(fid,'- Detection efficiency: `%.2f`; heterodyne penalty: `3 dB`.\n', ...
    etaDetection);
fprintf(fid,'- Integration aperture: `%.4g ps`.\n',1e12*integrationTime);
fprintf(fid,'- Mean intracavity photons, J=0: `%.4g +/- %.3g`.\n', ...
    meanPhotonNumber(1),sdPhotonNumber(1));
fprintf(fid,'- Mean intracavity photons, J=0.65: `%.4g +/- %.3g`.\n', ...
    meanPhotonNumber(2),sdPhotonNumber(2));
fprintf(fid,['- Power values scale the ideal reference drive of 0.224 nW/ring. ' ...
    'They exclude LO, insertion loss, RF/ADC, stabilization, and wall-plug ' ...
    'power and must not be quoted as total system energy.\n']);
fprintf('PHOTON_PRECISION_MAPPING_PASS\n');
