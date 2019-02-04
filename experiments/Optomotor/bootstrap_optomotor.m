function [varargout]=bootstrap_optomotor(expmt,nReps,field)

% Create bootstrapped distribution of occupancy from slow phototaxis data.
% For each bootstrap iteration:
%   1. Choose a fly at random
%   2. Then select a stimulus bout at random
%   3. Repeat the process until the sequence of bouts equals the duration
%      of the experiment.
%   4. Repeat steps 1-3 to create a bootstrapped score for each animal in
%      the experiment to create a distribution of scores to measure both 
%      mean and dispersion.
%   5. Repeat steps 1-4 nReps time to assess the likeliness of the data by
%      random chance.

%% bootstrap sample data

if isfield(expmt,'nTracks')
    nf = expmt.nTracks;
else
    nf = size(expmt.(field).sdist,2);
end

if isfield(expmt.(field),'active')
    expmt.(field).sdist(:,~expmt.(field).active) = [];
    expmt.(field).tdist(:,~expmt.(field).active) = [];
    expmt.(field).n(~expmt.(field).active) = [];
    nf = numel(expmt.(field).n);
end


opto_index = NaN(nReps,nf);

wh = waitbar(0,['iteration 0 out of ' num2str(nReps)]);
wh.Name = 'Bootstrap resampling optomotor data, please wait...';

for j = 1:nReps
    
    if ishghandle(wh)
        waitbar(j/nReps,wh,['iteration ' num2str(j) ' out of ' num2str(nReps)]);
    end
    
    n = expmt.(field).n(randi([1 nf],nf,1));
    ids = arrayfun(@(k) drawIDs(k,nf), n, 'UniformOutput',false);
    
    sd = NaN(max(expmt.(field).n),nf);
    td = NaN(max(expmt.(field).n),nf);
    
    for i = 1:nf
        
        fly_sub = ids{i};
        trial_sub = ceil(expmt.Optomotor.n(fly_sub).*rand(length(i),1));
        trial_sub(trial_sub==0)=1;
        idx = sub2ind(size(expmt.Optomotor.sdist),trial_sub,fly_sub);
        tmp = expmt.Optomotor.sdist(idx);
        sd(1:numel(tmp),i)=tmp;
        tmp = expmt.Optomotor.tdist(idx);
        td(1:numel(tmp),i)=tmp;
        
    end
    
    opto_index(j,:) = nansum(sd)./nansum(td);
    clearvars sd td tmp trial_sub fly_sub idx
    
end
    
if ishghandle(wh)
    close(wh);
end

%%

data = expmt.(field).index;

% create histogram of occupancy scores
binmin=-1;
binmax=1;
w = binmax - binmin;
plt_res = w/(10^floor(log10(nf)));
bins = -1:plt_res:1;
c = histc(opto_index,bins) ./ repmat(sum(histc(opto_index,bins)),numel(bins),1);
[mu,~,ci95,~] = normfit(c');

%% generate plots

f=figure();
hold on

% plot bootstrapped trace
plot(mu,'b','LineWidth',3);
set(gca,'Xtick',-1:0.2:1,'XtickLabel',-1:0.2:1,...
    'XLim',[1 length(mu)],'YLim',[0 ceil(max(ci95(:))*100)/100]);

% plot observed data
c = histc(data,bins) ./ sum(sum(histc(data,bins)));
plot(c,'r','LineWidth',3);
legend({['bootstrapped (nReps = ' num2str(nReps) ')'];['observed (n=' num2str(nf) ')']});
title([field ' index histogram (obs v. bootstrapped)']);
xlabel('Optomotor index');

% add confidence interval patch
vx = [1:length(bins) fliplr(1:length(bins))];
vy = [ci95(1,:) fliplr(ci95(2,:))];
ph = patch(vx,vy,[0 0.9 0.9],'FaceAlpha',0.3);
uistack(ph,'bottom');

for i=1:nargout
    switch i
        case 1, varargout{i} = mu;
        case 2, varargout{i} = data;
        case 3, varargout{i} = f;
    end
end




function ids = drawIDs(n,nf)
    
ids = randi([1 nf],n,1);








