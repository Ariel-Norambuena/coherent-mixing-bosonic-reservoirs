%% run_full_K_sweep_20260706.m
% Paper-grade independent K sweep for the bosonic Kerr NARMA10 reservoir.
%
% This launcher keeps the full-size default configuration in
% Fig3_KerrReservoir_NARMA10_Reproducible.m, enables the independent K sweep,
% and skips the separate K=0/J=0 physical ablations to avoid duplicate
% simulations. Each K case still fits its own PCA and ridge readout.

clear; clc;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

logFile = fullfile(scriptDir, 'Fig3_KerrReservoir_NARMA10_Reproducible_KSweepFull_20260706_diary.txt');
if exist(logFile, 'file')
    delete(logFile);
end
diary(logFile);

fprintf('Starting full independent K sweep at %s\n', ...
    char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
fprintf('Working directory: %s\n', pwd);
fprintf('Script directory:  %s\n', scriptDir);

KERR_NARMA_RUN_KSWEEP = true;
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS = true;
KERR_NARMA_OUTPUT_TAG = 'KSweepFull_20260706';

run(fullfile(scriptDir, 'Fig3_KerrReservoir_NARMA10_Reproducible.m'));

fprintf('Finished full independent K sweep at %s\n', ...
    char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
diary off;
