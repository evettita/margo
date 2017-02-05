function varargout = advancedTrackingParam_subgui(varargin)
% ADVANCEDTRACKINGPARAM_SUBGUI MATLAB code for advancedTrackingParam_subgui.fig
%      ADVANCEDTRACKINGPARAM_SUBGUI, by itself, creates a new ADVANCEDTRACKINGPARAM_SUBGUI or raises the existing
%      singleton*.
%
%      H = ADVANCEDTRACKINGPARAM_SUBGUI returns the handle to a new ADVANCEDTRACKINGPARAM_SUBGUI or the handle to
%      the existing singleton*.
%
%      ADVANCEDTRACKINGPARAM_SUBGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ADVANCEDTRACKINGPARAM_SUBGUI.M with the given input arguments.
%
%      ADVANCEDTRACKINGPARAM_SUBGUI('Property','Value',...) creates a new ADVANCEDTRACKINGPARAM_SUBGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before advancedTrackingParam_subgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to advancedTrackingParam_subgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help advancedTrackingParam_subgui

% Last Modified by GUIDE v2.5 04-Feb-2017 13:30:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @advancedTrackingParam_subgui_OpeningFcn, ...
                   'gui_OutputFcn',  @advancedTrackingParam_subgui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT




% --- Executes just before advancedTrackingParam_subgui is made visible.
function advancedTrackingParam_subgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to advancedTrackingParam_subgui (see VARARGIN)

expmt = varargin{1};
param_data = expmt.parameters;

in_handles = varargin{2};
handles.figure1.UserData.gui_handles = in_handles;
handles.figure1.UserData.expmt = expmt;


% Set GUI strings with input parameters
set(handles.edit_speed_thresh,'string',param_data.speed_thresh);
set(handles.edit_dist_thresh,'string',param_data.distance_thresh);
set(handles.edit_target_rate,'string',param_data.target_rate);
set(handles.edit_vignette_sigma,'string',param_data.vignette_sigma);
set(handles.edit_vignette_weight,'string',param_data.vignette_weight);

% Assign current values as default output
handles.figure1.UserData.speed_thresh=str2num(get(handles.edit_speed_thresh,'string'));
handles.figure1.UserData.distance_thresh=str2num(get(handles.edit_dist_thresh,'string'));
handles.figure1.UserData.target_rate=str2num(get(handles.edit_target_rate,'string'));
handles.figure1.UserData.vignette_sigma=str2num(get(handles.edit_vignette_sigma,'string'));
handles.figure1.UserData.vignette_weight=str2num(get(handles.edit_vignette_weight,'string'));

% Update handles structure
guidata(hObject, handles);




% --- Outputs from this function are returned to the command line.
function varargout = advancedTrackingParam_subgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

track_start = boolean(1);
expmt = handles.figure1.UserData.expmt;
gui_handles = handles.figure1.UserData.gui_handles;
display_menu = findobj('Tag','display_menu');
thresh_slider = findobj('Tag','track_thresh_slider');

