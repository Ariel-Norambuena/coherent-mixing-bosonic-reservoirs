%% Build and audit the cached stage-2 NARMA10 selection plan.
% This script performs no reservoir simulation and never touches locked seeds.

clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
protocolFile = fullfile(scriptDir, 'configs', ...
    'narma_revision_protocol_20260807.json');
stage1File = fullfile(scriptDir, 'configs', ...
    'narma_selection_stage1_result_20260807.json');
assert(isfile(protocolFile) && isfile(stage1File));
protocol = jsondecode(fileread(protocolFile));
stage1 = jsondecode(fileread(stage1File));
assert(strcmp(stage1.status, 'stage_1_complete'));
assert(~stage1.test_metrics_evaluated);

offsets = protocol.selection_offsets(:);
lockedOffsets = protocol.locked_test_offsets(:);
physical = stage1.stage_2_candidates(:);
inputGains = protocol.selection_stage_2.input_gain_scales(:);
stepCounts = protocol.selection_stage_2.steps_per_sample(:);
virtualCounts = protocol.selection_stage_2.virtual_samples(:);
tapSets = protocol.selection_stage_2.tap_sets;
if ~iscell(tapSets)
    tapSets = squeeze(num2cell(tapSets,2));
end

nSeeds = numel(offsets);
nPhysical = numel(physical);
nGains = numel(inputGains);
nSteps = numel(stepCounts);
nVirtual = numel(virtualCounts);
nTapSets = numel(tapSets);
nTrajectories = nSeeds*nPhysical*nGains*nSteps;
nReadouts = nTrajectories*nVirtual*nTapSets;

selectionIndex = nan(nTrajectories,1);
seedOffset = nan(nTrajectories,1);
K = nan(nTrajectories,1);
J = nan(nTrajectories,1);
inputGainScale = nan(nTrajectories,1);
stepsPerSample = nan(nTrajectories,1);
unionVirtualCount = nan(nTrajectories,1);
unionVirtualNodeIdx = strings(nTrajectories,1);
estimatedStateCacheMiB = nan(nTrajectories,1);
trajectoryId = (1:nTrajectories).';

N = 12;
nCopies = 3;
nSamples = 22000;
complexDoubleBytes = 16;
row = 0;
for s = 1:nSeeds
    for p = 1:nPhysical
        for g = 1:nGains
            for h = 1:nSteps
                row = row + 1;
                steps = stepCounts(h);
                unionIdx = [];
                for v = 1:nVirtual
                    idx = unique(round(linspace(round(0.20*steps), ...
                        steps, virtualCounts(v))));
                    unionIdx = union(unionIdx, idx, 'stable');
                end
                selectionIndex(row) = s;
                seedOffset(row) = offsets(s);
                K(row) = physical(p).K;
                J(row) = physical(p).J;
                inputGainScale(row) = inputGains(g);
                stepsPerSample(row) = steps;
                unionVirtualCount(row) = numel(unionIdx);
                unionVirtualNodeIdx(row) = join(string(unionIdx), ';');
                estimatedStateCacheMiB(row) = ...
                    nSamples*numel(unionIdx)*N*nCopies*complexDoubleBytes/2^20;
            end
        end
    end
end
assert(row == nTrajectories);
assert(isempty(intersect(unique(seedOffset), lockedOffsets)));
assert(all(estimatedStateCacheMiB < 256));

trajectoryTable = table(trajectoryId, selectionIndex, seedOffset, K, J, ...
    inputGainScale, stepsPerSample, unionVirtualCount, unionVirtualNodeIdx, ...
    estimatedStateCacheMiB);
trajectoryFile = fullfile(scriptDir, ...
    'NARMASelectionStage2_TrajectoryPlan_20260810.csv');
writetable(trajectoryTable, trajectoryFile);

readoutId = (1:nReadouts).';
readoutTrajectoryId = nan(nReadouts,1);
requestedVirtualSamples = nan(nReadouts,1);
actualVirtualSamples = nan(nReadouts,1);
virtualNodeIdx = strings(nReadouts,1);
tapSetIndex = nan(nReadouts,1);
tapDelays = strings(nReadouts,1);
nDelayBlocks = nan(nReadouts,1);
nPC = nan(nReadouts,1);
actualCoefficientsIncludingBias = nan(nReadouts,1);
rawQuadratureDimension = nan(nReadouts,1);

