%% Combine the results from the different treatments

%% cleanup
clc; 
clear;
close all;
saveFlag=1;

%%
% cd('D:/aviam/Box Sync/Vardi data (don''t sync)/Avia/2-protocols and tools/imageAnalysis/matlab/itria'); %only on Avia's computer.
owd=pwd;%original working directory
if(~isdeployed);  cd(fileparts(which('combineResults.m')));  end %switch directory to that of the source script

%% load variables
[varsDataName,varsDataPath] = uigetfile({'vars.mat';'*.mat'},'Choose "vars" file');
load([varsDataPath,'/',varsDataName],'vars');
oldPath=cd(varsDataPath);
%% choose folder for output
ouput_folder = uigetdir([],'Choose folder for the output'); 
cd(ouput_folder);

%% load all the data files
j=0; %file count initiation
loadAnswer='Yes';
s = warning('error', 'MATLAB:load:variableNotFound'); %change the warning to an error when the variable is not found

while strcmp(loadAnswer,'Yes')
    try %try to upload the next file
        [TrackDataName,TrackDataPath] = uigetfile({'TrackData.mat';'*.mat'},'Choose the next "TrackData" file');
        load([TrackDataPath,'/',TrackDataName],'tracks_analysis')
    catch
        warning('Couldn''t load file, please try again');        
        qstring = 'Do you want to load more files?';
        loadAnswer = questdlg(qstring,'Load Track Data');
        waitfor(loadAnswer);
        continue;
    end
    
    j=j+1; %file count
    %get file-specific statistics
    try
        live_count(j)=sum(arrayfun(@(Q) strcmp(Q.cellFate,'live'),tracks_analysis));
        dead_count(j)=sum(arrayfun(@(Q) strcmp(Q.cellFate,'dead'),tracks_analysis));
        unknown_count(j)=sum(arrayfun(@(Q) strcmp(Q.cellFate,'unknown'),tracks_analysis));
    catch
        warning('there was a problem with cell fate determination');
    end
% N_cells(j)=live_count(j)+dead_count(j);
% deadFraction(j)=dead_count(j)/N_cells(j);
    file_ID{j} = inputdlg({'Enter file ID name (number or string):'},'file ID name input',1,{'0'});
    for i=1:length(tracks_analysis)
        tracks_analysis(i).fileID=file_ID{j};
    end
    
    if j==1 %first file
        combined_tracks=tracks_analysis; %create the combined_tracks
    else %the rest of the files     
        combined_tracks=[combined_tracks;tracks_analysis];
    end

    qstring = 'Do you want to load more files?';
    loadAnswer = questdlg(qstring,'Load Track Data');
    waitfor(loadAnswer);
    clear tracks_analysis;
    cd(TrackDataPath);
end

% clear tracks_analysis;
cd(ouput_folder);
warning(s); %cahnge back the warning into a warning

%% Get statistics of the total number of cells

%per file
N_cells=live_count+dead_count;
deadFraction=dead_count./N_cells;

%combined files
live_count_total=sum(arrayfun(@(Q) strcmp(Q.cellFate,'live'),combined_tracks));
dead_count_total=sum(arrayfun(@(Q) strcmp(Q.cellFate,'dead'),combined_tracks));
unknown_count_total=sum(arrayfun(@(Q) strcmp(Q.cellFate,'unknown'),combined_tracks));
N_cells_total=live_count_total+dead_count_total;
deadFraction_total=dead_count_total./N_cells_total;

%% Show death frequency per field
%Each field in different color. The combined death fraction and the mean
%death fraction of hte fields is displayed in black.
scrsz = get(groot,'ScreenSize');
hFig=figure('Position', [scrsz(3)*0.02 scrsz(4)*0.05 scrsz(3)*0.95 scrsz(4)*0.86]);
for i=1:length(file_ID)
    plot(N_cells(i),deadFraction(i),'o');
    hold on
end

errorbar(mean(N_cells),mean(deadFraction),std(deadFraction)/sqrt(length(deadFraction)),'x','MarkerSize',10,'Color','k');
% errorbar(mean(N_cells),mean(deadFraction),yError,yError,xError,xError,'x','MarkerSize',10,'Color','k');% works for matlab 2016b+ yneg,ypos,xneg,xpos
%To add horizontal error bars uncomment the next section:
% x_error=std(N_cells)/sqrt(length(N_cells)); %SEM of cell number
% line([mean(N_cells)-x_error, mean(N_cells)+x_error],[mean(deadFraction),mean(deadFraction)],'Color','k');
plot(mean(N_cells),deadFraction_total,'s','MarkerSize',10,'Color','k');
ylim([0 1]);
xlabel('Cells detected');
ylabel('Fraction of dead cells');
titleStr=sprintf('Fraction of dead cells as a function of cell number (with known cell fate).\n square = total (combined fields); X = mean of fields; error bars = SEM; Color = field');
title(titleStr);

if saveFlag==1
    savefig(hFig,'Dead_per_field.fig');
    print('Dead_per_field','-dpng');
    save('combined_data.mat','combined_tracks','N_cells','deadFraction','live_count_total',...
        'dead_count_total','unknown_count_total','N_cells_total','deadFraction_total');
end

h=msgbox('Press OK when you''re ready to move on','Analysis');
waitfor(h);
close(hFig);

%% trim cells with unknown fate
Track_Fate=arrayfun(@(Q) Q.cellFate,combined_tracks,'UniformOutput',0); %Find track fate
combined_tracks_trim=combined_tracks(~strcmp(Track_Fate,'unknown')); %Trim tracks with less than desired length
if saveFlag==1
    save('combined_data.mat','combined_tracks_trim','-append');
