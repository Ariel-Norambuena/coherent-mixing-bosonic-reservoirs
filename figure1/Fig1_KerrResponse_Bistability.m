%% Fig1_KerrResponse_Bistability.m
% Driven-dissipative Kerr oscillator: nonlinear response, bistability,
% susceptibility, and stable high-response operating window.
%
% This script is dimensionless: all frequencies are measured in units of kappa.
% It produces Fig1_KerrResponse_Bistability.pdf and a MAT file with the data.
%
% Model in the drive rotating frame:
%   dbeta/dt = -(kappa/2 + i Delta) beta - i K |beta|^2 beta - i F.
% Steady-state intensity n = |beta_ss|^2 satisfies
%   F^2 = n[(kappa/2)^2 + (Delta + K n)^2].
%
% Author: generated for the Kerr synchronization reservoir manuscript.

clear; close all; clc;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

%% ------------------------- User parameters -------------------------------
kappa = 1.0;                 % unit of frequency
K     = -1.0;                % softening Kerr nonlinearity
DeltaVec = linspace(-6*kappa, 6*kappa, 401);       % detuning scan
Fbranch  = 0.78;             % drive amplitude for branch plot
FVec     = linspace(0.01, 7, 401);       % drive-amplitude scan
exportPDF = true;

%% ------------------------- Branches for fixed F ---------------------------
branchData = computeBranches(DeltaVec, Fbranch, kappa, K);

%% ------------------------- 2D scans --------------------------------------
Nstable = zeros(numel(FVec), numel(DeltaVec));
SusMax  = zeros(numel(FVec), numel(DeltaVec));
NmaxStable = nan(numel(FVec), numel(DeltaVec));
DeffStable = nan(numel(FVec), numel(DeltaVec));

for a = 1:numel(FVec)
    F = FVec(a);
    for b = 1:numel(DeltaVec)
        Delta = DeltaVec(b);
        rootsData = kerrSteadyRoots(Delta, F, kappa, K);
        stableMask = [rootsData.stable];
        Nstable(a,b) = sum(stableMask);
        if any(stableMask)
            nStable = [rootsData(stableMask).n];
            susStable = abs([rootsData(stableMask).sus]);
            [SusMax(a,b), idx] = max(susStable);
            NmaxStable(a,b) = nStable(idx);
            DeffStable(a,b) = Delta + K*NmaxStable(a,b);
        end
    end
end

%% ------------------------- Analytic turning boundary ----------------------
% Turning points satisfy dF^2/dn=0. The onset of bistability occurs when
% Delta^2 > 3 kappa^2/4 and Delta/K < 0. Here K<0, so Delta>sqrt(3)kappa/2.
DeltaTurn = linspace(sqrt(3)*kappa/2, max(DeltaVec), 800);
Fturn1 = nan(size(DeltaTurn));
Fturn2 = nan(size(DeltaTurn));
for k = 1:numel(DeltaTurn)
    Delta = DeltaTurn(k);
    disc = Delta^2 - 3*kappa^2/4;
    n1 = (-2*Delta + sqrt(disc))/(3*K);
    n2 = (-2*Delta - sqrt(disc))/(3*K);
    Fturn1(k) = real(sqrt(max(0, n1*((kappa/2)^2 + (Delta + K*n1)^2))));
    Fturn2(k) = real(sqrt(max(0, n2*((kappa/2)^2 + (Delta + K*n2)^2))));
end

