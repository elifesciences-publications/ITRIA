%% the Itria script
%{
MIT License
Copyright (c) 2018 Avia Mizrachi

%% Important!
% all the variables and parameters that can be changed by the user are in
the varsFunc. Please see that function and varify that everything fits the
requirements before running the sacript.

This script is made for image analysis of roGFP timelapse imaging in photosynthetic cells.
This script takes a 4-channel .vsi timelapse file and creates a ratio image
of 405/488 and calculates the oxD pixel by pixel based on extreme values for max ox and
max red. 
It also creates an expression image which is the intensity of 405 multiplied by the 488.  

pre-processing:
The user chooses background ROI and the background is substracted.
Then, the user chooses a threshold value (or uses automated threshold with
pre-defined values).

Imaging channel order:
1. ex 405 (roGFP405)
2. ex 488 (roGFP488)
3. chlorophyll
4. bright field
any changes in the channels order shoud be done within the varsFunc
function.
it should have only one Z plane (meaning not a 3d image), and could be either a timelapse or a single timepoint.

The output:
1. ratio timelapse image (with and without BF overlay)
2. roGFP expression image
3. txt file containing the path, file name, and mean background intensities used for bg substraction.
4. zip file of the background ROI.
5. zip file of detected cells ROIs
6. oxD timelapse image (with and without BF overlay)
7. roGFP expression image (405i*488i/5000) ***divide in 5000 for cal bar visualization
8. measurements of roGFP ratio and 488i per cell.
All output files are saved in an output directory within the directory of the original image.

%}

%% To see the files required for the itria execute this function
% [fList, pList] = matlab.codetools.requiredFilesAndProducts('myroGFP.m'); 

%% for image stabilizer and any other application that uses MIJI run this part!
javaaddpath 'C:/Program Files/MATLAB/R2015b/java/mij.jar'
javaaddpath 'C:/Program Files/MATLAB/R2015b/java/ij.jar'

%% settings and preparations
clc; 
clear;
close all;
saveFlag=1; %choose 1 in order to save the output. otherwise enter 0;
varsChoice='new'; %options: 'new' or 'load'. New to create the vars variable, load to load previous variables.
timeChioce='new'; %Whether to load aquisition time parameters or create new ones. options: 'new' or 'load'.
%open log file
%log_txt = fopen('analysis_log.txt','w'); %text file for the log

%% switch to the directory of the script. 
% cd('D:/aviam/Box Sync/Vardi data (don''t sync)/Avia/2-protocols and tools/imageAnalysis/matlab/itria'); %only on Avia's computer.
owd = pwd; %original working directory
if(~isdeployed);  cd(fileparts(which('itria.m')));  end %switch directory to that of the script


%% variables and parameters
switch varsChoice
    case 'new'
        vars = varsFunc();
    case 'load'
        [varsName,varsPath] = uigetfile('*.mat','Choose "vars" file');
        load([varsPath,'/',varsName],'vars')
        cd(varsPath);
    otherwise
        warning('"vars" loading choice wasn''t specified correctly. new "vars" variable created.');
        vars = varsFunc();
end

%% background image choice 
vars.bgMethod='roi';%'bgImage';%choose 'bgImage' to load a background image for subtraction or 'roi' to subtract background based on the ROI

