%% Fig3_KerrReservoir_NARMA10_PublicationGrade_EnsembleMasked.m
% Publication-grade NARMA10 benchmark for a driven-dissipative Kerr reservoir.
%
% This version implements the improvements discussed for a stronger and more
% publishable simulation:
%   1) N = 12 Kerr oscillators with first-, second-, and third-neighbor coupling.
%   2) Input masking inside each input-hold interval, so virtual nodes see
%      different modulations of the same input sample.
%   3) Small ensemble of independently disordered Kerr reservoirs.
%   4) PCA/SVD compression BEFORE tapped-delay expansion, reducing redundancy.
%   5) Stable ridge readout with robust validation and finite-value checks.
%   6) Baselines: no temporal taps, input-only linear tapped delays, K = 0, J = 0.
%   7) Optional K/J sweeps and feature ablations with independently trained
%      PCA/readout pipelines for each physical case.
%   8) Safe saving with -v7.3 and no large matrices unless requested.
%
% Physical parameters are never trained. K/J changes occur only in explicit
% ablations or sweeps; only the final linear readout is optimized.
%
% Author: generated for the Kerr synchronization reservoir manuscript.

overrideQuick = exist('KERR_NARMA_QUICK','var') && KERR_NARMA_QUICK;
overrideSmoke = exist('KERR_NARMA_SMOKE','var') && KERR_NARMA_SMOKE;
overrideKSweep = exist('KERR_NARMA_RUN_KSWEEP','var') && KERR_NARMA_RUN_KSWEEP;
overrideJSweep = exist('KERR_NARMA_RUN_JSWEEP','var') && KERR_NARMA_RUN_JSWEEP;
overrideFeatureAblations = exist('KERR_NARMA_RUN_FEATURE_ABLATIONS','var') && KERR_NARMA_RUN_FEATURE_ABLATIONS;
overrideSkipPhysical = exist('KERR_NARMA_SKIP_PHYSICAL_ABLATIONS','var') && KERR_NARMA_SKIP_PHYSICAL_ABLATIONS;
overrideSkipBaselines = exist('KERR_NARMA_SKIP_BASELINES','var') && KERR_NARMA_SKIP_BASELINES;
overrideDisablePlots = exist('KERR_NARMA_DISABLE_PLOTS','var') && KERR_NARMA_DISABLE_PLOTS;
if exist('KERR_NARMA_OUTPUT_TAG','var')
    overrideOutputTag = KERR_NARMA_OUTPUT_TAG;
else
    overrideOutputTag = '';
end
if exist('KERR_NARMA_KLIST','var')
    overrideKList = KERR_NARMA_KLIST;
else
    overrideKList = [];
end
if exist('KERR_NARMA_JLIST','var')
    overrideJList = KERR_NARMA_JLIST;
else
    overrideJList = [];
end
if exist('KERR_NARMA_JSWEEP_KLIST','var')
    overrideJSweepKList = KERR_NARMA_JSWEEP_KLIST;
else
    overrideJSweepKList = [];
end
if exist('KERR_NARMA_SEED_OFFSET','var')
    overrideSeedOffset = KERR_NARMA_SEED_OFFSET;
else
    overrideSeedOffset = 0;
end
if exist('KERR_NARMA_BASE_K','var')
    overrideBaseK = KERR_NARMA_BASE_K;
else
    overrideBaseK = [];
end
if exist('KERR_NARMA_BASE_J','var')
    overrideBaseJ = KERR_NARMA_BASE_J;
else
    overrideBaseJ = [];
end
if exist('KERR_NARMA_FEATURE_CASES','var')
    overrideFeatureCases = KERR_NARMA_FEATURE_CASES;
else
    overrideFeatureCases = [];
end
if exist('KERR_NARMA_FEATURE_MODES','var')
    overrideFeatureModes = KERR_NARMA_FEATURE_MODES;
else
    overrideFeatureModes = {};
end
if exist('KERR_NARMA_BASE_FEATURE_MODE','var')
    overrideBaseFeatureMode = KERR_NARMA_BASE_FEATURE_MODE;
else
    overrideBaseFeatureMode = '';
end
customDatasetFlags = [exist('KERR_NARMA_CUSTOM_INPUT_RAW','var'), ...
    exist('KERR_NARMA_CUSTOM_INPUT_ENCODED','var'), ...
    exist('KERR_NARMA_CUSTOM_TARGET','var')];
if any(customDatasetFlags) && ~all(customDatasetFlags)
    error(['Custom datasets require KERR_NARMA_CUSTOM_INPUT_RAW, ' ...
        'KERR_NARMA_CUSTOM_INPUT_ENCODED, and KERR_NARMA_CUSTOM_TARGET.']);
end
if all(customDatasetFlags)
    overrideCustomInputRaw = KERR_NARMA_CUSTOM_INPUT_RAW;
    overrideCustomInputEncoded = KERR_NARMA_CUSTOM_INPUT_ENCODED;
    overrideCustomTarget = KERR_NARMA_CUSTOM_TARGET;
else
    overrideCustomInputRaw = [];
    overrideCustomInputEncoded = [];
    overrideCustomTarget = [];
end
if exist('KERR_NARMA_TASK_LABEL','var')
    overrideTaskLabel = char(KERR_NARMA_TASK_LABEL);
else
    overrideTaskLabel = 'NARMA10';
end
overrideValidateFeatureCache = exist('KERR_NARMA_VALIDATE_FEATURE_CACHE','var') && ...
    KERR_NARMA_VALIDATE_FEATURE_CACHE;
overrideSaveRawFeatures = exist('KERR_NARMA_SAVE_RAW_FEATURES','var') && ...
    KERR_NARMA_SAVE_RAW_FEATURES;
overrideSaveCompactFeatures = exist('KERR_NARMA_SAVE_COMPACT_FEATURES','var') && ...
    KERR_NARMA_SAVE_COMPACT_FEATURES;
if exist('KERR_NARMA_INPUT_MODE','var')
    overrideInputMode = char(KERR_NARMA_INPUT_MODE);
else
    overrideInputMode = '';
end
if exist('KERR_NARMA_GDELTA_MODE','var')
    overrideGDeltaMode = char(KERR_NARMA_GDELTA_MODE);
else
    overrideGDeltaMode = 'heterogeneous';
end
if exist('KERR_NARMA_GF_MODE','var')
    overrideGFMode = char(KERR_NARMA_GF_MODE);
else
    overrideGFMode = 'heterogeneous';
end
overrideDisableStaticDisorder = exist('KERR_NARMA_DISABLE_STATIC_DISORDER','var') && ...
    KERR_NARMA_DISABLE_STATIC_DISORDER;
if exist('KERR_NARMA_COPY_DISORDER_SCALE','var')
    overrideCopyDisorderScale = KERR_NARMA_COPY_DISORDER_SCALE;
else
    overrideCopyDisorderScale = 1;
end
if exist('KERR_NARMA_COPY_DETUNING_DISORDER','var')
    overrideCopyDetuningDisorder = KERR_NARMA_COPY_DETUNING_DISORDER;
else
    overrideCopyDetuningDisorder = [];
end
if exist('KERR_NARMA_NUM_RESERVOIRS','var')
    overrideNumReservoirs = KERR_NARMA_NUM_RESERVOIRS;
else
    overrideNumReservoirs = [];
end
if exist('KERR_NARMA_PROTOCOL_MODE','var')
    overrideProtocolMode = char(KERR_NARMA_PROTOCOL_MODE);
else
    overrideProtocolMode = 'development';
end
if exist('KERR_NARMA_NPC','var')
    overrideNPC = KERR_NARMA_NPC;
else
    overrideNPC = [];
end
if exist('KERR_NARMA_TAP_DELAYS','var')
    overrideTapDelays = KERR_NARMA_TAP_DELAYS;
else
    overrideTapDelays = [];
end
if exist('KERR_NARMA_STEPS_PER_SAMPLE','var')
    overrideStepsPerSample = KERR_NARMA_STEPS_PER_SAMPLE;
else
    overrideStepsPerSample = [];
end
if exist('KERR_NARMA_DT','var')
    overrideDt = KERR_NARMA_DT;
else
    overrideDt = [];
end
if exist('KERR_NARMA_INPUT_MASK','var')
    overrideInputMask = KERR_NARMA_INPUT_MASK;
else
    overrideInputMask = [];
end
if exist('KERR_NARMA_INPUT_BIAS','var')
    overrideInputBias = KERR_NARMA_INPUT_BIAS;
else
    overrideInputBias = [];
end
if exist('KERR_NARMA_NUM_VIRTUAL','var')
    overrideNumVirtual = KERR_NARMA_NUM_VIRTUAL;
else
    overrideNumVirtual = [];
end
if exist('KERR_NARMA_INPUT_GAIN_SCALE','var')
    overrideInputGainScale = KERR_NARMA_INPUT_GAIN_SCALE;
else
    overrideInputGainScale = [];
end
if exist('KERR_NARMA_VIRTUAL_NODE_IDX','var')
    overrideVirtualNodeIdx = KERR_NARMA_VIRTUAL_NODE_IDX;
else
    overrideVirtualNodeIdx = [];
end
if exist('KERR_NARMA_READOUT_VARIANTS','var')
    overrideReadoutVariants = KERR_NARMA_READOUT_VARIANTS;
else
    overrideReadoutVariants = struct([]);
end
if exist('KERR_NARMA_FEATURE_BUDGET_VARIANTS','var')
    overrideFeatureBudgetVariants = KERR_NARMA_FEATURE_BUDGET_VARIANTS;
else
    overrideFeatureBudgetVariants = struct([]);
end
if exist('KERR_NARMA_FEATURE_BUDGET_LAMBDA_MAP','var')
    overrideFeatureBudgetLambdaMap = KERR_NARMA_FEATURE_BUDGET_LAMBDA_MAP;
else
    overrideFeatureBudgetLambdaMap = [];
end
if exist('KERR_NARMA_LAMBDA_GRID','var')
    overrideLambdaGrid = KERR_NARMA_LAMBDA_GRID;
else
    overrideLambdaGrid = [];
end
overrideLockedPair = exist('KERR_NARMA_LOCKED_PAIR','var') && ...
    KERR_NARMA_LOCKED_PAIR;
clearvars -except overrideQuick overrideSmoke overrideKSweep overrideJSweep overrideFeatureAblations overrideSkipPhysical overrideSkipBaselines overrideDisablePlots overrideOutputTag overrideKList overrideJList overrideJSweepKList overrideSeedOffset overrideBaseK overrideBaseJ overrideFeatureCases overrideFeatureModes overrideBaseFeatureMode overrideCustomInputRaw overrideCustomInputEncoded overrideCustomTarget overrideTaskLabel overrideValidateFeatureCache overrideSaveRawFeatures overrideSaveCompactFeatures overrideInputMode overrideGDeltaMode overrideGFMode overrideDisableStaticDisorder overrideCopyDisorderScale overrideCopyDetuningDisorder overrideNumReservoirs overrideProtocolMode overrideNPC overrideTapDelays overrideStepsPerSample overrideDt overrideInputMask overrideInputBias overrideNumVirtual overrideInputGainScale overrideVirtualNodeIdx overrideReadoutVariants overrideFeatureBudgetVariants overrideFeatureBudgetLambdaMap overrideLambdaGrid overrideLockedPair;
close all; clc;

%% ========================== User configuration ============================
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

if ~isscalar(overrideSeedOffset) || ~isfinite(overrideSeedOffset) || ...
        overrideSeedOffset < 0 || overrideSeedOffset ~= floor(overrideSeedOffset)
    error('KERR_NARMA_SEED_OFFSET must be a nonnegative integer.');
end
cfg.seedOffset = overrideSeedOffset;
cfg.masterSeed = 132 + 1009*cfg.seedOffset;
cfg.reservoirSeed = 22 + 2003*cfg.seedOffset;
cfg.maskSeed = 900 + 3001*cfg.seedOffset;
cfg.copySeed = 1234 + 4001*cfg.seedOffset;
cfg.protocolMode = lower(strtrim(overrideProtocolMode));
validProtocolModes = {'development','selection','locked'};
if ~ismember(cfg.protocolMode, validProtocolModes)
    error('KERR_NARMA_PROTOCOL_MODE must be development, selection, or locked.');
end
cfg.evaluateTest = ~strcmp(cfg.protocolMode, 'selection');

% Dataset and splitting
cfg.numSamples = 22000;
cfg.washout    = 2000;
cfg.numTrain   = 12000;
cfg.numVal     = 4000;
cfg.numTest    = 3000;

