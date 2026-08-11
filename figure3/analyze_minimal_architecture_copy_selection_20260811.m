%% Select the smallest deterministic copy count and freeze the fresh test.

clear; clc; close all;
scriptDir=fileparts(mfilename('fullpath'));
protocolPath=fullfile(scriptDir,'configs','additional_benchmark_protocol_20260811.json');
stageAPath=fullfile(scriptDir,'configs','minimal_architecture_stage_a_result_20260811.json');
protocol=jsondecode(fileread(protocolPath)); stageA=jsondecode(fileread(stageAPath));
offsets=protocol.selection_offsets(:).'; copies=protocol.copy_grid(:).';
lambdaGrid=protocol.lambda_grid(:); nSeed=numel(offsets); nCopy=numel(copies);
curves=nan(nSeed,nCopy,numel(lambdaGrid));
for s=1:nSeed
    for c=1:nCopy
        tag=sprintf('MinimalCopy_S%02d_C%02d_Offset%04d_20260811',s,copies(c),offsets(s));
        file=fullfile(scriptDir,['Fig3_KerrReservoir_NARMA10_Reproducible_' tag '_summary.mat']);
        assert(isfile(file),'Missing copy result %s.',file);
        S=load(file,'cfg','P','results');
        assert(strcmp(S.cfg.protocolMode,'selection') && S.cfg.numReservoirs==copies(c));
        assert(abs(S.P.J0-stageA.selected.J)<1e-14 && ~S.cfg.staticDisorderEnabled);
        curves(s,c,:)=S.results.main.valCurve(:);
    end
end
globalLambda=nan(nCopy,1);meanValidationNRMSE=globalLambda;sdValidationNRMSE=globalLambda;
values=nan(nSeed,nCopy);
for c=1:nCopy
    meanCurve=squeeze(mean(curves(:,c,:),1));[~,idx]=min(meanCurve);
    globalLambda(c)=lambdaGrid(idx);values(:,c)=squeeze(curves(:,c,idx));
    meanValidationNRMSE(c)=mean(values(:,c));sdValidationNRMSE(c)=std(values(:,c));
end
summary=table(copies(:),globalLambda,meanValidationNRMSE,sdValidationNRMSE, ...
    'VariableNames',{'copies','globalLambda','meanValidationNRMSE','sdValidationNRMSE'});
writetable(summary,fullfile(scriptDir,'MinimalArchitectureCopySelection_20260811.csv'));
[seedIndex,copyIndex]=ndgrid((1:nSeed)',(1:nCopy)');
seedOffset=offsets(seedIndex(:));seedOffset=seedOffset(:);
copyCount=copies(copyIndex(:));copyCount=copyCount(:);
validationNRMSE=values(:);
raw=table(seedIndex(:),seedOffset,copyCount,validationNRMSE, ...
    'VariableNames',{'selectionIndex','seedOffset','copies','validationNRMSE'});
writetable(raw,fullfile(scriptDir, ...
    'MinimalArchitectureCopySelection_Raw_20260811.csv'));
eligible=find(meanValidationNRMSE<=min(meanValidationNRMSE)+protocol.absolute_tie_tolerance);
[~,i]=min(copies(eligible));selected=eligible(i);

locked.schema_version=1;locked.status='frozen_not_executed';
locked.created_date='2026-08-11';locked.protocol_sha256=sha256File(protocolPath);
locked.stage_a_sha256=sha256File(stageAPath);locked.K=protocol.K;
locked.J_control=0;locked.J_intervention=stageA.selected.J;
locked.input_gain_scale=stageA.selected.input_gain_scale;
locked.num_reservoirs=copies(selected);locked.steps_per_sample=protocol.steps_per_sample;
locked.virtual_node_indices=protocol.virtual_node_indices(:).';
locked.tap_delays=protocol.tap_delays(:).';locked.n_pc=protocol.n_pc;
locked.readout_coefficients_including_bias=protocol.readout_coefficients_including_bias;
locked.ridge_lambda_control=stageA.control.ridge_lambda;
locked.ridge_lambda_intervention=globalLambda(selected);
locked.input_mask=protocol.input_mask(:);locked.input_bias=protocol.input_bias(:);
locked.locked_offsets=protocol.fresh_narma_offsets(:).';
locked.selection_offsets=offsets;
locked.selection_mean_nrmse=meanValidationNRMSE(selected);
locked.selection_sd_nrmse=sdValidationNRMSE(selected);
locked.copy_tie_tolerance=protocol.absolute_tie_tolerance;
lockedFile=fullfile(scriptDir,'configs','minimal_architecture_locked_config_20260811.json');
writeFrozenJson(lockedFile,locked);

fig=figure('Color','w','Units','inches','Position',[1 1 5.7 4.3]);
errorbar(copies,meanValidationNRMSE,sdValidationNRMSE/sqrt(nSeed),'-o', ...
    'LineWidth',1.8,'MarkerSize',7);grid on;box on;xticks(copies);
xlabel('deterministic reservoir copies');ylabel('validation NRMSE');
title('Copy-count ablation at selected $J$ and gain','Interpreter','latex');
set(findall(fig,'-property','FontSize'),'FontSize',11);
exportgraphics(fig,fullfile(scriptDir,'MinimalArchitectureCopySelection_20260811.pdf'),'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir,'MinimalArchitectureCopySelection_20260811.png'),'Resolution',300);close(fig);
fprintf('MINIMAL_COPY_ANALYSIS_PASS copies=%d J=%.3f val=%.6f hash=%s\n', ...
    copies(selected),locked.J_intervention,meanValidationNRMSE(selected),sha256File(lockedFile));

function writeFrozenJson(path,value)
text=[jsonencode(value,PrettyPrint=true) newline];
if isfile(path),assert(strcmp(fileread(path),text),'Frozen locked config differs.');
else,fid=fopen(path,'w');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));fprintf(fid,'%s',text);end
hash=sha256File(path);checksum=sprintf('%s  %s\n',hash,string(extractAfter(path,filesep)));
checksumPath=[path '.sha256'];
if isfile(checksumPath),assert(strcmp(fileread(checksumPath),checksum),'Checksum differs.');
else,fid=fopen(checksumPath,'w');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));fprintf(fid,'%s',checksum);end
end
function digest=sha256File(path)
engine=java.security.MessageDigest.getInstance('SHA-256');fid=fopen(path,'rb');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));bytes=typecast(engine.digest(fread(fid,Inf,'*uint8')),'uint8');digest=lower(reshape(dec2hex(bytes,2).',1,[]));
end
