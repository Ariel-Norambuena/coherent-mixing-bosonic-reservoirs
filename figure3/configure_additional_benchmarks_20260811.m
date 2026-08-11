%% Freeze the selection plans for the minimal architecture and phase task.

clear; clc;
scriptDir = fileparts(mfilename('fullpath'));
configDir = fullfile(scriptDir,'configs');
if ~isfolder(configDir), mkdir(configDir); end

nSteps = 55;
t = ((0:nSteps-1).' + 0.5)/nSteps;
mask = sin(2*pi*t) + 0.55*sin(2*pi*7*t + 0.31) + ...
    0.30*cos(2*pi*13*t - 0.27);
mask = mask/max(abs(mask));
bias = 0.15*cos(2*pi*3*t + 0.19);

protocol.schema_version = 1;
protocol.status = 'selection_plan_frozen';
protocol.created_date = '2026-08-11';
protocol.selection_offsets = 101:110;
protocol.fresh_narma_offsets = 3001:3030;
protocol.phase_selection_offsets = 201:210;
protocol.phase_locked_offsets = 4001:4030;
protocol.K = 0;
protocol.J_grid = [0 0.45 0.65 0.85];
protocol.input_gain_grid = [1.00 1.25 1.50];
protocol.copy_grid = [1 2 3];
protocol.stage_a_copies = 1;
protocol.steps_per_sample = nSteps;
protocol.virtual_node_indices = [11 20 29 37 46 55];
protocol.tap_delays = [0 1 2 3 4 5 6 7 8 9 10 12 15];
protocol.n_pc = 26;
protocol.readout_coefficients_including_bias = 339;
protocol.lambda_grid = logspace(-6,3,28);
protocol.absolute_tie_tolerance = 0.003;
protocol.input_mask = mask;
protocol.input_bias = bias;
protocol.encoding = 'uniform detuning plus uniform amplitude';
protocol.static_disorder = false;
protocol.copy_disorder = false;
protocol.selection_rule = ['Stage A minimizes mean validation NRMSE over ' ...
    'coupled J and gain at one copy using one global ridge value. Stage B ' ...
    'tests one, two, and three deterministic copies at the selected point; ' ...
    'within the absolute tie tolerance, fewer copies are preferred.'];
protocol.locked_rule = ['Fresh NARMA offsets and phase-task locked offsets ' ...
    'remain inaccessible until separate locked JSON files and SHA-256 ' ...
    'checksums are written by the selection analyzers.'];

path = fullfile(configDir,'additional_benchmark_protocol_20260811.json');
writeFrozenJson(path,protocol);
fprintf('ADDITIONAL_BENCHMARK_PROTOCOL_PASS %s\n',sha256File(path));

function writeFrozenJson(path,value)
text = [jsonencode(value,PrettyPrint=true) newline];
if isfile(path)
    assert(strcmp(fileread(path),text), ...
        'Existing frozen protocol differs from the requested plan.');
else
    fid = fopen(path,'w');
    assert(fid >= 0,'Could not create %s.',path);
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid,'%s',text);
end
checksumPath = [path '.sha256'];
checksumText = sprintf('%s  %s\n',sha256File(path),string(extractAfter(path,filesep)));
if isfile(checksumPath)
    assert(strcmp(fileread(checksumPath),checksumText), ...
        'Existing protocol checksum file differs.');
else
    fid = fopen(checksumPath,'w');
    assert(fid >= 0,'Could not create checksum file.');
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid,'%s',checksumText);
end
end

function digest = sha256File(path)
engine = java.security.MessageDigest.getInstance('SHA-256');
fid = fopen(path,'rb'); assert(fid >= 0,'Could not hash %s.',path);
cleanup = onCleanup(@() fclose(fid));
data = fread(fid,Inf,'*uint8');
bytes = typecast(engine.digest(data),'uint8');
digest = lower(reshape(dec2hex(bytes,2).',1,[]));
end

