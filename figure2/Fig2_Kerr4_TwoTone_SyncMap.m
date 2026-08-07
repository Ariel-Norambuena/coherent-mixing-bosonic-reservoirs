%% Fig2_Kerr4_TwoTone_SyncMap.m
% Four coupled driven-dissipative Kerr oscillators under two input tones.
% Produces a synchronization map in the (f_A,f_B) plane and operational
% diagnostics: mean PLV to each tone, label histogram, H_sync and N_sync.
%
% The model is integrated in a frame rotating at omega_A:
%   dbeta_i/dt = -(kappa/2+i Delta_i) beta_i - i K |beta_i|^2 beta_i
%                - i sum_j J_ij beta_j - i F_A - i F_B exp(-i delta t),
% with Delta_i = omega_i - omega_A and delta = omega_B - omega_A.
%
% Important convention: if beta_i has phase theta_i(t), the laboratory
% oscillation frequency is f_i^lab = f_A - <dot(theta_i)>/(2*pi).
%
% Author: generated for the Kerr synchronization reservoir manuscript.

clear; close all; clc;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

%% ------------------------- Physical parameters ---------------------------
P.N = 4;
P.kappa = 2*pi*2.0e6;            % loss rate [rad/s]
P.K     = -2*pi*5.0e6;           % Kerr shift [rad/s/photon in mean-field units]
P.FA    = 2*pi*2.0e6;            % tone-A drive amplitude [rad/s]
P.FB    = 2*pi*2.0e6;            % tone-B drive amplitude [rad/s]

f0 = 330e6;                      % base natural frequency [Hz]
mismatch = [-0.030, -0.010, 0.010, 0.030];
P.omega = 2*pi*f0*(1 + mismatch(:));

J0 = 2*pi*2.0e6;                 % nearest-neighbor coherent hopping [rad/s]
Adj = [0 1 0 1; 1 0 1 0; 0 1 0 1; 1 0 1 0];
P.J = J0*Adj;

%% ------------------------- Numerical controls ----------------------------
fA_vec = linspace(330e6, 380e6, 200);        % increase to 81 for final production
fB_vec = linspace(330e6, 380e6, 200);
Tsettle = 25e-6;                            % transient time [s]
Tobs    = 15e-6;                            % observation window [s]
RelTol  = 1e-8;
AbsTol  = 1e-10;

% Locking thresholds. Keep fixed across all scans.
tol_Hz = 0.5e6;
plvThresh = 0.85;

% Reproducibility and continuation strategy.
rng(4);
beta0 = 1e-6*exp(1i*2*pi*rand(P.N,1));
y0_global = [real(beta0); imag(beta0)];

useParallel = strcmp(getenv('KERR_FIG2_PARALLEL'),'1');
saveIntermediate = true;
cacheFile = fullfile(scriptDir,'Fig2_Kerr4_TwoTone_SyncMap_data.mat');
%% ------------------------- Frequency scan --------------------------------
M = numel(fA_vec); L = numel(fB_vec);
stateCode = zeros(L,M);
meanPLVA  = zeros(L,M);
meanPLVB  = zeros(L,M);
meanN     = zeros(L,M);
meanLabFreq = zeros(L,M,P.N);
labelWords = strings(L,M);

if exist(cacheFile,'file')
    fprintf('Loading cached data from %s\n', cacheFile);
    load(cacheFile);
