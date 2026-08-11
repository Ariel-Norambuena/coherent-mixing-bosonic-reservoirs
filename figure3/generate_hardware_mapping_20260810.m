%% Generate an auditable hybrid SiN/TFLN implementation mapping.

clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
lockedFile = fullfile(scriptDir,'configs','narma_locked_config_20260810.json');
assert(isfile(lockedFile),'Freeze the locked NARMA10 architecture first.');
locked = jsondecode(fileread(lockedFile));

scale.loadedLinewidthHz = 8e6;
scale.kappaNormalized = 0.120;
scale.frequencyUnitHz = scale.loadedLinewidthHz/scale.kappaNormalized;
scale.frequencyUnitRad = 2*pi*scale.frequencyUnitHz;
scale.wavelengthM = 1550e-9;
scale.externalCouplingFraction = 0.5;
scale.nModes = 12;
scale.nCopies = 3;
scale.dtNormalized = 0.0125;
scale.F0Normalized = 0.50;

symbolNormalized = locked.steps_per_sample*scale.dtNormalized;
symbolTime = symbolNormalized/scale.frequencyUnitRad;
substepTime = scale.dtNormalized/scale.frequencyUnitRad;
virtualIndices = locked.virtual_node_indices(:).';
virtualTimes = virtualIndices*substepTime;
minimumVirtualSpacing = min(diff(virtualTimes));
averageVirtualRate = numel(virtualIndices)/symbolTime;
peakVirtualRate = 1/minimumVirtualSpacing;
nPC = locked.n_pc;
nDelayBlocks = numel(locked.tap_delays);
rawQuadraturesOriginal = scale.nModes*scale.nCopies*2*numel(virtualIndices);
rawQuadraturesMinimal = scale.nModes*2*numel(virtualIndices);
trainedReadoutWeights = locked.readout_coefficients_including_bias-1;
explicitPcaMacsOriginal = rawQuadraturesOriginal*nPC;
explicitPcaMacsMinimal = rawQuadraturesMinimal*nPC;
fusedLinearMacsOriginal = rawQuadraturesOriginal*nDelayBlocks;
fusedLinearMacsMinimal = rawQuadraturesMinimal*nDelayBlocks;

hbar = 1.054571817e-34;
c = 299792458;
opticalOmega = 2*pi*c/scale.wavelengthM;
kappaExternalRad = scale.externalCouplingFraction* ...
    2*pi*scale.loadedLinewidthHz;
driveRate = scale.F0Normalized*scale.frequencyUnitRad;
inputPowerPerRing = hbar*opticalOmega*driveRate^2/kappaExternalRad;
totalOnChipPower = inputPowerPerRing*scale.nModes*scale.nCopies;
resonantPhotonEstimate = (2*scale.F0Normalized/scale.kappaNormalized)^2;

measuredPhotonMaximum = NaN;
lockedSummaries = dir(fullfile(scriptDir, ...
    'Fig3_KerrReservoir_NARMA10_Reproducible_LockedTest*_summary.mat'));
if ~isempty(lockedSummaries)
    maxima = nan(numel(lockedSummaries),1);
    for q = 1:numel(lockedSummaries)
        S = load(fullfile(lockedSummaries(q).folder,lockedSummaries(q).name), ...
            'betaFinalAll');
        maxima(q) = max(abs(S.betaFinalAll(:)).^2);
    end
    measuredPhotonMaximum = max(maxima);
end

quantity = [
    "Frequency unit"
    "Loaded linewidth"
    "Selected coherent hopping"
    "Static-detuning half span"
    "Maximum detuning-modulation scale"
    "Static drive scale"
    "Maximum drive-modulation scale"
    "Input-symbol time"
    "Mask-waveform update"
    "Average virtual-sample rate per detector"
    "Peak virtual-sample rate per detector"
    "On-chip optical input power per ring"
    "Total on-chip input power for three copies"
    "Uncoupled resonant photon estimate"
    "Observed maximum sampled photon number"
    "Intensity detector/ADC channels"
    "Coherent I/Q receiver outputs"
    "Optical 90-degree hybrids"
    "Balanced photodiodes for I/Q"
    "High-speed local detuning controls"
    "Shared amplitude modulators"
    "Trained readout weights excluding bias"
    "Explicit PCA MACs per symbol"
    "Fused linear MACs per symbol"
    ];
