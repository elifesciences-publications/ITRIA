% This script exports to excel the cell fate and oxidation at a specific
% timepoint

%datastrct = tracks_analysis;

%%
oldPath=cd(output_folder); %change folder to the output folder
clearFlag=1;
saveFlag=1;
%% choose timepoint
%get the timepoints of the treatment, and a specific timepoint to
%be used for analysis.
idxFrames=(vars.timeArray>=vars.treatTime(1));%get the index of the timepoints after treatment
idxStart=find(vars.timeArray>=vars.treatTime(1),1);%the index of the first frame of the sytox treatment

%let the user choose the timepoint to be used for sytox analysis
prompt=sprintf('Select %s treatment timepoint:\n',vars.treatLables{1});
list=vars.Treat_dT_label{1}(idxFrames);
frameAnswer='No'; %for the while loop initiation
scrsz = get(groot,'ScreenSize'); %get the screen size for the plot

while strcmp(frameAnswer,'No')    
    [Selection,ok] = listdlg('Name','Treatment timepoint',...
        'PromptString',prompt,...
        'SelectionMode','single',...
        'ListString',list);
    if ok~=1
        warning('You have to choose one timepoint!');
        while ok==0
            [Selection,ok] = listdlg('Name','Treatment timepoint',...
            'PromptString',prompt,...
            'SelectionMode','single',...
            'ListString',list);
        end
    end
    
    idxF=find(strcmp(vars.Treat_dT_label{1}, list(Selection))); %the number of the selected sytox frame. This option is better for the analysis later.

    %view the chosen frames with the two next to it
%     scrsz = get(groot,'ScreenSize');
    h=figure('Position',[scrsz(3)*0.02 scrsz(4)*0.05 scrsz(3)*0.95 scrsz(4)*0.86]);
    % h=figure('Position', [150, 50, size(final488,2).*2, size(final488,1).*1.8]);
    if idxF>1
        h1=subplot(1,3,1);
        p = get(h1, 'pos');
        p(1) = p(1)-0.12;
        p(3) = p(3) + 0.1;
        p(4) = p(4) + 0.1;
        set(h1, 'pos', p);
        imshow(final488(:,:,idxF-1),'InitialMagnification',150);
        axis image
        titleStr=sprintf('channel 488 frame %g',idxF-1);
        title(titleStr);
    end

    h2=subplot(1,3,2);
    p = get(h2, 'pos');
    p(1) = p(1)-0.07;
    p(3) = p(3) + 0.1;
    p(4) = p(4) + 0.1;
    set(h2, 'pos', p);
    imshow(final488(:,:,idxF),'InitialMagnification',150);
    axis image
    titleStr=sprintf('channel 488 frame %g (chosen)',idxF);
    title(titleStr);

    if nFrames>idxF
        h3=subplot(1,3,3);
        p = get(h3, 'pos');
        p(1) = p(1)-0.02;
        p(3) = p(3) + 0.1;
        p(4) = p(4) + 0.1;
        set(h3, 'pos', p);
        imshow(final488(:,:,idxF+1),'InitialMagnification',150);
        axis image
        titleStr=sprintf('channel 488 frame %g',idxF+1);
        title(titleStr);
    end
    
    %ask the user to confirm the choice
    qstring = 'Are you happy with the chosen frame?';
    frameAnswer = questdlg(qstring,'Analysis frame');
    close(h);
end

fprintf('Treatment started at %s, frame: %g\n',datestr(vars.timeArray(idxStart)),idxStart);
fprintf('The frame chosen for sytox analysis is: %g,  %s post treatment\n',idxF,vars.Treat_dT_label{1}{idxF});
Im_chosen=final488(:,:,idxF); %the image to be used for the analysis

if clearFlag==1
    clear h h1 h2 h3 p qstring sytAnswer titleStr prompt list
    
end

