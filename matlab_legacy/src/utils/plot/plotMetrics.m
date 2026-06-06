function plotMetrics(M, C)
%PLOTMETRICS  Render metrics as a small table-like figure.
figure('Name','Metrics');
uit = uitable('Data', [M.rmse M.mae M.r2], 'ColumnName', {'RMSE','MAE','R^2'}, 'RowName', {'Run'});
uit.Position(3:4) = [300 60];
if ~exist(fullfile(C.exp.saveDir,'figures'),'dir'), mkdir(fullfile(C.exp.saveDir,'figures')); end
saveas(gcf, fullfile(C.exp.saveDir,'figures','metrics.png'));
end