symbol = [
    "Omega_0/(2 pi)"
    "kappa/(2 pi)"
    "J_star/(2 pi)"
    "max |Delta_0|/(2 pi)"
    "max |g_Delta|/(2 pi)"
    "F_0/(2 pi)"
    "max |g_F|/(2 pi)"
    "T_s"
    "T_m"
    "f_v,avg"
    "f_v,peak"
    "P_in,ring"
    "P_in,total"
    "n_res"
    "max sampled |beta|^2"
    "N_PD"
    "N_IQ"
    "N_hybrid"
    "N_balancedPD"
    "N_Delta"
    "N_AM"
    "N_w"
    "N_PCA"
    "N_fused"
    ];
normalizedValue = [
    1
    scale.kappaNormalized
    locked.J_intervention
    1.05
    0.72*locked.input_gain_scale
    scale.F0Normalized
    0.10*locked.input_gain_scale
    symbolNormalized
    scale.dtNormalized
    NaN
    NaN
    NaN
    NaN
    scale.F0Normalized
    NaN
    resonantPhotonEstimate
    measuredPhotonMaximum
    NaN
    NaN
    NaN
    NaN
    trainedReadoutWeights
    explicitPcaMacsOriginal
    fusedLinearMacsOriginal
    ];
physicalValue = [
    scale.frequencyUnitHz
    scale.loadedLinewidthHz
    locked.J_intervention*scale.frequencyUnitHz
    1.05*scale.frequencyUnitHz
    0.72*locked.input_gain_scale*scale.frequencyUnitHz
    scale.F0Normalized*scale.frequencyUnitHz
    0.10*locked.input_gain_scale*scale.frequencyUnitHz
    symbolTime
    substepTime
    averageVirtualRate
    peakVirtualRate
    inputPowerPerRing
    totalOnChipPower
    resonantPhotonEstimate
    measuredPhotonMaximum
    scale.nModes*scale.nCopies
    2*scale.nModes*scale.nCopies
    scale.nModes*scale.nCopies
    4*scale.nModes*scale.nCopies
    scale.nModes*scale.nCopies
    scale.nCopies
    trainedReadoutWeights
    explicitPcaMacsOriginal
    fusedLinearMacsOriginal
    ];
unit = [
    "Hz";"Hz";"Hz";"Hz";"Hz";"Hz";"Hz";"s";"s";"samples/s";"samples/s"; ...
    "W";"W";"photons";"photons";"channels";"real channels"; ...
    "optical hybrids";"photodiodes"; ...
    "RF-weighted electrodes";"modulators";"coefficients"; ...
    "multiply-accumulates";"multiply-accumulates"
    ];
implementation = [
    "Scale fixed by the illustrative loaded linewidth"
    "Measured-device target, not simulated fabrication tolerance"
    "Weighted evanescent couplers"
    "Static heaters or DC electro-optic bias"
    "Hybrid electro-optic resonance tuning"
    "Shared coherent optical injection"
    "Input Mach-Zehnder modulation"
    "Input hold interval"
    "Piecewise-constant RF waveform update"
    "Six gated samples per symbol"
    "Set by the closest selected virtual-node indices"
    "Critical-coupling estimate at 1550 nm"
    "Excludes laser wall-plug and insertion losses"
    "Single uncoupled ring exactly on resonance"
    "Computed from locked summaries when available"
    "One drop-port intensity channel per mode and copy"
    "Two quadrature values per mode and copy"
    "One optical 90-degree hybrid per mode and copy"
    "Four photodiodes per I/Q hybrid; 72 differential electrical outputs"
    "Worst-case independent-gain implementation; RF fan-out may reduce sources"
    "One shared drive modulator per copy"
    "Primary locked linear readout, excluding bias"
    "Dense projection of 432 raw quadratures onto 26 PCs"
    "PCA and linear readout algebraically fused over 13 delay blocks"
    ];

tolerance = [
    "Chosen scale";"Not swept";"4% rms copy disorder, recalibrated"; ...
    "0.05 normalized rms copy disorder, recalibrated"; ...
    "10% rms copy disorder, recalibrated";"Not swept"; ...
    "10% rms copy disorder, recalibrated";"Clock locked";"Clock locked"; ...
    "ADC timing requirement";"ADC timing requirement"; ...
    "Illustrative only";"Illustrative only";"Illustrative only"; ...
    "Measured across locked runs";"Architecture count";"Architecture count"; ...
    "Architecture count";"Architecture count";"Architecture count"; ...
    "Architecture count";"Exact coefficient count"; ...
    "Explicit dense-transform count";"Fused dense-transform count"];
T = table(quantity,symbol,normalizedValue,physicalValue,unit,tolerance,implementation);
writetable(T,fullfile(scriptDir,'HardwareMapping_HybridSiNTFLN_20260810.csv'));

