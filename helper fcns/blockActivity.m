function block_indices = blockActivity(speed)

moving = speed > 0.8;
transitions = int8([zeros(size(moving,1),1) diff(moving,1,2)]);

% get activity bout stops
[row,col]=find(transitions==-1);
stops = arrayfun(@(k) blockByID(k,row,col), 1:size(moving,1),'UniformOutput',false);

% get activity bout starts
[row,col]=find(transitions==1);
starts = arrayfun(@(k) blockByID(k,row,col), 1:size(moving,1),'UniformOutput',false);

% get num starts and stops for each animal
nStarts = cell2mat(cellfun(@size,starts(:),'UniformOutput',false));
nStarts=nStarts(:,1);
nStops = cell2mat(cellfun(@size,stops(:),'UniformOutput',false));
nStops=nStops(:,1);

% get the average interframe interval and compute minimum bout length in
% num frames


% filter by bout lengths
block_indices = arrayfun(@filterShortBouts,starts,stops,'UniformOutput',false);



function idx = blockByID(id,r,c)

    idx = c(r==id);
    
    
function idx = filterShortBouts(starts,stops)

    if any(size(starts{:}) ~= size(stops{:}))
        
        % determine which comes first
        start_end = length(starts{:}) > length(stops{:});
       
        if start_end
            starts{:}(end) = [];
        else
            stops{:}(end) = [];
        end
    end
    
    if any(size(starts) ~= size(stops))
        disp('break');
    end

    if length(starts{:})>0 && length(stops{:})>0
        bout_length = abs(starts{:}-stops{:});
        long_bout = bout_length > 15;
        idx = [starts{:}(long_bout) stops{:}(long_bout)];

        if size(idx,1)>1
            % ensure that lower index comes first
            [~,i]=min(idx');
            idx(i==2,:) = idx(i==2,[2 1]);

            % shift indices to get bouts
            idx = [idx;[idx(1:length(idx)-1,2) idx(2:end,1)]];

            bout_length = idx(:,2)-idx(:,1);
            idx(bout_length<30,:)=[];
        end
    else
        idx = [];
    end
    
    
    

        
        