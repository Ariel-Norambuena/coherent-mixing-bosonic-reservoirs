%% Signal complexity for NARMA10 and coherent phase-channel equalization.

clear;close all;clc;scriptDir=fileparts(mfilename('fullpath'));
rng(20260811,'twister');nSamples=7000;
u=.5*rand(nSamples,1);y=zeros(nSamples,1);
for k=11:nSamples-1,y(k+1)=.3*y(k)+.05*y(k)*sum(y(k-9:k))+1.5*u(k-9)*u(k)+.1;end
[phaseInput,~,phaseTarget,received]=make_phase_channel_dataset_20260811(nSamples,211);
keep=1001:nSamples;u=u(keep);y=y(keep);phaseInput=phaseInput(keep);phaseTarget=phaseTarget(keep);received=received(keep);
yZ=(y-mean(y))/std(y,1);phaseZ=(phaseInput-mean(phaseInput))/std(phaseInput,1);
[fY,pY]=normalizedSpectrum(yZ);[fP,pP]=normalizedSpectrum(phaseZ);
pY=movmean(pY,31);pY=pY/max(pY);pP=movmean(pP,31);pP=pP/max(pP);

blue=[.13 .42 .70];red=[.80 .25 .18];purple=[.45 .28 .68];gray=[.62 .64 .67];
fig=figure('Color','w','Visible','off','Units','inches','Position',[1 1 7.4 5.2]);
tiledlayout(2,2,'Padding','compact','TileSpacing','compact');
ax1=nexttile;hold(ax1,'on');box(ax1,'on');grid(ax1,'on');idx=1:220;
plot(ax1,idx,rescale(u(idx),min(y(idx)),max(y(idx))),'Color',gray,'LineWidth',.8,'DisplayName','input (rescaled)');
plot(ax1,idx,y(idx),'Color',blue,'LineWidth',1.25,'DisplayName','$y_k$');xlabel(ax1,'symbol $k$','Interpreter','latex');ylabel(ax1,'amplitude');title(ax1,'(a) NARMA10 recurrence','FontWeight','normal');legend(ax1,'Interpreter','latex','Location','northeast','Box','off');
ax2=nexttile;hold(ax2,'on');box(ax2,'on');grid(ax2,'on');idx=1:220;
stairs(ax2,idx,.82*phaseTarget(idx),'Color',gray,'LineWidth',.8,'DisplayName','delayed BPSK target');
plot(ax2,idx,phaseInput(idx),'Color',red,'LineWidth',1.05,'DisplayName','$\arg r_k/\pi$');xlabel(ax2,'symbol $k$','Interpreter','latex');ylabel(ax2,'normalized phase');title(ax2,'(b) Coherent phase channel','FontWeight','normal');legend(ax2,'Interpreter','latex','Location','southwest','Box','off');ylim(ax2,[-1.1 1.1]);
ax3=nexttile;hold(ax3,'on');box(ax3,'on');grid(ax3,'on');idx=1:1800;
neg=phaseTarget(idx)<0;scatter(ax3,real(received(idx(neg))),imag(received(idx(neg))),8,blue,'filled','MarkerFaceAlpha',.28,'DisplayName','$s_{k-2}=-1$');scatter(ax3,real(received(idx(~neg))),imag(received(idx(~neg))),8,red,'filled','MarkerFaceAlpha',.28,'DisplayName','$s_{k-2}=+1$');axis(ax3,'equal');xlabel(ax3,'$\mathrm{Re}\,r_k$','Interpreter','latex');ylabel(ax3,'$\mathrm{Im}\,r_k$','Interpreter','latex');title(ax3,'(c) ISI-distorted received field','FontWeight','normal');legend(ax3,'Interpreter','latex','Location','best','Box','off');
ax4=nexttile;hold(ax4,'on');box(ax4,'on');grid(ax4,'on');semilogy(ax4,fY,pY,'Color',blue,'LineWidth',1.25,'DisplayName','NARMA10 target');semilogy(ax4,fP,pP,'Color',purple,'LineWidth',1.25,'DisplayName','received phase');xlabel(ax4,'normalized frequency');ylabel(ax4,'normalized power');title(ax4,'(d) Smoothed periodograms','FontWeight','normal');legend(ax4,'Location','northeast','Box','off');xlim(ax4,[0 .5]);ylim(ax4,[1e-4 1.2]);
set([ax1 ax2 ax3 ax4],'FontName','Arial','FontSize',10.5,'LineWidth',.8);
exportgraphics(fig,fullfile(scriptDir,'Figure3_TaskSignalComplexityExtended_20260811.pdf'),'ContentType','vector');exportgraphics(fig,fullfile(scriptDir,'Figure3_TaskSignalComplexityExtended_20260811.png'),'Resolution',300);close(fig);
trace=table((1:350)',u(1:350),y(1:350),phaseInput(1:350),phaseTarget(1:350),real(received(1:350)),imag(received(1:350)),'VariableNames',{'sample','narmaInput','narmaTarget','receivedPhase','delayedBpskTarget','receivedReal','receivedImag'});writetable(trace,fullfile(scriptDir,'TaskSignalTracesExtended_20260811.csv'));
spectrum=table(fY,pY,pP,'VariableNames',{'normalizedFrequency','narmaNormalizedPower','phaseNormalizedPower'});writetable(spectrum,fullfile(scriptDir,'TaskSignalSpectraExtended_20260811.csv'));
fprintf('TASK_SIGNAL_COMPLEXITY_EXTENDED_PASS\n');

function [frequency,power]=normalizedSpectrum(signal)
n=numel(signal);window=.5-.5*cos(2*pi*(0:n-1)'/(n-1));transform=fft(signal.*window);keep=1:(floor(n/2)+1);power=abs(transform(keep)).^2;power=power/max(power);frequency=(keep'-1)/n;
end
