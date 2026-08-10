function run_all(mode)
%RUN_ALL Regenerate final analysis artifacts from archived compact results.

if nargin == 0
    mode = "analysis";
end
mode = string(validatestring(string(mode), ...
    ["analysis", "verify", "full_audit"]));

rootDir = fileparts(mfilename('fullpath'));
figureDir = fullfile(rootDir, 'Figure 3');
if ~isfolder(figureDir)
    figureDir = fullfile(rootDir, 'figure3');
end
assert(isfolder(figureDir), 'Could not locate the Figure 3 source directory.');
oldDir = pwd;
cleanup = onCleanup(@() cd(oldDir));
cd(figureDir);
addpath(figureDir);

analysisScripts = {
    'verify_k0_contraction_20260810.m'
    'generate_figure1_architecture_mechanism_20260810.m'
    'generate_figure2_selection_capacity_20260810.m'
    'plot_narma_locked_pairs_from_tables_20260810.m'
    'plot_narma_mechanism_from_tables_20260810.m'
    'plot_narma_fair_comparison_from_tables_20260810.m'
    'plot_narma_robustness_from_tables_20260810.m'
    };

for idx = 1:numel(analysisScripts)
    fprintf('[%02d/%02d] %s\n', idx, numel(analysisScripts), analysisScripts{idx});
    evalin('base', sprintf("run('%s')", analysisScripts{idx}));
end

if mode == "verify" || mode == "full_audit"
    fprintf('[compact check] test_compact_release_20260810\n');
    evalin('base', 'test_compact_release_20260810');
end

if mode == "full_audit"
    fullAuditScripts = {
        'analyze_narma_selection_stage1_20260807.m'
        'analyze_narma_selection_stability_20260809.m'
        'analyze_narma_selection_stage2_20260810.m'
        'analyze_narma_locked_pairs_20260810.m'
        'analyze_narma_baseline_locked_20260810.m'
        'analyze_narma_fair_comparison_20260810.m'
        'analyze_narma_mechanism_ablation_20260810.m'
        'analyze_narma_processing_capacity_20260810.m'
        'analyze_narma_measurement_robustness_20260810.m'
        'analyze_narma_solver_convergence_20260810.m'
        'analyze_narma_determinism_20260810.m'
        'generate_hardware_mapping_20260810.m'
        };
    for idx = 1:numel(fullAuditScripts)
        fprintf('[audit %02d/%02d] %s\n',idx,numel(fullAuditScripts), ...
            fullAuditScripts{idx});
        evalin('base',sprintf("run('%s')",fullAuditScripts{idx}));
    end
    checks = {
        'test_selection_no_leakage_20260807'
        'test_narma_alignment_split_metrics_20260808'
        'test_stage2_cached_direct_equivalence_20260810'
        };
    for idx = 1:numel(checks)
        fprintf('[check %d/%d] %s\n', idx, numel(checks), checks{idx});
        evalin('base', checks{idx});
    end
end

requiredOutputs = {
    'NARMALockedPairs_Statistics_20260810.csv'
    'NARMAFairComparison_20260810.pdf'
    'NARMAMechanismAblation_Summary_20260810.csv'
    'NARMAProcessingCapacity_Summary_20260810.csv'
    'NARMAMeasurementRobustness_Summary_20260810.csv'
    'HardwareResourceBudget_20260810.csv'
    'Figure1_ArchitectureMechanism_20260810.pdf'
    'Figure2_SelectionCapacity_20260810.pdf'
    };
missing = requiredOutputs(~cellfun(@isfile, requiredOutputs));
assert(isempty(missing), 'Missing expected output(s): %s', strjoin(missing, ', '));
fprintf('Reproduction %s completed: %d required outputs found.\n', mode, numel(requiredOutputs));
end
