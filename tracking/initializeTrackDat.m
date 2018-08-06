function trackDat = initializeTrackDat(expmt)

trackDat.fields={'centroid';'area';'time'};  % Define fields for regionprops
trackDat.t = 0;
trackDat.ct = 0;
trackDat.lastFrame = false;

if isfield(expmt.meta.roi,'n')
    nROIs = expmt.meta.roi.n;        % total number of ROIs
    trackDat.tStamp=zeros(nROIs,1);
    nt = expmt.meta.roi.num_traces;
    nr = expmt.meta.roi.n;
    md = expmt.parameters.max_trace_duration;
else
    return
end

trackDat.traces = TracePool(nr, nt, md);
trackDat.candidates = TracePool(nr, 0, md, 'Bounded', false);
switch expmt.meta.track_mode
    case 'multitrack'
        trackDat.centroid = cat(1,trackDat.traces.cen);
    case 'single'
        trackDat.centroid = expmt.meta.roi.centers;
end

% Reference vars
depth = expmt.parameters.ref_depth;       % number of rolling sub references
if ~isempty(fieldnames(expmt.meta.ref))
    trackDat.ref = expmt.meta.ref;
else
    trackDat.ref.cen = cell(expmt.meta.roi.n,1);
    trackDat.ref.cen = arrayfun(@(n) NaN(n,2,depth), nt, 'UniformOutput', false);        
    trackDat.ref.ct = zeros(nROIs, 1);              % Reference number placeholder
    trackDat.ref.t = 0;                             % reference time stamp
    trackDat.ref.last_update = zeros(nROIs,1);
    trackDat.ref.bg_mode = 'light';                 % set reference mode to dark
                                                    % obj on light background
end

% Noise correction vars
if ~isempty(fieldnames(expmt.meta.noise))
    trackDat.px_dist = zeros(10,1);      % distribution of pixels over threshold  
    trackDat.pix_dev = zeros(10,1);      % stdev of pixels over threshold
end
