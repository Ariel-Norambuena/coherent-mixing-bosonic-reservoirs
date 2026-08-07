%% run_full_J_high_extension_20260720.m
% Targeted paper-grade extension of the K=0 coupling sweep beyond J=0.65.

clear; clc;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

logFile = fullfile(scriptDir, ...
    'Fig3_KerrReservoir_NARMA10_Reproducible_JSweepHighJFull_20260720_diary.txt');
if exist(logFile, 'file')
    delete(logFile);
end
diary(logFile);

fprintf('Starting targeted high-J extension at %s\n', ...
    char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));

KERR_NARMA_RUN_JSWEEP = true;
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS = true;
KERR_NARMA_JLIST = [0.80, 0.95, 1.10];
KERR_NARMA_JSWEEP_KLIST = 0;
KERR_NARMA_OUTPUT_TAG = 'JSweepHighJFull_20260720';

run(fullfile(scriptDir, 'Fig3_KerrReservoir_NARMA10_Reproducible.m'));

fprintf('Finished targeted high-J extension at %s\n', ...
    char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
diary off;