%% input directory and files
input_folder = uigetdir;
file_str = [input_folder,'\',vars.imgSufix];
file_list = dir(file_str);
nFiles = length(file_list(:,1));
if saveFlag==1
    mkdir(input_folder,'output'); %create output directory
    output_folder = [input_folder,'\output'];
else
    output_folder=input_folder;
end
%write in the log file
%{
fprintf(log_txt, 'input directory:  %s  \n',input_folder);
fprintf(log_txt, 'output directory:  %s  \n',output_folder);
disp(log_txt);
fclose(log_txt);
%}

%% loop through the files and concatenate images
%open the first image
if strcmp(vars.concatChoice,'yes')==1 %if to concatenate stacks
    for i=1:nFiles %loop through the files, concatenate them.
        file_path = strcat(input_folder,'\',file_list(i).name); %get the file path of file i
        if i ==1 %first image - different treatment for 1st file
            [imgMat, imgData, omeMeta]=imgRead(vars,file_path); %read the stack
            vars.endFrame = imgData.sizeT; %get the number of frames
            
            %get the timepoints of the stack
            imgData.AcquisitionDateArray = imgData.AcquisitionDate;
            if strcmp(timeChioce,'new') || strcmp(varsChoice,'new') %create new time array and time difference from treatments 
                if strcmp(varsChoice,'load') %remove previous time data
                    vars = rmfield(vars,{'timeArray','Treat_dT','Treat_dT_label'}); %remove the timearrays before the next loop 
                end
                  
                fprintf('This is the aquisition date of stack %g:\n',i)
                disp(imgData.AcquisitionDate);
                prompt = {'Enter start date (dd/MM/yyyy):','Enter start time (HH:mm):','Enter delta T (in minutes):'};
                dlg_title = 'Aquisition time input';
                num_lines = 1;
                defaultans = {'dd/MM/yyyy','HH:mm','0'};
                answer = inputdlg(prompt,dlg_title,num_lines,defaultans);            
                fullStartDate=[answer{1} ',' answer{2}];
                vars.startT(i) = datetime(fullStartDate,'InputFormat','dd/MM/yyyy,HH:mm'); %get the full time of aquisition start
                vars.deltaT(i) = str2double(answer{3}); %get the time difference between frames (in minutes)
                vars.endT(i)=vars.startT(i)+(minutes(vars.deltaT(i))*(imgData.sizeT-1)); %caluculate the end time of the stack
                vars.timeArray=vars.startT(i):minutes(vars.deltaT(i)):vars.endT(i); %create aquisition time array
            end
            
        else  %after the first images concatenate the stacks
            [imgMat0, imgData0, omeMeta0]=imgRead(vars,file_path);
            
            %check if the stacks match in their dimentions >> concat stacks
            if imgData0.sizeZ ~= imgData.sizeZ || imgData0.sizeC ~= imgData.sizeC ... 
                    || imgData0.sizeX ~= imgData.sizeX || imgData0.sizeY ~= imgData.sizeY                 
%             if imgData0.sizeZ == imgData.sizeZ && imgData0.sizeC == imgData.sizeC ... 
%                     && imgData0.sizeX == imgData.sizeX && imgData0.sizeY == imgData.sizeY 
%                 imgMat(:,:,:,(vars.endT+1):(vars.endT+imgData0.sizeT)) = imgMat0(:,:,:,:); %imgMat(SizeY, SizeX, sizeC, sizeT);     
%             else %stacks do not match
                error('the stacks do not match in their dimentions');                
            end %stack match
            
            imgMat(:,:,:,(vars.endFrame+1):(vars.endFrame+imgData0.sizeT)) = imgMat0(:,:,:,:); %imgMat(SizeY, SizeX, sizeC, sizeT);
            
            %get the timepoints of the stack
            imgData.AcquisitionDateArray = [imgData.AcquisitionDateArray,imgData0.AcquisitionDate]; %add the date to the date array
            if strcmp(timeChioce,'new') || strcmp(varsChoice,'new')                         
                fprintf('This is the aquisition date of stack %g:\n',i)
                disp(imgData0.AcquisitionDate);
                prompt = {'Enter start date (dd/MM/yyyy):','Enter start time (HH:mm):','Enter delta T (in minutes):'};
                dlg_title = 'Aquisition time input';
                num_lines = 1;
                defaultans = {datestr(vars.endT(i-1),'dd/mm/yyyy'),datestr(vars.endT(i-1),'HH:MM'),num2str(vars.deltaT(i-1))};
                answer = inputdlg(prompt,dlg_title,num_lines,defaultans);           
                fullStartDate=[answer{1} ',' answer{2}];
                vars.startT(i) = datetime(fullStartDate,'InputFormat','dd/MM/yyyy,HH:mm');
                vars.deltaT(i) = str2double(answer{3});
                vars.endT(i)=vars.startT(i)+(minutes(vars.deltaT(i))*(imgData0.sizeT-1)); %caluculate the end time of the stack
                vars.timeArray=[vars.timeArray,vars.startT(i):minutes(vars.deltaT(i)):vars.endT(i)];
            end

            %update sizeT and clear the temp mat
            imgData.sizeT = imgData.sizeT+imgData0.sizeT; %size T is the sum of timepoints of the two stacks
            vars.endFrame = imgData.sizeT;
            imgData.planes = imgData.planes + imgData0.planes;
            clear imgData0 imgMat0 omeMeta0;

        end % 1st or later images

    end %files loop

    if strcmp(timeChioce,'new') || strcmp(varsChoice,'new')
        vars.Treat_dT=cell(length(vars.treatLables),1);
        vars.Treat_dT_label=cell(length(vars.treatLables),1);
        for j=1:length(vars.treatLables) %calculate the time difference per treatment
            vars.Treat_dT{j}=between(vars.treatTime(j),vars.timeArray); %time difference array from treatment 1        
            vars.Treat_dT_label{j}=cellstr(vars.Treat_dT{j});
            vars.Treat_dT_label{j}=regexprep(vars.Treat_dT_label{j},'m\s\d*s','m');
        end
              
        %convert the time to a number
%         [time_array]=time2hours(timeLabel)
        vars.H_post_treat1=time2hours(vars.Treat_dT_label{1});
        vars.H_post_treat2=time2hours(vars.Treat_dT_label{2});

    end
    
    %analyze the concatenated stack 
%     myroGFP(imgMat,imgData,vars,output_folder,saveFlag)

else %no stack concatenation
    for i=1:nFiles %loop through the files and analyse them one by one
        file_path = strcat(input_folder,'\',file_list(i).name);
        [~,fName,~]=fileparts(file_list(i).name);
        mkdir(output_folder,['output_',fName]); %create output directory
        output_folder_i = [output_folder,['\output_',fName]];
%         cd(output_folder_i)
        %open image i
        [imgMat, imgData, omeMeta]=imgRead(vars,file_path);
        
        %get aquisition time
        if (i==1 && (strcmp(timeChioce,'new') || strcmp(varsChoice,'new'))) || strcmp(timeChioce,'new') %create new aquisition time. Differentiate between the first and other stacks. Otherwise - use the loaded time data.
            if strcmp(varsChoice,'load') %remove previous time data
                vars = rmfield(vars,{'timeArray','Treat_dT','Treat_dT_label'}); %remove the timearrays before the next loop 
            end
        
            fprintf('This is the aquisition date of stack %g:\n',i)
            disp(imgData.AcquisitionDate);
            prompt = {'Enter start date (dd/MM/yyyy):','Enter start time (HH:mm):','Enter delta T (in minutes):'};
            dlg_title = 'Aquisition time input';
            num_lines = 1;
            defaultans = {'dd/MM/yyyy','HH:mm','0'};
            answer = inputdlg(prompt,dlg_title,num_lines,defaultans);

            fullStartDate=[answer{1} ',' answer{2}];
            vars.startT = datetime(fullStartDate,'InputFormat','dd/MM/yyyy,HH:mm');
            vars.deltaT = str2double(answer{3});
            vars.endT=vars.startT+(minutes(vars.deltaT)*(imgData.sizeT-1)); %caluculate the end time of the stack
            vars.timeArray=vars.startT:minutes(vars.deltaT):vars.endT;

            %get the time relative to the treatment
            vars.Treat_dT=cell(length(vars.treatLables),1);
            vars.Treat_dT_label=cell(length(vars.treatLables),1);
            for j=1:length(vars.treatLables) %calculate the time difference per treatment
                vars.Treat_dT{j}=between(vars.treatTime(j),vars.timeArray); %time difference array from treatment i       
                vars.Treat_dT_label{j}=cellstr(vars.Treat_dT{j});
                vars.Treat_dT_label{j}=regexprep(vars.Treat_dT_label{j},'m\s\d*s','m'); %create cell array of text labels of the relative time from treatment
            end
            
            %convert the time to a number
            vars.H_post_treat1=time2hours(vars.Treat_dT_label{1});
            vars.H_post_treat2=time2hours(vars.Treat_dT_label{2});

        end %timeChioce
        
        %analyse the stack
        myroGFP(imgMat,imgData,vars,output_folder_i,saveFlag)
%         [outputStruct] = myroGFP(imgMat, imgData, vars, output_folder_i,saveFlag);
        
        close all 
        
        %cleanup before the next stack
        if strcmp(timeChioce,'new')
            vars = rmfield(vars,{'timeArray','Treat_dT','Treat_dT_label'}); %remove the timearrays before the next loop 
        end
        
    end %file loop   

end %concat choice

disp('the script reached the end');

%%
cd(owd); %switch back to the original working directory
%% time testing
            %get the relative time difference from treatments:
%             vars.Treat1Time=[vars.Treat1Time,between(vars.treatTime(1),vars.timeArray((vars.endFrame+1):end))]; %concatenating the time arrays
%             vars.Treat2Time=[vars.Treat2Time,between(vars.treatTime(2),vars.timeArray((vars.endFrame+1):end))]; %concatenating the time arrays
%     vars.Treat1Time=between(vars.treatTime(1),vars.timeArray); %time difference array from treatment 1
%     vars.Treat2Time=between(vars.treatTime(2),vars.timeArray); %time difference array from treatment 2
%     vars.Treat1TimeL=cellstr(vars.Treat1Time);
%     vars.Treat1TimeL=regexprep(vars.Treat1TimeL,'m\s\d*s','m');
%     vars.Treat2TimeL=cellstr(vars.Treat2Time);
%     vars.Treat2TimeL=regexprep(vars.Treat2TimeL,'m\s\d*s','m');
%{
% vars.timeArray = zeros(1,nFiles);
% vars.startTarray = zeros(1,nFiles); %array of start times - for time stamp
% imgData.startT=[];
% oldPath=cd(output_folder);
%     vars.startT=zeros(1,nFiles);
%     vars.deltaT=zeros(1,nFiles);
%     vars.endT=zeros(1,nFiles);
        %get the startT for file i
        %{
        prompt = {sprintf('Stack no. %d\nThe last stack ended at %d min.\n Enter start time: ',i,vars.endTime)};
        dlg_title = 'Start time input';
        num_lines = 1;
        if i==1
            defAns = {num2str(vars.startT)};
        else
            defAns = {num2str(vars.endTime+vars.deltaT)};
        end
        
        answer = inputdlg(prompt,dlg_title,num_lines,defAns);
        vars.startT = str2double(answer{1});       
        vars.startTarray(1,i)=vars.startT;
        %}
%             prompt = {'Enter start time (HH:MM, default is the last timepoint):','Enter start date (dd/mm):','Enter deltaT (HH:MM):'};
%             dlg_title = 'Aquisition time input';
%             num_lines = 1;
%             defaultans = {vars.timeStampArray{end},datestr(vars.startD(i-1),'dd/mm'),datestr(vars.deltaT(i-1),'HH:MM')};
% %             defaultans = {num2str(thrLow),num2str(thrUp)};
%             answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
%             vars.startT(i) = datenum(answer{1},'HH:MM');
%             vars.startD(i) = datenum(answer{2},'dd/mm');
%             vars.deltaT(i) = datenum(answer{3},'HH:MM');          
%             vars.timeArray(vars.endT+1)=vars.startT(i);
%             vars.timeStampArray{vars.endT+1}=datestr(vars.timeArray(vars.endT+1),'HH:MM');               
% %             datestr
%             for j=(vars.endT+2):(vars.endT+imgData0.sizeT)
%                 vars.timeArray(j)=vars.timeArray(j-1)+vars.deltaT(i);
%                 vars.timeStampArray{j}=datestr(vars.timeArray(j),'HH:MM');
%             end
%             vars.endT(i)=vars.startT(i)+(minutes(vars.deltaT(i))*(20)); %caluculate the end time of the stack            
% %             t1 = datevec(str,'mmmm dd, yyyy HH:MM:SS')
% %             vars.treatTimeLabels={'07/09/2016,12:55','08/09/2016,11:45'};%'dd/mm/yyyy,HH:MM'
% %             vars.treatTime=datenum(vars.treatTimeLabels,'dd/mm/yyyy,HH:MM');

%             vars.startT(i) = datenum(answer{1},'yyyy/mm/dd,HH:MM:SS');            
%             vars.startT(i)=answer{1};
%             vars.deltaT(i) = str2double(answer{2});
%             endT_interval=vars.deltaT(i)*(imgData.sizeT-1);
%             t2 = vars.startT(i) + minutes(0:vars.deltaT(i):endT_interval);
            
%             vars.startT(i) = datevec(answer{1},'yyyy/mm/dd,HH:MM:SS');
% %             vars.startD(i) = datenum(answer{2},'dd/mm');
%             vars.deltaT(i) = datevec([answer{3},'HH:MM');          
%             vars.timeStampArray=cell(1,imgData.sizeT);
%             vars.timeArray=zeros(1,imgData.sizeT);
%             vars.timeArray(1)=vars.startT(i);
%             vars.timeStampArray{1}=datestr(vars.timeArray(1),'dd/mm/yyyy,HH:MM');
% %             datestr
%             for j=2:imgData.sizeT
%                 vars.timeArray(j)=vars.timeArray(j-1)+vars.deltaT(i);
%                 vars.timeStampArray{j}=datestr(vars.timeArray(j),'dd/mm/yyyy,HH:MM');
%             end
            
%             imgData.timeStamp=[imgData.timeStamp,timeArray];
%             vars.timeStampArray{1:end}=datestr(vars.timeArray(1:end),'HH:MM');
%}

%% display image/video 
%{
    %To display a single frame of a single channel:
    %imshow(imgMat(Y,X,channel,timepoint),colorMap);
    %imshow(imgMat(:,:,4,1));
    
    %To play a movie of a single channel:
    %implay(imgMat(Y,X,channel,timepoints),FramesPerSecond);
    %hVid=implay;
    %set(hVid, 'Position', [0 0 imgData.sizeX imgData.sizeY]);
    %implay(imgMat(:,:,4,:),3);


%}

%% might be useful in the future
%{

%options for the future
%files = getfield(what, 'm') % get files with '.m' extenstion

% Enlarge figure to full screen:
set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
redChannel = grayImage;
greenChannel = grayImage;
blueChannel = grayImage;
rgbImage = cat(3, redChannel, greenChannel, blueChannel);
%[pathstr,name,ext] = fileparts(filename);
%f = fullfile(filepart1,...,filepartN); %instead of strcat
%drawnow;%use in the figure to show the updates imidiately
%axis image; % Make sure image is not artificially stretched because of screen's aspect ratio.
%CC = bwconncomp(BW) %returns the connected components CC found in BW. The binary image BW can have any dimension. CC is a structure with four fields.
%CC = bwconncomp(BW,conn)% for 2D connectivity use conn=8. specifies the desired connectivity for the connected components. conn can have the following scalar values.
%}

%%
        %calculate the relative time difference from the treatments:
%             vars.Treat1Time=between(vars.treatTime(1),vars.timeArray); %time difference array from treatment 1
%             vars.Treat2Time=between(vars.treatTime(2),vars.timeArray); %time difference array from treatment 2
