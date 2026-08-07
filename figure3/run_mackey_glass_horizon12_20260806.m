%% run_mackey_glass_horizon12_20260806.m
% Direct Mackey-Glass prediction with paired K=0, J=0/0.80 reservoirs.

if exist('KERR_NARMA_SMOKE','var') && KERR_NARMA_SMOKE
    numSamples = 220;
    washout = 20;
    numTrain = 70;
elseif exist('KERR_NARMA_QUICK','var') && KERR_NARMA_QUICK
    numSamples = 900;
    washout = 80;
    numTrain = 300;
else
    numSamples = 22000;
    washout = 2000;
    numTrain = 12000;
end

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

horizon = 12;
if exist('KERR_MG_HORIZON','var')
    horizon = KERR_MG_HORIZON;
end
assert(isscalar(horizon) && isfinite(horizon) && horizon >= 1 && ...
    horizon == floor(horizon),'KERR_MG_HORIZON must be a positive integer.');
if exist('KERR_MG_LAUNCHER_TAG','var') && ...
        (ischar(KERR_MG_LAUNCHER_TAG) || ...
        (isstring(KERR_MG_LAUNCHER_TAG) && isscalar(KERR_MG_LAUNCHER_TAG)))
    tag = char(KERR_MG_LAUNCHER_TAG);
else
    tag = sprintf('MackeyGlassH%d_20260806',horizon);
end
assert(~isempty(tag),'Mackey-Glass output tag must not be empty.');
existingOutputs = dir(fullfile(scriptDir,['*' tag '*']));
assert(isempty(existingOutputs), ...
    'Refusing to overwrite %d existing output(s) containing tag %s.', ...
    numel(existingOutputs),tag);

series = generateMackeyGlass(numSamples+horizon);
uRaw = series(1:numSamples);
target = series((1:numSamples)+horizon);
startIdx = washout+20+1;
idxTrain = startIdx:(startIdx+numTrain-1);
trainMin = min(uRaw(idxTrain));
trainMax = max(uRaw(idxTrain));
assert(trainMax-trainMin>1e-8,'Mackey-Glass training range is degenerate.');
uEncoded = 2*(uRaw-trainMin)/(trainMax-trainMin)-1;
uEncoded = min(max(uEncoded,-1.25),1.25);

KERR_NARMA_CUSTOM_INPUT_RAW = uRaw;
KERR_NARMA_CUSTOM_INPUT_ENCODED = uEncoded;
KERR_NARMA_CUSTOM_TARGET = target;
KERR_NARMA_TASK_LABEL = sprintf('Mackey-Glass h=%d',horizon);
cacheOnly = exist('KERR_MG_CACHE_ONLY','var') && KERR_MG_CACHE_ONLY;
KERR_NARMA_RUN_FEATURE_ABLATIONS = ~cacheOnly;
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS = true;
KERR_NARMA_BASE_K = 0;
if exist('KERR_MG_J','var')
    KERR_NARMA_BASE_J = KERR_MG_J;
else
    KERR_NARMA_BASE_J = 0.80;
end
KERR_NARMA_BASE_FEATURE_MODE = 'number_features';
KERR_NARMA_FEATURE_CASES = [0,0;0,0.80];
KERR_NARMA_FEATURE_MODES = {'number_features'};
KERR_NARMA_OUTPUT_TAG = tag;
KERR_NARMA_SAVE_RAW_FEATURES = cacheOnly;

run(fullfile(scriptDir,'Fig3_KerrReservoir_NARMA10_Reproducible.m'));

function sampled = generateMackeyGlass(numSamples)
beta = 0.20;
gamma = 0.10;
power = 10;
delay = 17;
dt = 0.10;
sampleStride = 10;
delaySteps = round(delay/dt);
burnInSteps = 5000;
neededSteps = burnInSteps+sampleStride*(numSamples-1)+1;
x = 1.20*ones(neededSteps+delaySteps,1);
for step = delaySteps:(numel(x)-1)
    delayed = x(step-delaySteps+1);
    current = x(step);
    derivative = beta*delayed/(1+delayed^power)-gamma*current;
    x(step+1) = current+dt*derivative;
end
firstSample = delaySteps+burnInSteps;
sampleIndices = firstSample+(0:(numSamples-1))*sampleStride;
sampled = x(sampleIndices);
assert(all(isfinite(sampled)) && var(sampled,1)>1e-8, ...
    'Mackey-Glass generator produced an invalid sequence.');
end