while ishghandle(hObject)
    
    pause(0.001);
    
    % check if parameter visualization aids are toggled
    disp_speed = get(handles.speed_thresh_radiobutton,'value');
    disp_dist = get(handles.dist_thresh_radiobutton,'value');
    disp_area = get(handles.area_radiobutton,'value');
    
    if disp_speed || disp_dist || disp_area
        
        % start camera if camera is not running
        if isfield(expmt.camInfo,'vid') && strcmp(expmt.camInfo.vid.Running,'off')
            start(expmt.camInfo.vid);
            pause(0.1);
        end
        
        if isfield(expmt.camInfo,'vid') && strcmp(expmt.camInfo.vid.Running,'on')
            imagedata = peekdata(expmt.camInfo.vid,1);
            
            switch display_menu.UserData
                case 1
                    
                    gui_handle.CurrentAxes.CData = imagedata;
                    
                case 2
                    
                    if isfield(expmt,'ref') && isfield(expmt,'vignetteMat')
                    gui_handle.CurrentAxes.CData = ...
                        (expmt.ref-expmt.vignetteMat)-(imagedata-expmt.vignetteMat);
                    else
                        display_menu.UserData = 1;
                        display_menu.Children(5).checked = 'on';
                        display_menu.Children(4).checked = 'off';
                        display_menu.Children(4).enable = 'off';
                    end
                    
                case 3
                    
                    if isfield(expmt,'ref') && isfield(expmt,'vignetteMat')
                        thresh = get(thresh_slider,'value');
                        diffim = (expmt.ref-expmt.vignetteMat)-(imagedata-expmt.vignetteMat);
                        gui_handle.CurrentAxes.CData = diffim > thresh;
                    else
                        display_menu.UserData = 1;
                        display_menu.Children(5).checked = 'on';
                        display_menu.Children(3).checked = 'off';
                        display_menu.Children(3).enable = 'off';
                    end 
                    
            end
            
        end
        
        if track_start
            
            tElapsed=0;
            propFields={'Centroid';'Area'};     % Define fields for regionprops
            
            if isfield(expmt,'ROI') && isfield(expmt.ROI,'centers')
                lastCentroid = expmt.ROI.centers;     % placeholder for most recent non-NaN centroids
            else
                midpoint(1) = sum(gui_handles.CurrentAxes.XLim)/2;
                midpoint(2) = sum(gui_handles.CurrentAxes.YLim)/2;
                lastCentroid = [midpoint(1) midpoint(2)];
            end
            
            % initialize coords
            s_bounds = centerRect(lastCentroid,handles.figure1.UserData.speed_thresh);
            d_bounds = centerRect(lastCentroid,handles.figure1.UserData.distance_thresh);
            mi_bounds = centerRect(lastCentroid,handles.figure1.UserData.area_min);
            ma_bounds = centerRect(lastCentroid,handles.figure1.UserData.area_max);
            
            for i = 1:size(lastCentroid,1)

                spdCirc(i) = rectangle(gui_handles.CurrentAxes,'Position',s_bounds,'EdgeColor',[0 1 0]);
                minCirc(i) = viscircles(gui_handles.CurrentAxes,'Position',mi_bounds,'EdgeColor',[1 0 1]);
                maxCirc(i) = viscircles(gui_handles.CurrentAxes,'Position',ma_bounds,'EdgeColor',[1 0 0]);
                dstCirc(i) = viscircles(gui_handles.CurrentAxes,'Position',d_bounds,'EdgeColor',[0 0 1]);
            end
            
        end
        
        if disp_speed_thresh
                   
            if isfield(expmt,'ref') && isfield(expmt,'vignetteMat')
                
                thresh = get(thresh_slider,'value');
                diffim = (expmt.ref-expmt.vignetteMat)-(imagedata-expmt.vignetteMat);
                        props=regionprops((diffim>imageThresh),propFields);

                % Match centroids to ROIs by finding nearest ROI center
                validCentroids=([props.Area]>4&[props.Area]<120);
                cenDat=reshape([props(validCentroids).Centroid],2,length([props(validCentroids).Centroid])/2)';

                % Match centroids to last known centroid positions
                [cen_permutation,update_centroid]=matchCentroids2ROIs(cenDat,lastCentroid,expmt.ROI.centers,expmt.parameters.distanceThresh);

                % Apply speed threshold to centroid tracking
                if any(update_centroid)
                    d = sqrt([cenDat(cen_permutation,1)-lastCentroid(update_centroid,1)].^2 ...
                        + [cenDat(cen_permutation,2)-lastCentroid(update_centroid,2)].^2);
                    dt = tElapsed-centStamp(update_centroid);
                    speed = d./dt;
                    above_spd_thresh = speed > expmt.parameters.speed_thresh;
                    cen_permutation(above_spd_thresh)=[];
                    update_centroid=find(update_centroid);
                    update_centroid(above_spd_thresh)=[];
                end

                % Use permutation vector to sort raw centroid data and update
                % vector to specify which centroids are reliable and should be updated
                lastCentroid(update_centroid,:)=cenDat(cen_permutation,:);
                centStamp(update_centroid) = tElapsed;
                
                %spdCirc.
                
            else
                
                
                
            end
            
        end
            
            
    end
                
                
    
    % constantly reassign output from the subgui until it closes
    if isprop(handles.figure1,'UserData')
    	varargout{1} = handles.figure1.UserData;
    end
    
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

delete(handles.figure1);






%*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%
%*-*-*-*-*-*-*-*-*-*-*-*-* GUI CALLBACKS *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%
%*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%




function edit_vignette_weight_Callback(hObject, eventdata, handles)
% hObject    handle to edit_vignette_weight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_vignette_weight as text
%        str2double(get(hObject,'String')) returns contents of edit_vignette_weight as a double

handles.figure1.UserData.vignette_weight=str2num(get(handles.edit_vignette_weight,'string'));
guidata(hObject,handles);


function edit_vignette_sigma_Callback(hObject, eventdata, handles)
% hObject    handle to edit_vignette_sigma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_vignette_sigma as text
%        str2double(get(hObject,'String')) returns contents of edit_vignette_sigma as a double

handles.figure1.UserData.vignette_sigma=str2num(get(handles.edit_vignette_sigma,'string'));
guidata(hObject,handles);


function edit_target_rate_Callback(hObject, eventdata, handles)
% hObject    handle to edit29 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit29 as text
%        str2double(get(hObject,'String')) returns contents of edit29 as a double

handles.figure1.UserData.target_rate=str2num(get(handles.edit29,'string'));
guidata(hObject,handles);



function edit_dist_thresh_Callback(hObject, eventdata, handles)
% hObject    handle to edit_dist_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_dist_thresh as text
%        str2double(get(hObject,'String')) returns contents of edit_dist_thresh as a double

