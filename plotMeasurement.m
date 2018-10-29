
function [hFig]=plotMeasurement(tracks_struct,y_fieldName,x_fieldName,colorMap,x_lim,y_lim,x_label,y_label,titlestr,avoidInd)
%This function plots the feature in field 'y_fieldName' within
%'tracks_struct' structure over field 'x_fieldName' (if not specified, the 
%default is "frame").
%Input arguments from x_fieldName to the end are optional, in order to avoid specify
%any of them simply use an empty array [], and the default will be used.
%it avoids NaN values (connects gaps between nan values).
if nargin <10; avoidInd=[]; end
if nargin <9; titlestr=[];end
if nargin <8; y_label=[];end
if nargin <7; x_label=[];end
if nargin <6; y_lim=[];end
if nargin <5; x_lim=[];end
if nargin <4; colorMap=[];end
if nargin <3 || isempty(x_fieldName); x_fieldName='Frame';end

%% for testing
% y_fieldName='int488';
% colorMap='fateColor';
% % y_lim=[min(
% x_lim=[0 (idxSytStart-1)]; %only show frames before sytox treatment

%%
scrsz = get(groot,'ScreenSize');
hFig=figure('Position', [scrsz(3)*0.02 scrsz(4)*0.05 scrsz(3)*0.95 scrsz(4)*0.86]);
hold on
for i=1:length(tracks_struct)
    if ~isempty(avoidInd)
        indx=~isnan(tracks_struct(i).(y_fieldName)) & tracks_struct(i).Treat1_Hours<=avoidInd;
    else
        indx=~isnan(tracks_struct(i).(y_fieldName)); %avoid NaN values
    end
    if ~isempty(colorMap)
        plot(tracks_struct(i).(x_fieldName)(indx), tracks_struct(i).(y_fieldName)(indx),'o-','Color',tracks_struct(i).(colorMap))
    else
        plot(tracks_struct(i).(x_fieldName)(indx), tracks_struct(i).(y_fieldName)(indx),'o-')
    end
end

if ~isempty(colorMap) && isempty(titlestr) 
    titlestr=sprintf('%s per cell over time. colorCoding: %s',y_fieldName,colorMap);
elseif isempty(titlestr)
    titlestr=sprintf('%s per cell as a function of %s',y_fieldName, x_fieldName);
end
title(titlestr);
if ~isempty(x_lim)
    xlim(x_lim);
end
if ~isempty(y_lim)
     ylim(y_lim);
end
if ~isempty(x_label)
    xlabel(x_label);
else
    xlabel(x_fieldName);
end
if ~isempty(y_label)
    ylabel(y_label);
else
    ylabel(y_fieldName);
end
% if ~strcmp(x_fieldName,'Frame')
%     ax = gca;
%     xTickValues=ax.XTick;
%     x_tick_unique=arrayfun(@(Q) unique(Q.(x_fieldName)),tracks_struct,'UniformOutput','False');
% %     x_tick_ind;
%     ax.XTickLabel=x_tick(x_tick_ind);
% %     if exist('xticklabels','builtin') %introduced in matlab version R2016b
% %         xticklabels(x_tick(x_tick_ind));
% %     else        
% end

end