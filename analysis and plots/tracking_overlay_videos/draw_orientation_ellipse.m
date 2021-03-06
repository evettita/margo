function handles = draw_orientation_ellipse(expmt, frame_num, varargin)
% draw an ellipse on each tracked object in tracking overlay video
%
% Inputs
%   expmt       - ExperimentData for the tracking session
%   frame_num   - index of the acquisition frame
%   varargin
%       handles - handles to update (leave blank to initialize handles)
%       options - struct of plotting options (leave blank to use defaults)
% Outputs
%   handles - struct of plot handles
%
% Plotting Options
%   These struct fields are name value pairs for the various plots below.
%   Eeach field should take the form of a cell array of name value pairs
%   (eg. options.heading = {'Color'; 'r'; 'MarkerSize', ...}
%
%   heading     - Name-Value pairs for heading indicator plot (type=line)
%   ellipse     - Name-Value pairs for ellipse patch plot (type=patch)
%   major_axis  - Name-Value pairs for major axis plot (type=line)
%   minor_axis  - Name-Value pairs for minor axis plot (type=line)
%

% parse inputs
handles = struct();
options = struct();
for i=1:numel(varargin)
    switch i
        case 1, handles = varargin{i};
        case 2, options = varargin{i};
    end
end

% set any missing options to defaults
options = set_options(options);

% assert that necessary fields exist
if ~any(strcmpi('orientation', expmt.meta.fields))
    error('Cannot draw orientation ellipse. No orientation field in expmt.');
end
if ~any(strcmpi('Direction', expmt.meta.fields))
    error('Cannot draw head/tail markers. No heading direction field in expmt.');
end

% reset all data maps
reset(expmt);

% get orientation, heading direction
ori = expmt.meta.ori(frame_num,:);
hdir = expmt.meta.hdir(frame_num,:);


% set major/minor axis length and compute eccentricity of ellipse
mil = expmt.meta.mi(frame_num,:);
mal = expmt.meta.ma(frame_num,:);
foci = sqrt(diff((0.5.*[mil;mal]).^2));
eccentricity = foci./sqrt(foci.^2+(mil./2).^2);

% compute major axis vertices for each ellipse
ang = ori.*pi./180;
cen = num2cell(expmt.data.centroid.raw(frame_num,:,:)',2);
ma_vertices = arrayfun(@(c,a,mal) repmat(c{1},2,1) + [1;-1]*((mal/2).*[cos(a) sin(a)]),...
    cen, ang', mal', 'UniformOutput',false);
mi_vertices = arrayfun(@(c,a,mil) repmat(c{1},2,1) + [1;-1]*((mil/2).*[cos(a) sin(a)]),...
    cen, ang'+pi/2, mil', 'UniformOutput',false);

% initialize coordinates of ellipse patches for drawing
[vx, vy] = cellfun(@(mav, e) ellipse_coords(mav, e),...
    ma_vertices, num2cell(eccentricity)', 'UniformOutput', false);

% draw patches
hold on
if ~isfield(handles,'ellipse') || isempty(handles.ellipse)
    handles.ellipse = patch('XData', cat(2,vx{:}), 'YData', cat(2,vy{:}),...
        options.ellipse{:});
else
    handles.ellipse.XData = cat(2,vx{:});
    handles.ellipse.YData = cat(2,vy{:});
end

% get major and minor axis lines
ma_line = cellfun(@(mav) cat(1,mav,NaN(1,2)), ma_vertices, 'UniformOutput', false);
ma_line = cat(1,ma_line{:});
mi_line = cellfun(@(miv) cat(1,miv,NaN(1,2)), mi_vertices, 'UniformOutput', false);
mi_line = cat(1,mi_line{:});

% plot major axis line
if ~isfield(handles,'major_axis') || isempty(handles.major_axis)
    handles.major_axis = plot(ma_line(:,1), ma_line(:,2), options.major_axis{:});
else
    handles.major_axis.XData = ma_line(:,1);
    handles.major_axis.YData = ma_line(:,2);
end

% plot minor axis line
if ~isfield(handles,'minor_axis') || isempty(handles.minor_axis)
    handles.minor_axis = plot(mi_line(:,1), mi_line(:,2), options.minor_axis{:});
else
    handles.minor_axis.XData = mi_line(:,1);
    handles.minor_axis.YData = mi_line(:,2);
end

% find vertex closest to heading direction
[~,head_idx] = min(abs([1;1]*hdir - [1;-1]*ang));
% [~,tail_idx] = max(abs([1;1]*hdir - [1;-1]*ang));

% record positions
head_coords = arrayfun(@(mav,i) mav{1}(i,:),...
    ma_vertices', head_idx,'UniformOutput',false);
head_coords = cat(1,head_coords{:});
% tail_coords = arrayfun(@(mav,i) mav{1}(i,:),...
%     ma_vertices', tail_idx,'UniformOutput',false);
% tail_coords = cat(1,tail_coords{:});

% plot head and tail
if ~isfield(handles,'heading') || isempty(handles.heading)
    handles.heading = ...
        plot(head_coords(:,1),head_coords(:,2),'o','MarkerSize',2.5,...
        'MarkerFaceColor','m','MarkerEdgeColor','none');
else
    handles.heading.XData = head_coords(:,1);
    handles.heading.YData = head_coords(:,2);
end
% plot(ax_handle,tail_coords(:,1),tail_coords(:,2),'o','MarkerSize',2.5,...
%     'MarkerFaceColor','m','MarkerEdgeColor','none');



% initialize patch coordinates for ellipses
function [X_out, Y_out] = ellipse_coords(ma_vert, e)

a = 1/2*sqrt(sum(diff(ma_vert).^2));
b = a*sqrt(1-e^2);
t = linspace(0,2*pi,30);
X = a*cos(t);
Y = b*sin(t);
w = atan2(diff(ma_vert(:,2)),diff(ma_vert(:,1)));

X_out = sum(ma_vert(:,1))/2 + X*cos(w) - Y*sin(w);
Y_out = sum(ma_vert(:,2))/2 + X*sin(w) + Y*cos(w);
X_out = X_out';
Y_out = Y_out';


function options = set_options(options)

if ~isfield(options,'ellipse') || isempty(options.ellipse)
    options.ellipse = {'EdgeColor'; 'b'; 'LineWidth'; 0.5; ...
        'FaceColor'; 'none'};
end
if ~isfield(options,'major_axis') || isempty(options.major_axis)
    options.major_axis = {'Color'; 'b'; 'LineWidth'; 0.5};
end
if ~isfield(options,'minor_axis') || isempty(options.minor_axis)
    options.minor_axis = {'Color'; 'b'; 'LineWidth'; 0.5};
end
if ~isfield(options,'heading') || isempty(options.heading)
    options.heading = {'o'; 'MarkerSize'; 2.5; ...
        'MarkerFaceColor'; 'm'; 'MarkerEdgeColor'; 'none'};
end


