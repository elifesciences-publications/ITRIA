%% generate background image
%function []=createBackgroundImage()

%% initiation
clc; 
clear;
close all;
saveFlag=1; %choose 1 in order to save the output. otherwise enter 0;
clearFlag=0; %1 to clear variables along the way.
varsChoice='new'; %options: 'new' or 'load'. New to create the vars variable, load to load previous variables.
owd = pwd; %original working directory
if(~isdeployed); cd(fileparts(which('createBackgroundImage.m'))); end %switch directory to that of the script

%% variables and parameters
%for this script the vars function is relevant for the image data: sufix,
%bit depth, etc.
switch varsChoice
    case 'new'
        vars = varsFunc();
    case 'load'
        [varsName,varsPath] = uigetfile('*.mat','Choose "vars" file');
        load([varsPath,'/',varsName],'vars')
    otherwise
        warning('"vars" loading choice wasn''t specified correctly. new "vars" variable created.');
        vars = varsFunc();
end

%% get the input and output directories from the user
input_folder = uigetdir(pwd,'Choose file input folder');
output_folder=uigetdir(input_folder,'Choose output folder');
cd(input_folder);
file_str = [input_folder,'\',vars.imgSufix];
file_list = dir(file_str);
nFiles = length(file_list(:,1));

%% 1.upload a stack of background images - use the itria
for i=1:nFiles %loop through the files, concatenate them.
    file_path = strcat(input_folder,'\',file_list(i).name); %get the file path of file i
    if i ==1 %first image - different treatment for 1st file
        [imgMat, imgData, omeMeta]=imgRead(vars,file_path); %read the stack
        vars.endFrame = imgData.sizeT; %get the number of frames

    else  %after the first images concatenate the stacks
        [imgMat0, imgData0, omeMeta0]=imgRead(vars,file_path);

        %check if the stacks match in their dimentions >> concat stacks
        if imgData0.sizeZ ~= imgData.sizeZ || imgData0.sizeC ~= imgData.sizeC ... 
                || imgData0.sizeX ~= imgData.sizeX || imgData0.sizeY ~= imgData.sizeY                 
            error('the stacks do not match in their dimentions');                
        end %stacks match in dimensions

        imgMat(:,:,:,(vars.endFrame+1):(vars.endFrame+imgData0.sizeT)) = imgMat0(:,:,:,:); %imgMat(SizeY, SizeX, sizeC, sizeT);
        imgData.sizeT = imgData.sizeT+imgData0.sizeT; %size T is the sum of timepoints of the two stacks
        vars.endFrame = imgData.sizeT;
        imgData.planes = imgData.planes + imgData0.planes;
        clear imgData0 imgMat0 omeMeta0;

    end % 1st or later images

end %files loop

%% 2.pre-processing
%% get the channels and reshape to 3D
raw405 = reshape(imgMat(:,:,vars.ind405,:),size(imgMat,1),size(imgMat,2),size(imgMat,4)); % 405
raw488 = reshape(imgMat(:,:,vars.ind488,:),size(imgMat,1),size(imgMat,2),size(imgMat,4)); % 488
rawChl = reshape(imgMat(:,:,vars.indChl,:),size(imgMat,1),size(imgMat,2),size(imgMat,4)); % chlorophyll
rawBF = reshape(imgMat(:,:,vars.indBF,:),size(imgMat,1),size(imgMat,2),size(imgMat,4)); % bright field

nFrames=size(rawBF,3); %get the frame number

if clearFlag==1
    clear imgMat omeMeta 
end
%% Convert to double
rawChl=double(rawChl);
raw405=double(raw405);
raw488=double(raw488);
rawBF=double(rawBF);

%% Normalize the stacks
% Normalize to [0 1] according to the image bit-depth
rawChl=rawChl./vars.maxRange;
raw405=raw405./vars.maxRange;
raw488=raw488./vars.maxRange;
rawBF=rawBF./vars.maxRange;

%% 3. raw background images - short video
%view the raw stack of the background images frame by frame
scrsz = get(groot,'ScreenSize'); %get the screen size for the plot
hFig=figure('Position',[scrsz(3)*0.02 scrsz(4)*0.05 scrsz(3)*0.95 scrsz(4)*0.86]);
pauseTime=0.5;
% title('raw BF');
for i=1:nFrames
    titleStr=sprintf('Raw background images, frame %g',i);
    suptitle(titleStr); %if it doesn't work just comment this part
    subplot(2,2,1);
    imshow(rawBF(:,:,i),[min(rawBF(:)),max(rawBF(:))]);
    title('rawBF');
    subplot(2,2,2);
    imshow(rawChl(:,:,i),[min(rawChl(:)),max(rawChl(:))]);
    title('rawChl');
    subplot(2,2,3);
    imshow(raw405(:,:,i),[min(raw405(:)),max(raw405(:))]);
    title('raw405');
    subplot(2,2,4);
    imshow(raw488(:,:,i),[min(raw488(:)),max(raw488(:))]);
    title('raw488');
%     imshow(rawBF(:,:,i),'InitialMagnification',150);
    pause(pauseTime);
end
h=msgbox('Press OK when you''re ready to move on','raw background images');
waitfor(h);
close(hFig);

%% if you want to delete a frame do it here
i=4; %frame to delete
hFig=figure('Position',[scrsz(3)*0.02 scrsz(4)*0.05 scrsz(3)*0.95 scrsz(4)*0.86]);
titleStr=sprintf('Raw background images, frame %g',i);
suptitle(titleStr); %if it doesn't work just comment this part
subplot(2,2,1);
imshow(rawBF(:,:,i),[min(rawBF(:)),max(rawBF(:))]);
title('rawBF');
subplot(2,2,2);
imshow(rawChl(:,:,i),[min(rawChl(:)),max(rawChl(:))]);
title('rawChl');
subplot(2,2,3);
imshow(raw405(:,:,i),[min(raw405(:)),max(raw405(:))]);
title('raw405');
subplot(2,2,4);
imshow(raw488(:,:,i),[min(raw488(:)),max(raw488(:))]);
title('raw488');
qstring = 'Are you sure you want to delete this frame?';
deleteAnswer = questdlg(qstring,'Frame to delete');
if strcmp(deleteAnswer,'Yes')
    rawBF(:,:,i)=[];
    rawChl(:,:,i)=[];
    raw405(:,:,i)=[];
    raw488(:,:,i)=[];
    nFrames=size(rawBF,3); %get the new frame number
    fprintf('Frame %g was deleted. New frame number: %g\n',i,nFrames);
end
close(hFig);
%% generate median image
median_BF=median(rawBF,3);
median_chl=median(rawChl,3);
median_405=median(raw405,3);
median_488=median(raw488,3);
hFig=figure('Position',[scrsz(3)*0.02 scrsz(4)*0.05 scrsz(3)*0.95 scrsz(4)*0.86]);
subplot(2,2,1);
imshow(median_BF,[min(median_BF(:)),max(median_BF(:))]);
title('median BF');
subplot(2,2,2);
imshow(median_chl,[min(median_chl(:)),max(median_chl(:))]);
title('median chl');
subplot(2,2,3);
imshow(median_405,[min(median_405(:)),max(median_405(:))]);
title('median 405');
subplot(2,2,4);
imshow(median_488,[min(median_488(:)),max(median_488(:))]);
title('median 488');
h=msgbox('Press OK when you''re ready to move on','median background');
waitfor(h);
close(hFig);
if saveFlag==1
    cd(output_folder);
    save('background_median.mat','median_BF','median_chl','median_405','median_488');
end
%% zoom in - 405 
% figure;
% imshow(median_405,[min(median_405(:)),max(median_405(:))]);

%% blur median image
sigma=20;
sigma_bf=5;
blur_BF = imgaussfilt(median_BF,sigma_bf); %gaussian filter
blur_chl=imgaussfilt(median_chl,sigma);
blur_405=imgaussfilt(median_405,sigma);
blur_488=imgaussfilt(median_488,sigma);

hFig=figure('Position', [150, 50, size(rawBF,2).*2, size(rawBF,1).*1.8]);
% imshow(BF_median_filt,'InitialMagnification',150);
% titleStr=sprintf('BF median after gaussian filter, sigma: %g',sigma);
% title(titleStr);
subplot(2,2,1);
imshow(blur_BF,[min(blur_BF(:)),max(blur_BF(:))]);
titleStr=sprintf('BF median after gaussian filter, sigma: %g',sigma_bf);
title(titleStr);
% title('blur BF');
subplot(2,2,2);
imshow(blur_chl,[min(blur_chl(:)),max(blur_chl(:))]);
titleStr=sprintf('Chl median after gaussian filter, sigma: %g',sigma);
title(titleStr);
% title('blur chl');
subplot(2,2,3);
imshow(blur_405,[min(blur_405(:)),max(blur_405(:))]);
titleStr=sprintf('405 median after gaussian filter, sigma: %g',sigma);
title(titleStr);
subplot(2,2,4);
imshow(blur_488,[min(blur_488(:)),max(blur_488(:))]);
titleStr=sprintf('488 median after gaussian filter, sigma: %g',sigma);
title(titleStr);
if saveFlag==1
%     save('backgroundData.mat','median_filt_BF','median_BF');
end
h=msgbox('Press OK when you''re ready to move on','blur median background');
waitfor(h);
close(hFig);
if saveFlag==1
    save('background_median.mat','blur_BF','blur_chl','blur_405','blur_488','-append');
end
%% Other option: use minimum intensity instead (and max intensity for BF)

%% fluorescence background - min
max_BF=max(rawBF,[],3); %in BF the background is max intensity (objects are dark)
min_chl=min(rawChl,[],3);
min_405=min(raw405,[],3);
min_488=min(raw488,[],3);
hFig=figure('Position',[scrsz(3)*0.02 scrsz(4)*0.05 scrsz(3)*0.95 scrsz(4)*0.86]);
subplot(2,2,1);
imshow(max_BF,[min(max_BF(:)),max(max_BF(:))]);
title('max BF');
subplot(2,2,2);
imshow(min_chl,[min(min_chl(:)),max(min_chl(:))]);
title('min chl');
subplot(2,2,3);
imshow(min_405,[min(min_405(:)),max(min_405(:))]);
title('min 405');
subplot(2,2,4);
imshow(min_488,[min(min_488(:)),max(min_488(:))]);
title('min 488');
h=msgbox('Press OK when you''re ready to move on','min background');
waitfor(h);
close(hFig);
if saveFlag==1
    cd(output_folder);
    save('background_min.mat','max_BF','min_chl','min_405','min_488');
end

%% Blur min image
sigma=20;
sigma_bf=5;
blur_BF=imgaussfilt(max_BF,sigma_bf); %gaussian filter
blur_chl=imgaussfilt(min_chl,sigma);
blur_405=imgaussfilt(min_405,sigma);
blur_488=imgaussfilt(min_488,sigma);

hFig=figure('Position', [150, 50, size(rawBF,2).*2, size(rawBF,1).*1.8]);
% imshow(BF_median_filt,'InitialMagnification',150);
% titleStr=sprintf('BF median after gaussian filter, sigma: %g',sigma);
% title(titleStr);
subplot(2,2,1);
imshow(blur_BF,[min(blur_BF(:)),max(blur_BF(:))]);
titleStr=sprintf('BF median after gaussian filter, sigma: %g',sigma_bf);
title(titleStr);
% title('blur BF');
subplot(2,2,2);
imshow(blur_chl,[min(blur_chl(:)),max(blur_chl(:))]);
titleStr=sprintf('Chl median after gaussian filter, sigma: %g',sigma);
title(titleStr);
% title('blur chl');
subplot(2,2,3);
imshow(blur_405,[min(blur_405(:)),max(blur_405(:))]);
title('blur 405');
subplot(2,2,4);
imshow(blur_488,[min(blur_488(:)),max(blur_488(:))]);
title('blur 488');
h=msgbox('Press OK when you''re ready to move on','blur min background');
waitfor(h);
close(hFig);
if saveFlag==1
    save('background_min.mat','blur_BF','blur_chl','blur_405','blur_488','-append');
end


%%
fprintf('Congradulations! You created a background image!\n Now go on and analyze the data... Good luck.\n');
%%%%  ---- The End! ---- %%%%



