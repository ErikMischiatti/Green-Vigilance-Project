function [h_base, h_uav, h_ugv] = draw_agents_markers(base_xy, ugv_xy, varargin)
%DRAW_AGENTS_MARKERS  Plot base (★), UAV start (blue X), UGV seeds (magenta o).
%   [h_base,h_uav,h_ugv] = draw_agents_markers(base_xy, ugv_xy, 'Name',Value,...)
%   base_xy: [x y]
%   ugv_xy:  Mx2 (optional). If empty/missing, only base and UAV are drawn.
%
%   Options (Name-Value):
%     'Z'           : scalar z position for markers (default: eps)
%     'Style'       : struct with fields:
%          .base    : {'Marker','*','Color',[0 0 0],'MarkerSize',10,'LineWidth',1.2}
%          .uav     : {'Marker','x','Color',[0 0 1],'MarkerSize',10,'LineWidth',1.5}
%          .ugv     : {'Marker','o','EdgeColor',[1 0 1],'FaceColor',[1 0.6 1],'Size',5}
%     'UseScatter'  : true/false for UGVs (default: true)
%     'Labels'      : true/false – add text labels (default: false)
%     'LabelFontSize': numeric (default: 9)

if nargin < 2, ugv_xy = []; end

% ---- Defaults
zDefault = eps;
style.base = {'Marker','*','Color',[0 0 0],'MarkerSize',10,'LineWidth',1.2};
style.uav  = {'Marker','x','Color',[0 0 1],'MarkerSize',10,'LineWidth',1.5};
style.ugv  = struct('Marker','o','EdgeColor',[1 0 1],'FaceColor',[1 0.6 1],'Size',5);

p = inputParser;
p.addParameter('Z', 0.5, @(x)isnumeric(x)&&isscalar(x)); %0.5 altezza da terra della base
p.addParameter('Style', style, @(s)isstruct(s));
p.addParameter('UseScatter', true, @(x)islogical(x)||ismember(x,[0 1]));
p.addParameter('Labels', false, @(x)islogical(x)||ismember(x,[0 1]));
p.addParameter('LabelFontSize', 9, @(x)isnumeric(x)&&isscalar(x));
p.parse(varargin{:});
Z          = p.Results.Z;
style      = p.Results.Style;
useScatter = logical(p.Results.UseScatter);
addLabels  = logical(p.Results.Labels);
labFS      = p.Results.LabelFontSize;

% ---- Validate inputs
base_xy = base_xy(:).';
if numel(base_xy) ~= 2
    error('draw_agents_markers:base_xy','base_xy must be 1x2 [x y].');
end
if ~isempty(ugv_xy) && size(ugv_xy,2) ~= 2
    error('draw_agents_markers:ugv_xy','ugv_xy must be Mx2.');
end

% ---- Hold handling
wasHold = ishold;
hold on;

% ---- Base
h_base = plot3(base_xy(1), base_xy(2), Z, ...
    style.base{:}, 'DisplayName','Base', 'Tag','agent_base');

% ---- UAV (at base)
h_uav  = plot3(base_xy(1), base_xy(2), Z, ...
    style.uav{:}, 'DisplayName','UAV start', 'Tag','agent_uav');

% ---- UGVs
h_ugv = gobjects(0);
if ~isempty(ugv_xy)
    if useScatter
        h_ugv = scatter3(ugv_xy(:,1), ugv_xy(:,2), Z*ones(size(ugv_xy,1),1), ...
            style.ugv.Size, 'filled', ...
            'Marker', style.ugv.Marker, ...
            'MarkerEdgeColor', style.ugv.EdgeColor, ...
            'MarkerFaceColor', style.ugv.FaceColor, ...
            'DisplayName','UGV seeds', 'Tag','agent_ugv');
    else
        h_ugv = plot3(ugv_xy(:,1), ugv_xy(:,2), Z*ones(size(ugv_xy,1),1), ...
            style.ugv.Marker, 'MarkerSize', style.ugv.Size, ...
            'MarkerEdgeColor', style.ugv.EdgeColor, ...
            'MarkerFaceColor', style.ugv.FaceColor, ...
            'LineStyle','none', 'DisplayName','UGV seeds', 'Tag','agent_ugv');
    end
end

% ---- Optional labels
if addLabels
    text(base_xy(1), base_xy(2), Z, '  Base', 'FontSize', labFS, 'Color',[0 0 0], 'VerticalAlignment','bottom');
    text(base_xy(1), base_xy(2), Z, '  UAV',  'FontSize', labFS, 'Color',[0 0 1], 'VerticalAlignment','top');
    if ~isempty(ugv_xy)
        for i=1:size(ugv_xy,1)
            text(ugv_xy(i,1), ugv_xy(i,2), Z, sprintf('  UGV%d',i), 'FontSize', labFS, ...
                 'Color',[0.6 0 0.6], 'VerticalAlignment','bottom');
        end
    end
end

% ---- Restore hold
if ~wasHold, hold off; end
end