% Time multiplexing
cfg.dt = 0.0125;
cfg.stepsPerSample = 55;
cfg.numVirtual = 10;
cfg.virtualNodeIdx = unique(round(linspace(round(0.20*cfg.stepsPerSample), ...
                                           cfg.stepsPerSample, cfg.numVirtual)));
cfg.numVirtual = numel(cfg.virtualNodeIdx);

% Input masking inside each input-hold interval
cfg.useInputMask = true;
cfg.maskStrength = 1.00;
cfg.maskBias = 0.15;
cfg.inputClip = 1.25;

% Ensemble of reservoirs
cfg.numReservoirs = 3;
cfg.copyDetuningDisorder = 0.05;
cfg.copyMaskDisorder = 0.10;
cfg.copyDriveDisorder = 0.10;
cfg.copyJDisorder = 0.04;

% PCA and tapped delays
cfg.nPC = 350;
cfg.tapDelays = [0 1 2 3 4 5 6 7 8 9 10 12 15];
cfg.featureMode = 'all_features';
if ~isempty(overrideBaseFeatureMode)
    if ~(ischar(overrideBaseFeatureMode) || ...
            (isstring(overrideBaseFeatureMode) && isscalar(overrideBaseFeatureMode)))
        error('KERR_NARMA_BASE_FEATURE_MODE must be a character vector or string scalar.');
    end
    cfg.featureMode = char(overrideBaseFeatureMode);
end

% Ridge validation. Keep this conservative; previous optima were ~1e3.
cfg.lambdaGrid = logspace(0,7,85);

% Baselines, sweeps, feature ablations, and saving
cfg.runBaselines = ~overrideSkipBaselines;
cfg.runPhysicalAblations = true;  % K=0 and J=0 ablations, independently fitted
cfg.runKSweep = false;
cfg.runJSweep = false;
cfg.runFeatureAblations = false;
cfg.Klist = [0, -0.02, -0.05, -0.10, -0.20, -0.35, -0.50, -0.80, -1.10, -1.40, -1.70];
if ~isempty(overrideKList)
    cfg.Klist = overrideKList;
end
cfg.Jlist = [0, 0.05, 0.10, 0.17, 0.25, 0.34, 0.45, 0.60];
cfg.JSweepKlist = [0, -1.62];
if ~isempty(overrideJList)
    cfg.Jlist = overrideJList;
end
if ~isempty(overrideJSweepKList)
    cfg.JSweepKlist = overrideJSweepKList;
end
cfg.featureModes = {'linear_features','number_features','number_nonlinear','phase_coherence','all_features'};
if ~isempty(overrideFeatureModes)
    if iscell(overrideFeatureModes)
        cfg.featureModes = overrideFeatureModes(:).';
    elseif isstring(overrideFeatureModes) || ischar(overrideFeatureModes)
        cfg.featureModes = cellstr(overrideFeatureModes);
    else
        error('KERR_NARMA_FEATURE_MODES must be a cell array, string array, or character vector.');
    end
end
if ~isempty(overrideFeatureCases) && (size(overrideFeatureCases,2) ~= 2 || ...
        any(~isfinite(overrideFeatureCases(:))))
    error('KERR_NARMA_FEATURE_CASES must be a finite n-by-2 matrix of [K,J] rows.');
end
cfg.featureCases = overrideFeatureCases;
cfg.validateFeatureCache = overrideValidateFeatureCache;
cfg.saveLargeMatrices = false;
cfg.saveRawFeatures = overrideSaveRawFeatures;
cfg.saveCompactFeatures = overrideSaveCompactFeatures;
cfg.makePlots = true;
cfg.quickTest = false;
cfg.smokeTest = false;
cfg.taskLabel = overrideTaskLabel;
cfg.outputPrefix = fullfile(scriptDir, 'Fig3_KerrReservoir_NARMA10_Reproducible');
if ~isempty(overrideOutputTag)
    cfg.outputPrefix = fullfile(scriptDir, ['Fig3_KerrReservoir_NARMA10_Reproducible_' char(overrideOutputTag)]);
end

% Command-line overrides, useful for smoke tests:
% matlab -batch "KERR_NARMA_QUICK=true; run('Figure 3/Fig3_KerrReservoir_NARMA10_Reproducible.m')"
if overrideQuick
    cfg.quickTest = true;
end
if overrideSmoke
    cfg.quickTest = true;
    cfg.smokeTest = true;
end
if overrideKSweep
    cfg.runKSweep = true;
end
if overrideJSweep
    cfg.runJSweep = true;
end
if overrideFeatureAblations
    cfg.runFeatureAblations = true;
end
if overrideSkipPhysical
    cfg.runPhysicalAblations = false;
end
if overrideDisablePlots
    cfg.makePlots = false;
end

if ~isscalar(overrideCopyDisorderScale) || ~isfinite(overrideCopyDisorderScale) || ...
        overrideCopyDisorderScale < 0
    error('KERR_NARMA_COPY_DISORDER_SCALE must be a nonnegative finite scalar.');
end
cfg.copyDetuningDisorder = overrideCopyDisorderScale*cfg.copyDetuningDisorder;
cfg.copyMaskDisorder = overrideCopyDisorderScale*cfg.copyMaskDisorder;
cfg.copyDriveDisorder = overrideCopyDisorderScale*cfg.copyDriveDisorder;
cfg.copyJDisorder = overrideCopyDisorderScale*cfg.copyJDisorder;
if ~isempty(overrideCopyDetuningDisorder)
    if ~isscalar(overrideCopyDetuningDisorder) || ...
            ~isfinite(overrideCopyDetuningDisorder) || overrideCopyDetuningDisorder < 0
        error('KERR_NARMA_COPY_DETUNING_DISORDER must be a nonnegative finite scalar.');
    end
    cfg.copyDetuningDisorder = overrideCopyDetuningDisorder;
end

if cfg.quickTest
    fprintf('Quick-test mode enabled: using a reduced dataset and smaller reservoir ensemble.\n');
    cfg.numSamples = 900;
    cfg.washout    = 80;
    cfg.numTrain   = 300;
    cfg.numVal     = 150;
    cfg.numTest    = 150;
    cfg.stepsPerSample = 8;
    cfg.numVirtual = 3;
    cfg.virtualNodeIdx = unique(round(linspace(round(0.20*cfg.stepsPerSample), ...
                                               cfg.stepsPerSample, cfg.numVirtual)));
    cfg.numVirtual = numel(cfg.virtualNodeIdx);
    cfg.numReservoirs = 1;
    cfg.nPC = 16;
    cfg.tapDelays = [0 1 2 4 7];
    cfg.lambdaGrid = logspace(-1,5,24);
    cfg.runPhysicalAblations = true;
    cfg.runKSweep = overrideKSweep;
    cfg.runJSweep = overrideJSweep;
    cfg.runFeatureAblations = overrideFeatureAblations;
    cfg.Klist = [0, -0.10, -0.50, -1.62];
    if ~isempty(overrideKList)
        cfg.Klist = overrideKList;
    end
    cfg.Jlist = [0, 0.17, 0.34, 0.60];
    cfg.JSweepKlist = [0, -1.62];
    if ~isempty(overrideJList)
        cfg.Jlist = overrideJList;
    end
    if ~isempty(overrideJSweepKList)
        cfg.JSweepKlist = overrideJSweepKList;
    end
    cfg.outputPrefix = fullfile(scriptDir, 'Fig3_KerrReservoir_NARMA10_Reproducible_QUICK');
    if ~isempty(overrideOutputTag)
        cfg.outputPrefix = fullfile(scriptDir, ['Fig3_KerrReservoir_NARMA10_Reproducible_QUICK_' char(overrideOutputTag)]);
    end

    if cfg.smokeTest
        fprintf('Smoke-test mode enabled: using minimal sizes and disabling plots/physical ablations.\n');
        cfg.numSamples = 220;
        cfg.washout    = 20;
        cfg.numTrain   = 70;
        cfg.numVal     = 40;
        cfg.numTest    = 40;
        cfg.stepsPerSample = 3;
        cfg.numVirtual = 1;
        cfg.virtualNodeIdx = cfg.stepsPerSample;
        cfg.numReservoirs = 1;
        cfg.nPC = 4;
        cfg.tapDelays = [0 1 2];
        cfg.lambdaGrid = logspace(-1,3,10);
        cfg.runPhysicalAblations = false;
        cfg.runKSweep = false;
        cfg.runJSweep = overrideJSweep;
        cfg.runFeatureAblations = overrideFeatureAblations;
        cfg.Jlist = [0, 0.34];
        cfg.JSweepKlist = [0, -1.62];
        if ~isempty(overrideJList)
            cfg.Jlist = overrideJList;
        end
        if ~isempty(overrideJSweepKList)
            cfg.JSweepKlist = overrideJSweepKList;
        end
        cfg.makePlots = false;
        cfg.outputPrefix = fullfile(scriptDir, 'Fig3_KerrReservoir_NARMA10_Reproducible_SMOKE');
        if ~isempty(overrideOutputTag)
            cfg.outputPrefix = fullfile(scriptDir, ['Fig3_KerrReservoir_NARMA10_Reproducible_SMOKE_' char(overrideOutputTag)]);
        end
    end
end

% Apply skip flags after quick/smoke presets, because those presets rewrite
% several run-control fields.
if overrideSkipPhysical
    cfg.runPhysicalAblations = false;
end

% Explicit revision-protocol overrides are applied after quick/smoke presets.
if ~isempty(overrideNumReservoirs)
    if ~isscalar(overrideNumReservoirs) || ~isfinite(overrideNumReservoirs) || ...
            overrideNumReservoirs < 1 || ...
            overrideNumReservoirs ~= floor(overrideNumReservoirs)
        error('KERR_NARMA_NUM_RESERVOIRS must be a positive integer.');
    end
    cfg.numReservoirs = overrideNumReservoirs;
end
if ~isempty(overrideNPC)
    if ~isscalar(overrideNPC) || ~isfinite(overrideNPC) || ...
            overrideNPC < 1 || overrideNPC ~= floor(overrideNPC)
        error('KERR_NARMA_NPC must be a positive integer.');
    end
    cfg.nPC = overrideNPC;
