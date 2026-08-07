%% run_targeted_compact_features_seed_20260806.m
% Paired K=0 compact-feature confirmation with collision-safe output tags.

if ~exist('KERR_NARMA_SEED_OFFSET','var')
    error('Set KERR_NARMA_SEED_OFFSET to a positive integer before running.');
end
seedOffsetLocal = KERR_NARMA_SEED_OFFSET;
if ~isscalar(seedOffsetLocal) || ~isfinite(seedOffsetLocal) || ...
        seedOffsetLocal < 1 || seedOffsetLocal ~= floor(seedOffsetLocal)
    error('KERR_NARMA_SEED_OFFSET must be a positive integer.');
end

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

if exist('KERR_NARMA_LAUNCHER_TAG','var') && ...
        (ischar(KERR_NARMA_LAUNCHER_TAG) || ...
        (isstring(KERR_NARMA_LAUNCHER_TAG) && isscalar(KERR_NARMA_LAUNCHER_TAG)))
    tag = char(KERR_NARMA_LAUNCHER_TAG);
else
    tag = sprintf('CompactFeaturesSeed%02d_20260806', seedOffsetLocal);
end
assert(~isempty(tag), 'Output tag must not be empty.');

existingOutputs = dir(fullfile(scriptDir, ['*' tag '*']));
assert(isempty(existingOutputs), ...
    'Refusing to overwrite %d existing output(s) containing tag %s.', ...
    numel(existingOutputs), tag);

logFile = fullfile(scriptDir, ...
    ['Fig3_KerrReservoir_NARMA10_Reproducible_' tag '_diary.txt']);
diary(logFile);
fprintf('Starting compact-feature seed offset %d at %s\n', seedOffsetLocal, ...
    char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));

KERR_NARMA_RUN_FEATURE_ABLATIONS = true;
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS = true;
KERR_NARMA_SKIP_BASELINES = true;
KERR_NARMA_BASE_K = 0;
KERR_NARMA_BASE_J = 0.80;
KERR_NARMA_BASE_FEATURE_MODE = 'linear_features';
KERR_NARMA_FEATURE_CASES = [0, 0; 0, 0.80];
KERR_NARMA_FEATURE_MODES = {'linear_features','number_features'};
KERR_NARMA_OUTPUT_TAG = tag;

run(fullfile(scriptDir, 'Fig3_KerrReservoir_NARMA10_Reproducible.m'));

fprintf('Finished compact-feature seed at %s\n', ...
    char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
diary off;