end


%% get minimum and maximum timepoints
min_time=min(arrayfun(@(Q) min(Q.Treat1_Hours),combined_tracks));
max_time=max(arrayfun(@(Q) max(Q.Treat1_Hours),combined_tracks));

%% plot combined oxidation over time with cell fate
% x_lim=[min(H_num_total) H_num_total(idxSytStart-1)];
x_lim=[min_time,21];
% x_lim=[];
y_lim=[-0.1 1.3];
x_label=sprintf('Time post %s treatment (hours)',vars.treatLables{1});
y_label='mean oxD per cell';
titlestr='Oxidation per cell over time. Blue = live cells ; Red = dead cells, black = unknown fate.';
avoidTimes=21; %plot only time points up to 21 hours post treatment
% [hFig]=plotMeasurement(tracks_struct,y_fieldName,x_fieldName,colorMap,x_lim,y_lim,x_label,y_label,titlestr,avoidInd);
[hFig]=plotMeasurement(combined_tracks_trim,'AvgInt','Treat1_Hours','fateColor',x_lim,y_lim,x_label,y_label,titlestr,avoidTimes);%vars.Treat_dT_label{1}

if saveFlag==1
    savefig(hFig,'cells_ox_time_fate.fig');
    print('cells_ox_time_fate','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','Analysis');
waitfor(h);
close(hFig);

%% plot combined oxidation over time with cell fate - zoom in on the first 2 hours
x_lim=[min_time,2];
y_lim=[0 1.1];
x_label=sprintf('Time post %s treatment (hours)',vars.treatLables{1});
y_label='mean oxD per cell';
titlestr='Oxidation per cell over time. Blue = live cells ; Red = dead cells, black = unknown fate.';
avoidTimes=5; %plot only time points up to 21 hours post treatment
% [hFig]=plotMeasurement(tracks_struct,y_fieldName,x_fieldName,colorMap,x_lim,y_lim,x_label,y_label,titlestr);
[hFig]=plotMeasurement(combined_tracks_trim,'AvgInt','Treat1_Hours','fateColor',x_lim,y_lim,x_label,y_label,titlestr,avoidTimes);%vars.Treat_dT_label{1}

if saveFlag==1
    savefig(hFig,'cells_ox_time_fate_initial.fig');
    print('cells_ox_time_fate_initial','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','Analysis');
waitfor(h);
close(hFig);

%% plot combined oxidation over time with cell fate - zoom in on the dawn
x_lim=[18,20];
y_lim=[0 1];
x_label=sprintf('Time post %s treatment (hours)',vars.treatLables{1});
y_label='mean oxD per cell';
titlestr='Oxidation per cell over time. Blue = live cells ; Red = dead cells, black = unknown fate.';
avoidTimes=21; %plot only time points up to 21 hours post treatment
% [hFig]=plotMeasurement(tracks_struct,y_fieldName,x_fieldName,colorMap,x_lim,y_lim,x_label,y_label,titlestr);
[hFig]=plotMeasurement(combined_tracks_trim,'AvgInt','Treat1_Hours','fateColor',x_lim,y_lim,x_label,y_label,titlestr,avoidTimes);%vars.Treat_dT_label{1}

if saveFlag==1
    savefig(hFig,'cells_ox_time_fate_dawn.fig');
    print('cells_ox_time_fate_dawn','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','Analysis');
waitfor(h);
close(hFig);

%%

%% create dataset for a classifier

% prepare a table with cell oxidation over time
% maxFrame=max(arrayfun(@(Q) max(Q.Frame),combined_tracks_trim));
oxidation_Data=cell2mat(arrayfun(@(Q) Q.AvgInt,combined_tracks_trim,'UniformOutput',0));
time_Data=cell2mat(arrayfun(@(Q) Q.Treat1_Hours,combined_tracks_trim,'UniformOutput',0));
unique_time=unique(time_Data);
ox_mat=NaN(length(combined_tracks_trim),length(unique_time));
for m=1:length(combined_tracks_trim)
    combined_tracks_trim(m).newID=m;% give new ID for the combined tracks
    ox_data=combined_tracks_trim(m).AvgInt;
    t_data=combined_tracks_trim(m).Treat1_Hours;
    for n=1:length(unique_time)
        time_now=unique_time(n);
        ind_now=arrayfun(@(Q) Q==time_now,t_data);
        if sum(ind_now)<1
            continue
        else
            ox_mat(m,n)=ox_data(ind_now);
        end
    end
end

%%
test_data=ox_mat(:,3);
test_data_trim=test_data(~isnan(test_data));
%% get the cell fate of the dataset
cell_fate=arrayfun(@(Q) Q.cellFate,combined_tracks_trim,'UniformOutput',0); %Find track fate
cell_fate_trim=cell_fate(~isnan(test_data));
%%
label_data=zeros(size(cell_fate_trim));
label_data(strcmp(cell_fate_trim,'live'))=1;
%% 
test_mat=zeros(length(label_data),2);
test_mat(:,1)=test_data_trim;
test_mat(:,2)=label_data;

%%
% oxidation_Data2=cell2mat(oxidation_Data);
% oxidation_Data3=reshape(oxidation_Data2,length(oxidation_Data),length(combined_tracks_trim(1).AvgInt));
test_data2=cell(length(test_data),2);
test_data2(:,1)=num2cell(test_data);
test_data2(:,2)=cell_fate;

%%
test_mat2=num2cell(ox_mat);
test_mat2(:,end+1)=cell_fate;

%%
test_mat3=ox_mat;
test_mat3(:,end+1)=strcmp(cell_fate,'live');
%% change back to the original working directory
cd(owd);
