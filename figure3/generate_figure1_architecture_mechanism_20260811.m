%% generate_figure1_architecture_mechanism_20260811.m
% Physical overview aligned with the mechanisms that survive the ablations.

clear; close all; clc;
scriptDir = fileparts(mfilename('fullpath'));

blue = [.12 .39 .68];
green = [.10 .52 .36];
red = [.78 .25 .17];
gold = [.88 .60 .10];
dark = [.18 .18 .20];
gray = [.62 .64 .67];

fig = figure('Color','w','Visible','off','Units','inches', ...
    'Position',[1 1 7.2 5.5]);
tiledlayout(2,2,'Padding','compact','TileSpacing','compact');

% (a) Actual periodic first-, second-, and third-neighbor topology.
ax1 = nexttile; hold(ax1,'on'); axis(ax1,'equal'); axis(ax1,'off');
theta = pi/2-(0:11)'*2*pi/12;
xy = [cos(theta) sin(theta)];
drawEdges(ax1,xy,3,gold,':',0.75);
drawEdges(ax1,xy,2,blue,'--',0.85);
drawEdges(ax1,xy,1,green,'-',1.25);
scatter(ax1,xy(:,1),xy(:,2),34,'w','filled','MarkerEdgeColor',dark, ...
    'LineWidth',0.8);
for q = 1:12
    text(ax1,1.18*xy(q,1),1.18*xy(q,2),sprintf('%d',q), ...
        'HorizontalAlignment','center','FontSize',7.5,'Color',dark);
end
axis(ax1,[-1.45 2.05 -1.35 1.35]);
text(ax1,1.48,.95,'$\times\,3$ copies','Interpreter','latex', ...
    'HorizontalAlignment','center','FontSize',9.5,'FontWeight','bold');
text(ax1,1.48,.55,'shared masked input','HorizontalAlignment','center', ...
    'FontSize',8,'Color',red);
text(ax1,1.48,.20,'$\longrightarrow\ (X,P)$','Interpreter','latex', ...
    'HorizontalAlignment','center','FontSize',9,'Color',blue);
text(ax1,1.48,-.08,'$\longrightarrow\ n$','Interpreter','latex', ...
    'HorizontalAlignment','center','FontSize',9,'Color',gold);
plot(ax1,[-.75 -.45],[-1.26 -1.26],'-','Color',green,'LineWidth',1.3);
plot(ax1,[-.30 0],[-1.26 -1.26],'--','Color',blue,'LineWidth',1.0);
plot(ax1,[.15 .45],[-1.26 -1.26],':','Color',gold,'LineWidth',1.0);
text(ax1,-.60,-1.36,'1st','HorizontalAlignment','center','FontSize',7.5);
text(ax1,-.15,-1.36,'2nd','HorizontalAlignment','center','FontSize',7.5);
text(ax1,.30,-1.36,'3rd','HorizontalAlignment','center','FontSize',7.5);
title(ax1,'(a) Periodic 12-mode network','FontWeight','normal');

% (b) Coherent hopping redistributes the static spectrum into supermodes.
ax2 = nexttile; hold(ax2,'on'); box(ax2,'on'); grid(ax2,'on');
N = 12;
Delta = linspace(-1.05,1.05,N).';
Adj1 = circshift(eye(N),1)+circshift(eye(N),-1);
Adj2 = circshift(eye(N),2)+circshift(eye(N),-2);
Adj3 = circshift(eye(N),3)+circshift(eye(N),-3);
e0 = sort(eig(diag(Delta)));
ec = sort(eig(diag(Delta)+.65*(Adj1+.32*Adj2+.10*Adj3)));
for q = 1:N
    plot(ax2,[1 2],[e0(q) ec(q)],'-','Color',[.82 .84 .86], ...
        'LineWidth',0.7);
end
scatter(ax2,ones(N,1),e0,26,gray,'filled','MarkerEdgeColor','w');
scatter(ax2,2*ones(N,1),ec,30,blue,'filled','MarkerEdgeColor','w');
set(ax2,'XLim',[.55 2.45],'XTick',[1 2], ...
    'XTickLabel',{'uncoupled','J=0.65'});
