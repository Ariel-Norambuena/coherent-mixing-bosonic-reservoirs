%% Audit the frozen NARMA10/ESN protocol before the major revision.
% This script reads generated MAT artifacts. It does not run a reservoir or
% alter any scientific result.

clear; clc;

scriptDir = fileparts(mfilename('fullpath'));
bosonicFile = fullfile(scriptDir, ...
    'Fig3_KerrReservoir_NARMA10_Reproducible_CompactFeaturesSeed01_20260806_summary.mat');
esnFile = fullfile(scriptDir, 'Fig3_ESN_NARMA10_Full_20260806_summary.mat');

assert(isfile(bosonicFile), 'Missing frozen bosonic summary: %s', bosonicFile);
assert(isfile(esnFile), 'Missing frozen ESN summary: %s', esnFile);

B = load(bosonicFile, 'cfg', 'P', 'datasetSeed');
E = load(esnFile, 'cfg', 'bestConfig');

nDelayBlocks = numel(B.cfg.tapDelays);
bosonicCoefficients = 1 + B.cfg.nPC*nDelayBlocks;
esnCoefficients = 1 + E.cfg.nUnits;
startIdx = B.cfg.washout + max([20, B.cfg.tapDelays]) + 1;
trainEnd = startIdx + B.cfg.numTrain - 1;
valEnd = trainEnd + B.cfg.numVal;
testEnd = valEnd + B.cfg.numTest;
symbolTime = B.cfg.dt*B.cfg.stepsPerSample;

assert(B.cfg.nPC == 350, 'Frozen bosonic PC count changed unexpectedly.');
assert(nDelayBlocks == 13, 'Frozen delay-block count changed unexpectedly.');
assert(bosonicCoefficients == 4551, 'Unexpected bosonic coefficient count.');
assert(E.cfg.nUnits == 350 && esnCoefficients == 351, ...
    'Unexpected ESN coefficient count.');
assert(testEnd <= B.cfg.numSamples, 'Frozen split exceeds the dataset.');

quantity = [
    "physical_modes_per_copy"
    "reservoir_copies"
    "total_physical_modes"
    "virtual_samples_per_symbol"
    "mask_updates_per_symbol"
    "normalized_symbol_time"
    "retained_pcs"
    "delay_blocks"
    "bosonic_readout_coefficients"
    "esn_states"
    "esn_readout_coefficients"
    "coefficient_ratio_bosonic_to_esn"
    "train_samples"
    "validation_samples"
    "test_samples"
    "train_start_index"
    "train_end_index"
    "validation_start_index"
    "validation_end_index"
    "test_start_index"
    "test_end_index"
    "dataset_seed"
    ];

value = [
    B.P.N
    B.cfg.numReservoirs
    B.P.N*B.cfg.numReservoirs
    B.cfg.numVirtual
    B.cfg.stepsPerSample
    symbolTime
    B.cfg.nPC
    nDelayBlocks
    bosonicCoefficients
    E.cfg.nUnits
    esnCoefficients
    bosonicCoefficients/esnCoefficients
    B.cfg.numTrain
    B.cfg.numVal
    B.cfg.numTest
    startIdx
    trainEnd
    trainEnd + 1
    valEnd
    valEnd + 1
    testEnd
    B.datasetSeed
    ];

unit = [
    "modes"
    "copies"
    "modes"
    "samples/symbol"
    "integration steps/symbol"
    "normalized time"
    "components"
    "blocks"
    "coefficients including bias"
    "states"
    "coefficients including bias"
    "ratio"
    "samples"
    "samples"
    "samples"
    "index"
    "index"
    "index"
    "index"
    "index"
    "index"
    "seed"
    ];

T = table(quantity, value, unit);
csvFile = fullfile(scriptDir, 'PreReviewProtocolAudit_20260807.csv');
writetable(T, csvFile);

mdFile = fullfile(scriptDir, 'PreReviewProtocolAudit_20260807.md');
fid = fopen(mdFile, 'w');
assert(fid >= 0, 'Could not open audit report for writing.');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Pre-review protocol audit\n\n');
fprintf(fid, 'Status: **PASS** (the frozen implementation was read successfully).\n\n');
fprintf(fid, 'This is an audit of the old protocol, not an endorsement of its statistical design.\n\n');
fprintf(fid, '## Capacity mismatch\n\n');
fprintf(fid, ['The bosonic readout retains %d PCs before %d delay blocks, for %d trained ' ...
    'coefficients including bias. The ESN uses %d states and %d output coefficients. ' ...
    'The old comparison therefore has a %.2fx readout-coefficient mismatch and must ' ...
    'not be called matched by trained capacity.\n\n'], B.cfg.nPC, nDelayBlocks, ...
    bosonicCoefficients, E.cfg.nUnits, esnCoefficients, ...
    bosonicCoefficients/esnCoefficients);
fprintf(fid, '## Frozen split\n\n');
fprintf(fid, ['After washout and the causal-history guard, train is %d--%d, validation ' ...
    'is %d--%d, and test is %d--%d. PCA and standardization are fitted on train, ' ...
    'ridge is selected on validation, and the final readout is refitted on ' ...
    'train+validation. The unresolved leakage is architectural selection from ' ...
    'displayed test sweeps, not the local PCA/ridge implementation.\n\n'], ...
    startIdx, trainEnd, trainEnd+1, valEnd, valEnd+1, testEnd);
fprintf(fid, '## Sampling and resources\n\n');
fprintf(fid, ['The run uses %d physical modes per copy, %d copies, %d integration/mask ' ...
    'steps per symbol, and %d sampled virtual nodes per symbol. The normalized ' ...
    'symbol time is %.6g. These are distinct quantities and must not be conflated ' ...
    'in the physical mapping.\n'], B.P.N, B.cfg.numReservoirs, ...
    B.cfg.stepsPerSample, B.cfg.numVirtual, symbolTime);

fprintf('Pre-review protocol audit PASS.\n');
fprintf('Bosonic coefficients: %d | ESN coefficients: %d | ratio: %.2f\n', ...
    bosonicCoefficients, esnCoefficients, bosonicCoefficients/esnCoefficients);
fprintf('CSV: %s\nReport: %s\n', csvFile, mdFile);