%% View the chosen frame overlayed on BF
hFig=figure;
titleStr='488 and bright field overlay';
cmap = [0,1,0]; %colormap
rgbImg = falseColor(Im_chosen,cmap);
imshow(BFfilt(:,:,idxF),'InitialMagnification', 150);
% h1.AlphaData=0.5;
hold on
h2=imshow(rgbImg, 'InitialMagnification', 150);
h2.AlphaData=0.8;
axis image;
title(titleStr);
hMsg=msgbox('Press OK when you''re ready to move on','Analysis frame');%Wait for user to view the image
waitfor(hMsg);
close(hFig);

clear h1 h2 hFig


%% generate table

dataStruct = struct;
%% remove unknown fate
Track_Fate=arrayfun(@(Q) Q.cellFate,tracks_analysis,'UniformOutput',0); %Find track fate
tracks_analysis_fate=tracks_analysis(~strcmp(Track_Fate,'unknown')); %Trim tracks with less than desired length
%% get data
j=0;
for i=1:length(tracks_analysis_fate) %loop through the cells
    frameIdx=tracks_analysis_fate(i).Frame==idxF;%get the index of the chosen timepoint. This can be adapted to multiple timepoints in the future. 
    if sum(frameIdx)==0 %the cell wasn't detected in the frame
        continue;       
    elseif sum(frameIdx)==1 %the cell was detected in the sytox frame
        if ~isnan(tracks_analysis_fate(i).AvgInt(frameIdx))
            j=j+1;
            dataStruct(j).meanOx=tracks_analysis_fate(i).AvgInt(frameIdx);
            meanOx_array(j)=dataStruct(j).meanOx;
            dataStruct(j).cellFate=tracks_analysis_fate(i).cellFate;           
            cellFate_array{j}=dataStruct(j).cellFate;   
%             dataStruct(j).int488=tracks_analysis(i).int488(frameIdx);
%             int488_array(j)=dataStruct(j).int488;
%             dataStruct(j).roGFP_ratio=tracks_analysis(i).roGFP_ratio(frameIdx);
%             roGFP_ratio_array(j)=dataStruct(j).roGFP_ratio;
%             dataStruct(j).max_roGFP=tracks_analysis(i).max_roGFP(frameIdx);
%             max_roGFP_array(j)=dataStruct(j).max_roGFP;
%             dataStruct(j).min_roGFP=tracks_analysis(i).min_roGFP(frameIdx);
%             min_roGFP_array(j)=dataStruct(j).min_roGFP;       
%             dataStruct(j).int488_overlap=tracks_analysis(i).int488_overlap(frameIdx);
%             dataStruct(j).roGFP_ratio_overlap=tracks_analysis(i).roGFP_ratio_overlap(frameIdx);
%             dataStruct(j).FileName='file1';%file_list(1).name;
            dataStruct(j).FileName=file_list(1).name;

        end        
    else
        error('More than one matching timepoint was found for the treatment'); 
        %actually, this error should never occour. However, in the future
        %the script can be adapted to look for matching across several timepoints. 
        %for example, create a mini-stack of 3 sytox timepoint and look for 
        %sytox co-localization in any of these frames in order to be sure 
        %that no cell is missed out because of out-of-focus etc. 
    end

end

%%
% dataMat=cell(length(int488_array)+1,4);
% dataMat{1,1}='int488';
% dataMat{1,2}='roGFP_ratio';
% dataMat{1,3}='max_roGFP';
% dataMat{1,4}='min_roGFP';
headText=sprintf('cell oxidation vs. cell fate - frame %d, at %s post %s treatment',...
    idxF,vars.Treat_dT_label{1}{idxF},vars.treatLables{1});
headText=cellstr(headText);
dataMat=[headText,{''}; {'cell fate'},{'mean oxidation'}; cellFate_array', num2cell(meanOx_array)'];
save('ox_death_data.mat','dataMat','dataStruct');%'cellsProps',

xlswrite('ox_death_data.xlsx',dataMat);

fprintf('it is done!\n');
%%
clear  cellFate_array meanOx_array dataMat dataStruct
%%