ylabel(ax2,'supermode frequency (normalized)');
text(ax2,1.03,max(ec)-.15,'$J/\kappa=5.42$','Interpreter','latex', ...
    'FontSize',8.5,'Color',dark);
text(ax2,1.03,max(ec)-.55,'$JT_s=0.447$','Interpreter','latex', ...
    'FontSize',8.5,'Color',dark);
title(ax2,'(b) Coherent supermode mixing','FontWeight','normal');

% (c) Exact contraction: hopping changes orientation, not the loss envelope.
ax3 = nexttile; hold(ax3,'on');
T = readtable(fullfile(scriptDir,'K0ContractionVerification_20260810.csv'));
semilogy(ax3,T.t,T.sameInputNorm,'-','Color',blue,'LineWidth',1.7, ...
    'DisplayName','numerical separation');
semilogy(ax3,T.t,T.sameInputBound,'--','Color',dark,'LineWidth',1.3, ...
    'DisplayName','$e^{-\kappa t/2}$ envelope');
xlabel(ax3,'time');
ylabel(ax3,'$\Vert\delta\beta(t)\Vert_2$','Interpreter','latex');
title(ax3,'(c) Loss-limited fading envelope','FontWeight','normal');
legend(ax3,'Interpreter','latex','Location','southwest','Box','off');
grid(ax3,'on'); box(ax3,'on');

% (d) Observation map: phase-sensitive and phase-insensitive coordinates.
ax4 = nexttile; hold(ax4,'on'); axis(ax4,'equal'); box(ax4,'on'); grid(ax4,'on');
phi = linspace(0,2*pi,300);
plot(ax4,cos(phi),sin(phi),'-','Color',[.75 .77 .80],'LineWidth',1.0);
phases = [pi/7 3*pi/5 7*pi/6];
cols = [blue; red; green];
for q = 1:numel(phases)
    x = cos(phases(q)); y = sin(phases(q));
    quiver(ax4,0,0,x,y,0,'Color',cols(q,:),'LineWidth',1.5, ...
        'MaxHeadSize',0.18);
    scatter(ax4,x,y,34,cols(q,:),'filled','MarkerEdgeColor','w');
end
plot(ax4,[-1.15 1.15],[0 0],'-','Color',[.78 .78 .78],'LineWidth',.7);
plot(ax4,[0 0],[-1.15 1.15],'-','Color',[.78 .78 .78],'LineWidth',.7);
xlabel(ax4,'$X=\sqrt{2}\,\mathrm{Re}\,\beta$','Interpreter','latex');
ylabel(ax4,'$P=\sqrt{2}\,\mathrm{Im}\,\beta$','Interpreter','latex');
text(ax4,0,-1.27,'same $n=|\beta|^2$, distinct phases', ...
    'Interpreter','latex','HorizontalAlignment','center','FontSize',8.5);
axis(ax4,[-1.25 1.25 -1.38 1.25]);
title(ax4,'(d) Observable selects accessible phase','FontWeight','normal');

set([ax1 ax2 ax3 ax4],'FontName','Arial','FontSize',9.5,'LineWidth',.8);
outPdf = fullfile(scriptDir,'Figure1_PhysicalMechanism_20260811.pdf');
outPng = fullfile(scriptDir,'Figure1_PhysicalMechanism_20260811.png');
exportgraphics(fig,outPdf,'ContentType','vector');
exportgraphics(fig,outPng,'Resolution',300);
close(fig);
fprintf('FIGURE1_PHYSICAL_MECHANISM_PASS\n');

function drawEdges(ax,xy,distance,color,lineStyle,lineWidth)
N = size(xy,1);
for q = 1:N
    r = mod(q-1+distance,N)+1;
    if q < r || distance == N/2
        plot(ax,xy([q r],1),xy([q r],2),lineStyle,'Color',color, ...
            'LineWidth',lineWidth);
    end
end
end
