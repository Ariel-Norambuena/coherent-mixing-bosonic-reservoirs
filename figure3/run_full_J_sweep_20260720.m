%% run_full_J_sweep_20260720.m
% Paper-grade independent coupling sweep for the bosonic NARMA10 reservoir.
%
% The sweep compares the linear-bosonic point K=0 with the default Kerr point
% K=-1.62. Every (K,J) case uses the same dataset, masks, and disorder seeds,
% while fitting its own PCA projection and ridge readout. J=0 is included as
% the uncoupled reference.

clear; clc;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

logFile = fullfile(scriptDir, ...
    'Fig3_KerrReservoir_NARMA10_Reproducible_JSweepFull_20260720_diary.txt');
if exist(logFile, 'file')
    delete(logFile);
end
diary(logFile);

fprintf('Starting full independent J sweep at %s\n', ...
    char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
fprintf('Working directory: %s\n', pwd);
fprintf('Script directory:  %s\n', scriptDir);

KERR_NARMA_RUN_JSWEEP = true;
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS = true;
KERR_NARMA_JLIST = [0, 0.10, 0.20, 0.34, 0.50, 0.65];
KERR_NARMA_JSWEEP_KLIST = [0, -1.62];
KERR_NARMA_OUTPUT_TAG = 'JSweepFull_20260720';

run(fullfile(scriptDir, 'Fig3_KerrReservoir_NARMA10_Reproducible.m'));

fprintf('Finished full independent J sweep at %s\n', ...
    char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
diary off;
