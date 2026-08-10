%% Verify the exact K=0 contraction and old-input forgetting bound.

clear; clc; close all;
scriptDir = fileparts(mfilename('fullpath'));
rng(20260810, 'twister');

N = 12;
kappa = 0.120;
J0 = 0.65;
dt = 0.0125;
nSteps = 1600;
cutoff = 600;
Adj1 = circshift(eye(N),1)+circshift(eye(N),-1);
Adj2 = circshift(eye(N),2)+circshift(eye(N),-2);
Adj3 = circshift(eye(N),3)+circshift(eye(N),-3);
J = J0*(Adj1+0.32*Adj2+0.10*Adj3);
Delta0 = linspace(-1.05,1.05,N).'+0.06*randn(N,1);
mask = [1.00; -0.82; 0.61; -0.95; 0.74; -0.48; ...
    0.88; -0.58; 0.36; -0.70; 0.52; -0.66];
gDelta = 0.72*mask;
gF = 0.10*circshift(mask,3);
F0 = 0.50;

uCommon = 2*rand(nSteps,1)-1;
uHistoryA = 2*rand(nSteps,1)-1;
uHistoryB = 2*rand(nSteps,1)-1;
uHistoryB(cutoff+1:end) = uHistoryA(cutoff+1:end);

betaSameA = randn(N,1)+1i*randn(N,1);
betaSameB = randn(N,1)+1i*randn(N,1);
betaHistoryA = zeros(N,1);
betaHistoryB = zeros(N,1);
sameInputNorm = nan(nSteps+1,1);
oldHistoryNorm = nan(nSteps+1,1);
sameInputNorm(1) = norm(betaSameA-betaSameB);
oldHistoryNorm(1) = 0;

for k = 1:nSteps
    betaSameA = affineExactStep(betaSameA,uCommon(k),Delta0,gDelta, ...
        F0,gF,J,kappa,dt);
    betaSameB = affineExactStep(betaSameB,uCommon(k),Delta0,gDelta, ...
        F0,gF,J,kappa,dt);
    betaHistoryA = affineExactStep(betaHistoryA,uHistoryA(k),Delta0,gDelta, ...
        F0,gF,J,kappa,dt);
    betaHistoryB = affineExactStep(betaHistoryB,uHistoryB(k),Delta0,gDelta, ...
        F0,gF,J,kappa,dt);
    sameInputNorm(k+1) = norm(betaSameA-betaSameB);
    oldHistoryNorm(k+1) = norm(betaHistoryA-betaHistoryB);
end

t = (0:nSteps).'*dt;
sameInputBound = sameInputNorm(1)*exp(-kappa*t/2);
cutoffIndex = cutoff+1;
oldHistoryBound = nan(size(t));
oldHistoryBound(cutoffIndex:end) = oldHistoryNorm(cutoffIndex)* ...
    exp(-kappa*(t(cutoffIndex:end)-t(cutoffIndex))/2);
sameRelativeError = max(abs(sameInputNorm-sameInputBound) ./ ...
    max(sameInputBound,realmin));
oldRelativeError = max(abs(oldHistoryNorm(cutoffIndex:end)- ...
    oldHistoryBound(cutoffIndex:end)) ./ ...
    max(oldHistoryBound(cutoffIndex:end),realmin));
fitRows = sameInputNorm > 1e-12;
fitCoefficients = polyfit(t(fitRows),log(sameInputNorm(fitRows)),1);
estimatedConditionalExponent = fitCoefficients(1);
theoreticalUpperBound = -kappa/2;

assert(sameRelativeError < 2e-11, ...
    'Same-input contraction differs from the exact law.');
assert(oldRelativeError < 2e-11, ...
    'Old-input forgetting differs from the exact post-cutoff law.');
assert(abs(estimatedConditionalExponent-theoreticalUpperBound) < 1e-11);

T = table(t,sameInputNorm,sameInputBound,oldHistoryNorm,oldHistoryBound);
csvFile = fullfile(scriptDir,'K0ContractionVerification_20260810.csv');
writetable(T,csvFile);

