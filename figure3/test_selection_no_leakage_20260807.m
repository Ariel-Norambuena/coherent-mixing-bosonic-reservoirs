function test_selection_no_leakage_20260807
% End-to-end smoke test that proves selection mode never evaluates test data.

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
KERR_NARMA_SMOKE = true; %#ok<NASGU>
KERR_NARMA_PROTOCOL_MODE = 'selection'; %#ok<NASGU>
KERR_NARMA_RUN_JSWEEP = true; %#ok<NASGU>
KERR_NARMA_SKIP_PHYSICAL_ABLATIONS = true; %#ok<NASGU>
KERR_NARMA_BASE_K = 0; %#ok<NASGU>
KERR_NARMA_BASE_J = 0.34; %#ok<NASGU>
KERR_NARMA_JLIST = [0 0.34]; %#ok<NASGU>
KERR_NARMA_JSWEEP_KLIST = 0; %#ok<NASGU>
KERR_NARMA_OUTPUT_TAG = ['AutomatedNoLeakage_' stamp]; %#ok<NASGU>

run(fullfile(fileparts(mfilename('fullpath')), ...
    'Fig3_KerrReservoir_NARMA10_Reproducible.m'));

summaryFile = [cfg.outputPrefix '_summary.mat'];
csvFile = [cfg.outputPrefix '_JSweep_summary.csv'];
assert(isfile(summaryFile), 'Selection smoke summary was not created.');
assert(isfile(csvFile), 'Selection smoke CSV was not created.');

S = load(summaryFile);
assert(strcmp(S.cfg.protocolMode, 'selection'));
assert(~S.cfg.evaluateTest);
assert(isnan(S.results.main.NRMSE));
assert(isempty(S.results.main.Yte) && isempty(S.results.main.Yhat));
assert(all(isnan(S.results.JSweep.NRMSE), 'all'));
assert(all(isnan(S.results.JSweep.R2true), 'all'));
assert(all(isfinite(S.results.JSweep.valNRMSE), 'all'));
assert(strcmp(S.results.JSweep.selectionMetric, 'validation'));

T = readtable(csvFile);
assert(all(isnan(T.testNRMSE)));
assert(all(isnan(T.R2true)));
assert(all(isfinite(T.valNRMSE)));

delete(summaryFile);
delete(csvFile);
fprintf('Selection no-leakage end-to-end test PASS.\n');
end
