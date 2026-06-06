function saveResults(res, metrics, C, meta)
%SAVERESULTS  Persist artifacts.
saveDir = C.exp.saveDir; if ~exist(saveDir,'dir'), mkdir(saveDir); end
fname = fullfile(saveDir, sprintf('run_%s_%s.mat', C.alg.name, datestr(now,'yyyymmdd_HHMMSS')));
save(fname, 'res','metrics','C','meta','-v7');
end