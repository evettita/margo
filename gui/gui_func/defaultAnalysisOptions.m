function [fields,options,varargout] = defaultAnalysisOptions(varargin)

f = false;
options = struct('disable',true,'handedness',f,'bouts',f,'bootstrap',f,...
    'regress',f,'slide',f,'areathresh',f,'save',true,'raw',f);
options.raw = {};
fields = {'centroid';'time'};
f={'centroid';'time'};
if ~isempty(varargin)
    expmt = varargin{1};
    remove_fields = cellfun(@(x) ~any(strcmp(x,f)),expmt.fields);
    remove_fields = expmt.fields(remove_fields);
    for i=1:numel(remove_fields)
        expmt = rmfield(expmt,remove_fields{i});
    end
    varargout = {expmt};
end
