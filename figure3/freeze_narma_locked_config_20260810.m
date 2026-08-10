%% Freeze the locked NARMA10 configuration after stage-2 selection.
% This script refuses to overwrite a frozen configuration or proceed if any
% locked-test output already exists.

clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
protocolFile = fullfile(scriptDir, 'configs', ...
    'narma_revision_protocol_20260807.json');
stage2File = fullfile(scriptDir, 'configs', ...
    'narma_selection_stage2_result_20260810.json');
outputFile = fullfile(scriptDir, 'configs', ...
    'narma_locked_config_20260810.json');
checksumFile = [outputFile '.sha256'];
assert(isfile(protocolFile) && isfile(stage2File), ...
    'Stage-2 selection must be complete before freezing locked configuration.');
assert(~isfile(outputFile) && ~isfile(checksumFile), ...
    'Collision guard: locked configuration is already frozen.');
assert(isempty(dir(fullfile(scriptDir, '*LockedTest*'))), ...
    'Locked-test outputs already exist; refusing to refreeze configuration.');

protocol = jsondecode(fileread(protocolFile));
stage2 = jsondecode(fileread(stage2File));
assert(strcmp(stage2.status, 'stage_2_complete'));
assert(~stage2.test_metrics_evaluated);
selected = stage2.selected;
assert(selected.J > 0 && selected.readout_coefficients_including_bias <= ...
    protocol.primary_endpoint.coefficient_budget);

matchingTapSet = [];
tapSets = protocol.selection_stage_2.tap_sets;
if ~iscell(tapSets)
    tapSets = squeeze(num2cell(tapSets,2));
end
for q = 1:numel(tapSets)
    if numel(tapSets{q}) == selected.n_delay_blocks
        matchingTapSet = tapSets{q}(:).';
        break;
    end
end
assert(~isempty(matchingTapSet), 'Selected tap set is absent from protocol.');
virtualNodeIdx = unique(round(linspace(round(0.20*selected.steps_per_sample), ...
    selected.steps_per_sample, selected.virtual_samples)));

locked.schema_version = 1;
locked.status = 'frozen_not_executed';
locked.created_date = '2026-08-10';
locked.source_protocol_sha256 = sha256File(protocolFile);
locked.source_stage2_result_sha256 = sha256File(stage2File);
locked.task = 'NARMA10';
locked.locked_test_offsets = protocol.locked_test_offsets(:).';
locked.paired_realizations = numel(locked.locked_test_offsets);
locked.K = selected.K;
locked.J_control = 0;
locked.J_intervention = selected.J;
locked.input_gain_scale = selected.input_gain_scale;
locked.steps_per_sample = selected.steps_per_sample;
locked.virtual_node_indices = virtualNodeIdx;
locked.tap_delays = matchingTapSet;
locked.n_pc = selected.n_pc;
locked.readout_coefficients_including_bias = ...
    selected.readout_coefficients_including_bias;
locked.ridge_lambda = selected.ridge_lambda;
locked.feature_modes = {'linear_features','number_features'};
locked.primary_feature_mode = 'linear_features';
locked.secondary_feature_mode = 'number_features';
locked.test_metric = 'NRMSE';
locked.bootstrap_resamples = protocol.locked_test_policy.bootstrap_resamples;
locked.minimum_improvement_fraction = ...
    protocol.locked_test_policy.minimum_improvement_fraction;
locked.execution_policy = 'execute each offset once; never tune from locked outputs';
locked.shared_within_pair = protocol.locked_test_policy.shared_within_pair;

fid = fopen(outputFile, 'w');
assert(fid >= 0, 'Could not create locked configuration.');
fprintf(fid, '%s\n', jsonencode(locked, PrettyPrint=true));
fclose(fid);
configHash = sha256File(outputFile);
fid = fopen(checksumFile, 'w');
assert(fid >= 0, 'Could not create locked checksum file.');
fprintf(fid, '%s  %s\n', configHash, 'narma_locked_config_20260810.json');
fclose(fid);

auditFile = fullfile(scriptDir, 'NARMALockedConfigAudit_20260810.md');
fid = fopen(auditFile, 'w');
assert(fid >= 0, 'Could not create locked configuration audit.');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Frozen NARMA10 locked configuration\n\n');
fprintf(fid, 'Status: **FROZEN, NOT EXECUTED**\n\n');
fprintf(fid, '- Configuration SHA-256: `%s`.\n', configHash);
fprintf(fid, '- Locked paired realizations: `%d`.\n', locked.paired_realizations);
fprintf(fid, '- Physical pair: `K=%g`, `J=0` versus `J=%g`.\n', ...
    locked.K, locked.J_intervention);
fprintf(fid, '- Input gain: `%g`; steps per sample: `%d`.\n', ...
    locked.input_gain_scale, locked.steps_per_sample);
fprintf(fid, '- Virtual nodes: `%s`.\n', join(string(virtualNodeIdx), ', '));
fprintf(fid, '- Tap delays: `%s`.\n', join(string(matchingTapSet), ', '));
fprintf(fid, '- PCs: `%d`; coefficients including bias: `%d`.\n', ...
    locked.n_pc, locked.readout_coefficients_including_bias);
fprintf(fid, '- Fixed ridge lambda: `%.12g`.\n', locked.ridge_lambda);
fprintf(fid, '- Primary readout: quadratures; secondary: number statistics.\n');
fprintf(fid, '- Locked outputs present when frozen: `0`.\n');

fprintf('Locked NARMA10 configuration frozen.\n');
fprintf('SHA-256: %s\n', configHash);

function digest = sha256File(path)
    engine = java.security.MessageDigest.getInstance('SHA-256');
    bytes = typecast(engine.digest(uint8(fileread(path))), 'uint8');
    digest = lower(reshape(dec2hex(bytes,2).',1,[]));
end