end
if ~isempty(overrideTapDelays)
    if ~isvector(overrideTapDelays) || any(~isfinite(overrideTapDelays)) || ...
            any(overrideTapDelays < 0) || any(overrideTapDelays ~= floor(overrideTapDelays))
        error('KERR_NARMA_TAP_DELAYS must contain nonnegative integers.');
    end
    cfg.tapDelays = unique(overrideTapDelays(:).', 'stable');
end
if ~isempty(overrideStepsPerSample)
    if ~isscalar(overrideStepsPerSample) || ~isfinite(overrideStepsPerSample) || ...
            overrideStepsPerSample < 1 || overrideStepsPerSample ~= floor(overrideStepsPerSample)
        error('KERR_NARMA_STEPS_PER_SAMPLE must be a positive integer.');
    end
    cfg.stepsPerSample = overrideStepsPerSample;
end
if ~isempty(overrideDt)
    if ~isscalar(overrideDt) || ~isfinite(overrideDt) || overrideDt <= 0
        error('KERR_NARMA_DT must be a positive finite scalar.');
    end
    cfg.dt = overrideDt;
end
if ~isempty(overrideNumVirtual)
    if ~isscalar(overrideNumVirtual) || ~isfinite(overrideNumVirtual) || ...
            overrideNumVirtual < 1 || overrideNumVirtual ~= floor(overrideNumVirtual)
        error('KERR_NARMA_NUM_VIRTUAL must be a positive integer.');
    end
    cfg.numVirtual = overrideNumVirtual;
end
if cfg.numVirtual > cfg.stepsPerSample
    error('The number of virtual samples cannot exceed integration steps per sample.');
end
cfg.virtualNodeIdx = unique(round(linspace(round(0.20*cfg.stepsPerSample), ...
    cfg.stepsPerSample, cfg.numVirtual)));
cfg.numVirtual = numel(cfg.virtualNodeIdx);
if ~isempty(overrideVirtualNodeIdx)
    if ~isvector(overrideVirtualNodeIdx) || any(~isfinite(overrideVirtualNodeIdx)) || ...
            any(overrideVirtualNodeIdx < 1) || ...
            any(overrideVirtualNodeIdx > cfg.stepsPerSample) || ...
            any(overrideVirtualNodeIdx ~= floor(overrideVirtualNodeIdx))
        error(['KERR_NARMA_VIRTUAL_NODE_IDX must contain integer integration ' ...
            'indices within the input-hold interval.']);
    end
    cfg.virtualNodeIdx = unique(overrideVirtualNodeIdx(:).', 'sorted');
    cfg.numVirtual = numel(cfg.virtualNodeIdx);
end
if isempty(overrideInputGainScale)
    cfg.inputGainScale = 1;
else
    if ~isscalar(overrideInputGainScale) || ~isfinite(overrideInputGainScale) || ...
            overrideInputGainScale <= 0
        error('KERR_NARMA_INPUT_GAIN_SCALE must be a positive finite scalar.');
    end
    cfg.inputGainScale = overrideInputGainScale;
end
if ~isempty(overrideLambdaGrid)
    if ~isvector(overrideLambdaGrid) || any(~isfinite(overrideLambdaGrid)) || ...
            any(overrideLambdaGrid <= 0)
        error('KERR_NARMA_LAMBDA_GRID must contain positive finite values.');
    end
    cfg.lambdaGrid = unique(overrideLambdaGrid(:).', 'sorted');
end
cfg.readoutVariants = overrideReadoutVariants(:);
requiredVariantFields = {'label','virtualNodeIdx','tapDelays','nPC'};
for q = 1:numel(cfg.readoutVariants)
    for f = 1:numel(requiredVariantFields)
        assert(isfield(cfg.readoutVariants(q), requiredVariantFields{f}), ...
            'Readout variant %d is missing field %s.', q, requiredVariantFields{f});
    end
    nodes = cfg.readoutVariants(q).virtualNodeIdx(:).';
    taps = cfg.readoutVariants(q).tapDelays(:).';
    retainedPC = cfg.readoutVariants(q).nPC;
    assert(~isempty(nodes) && all(ismember(nodes, cfg.virtualNodeIdx)), ...
        'Readout variant nodes must be a subset of the simulated union nodes.');
    assert(~isempty(taps) && all(isfinite(taps)) && all(taps >= 0) && ...
        all(taps == floor(taps)), 'Readout variant taps must be nonnegative integers.');
    assert(isscalar(retainedPC) && isfinite(retainedPC) && retainedPC >= 1 && ...
        retainedPC == floor(retainedPC), 'Readout variant nPC must be a positive integer.');
    cfg.readoutVariants(q).virtualNodeIdx = unique(nodes, 'stable');
    cfg.readoutVariants(q).tapDelays = unique(taps, 'stable');
end
cfg.featureBudgetVariants = overrideFeatureBudgetVariants(:);
cfg.featureBudgetLambdaMap = overrideFeatureBudgetLambdaMap;
requiredBudgetFields = {'label','tapDelays','nPC'};
for q = 1:numel(cfg.featureBudgetVariants)
    for f = 1:numel(requiredBudgetFields)
        assert(isfield(cfg.featureBudgetVariants(q), requiredBudgetFields{f}), ...
            'Feature-budget variant %d is missing field %s.', q, ...
            requiredBudgetFields{f});
    end
    taps = cfg.featureBudgetVariants(q).tapDelays(:).';
    retainedPC = cfg.featureBudgetVariants(q).nPC;
    assert(~isempty(taps) && all(isfinite(taps)) && all(taps >= 0) && ...
        all(taps == floor(taps)), ...
        'Feature-budget variant taps must be nonnegative integers.');
    assert(isscalar(retainedPC) && isfinite(retainedPC) && retainedPC >= 1 && ...
        retainedPC == floor(retainedPC), ...
        'Feature-budget variant nPC must be a positive integer.');
    cfg.featureBudgetVariants(q).tapDelays = unique(taps, 'stable');
    if isfield(cfg.featureBudgetVariants(q),'lambdaGrid') && ...
            ~isempty(cfg.featureBudgetVariants(q).lambdaGrid)
        variantLambda = cfg.featureBudgetVariants(q).lambdaGrid(:).';
        assert(all(isfinite(variantLambda)) && all(variantLambda > 0), ...
            'Feature-budget lambda grids must be positive and finite.');
        cfg.featureBudgetVariants(q).lambdaGrid = unique(variantLambda,'sorted');
    end
end
if ~isempty(cfg.featureBudgetLambdaMap)
    expectedLambdaCount = size(cfg.featureCases,1)*numel(cfg.featureModes)* ...
        numel(cfg.featureBudgetVariants);
    assert(numel(cfg.featureBudgetLambdaMap) == expectedLambdaCount && ...
        all(isfinite(cfg.featureBudgetLambdaMap(:))) && ...
        all(cfg.featureBudgetLambdaMap(:) > 0), ...
        'Feature-budget lambda map has invalid dimensions or values.');
    cfg.featureBudgetLambdaMap = reshape(cfg.featureBudgetLambdaMap, ...
        size(cfg.featureCases,1),numel(cfg.featureModes), ...
        numel(cfg.featureBudgetVariants));
end

if ~strcmp(cfg.protocolMode, 'development') && isempty(overrideOutputTag)
    error('Selection and locked runs require a unique KERR_NARMA_OUTPUT_TAG.');
end
if strcmp(cfg.protocolMode, 'selection')
    cfg.makePlots = false;
elseif strcmp(cfg.protocolMode, 'locked') && ...
        (cfg.runKSweep || cfg.runJSweep || cfg.runPhysicalAblations || ...
        (cfg.runFeatureAblations && ~overrideLockedPair))
    error(['Locked mode forbids sweeps and ordinary ablations; only the ' ...
        'predeclared locked feature pair is allowed.']);
end
cfg.lockedPair = overrideLockedPair;

%% ======================== Base Kerr reservoir model =======================
P = makeBaseKerrReservoir(cfg.reservoirSeed);
if ~isempty(overrideBaseK)
    P.K = overrideBaseK;
end
if ~isempty(overrideBaseJ)
    P.J0 = overrideBaseJ;
    P.J = P.J0*P.Adj;
end
P.gDelta = cfg.inputGainScale*P.gDelta;
P.gF = cfg.inputGainScale*P.gF;
if overrideDisableStaticDisorder
    P.Delta0 = linspace(-1.05,1.05,P.N).';
end
P.gDelta = applyEncodingPattern(P.gDelta, overrideGDeltaMode, 'gDelta');
P.gF = applyEncodingPattern(P.gF, overrideGFMode, 'gF');
if ~isempty(overrideInputMode)
    validInputModes = {'detuning','amplitude','detuning+amplitude'};
    overrideInputMode = lower(strtrim(overrideInputMode));
    if ~ismember(overrideInputMode, validInputModes)
        error('KERR_NARMA_INPUT_MODE must be detuning, amplitude, or detuning+amplitude.');
    end
    P.inputMode = overrideInputMode;
end
cfg.encodingGDeltaMode = lower(strtrim(overrideGDeltaMode));
cfg.encodingGFMode = lower(strtrim(overrideGFMode));
cfg.staticDisorderEnabled = ~overrideDisableStaticDisorder;
cfg.inputMode = P.inputMode;

%% ======================== Input mask construction =========================
rng(cfg.maskSeed);
if isempty(overrideInputMask)
    cfg.inputMask = 2*rand(cfg.stepsPerSample,1) - 1;
else
    cfg.inputMask = overrideInputMask(:);
    assert(numel(cfg.inputMask)==cfg.stepsPerSample && all(isfinite(cfg.inputMask)), ...
        'KERR_NARMA_INPUT_MASK must be finite and match stepsPerSample.');
end
if isempty(overrideInputBias)
    cfg.inputBias = cfg.maskBias*(2*rand(cfg.stepsPerSample,1) - 1);
else
    cfg.inputBias = overrideInputBias(:);
    assert(numel(cfg.inputBias)==cfg.stepsPerSample && all(isfinite(cfg.inputBias)), ...
        'KERR_NARMA_INPUT_BIAS must be finite and match stepsPerSample.');
end

%% ======================== Input and target ================================
if isempty(overrideCustomInputRaw)
    [uN, uEnc, yN, datasetSeed] = makeStableNarma10Dataset(cfg.numSamples, cfg.masterSeed);
else
    uN = overrideCustomInputRaw(:);
    uEnc = overrideCustomInputEncoded(:);
    yN = overrideCustomTarget(:);
    datasetSeed = cfg.masterSeed;
    assert(numel(uN)==cfg.numSamples && numel(uEnc)==cfg.numSamples && ...
        numel(yN)==cfg.numSamples, ...
        'Custom input and target lengths must equal cfg.numSamples=%d.',cfg.numSamples);
    assert(all(isfinite([uN;uEnc;yN])), ...
        'Custom input or target contains NaN or Inf.');
end
fprintf('%s dataset seed = %d | max y = %.4f | var y = %.5g\n', ...
    cfg.taskLabel,datasetSeed,max(yN),var(yN,1));

%% ======================== Indexing ========================================
allTapDelays = cfg.tapDelays;
for q = 1:numel(cfg.readoutVariants)
    allTapDelays = [allTapDelays cfg.readoutVariants(q).tapDelays]; %#ok<AGROW>
end
startIdx = cfg.washout + max([20, allTapDelays]) + 1;
idxTrain = startIdx:(startIdx + cfg.numTrain - 1);
idxVal   = (idxTrain(end)+1):(idxTrain(end)+cfg.numVal);
idxTest  = (idxVal(end)+1):(idxVal(end)+cfg.numTest);
idxTrainVal = [idxTrain idxVal];

if idxTest(end) > cfg.numSamples
    error('Not enough samples for the requested washout/train/val/test split.');
end
cfg.idxTrain = idxTrain;
cfg.idxVal = idxVal;
cfg.idxTestReserved = idxTest;
if ~cfg.evaluateTest
    idxTest = [];
end

%% ======================== Main simulation =================================
fprintf('\n=== Kerr %s ensemble-masked publication run ===\n',cfg.taskLabel);
fprintf('Protocol mode = %s | test evaluation enabled = %d\n', ...
    cfg.protocolMode, cfg.evaluateTest);
fprintf('Samples = %d | N = %d | reservoirs = %d | virtual nodes = %d | taps = %d\n', ...
    cfg.numSamples, P.N, cfg.numReservoirs, cfg.numVirtual, numel(cfg.tapDelays));
fprintf('dt = %.5g | steps/input = %d | T_sample = %.5g\n', ...
    cfg.dt, cfg.stepsPerSample, cfg.dt*cfg.stepsPerSample);

if cfg.runFeatureAblations || cfg.validateFeatureCache
    [Xvirt, betaFinalAll, featureMainStates] = simulateEnsembleReservoir(uEnc, P, cfg);
else
    [Xvirt, betaFinalAll] = simulateEnsembleReservoir(uEnc, P, cfg);
    featureMainStates = [];
end

fprintf('Raw virtual feature dimension = %d\n', size(Xvirt,2));
fprintf('Max |beta|                   = %.4e\n', max(abs(betaFinalAll(:))));
fprintf('Max |Xvirt|                  = %.4e\n', max(abs(Xvirt(:))));
fprintf('Any NaN in Xvirt?            = %d\n', any(isnan(Xvirt(:))));
fprintf('Any Inf in Xvirt?            = %d\n', any(isinf(Xvirt(:))));

assert(all(isfinite(Xvirt(:))), 'Xvirt contains NaN or Inf. Reduce nonlinearity or increase damping.');
assert(all(isfinite(betaFinalAll(:))), 'Reservoir trajectory contains NaN or Inf.');
assert(all(isfinite(yN(:))), 'Task target contains NaN or Inf.');

if cfg.validateFeatureCache
    validateFeatureCache(featureMainStates, Xvirt, uEnc, P, cfg);
end

%% ======================== PCA/SVD before tapped delays ====================
fprintf('Computing top %d PCA/SVD components from training features...\n', cfg.nPC);
[Zvirt, pcaInfo] = pcaProjectTrainOnly(Xvirt, idxTrain, cfg.nPC);
fprintf('Projection completed. Retained PCs = %d | last singular value = %.4e\n', ...
    size(Zvirt,2), pcaInfo.singularValues(end));

Ztap = addTappedDelays(Zvirt, cfg.tapDelays);
Xall = [ones(cfg.numSamples,1), Ztap];

fprintf('Compressed+tapped feature dimension = %d\n', size(Xall,2));
fprintf('Train samples                       = %d\n', numel(idxTrain));
fprintf('Any NaN in compressed/tapped Xall?  = %d\n', any(isnan(Xall(:))));
fprintf('Any Inf in compressed/tapped Xall?  = %d\n', any(isinf(Xall(:))));
fprintf('Any NaN in NARMA target yN?         = %d\n', any(isnan(yN(:))));
fprintf('Any Inf in NARMA target yN?         = %d\n', any(isinf(yN(:))));

assert(all(isfinite(Xall(:))), 'Compressed/tapped feature matrix contains NaN or Inf.');

%% ======================== Train and evaluate main readout =================
main = trainValidateTestReadout(Xall, yN, idxTrain, idxVal, idxTest, cfg.lambdaGrid, 'main Kerr');

mainInfo.label = 'main physical case';
mainInfo.K = P.K;
mainInfo.J0 = P.J0;
mainInfo.featureMode = cfg.featureMode;
mainInfo.rawFeatureDim = size(Xvirt,2);
mainInfo.retainedPC = size(Zvirt,2);
mainInfo.tappedFeatureDim = size(Xall,2);
mainInfo.maxAbsBeta = max(abs(betaFinalAll(:)));
mainInfo.maxAbsXvirt = max(abs(Xvirt(:)));
mainInfo.anyNaNXvirt = any(isnan(Xvirt(:)));
mainInfo.anyInfXvirt = any(isinf(Xvirt(:)));
mainInfo.anyNaNXcase = any(isnan(Xall(:)));
mainInfo.anyInfXcase = any(isinf(Xall(:)));
mainInfo.singularValues = pcaInfo.singularValues;

fprintf('Best ridge lambda from validation = %.3e | val NRMSE = %.4f\n', ...
    main.lambdaBest, main.valNRMSE);
fprintf('Publication run %s NRMSE       = %.4f\n',cfg.taskLabel,main.NRMSE);
fprintf('Publication run squared corr. R^2  = %.4f\n', main.R2corr);
fprintf('Publication run true test R^2      = %.4f\n', main.R2true);

%% ======================== Baselines and ablations =========================
results = struct();
results.main = main;
results.mainInfo = mainInfo;
if ~isempty(cfg.readoutVariants)
    results.readoutVariants = evaluateReadoutVariantsFromUnion( ...
        Xvirt, yN, P, cfg, idxTrain, idxVal, idxTest);
end

if cfg.runBaselines
    % Baseline 1: same compressed reservoir, no temporal taps.
    XnoTap = [ones(cfg.numSamples,1), Zvirt];
    noTap = trainValidateTestReadout(XnoTap, yN, idxTrain, idxVal, idxTest, cfg.lambdaGrid, 'reservoir no taps');
    results.noTap = noTap;
    fprintf('Baseline reservoir without taps NRMSE = %.4f\n', noTap.NRMSE);

    % Baseline 2: input-only linear tapped delays.
    Xin = makeInputTappedFeatures(uN, cfg.tapDelays);
    inputOnly = trainValidateTestReadout(Xin, yN, idxTrain, idxVal, idxTest, cfg.lambdaGrid, 'input-only taps');
    results.inputOnly = inputOnly;
    fprintf('Baseline input-only linear taps NRMSE = %.4f\n', inputOnly.NRMSE);
end

if cfg.runPhysicalAblations
    % Ablation K = 0: removes local Kerr nonlinearity.
    fprintf('\nRunning physical ablation with independent PCA/readout: K = 0...\n');
    PnoK = P; PnoK.K = 0;
    [noK, noKInfo] = evaluateReservoirCase(uEnc, yN, PnoK, cfg, idxTrain, idxVal, idxTest, 'K=0');
    results.noK = noK;
    results.noKInfo = noKInfo;
    fprintf('Physical ablation K = 0 NRMSE        = %.4f\n', noK.NRMSE);

    % Ablation J = 0: removes coherent hopping/coupling.
    fprintf('\nRunning physical ablation with independent PCA/readout: J = 0...\n');
    PnoJ = P; PnoJ.J0 = 0; PnoJ.J = zeros(P.N);
    [noJ, noJInfo] = evaluateReservoirCase(uEnc, yN, PnoJ, cfg, idxTrain, idxVal, idxTest, 'J=0');
    results.noJ = noJ;
    results.noJInfo = noJInfo;
    fprintf('Physical ablation J = 0 NRMSE        = %.4f\n', noJ.NRMSE);
end

if cfg.runKSweep
    results.KSweep = runKSweepCases(uEnc, yN, P, cfg, idxTrain, idxVal, idxTest);
    plotKSweepSummary(results.KSweep, cfg);
end

if cfg.runJSweep
    results.JSweep = runJSweepCases(uEnc, yN, P, cfg, idxTrain, idxVal, idxTest, main, mainInfo);
    if cfg.makePlots
        plotJSweepSummary(results.JSweep, cfg);
    end
end

if cfg.runFeatureAblations
    results.featureAblation = runFeatureAblationCases(uEnc, yN, P, cfg, ...
        idxTrain, idxVal, idxTest, main, mainInfo, featureMainStates, betaFinalAll);
    plotFeatureAblationSummary(results.featureAblation, cfg);
end

%% ======================== Publication-quality plot ========================
if cfg.makePlots
fig = figure('Color','w','Name','Kerr reservoir NARMA10 ensemble masked');
set(fig,'Units','inches','Position',[1 1 7.2 5.2]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

nexttile; box on; hold on;
traceLen = min(450, numel(uN));
plot(uN(1:traceLen), 'k-', 'LineWidth', 0.9);
plot(rescale(abs(betaFinalAll(1:traceLen,1:min(6,size(betaFinalAll,2)))).^2, 0, 0.5), 'LineWidth', 0.8);
xlabel('input step $k$','Interpreter','latex');
ylabel('signal','Interpreter','latex');
title('(a) Input and representative Kerr intensities','Interpreter','latex');
set(gca,'FontSize',11,'TickLabelInterpreter','latex');

nexttile; box on; hold on;
semilogx(cfg.lambdaGrid, main.valCurve, 'o-', 'LineWidth',1.0, 'MarkerSize',4);
xline(main.lambdaBest,'--','LineWidth',1.0);
xlabel('$\lambda_{\rm R}$','Interpreter','latex');
ylabel('validation NRMSE','Interpreter','latex');
title('(b) Ridge validation','Interpreter','latex');
set(gca,'FontSize',11,'TickLabelInterpreter','latex');

nexttile; box on; hold on;
testTraceLen = min(450, numel(main.Yte));
plot(main.Yte(1:testTraceLen), 'k-', 'LineWidth', 1.1);
plot(main.Yhat(1:testTraceLen), '--', 'LineWidth', 1.1);
if isfield(results,'inputOnly')
    plot(results.inputOnly.Yhat(1:testTraceLen), ':', 'LineWidth', 1.1);
    legend({'target','Kerr reservoir','input-only taps'},'Interpreter','latex','Location','best');
else
    legend({'target','Kerr reservoir'},'Interpreter','latex','Location','best');
end
xlabel('test step','Interpreter','latex');
ylabel('$y_k$','Interpreter','latex');
title(sprintf('(c) %s prediction, NRMSE = %.3f',cfg.taskLabel,main.NRMSE), ...
    'Interpreter','none');
set(gca,'FontSize',11,'TickLabelInterpreter','latex');

nexttile; box on; hold on;
labels = {'Kerr'};
vals = main.NRMSE;
if isfield(results,'noTap')
    labels{end+1} = 'no taps'; vals(end+1) = results.noTap.NRMSE;
end
if isfield(results,'inputOnly')
    labels{end+1} = 'input only'; vals(end+1) = results.inputOnly.NRMSE;
end
if isfield(results,'noK')
    labels{end+1} = '$K=0$'; vals(end+1) = results.noK.NRMSE;
end
if isfield(results,'noJ')
    labels{end+1} = '$J=0$'; vals(end+1) = results.noJ.NRMSE;
end
bar(vals, 'LineWidth',0.8);
set(gca,'XTick',1:numel(labels),'XTickLabel',labels,'TickLabelInterpreter','latex');
xtickangle(25);
ylabel('test NRMSE','Interpreter','latex');
title('(d) Baselines and physical ablations','Interpreter','latex');
set(gca,'FontSize',11,'TickLabelInterpreter','latex');

exportgraphics(fig, [cfg.outputPrefix '.pdf'], 'ContentType','vector');
exportgraphics(fig, [cfg.outputPrefix '.png'], 'Resolution', 300);
end

%% ======================== Save summary ====================================
summaryFile = [cfg.outputPrefix '_summary.mat'];
if cfg.saveLargeMatrices
    save(summaryFile, 'cfg','P','uN','uEnc','yN','datasetSeed','results', ...
        'pcaInfo','Xvirt','Zvirt','Xall','betaFinalAll','-v7.3');
elseif cfg.saveRawFeatures
    save(summaryFile, 'cfg','P','uN','uEnc','yN','datasetSeed','results', ...
        'pcaInfo','Xvirt','Zvirt','betaFinalAll','-v7.3');
elseif cfg.saveCompactFeatures
    save(summaryFile, 'cfg','P','uN','uEnc','yN','datasetSeed','results', ...
        'pcaInfo','Zvirt','betaFinalAll','-v7.3');
else
    save(summaryFile, 'cfg','P','uN','uEnc','yN','datasetSeed','results', ...
        'pcaInfo','betaFinalAll','-v7.3');
end
if isfield(results, 'KSweep')
    writeKSweepCSV(results.KSweep, [cfg.outputPrefix '_KSweep_summary.csv']);
end
if isfield(results, 'JSweep')
    writeJSweepCSV(results.JSweep, [cfg.outputPrefix '_JSweep_summary.csv']);
end
if isfield(results, 'featureAblation')
    writeFeatureAblationCSV(results.featureAblation, [cfg.outputPrefix '_FeatureAblations_summary.csv']);
    if ~isempty(cfg.featureBudgetVariants)
        writeFeatureBudgetVariantsCSV(results.featureAblation, ...
            [cfg.outputPrefix '_FeatureBudgetVariants_summary.csv']);
    end
end
if isfield(results, 'readoutVariants')
    writeReadoutVariantsCSV(results.readoutVariants, ...
        [cfg.outputPrefix '_ReadoutVariants_summary.csv']);
end
fprintf('Saved summary to %s\n', summaryFile);

%% ============================= Local functions ============================
function P = makeBaseKerrReservoir(seed)
    rng(seed);
    P.N = 12;

    % Edge-of-chaos-like, but stable, parameter set.
    P.kappa = 0.120;
    P.K     = -1.62;
    P.J0    = 0.34;
    P.F0    = 0.50;

    Adj1 = circshift(eye(P.N),1) + circshift(eye(P.N),-1);
    Adj2 = circshift(eye(P.N),2) + circshift(eye(P.N),-2);
    Adj3 = circshift(eye(P.N),3) + circshift(eye(P.N),-3);
    P.Adj = Adj1 + 0.32*Adj2 + 0.10*Adj3;
    P.J   = P.J0 * P.Adj;

    P.Delta0 = linspace(-1.05,1.05,P.N).' + 0.06*randn(P.N,1);

    mask = [1.00; -0.82; 0.61; -0.95; 0.74; -0.48; ...
            0.88; -0.58; 0.36; -0.70; 0.52; -0.66];

    P.gDelta = 0.72*mask;
    P.gF     = 0.10*circshift(mask,3);
    P.inputMode = 'detuning+amplitude';
end

function values = applyEncodingPattern(values, mode, label)
    mode = lower(strtrim(mode));
    switch mode
        case {'heterogeneous','hetero'}
            return;
        case {'uniform','common'}
            amplitude = norm(values,2)/sqrt(numel(values));
            values = amplitude*ones(size(values));
        case {'zero','off','none'}
            values = zeros(size(values));
        otherwise
            error('Unknown %s encoding mode "%s".', label, mode);
    end
end

function [uN, uEnc, yN, usedSeed] = makeStableNarma10Dataset(numSamples, baseSeed)
    for trial = 0:200
        usedSeed = baseSeed + trial;
        rng(usedSeed);
        uN = 0.5*rand(numSamples,1);
        yN = narma10(uN);
        if all(isfinite(yN)) && var(yN,1) > 1e-8 && max(abs(yN)) < 10
            uEnc = 4*uN - 1;
            return;
        end
    end
    error('Could not generate a stable NARMA10 dataset.');
end

function y = narma10(u)
    u = u(:); T = numel(u); y = zeros(T,1);
    for k = 11:T-1
        y(k+1) = 0.3*y(k) + 0.05*y(k)*sum(y(k-9:k)) + 1.5*u(k-9)*u(k) + 0.1;
    end
end

function [Xall, betaFinalAll, virtualStatesAll] = simulateEnsembleReservoir(u, P, cfg)
    Xall = [];
    betaFinalAll = [];
    recordStates = nargout >= 3;
    virtualStatesAll = [];
    for r = 1:cfg.numReservoirs
        Pcopy = makeReservoirCopy(P, cfg, r);
        fprintf('  Simulating reservoir copy %d/%d...\n', r, cfg.numReservoirs);
        if recordStates
            [Xr, betar, statesR] = simulateReservoirVirtualMasked(u, Pcopy, cfg);
            virtualStatesAll = [virtualStatesAll, statesR]; %#ok<AGROW>
        else
            [Xr, betar] = simulateReservoirVirtualMasked(u, Pcopy, cfg);
        end
        Xall = [Xall, Xr]; %#ok<AGROW>
        betaFinalAll = [betaFinalAll, betar]; %#ok<AGROW>
    end
end

function [virtualStatesAll, betaFinalAll] = simulateEnsembleVirtualStates(u, P, cfg)
    virtualStatesAll = [];
    betaFinalAll = [];
    for r = 1:cfg.numReservoirs
        Pcopy = makeReservoirCopy(P, cfg, r);
        fprintf('  Simulating cached-state reservoir copy %d/%d...\n', r, cfg.numReservoirs);
        [statesR, betar] = simulateReservoirVirtualStates(u, Pcopy, cfg);
        virtualStatesAll = [virtualStatesAll, statesR]; %#ok<AGROW>
        betaFinalAll = [betaFinalAll, betar]; %#ok<AGROW>
    end
end

function Pcopy = makeReservoirCopy(P, cfg, r)
    rng(cfg.copySeed + 7919*r);
    Pcopy = P;
    Pcopy.Delta0 = P.Delta0 + cfg.copyDetuningDisorder*randn(P.N,1);
    Pcopy.gDelta = P.gDelta .* (1 + cfg.copyMaskDisorder*randn(P.N,1));
    Pcopy.gF     = P.gF     .* (1 + cfg.copyDriveDisorder*randn(P.N,1));
    Jnoise = 1 + cfg.copyJDisorder*randn(P.N);
    Jnoise = 0.5*(Jnoise + Jnoise.');
    Pcopy.J = P.J .* Jnoise;
    Pcopy.J = Pcopy.J - diag(diag(Pcopy.J));
end

function [X, betaFinal, virtualStates] = simulateReservoirVirtualMasked(u, P, cfg)
    N = P.N;
    rng(1000 + N);
    beta = 1e-4*exp(1i*2*pi*rand(N,1));
    numSamples = numel(u);
    localDim = numel(makeLocalFeatures(beta, cfg.featureMode));
    numVirtual = numel(cfg.virtualNodeIdx);
    X = zeros(numSamples, numVirtual*localDim);
    betaFinal = zeros(numSamples,N);
    recordStates = nargout >= 3;
    if recordStates
        virtualStates = complex(zeros(numSamples, numVirtual*N));
    else
        virtualStates = [];
    end

    for k = 1:numSamples
        uk = u(k);
        vcount = 0;
        xrow = zeros(1, numVirtual*localDim);
        if recordStates
            stateRow = complex(zeros(1, numVirtual*N));
        end

        for s = 1:cfg.stepsPerSample
            if cfg.useInputMask
                ueff = cfg.maskStrength*cfg.inputMask(s)*uk + cfg.inputBias(s);
                ueff = max(min(ueff, cfg.inputClip), -cfg.inputClip);
            else
                ueff = uk;
            end

            beta = rk4Step(@(b) rhsReservoir(b, ueff, P), beta, cfg.dt);

            if any(s == cfg.virtualNodeIdx)
                vcount = vcount + 1;
                idx = (vcount-1)*localDim + (1:localDim);
                xrow(idx) = makeLocalFeatures(beta, cfg.featureMode).';
                if recordStates
                    stateIdx = (vcount-1)*N + (1:N);
                    stateRow(stateIdx) = beta.';
                end
            end
        end
        X(k,:) = xrow;
        betaFinal(k,:) = beta.';
        if recordStates
            virtualStates(k,:) = stateRow;
        end

        if any(~isfinite(beta))
            error('Reservoir trajectory produced NaN/Inf at sample %d.', k);
        end
    end
end

function [virtualStates, betaFinal] = simulateReservoirVirtualStates(u, P, cfg)
    N = P.N;
    rng(1000 + N);
    beta = 1e-4*exp(1i*2*pi*rand(N,1));
    numSamples = numel(u);
    numVirtual = numel(cfg.virtualNodeIdx);
    virtualStates = complex(zeros(numSamples, numVirtual*N));
    betaFinal = complex(zeros(numSamples,N));

    for k = 1:numSamples
        uk = u(k);
        vcount = 0;
        stateRow = complex(zeros(1, numVirtual*N));

        for s = 1:cfg.stepsPerSample
            if cfg.useInputMask
                ueff = cfg.maskStrength*cfg.inputMask(s)*uk + cfg.inputBias(s);
                ueff = max(min(ueff, cfg.inputClip), -cfg.inputClip);
            else
                ueff = uk;
            end

            beta = rk4Step(@(b) rhsReservoir(b, ueff, P), beta, cfg.dt);

            if any(s == cfg.virtualNodeIdx)
                vcount = vcount + 1;
                stateIdx = (vcount-1)*N + (1:N);
                stateRow(stateIdx) = beta.';
            end
        end

        virtualStates(k,:) = stateRow;
        betaFinal(k,:) = beta.';
        if any(~isfinite(beta))
            error('Reservoir trajectory produced NaN/Inf at sample %d.', k);
        end
    end
end

function X = featureMatrixFromVirtualStates(virtualStates, N, featureMode)
    if mod(size(virtualStates,2), N) ~= 0
        error('Virtual-state width must be divisible by the number of modes.');
    end

    numSamples = size(virtualStates,1);
    numBlocks = size(virtualStates,2)/N;
    localDim = numel(makeLocalFeatures(virtualStates(1,1:N).', featureMode));
    X = zeros(numSamples, numBlocks*localDim);

    pairI = [];
    pairJ = [];
    for i = 1:N
        for j = i+1:N
            pairI(end+1) = i; %#ok<AGROW>
            pairJ(end+1) = j; %#ok<AGROW>
        end
    end
    numPairs = numel(pairI);

    for block = 1:numBlocks
        stateIdx = (block-1)*N + (1:N);
        beta = virtualStates(:,stateIdx);
        n = abs(beta).^2;
        theta = angle(beta);
        meanN = mean(n,2);
        varN = var(n,1,2);
        maxN = max(n,[],2);

        switch lower(featureMode)
            case {'linear_features','linear'}
                Xblock = [real(beta), imag(beta)];

            case {'number_features','number'}
                Xblock = [n, meanN, varN, maxN];

            case {'number_nonlinear','number-nonlinear'}
                nPairs = n(:,pairI).*n(:,pairJ);
                Xblock = [n, n.^2, sqrt(n + 1e-12), tanh(n), nPairs, ...
                    meanN, varN, maxN];

            case {'phase_coherence','phase-coherence'}
                phaseDiff = theta(:,pairI) - theta(:,pairJ);
                phasePairs = zeros(numSamples, 2*numPairs);
                phasePairs(:,1:2:end) = cos(phaseDiff);
                phasePairs(:,2:2:end) = sin(phaseDiff);
                coherence = beta(:,pairI).*conj(beta(:,pairJ));
                coherPairs = zeros(numSamples, 2*numPairs);
                coherPairs(:,1:2:end) = real(coherence);
                coherPairs(:,2:2:end) = imag(coherence);
                R1 = abs(mean(exp(1i*theta),2));
                R2 = abs(mean(exp(2i*theta),2));
                Xblock = [phasePairs, coherPairs, R1, R2];

            case {'all_features','all'}
                nPairs = n(:,pairI).*n(:,pairJ);
                phaseDiff = theta(:,pairI) - theta(:,pairJ);
                phasePairs = zeros(numSamples, 2*numPairs);
                phasePairs(:,1:2:end) = cos(phaseDiff);
                phasePairs(:,2:2:end) = sin(phaseDiff);
                coherence = beta(:,pairI).*conj(beta(:,pairJ));
                coherPairs = zeros(numSamples, 2*numPairs);
                coherPairs(:,1:2:end) = real(coherence);
                coherPairs(:,2:2:end) = imag(coherence);
                R1 = abs(mean(exp(1i*theta),2));
                R2 = abs(mean(exp(2i*theta),2));
                Xblock = [real(beta), imag(beta), n, n.^2, sqrt(n + 1e-12), ...
                    tanh(n), nPairs, phasePairs, coherPairs, R1, R2, ...
                    meanN, varN, maxN];

            otherwise
                error('Unknown featureMode "%s".', featureMode);
        end

        featureIdx = (block-1)*localDim + (1:localDim);
        X(:,featureIdx) = Xblock;
    end
end

function validateFeatureCache(virtualStates, XallFeatures, uEnc, P, cfg)
    fprintf('\n=== Validating cached feature reconstruction ===\n');
    modes = cfg.featureModes(:).';
    for m = 1:numel(modes)
        mode = modes{m};
        Xcached = featureMatrixFromVirtualStates(virtualStates, P.N, mode);
        if strcmpi(mode, 'all_features') || strcmpi(mode, 'all')
            Xdirect = XallFeatures;
        else
            cfgDirect = cfg;
            cfgDirect.featureMode = mode;
            [Xdirect, ~] = simulateEnsembleReservoir(uEnc, P, cfgDirect);
        end
        maxDiff = max(abs(Xcached(:) - Xdirect(:)));
        scale = max(1, max(abs(Xdirect(:))));
        fprintf('  %-18s | max abs difference = %.3e\n', mode, maxDiff);
        assert(maxDiff <= 1e-11*scale, ...
            'Cached feature reconstruction failed for mode %s.', mode);
        clear Xcached Xdirect;
    end
end

function db = rhsReservoir(beta, u, P)
    switch P.inputMode
        case 'detuning'
            Delta = P.Delta0 + P.gDelta*u;
            F = P.F0*ones(P.N,1);
        case 'amplitude'
            Delta = P.Delta0;
            F = P.F0 + P.gF*u;
        otherwise
            Delta = P.Delta0 + P.gDelta*u;
            F = P.F0 + P.gF*u;
    end
    db = -(P.kappa/2 + 1i*Delta).*beta ...
         -1i*P.K*(abs(beta).^2).*beta ...
         -1i*(P.J*beta) ...
         -1i*F;
end

function bnext = rk4Step(fun, b, dt)
    k1 = fun(b);
    k2 = fun(b + 0.5*dt*k1);
    k3 = fun(b + 0.5*dt*k2);
    k4 = fun(b + dt*k3);
    bnext = b + (dt/6)*(k1 + 2*k2 + 2*k3 + k4);
end

function x = makeLocalFeatures(beta, featureMode)
    if nargin < 2 || isempty(featureMode)
        featureMode = 'all_features';
    end

    N = numel(beta);
    n = abs(beta).^2;
    th = angle(beta);

    nPairs = [];
    phasePairs = [];
    coherPairs = [];
    for i = 1:N
        for j = i+1:N
            nPairs = [nPairs; n(i)*n(j)]; %#ok<AGROW>
            phasePairs = [phasePairs; cos(th(i)-th(j)); sin(th(i)-th(j))]; %#ok<AGROW>
            cij = beta(i)*conj(beta(j));
            coherPairs = [coherPairs; real(cij); imag(cij)]; %#ok<AGROW>
        end
    end

    R1 = abs(mean(exp(1i*th)));
    R2 = abs(mean(exp(2i*th)));
    meanN = mean(n);
    varN = var(n,1);
    maxN = max(n);

    switch lower(featureMode)
        case {'linear_features','linear'}
            x = [real(beta); imag(beta)];

        case {'number_features','number'}
            x = [n; meanN; varN; maxN];

        case {'number_nonlinear','number-nonlinear'}
            x = [n; n.^2; sqrt(n + 1e-12); tanh(n); nPairs; meanN; varN; maxN];

        case {'phase_coherence','phase-coherence'}
            x = [phasePairs; coherPairs; R1; R2];

        case {'all_features','all'}
            % sqrt(n) and tanh(n) add bounded nonlinear observables and improve conditioning.
            x = [real(beta); imag(beta); n; n.^2; sqrt(n + 1e-12); tanh(n); ...
                 nPairs; phasePairs; coherPairs; R1; R2; meanN; varN; maxN];

        otherwise
            error('Unknown featureMode "%s".', featureMode);
    end
end

function [Z, info] = pcaProjectTrainOnly(X, idxTrain, nPC)
    mu = mean(X(idxTrain,:),1);
    sig = std(X(idxTrain,:),0,1);
    sig(sig < 1e-12) = 1;
    XzTrain = (X(idxTrain,:) - mu)./sig;

    % Economy SVD on training data only. V contains feature-space directions.
    [~,S,V] = svd(XzTrain, 'econ');
    nPCeff = min([nPC, size(V,2)]);
    Vpc = V(:,1:nPCeff);
    svals = diag(S);
    svals = svals(1:nPCeff);

    Z = (X - mu)./sig * Vpc;
    info.mu = mu;
    info.sig = sig;
    info.Vpc = Vpc;
    info.singularValues = svals;
end

function variants = evaluateReadoutVariantsFromUnion(Xunion, y, P, cfg, ...
        idxTrain, idxVal, idxTest)
    definitions = cfg.readoutVariants;
    nVariants = numel(definitions);
    variants.label = strings(nVariants,1);
    variants.virtualNodeIdx = cell(nVariants,1);
    variants.tapDelays = cell(nVariants,1);
    variants.nPCRequested = nan(nVariants,1);
    variants.nPCRetained = nan(nVariants,1);
    variants.rawFeatureDim = nan(nVariants,1);
    variants.tappedFeatureDim = nan(nVariants,1);
    variants.valNRMSE = nan(nVariants,1);
    variants.testNRMSE = nan(nVariants,1);
    variants.R2true = nan(nVariants,1);
    variants.R2corr = nan(nVariants,1);
    variants.lambdaBest = nan(nVariants,1);
    variants.readout = cell(nVariants,1);
    variants.pcaInfo = cell(nVariants,1);

    fprintf('\n=== Cached readout variants from union virtual states ===\n');
    for q = 1:nVariants
        definition = definitions(q);
        Xvariant = subsetVirtualFeatureBlocks(Xunion, P, cfg, ...
            definition.virtualNodeIdx);
        [Zvariant, pcaVariant] = pcaProjectTrainOnly( ...
            Xvariant, idxTrain, definition.nPC);
        Xreadout = [ones(cfg.numSamples,1), ...
            addTappedDelays(Zvariant, definition.tapDelays)];
        readout = trainValidateTestReadout(Xreadout, y, idxTrain, idxVal, ...
            idxTest, cfg.lambdaGrid, char(definition.label));

        variants.label(q) = string(definition.label);
        variants.virtualNodeIdx{q} = definition.virtualNodeIdx(:).';
        variants.tapDelays{q} = definition.tapDelays(:).';
        variants.nPCRequested(q) = definition.nPC;
        variants.nPCRetained(q) = size(Zvariant,2);
        variants.rawFeatureDim(q) = size(Xvariant,2);
        variants.tappedFeatureDim(q) = size(Xreadout,2);
        variants.valNRMSE(q) = readout.valNRMSE;
        variants.testNRMSE(q) = readout.NRMSE;
        variants.R2true(q) = readout.R2true;
        variants.R2corr(q) = readout.R2corr;
        variants.lambdaBest(q) = readout.lambdaBest;
        variants.readout{q} = readout;
        variants.pcaInfo{q} = pcaVariant;

        fprintf(['  %s | virtual=%d | taps=%d | PCs=%d | coefficients=%d | ' ...
            'val NRMSE=%.4f | test NRMSE=%.4f\n'], char(variants.label(q)), ...
            numel(definition.virtualNodeIdx), numel(definition.tapDelays), ...
            size(Zvariant,2), size(Xreadout,2), readout.valNRMSE, readout.NRMSE);
    end
end

function Xsubset = subsetVirtualFeatureBlocks(Xunion, P, cfg, requestedNodes)
    unionNodes = cfg.virtualNodeIdx(:).';
    requestedNodes = requestedNodes(:).';
    [found, positions] = ismember(requestedNodes, unionNodes);
    assert(all(found), 'Requested virtual nodes are absent from union cache.');
    localDim = numel(makeLocalFeatures(complex(zeros(P.N,1)), cfg.featureMode));
    blocksPerCopy = numel(unionNodes);
    widthPerCopy = blocksPerCopy*localDim;
    assert(size(Xunion,2) == cfg.numReservoirs*widthPerCopy, ...
        'Union feature width does not match copy/block accounting.');

    selectedColumns = zeros(1, cfg.numReservoirs*numel(requestedNodes)*localDim);
    cursor = 0;
    for r = 1:cfg.numReservoirs
        copyOffset = (r-1)*widthPerCopy;
        for p = positions
            columns = copyOffset + (p-1)*localDim + (1:localDim);
            selectedColumns(cursor+(1:localDim)) = columns;
            cursor = cursor + localDim;
        end
    end
    Xsubset = Xunion(:,selectedColumns);
end

function [result, info] = evaluateReservoirCase(uEnc, yN, Pcase, cfg, idxTrain, idxVal, idxTest, label)
    fprintf('  Case "%s": K = %.4g | J0 = %.4g | featureMode = %s\n', ...
        label, Pcase.K, Pcase.J0, cfg.featureMode);

    [Xvirt, betaFinal] = simulateEnsembleReservoir(uEnc, Pcase, cfg);
    finiteX = all(isfinite(Xvirt(:)));
    finiteB = all(isfinite(betaFinal(:)));
    if ~finiteX || ~finiteB
        error('Non-finite reservoir data in case "%s".', label);
    end

    [result, info] = evaluateFeatureMatrixCase(Xvirt, betaFinal, yN, Pcase, ...
        cfg, idxTrain, idxVal, idxTest, label);
end

function [result, info] = evaluateFeatureMatrixCase(Xvirt, betaFinal, yN, Pcase, ...
        cfg, idxTrain, idxVal, idxTest, label)
    if ~all(isfinite(Xvirt(:))) || ~all(isfinite(betaFinal(:)))
        error('Non-finite cached reservoir data in case "%s".', label);
    end
    [Zvirt, pcaInfoCase] = pcaProjectTrainOnly(Xvirt, idxTrain, cfg.nPC);
    Xcase = [ones(cfg.numSamples,1), addTappedDelays(Zvirt, cfg.tapDelays)];
    result = trainValidateTestReadout(Xcase, yN, idxTrain, idxVal, idxTest, cfg.lambdaGrid, label);

    info.label = label;
    info.K = Pcase.K;
    info.J0 = Pcase.J0;
    info.featureMode = cfg.featureMode;
    info.rawFeatureDim = size(Xvirt,2);
    info.retainedPC = size(Zvirt,2);
    info.tappedFeatureDim = size(Xcase,2);
    info.maxAbsBeta = max(abs(betaFinal(:)));
    info.maxAbsXvirt = max(abs(Xvirt(:)));
    info.anyNaNXvirt = any(isnan(Xvirt(:)));
    info.anyInfXvirt = any(isinf(Xvirt(:)));
    info.anyNaNXcase = any(isnan(Xcase(:)));
    info.anyInfXcase = any(isinf(Xcase(:)));
    info.singularValues = pcaInfoCase.singularValues;
end

function sweep = runKSweepCases(uEnc, yN, P, cfg, idxTrain, idxVal, idxTest)
    fprintf('\n=== Independent K sweep ===\n');
    Klist = cfg.Klist(:);
    nK = numel(Klist);

    sweep.K = Klist;
    sweep.NRMSE = nan(nK,1);
    sweep.valNRMSE = nan(nK,1);
    sweep.R2true = nan(nK,1);
    sweep.R2corr = nan(nK,1);
    sweep.lambdaBest = nan(nK,1);
    sweep.maxAbsBeta = nan(nK,1);
    sweep.maxAbsXvirt = nan(nK,1);
    sweep.caseInfo = cell(nK, 1);
    sweep.readout = cell(nK, 1);

    for q = 1:nK
        Pcase = P;
        Pcase.K = Klist(q);
        label = sprintf('K sweep K=%+.3g', Klist(q));
        [res, info] = evaluateReservoirCase(uEnc, yN, Pcase, cfg, idxTrain, idxVal, idxTest, label);

        sweep.NRMSE(q) = res.NRMSE;
        sweep.valNRMSE(q) = res.valNRMSE;
        sweep.R2true(q) = res.R2true;
        sweep.R2corr(q) = res.R2corr;
        sweep.lambdaBest(q) = res.lambdaBest;
        sweep.maxAbsBeta(q) = info.maxAbsBeta;
        sweep.maxAbsXvirt(q) = info.maxAbsXvirt;
        sweep.caseInfo{q} = info;
        sweep.readout{q} = res;

        fprintf('  K = %+7.3f | val NRMSE = %.4f | test NRMSE = %.4f | R2 = %.4f\n', ...
            Klist(q), res.valNRMSE, res.NRMSE, res.R2true);
    end

    if cfg.evaluateTest
        [sweep.bestNRMSE, bestIdx] = min(sweep.NRMSE);
        sweep.bestValNRMSE = sweep.valNRMSE(bestIdx);
        selectionLabel = 'test';
        selectedMetric = sweep.bestNRMSE;
    else
        [sweep.bestValNRMSE, bestIdx] = min(sweep.valNRMSE);
        sweep.bestNRMSE = NaN;
        selectionLabel = 'validation';
        selectedMetric = sweep.bestValNRMSE;
    end
    sweep.bestK = Klist(bestIdx);
    sweep.selectionMetric = selectionLabel;
    fprintf('Best K in sweep: K = %.4g | %s NRMSE = %.4f\n', ...
        sweep.bestK, selectionLabel, selectedMetric);
end

function sweep = runJSweepCases(uEnc, yN, P, cfg, idxTrain, idxVal, idxTest, main, mainInfo)
    fprintf('\n=== Independent J sweep at fixed K cases ===\n');
    Jlist = cfg.Jlist(:).';
    Kcases = cfg.JSweepKlist(:);
    nJ = numel(Jlist);
    nK = numel(Kcases);

    sweep.J = Jlist;
    sweep.K = Kcases;
    sweep.NRMSE = nan(nK,nJ);
    sweep.valNRMSE = nan(nK,nJ);
    sweep.R2true = nan(nK,nJ);
    sweep.R2corr = nan(nK,nJ);
    sweep.lambdaBest = nan(nK,nJ);
    sweep.maxAbsBeta = nan(nK,nJ);
    sweep.maxAbsXvirt = nan(nK,nJ);
    sweep.NRMSEgainVsJ0 = nan(nK,nJ);
    sweep.relativeGainVsJ0Pct = nan(nK,nJ);
    sweep.caseInfo = cell(nK,nJ);
    sweep.readout = cell(nK,nJ);

    for q = 1:nK
        for m = 1:nJ
            Pcase = P;
            Pcase.K = Kcases(q);
            Pcase.J0 = Jlist(m);
            Pcase.J = Jlist(m)*P.Adj;
            label = sprintf('J sweep K=%+.3g J=%.3g', Kcases(q), Jlist(m));
            matchesMain = abs(Kcases(q)-P.K) < 1e-14 && abs(Jlist(m)-P.J0) < 1e-14;
            if matchesMain
                res = main;
                info = mainInfo;
                info.label = [label ' (reused main case)'];
                fprintf('  Reusing already fitted main physical case for K = %.4g, J = %.4g.\n', ...
                    Kcases(q), Jlist(m));
            else
                [res, info] = evaluateReservoirCase(uEnc, yN, Pcase, cfg, idxTrain, idxVal, idxTest, label);
            end

            sweep.NRMSE(q,m) = res.NRMSE;
            sweep.valNRMSE(q,m) = res.valNRMSE;
            sweep.R2true(q,m) = res.R2true;
            sweep.R2corr(q,m) = res.R2corr;
            sweep.lambdaBest(q,m) = res.lambdaBest;
            sweep.maxAbsBeta(q,m) = info.maxAbsBeta;
            sweep.maxAbsXvirt(q,m) = info.maxAbsXvirt;
            sweep.caseInfo{q,m} = info;
            sweep.readout{q,m} = res;

            fprintf('  K = %+7.3f | J = %.3f | val NRMSE = %.4f | test NRMSE = %.4f | R2 = %.4f\n', ...
                Kcases(q), Jlist(m), res.valNRMSE, res.NRMSE, res.R2true);
        end

        zeroIdx = find(abs(Jlist) < 1e-14, 1);
        if ~isempty(zeroIdx) && cfg.evaluateTest
            reference = sweep.NRMSE(q,zeroIdx);
            sweep.NRMSEgainVsJ0(q,:) = reference - sweep.NRMSE(q,:);
            sweep.relativeGainVsJ0Pct(q,:) = 100*sweep.NRMSEgainVsJ0(q,:)/reference;
        end

        if cfg.evaluateTest
            [sweep.bestNRMSE(q,1), bestIdx] = min(sweep.NRMSE(q,:));
            sweep.bestValNRMSE(q,1) = sweep.valNRMSE(q,bestIdx);
            selectionLabel = 'test';
            selectedMetric = sweep.bestNRMSE(q,1);
        else
            [sweep.bestValNRMSE(q,1), bestIdx] = min(sweep.valNRMSE(q,:));
            sweep.bestNRMSE(q,1) = NaN;
            selectionLabel = 'validation';
            selectedMetric = sweep.bestValNRMSE(q,1);
        end
        sweep.bestJ(q,1) = Jlist(bestIdx);
        sweep.selectionMetric = selectionLabel;
        fprintf('Best J at K = %.4g: J = %.4g | %s NRMSE = %.4f\n', ...
            Kcases(q), sweep.bestJ(q), selectionLabel, selectedMetric);
    end
end

function featureAblation = runFeatureAblationCases(uEnc, yN, P, cfg, ...
        idxTrain, idxVal, idxTest, main, mainInfo, mainStates, betaFinalMain)
    fprintf('\n=== Feature ablations ===\n');
    modes = cfg.featureModes(:).';
    if isempty(cfg.featureCases)
        physicalCases = [P.K, P.J0; 0, P.J0];
    else
        physicalCases = cfg.featureCases;
    end
    nCases = size(physicalCases,1);
    caseLabels = cell(nCases,1);
    for q = 1:nCases
        caseLabels{q} = sprintf('K%+.3g_J%.3g', physicalCases(q,1), physicalCases(q,2));
    end
    nM = numel(modes);

    featureAblation.featureModes = modes;
    featureAblation.physicalCases = physicalCases;
    featureAblation.Kcases = physicalCases(:,1);
    featureAblation.Jcases = physicalCases(:,2);
    featureAblation.caseLabels = caseLabels;
    featureAblation.Klabels = caseLabels; % Backward-compatible plotting field.
    featureAblation.NRMSE = nan(nCases,nM);
    featureAblation.valNRMSE = nan(nCases,nM);
    featureAblation.R2true = nan(nCases,nM);
    featureAblation.lambdaBest = nan(nCases,nM);
    featureAblation.rawFeatureDim = nan(nCases,nM);
    featureAblation.readout = cell(nCases,nM);
    featureAblation.caseInfo = cell(nCases,nM);
    featureAblation.budgetVariants = cell(nCases,nM);

    for q = 1:nCases
        Pcase = P;
        Pcase.K = physicalCases(q,1);
        Pcase.J0 = physicalCases(q,2);
        Pcase.J = Pcase.J0*Pcase.Adj;
        matchesMain = abs(Pcase.K - mainInfo.K) < 1e-12 && ...
            abs(Pcase.J0 - mainInfo.J0) < 1e-12;
        if matchesMain
            statesCase = mainStates;
            betaFinalCase = betaFinalMain;
            fprintf('  Reusing main virtual states for %s.\n', caseLabels{q});
        else
            [statesCase, betaFinalCase] = simulateEnsembleVirtualStates(uEnc, Pcase, cfg);
        end

        for m = 1:nM
            cfgCase = cfg;
            cfgCase.featureMode = modes{m};
            if ~isempty(cfg.featureBudgetLambdaMap)
                cfgCase.featureBudgetLambdaVector = reshape( ...
                    cfg.featureBudgetLambdaMap(q,m,:),1,[]);
            end
            label = sprintf('%s/%s', caseLabels{q}, modes{m});
            matchesMainFeature = strcmpi(modes{m}, mainInfo.featureMode);
            XvirtCase = featureMatrixFromVirtualStates(statesCase, P.N, modes{m});
            if matchesMain && matchesMainFeature
                res = main;
                info = mainInfo;
                info.label = [label ' (reused main case)'];
                fprintf('  Reusing fitted main %s result for %s.\n', ...
                    mainInfo.featureMode, caseLabels{q});
            else
                [res, info] = evaluateFeatureMatrixCase(XvirtCase, betaFinalCase, ...
                    yN, Pcase, cfgCase, idxTrain, idxVal, idxTest, label);
            end
            if ~isempty(cfg.featureBudgetVariants)
                featureAblation.budgetVariants{q,m} = ...
                    evaluateFeatureBudgetVariants(XvirtCase,yN,cfgCase, ...
                    idxTrain,idxVal,idxTest,label);
            end
            clear XvirtCase;

            featureAblation.NRMSE(q,m) = res.NRMSE;
            featureAblation.valNRMSE(q,m) = res.valNRMSE;
            featureAblation.R2true(q,m) = res.R2true;
            featureAblation.lambdaBest(q,m) = res.lambdaBest;
            featureAblation.rawFeatureDim(q,m) = info.rawFeatureDim;
            featureAblation.readout{q,m} = res;
            featureAblation.caseInfo{q,m} = info;

            fprintf('  %-14s | %-18s | NRMSE = %.4f | R2 = %.4f | raw dim = %d\n', ...
                caseLabels{q}, modes{m}, res.NRMSE, res.R2true, info.rawFeatureDim);
        end
        clear statesCase betaFinalCase;
    end
end

function variants = evaluateFeatureBudgetVariants(Xvirt,y,cfg,idxTrain, ...
        idxVal,idxTest,caseLabel)
    definitions = cfg.featureBudgetVariants;
    nVariants = numel(definitions);
    maxPC = max([definitions.nPC]);
    [Zmax,pcaInfo] = pcaProjectTrainOnly(Xvirt,idxTrain,maxPC);
    variants.label = strings(nVariants,1);
    variants.tapDelays = cell(nVariants,1);
    variants.nPCRequested = nan(nVariants,1);
    variants.nPCRetained = nan(nVariants,1);
    variants.readoutCoefficients = nan(nVariants,1);
    variants.valNRMSE = nan(nVariants,1);
    variants.testNRMSE = nan(nVariants,1);
    variants.R2true = nan(nVariants,1);
    variants.lambdaBest = nan(nVariants,1);
    variants.readout = cell(nVariants,1);
    variants.singularValues = pcaInfo.singularValues;
    for q = 1:nVariants
        definition = definitions(q);
        nRetained = min(definition.nPC,size(Zmax,2));
        Xreadout = [ones(cfg.numSamples,1), ...
            addTappedDelays(Zmax(:,1:nRetained),definition.tapDelays)];
        lambdaGrid = cfg.lambdaGrid;
        if isfield(definition,'lambdaGrid') && ~isempty(definition.lambdaGrid)
            lambdaGrid = definition.lambdaGrid;
        end
        if isfield(cfg,'featureBudgetLambdaVector')
            lambdaGrid = cfg.featureBudgetLambdaVector(q);
        end
        label = sprintf('%s/%s',caseLabel,char(string(definition.label)));
        readout = trainValidateTestReadout(Xreadout,y,idxTrain,idxVal, ...
            idxTest,lambdaGrid,label);
        variants.label(q) = string(definition.label);
        variants.tapDelays{q} = definition.tapDelays(:).';
        variants.nPCRequested(q) = definition.nPC;
        variants.nPCRetained(q) = nRetained;
        variants.readoutCoefficients(q) = size(Xreadout,2);
        variants.valNRMSE(q) = readout.valNRMSE;
        variants.testNRMSE(q) = readout.NRMSE;
        variants.R2true(q) = readout.R2true;
        variants.lambdaBest(q) = readout.lambdaBest;
        variants.readout{q} = readout;
    end
end

function plotKSweepSummary(sweep, cfg)
    fig = figure('Color','w','Name','K sweep summary');
    set(fig,'Units','inches','Position',[1 1 7.2 4.8]);
    tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

    nexttile; box on; hold on;
    plot(sweep.K, sweep.NRMSE, 'o-', 'LineWidth', 1.2);
    xlabel('$K$','Interpreter','latex');
    ylabel('test NRMSE','Interpreter','latex');
    title('(a) Test error','Interpreter','latex');
    set(gca,'FontSize',11,'TickLabelInterpreter','latex');

    nexttile; box on; hold on;
    plot(sweep.K, sweep.valNRMSE, 'o-', 'LineWidth', 1.2);
    xlabel('$K$','Interpreter','latex');
    ylabel('validation NRMSE','Interpreter','latex');
    title('(b) Validation error','Interpreter','latex');
    set(gca,'FontSize',11,'TickLabelInterpreter','latex');

    nexttile; box on; hold on;
    plot(sweep.K, sweep.R2true, 'o-', 'LineWidth', 1.2);
    xlabel('$K$','Interpreter','latex');
    ylabel('true test $R^2$','Interpreter','latex');
    title('(c) Explained variance','Interpreter','latex');
    set(gca,'FontSize',11,'TickLabelInterpreter','latex');

    nexttile; box on; hold on;
    plot(sweep.K, sweep.maxAbsBeta, 'o-', 'LineWidth', 1.2);
    xlabel('$K$','Interpreter','latex');
    ylabel('max $|\beta|$','Interpreter','latex');
    title('(d) Stability diagnostic','Interpreter','latex');
    set(gca,'FontSize',11,'TickLabelInterpreter','latex');

    exportgraphics(fig, [cfg.outputPrefix '_KSweep.pdf'], 'ContentType','vector');
    exportgraphics(fig, [cfg.outputPrefix '_KSweep.png'], 'Resolution', 300);
end

function plotJSweepSummary(sweep, cfg)
    fig = figure('Color','w','Name','J sweep summary');
    set(fig,'Units','inches','Position',[1 1 7.2 4.8]);
    tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

    nexttile; box on; hold on;
    for q = 1:numel(sweep.K)
        plot(sweep.J, sweep.NRMSE(q,:), 'o-', 'LineWidth', 1.2, ...
            'DisplayName', sprintf('$K=%+.3g$', sweep.K(q)));
    end
    xlabel('$J_0$','Interpreter','latex');
    ylabel('test NRMSE','Interpreter','latex');
    title('(a) Coupling sweep','Interpreter','latex');
    legend('Interpreter','latex','Location','best');
    set(gca,'FontSize',11,'TickLabelInterpreter','latex');

    nexttile; box on; hold on;
    for q = 1:numel(sweep.K)
        plot(sweep.J, sweep.valNRMSE(q,:), 'o-', 'LineWidth', 1.2, ...
            'DisplayName', sprintf('$K=%+.3g$', sweep.K(q)));
    end
    xlabel('$J_0$','Interpreter','latex');
    ylabel('validation NRMSE','Interpreter','latex');
    title('(b) Validation error','Interpreter','latex');
    legend('Interpreter','latex','Location','best');
    set(gca,'FontSize',11,'TickLabelInterpreter','latex');

    nexttile; box on; hold on;
    for q = 1:numel(sweep.K)
        plot(sweep.J, sweep.R2true(q,:), 'o-', 'LineWidth', 1.2, ...
            'DisplayName', sprintf('$K=%+.3g$', sweep.K(q)));
    end
    xlabel('$J_0$','Interpreter','latex');
    ylabel('true test $R^2$','Interpreter','latex');
    title('(c) Explained variance','Interpreter','latex');
    legend('Interpreter','latex','Location','best');
    set(gca,'FontSize',11,'TickLabelInterpreter','latex');

    nexttile; box on; hold on;
    for q = 1:numel(sweep.K)
        plot(sweep.J, sweep.relativeGainVsJ0Pct(q,:), 'o-', 'LineWidth', 1.2, ...
            'DisplayName', sprintf('$K=%+.3g$', sweep.K(q)));
    end
    yline(0, 'k:');
    xlabel('$J_0$','Interpreter','latex');
    ylabel('NRMSE gain vs. $J=0$ (\%)','Interpreter','latex');
    title('(d) Benefit of coherent coupling','Interpreter','latex');
    legend('Interpreter','latex','Location','best');
    set(gca,'FontSize',11,'TickLabelInterpreter','latex');

    exportgraphics(fig, [cfg.outputPrefix '_JSweep.pdf'], 'ContentType','vector');
    exportgraphics(fig, [cfg.outputPrefix '_JSweep.png'], 'Resolution', 300);
end

function plotFeatureAblationSummary(featureAblation, cfg)
    fig = figure('Color','w','Name','Feature ablation summary');
    set(fig,'Units','centimeters','Position',[3 3 22 11]);

    vals = featureAblation.NRMSE;
    if isscalar(featureAblation.featureModes)
        bar(vals(:), 'LineWidth', 0.8);
        tickLabels = featureAblation.Klabels;
    else
        bar(vals.', 'LineWidth', 0.8);
        tickLabels = featureAblation.featureModes;
        legend(featureAblation.Klabels, 'Interpreter','none', 'Location','best');
    end
    box on;
    ylabel('test NRMSE','Interpreter','latex');
    set(gca, 'XTick', 1:numel(tickLabels), ...
        'XTickLabel', tickLabels, ...
        'TickLabelInterpreter','none', 'FontSize', 11);
    xtickangle(25);
    title('Feature-block ablation','Interpreter','latex');

    exportgraphics(fig, [cfg.outputPrefix '_FeatureAblations.pdf'], 'ContentType','vector');
    exportgraphics(fig, [cfg.outputPrefix '_FeatureAblations.png'], 'Resolution', 300);
end

function writeKSweepCSV(sweep, filename)
    T = table(sweep.K(:), sweep.valNRMSE(:), sweep.NRMSE(:), sweep.R2true(:), ...
        sweep.R2corr(:), sweep.lambdaBest(:), sweep.maxAbsBeta(:), sweep.maxAbsXvirt(:), ...
        'VariableNames', {'K','valNRMSE','testNRMSE','R2true','R2corr','lambdaBest','maxAbsBeta','maxAbsXvirt'});
    writetable(T, filename);
end

function writeJSweepCSV(sweep, filename)
    nK = numel(sweep.K);
    nJ = numel(sweep.J);
    Kvals = repelem(sweep.K(:), nJ);
    Kvals = Kvals(:);
    Jvals = repmat(sweep.J(:), nK, 1);
    T = table(Kvals, Jvals, reshape(sweep.valNRMSE.',[],1), ...
        reshape(sweep.NRMSE.',[],1), reshape(sweep.R2true.',[],1), ...
        reshape(sweep.R2corr.',[],1), reshape(sweep.lambdaBest.',[],1), ...
        reshape(sweep.maxAbsBeta.',[],1), reshape(sweep.maxAbsXvirt.',[],1), ...
        reshape(sweep.NRMSEgainVsJ0.',[],1), reshape(sweep.relativeGainVsJ0Pct.',[],1), ...
        'VariableNames', {'K','J','valNRMSE','testNRMSE','R2true','R2corr', ...
        'lambdaBest','maxAbsBeta','maxAbsXvirt','NRMSEgainVsJ0','relativeGainVsJ0Pct'});
    writetable(T, filename);
end

function writeFeatureAblationCSV(featureAblation, filename)
    rows = {};
    Kvals = [];
    Jvals = [];
    valNRMSE = [];
    testNRMSE = [];
    R2true = [];
    lambdaBest = [];
    rawFeatureDim = [];

    for q = 1:numel(featureAblation.Kcases)
        for m = 1:numel(featureAblation.featureModes)
            rows{end+1,1} = featureAblation.Klabels{q}; %#ok<AGROW>
            rows{end,2} = featureAblation.featureModes{m};
            Kvals(end+1,1) = featureAblation.Kcases(q); %#ok<AGROW>
            Jvals(end+1,1) = featureAblation.Jcases(q); %#ok<AGROW>
            valNRMSE(end+1,1) = featureAblation.valNRMSE(q,m); %#ok<AGROW>
            testNRMSE(end+1,1) = featureAblation.NRMSE(q,m); %#ok<AGROW>
            R2true(end+1,1) = featureAblation.R2true(q,m); %#ok<AGROW>
            lambdaBest(end+1,1) = featureAblation.lambdaBest(q,m); %#ok<AGROW>
            rawFeatureDim(end+1,1) = featureAblation.rawFeatureDim(q,m); %#ok<AGROW>
        end
    end

    T = table(rows(:,1), rows(:,2), Kvals, Jvals, valNRMSE, testNRMSE, R2true, ...
        lambdaBest, rawFeatureDim, 'VariableNames', {'caseLabel','featureMode','K','J', ...
        'valNRMSE','testNRMSE','R2true','lambdaBest','rawFeatureDim'});
    writetable(T, filename);
end

function writeFeatureBudgetVariantsCSV(featureAblation,filename)
    nCases = numel(featureAblation.Kcases);
    nModes = numel(featureAblation.featureModes);
    nVariants = numel(featureAblation.budgetVariants{1,1}.label);
    nRows = nCases*nModes*nVariants;
    caseLabel = strings(nRows,1);
    featureMode = strings(nRows,1);
    variant = strings(nRows,1);
    K = nan(nRows,1);
    J = nan(nRows,1);
    nPC = nan(nRows,1);
    tapDelays = strings(nRows,1);
    readoutCoefficients = nan(nRows,1);
    valNRMSE = nan(nRows,1);
    testNRMSE = nan(nRows,1);
    R2true = nan(nRows,1);
    lambdaBest = nan(nRows,1);
    cursor = 0;
    for q = 1:nCases
        for m = 1:nModes
            values = featureAblation.budgetVariants{q,m};
            assert(numel(values.label) == nVariants);
            for v = 1:nVariants
                cursor = cursor+1;
                caseLabel(cursor) = featureAblation.caseLabels{q};
                featureMode(cursor) = featureAblation.featureModes{m};
                variant(cursor) = values.label(v);
                K(cursor) = featureAblation.Kcases(q);
                J(cursor) = featureAblation.Jcases(q);
                nPC(cursor) = values.nPCRetained(v);
                tapDelays(cursor) = join(string(values.tapDelays{v}),';');
                readoutCoefficients(cursor) = values.readoutCoefficients(v);
                valNRMSE(cursor) = values.valNRMSE(v);
                testNRMSE(cursor) = values.testNRMSE(v);
                R2true(cursor) = values.R2true(v);
                lambdaBest(cursor) = values.lambdaBest(v);
            end
        end
    end
    assert(cursor == nRows);
    T = table(caseLabel,featureMode,variant,K,J,nPC,tapDelays, ...
        readoutCoefficients,valNRMSE,testNRMSE,R2true,lambdaBest);
    writetable(T,filename);
end

function writeReadoutVariantsCSV(variants, filename)
    nVariants = numel(variants.label);
    virtualNodeIdx = strings(nVariants,1);
    tapDelays = strings(nVariants,1);
    for q = 1:nVariants
        virtualNodeIdx(q) = join(string(variants.virtualNodeIdx{q}), ';');
        tapDelays(q) = join(string(variants.tapDelays{q}), ';');
    end
    T = table(variants.label, virtualNodeIdx, tapDelays, ...
        variants.nPCRequested, variants.nPCRetained, variants.rawFeatureDim, ...
        variants.tappedFeatureDim, variants.valNRMSE, variants.testNRMSE, ...
        variants.R2true, variants.R2corr, variants.lambdaBest, ...
        'VariableNames', {'label','virtualNodeIdx','tapDelays','nPCRequested', ...
        'nPCRetained','rawFeatureDim','readoutCoefficients','valNRMSE', ...
        'testNRMSE','R2true','R2corr','lambdaBest'});
    writetable(T, filename);
end

function Xt = addTappedDelays(X, delays)
    [T,D] = size(X);
    Xt = zeros(T, D*numel(delays));
    for q = 1:numel(delays)
        d = delays(q);
        cols = (q-1)*D + (1:D);
        if d == 0
            Xt(:,cols) = X;
        else
            Xt((d+1):end,cols) = X(1:(end-d),:);
        end
    end
end

function X = makeInputTappedFeatures(u, delays)
    u = u(:);
    T = numel(u);
    X = ones(T, 1 + numel(delays));
    for q = 1:numel(delays)
        d = delays(q);
        if d == 0
            X(:,1+q) = u;
        else
            X((d+1):end,1+q) = u(1:(end-d));
        end
    end
end

function result = trainValidateTestReadout(Xall, y, idxTrain, idxVal, idxTest, lambdaGrid, label)
    [XZ, muX, sigX] = standardizeByTrain(Xall, idxTrain);
    assert(all(isfinite(XZ(:))), ['Non-finite standardized features for ' label]);

    Xtr = XZ(idxTrain,:).';    YtrRaw = y(idxTrain).';
    Xva = XZ(idxVal,:).';      Yva = y(idxVal).';

    yMean = mean(YtrRaw);
    yStd  = std(YtrRaw, 0, 2);
    if yStd < 1e-14, yStd = 1; end
    Ytr = (YtrRaw - yMean)/yStd;
    ridgeBasis = prepareRidgeBasis(Xtr,Ytr);

    valNRMSE = inf(numel(lambdaGrid),1);
    for ell = 1:numel(lambdaGrid)
        try
            W = ridgeFromPreparedBasis(ridgeBasis,lambdaGrid(ell));
            YhatValZ = (W*Xva).';
            YhatVal = yStd*YhatValZ + yMean;
            valNRMSE(ell) = nrmse(Yva(:), YhatVal(:));
        catch
            valNRMSE(ell) = inf;
        end
    end

    [bestVal, bestIdx] = min(valNRMSE);
    if ~isfinite(bestVal)
        error('All validation NRMSE values are Inf/NaN for %s.', label);
    end
    lambdaBest = lambdaGrid(bestIdx);

    result.label = label;
    result.lambdaBest = lambdaBest;
    result.valNRMSE = bestVal;
    result.valCurve = valNRMSE;
    result.muX = muX;
    result.sigX = sigX;

    % Selection mode deliberately supplies an empty test index. Returning
    % NaNs prevents accidental use of held-out metrics in architecture choice.
    if isempty(idxTest)
        result.NRMSE = NaN;
        result.R2corr = NaN;
        result.R2true = NaN;
        result.Yte = zeros(0,1);
        result.Yhat = zeros(0,1);
        return;
    end

    Xte = XZ(idxTest,:).';     Yte = y(idxTest).';

    idxTrainVal = [idxTrain idxVal];
    Xtv = XZ(idxTrainVal,:).'; YtvRaw = y(idxTrainVal).';
    yMeanTV = mean(YtvRaw);
    yStdTV = std(YtvRaw,0,2);
    if yStdTV < 1e-14, yStdTV = 1; end
    Ytv = (YtvRaw - yMeanTV)/yStdTV;

    Wbest = ridgeReadoutStable(Xtv, Ytv, lambdaBest);
    YhatZ = (Wbest*Xte).';
    Yhat = yStdTV*YhatZ + yMeanTV;

    result.NRMSE = nrmse(Yte(:), Yhat(:));
    result.R2corr = squaredCorrelation(Yte(:), Yhat(:));
    result.R2true = 1 - sum((Yte(:)-Yhat(:)).^2)/sum((Yte(:)-mean(Yte(:))).^2);
    result.Yte = Yte(:);
    result.Yhat = Yhat(:);
end

function [XZ, muX, sigX] = standardizeByTrain(X, idxTrain)
    muX = mean(X(idxTrain,:),1);
    sigX = std(X(idxTrain,:),0,1);
    sigX(sigX < 1e-12) = 1;
    XZ = (X - muX)./sigX;
    XZ(:,1) = 1; % explicit bias, if present
end

function prepared = prepareRidgeBasis(X,Y)
    [D,M] = size(X);
    prepared.X = X;
    if D >= M
        gram = X.'*X;
        gram = 0.5*(gram+gram.');
        [prepared.basis,eigenvalues] = eig(gram,'vector');
        prepared.eigenvalues = max(real(eigenvalues),0);
        prepared.projectedTarget = prepared.basis.'*Y.';
        prepared.dual = true;
    else
        gram = X*X.';
        gram = 0.5*(gram+gram.');
        [prepared.basis,eigenvalues] = eig(gram,'vector');
        prepared.eigenvalues = max(real(eigenvalues),0);
        prepared.projectedTarget = prepared.basis.'*(X*Y.');
        prepared.dual = false;
    end
end

function W = ridgeFromPreparedBasis(prepared,lambda)
    coefficients = prepared.projectedTarget./(prepared.eigenvalues+lambda);
    solved = prepared.basis*coefficients;
    if prepared.dual
        W = solved.'*prepared.X.';
    else
        W = solved.';
    end
end

function W = ridgeReadoutStable(X, Y, lambda)
    % X: features x samples; Y: outputs x samples.
    % Uses dual form when features >= samples.
    [D, M] = size(X);
    if D >= M
        G = X' * X;
        A = G + lambda * eye(M, 'like', G);
        B = Y.';
        C = solveSPD(A, B);
        W = C.' * X.';
    else
        G = X * X.';
        A = G + lambda * eye(D, 'like', G);
        B = X * Y.';
        C = solveSPD(A, B);
        W = C.';
    end
end

function C = solveSPD(A, B)
    A = 0.5*(A + A.');
    [R,p] = chol(A, 'lower');
    if p == 0
        C = R' \ (R \ B);
    else
        C = A \ B;
    end
end

function e = nrmse(y, yhat)
    y = y(:); yhat = yhat(:);
    if any(~isfinite(yhat)) || any(~isfinite(y))
        e = inf; return;
    end
    vy = var(y,1);
    if vy < 1e-15
        e = inf; return;
    end
    e = sqrt(mean((y-yhat).^2)/vy);
end

function c2 = squaredCorrelation(y, yhat)
    y = y(:); yhat = yhat(:);
    if any(~isfinite(y)) || any(~isfinite(yhat))
        c2 = NaN; return;
    end
    y = y - mean(y); yhat = yhat - mean(yhat);
    denom = (sum(y.^2)*sum(yhat.^2));
    if denom < 1e-15
        c2 = 0;
    else
        c2 = (sum(y.*yhat)^2)/denom;
    end
end