else
    fprintf('Running %d x %d synchronization scan...\n', M, L);
    opts = odeset('RelTol',RelTol,'AbsTol',AbsTol);

    if useParallel
        % Parallel mode uses the same initial condition for all points.
        numPoints = M*L;
        stateCodeVec = zeros(numPoints,1);
        meanPLVAVec = zeros(numPoints,1);
        meanPLVBVec = zeros(numPoints,1);
        meanNVec = zeros(numPoints,1);
        meanLabFreqVec = zeros(numPoints,P.N);
        labelWordsVec = strings(numPoints,1);
        [fBGrid,fAGrid] = ndgrid(fB_vec,fA_vec);
        fAForPoint = fAGrid(:);
        fBForPoint = fBGrid(:);
        parfor idx = 1:(M*L)
            result = simulatePoint(fAForPoint(idx),fBForPoint(idx),y0_global, ...
                P,Tsettle,Tobs,opts,tol_Hz,plvThresh);
            stateCodeVec(idx) = result.code;
            meanPLVAVec(idx) = result.meanPLVA;
            meanPLVBVec(idx) = result.meanPLVB;
            meanNVec(idx) = result.meanN;
            meanLabFreqVec(idx,:) = result.fLab;
            labelWordsVec(idx) = result.word;
        end
        stateCode = reshape(stateCodeVec,L,M);
        meanPLVA = reshape(meanPLVAVec,L,M);
        meanPLVB = reshape(meanPLVBVec,L,M);
        meanN = reshape(meanNVec,L,M);
        labelWords = reshape(labelWordsVec,L,M);
        for modeIndex = 1:P.N
            meanLabFreq(:,:,modeIndex) = reshape(meanLabFreqVec(:,modeIndex),L,M);
        end
    else
        % Serial mode continues from neighboring points. This is faster and
        % mimics experimental frequency sweeps, but may reveal hysteresis.
        y0 = y0_global;
        for ii = 1:M
            fprintf('  column %d/%d: fA = %.2f MHz\n', ii, M, fA_vec(ii)/1e6);
            for jj = 1:L
                result = simulatePoint(fA_vec(ii), fB_vec(jj), y0, P, Tsettle, Tobs, opts, tol_Hz, plvThresh);
                stateCode(jj,ii) = result.code;
                meanPLVA(jj,ii)  = result.meanPLVA;
                meanPLVB(jj,ii)  = result.meanPLVB;
                meanN(jj,ii)     = result.meanN;
                meanLabFreq(jj,ii,:) = result.fLab;
                labelWords(jj,ii) = result.word;
                y0 = result.yFinal;
            end
        end
    end

    [Hsync, Nsync, uniqueCodes, probs, uniqueWords] = entropyFromCodes(stateCode, labelWords);
    if saveIntermediate
        save(cacheFile, 'P','fA_vec','fB_vec','Tsettle','Tobs','RelTol','AbsTol', ...
            'tol_Hz','plvThresh','stateCode','meanPLVA','meanPLVB','meanN', ...
            'meanLabFreq','labelWords','Hsync','Nsync','uniqueCodes','probs','uniqueWords');
    end
end

fprintf('H_sync = %.4f nats, N_sync = %.3f effective cells.\n', Hsync, Nsync);

