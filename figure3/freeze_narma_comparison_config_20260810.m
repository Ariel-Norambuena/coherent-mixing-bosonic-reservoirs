%% Freeze every physical and classical comparison choice before locked test.

clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
configDir = fullfile(scriptDir,'configs');
architectureFile = fullfile(configDir,'narma_locked_config_20260810.json');
physicalFile = fullfile(configDir,'narma_physical_budget_selected_20260810.json');
esnFile = fullfile(configDir,'narma_esn_selected_20260810.json');
baselineFile = fullfile(configDir,'narma_baseline_budget_selected_20260810.json');
outputFile = fullfile(configDir,'narma_locked_comparison_config_20260810.json');
checksumFile = [outputFile '.sha256'];
assert(all(isfile({architectureFile,physicalFile,esnFile,baselineFile})), ...
    'Every validation-selected component must exist before comparison freeze.');
assert(~isfile(outputFile) && ~isfile(checksumFile), ...
    'Collision guard: comparison configuration is already frozen.');
assert(isempty(dir(fullfile(scriptDir,'*LockedTest*'))), ...
    'Locked-test outputs exist; refusing to freeze after test exposure.');

architecture = jsondecode(fileread(architectureFile));
physical = jsondecode(fileread(physicalFile));
esn = jsondecode(fileread(esnFile));
baseline = jsondecode(fileread(baselineFile));
assert(strcmp(architecture.status,'frozen_not_executed'));
assert(~physical.test_metrics_evaluated && ~esn.test_metrics_evaluated && ...
    ~baseline.test_metrics_evaluated);

comparison.schema_version = 1;
comparison.status = 'frozen_not_executed';
comparison.created_date = '2026-08-10';
comparison.execution_policy = ...
    'all validation choices frozen before first access to offsets 1001--1030';
comparison.locked_test_offsets = architecture.locked_test_offsets;
comparison.architecture_config_sha256 = sha256File(architectureFile);
comparison.physical_budget_config_sha256 = sha256File(physicalFile);
comparison.esn_config_sha256 = sha256File(esnFile);
comparison.classical_budget_config_sha256 = sha256File(baselineFile);
comparison.architecture = architecture;
comparison.physical_models = physical.models;
comparison.esn_hyperparameters = esn;
comparison.classical_models = baseline.models;
comparison.primary_endpoint.feature_mode = 'linear_features';
comparison.primary_endpoint.requested_budget = 351;
comparison.primary_endpoint.metric = ...
    'paired test NRMSE difference J=0 minus J=0.65 across 30 offsets';
comparison.secondary_endpoint.feature_mode = 'number_features';
comparison.secondary_endpoint.requested_budget = 351;
comparison.multiple_comparison_policy = ...
    'primary endpoint confirmatory; other budgets and intensity endpoint descriptive';

fid = fopen(outputFile,'w');assert(fid >= 0);
fprintf(fid,'%s\n',jsonencode(comparison,PrettyPrint=true));fclose(fid);
configHash = sha256File(outputFile);
fid = fopen(checksumFile,'w');assert(fid >= 0);
fprintf(fid,'%s  narma_locked_comparison_config_20260810.json\n',configHash);
fclose(fid);

auditFile = fullfile(scriptDir,'NARMALockedComparisonConfigAudit_20260810.md');
fid = fopen(auditFile,'w');assert(fid >= 0);cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'# Frozen NARMA10 comparison configuration\n\n');
fprintf(fid,'Status: **FROZEN, NOT EXECUTED**\n\n');
fprintf(fid,'- Comparison SHA-256: `%s`.\n',configHash);
fprintf(fid,'- Architecture SHA-256: `%s`.\n',comparison.architecture_config_sha256);
fprintf(fid,'- Physical budget SHA-256: `%s`.\n',comparison.physical_budget_config_sha256);
fprintf(fid,'- ESN SHA-256: `%s`.\n',comparison.esn_config_sha256);
fprintf(fid,'- Classical budget SHA-256: `%s`.\n',comparison.classical_budget_config_sha256);
fprintf(fid,'- Physical models: `%d`; classical models: `%d`.\n', ...
    numel(comparison.physical_models),numel(comparison.classical_models));
fprintf(fid,'- Locked outputs present at freeze: `0`.\n');
fprintf('COMPARISON_CONFIG_FROZEN %s\n',configHash);

function digest = sha256File(path)
    engine=java.security.MessageDigest.getInstance('SHA-256');
    bytes=typecast(engine.digest(uint8(fileread(path))),'uint8');
    digest=lower(reshape(dec2hex(bytes,2).',1,[]));
end
