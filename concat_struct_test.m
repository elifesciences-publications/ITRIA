% combine data by concatenating structures.
%%
% %% first run
% data_total=dataStruct;
% 
% %% adding data
% data_total=[data_total,dataStruct];
% 
% %%
% 
% for j=1:length(data_total)
%     dataStruct(j).FileName='file1';
% end

%%
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
        [TrackDataName,TrackDataPath] = uigetfile({'*.mat';'*.mat'},'Choose the next file');
        load([TrackDataPath,'/',TrackDataName],'dataStruct','dataMat');
    catch
        warning('Couldn''t load file, please try again');        
        qstring = 'Do you want to load more files?';
        loadAnswer = questdlg(qstring,'Load Track Data');
        waitfor(loadAnswer);
        continue;
    end
    
    j=j+1; %file count

% N_cells(j)=live_count(j)+dead_count(j);
% deadFraction(j)=dead_count(j)/N_cells(j);
    file_ID{j} = inputdlg({'Enter file ID name (number or string):'},'file ID name input',1,{'0'});
    for i=1:length(dataStruct)
        dataStruct(i).fileID=file_ID{j};
    end
    
    if j==1 %first file
        combined_data=dataStruct; %create the combined_tracks
        combined_mat=dataMat;
    else %the rest of the files     
        combined_data=[combined_data,dataStruct];
        dataMat(1:2,:)=[];
        combined_mat=[combined_mat;dataMat];
    end

    qstring = 'Do you want to load more files?';
    loadAnswer = questdlg(qstring,'Load Track Data');
    waitfor(loadAnswer);
    clear dataStruct dataMat;
    cd(TrackDataPath);
end

% clear tracks_analysis;
cd(ouput_folder);
warning(s); %cahnge back the warning into a warning

%% 
if saveFlag==1
    save('ox_death_data_combined.mat','combined_mat','combined_data');%'cellsProps',
    xlswrite('ox_death_data_mat_combined.xlsx',combined_mat);
end
%% Remove raws with -Inf values
ind=combined_mat(:,1)==-Inf;
combined_mat(ind,:)=[];
ind = false(length(combined_data),1);
for i=1:length(combined_data)
    if combined_data(i).int488==-Inf
        ind(i)=true;
    end
end
combined_data(ind)=[];

if saveFlag==1
    save('intensity_data_combined.mat','combined_mat','combined_data');%'cellsProps',
    xlswrite('intensity_data_mat_combined.xlsx',combined_mat);
end
%%
fprintf('That''s it!\n');
%%