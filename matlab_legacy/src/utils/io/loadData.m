function [data, meta] = loadData(C)
%LOADDATA  Load or synthesize dataset.
rawDir = C.data.rawDir; procDir = C.data.procDir;
if ~exist(procDir,'dir'), mkdir(procDir); end

% Placeholder: synthesize small dataset if none exists
if ~exist(rawDir,'dir') || isempty(dir(fullfile(rawDir,'*.mat')))
    rng(C.exp.seed);
    X = randn(200,3); y = X*[0.5;-1;0.3] + 0.1*randn(200,1);
    data = struct('X',X,'y',y);
    meta  = struct('source','synthetic');
else
    S = dir(fullfile(rawDir,'*.mat')); load(fullfile(rawDir,S(1).name),'data');
    meta  = struct('source','file','file',S(1).name);
end

if C.data.cache
    save(fullfile(procDir,'cache_data.mat'),'data','-v7');
end
end