%% ------------------------- Plot ------------------------------------------
fig = figure('Color','w','Name','Fig. 2 Four-Kerr synchronization map');
set(fig,'Units','inches','Position',[1 1 7.2 5.2]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
fontSize = 11;

% Re-index codes to consecutive integers for clean plotting.
[~,~,codeIndex] = unique(stateCode(:));
codeIndex = reshape(codeIndex, size(stateCode));
nCodes = max(codeIndex(:));

nexttile; box on;
imagesc(fA_vec/1e6, fB_vec/1e6, codeIndex); axis xy tight;
xlabel('$f_A$ (MHz)','Interpreter','latex'); ylabel('$f_B$ (MHz)','Interpreter','latex');
title(sprintf('(a) Synchronization cells, $N_{\\rm sync}=%.2f$',Nsync),'Interpreter','latex');
colormap(gca, lines(max(nCodes,7))); cb = colorbar; cb.Label.String = 'cell index';
set(gca,'FontSize',fontSize,'TickLabelInterpreter','latex');

nexttile; box on;
imagesc(fA_vec/1e6, fB_vec/1e6, meanPLVA); axis xy tight; clim([0 1]);
xlabel('$f_A$ (MHz)','Interpreter','latex'); ylabel('$f_B$ (MHz)','Interpreter','latex');
title('(b) Mean PLV to tone A','Interpreter','latex');
cb = colorbar; cb.Label.String = '$\langle {\rm PLV}_{iA}\rangle_i$'; cb.Label.Interpreter = 'latex';
set(gca,'FontSize',fontSize,'TickLabelInterpreter','latex');

nexttile; box on;
imagesc(fA_vec/1e6, fB_vec/1e6, meanPLVB); axis xy tight; clim([0 1]);
xlabel('$f_A$ (MHz)','Interpreter','latex'); ylabel('$f_B$ (MHz)','Interpreter','latex');
title('(c) Mean PLV to tone B','Interpreter','latex');
cb = colorbar; cb.Label.String = '$\langle {\rm PLV}_{iB}\rangle_i$'; cb.Label.Interpreter = 'latex';
set(gca,'FontSize',fontSize,'TickLabelInterpreter','latex');

nexttile; box on; hold on;
[probsSort, ord] = sort(probs, 'descend');
bar(probsSort, 'LineWidth', 0.8);
ylabel('$p_\sigma$','Interpreter','latex'); xlabel('synchronization cell, sorted','Interpreter','latex');
title(sprintf('(d) Cell distribution, $H_{\\rm sync}=%.2f$', Hsync),'Interpreter','latex');
set(gca,'FontSize',fontSize,'TickLabelInterpreter','latex');

exportgraphics(fig, fullfile(scriptDir,'Fig2_Kerr4_TwoTone_SyncMap.pdf'), ...
    'ContentType','vector');
exportgraphics(fig, fullfile(scriptDir,'Fig2_Kerr4_TwoTone_SyncMap.png'), ...
    'Resolution', 300);

fprintf('\nDominant synchronization words:\n');
for q = 1:min(12,numel(ord))
    fprintf('  p=%6.3f  %s\n', probsSort(q), char(uniqueWords(ord(q))));
end

%% ============================= Local functions ============================
function result = simulatePoint(fA, fB, y0, P, Tsettle, Tobs, opts, tol_Hz, plvThresh)
    wA = 2*pi*fA; wB = 2*pi*fB; delta = wB - wA;
    Q = P;
    Q.Delta = P.omega - wA;
    Q.delta = delta;
    Q.fA = fA; Q.fB = fB;

    [~, yTrans] = ode45(@(t,y) rhsKerrTwoTone(t,y,Q), [0 Tsettle], y0, opts);
    ySS = yTrans(end,:).';
    [t, yObs] = ode45(@(t,y) rhsKerrTwoTone(t,y,Q), [0 Tobs], ySS, opts);
    beta = yObs(:,1:P.N) + 1i*yObs(:,P.N+1:2*P.N);

    theta = unwrap(angle(beta));
    dtheta = zeros(size(theta));
    for i = 1:P.N
        dtheta(:,i) = gradient(theta(:,i), t);
    end
    fLab = fA - mean(dtheta(round(0.3*numel(t)):end,:), 1)/(2*pi);

    i0 = max(1, floor(0.30*numel(t)));
    tt = t(i0:end);
    th = theta(i0:end,:);
    PLVA = abs(mean(exp(1i*th), 1));
    PLVB = abs(mean(exp(1i*(th + delta*tt)), 1));

    lockA = (abs(fLab - fA) <= tol_Hz) & (PLVA >= plvThresh);
    lockB = (abs(fLab - fB) <= tol_Hz) & (PLVB >= plvThresh);

    [code, word] = encodeLockWord(lockA, lockB);
    result.code = code;
    result.word = word;
    result.meanPLVA = mean(PLVA);
    result.meanPLVB = mean(PLVB);
    tmpN = abs(beta(i0:end,:)).^2;
    result.meanN = mean(tmpN(:));
    result.fLab = fLab;
    result.yFinal = yObs(end,:).';
end

function dy = rhsKerrTwoTone(t, y, P)
    N = P.N;
    beta = y(1:N) + 1i*y(N+1:2*N);
    lin    = -(P.kappa/2 + 1i*P.Delta(:)).*beta;
    nonlin = -1i*P.K*(abs(beta).^2).*beta;
    coupl  = -1i*(P.J*beta);
    drive  = -1i*(P.FA + P.FB*exp(-1i*P.delta*t))*ones(N,1);
    dbeta = lin + nonlin + coupl + drive;
    dy = [real(dbeta); imag(dbeta)];
end

function [code, word] = encodeLockWord(lockA, lockB)
    N = numel(lockA);
    digit = zeros(1,N); % 0 none, 1 A, 2 B, 3 AB/ambiguous
    tokens = strings(1,N);
    for i = 1:N
        if lockA(i) && ~lockB(i)
            digit(i) = 1; tokens(i) = sprintf('%dA',i);
        elseif ~lockA(i) && lockB(i)
            digit(i) = 2; tokens(i) = sprintf('%dB',i);
        elseif lockA(i) && lockB(i)
            digit(i) = 3; tokens(i) = sprintf('%dAB',i);
        else
            digit(i) = 0; tokens(i) = sprintf('%d0',i);
        end
    end
    code = sum(digit .* (4.^(0:N-1)));
    word = strjoin(tokens, '-');
end

function [Hsync, Nsync, uniqueCodes, probs, uniqueWords] = entropyFromCodes(stateCode, labelWords)
    [uniqueCodes, ~, ic] = unique(stateCode(:));
    counts = accumarray(ic, 1);
    probs = counts/sum(counts);
    Hsync = -sum(probs .* log(probs + eps));
    Nsync = exp(Hsync);
    uniqueWords = strings(size(uniqueCodes));
    for k = 1:numel(uniqueCodes)
        idx = find(stateCode(:) == uniqueCodes(k), 1, 'first');
        uniqueWords(k) = labelWords(idx);
    end
end
