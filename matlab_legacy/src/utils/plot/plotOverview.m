function plotOverview(res, data, C)
%PLOTOVERVIEW  Basic diagnostic figure.
figure('Name','Overview');
subplot(1,2,1); plot(data.y, res.yhat, '.'); xlabel('y'); ylabel('yhat'); grid on; axis equal; title('Pred vs True');
subplot(1,2,2); histogram(res.yhat - data.y); xlabel('error'); title('Residuals'); grid on;
if ~exist(fullfile(C.exp.saveDir,'figures'),'dir'), mkdir(fullfile(C.exp.saveDir,'figures')); end
saveas(gcf, fullfile(C.exp.saveDir,'figures','overview.png'));
end