summary = table(N,kappa,J0,dt,nSteps,cutoff,theoreticalUpperBound, ...
    estimatedConditionalExponent,sameRelativeError,oldRelativeError);
writetable(summary,fullfile(scriptDir,'K0ContractionSummary_20260810.csv'));

fig = figure('Color','w','Visible','off','Units','inches', ...
    'Position',[1 1 6.8 3.5]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
nexttile;
semilogy(t,sameInputNorm,'-','Color',[0.10 0.38 0.65], ...
    'LineWidth',1.5,'DisplayName','Numerical difference');
hold on;
semilogy(t,sameInputBound,'--','Color',[0.15 0.15 0.15], ...
    'LineWidth',1.2,'DisplayName','$e^{-\kappa t/2}$');
xlabel('$t$','Interpreter','latex');
ylabel('$\Vert\delta\beta(t)\Vert_2$','Interpreter','latex');
title('(a) Same input','FontWeight','normal');
legend('Interpreter','latex','Location','southwest','Box','off');
grid on; box on;
set(gca,'FontSize',11,'LineWidth',0.9,'TickLabelInterpreter','latex');
nexttile;
semilogy(t,oldHistoryNorm,'-','Color',[0.78 0.25 0.20], ...
    'LineWidth',1.5,'DisplayName','Different old inputs');
hold on;
semilogy(t,oldHistoryBound,'--','Color',[0.15 0.15 0.15], ...
    'LineWidth',1.2,'DisplayName','Post-cutoff bound');
xline(t(cutoffIndex),':','Color',[0.25 0.25 0.25], ...
    'HandleVisibility','off');
xlabel('$t$','Interpreter','latex');
ylabel('$\Vert\delta\beta(t)\Vert_2$','Interpreter','latex');
title('(b) Old-input forgetting','FontWeight','normal');
legend('Interpreter','latex','Location','southwest','Box','off');
grid on; box on;
set(gca,'FontSize',11,'LineWidth',0.9,'TickLabelInterpreter','latex');
exportgraphics(fig,fullfile(scriptDir,'K0ContractionVerification_20260810.pdf'), ...
    'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'K0ContractionVerification_20260810.png'), ...
    'Resolution',300);
close(fig);

reportFile = fullfile(scriptDir,'K0ContractionAudit_20260810.md');
fid = fopen(reportFile,'w');
assert(fid >= 0,'Could not create contraction audit.');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'# Exact contraction audit at K = 0\n\n');
fprintf(fid,'- Damping: `kappa = %.6g`; coupling: `J = %.6g`.\n',kappa,J0);
fprintf(fid,'- Exact conditional-exponent bound: `-kappa/2 = %.12g`.\n', ...
    theoreticalUpperBound);
fprintf(fid,'- Fitted numerical exponent: `%.12g`.\n',estimatedConditionalExponent);
fprintf(fid,'- Same-input maximum relative error: `%.3e`.\n',sameRelativeError);
fprintf(fid,'- Post-cutoff old-input maximum relative error: `%.3e`.\n', ...
    oldRelativeError);
fprintf(fid,['- The propagation used exact matrix exponentials for each ' ...
    'piecewise-constant input step. Hermitian hopping changes modal ' ...
    'coordinates but not the Euclidean contraction rate.\n']);
fprintf('K0_CONTRACTION_PASS exponent=%.12g relative_error=%.3e\n', ...
    estimatedConditionalExponent,max(sameRelativeError,oldRelativeError));

function betaNext = affineExactStep(beta,u,Delta0,gDelta,F0,gF,J,kappa,dt)
    N = numel(beta);
    H = diag(Delta0+gDelta*u)+J;
    A = -(kappa/2)*eye(N)-1i*H;
    drive = -1i*(F0*ones(N,1)+gF*u);
    augmented = [A,drive; zeros(1,N+1)];
    propagated = expm(augmented*dt)*[beta;1];
    betaNext = propagated(1:N);
end