handles.figure1.UserData.distance_thresh=str2num(get(handles.edit_dist_thresh,'string'));
guidata(hObject,handles);



function edit_speed_thresh_Callback(hObject, eventdata, handles)
% hObject    handle to edit_speed_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_speed_thresh as text
%        str2double(get(hObject,'String')) returns contents of edit_speed_thresh as a double

handles.figure1.UserData.speed_thresh=str2num(get(handles.edit_speed_thresh,'string'));
guidata(hObject,handles);


% --- Executes on button press in help_button.
function help_button_Callback(hObject, eventdata, handles)
% hObject    handle to help_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

msg_title=['Parameter Info'];
spc=[' '];
item1=['\bfSpeed Threshold\rm - sets the upper bound for maximum allowable frame ' ...
    'to frame speed for centroid tracking and sorting. Centroids that move '...
    'faster than the speed threshold are considered either a frame to '...
    'frame mismatch or false positive due to noise and are dropped for '...
    'the current frame. \it(tip: raise speed '...
    'thresh if tracking appears to lag behind the tracked object).\rm'];

item2=['\bfDistance Threshold\rm - sets the upper bound for maximum allowable frame ' ...
    'to frame distance between an object and the center of its ROI. '...
    'If distance thresh is exceeded between a centroid and its matched ROI, '...
    'the centroid is dropped for the current frame. \it(tip: Lower distance '...
    'thresh if IDs switch between neighboring ROIs).\rm'];

item3=['\bfTarget Acquisition Rate\rm - sets the upper bound for the acquisition ' ...
    'frame rate. This parameter can be used to improve consistency of '...
    'interframe interval (ifi) or lower the acquisition rate to reduce the amount '...
    'of data saved. Setting this parameter to -1 disable this parameter and '...
    'at the maximum possible speed (this will result in less consistent ifi). '...
    '\it(tip: acquisition rates of 5-10Hz are often sufficient and result in '...
    'smaller file sizes).\rm'];

item4=['\bfVignette Gaussian Sigma\rm - defines the standard deviation of a gaussian'...
    ' used to correct for vignetting in illumination. This gaussian is subtracted '...
    'off of the image to achieve more evenly lit ROIs. This strategy is used '...
    'only in the initial detection of ROIs and is not applied to object tracking. '...
    ' Sigma is expressed as a fraction of the image height in pixels \it(tip: '...
    'adjust this parameter if thresholded ROIs are occluded in a circular shape).\rm'];

item5=['\bfVignette Gaussian Weight\rm - sets the weight of the above gaussian ' ...
    'before subtracting it off of the ROI image. Weight is expressed as '...
    'a fraction of the maximum intensity.'];

closing=['See Manual for additional tips and details.'];
message={spc item1 spc item2 spc item3 spc item4 spc item5 spc closing};

% Display info
Opt.Interpreter='tex';
Opt.WindowStyle='normal';
waitfor(msgbox(message,msg_title,'none',Opt));






%*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%
%*-*-*-*-*-*-*-*-*-*-* GUI OBJECT CREATION *-*-*-*-*-*-*-*-*-*-*-*-*-*-*%
%*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%




% --- Executes during object creation, after setting all properties.
function edit_dist_thresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_dist_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edit_vignette_weight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_vignette_weight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edit_vignette_sigma_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_vignette_sigma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edit_target_rate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit29 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function edit_speed_thresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_speed_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_area_min_Callback(hObject, eventdata, handles)
% hObject    handle to edit_area_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.figure1.UserData.area_min = str2num(get(hObject,'string'));
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_area_min_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_area_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_area_max_Callback(hObject, eventdata, handles)
% hObject    handle to edit_area_max (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.figure1.UserData.area_max = str2num(get(hObject,'string'));
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_area_max_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_area_max (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit29_Callback(hObject, eventdata, handles)
% hObject    handle to edit29 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit29 as text
%        str2double(get(hObject,'String')) returns contents of edit29 as a double


% --- Executes during object creation, after setting all properties.
function edit29_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit29 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit30_Callback(hObject, eventdata, handles)
% hObject    handle to edit30 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit30 as text
%        str2double(get(hObject,'String')) returns contents of edit30 as a double


% --- Executes during object creation, after setting all properties.
function edit30_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit30 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in speed_thresh_radiobutton.
function speed_thresh_radiobutton_Callback(hObject, eventdata, handles)
% hObject    handle to speed_thresh_radiobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in distance_thresh_radiobutton.
function distance_thresh_radiobutton_Callback(hObject, eventdata, handles)
% hObject    handle to distance_thresh_radiobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of distance_thresh_radiobutton



% --- Executes on button press in area_radiobutton.
function area_radiobutton_Callback(hObject, eventdata, handles)
% hObject    handle to area_radiobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of area_radiobutton
