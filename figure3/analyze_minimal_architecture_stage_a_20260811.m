%% Aggregate validation-only J/gain selection for the deterministic network.

clear; clc; close all;
scriptDir = fileparts(mfilename('fullpath'));
protocolPath = fullfile(scriptDir,'configs', ...
    'additional_benchmark_protocol_20260811.json');
protocol = jsondecode(fileread(protocolPath));
offsets = protocol.selection_offsets(:).';
Jgrid = protocol.J_grid(:).';
gainGrid = protocol.input_gain_grid(:).';
lambdaGrid = protocol.lambda_grid(:);
nSeed = numel(offsets); nJ = numel(Jgrid); nGain = numel(gainGrid);
curves = nan(nSeed,nJ,nGain,numel(lambdaGrid));

for s = 1:nSeed
    for j = 1:nJ
        for g = 1:nGain
            tag = sprintf('MinimalStageA_S%02d_J%02d_G%02d_Offset%04d_20260811', ...
                s,j,g,offsets(s));
            file = fullfile(scriptDir, ...
                ['Fig3_KerrReservoir_NARMA10_Reproducible_' tag '_summary.mat']);
            assert(isfile(file),'Missing stage-A result: %s',file);
            S = load(file,'cfg','P','results');
            assert(strcmp(S.cfg.protocolMode,'selection') && ~S.cfg.evaluateTest);
            assert(S.cfg.numReservoirs == 1 && ~S.cfg.staticDisorderEnabled);
            assert(abs(S.P.J0-Jgrid(j)) < 1e-14 && ...
                abs(S.cfg.inputGainScale-gainGrid(g)) < 1e-14);
            assert(isnan(S.results.main.NRMSE));
            curve = S.results.main.valCurve(:);
            assert(numel(curve)==numel(lambdaGrid) && all(isfinite(curve)));
            curves(s,j,g,:) = curve;
        end
    end
end

J = nan(nJ*nGain,1); inputGainScale = J; globalLambda = J;
meanValidationNRMSE = J; sdValidationNRMSE = J;
globalValues = nan(nSeed,nJ,nGain);
row = 0;
for j = 1:nJ
    for g = 1:nGain
        row = row+1;
        meanCurve = squeeze(mean(curves(:,j,g,:),1));
        [~,idx] = min(meanCurve);
        values = squeeze(curves(:,j,g,idx));
        globalValues(:,j,g) = values;
        J(row)=Jgrid(j); inputGainScale(row)=gainGrid(g);
        globalLambda(row)=lambdaGrid(idx);
        meanValidationNRMSE(row)=mean(values);
        sdValidationNRMSE(row)=std(values);
    end
end
summary = table(J,inputGainScale,globalLambda,meanValidationNRMSE, ...
    sdValidationNRMSE);
writetable(summary,fullfile(scriptDir, ...
    'MinimalArchitectureStageA_Summary_20260811.csv'));

coupledRows = find(summary.J > 0);
[~,local] = min(summary.meanValidationNRMSE(coupledRows));
selectedRow = coupledRows(local);
selectedJ = summary.J(selectedRow);
selectedGain = summary.inputGainScale(selectedRow);
selectedJIndex = find(abs(Jgrid-selectedJ)<1e-14);
selectedGainIndex = find(abs(gainGrid-selectedGain)<1e-14);
controlRow = find(abs(summary.J)<1e-14 & ...
    abs(summary.inputGainScale-selectedGain)<1e-14);
assert(isscalar(controlRow));

result.schema_version = 1;
result.status = 'stage_a_selection_complete';
result.test_metrics_evaluated = false;
result.protocol_sha256 = sha256File(protocolPath);
result.selection_offsets = offsets;
result.selected.J = selectedJ;
result.selected.input_gain_scale = selectedGain;
result.selected.ridge_lambda = summary.globalLambda(selectedRow);
result.selected.mean_validation_nrmse = ...
    summary.meanValidationNRMSE(selectedRow);
result.selected.sd_validation_nrmse = summary.sdValidationNRMSE(selectedRow);
result.control.J = 0;
result.control.ridge_lambda = summary.globalLambda(controlRow);
result.control.mean_validation_nrmse = summary.meanValidationNRMSE(controlRow);
result.control.sd_validation_nrmse = summary.sdValidationNRMSE(controlRow);
resultFile = fullfile(scriptDir,'configs', ...
    'minimal_architecture_stage_a_result_20260811.json');
writeJson(resultFile,result);

fig = figure('Color','w','Units','inches','Position',[1 1 7.4 4.6]);
hold on;
colors = lines(nGain);
for g = 1:nGain
    means = squeeze(mean(globalValues(:,:,g),1));
    sem = squeeze(std(globalValues(:,:,g),0,1))/sqrt(nSeed);
    errorbar(Jgrid,means,sem,'-o','LineWidth',1.7,'MarkerSize',6, ...
        'Color',colors(g,:),'DisplayName',sprintf('$g=%.2f$',gainGrid(g)));
end
xlabel('$J$','Interpreter','latex'); ylabel('validation NRMSE','Interpreter','latex');
title('Deterministic one-copy selection','Interpreter','latex');
legend('Location','best','Interpreter','latex'); grid on; box on;
set(findall(fig,'-property','FontSize'),'FontSize',11);
exportgraphics(fig,fullfile(scriptDir, ...
    'MinimalArchitectureStageA_20260811.pdf'),'ContentType','vector');
exportgraphics(fig,fullfile(scriptDir, ...
    'MinimalArchitectureStageA_20260811.png'),'Resolution',300);
close(fig);
fprintf(['MINIMAL_STAGE_A_ANALYSIS_PASS J=%.3f gain=%.2f ' ...
    'val=%.6f control=%.6f\n'],selectedJ,selectedGain, ...
    result.selected.mean_validation_nrmse,result.control.mean_validation_nrmse);

function writeJson(path,value)
fid=fopen(path,'w'); assert(fid>=0,'Could not write %s.',path);
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,PrettyPrint=true));
end

function digest = sha256File(path)
engine=java.security.MessageDigest.getInstance('SHA-256');
fid=fopen(path,'rb'); assert(fid>=0); cleanup=onCleanup(@() fclose(fid));
bytes=typecast(engine.digest(fread(fid,Inf,'*uint8')),'uint8');
digest=lower(reshape(dec2hex(bytes,2).',1,[]));
end

