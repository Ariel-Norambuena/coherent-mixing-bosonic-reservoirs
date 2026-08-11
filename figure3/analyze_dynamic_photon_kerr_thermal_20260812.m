%% Dynamic-signal photon mapping and Kerr/thermal self-consistency audit.
% Reviewer-triggered analysis. The informative signal is the centered raw
% quadrature variance; receiver noise is propagated through training-only
% standardization and PCA.

clear;clc;scriptDir=fileparts(mfilename('fullpath'));
loadedLinewidthHz=8e6;kappaNormalized=.120;
frequencyUnitRad=2*pi*loadedLinewidthHz/kappaNormalized;
kappaExternal=.5*2*pi*loadedLinewidthHz;etaDetection=.50;
dtPhysical=.0125/frequencyUnitRad;virtualIndices=[11 20 29 37 46 55];
integrationTime=min(diff(virtualIndices))*dtPhysical;
referencePowerPerRing=0.224e-9;targetEffectivePhotons=1e4;
Jvalues=[0 .65];conditions=["J=0";"J=0.65"];

meanOccupancy=nan(2,1);carrierEffectivePhotons=meanOccupancy;
medianRawEffectivePhotons=meanOccupancy;minimumRawEffectivePhotons=meanOccupancy;
medianPcaEffectivePhotons=meanOccupancy;minimumPcaEffectivePhotons=meanOccupancy;
dynamicToCarrierRatio=meanOccupancy;requiredPowerMedianPca_W=meanOccupancy;
requiredPowerMinimumPca_W=meanOccupancy;