architecture = ["original";"minimal"];
copies = [scale.nCopies;1];
totalResonators = scale.nModes*copies;
resources = table(architecture,repmat(scale.nModes,2,1),copies,totalResonators, ...
    totalResonators,2*totalResonators,totalResonators,4*totalResonators, ...
    [totalResonators(1);0],[scale.nCopies;1],repmat(numel(virtualIndices),2,1), ...
    repmat(averageVirtualRate,2,1),repmat(peakVirtualRate,2,1), ...
    repmat(trainedReadoutWeights,2,1), ...
    [explicitPcaMacsOriginal;explicitPcaMacsMinimal], ...
    [fusedLinearMacsOriginal;fusedLinearMacsMinimal], ...
    'VariableNames',{'architecture','modesPerCopy','copies','totalResonators', ...
    'intensityChannels','quadratureValues','opticalIQHybrids','balancedPhotodiodes', ...
    'localDetuningControls', ...
    'sharedAmplitudeModulators','virtualSamplesPerSymbol', ...
    'averageSampleRatePerChannel','peakSampleRatePerChannel', ...
    'trainedReadoutWeightsExcludingBias','explicitPcaMacsPerSymbol', ...
    'fusedLinearMacsPerSymbol'});
writetable(resources,fullfile(scriptDir,'HardwareResourceBudget_20260810.csv'));

reportFile = fullfile(scriptDir,'HardwareMappingAudit_20260810.md');
fid = fopen(reportFile,'w');assert(fid >= 0);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'# Hybrid SiN/TFLN hardware mapping audit\n\n');
fprintf(fid,['This is an engineering translation of normalized parameters, ' ...
    'not a fabricated-device claim. It assumes a loaded linewidth of 8 MHz ' ...
    'and critical external coupling at 1550 nm.\n\n']);
fprintf(fid,'- Symbol time: `%.4g ns`; waveform update: `%.4g ps`.\n', ...
    1e9*symbolTime,1e12*substepTime);
fprintf(fid,'- Average/peak sample rates per detector: `%.4g/%.4g GS/s`.\n', ...
    averageVirtualRate/1e9,peakVirtualRate/1e9);
fprintf(fid,'- Coupling: `%.4g MHz`; detuning-modulation scale: `%.4g MHz`.\n', ...
    locked.J_intervention*scale.frequencyUnitHz/1e6, ...
    0.72*locked.input_gain_scale*scale.frequencyUnitHz/1e6);
fprintf(fid,'- Ideal on-chip drive estimate: `%.4g nW/ring`, `%.4g nW` total.\n', ...
    1e9*inputPowerPerRing,1e9*totalOnChipPower);
fprintf(fid,['- The power estimate excludes coupling loss, modulator insertion ' ...
    'loss, local-oscillator power, I/Q hybrids, RF drivers, ADCs, thermal stabilization, and laser wall-plug ' ...
    'efficiency; it must not be quoted as total system energy.\n']);
fprintf(fid,['- A monolithic passive SiN network alone does not implement the ' ...
    'required fast local detuning terms. The mapping therefore requires ' ...
    'hybrid electro-optic control or an equivalent measured transfer matrix.\n']);
fprintf(fid,['- The 55 mask values are waveform updates inside each symbol; only ' ...
    'six of those integration times are digitized as virtual samples. The ' ...
    'modulator therefore requires about 33.5 GHz update bandwidth while each ' ...
    'electrical I/Q output requires at most 4.19 GS/s.\n']);
fprintf(fid,['- The locked coupling gain is observed with simultaneous quadrature ' ...
    'features. A direct implementation therefore needs 36 optical I/Q hybrids, ' ...
    '144 photodiodes, and 72 differential ADC channels. Intensity-only readout ' ...
    'uses 36 detectors but does not inherit the locked coupling gain.\n']);
fprintf(fid,['- The trained readout has %d weights excluding bias. Explicit PCA ' ...
    'costs %d/%d MACs per symbol for the original/minimal architectures; ' ...
    'algebraic fusion with the linear readout reduces these counts to %d/%d. ' ...
    'These counts exclude standardization, buffering, acquisition, and energy.\n'], ...
    trainedReadoutWeights,explicitPcaMacsOriginal,explicitPcaMacsMinimal, ...
    fusedLinearMacsOriginal,fusedLinearMacsMinimal);
fprintf('HARDWARE_MAPPING_PASS symbol_ns=%.4g mask_GHz=%.4g\n', ...
    1e9*symbolTime,1e-9/substepTime);
