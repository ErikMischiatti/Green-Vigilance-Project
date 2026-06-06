function log = logger(C)
%LOGGER  Lightweight structured logger.
pfx = sprintf('[%s] ', datestr(now,'HH:MM:SS'));
log.info    = @(msg,varargin) fprintf([pfx 'INFO: '    msg '\n'], varargin{:});
log.warn    = @(msg,varargin) fprintf(2, [pfx 'WARN: ' msg '\n'], varargin{:});
log.error   = @(msg,varargin) fprintf(2, [pfx 'ERR: '  msg '\n'], varargin{:});
log.success = @(msg,varargin) fprintf([pfx 'OK: '      msg '\n'], varargin{:});
if isfield(C,'exp') && isfield(C.exp,'verbose') && C.exp.verbose==false
    log.info = @(varargin) []; % silence info if needed
end
end