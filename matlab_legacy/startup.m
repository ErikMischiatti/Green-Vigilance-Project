function startup
%STARTUP  Set MATLAB path for this project.
root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(root,'src')));
addpath(fullfile(root));
fprintf('[startup] Path set for %s\n', root);
end