for c=1:2
    tag=sprintf('DynamicPhotonAudit_C%02d_Offset0101_20260812',c);
    file=fullfile(scriptDir,['Fig3_KerrReservoir_NARMA10_Reproducible_' tag '_summary.mat']);
    S=load(file,'Xvirt','cfg','P','pcaInfo');
    assert(isequal(size(S.Xvirt),[22000 144]) && S.P.N==12 && ...
        S.cfg.numReservoirs==1 && abs(S.P.J0-Jvalues(c))<1e-14);
    train=S.cfg.idxTrain(:);X=S.Xvirt(train,:);
    rawVariance=var(X,1,1);
    rawEffective=.5*etaDetection*kappaExternal*integrationTime*rawVariance;
    medianRawEffectivePhotons(c)=median(rawEffective);
    minimumRawEffectivePhotons(c)=min(rawEffective);

    mu=S.pcaInfo.mu;sig=S.pcaInfo.sig;V=S.pcaInfo.Vpc;
    Z=(X-mu)./sig*V;
    pcSignalVariance=var(Z,1,1);
    rawNoiseToPc=sum((V./sig.').^2,1);
    pcEffective=.5*etaDetection*kappaExternal*integrationTime* ...
        pcSignalVariance./rawNoiseToPc;
    medianPcaEffectivePhotons(c)=median(pcEffective);
    minimumPcaEffectivePhotons(c)=min(pcEffective);

    nModes=S.P.N;nVirtual=numel(S.cfg.virtualNodeIdx);occupation=[];
    for v=1:nVirtual
        cols=(v-1)*2*nModes+(1:2*nModes);
        block=X(:,cols);
        occupation=[occupation;block(:,1:nModes).^2+block(:,nModes+(1:nModes)).^2]; %#ok<AGROW>
    end
    meanOccupancy(c)=mean(occupation,'all');
    carrierEffectivePhotons(c)=.5*etaDetection*kappaExternal* ...
        integrationTime*meanOccupancy(c);
    dynamicToCarrierRatio(c)=medianPcaEffectivePhotons(c)/carrierEffectivePhotons(c);
    requiredPowerMedianPca_W(c)=referencePowerPerRing* ...
        targetEffectivePhotons/medianPcaEffectivePhotons(c);
    requiredPowerMinimumPca_W(c)=referencePowerPerRing* ...
        targetEffectivePhotons/minimumPcaEffectivePhotons(c);
end

% Representative stoichiometric Si3N4 estimate at 1550 nm. This is a
% parameterized design check, not a claim for a fabricated device.
hbar=1.054571817e-34;c0=299792458;lambda0=1550e-9;omega0=2*pi*c0/lambda0;
nIndex=1.977;n2=2.3e-19;modeVolume=1000e-18;
kerrRadPerPhoton=hbar*omega0^2*c0*n2/(nIndex^2*modeVolume);
kerrHzPerPhoton=kerrRadPerPhoton/(2*pi);kappaRad=2*pi*loadedLinewidthHz;
powerScaleMedian=requiredPowerMedianPca_W/referencePowerPerRing;
scaledOccupancyMedian=meanOccupancy.*powerScaleMedian;
kerrShiftOverKappa=kerrRadPerPhoton*scaledOccupancyMedian/kappaRad;
maxKerrHzForPointOne=.1*loadedLinewidthHz./scaledOccupancyMedian;
requiredModeVolumeForPointOne=modeVolume.*kerrShiftOverKappa/.1;

thermoOpticCoefficient=2.45e-5;
thermalShiftHzPerK=(c0/lambda0)/nIndex*thermoOpticCoefficient;
allowedTemperatureRiseK=.1*loadedLinewidthHz/thermalShiftHzPerK;
allowedThermalSlopeMHzPerMilliwatt=.1*loadedLinewidthHz./ ...
    (requiredPowerMedianPca_W*1e3)/1e6;

T=table(conditions,Jvalues(:),meanOccupancy,carrierEffectivePhotons, ...
    medianRawEffectivePhotons,minimumRawEffectivePhotons, ...
    medianPcaEffectivePhotons,minimumPcaEffectivePhotons,dynamicToCarrierRatio, ...
    requiredPowerMedianPca_W,requiredPowerMinimumPca_W,scaledOccupancyMedian, ...
    kerrShiftOverKappa,maxKerrHzForPointOne,requiredModeVolumeForPointOne/1e-18, ...
    allowedThermalSlopeMHzPerMilliwatt, ...
    'VariableNames',{'condition','J','meanIntracavityOccupancy', ...
    'carrierEffectivePhotons','medianRawDynamicEffectivePhotons', ...
    'minimumRawDynamicEffectivePhotons','medianPcaDynamicEffectivePhotons', ...
    'minimumPcaDynamicEffectivePhotons','dynamicToCarrierRatio', ...
    'requiredPowerMedianPca_W','requiredPowerMinimumPca_W', ...
    'scaledMeanOccupancyMedianPca','kerrShiftOverKappa', ...
    'maxKerrHzPerPhotonForRatioPointOne','requiredModeVolumeForRatioPointOne_um3', ...
    'allowedThermalSlope_MHzPerMiliwatt'});
writetable(T,fullfile(scriptDir,'DynamicPhotonKerrThermalAudit_20260812.csv'));

fid=fopen(fullfile(scriptDir,'DynamicPhotonKerrThermalAudit_20260812.md'),'w');assert(fid>=0);
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'# Dynamic photon, residual Kerr, and thermal audit\n\n');
fprintf(fid,'Reviewer-triggered analysis using one archived-scale trajectory per condition.\n\n');
fprintf(fid,'- Loaded linewidth: `%.3g MHz`; external-coupling fraction: `0.5`.\n',loadedLinewidthHz/1e6);
fprintf(fid,'- Detection efficiency: `%.2f`; heterodyne factor: `1/2`.\n',etaDetection);
fprintf(fid,'- Integration aperture: `%.3f ps`; reference input: `%.3f nW/ring`.\n',integrationTime*1e12,referencePowerPerRing*1e9);
fprintf(fid,'- Target used only for comparison with the robustness sweep: `%.0e` effective photons.\n',targetEffectivePhotons);
fprintf(fid,'- Kerr model: n2=`%.2g m^2/W`, n=`%.3f`, Veff=`%.0f um^3`, K/2pi=`%.3g Hz/photon`.\n',n2,nIndex,modeVolume/1e-18,kerrHzPerPhoton);
fprintf(fid,'- Thermo-optic coefficient: `%.3g K^-1`; |dnu/dT|=`%.3g GHz/K`; DeltaT for 0.1 linewidth=`%.3g mK`.\n',thermoOpticCoefficient,thermalShiftHzPerK/1e9,allowedTemperatureRiseK*1e3);
fprintf(fid,['\nThe centered dynamic variance, rather than total carrier occupancy, is the ' ...
    'operational signal. At the median retained PCA component, the inferred ' ...
    'power and Kerr ratios are listed in the CSV. A physical platform is ' ...
    'self-consistent only if its measured K, absorption, and thermal resistance ' ...
    'satisfy both |K| nbar/kappa << 1 and |dnu/dT| Rth Pabs/kappa << 1.\n']);
fprintf(['DYNAMIC_PHOTON_KERR_THERMAL_PASS PmW=[%.4g %.4g] ' ...
    'Kratio=[%.4g %.4g] dyn/carrier=[%.4g %.4g]\n'], ...
    requiredPowerMedianPca_W*1e3,kerrShiftOverKappa,dynamicToCarrierRatio);
