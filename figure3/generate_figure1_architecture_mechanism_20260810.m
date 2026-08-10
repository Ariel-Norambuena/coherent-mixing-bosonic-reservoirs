%% generate_figure1_architecture_mechanism_20260810.m
clear;close all;clc;scriptDir=fileparts(mfilename('fullpath'));
fig=figure('Color','w','Visible','off','Units','inches','Position',[1 1 7.2 5.4]);
tiledlayout(2,2,'Padding','compact','TileSpacing','compact');

ax1=nexttile([1 2]);axis(ax1,[0 1 0 1]);axis(ax1,'off');hold(ax1,'on');
blue=[.15 .40 .68];green=[.12 .55 .38];red=[.78 .26 .18];gold=[.88 .62 .13];dark=[.18 .18 .20];
boxNode(ax1,[.03 .36 .12 .28],blue,'laser','source');
boxNode(ax1,[.20 .30 .16 .40],gold,'EO input','mask + bias');
% Coupled ring array.
rectangle(ax1,'Position',[.43 .17 .25 .66],'Curvature',.04,'EdgeColor',dark,'LineWidth',1.1,'FaceColor',[.97 .97 .97]);
for row=1:3
    for col=1:4
        x=.465+(col-1)*.058;y=.27+(row-1)*.22;
        rectangle(ax1,'Position',[x y .038 .10],'Curvature',[1 1],'EdgeColor',green,'LineWidth',1.5,'FaceColor','w');
        if col<4,plot(ax1,[x+.038 x+.058],[y+.05 y+.05],'-','Color',green,'LineWidth',1);end
        if row<3,plot(ax1,[x+.019 x+.019],[y+.10 y+.22],'-','Color',[.55 .55 .55],'LineWidth',.8);end
    end
end
text(ax1,.555,.91,'12-mode SiN network','HorizontalAlignment','center','FontWeight','bold','FontSize',10);
text(ax1,.555,.08,'coherent hopping $J_{ij}$','Interpreter','latex','HorizontalAlignment','center','FontSize',9);
for col=1:4
    quiver(ax1,.484+(col-1)*.058,.86,0,-.10,0,'Color',red,'LineWidth',1,'MaxHeadSize',.7);
end
text(ax1,.555,.98,'local TFLN detuning control','HorizontalAlignment','center','Color',red,'FontSize',9);
boxNode(ax1,[.74 .30 .13 .40],red,'detection','X/P or n');
boxNode(ax1,[.91 .36 .08 .28],dark,'linear','readout');
drawArrow(ax1,.15,.50,.20,.50,dark);drawArrow(ax1,.36,.50,.43,.50,dark);drawArrow(ax1,.68,.50,.74,.50,dark);drawArrow(ax1,.87,.50,.91,.50,dark);
text(ax1,.01,.96,'(a)','FontWeight','bold','FontSize',11);

ax2=nexttile;hold(ax2,'on');
N=12;Adj1=circshift(eye(N),1)+circshift(eye(N),-1);Adj2=circshift(eye(N),2)+circshift(eye(N),-2);Adj3=circshift(eye(N),3)+circshift(eye(N),-3);
J=.65*(Adj1+.32*Adj2+.10*Adj3);Delta=linspace(-1.05,1.05,N).';mask=[1;-.82;.61;-.95;.74;-.48;.88;-.58;.36;-.70;.52;-.66];G=diag(.9*mask);
H0=diag(Delta)+J;C=abs(H0*G-G*H0);imagesc(ax2,C);axis(ax2,'image');colormap(ax2,'parula');
xlabel(ax2,'mode $j$','Interpreter','latex');ylabel(ax2,'mode $i$','Interpreter','latex');
title(ax2,'(b) $|[H_0,G]_{ij}|$','Interpreter','latex','FontWeight','normal');cb=colorbar(ax2);cb.Label.String='noncommuting weight';

ax3=nexttile;hold(ax3,'on');T=readtable(fullfile(scriptDir,'K0ContractionVerification_20260810.csv'));
semilogy(ax3,T.t,T.sameInputNorm,'-','Color',blue,'LineWidth',1.7,'DisplayName','numerical separation');
semilogy(ax3,T.t,T.sameInputBound,'--','Color',dark,'LineWidth',1.3,'DisplayName','$e^{-\kappa t/2}$ bound');
xlabel(ax3,'time');ylabel(ax3,'$\Vert\delta\beta(t)\Vert_2$','Interpreter','latex');
title(ax3,'(c) Exact contraction at $K=0$','Interpreter','latex','FontWeight','normal');legend(ax3,'Interpreter','latex','Location','southwest','Box','off');grid(ax3,'on');box(ax3,'on');
set([ax2 ax3],'FontName','Arial','FontSize',9.5,'LineWidth',.8);
exportgraphics(fig,fullfile(scriptDir,'Figure1_ArchitectureMechanism_20260810.pdf'),'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'Figure1_ArchitectureMechanism_20260810.png'),'Resolution',300);close(fig);
fprintf('FIGURE1_ARCHITECTURE_MECHANISM_PASS\n');

function boxNode(ax,pos,color,line1,line2)
rectangle(ax,'Position',pos,'Curvature',.05,'FaceColor',[1 1 1],'EdgeColor',color,'LineWidth',1.5);
text(ax,pos(1)+pos(3)/2,pos(2)+.61*pos(4),line1,'HorizontalAlignment','center','FontWeight','bold','FontSize',9,'Color',color);
text(ax,pos(1)+pos(3)/2,pos(2)+.35*pos(4),line2,'HorizontalAlignment','center','FontSize',7.5,'Color',[.25 .25 .25]);
end

function drawArrow(ax,x1,y1,x2,y2,color)
quiver(ax,x1,y1,x2-x1,y2-y1,0,'Color',color,'LineWidth',1.4,'MaxHeadSize',.8);
end