budget = protocol.primary_endpoint.coefficient_budget;
row = 0;
for t = 1:nTrajectories
    steps = stepsPerSample(t);
    for v = 1:nVirtual
        idx = unique(round(linspace(round(0.20*steps), ...
            steps, virtualCounts(v))));
        for d = 1:nTapSets
            row = row + 1;
            taps = tapSets{d}(:).';
            blocks = numel(taps);
            retainedPC = floor((budget-1)/blocks);
            coefficients = 1 + retainedPC*blocks;
            rawDimension = 2*N*nCopies*numel(idx);
            assert(coefficients <= budget && retainedPC <= rawDimension);
            readoutTrajectoryId(row) = t;
            requestedVirtualSamples(row) = virtualCounts(v);
            actualVirtualSamples(row) = numel(idx);
            virtualNodeIdx(row) = join(string(idx), ';');
            tapSetIndex(row) = d;
            tapDelays(row) = join(string(taps), ';');
            nDelayBlocks(row) = blocks;
            nPC(row) = retainedPC;
            actualCoefficientsIncludingBias(row) = coefficients;
            rawQuadratureDimension(row) = rawDimension;
        end
    end
end
assert(row == nReadouts);

readoutTable = table(readoutId, readoutTrajectoryId, ...
    requestedVirtualSamples, actualVirtualSamples, virtualNodeIdx, ...
    tapSetIndex, tapDelays, nDelayBlocks, nPC, ...
    actualCoefficientsIncludingBias, rawQuadratureDimension);
readoutFile = fullfile(scriptDir, ...
    'NARMASelectionStage2_ReadoutPlan_20260810.csv');
writetable(readoutTable, readoutFile);

naiveTrajectoryCount = nReadouts;
simulationReductionFraction = 1-nTrajectories/naiveTrajectoryCount;
assert(abs(simulationReductionFraction-0.75) < 1e-14);
assert(all(actualCoefficientsIncludingBias <= budget));
assert(all(ismember(unique(seedOffset), offsets)));

mdFile = fullfile(scriptDir, 'NARMASelectionStage2_PlanAudit_20260810.md');
fid = fopen(mdFile, 'w');
assert(fid >= 0, 'Could not open stage-2 plan report.');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Cached NARMA10 stage-2 selection plan\n\n');
fprintf(fid, 'Status: **PASS**\n\n');
fprintf(fid, '- Selection seeds: `%d`; locked seeds used: `0`.\n', nSeeds);
fprintf(fid, '- Retained physical points: `%d`.\n', nPhysical);
for p = 1:nPhysical
    fprintf(fid, '  - `K=%g`, `J=%g`.\n', physical(p).K, physical(p).J);
end
fprintf(fid, '- Input-gain values: `%d`; integration-step values: `%d`.\n', ...
    nGains, nSteps);
fprintf(fid, '- Required reservoir trajectories: `%d`.\n', nTrajectories);
fprintf(fid, '- Validation-only readout fits: `%d`.\n', nReadouts);
fprintf(fid, ['- In-memory trajectory reuse reduces simulations from `%d` to `%d` ' ...
    '(`%.0f%%` reduction).\n'], naiveTrajectoryCount, nTrajectories, ...
    100*simulationReductionFraction);
fprintf(fid, ['- Per-trajectory union-state cache: `%.1f--%.1f MiB`; caches are ' ...
    'processed one at a time and are not written as large result files.\n'], ...
    min(estimatedStateCacheMiB), max(estimatedStateCacheMiB));
fprintf(fid, '- Readout budget: at most `%d` coefficients including bias.\n', budget);
fprintf(fid, ['- The 11-block tap set uses `%d` PCs and `%d` coefficients; the ' ...
    '13-block set uses `%d` PCs and `%d` coefficients.\n'], ...
    max(nPC(nDelayBlocks==11)), max(actualCoefficientsIncludingBias(nDelayBlocks==11)), ...
    max(nPC(nDelayBlocks==13)), max(actualCoefficientsIncludingBias(nDelayBlocks==13)));
fprintf(fid, ['\nThe implementation must simulate each trajectory once at the union ' ...
    'of requested virtual-node indices, derive both virtual-node subsets from ' ...
    'that state cache, and fit both tap sets using training/validation only.\n']);

fprintf('Stage-2 cached-grid plan PASS: %d trajectories, %d readouts.\n', ...
    nTrajectories, nReadouts);
fprintf('Locked offsets used: 0 | simulation reduction: %.0f%%.\n', ...
    100*simulationReductionFraction);
