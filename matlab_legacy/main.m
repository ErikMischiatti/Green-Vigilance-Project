function out = main(varargin)
%MAIN  End-to-end pipeline: load → run → evaluate → plots.
C = config(varargin{:});
log = logger(C);
log.info('Starting main pipeline...');

% 1) Load data
[data, meta] = loadData(C);

% 2) Run core algorithm
res = runAlgorithm(data, C, log);

% 3) Evaluate
metrics = evaluate(res, data, C);

% 4) Plots
plotOverview(res, data, C);
plotMetrics(metrics, C);

% 5) Save
saveResults(res, metrics, C, meta);

log.success('Done.');
if nargout, out = struct('res',res,'metrics',metrics,'cfg',C); end
end