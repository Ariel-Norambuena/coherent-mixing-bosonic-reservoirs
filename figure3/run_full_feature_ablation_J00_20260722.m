%% run_full_feature_ablation_J00_20260722.m
% Paper-grade observable-block ablation for the uncoupled linear reservoir.

clear; clc;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

logFile = fullfile(scriptDir, ...
    'Fig3_KerrReservoir_NARMA10_FeatureAblationK0J00Full_20260722_diary.txt');
if exist(logFile, 'file')
    delete(logFile);
end
diary(logFile);

fprintf('Starting full K=0, J=0 feature ablation at %s\n', ...
    char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
fprintf('Working directory: %s\n', pwd);
fprintf('Script directory:  %s\n', scriptDir);

KERR_NARMA_RUN_FEATURE_ABLATIONS = true;
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS = true;
KERR_NARMA_BASE_K = 0;
KERR_NARMA_BASE_J = 0;
KERR_NARMA_FEATURE_CASES = [0, 0];
KERR_NARMA_OUTPUT_TAG = 'FeatureAblationK0J00Full_20260722';

run(fullfile(scriptDir, 'Fig3_KerrReservoir_NARMA10_Reproducible.m'));

fprintf('Finished full K=0, J=0 feature ablation at %s\n', ...
    char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
diary off;
