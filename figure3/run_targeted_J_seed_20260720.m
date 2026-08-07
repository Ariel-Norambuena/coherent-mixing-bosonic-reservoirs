%% run_targeted_J_seed_20260720.m
% One full-size seed of the targeted K=0 comparison J=0 versus J=0.80.
% Set KERR_NARMA_SEED_OFFSET before running this launcher.

if ~exist('KERR_NARMA_SEED_OFFSET','var')
    error('Set KERR_NARMA_SEED_OFFSET to a positive integer before running.');
end
seedOffsetLocal = KERR_NARMA_SEED_OFFSET;
if ~isscalar(seedOffsetLocal) || seedOffsetLocal < 1 || ...
        seedOffsetLocal ~= floor(seedOffsetLocal)
    error('KERR_NARMA_SEED_OFFSET must be a positive integer for this launcher.');
end

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

tag = sprintf('JTargetSeed%02d_20260720', seedOffsetLocal);
logFile = fullfile(scriptDir, ...
    ['Fig3_KerrReservoir_NARMA10_Reproducible_' tag '_diary.txt']);
if exist(logFile, 'file')
    delete(logFile);
end
diary(logFile);

fprintf('Starting targeted J seed offset %d at %s\n', seedOffsetLocal, ...
    char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));

KERR_NARMA_RUN_JSWEEP = true;
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS = true;
KERR_NARMA_BASE_K = 0;
KERR_NARMA_BASE_J = 0.80;
KERR_NARMA_JLIST = [0, 0.80];
KERR_NARMA_JSWEEP_KLIST = 0;
KERR_NARMA_OUTPUT_TAG = tag;

run(fullfile(scriptDir, 'Fig3_KerrReservoir_NARMA10_Reproducible.m'));

fprintf('Finished targeted J seed at %s\n', ...
    char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
diary off;
