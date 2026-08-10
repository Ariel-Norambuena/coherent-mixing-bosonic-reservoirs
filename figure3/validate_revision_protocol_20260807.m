%% Validate the frozen seed banks and capacity accounting for the revision.

clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
configFile = fullfile(scriptDir, 'configs', ...
    'narma_revision_protocol_20260807.json');
assert(isfile(configFile), 'Missing revision protocol configuration.');

cfg = jsondecode(fileread(configFile));
development = cfg.historical_development_offsets(:);
selection = cfg.selection_offsets(:);
locked = cfg.locked_test_offsets(:);

assert(numel(unique(development)) == numel(development));
assert(numel(unique(selection)) == numel(selection));
assert(numel(unique(locked)) == numel(locked));
assert(isempty(intersect(development, selection)));
assert(isempty(intersect(development, locked)));
assert(isempty(intersect(selection, locked)));
assert(numel(selection) >= 10, 'Selection bank must contain at least 10 offsets.');
assert(numel(locked) >= 30, 'Locked test bank must contain at least 30 offsets.');
assert(~cfg.selection_rule.test_metrics_available, ...
    'Selection configuration must forbid test metrics.');
assert(cfg.locked_test_policy.execute_once_after_frozen_config_hash);

budgets = cfg.budget_curve.budgets(:);
nPC = cfg.budget_curve.n_pc_for_13_delay_blocks(:);
actual = cfg.budget_curve.actual_coefficients_including_bias(:);
calculated = 1 + 13*nPC;
assert(isequal(calculated, actual));
assert(all(actual <= budgets));
assert(all(diff(budgets) > 0) && all(diff(actual) > 0));
assert(cfg.primary_endpoint.actual_coefficients_including_bias == ...
    1 + cfg.primary_endpoint.n_pc*numel(cfg.primary_endpoint.tap_delays));
assert(cfg.primary_endpoint.actual_coefficients_including_bias <= ...
    cfg.primary_endpoint.coefficient_budget);

allOffsets = [development; selection; locked];
datasetSeeds = 132 + 1009*allOffsets;
reservoirSeeds = 22 + 2003*allOffsets;
maskSeeds = 900 + 3001*allOffsets;
copySeeds = 1234 + 4001*allOffsets;
allSeeds = [datasetSeeds; reservoirSeeds; maskSeeds; copySeeds];
assert(all(allSeeds >= 0 & allSeeds <= intmax('uint32')));

digest = java.security.MessageDigest.getInstance('SHA-256');
hashBytes = typecast(digest.digest(uint8(fileread(configFile))), 'uint8');
configHash = lower(reshape(dec2hex(hashBytes, 2).', 1, []));
reportFile = fullfile(scriptDir, 'NARMARevisionProtocolAudit_20260807.md');
fid = fopen(reportFile, 'w');
assert(fid >= 0, 'Could not open protocol audit report.');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# NARMA10 revision protocol audit\n\n');
fprintf(fid, 'Status: **PASS**\n\n');
fprintf(fid, '- Configuration SHA-256: `%s`\n', configHash);
fprintf(fid, '- Development offsets: %d\n', numel(development));
fprintf(fid, '- Selection offsets: %d\n', numel(selection));
fprintf(fid, '- Locked paired-test offsets: %d\n', numel(locked));
fprintf(fid, '- Shared offsets across banks: zero\n');
fprintf(fid, '- Primary budget: %d allowed, %d used coefficients including bias\n', ...
    cfg.primary_endpoint.coefficient_budget, ...
    cfg.primary_endpoint.actual_coefficients_including_bias);
fprintf(fid, '- Selection test metrics enabled: false\n');
fprintf(fid, '- Locked execution policy: one run after final configuration hash\n\n');
fprintf(fid, ['This audit validates the design and seed separation only. The locked ' ...
    'bank remains untouched until selection is complete and a final locked ' ...
    'configuration file is created.\n']);

fprintf('Revision protocol audit PASS.\n');
fprintf('Config SHA-256: %s\n', configHash);
fprintf('Selection offsets: %d | locked offsets: %d\n', ...
    numel(selection), numel(locked));