%% ------------------------- Plot ------------------------------------------
fig = figure('Color','w','Name','Fig. 1 Kerr response and bistability');
set(fig,'Units','inches','Position',[1 1 7.2 5.2]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
fontSize = 11;

% (a) Response branches
nexttile; hold on; box on;
stableD = [branchData([branchData.stable]).Delta];
stableN = [branchData([branchData.stable]).n];
unstD = [branchData(~[branchData.stable]).Delta];
unstN = [branchData(~[branchData.stable]).n];
plot(stableD, stableN, '.', 'MarkerSize', 5);
plot(unstD, unstN, '.', 'MarkerSize', 5);
xlabel('$\Delta/\kappa$','Interpreter','latex');
ylabel('$n=|\beta_{\rm ss}|^2$','Interpreter','latex');
title(sprintf('(a) Kerr response, $F/\\kappa=%.2f$',Fbranch),'Interpreter','latex');
legend({'stable','unstable'},'Interpreter','latex','Location','northwest');
set(gca,'FontSize',fontSize,'TickLabelInterpreter','latex');

% (b) Number of stable steady states
nexttile; box on; hold on;
imagesc(DeltaVec/kappa, FVec/kappa, Nstable); axis xy;
plot(DeltaTurn/kappa, Fturn1/kappa, 'k-', 'LineWidth', 2);
plot(DeltaTurn/kappa, Fturn2/kappa, 'k-', 'LineWidth', 2);
xlabel('$\Delta/\kappa$','Interpreter','latex');
ylabel('$F/\kappa$','Interpreter','latex');
title('(b) Number of stable branches','Interpreter','latex');
cb = colorbar; cb.Label.String = '$N_{\rm stable}$'; cb.Label.Interpreter = 'latex';
set(gca,'FontSize',fontSize,'TickLabelInterpreter','latex');
ylim([0 7])

% (c) Maximum stable susceptibility
nexttile; box on; hold on;
imagesc(DeltaVec/kappa, FVec/kappa, log10(1 + SusMax)); axis xy;
plot(DeltaTurn/kappa, Fturn1/kappa, 'k-', 'LineWidth', 1.2);
plot(DeltaTurn/kappa, Fturn2/kappa, 'k-', 'LineWidth', 1.2);
xlabel('$\Delta/\kappa$','Interpreter','latex');
ylabel('$F/\kappa$','Interpreter','latex');
title('(c) Stable nonlinear susceptibility','Interpreter','latex');
cb = colorbar; cb.Label.String = '$S_\Delta$'; cb.Label.Interpreter = 'latex';
set(gca,'FontSize',fontSize,'TickLabelInterpreter','latex');
ylim([0 7])

% (d) Effective detuning of most sensitive stable state
nexttile; box on; hold on;
imagesc(DeltaVec/kappa, FVec/kappa, DeffStable/kappa); axis xy;
plot(DeltaTurn/kappa, Fturn1/kappa, 'k-', 'LineWidth', 2);
plot(DeltaTurn/kappa, Fturn2/kappa, 'k-', 'LineWidth', 2);
xlabel('$\Delta/\kappa$','Interpreter','latex');
ylabel('$F/\kappa$','Interpreter','latex');
title('(d) Kerr-shifted detuning','Interpreter','latex');
cb = colorbar; cb.Label.String = '$\Delta_{\rm eff}/\kappa$'; cb.Label.Interpreter = 'latex';
set(gca,'FontSize',fontSize,'TickLabelInterpreter','latex');
ylim([0 7])

%% ------------------------- Save ------------------------------------------
save(fullfile(scriptDir,'Fig1_KerrResponse_Bistability_data.mat'), ...
    'kappa','K','DeltaVec','FVec', ...
    'Fbranch','branchData','Nstable','SusMax','NmaxStable','DeffStable', ...
    'DeltaTurn','Fturn1','Fturn2');
if exportPDF
    exportgraphics(fig, fullfile(scriptDir,'Fig1_KerrResponse_Bistability.pdf'), ...
        'ContentType','vector');
    exportgraphics(fig, fullfile(scriptDir,'Fig1_KerrResponse_Bistability.png'), ...
        'Resolution', 300);
end

%% ============================= Local functions ============================
function data = computeBranches(DeltaVec, F, kappa, K)
    data = struct('Delta',{},'n',{},'stable',{},'sus',{},'eigmax',{});
    c = 0;
    for b = 1:numel(DeltaVec)
        rootsData = kerrSteadyRoots(DeltaVec(b), F, kappa, K);
        for r = 1:numel(rootsData)
            c = c + 1;
            data(c).Delta  = DeltaVec(b);
            data(c).n      = rootsData(r).n;
            data(c).stable = rootsData(r).stable;
            data(c).sus    = rootsData(r).sus;
            data(c).eigmax = rootsData(r).eigmax;
        end
    end
end

function rootsData = kerrSteadyRoots(Delta, F, kappa, K)
    % Cubic coefficients for K^2 n^3 + 2 Delta K n^2 + ((k/2)^2+Delta^2)n - F^2 = 0.
    coeff = [K^2, 2*Delta*K, (kappa/2)^2 + Delta^2, -F^2];
    rr = roots(coeff);
    nRoots = sort(real(rr(abs(imag(rr)) < 1e-9 & real(rr) > 1e-12))).';
    rootsData = struct('n',{},'beta',{},'stable',{},'sus',{},'eigmax',{});
    for q = 1:numel(nRoots)
        n = nRoots(q);
        beta = -1i*F/(kappa/2 + 1i*(Delta + K*n));
        J = jacSingle(real(beta), imag(beta), Delta, kappa, K);
        ev = eig(J);
        eigmax = max(real(ev));
        dGdn = (kappa/2)^2 + (Delta + K*n)^2 + 2*K*n*(Delta + K*n);
        dGdD = 2*n*(Delta + K*n);
        sus = -dGdD/dGdn;
        rootsData(q).n = n;
        rootsData(q).beta = beta;
        rootsData(q).stable = eigmax < -1e-9;
        rootsData(q).sus = sus;
        rootsData(q).eigmax = eigmax;
    end
end

function J = jacSingle(x, y, Delta, kappa, K)
    J = zeros(2,2);
    J(1,1) = -kappa/2 + 2*K*x*y;
    J(1,2) = Delta + K*(x^2 + 3*y^2);
    J(2,1) = -Delta - K*(3*x^2 + y^2);
    J(2,2) = -kappa/2 - 2*K*x*y;
end
