%% Independent NARMA10 alignment, split-boundary, and metric audit.
% Uses a frozen full-size generated artifact and does not rerun the reservoir.

clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
inputFile = fullfile(scriptDir, ...
    'Fig3_KerrReservoir_NARMA10_Reproducible_CompactFeaturesSeed01_20260806_summary.mat');
assert(isfile(inputFile), 'Missing frozen full-size NARMA10 artifact.');
S = load(inputFile, 'cfg', 'uN', 'yN', 'results', 'datasetSeed');

u = S.uN(:);
y = S.yN(:);
T = numel(u);
assert(numel(y) == T && T == S.cfg.numSamples);

% Recompute every nontrivial target update independently from the saved data.
reconstructed = zeros(T,1);
reconstructed(1:11) = y(1:11);
for k = 11:(T-1)
    reconstructed(k+1) = 0.3*y(k) + 0.05*y(k)*sum(y(k-9:k)) + ...
        1.5*u(k-9)*u(k) + 0.1;
end
alignmentError = max(abs(reconstructed(12:end) - y(12:end)));
assert(alignmentError < 1e-14, 'NARMA10 target alignment mismatch.');

tapDelays = S.cfg.tapDelays(:).';
assert(all(isfinite(tapDelays)) && all(tapDelays >= 0) && ...
    all(tapDelays == floor(tapDelays)));
startIdx = S.cfg.washout + max([20, tapDelays]) + 1;
idxTrain = startIdx:(startIdx + S.cfg.numTrain - 1);
idxVal = (idxTrain(end)+1):(idxTrain(end)+S.cfg.numVal);
idxTest = (idxVal(end)+1):(idxVal(end)+S.cfg.numTest);
assert(idxTest(end) <= S.cfg.numSamples);
assert(isempty(intersect(idxTrain, idxVal)) && ...
    isempty(intersect(idxTrain, idxTest)) && isempty(intersect(idxVal, idxTest)));

allEvaluated = [idxTrain idxVal idxTest];
allSourceIndices = allEvaluated(:) - tapDelays;
assert(all(allSourceIndices(:) >= 1));
assert(all(allSourceIndices <= allEvaluated(:), 'all'));

% Continuous-stream evaluation intentionally permits causal history from the
% immediately preceding split for the first max(tapDelays) samples.
valCrosses = arrayfun(@(index) any(index-tapDelays < idxVal(1)), idxVal);
testCrosses = arrayfun(@(index) any(index-tapDelays < idxTest(1)), idxTest);
validationBoundarySamples = sum(valCrosses);
testBoundarySamples = sum(testCrosses);
assert(validationBoundarySamples == max(tapDelays));
assert(testBoundarySamples == max(tapDelays));
assert(all(idxVal(valCrosses)-max(tapDelays) >= idxTrain(1)));
assert(all(idxTest(testCrosses)-max(tapDelays) >= idxVal(1)));

% Recompute metrics independently from the saved target/prediction vectors.
main = S.results.main;
yTrue = main.Yte(:);
yHat = main.Yhat(:);
independentNRMSE = sqrt(mean((yTrue-yHat).^2)/mean((yTrue-mean(yTrue)).^2));
independentR2true = 1 - sum((yTrue-yHat).^2)/sum((yTrue-mean(yTrue)).^2);
corrMatrix = corrcoef(yTrue, yHat);
independentR2corr = corrMatrix(1,2)^2;
nrmseError = abs(independentNRMSE-main.NRMSE);
r2trueError = abs(independentR2true-main.R2true);
r2corrError = abs(independentR2corr-main.R2corr);
metricTolerance = 1e-12;
assert(nrmseError < metricTolerance);
assert(r2trueError < metricTolerance);
assert(r2corrError < metricTolerance);

check = [
    "narma_recurrence_max_abs_error"
    "nonnegative_causal_taps"
    "disjoint_target_splits"
    "validation_boundary_history_samples"
    "test_boundary_history_samples"
    "nrmse_abs_error"
    "coefficient_of_determination_abs_error"
    "squared_correlation_abs_error"
    ];
observed = [
    alignmentError
    double(all(tapDelays >= 0))
    1
    validationBoundarySamples
    testBoundarySamples
    nrmseError
    r2trueError
    r2corrError
    ];
limit = [
    1e-14
    1
    1
    max(tapDelays)
    max(tapDelays)
    metricTolerance
    metricTolerance
    metricTolerance
    ];
status = repmat("PASS", size(check));
auditTable = table(check, observed, limit, status);
csvFile = fullfile(scriptDir, 'NARMAAlignmentSplitMetricAudit_20260808.csv');
writetable(auditTable, csvFile);

mdFile = fullfile(scriptDir, 'NARMAAlignmentSplitMetricAudit_20260808.md');
fid = fopen(mdFile, 'w');
assert(fid >= 0, 'Could not open audit report.');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# NARMA10 alignment, split, and metric audit\n\n');
fprintf(fid, 'Status: **PASS**\n\n');
fprintf(fid, '- Frozen input artifact: `%s`\n', string(inputFile));
fprintf(fid, '- Effective dataset seed: `%d`\n', S.datasetSeed);
fprintf(fid, '- NARMA recurrence maximum absolute error: `%.3g`\n', alignmentError);
fprintf(fid, '- Train indices: `%d--%d` (%d samples)\n', ...
    idxTrain(1), idxTrain(end), numel(idxTrain));
fprintf(fid, '- Validation indices: `%d--%d` (%d samples)\n', ...
    idxVal(1), idxVal(end), numel(idxVal));
fprintf(fid, '- Test indices: `%d--%d` (%d samples)\n', ...
    idxTest(1), idxTest(end), numel(idxTest));
fprintf(fid, '- Maximum causal tap: `%d` samples\n', max(tapDelays));
fprintf(fid, ['- The first %d validation samples and first %d test samples use ' ...
    'only past features from the immediately preceding split. This is a ' ...
    'documented continuous-stream convention, not future-data leakage.\n'], ...
    validationBoundarySamples, testBoundarySamples);
fprintf(fid, '- Independent NRMSE absolute error: `%.3g`\n', nrmseError);
fprintf(fid, '- Independent coefficient-of-determination absolute error: `%.3g`\n', ...
    r2trueError);
fprintf(fid, '- Independent squared-correlation absolute error: `%.3g`\n', ...
    r2corrError);

fprintf('NARMA10 alignment/split/metric audit PASS.\n');
fprintf('Report: %s\n', mdFile);
