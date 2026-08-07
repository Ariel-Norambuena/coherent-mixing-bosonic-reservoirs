%% plot_final_narma_from_cache_20260807.m
% Rebuild the final NARMA10 diagnostic and Kerr-sweep figures from the
% compact summary MAT files, without rerunning the physical simulations.

clear;
close all;
clc;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

fontSize = 11;
blue = [0.00 0.45 0.74];
red = [0.72 0.22 0.20];
dark = [0.10 0.10 0.10];

%% NARMA10 diagnostic
mainFile = fullfile(scriptDir, ...
    'Fig3_KerrReservoir_NARMA10_EnsembleMasked_summary.mat');
if ~isfile(mainFile)
    mainFile = fullfile(scriptDir, ...
        'Fig3_KerrReservoir_NARMA10_Reproducible_summary.mat');
end
assert(isfile(mainFile),'Missing summary file: %s',mainFile);
S = load(mainFile,'cfg','uN','betaFinalAll','results');
assert(isfield(S.results,'main'),'Main NARMA10 result is missing.');

main = S.results.main;
fig = figure('Color','w','Visible','off','Units','inches', ...
    'Position',[1 1 7.2 5.2]);
tiles = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');

ax = nexttile(tiles,1);
hold(ax,'on'); box(ax,'on');
traceLen = min(450,numel(S.uN));
plot(ax,S.uN(1:traceLen),'Color',dark,'LineWidth',1.1);
intensityTraces = abs(S.betaFinalAll(1:traceLen,1:min(4,size(S.betaFinalAll,2)))).^2;
plot(ax,rescale(intensityTraces,0,0.5),'LineWidth',0.9);
xlabel(ax,'input step $k$','Interpreter','latex');
ylabel(ax,'normalized signal','Interpreter','latex');
title(ax,'(a) Input and reservoir intensities','FontWeight','normal');

ax = nexttile(tiles,2);
hold(ax,'on'); box(ax,'on');
semilogx(ax,S.cfg.lambdaGrid,main.valCurve,'o-','Color',blue, ...
    'LineWidth',1.2,'MarkerSize',4);
xline(ax,main.lambdaBest,'--','Color',red,'LineWidth',1.1);
xlabel(ax,'ridge penalty $\lambda_{\rm R}$','Interpreter','latex');
ylabel(ax,'validation NRMSE','Interpreter','latex');
title(ax,'(b) Readout selection','FontWeight','normal');

ax = nexttile(tiles,3);
hold(ax,'on'); box(ax,'on');
testTraceLen = min(450,numel(main.Yte));
plot(ax,main.Yte(1:testTraceLen),'Color',dark,'LineWidth',1.2, ...
    'DisplayName','target');
plot(ax,main.Yhat(1:testTraceLen),'--','Color',blue,'LineWidth',1.2, ...
    'DisplayName','bosonic reservoir');
if isfield(S.results,'inputOnly')
    plot(ax,S.results.inputOnly.Yhat(1:testTraceLen),':','Color',red, ...
        'LineWidth',1.2,'DisplayName','input-only delays');
end
legend(ax,'Location','best','Box','off');
xlabel(ax,'test step','Interpreter','latex');
ylabel(ax,'NARMA10 target','Interpreter','latex');
title(ax,'(c) Direct test prediction','FontWeight','normal');

ax = nexttile(tiles,4);
hold(ax,'on'); box(ax,'on');
labels = {'full','no taps','input only','$K=0$','$J=0$'};
values = [main.NRMSE,S.results.noTap.NRMSE,S.results.inputOnly.NRMSE, ...
    S.results.noK.NRMSE,S.results.noJ.NRMSE];
bar(ax,values,'FaceColor',blue,'LineWidth',0.8);
set(ax,'XTick',1:numel(labels),'XTickLabel',labels, ...
    'TickLabelInterpreter','latex');
xtickangle(ax,20);
ylabel(ax,'test NRMSE','Interpreter','latex');
title(ax,'(d) Physical and readout ablations','FontWeight','normal');

allAxes = findall(fig,'Type','axes');
set(allAxes,'FontName','Arial','FontSize',fontSize,'LineWidth',0.8, ...
    'TickLabelInterpreter','latex');
exportgraphics(fig,fullfile(scriptDir,'Fig3_NARMA10_EnsembleMasked.pdf'), ...
    'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'Fig3_NARMA10_EnsembleMasked.png'), ...
    'Resolution',300);
close(fig);

%% Independent Kerr sweep
sweepFile = fullfile(scriptDir, ...
    'Fig3_KerrReservoir_NARMA10_Reproducible_KSweepFull_20260706_summary.mat');
assert(isfile(sweepFile),'Missing summary file: %s',sweepFile);
Kdata = load(sweepFile,'results');
assert(isfield(Kdata.results,'KSweep'),'K-sweep result is missing.');
sweep = Kdata.results.KSweep;
[K,order] = sort(sweep.K);

fig = figure('Color','w','Visible','off','Units','inches', ...
    'Position',[1 1 7.2 4.8]);
tiles = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');

ax = nexttile(tiles,1);
plot(ax,K,sweep.NRMSE(order),'o-','Color',blue,'MarkerFaceColor','w', ...
    'LineWidth',1.4,'MarkerSize',5);
xline(ax,0,':','Color',red,'LineWidth',1.1);
xlabel(ax,'Kerr coefficient $K$','Interpreter','latex');
ylabel(ax,'test NRMSE','Interpreter','latex');
title(ax,'(a) Test error','FontWeight','normal');
grid(ax,'on'); box(ax,'on');

ax = nexttile(tiles,2);
plot(ax,K,sweep.valNRMSE(order),'o-','Color',blue,'MarkerFaceColor','w', ...
    'LineWidth',1.4,'MarkerSize',5);
xline(ax,0,':','Color',red,'LineWidth',1.1);
xlabel(ax,'Kerr coefficient $K$','Interpreter','latex');
ylabel(ax,'validation NRMSE','Interpreter','latex');
title(ax,'(b) Validation error','FontWeight','normal');
grid(ax,'on'); box(ax,'on');

ax = nexttile(tiles,3);
plot(ax,K,sweep.R2true(order),'o-','Color',blue,'MarkerFaceColor','w', ...
    'LineWidth',1.4,'MarkerSize',5);
xline(ax,0,':','Color',red,'LineWidth',1.1);
xlabel(ax,'Kerr coefficient $K$','Interpreter','latex');
ylabel(ax,'test $R^2$','Interpreter','latex');
title(ax,'(c) Explained variance','FontWeight','normal');
grid(ax,'on'); box(ax,'on');

ax = nexttile(tiles,4);
plot(ax,K,sweep.maxAbsBeta(order),'o-','Color',blue,'MarkerFaceColor','w', ...
    'LineWidth',1.4,'MarkerSize',5);
xline(ax,0,':','Color',red,'LineWidth',1.1);
xlabel(ax,'Kerr coefficient $K$','Interpreter','latex');
ylabel(ax,'maximum $|\beta|$','Interpreter','latex');
title(ax,'(d) State-amplitude diagnostic','FontWeight','normal');
grid(ax,'on'); box(ax,'on');

allAxes = findall(fig,'Type','axes');
set(allAxes,'FontName','Arial','FontSize',fontSize,'LineWidth',0.8, ...
    'TickLabelInterpreter','latex');
exportgraphics(fig,fullfile(scriptDir,'Fig3_KSweepFull_20260706.pdf'), ...
    'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'Fig3_KSweepFull_20260706.png'), ...
    'Resolution',300);
close(fig);

fprintf('Rebuilt final NARMA10 and K-sweep figures from cached summaries.\n');
