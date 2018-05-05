function [expmt]=autoROIs(gui_handles, expmt)
%
% Automatically detects light ROIs on a dark background and extracts
% their centroid coordinates and bounds. This function also detects
% and outputs the orientation of arenas with asymmetry about the
% horizontal axis (eg. Y shaped arenas). The function takes autotracker
% gui gui_handles as an input 
% Inputs

clearvars -except gui_handles expmt
colormap('gray')

gui_notify('running ROI detection',gui_handles.disp_note);
gui_handles.auto_detect_ROIs_pushbutton.Enable = 'off';

%% Define parameters - adjust parameters here to fix tracking and ROI segmentation errors

gui_fig = gui_handles.gui_fig;

% ROI detection parameters 
sigma=0.47;                                 % Sigma expressed as a fraction of the image height
kernelWeight=0.34;                          % Scalar weighting of kernel when applied to the image

%% Setup the camera and/or video object

expmt = getVideoInput(expmt,gui_handles);

%% Grab image for ROI detection and segment out ROIs

clean_gui(gui_handles.axes_handle);
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','Image');

switch expmt.source
    case 'camera'
        trackDat.im = peekdata(expmt.camInfo.vid,1);
    case 'video'
        [trackDat.im, expmt.video] = nextFrame(expmt.video,gui_handles);
end

% Extract green channel if image is RGB
if size(trackDat.im,3) > 1
    trackDat.im=trackDat.im(:,:,2);
end

if isempty(imh)
    imh = imagesc(trackDat.im);
elseif strcmp(imh.CDataMapping,'direct')
   imh.CDataMapping = 'scaled';
end


gui_handles.accept_ROI_thresh_pushbutton.Value = 0;
stop = false;

% Waits for "Accept Threshold" button press from user before accepting
% automatic ROI segmentation

clearvars hRect hText

hRect(1) = rectangle('Position',[0 0 0 0],'EdgeColor','r');
hText(1) = text(0,0,'','Color','b','HorizontalAlignment','Center');
delete(findobj('Type','patch'));
hPatch = patch('Faces',[],'XData',[],'YData',[],...
    'FaceColor','none','EdgeColor','r','Parent',gui_handles.axes_handle);
update_vignetting = false;
nROIs = 0;
tic

while stop~=1
    
    tic
    stop=get(gui_handles.accept_ROI_thresh_pushbutton,'value');

    % query next frame and optionally correct lens distortion
    [trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles);

    % Update threshold value
    ROI_thresh=get(gui_handles.ROI_thresh_slider,'value');

    switch expmt.vignette.mode
        case 'manual'
            % subtract the vignette correction off of the raw image
            if isfield(expmt.vignette,'im')
                trackDat.im = trackDat.im - expmt.vignette.im;
            else
                gauss = buildGaussianKernel(size(trackDat.im,2),...
                    size(trackDat.im,1),sigma,kernelWeight);
                trackDat.im=(uint8(double(trackDat.im).*gauss));
                expmt.vignette.mode = 'auto';
            end
            
        case 'auto'
            % approximate light source as guassian to smooth vignetting
            % for more even illumination and better ROI detection
             
            if update_vignetting 
                expmt.vignette.im = filterVignetting(trackDat.im,ROI_coords(end,:));
            end
            if isfield(expmt.vignette,'im')
                trackDat.im = trackDat.im - expmt.vignette.im;
            elseif ~exist('gauss','var')
                gauss = buildGaussianKernel(size(trackDat.im,2),...
                    size(trackDat.im,1),sigma,kernelWeight);
                trackDat.im=(uint8(double(trackDat.im).*gauss));
            end
            
            
    end
    
    % Extract ROIs from thresholded image
    [ROI_bounds,ROI_coords,~,~,binaryimage] = detect_ROIs(trackDat.im,ROI_thresh);
    update_vignetting = nROIs ~= size(ROI_coords,1) & size(ROI_coords,1) > 0;
    

    % Calculate coords of ROI centers
    [xCenters,yCenters]=ROIcenters(binaryimage,ROI_coords);
    centers=[xCenters,yCenters];

    % Define a permutation vector to sort ROIs from top-right to bottom left
    ROI_tol = gui_fig.UserData.ROI_tol;             % n stdevs from
    [centers,ROI_coords,ROI_bounds] = sortROIs(ROI_tol,centers,ROI_coords,ROI_bounds);

    % detect assymetry about vertical axis
    mazeOri = getMazeOrientation(binaryimage,ROI_coords);
    
    % Display ROIs
    imh.CData = binaryimage;    
    hPatch = displayROIs(hPatch,ROI_coords);
    
    if nROIs > size(ROI_coords,1)
        idx = numel(hText) - (nROIs - size(ROI_coords,1))+1:numel(hText);
        delete(hText(idx));
        hText(idx) = [];
    elseif nROIs < size(ROI_coords,1)
        idx = nROIs+1:size(ROI_coords,1);
        hText(idx) = text(zeros(numel(idx),1),zeros(numel(idx),1),'','Color','b',...
            'HorizontalAlignment','Center','Parent',gui_handles.axes_handle);
    end
    nROIs = size(ROI_coords,1);
    
    cellfun(@updateText,num2cell(hText),num2cell(centers(:,1)'),...
        num2cell(centers(:,2)'),num2cell(1:nROIs),'UniformOutput',false);
    
    % Report frames per sec to GUI
    set(gui_handles.edit_frame_rate,'String',num2str(round(1/toc)));
    drawnow limitrate

end

delete(hPatch);

gui_notify([num2str(size(centers,1)) ' ROIs detected'],gui_handles.disp_note);

% Reset the accept threshold button
set(gui_handles.accept_ROI_thresh_pushbutton,'value',0);

% create a vignette correction image if mode is set to auto
if strcmp(expmt.vignette.mode,'auto') && ~isempty(ROI_coords)
    expmt.vignette.im = filterVignetting(trackDat.im,ROI_coords(end,:));
end

% assign outputs
if ~isempty(ROI_coords)
    expmt.ROI.corners = ROI_coords;
    expmt.ROI.centers = centers;
    expmt.ROI.orientation = mazeOri;
    expmt.ROI.bounds = ROI_bounds;
    expmt.ROI.im = binaryimage;
end

gui_handles.auto_detect_ROIs_pushbutton.Enable = 'on';

function updateText(h,x,y,i)

h.String = num2str(i);
h.Position = [x y 0];

