%% myroGFP function
%{
This function analyses the image after it was opened:
1. pre-processing
2. 405 channel: bg subtraction + thresholding. A separate threshold for cell tracking to get pixel indexes all over the cell
3. 488 channel: bg subtraction + thresholding.
4. Chl channel: bg subtraction + thresholding.
5. co-localization mask 
6. roGFP expression stack + mask
7. 405/488 ratio
8. oxD calculation
9. 405/chl AF ratio - stress ratio
10. segmentation
11. cell tracking
12. analysis: 
    12.1 get timepoints
    12.2 sytox 
    12.3 plots and intensities: oxidation, roGFP488, AF, chl
%}

% function myroGFP(imgMat, imgData, vars, output_folder,saveFlag)
%Initiation & preparations
% if nargin<5nFiles
%     saveFlag=0;
% end
%%
clearFlag=1; %clear unecessary variables along the way. keep 0 for debugging/developing only.
oldPath=cd(output_folder); %change folder to the output folder
% if saveFlag==1
%     oldPath=cd(output_folder); %change folder to the output folder
% end


%% 1. pre-processing
%Get the raw stacks, stabilize for XY drifting, and convert to double.
%filter the BF stack to remove noise from dirt on the camera etc.

%% get the channels and reshape to 3D
raw405 = reshape(imgMat(:,:,vars.ind405,:),size(imgMat,1),size(imgMat,2),size(imgMat,4)); % 405
raw488 = reshape(imgMat(:,:,vars.ind488,:),size(imgMat,1),size(imgMat,2),size(imgMat,4)); % 488
rawChl = reshape(imgMat(:,:,vars.indChl,:),size(imgMat,1),size(imgMat,2),size(imgMat,4)); % chlorophyll
rawBF = reshape(imgMat(:,:,vars.indBF,:),size(imgMat,1),size(imgMat,2),size(imgMat,4)); % bright field

nFrames = imgData.sizeT;
% t=10; %choose the frame for visualization
% if t>nFrames
t=round(nFrames/2);
% end
if clearFlag==1
    clear imgMat; %to clear memory 
    clear omeMeta;
end

%% save raw stacks
%saved as uint16 (which is the output of the reshape function)
if saveFlag==1  
    saveTiffStack(rawChl,'rawChl',output_folder,'none','none'); 
    saveTiffStack(raw405,'raw405',output_folder,'none','none'); 
    saveTiffStack(raw488,'raw488',output_folder,'none','none'); 
    saveTiffStack(rawBF,'rawBF',output_folder,'none','none'); 
end

%% Convert to double
raw405=double(raw405);
raw488=double(raw488);
rawChl=double(rawChl);
rawBF=double(rawBF);

%% Normalize the stacks
% Normalize to [0 1] according to the image bit-depth
raw405=raw405./vars.maxRange;
raw488=raw488./vars.maxRange;
rawChl=rawChl./vars.maxRange;
rawBF=rawBF./vars.maxRange;

%save the raw images
if saveFlag==1 
    save('ImgData.mat','rawChl', 'rawBF','raw405','raw488','nFrames');
end

%% subtract background (from an image)
% [final_Stack,SNR_stack,bgROI,bgMean]=subtractBackground(rawStack,t,method,bgROI,bgImg)
method=vars.bgMethod; %choose 'roi' or 'bgImage'
% method_option=vars.method_option; %choose 'subtract' or 'divide'
vars.bgROI=[]; %relevant only for bgMethod 'roi'. Leave empty, this is being used by the subtractBackground function.
bgROI=vars.bgROI;
if strcmp(vars.bgMethod,'bgImage')
    %load bgImage
    [bgName,bgPath] = uigetfile('*.mat','Choose background data file');
    bgImg=load([bgPath,bgName]);
    bg405=bgImg.blur_405;
    bg488=bgImg.blur_488;
    bgChl=bgImg.blur_chl;
    bgBF=bgImg.blur_BF;
    if clearFlag==1
        clear bgImg
    end
else
    bg405=[];
    bg488=[];
    bgChl=[];
    bgBF=[];
end
%%
[final405,SNR_405,vars.bgROI_roGFP,vars.bgMean405]=subtractBackground(raw405,t,method,bgROI,bg405);
[final488,SNR_488,vars.bgROI_roGFP,vars.bgMean488]=subtractBackground(raw488,t,method,vars.bgROI_roGFP,bg488);
[finalChl_unstable,SNR_chl,vars.bgROI_chl,vars.bgMeanChl]=subtractBackground(rawChl,t,method,[],bgChl);%different roi for chl and roGFP
[BF_difference,SNR_BF,~,vars.bgMeanBF]=subtractBackground(rawBF,t,method,[],bgBF);%BF has a different sign

%remove negative values
final405(final405<0)=0;
final488(final488<0)=0;
finalChl_unstable(finalChl_unstable<0)=0;


if saveFlag==1 
    save('ImgData.mat','bg405', 'bg488','bgChl','bgBF','BF_difference','-append');
end
if clearFlag==1
    clear bg405 bg488 bgChl bgBF BF_difference SNR_BF
end


    
%% BF filtering
% [filteredStack] = bandPassFilter(stack, lowPass, highPass, filterSize, manualChoice)
%manual choice  = to review the filtering
[BFfilt,vars.lowPass, vars.highPass, vars.filterSize] = bandPassFilter(rawBF, vars.lowPass, vars.highPass, vars.filterSize, vars.filtChoice,t);

%normalize the BF channel (global)
% [outputStack] = normalizeImage(stack,norm_method);
% norm_method = 'global' -> normalize to the global max and min of the stack
% norm_method = 'local' -> normalize each frame to its local max and min
BFfilt = normalizeImage(BFfilt,'global');

% if saveFlag==1
%     saveTiffStack(BFfilt,'BF_filt',output_folder,'uint16','none'); %save BF filt tiff stack
% %     saveTiffStack(rawBF,'BF',output_folder,'uint16','none'); %save BF tiff stack
%     save('ImgData.mat','BFfilt', '-append');
% end
if clearFlag==1
    clear rawBF;
end

%% Stabilize the stack (XY drift correction)
%{
%This function requires MIJI - running imageJ from within matlab.
% for help on miji: http://bigwww.epfl.ch/sage/soft/mij/
% or: http://imagej.net/Miji
%It requires to following: 
% 1. Install imageJ or FIJI on the computer.
% 2. download and install mij.jar and ij.jar in the java folder of matlab
% 3. add the 'scripts' folder inside the Fiji.app folder to the matlab path
% 4. make sure that the image stabilizer and image stabilizer log applyer
% are installaed as plugins in FIJI! can be downloaded from here: http://imagej.net/Image_Stabilizer
% This function stabilizes the first stack and then applyes stabilization
% on the rest of the stack. It can take up to 4 stacks.
%}
%{
% Stabilize the stack (XY drift correction)
%{
%This function requires MIJI - running imageJ from within matlab.
% for help on miji: http://bigwww.epfl.ch/sage/soft/mij/
% or: http://imagej.net/Miji
%It requires to following: 
% 1. Install imageJ or FIJI on the computer.
% 2. download and install mij.jar and ij.jar in the java folder of matlab
% 3. add the 'scripts' folder inside the Fiji.app folder to the matlab path
% 4. make sure that the image stabilizer and image stabilizer log applyer
% are installaed as plugins in FIJI! can be downloaded from here: http://imagej.net/Image_Stabilizer
% This function stabilizes the first stack and then applyes stabilization
% on the rest of the stack. It can take up to 4 stacks.
%}
OpenFlag=1; %Miji open choice: 1-open, 0-don't open. choose 1, unless Miji is already opened.
CloseFlag=1; %Miji close choice: 1-close, 0-don't close. choose 1, unless you're going to use miji at a later stage as well. 
if nFrames>1
    [rawChl,raw405,raw488,rawBF] = ImageStabilizer(output_folder,rawChl,raw405,raw488,rawBF,OpenFlag,CloseFlag,saveFlag);
    cd(output_folder);
end
%}
OpenFlag=1; %Miji open choice: 1-open, 0-don't open. choose 1, unless Miji is already opened.
CloseFlag=1; %Miji close choice: 1-close, 0-don't close. choose 1, unless you're going to use miji at a later stage as well. 
if nFrames>1
    CloseFlag=0;
    [finalChl,final405,final488,BFfilt] = ImageStabilizer(output_folder,finalChl_unstable,final405,final488,BFfilt,OpenFlag,CloseFlag,saveFlag);
    OpenFlag=0;
    CloseFlag=1;
    [finalChl_forSNR,SNR_405,SNR_488,SNR_chl] = ImageStabilizer(output_folder,finalChl_unstable,SNR_405,SNR_488,SNR_chl,OpenFlag,CloseFlag,saveFlag,'SNR_stabilizer_log');
    cd(output_folder);
end

if ~exist('finalChl','var')
    finalChl=finalChl_unstable;
end
    
if saveFlag==1 
    save('ImgData.mat','SNR_405', 'SNR_488','SNR_chl','finalChl','final405','final488','BFfilt','-append');
    saveTiffStack(final405,'final405',output_folder,'uint16','none'); %save BF filt tiff stack
    saveTiffStack(final488,'final488',output_folder,'uint16','none'); %save BF filt tiff stack
    saveTiffStack(finalChl,'finalChl',output_folder,'uint16','none'); %save BF filt tiff stack
    saveTiffStack(BFfilt,'BFfilt',output_folder,'uint16','none'); %save BF filt tiff stack
end

if clearFlag==1
    clear finalChl_forSNR finalChl_unstable SNR_405 SNR_488 SNR_chl
end



%% optional - threshold BF
%{
% local normalization
% BF_norm=normalizeImage(BFfilt,'local');
% % imshow(BF_norm(:,:,t));
% figure;
% t=40;
% imshowpair(BF_norm(:,:,t),BFfilt(:,:,t),'montage');
% vars.thrBFlow=0.01;
% vars.thrBFup=Inf;
% [finalBF,thrBF,vars.thrBFlow,vars.thrBFup] = imgThreshold('bf',vars.thrBFlow,vars.thrBFup,BF_norm,vars,t);
% thrLow = min(BFfilt(:))+((max(BFfilt(:))-min(BFfilt(:)))/2);
% thrUp = Inf;
% thrBF=simpleThreshold(BFfilt, thrLow, thrUp, 'BF final',t);
% close();
%}

%% 2. thresholding 405 channel
% [bgStack, thrStack,thrLow,thrUp] = imgThreshold(channelName, thrLow, thrUp, imgMat, vars, timepoint)
% [final405,thr405,vars.thr405low,va`rs.thr405up,vars.bgROI] = imgThreshold('405',vars.thr405low,vars.thr405up,raw405,vars,t);
[thr405,vars.thr405low,vars.thr405up]=simpleThreshold(final405,vars.thr405low,vars.thr405up,'roGFP405 threshold',t);

%thr_405cells: a separate threshold for cellmask, to be used for tracking 
%to get pixel indexes all over the cell.
[thr_405cells,vars.thr405lowCells,vars.thr405upCells]=simpleThreshold(final405,vars.thr405lowCells,vars.thr405upCells,'405 cells threshold',t);
close();

if saveFlag==1
    saveTiffStack(final405,'final405',output_folder,'uint16','none'); %save final405 after background subtraction

    save('ImgData.mat','final405','thr405','thr_405cells','-append');
end
if clearFlag==1
    clear raw405;
end

%% view a movie of the 405 mask
pauseTime=0.1;
viewMaskMovie(BFfilt,thr405,pauseTime,'405 mask overlay');

%% view a movie of the 405 cells mask
pauseTime=0.1;
viewMaskMovie(BFfilt,thr_405cells,pauseTime,'405 cells mask overlay');

%% 3. thresholding 488 channel
% [final488,thr488,vars.thr488low,vars.thr488up] = imgThreshold('488',vars.thr488low,vars.thr488up,raw488,vars,t,vars.bgROI);
[thr488,vars.thr488low,vars.thr488up]=simpleThreshold(final488,vars.thr488low,vars.thr488up,'roGFP488 threshold',t);
if saveFlag==1
    saveTiffStack(final488,'final488',output_folder,'uint16','none'); %save final488 after background subtraction
    save('ImgData.mat','final488','thr488','-append');
end
if clearFlag==1
    clear raw488;
end
close();
%% view a movie of the 488 mask
pauseTime=0.1;
viewMaskMovie(BFfilt,thr488,pauseTime,'488 mask overlay');

%%
% maskOverlay = imoverlay(BFfilt(:,:,t), thr488(:,:,t), [1 0 0]);
% imshow(maskOverlay,'InitialMagnification', 150);
% titleStr=sprintf('%s, frame: %g','488 mask overlay',t);
% title(titleStr);
    
%% view a video of the stack frame by frame in false-color
%This shows a video of the 405 vs. the 488 channel - the difference between
%the channels is color-coded. This is not a ratio image, but just to get
%the sense of it!

% hFig=figure('Position', [150, 50, size(final488,2).*2, size(final488,1).*1.8]);
% pauseTime=0.1;
% 
% for i=1:nFrames 
%    imshowpair(final488(:,:,i),final405(:,:,i),'ColorChannels','green-magenta');
%    titleStr=sprintf('roGFP difference. 488-green. 405-magenta. Frame: %g',i);
%    title(titleStr);
%    hold on
%    drawnow 
%    pause(pauseTime);
% end
% h=msgbox('Press OK when you''re ready to move on','405-488 false colour');
% waitfor(h);
% close(hFig);

%% 4. threshold the chl channel
% [finalChl,thrChl,vars.thrChlLow,vars.thrChlUp] = imgThreshold('chl',vars.thrChlLow,vars.thrChlUp,rawChl,vars,t);


[thrChl,vars.thrChlLow,vars.thrChlUp]=simpleThreshold(finalChl,vars.thrChlLow,vars.thrChlUp,'Chlorophyll threshold',t);

if saveFlag==1
    saveTiffStack(finalChl,'finalChl',output_folder,'uint16','none'); %save chl after background subtraction
    save('ImgData.mat','finalChl','thrChl','-append');
end
if clearFlag==1
    clear rawChl;
end
%normalize the chl channel (local)
% [outputStack] = normalizeImage(stack,norm_method);
% norm_method = 'global' -> normalize to the global max and min of the stack
% norm_method = 'local' -> normalize each frame to its local max and min
close();

%% view a movie of the chl mask
pauseTime=0.2;
viewMaskMovie(BFfilt,thrChl,pauseTime,'Chl mask overlay');

%% 5. co-localization mask
%create a mask of co-localized pixels in the 405 and 488 channels
colocalizationMat = thr405>0 & thr488>0; 

if saveFlag==1
    save('ImgData.mat','colocalizationMat','-append');    
end
if clearFlag==1
%     clear thr405 thr488;
end

%% view a movie of the colocalization mask
% pauseTime=0.2;
% viewMaskMovie(BFfilt,colocalizationMat,pauseTime,'co-localization mask overlay');

%To view a timepoint of the mask:
% h=figure;
% viewFrame(colocalizationMat, t, [0 1], 'colocalization','gray');
% hMsg=msgbox('Press OK when you''re ready to move on','colocalization');%Wait for user to view the image
% waitfor(hMsg);
% close(h);

%% 6. roGFP expression stack
roGFPexpress = final405.*final488; %roGFP expression image
% roGFPexpress(~colocalizationMat)=NaN; %remove pixels that are not co-localized. If this is done before normalization, the min value of the normalized stack doesn't include background values.
norm_expression = normalizeImage(roGFPexpress,'global'); %normalize the roGFP expression - 'local' or 'global'
norm_expression(~colocalizationMat)=NaN; %remove pixels that are not co-localized. If this is done after normalization, the min value of the normalized stack includes background values.

%% view normalized roGFP expression (single timepoint)
hFig = figure;
cRange = [min(norm_expression(:)), max(norm_expression(:))]; %color range
% t=20;
ColorMap='jet';
viewFrame(norm_expression, t, cRange, 'roGFP normalized expression', ColorMap);
hMsg=msgbox('Press OK when you''re ready to move on','roGFP normalized expression');%Wait for user to view the image
waitfor(hMsg);
% [figH] = viewFrame(roGFPexpress, t, cRange, 'roGFP expression', ColorMap);
close(hFig);

%% Threshold the expression image
[thr_expression,vars.thrExprLow,vars.thrExprUp]=simpleThreshold(norm_expression,vars.thrExprLow,vars.thrExprUp,'roGFP expression',t);
close();
thr_expression(~colocalizationMat)=0; %remove pixels that aren't co-localized

if saveFlag==1
    saveTiffStack(roGFPexpress,'roGFP_expression',output_folder,'uint16','global'); %save roGFPexpression stack
    saveTiffStack(norm_expression,'roGFP_expression_norm',output_folder,'uint16','none'); %save normalized expression stack
    save('ImgData.mat','roGFPexpress','norm_expression','thr_expression','-append');
end

%% view a movie of the expression mask
pauseTime=0.2;
viewMaskMovie(BFfilt,thr_expression,pauseTime,'roGFP expression mask overlay',saveFlag,output_folder);

% h = figure;
% cRange = [0 1]; %color range
% % t=40;
% ColorMap='gray';
% [figH] = viewFrame(thr_expression, t, cRange, 'roGFP expression mask', ColorMap);
% hMsg=msgbox('Press OK when you''re ready to move on','roGFP expression mask');%Wait for user to view the image
% waitfor(hMsg);
% close(h);

%% 7. 405/488 ratio
%calculate the ratio between 405 and 488 channels pixel by pixel in the
%positions that were above the threshold
ratioStack = final405./final488;
if strcmp(vars.roGFP_maskType,'expression') %depending on mask choice in the vars function
    roGFPmask = thr_expression;
else 
    roGFPmask=colocalizationMat;% if not expression use co-localization    
end
ratioStack(~roGFPmask)= NaN; %remove pixels that are not in the mask

if saveFlag==1
    saveTiffStack(ratioStack,'roGFP_ratio',output_folder,'uint16','global'); %save roGFPratio tiff stack
    save('ImgData.mat','ratioStack','-append');    
end

%% plot the roGFP ratio of timepoint t
%use the function viewFrame:
% [figH] = viewFrame(stack, t, cmin, cmax, stackName)
% t = 20;
stackName = 'roGFP ratio';
cRange = [vars.Rred vars.Rox]; %color range
h=figure;
ColorMap='jet';
viewFrame(ratioStack, t, cRange, stackName, ColorMap);
hMsg=msgbox('Press OK when you''re ready to move on',stackName);%Wait for user to view the image
waitfor(hMsg);
close(h);

%% 8. oxD calculation
%create a stack of oxD calculated pixel by pixel according to the equation:
% oxD = ((R-Rred)/((I488ox/I488red)*(Rox-R)+(R-Rred)));
R=ratioStack(roGFPmask); %choose pixels that are relevant
oxDstack = NaN(size(ratioStack)); %create oxD stack
%calculate pixel by pixle oxD for the relevant pixels:
oxDstack(roGFPmask) = ((R-vars.Rred)./((vars.i488ox_red).*(vars.Rox-R)+(R-vars.Rred)));

if saveFlag==1
    saveTiffStack(oxDstack,'OxD',output_folder,'uint16','none'); %save OxD stack
    save('ImgData.mat','oxDstack','-append');  
end
if clearFlag==1
    clear R;
end

%% plot the oxD of timepoint t
% t = 10;
% cRange = [0 1]; %color range
% h = figure;
% [figH] = viewFrame(oxDstack, t, cRange, 'oxD');
% hMsg=msgbox('Press OK when you''re ready to move on','oxD');%Wait for user to view the image
% waitfor(hMsg);
% close(h);

%% view a movie of oxD
cRange = [-0.1 1.2]; %color range
h = figure;
pauseTime=0.5;
% titlestr=sprintf('oxD. Time post %s treatment:  %s  ',vars.treatLables{1},vars.Treat_dT_label{1}{i});
% figH = viewFrame(oxDstack, i, cRange, titlestr); 
% % figH = viewFrame(oxDstack, i, cRange, 'oxD'); 
% hold on
% pause(pauseTime);
% position=[10,10];
titlestr=sprintf('oxD, time stamp = time post %s treatment',vars.treatLables{1});
for i=1:nFrames
    if i~=1
        cla(figH,'reset')
    end
%     titlestr=sprintf('oxD: Time post %s treatment:  %s  ',vars.treatLables{1},vars.Treat_dT_label{1}{i});
    text_str=vars.Treat_dT_label{1}{i};
%     I=oxDstack(:,:,i);
%     text_str=sprintf('Time post %s treatment:  %s  ',vars.treatLables{1},vars.Treat_dT_label{1}{i});
%     RGB = insertText(I,position,text_str,'FontSize',16,'BoxColor',...
%         'yellow','BoxOpacity',0.4,'TextColor','white');
%     figH = viewFrame(RGB, 1, cRange, titlestr);
    figH = viewFrame(oxDstack, i, cRange, titlestr);
    text(7,10,text_str,'Color','white','FontSize',14);

%     figH = viewFrame(oxDstack, i, cRange, 'oxD'); 
    if i==1
        hold on
    end
    pause(pauseTime);   
end
hMsg=msgbox('Press OK when you''re ready to move on','oxD');%Wait for user to view the image
waitfor(hMsg);
close(h);


%% 9. 405/chl AF ratio - stress ratio
%create a stack of the 405/chl AF ratio
AFstack=final405./finalChl;
AFstack(~thrChl)=NaN;%remove pixels without chlorophyll
AFstack = normalizeImage(AFstack,'global'); %normalize the roGFP expression - 'local' or 'global'
if saveFlag==1
    saveTiffStack(AFstack,'AF_405_chl',output_folder,'uint16','none'); %save AF stack
    save('ImgData.mat','AFstack','-append');  
end

%% view a movie of AF ratio
% cRange = [min(AFstack(:)), max(AFstack(:))]; %color range
% h = figure;
% pauseTime=0.1;
% ColorMap='jet';
% i=1;
% figH = viewFrame(AFstack, i, cRange, '405/chl ratio',ColorMap);
% hold on
% pause(pauseTime);
% for i=2:nFrames
%     cla(figH,'reset')
%     figH = viewFrame(AFstack, i, cRange, '405/chl ratio',ColorMap);
% %     hold on
%     pause(pauseTime);   
% end
% hMsg=msgbox('Press OK when you''re ready to move on','oxD');%Wait for user to view the image
% waitfor(hMsg);
% close(h);


%% 11. cell segmentation
% The segmentation type depends on the choice in vars.segType.
% There are 3 options: 'mySegmentation', 'Fiji' or 'Mask only'.
%All use a mask stack, which depends on vars.maskType.
%options for mask type: 'expression', 'co-localization', 'Chl', '405'. 

switch vars.maskType
    case 'expression'
        maskStack=thr_expression;
        intStack=norm_expression;
    case 'co-localization'
        maskStack=colocalizationMat;
        intStack=norm_expression;
    case 'Chl'
        maskStack=thrChl;
        intStack=finalChl;
    case '405'
        maskStack=thr_405cells;
        intStack=final405;
    otherwise
        maskStack=colocalizationMat;
        intStack=norm_expression;
end

% vars.maskType='thr_405cells';
% IntStack=final405; %based on 405 intensity
% [cellsMask,segStack,vars]=stackSegmentation(maskStack,IntStack,vars.segType,vars); %segmentation
% vars.distType='intensity'; %choose either 'intensity', 'distance' or 'combined'. 
% intStack=roGFPexpress;
[cellsMask,~,vars]=stackSegmentation(maskStack,intStack,vars.segType,vars,vars.distType); %segmentation

if saveFlag==1
    save('ImgData.mat','cellsMask','-append');    
end
if clearFlag==1
    clear maskStack;
end
%% view a movie of the cell mask
pauseTime=0.3;
viewMaskMovie(BFfilt,cellsMask,pauseTime,'cells mask overlay',saveFlag,output_folder);
%% segment the roGFP signal - no need for that at the moment
%{
% maskStack=colocalizationMat;
% IntStack=roGFPexpress; %based on 405 intensity
% [roGFP_mask,roGFP_seg]=stackSegmentation(maskStack,IntStack,vars.segType,vars); %segmentation
% if saveFlag==1
%     save('ImgData.mat','roGFP_mask','-append');
%     if exist('roGFP_seg','var')
%         save('ImgData.mat','roGFP_seg','-append');
%     end        
% end
%% view a movie of the roGFP mask
% pauseTime=0.3;
% viewMaskMovie(BFfilt,cellsMask,pauseTime,'roGFP mask overlay');

%% display one timepoint in pseudocolor
% t=40;
% I_segmented = segStack(:,:,t);
% I_segColor = label2rgb(I_segmented,'jet',[.5 .5 .5]);
% figure;
% imshow(I_segColor,'InitialMagnification',150);
% title(sprintf('Watershed transform of roGFP488, frame %g, sigma %g',t, sigma));
% h=msgbox('Press OK when you''re ready to move on','Segmentation');
% waitfor(h);
% close();
%}

%% get cells properties
% cellsProps(t) holds the properties of the cells in frame t of the cellMask stack.
%{
% you can access a specific property as follows:
% cellsProps(t).PixelIdxList{i} = pixel indexes of cell i
% cellsProps(t).X(i)= width of each cell
% cellsProps(t).Y= height
% cellsProps(t).A= area
% cellsProps(t).AvgInt= average intensity
% cellsProps(t).MaxInt= max intensity
% cellsProps(t).MinInt= min intensity
% cellsProps(t).SumInt= sum intensity
% cellsProps(t).Ecc= Eccentricity
% cellsProps(t).MajAx= MajorAxisLength 
% cellsProps(t).MinAx= MinorAxisLength 
% cellsProps(t).Ang= Orientation 
% cellsProps(t).Frame= frame
% cellsProps(t).Conv= Conversion factor from pixel to um
%}
% [cellsProps] = myCellsProps(stack,intStack,cellsMask,ConvFactor,frameRate)
%choose stack to find the centers of the cells (for tracking)
switch vars.centersStack
    case 'Chl'
        centersStack=finalChl;
    case '405'
        centersStack=final405;
    case '488'
        centersStack=final488;
    case 'expression'
        centersStack=norm_expression;
    otherwise
        centersStack=intStack;
end

%choose stack to measure intensity of the cells over time (for tracking)
switch vars.intStack
    case 'oxD'
        intStack=oxDstack;%Stack for property measurements
    case '405'
        intStack=final405;
    case '488'
        intStack=final488;
    case 'AF'
        intStack=AFstack;
    case 'ratio'
        intStack=ratioStack;
    otherwise
        disp('the same intStack was used for segmentation and tracking');
end

[cellsProps] = myCellsProps(intStack,centersStack,cellsMask,vars.convFactor,vars.frameRate); %norm_expression instead of final488 %use oxDstack to measure properties. use bg488 to detect centers of the cells.

%% view cells detected over time 
cellNum=arrayfun(@(Q) length(Q.X),cellsProps)'; %array of cell numbers per frame
figure(1); clf; plot(cellNum);
%view avg. intensity vs. area 
% figure(2); clf; PlotParticles(cellsProps); colormap(jet)
h=msgbox('Press OK when you''re ready to move on','Cell detection');
waitfor(h);
close();
if saveFlag==1
    save('TrackData.mat','cellsProps');
end
if clearFlag==1
    clear intStack centersStack;
end
%% filter identified cells according to various properties
% [filt_cells] = cellsFilter(cellsProps,filtFeature,minValue,maxValue,stack,t)
% t=10;
t=25;
viewStack=final405;%BFfilt %final488
[filt_cells,vars.minArea,vars.maxArea] = cellsFilter(cellsProps,'A',vars.minArea,vars.maxArea,viewStack,t); %filter the cells by area (5 to 120 pixels per cell).
% [filt_cells,vars.minEcc,vars.maxEcc] = cellsFilter(filt_cells,'Ecc',vars.minEcc,vars.maxEcc,viewStack,t); %filter the cells by eccentricity
[filt_cells,vars.minMajAx,vars.maxMajAx] = cellsFilter(filt_cells,'MajAx',vars.minMajAx,vars.maxMajAx,viewStack,t); %filter the cells by Major axis
[filt_cells,vars.minMinAx,vars.maxMinAx] = cellsFilter(filt_cells,'MinAx',vars.minMinAx,vars.maxMinAx,viewStack,t); %filter the cells by minor axis
% [filt_cells] = cellsFilter(cellsProps,'SumInt',5,100,final488,t); %filter the cells by sum of intensity
if clearFlag==1
    clear viewStack;
end

%% plot number of cells over time after trimming
cellNum=arrayfun(@(Q) length(Q.X),filt_cells)'; %array of cell numbers per frame
figure(1); clf; plot(cellNum);
h=msgbox('Press OK when you''re ready to move on','Cell detection');
waitfor(h);
close();

if saveFlag==1
    save('TrackData.mat','filt_cells','-append');
    save('vars.mat','vars'); 
end
if clearFlag==1
    clear cellsProps
end

%% view a movie of the identified cells (after filtering)
% TestTrack2(stack,PTA,pauseTime,cmap,cRange)
pauseTime=0.2;
TestTrack2(BFfilt,filt_cells,pauseTime);
% TestTrack2(final488,filt_cells,pauseTime);
% cmap=jet;
% cRange=[0,1];
% TestTrack2(oxDstack,filt_cells,pauseTime,cmap,cRange);
h=msgbox('Press OK when you''re ready to move on','Cell detection');
waitfor(h);
close();
close();

%% 12. Cell tracking
% track the cells. now it only worls with 'position' mode, but in the
% future I'll add the option of velocity or acceleration.
% vars.TrackMode = 'position';   % Choice of {position, velocity, acceleration} to predict position based on previous behavior
% vars.DistanceLimit = 15;  %8          % Limit of distance a particle can travel between frames, in units defined by ConversionFactor
% vars.MatchMethod = 'best';         % Choice of {best, single}
% [ParticleOut] = trackMyCells(particles, trackmode, Rmax, matchmethod);
[cellTracks] = trackMyCells(filt_cells, vars.TrackMode, vars.DistanceLimit, vars.MatchMethod);

if saveFlag==1
    save('TrackData.mat','cellTracks','-append');
end
if clearFlag==1
    clear filt_cells
end
%% Calculate Fitted Position, Velocity, and Acceleration
% vars.FitLength=1;    %This describes the type and size of fitting for calculation, 
%                 % 0 - first order difference
%                 % 1 - second order difference
%                 % n>1 - polynomial fit, must be equal or larger than MinFrameLength
fps = vars.frameRate;

% [OutputStruct] = Trajectory2(ParticleTracks,fitlength,fps);                
tracks_analysis = Trajectory2(cellTracks,vars.FitLength,fps); %Calculate Track Properties
% The output "tracks_analysis" is a structure array with each structure
% element in the array representing a different track.
% P_Tracks_Analysis - in addition to the fields from the particle tracking (ie X, Y, Area, etc):
%                  .XFit - a vector of the fitted X position 
%                  .YFit - a vector of the fitted Y position
%                  .VelX - a vector of the X velocity based on the fitted position
%                  .VelY - a vector of the Y velocity based on the fitted position
%                  .AccX - a vector of the X acceleration based on the fitted position
%                  .AccY - a vector of the Y acceleration based on the fitted position
%                  .Fit  - a single number representing the fit length used for calculation
%                  .FPS  - a single number representing capture rate
%                  .Conv - a single number for the conversion factor in um/pixel
if clearFlag==1
    clear cellTracks
end

%% connect tracks with missing frames
%In this stage you can only use 'position' because the velocity and
%acceleration weren't calculated yet. If you do want to use it with
%velocity or acceleration please do so after trimming the unwanted tracks.
% MaxMissed=2;
% Calculate Fitted Position, Velocity, and Acceleration
% FitLength=0;    %This describes the type and size of fitting for calculation, 
                % 0 - first order difference
                % 1 - second order difference
                % n>1 - polynomial fit, must be equal or larger than MinFrameLength
                
                %*** from some reason it doesn't work well with n>1!!!! 
                %ask Vicente!!!
            
% trackmode_link = 'position';
% trackmode_fill = 'position';
% P_Tracks_Analysis = TrackLinker(P_Tracks_Analysis, 'velocity','velocity', DistanceLimit, FitLength, MaxMissed);
% [ParticleTracks] = TrackLinker2(ParticleTracks, trackmode_link, trackmode_fill, R_max, fitlength, T_miss_max)
linked_tracks = TrackLinker2(tracks_analysis, vars.trackmode_link, vars.trackmode_fill, vars.DistanceLimit, vars.FitLength, vars.maxMissed);
if clearFlag==1
    clear tracks_analysis
end
%% Track Trimming
% Trim Tracks based on length.
vars.MinFrameLength=6; %Set the minimum number of frames for a track of interest, needs to be at least > 2*FitLength
Track_Length=arrayfun(@(Q) length(Q.X),linked_tracks); %Find track lengths
trim_tracks=linked_tracks(Track_Length>vars.MinFrameLength); %Trim tracks with less than desired length
vars.trackTrimmingFlag=1; %if the tracks were trimmed or not  
if clearFlag==1
    clear linked_tracks
end

%% without track trimming
% trim_tracks=linked_tracks;
%% re-calculate track features after linking and trimming               
tracks_analysis = Trajectory2(trim_tracks,vars.FitLength,fps); %Calculate Track Properties
if saveFlag==1
    save('TrackData.mat','tracks_analysis','-append');
end
if clearFlag==1
    clear trim_tracks
end
%% reshape the tracks structure and sort it by time
final_tracks=ParticleTracks2Time2(tracks_analysis); 
%final_tracks has the same fields as "tracks_analysis", but it is sorted by time.
%Each element of final_tracks is a single frame.
if saveFlag==1
    save('TrackData.mat','final_tracks','-append');
end

%% Plot tracks statistics
% Plot the resulting data distribution
figure; 
PlotTrackStats2(tracks_analysis); 
h=msgbox('Press OK when you''re ready to move on','Tracks analysis');
waitfor(h);
close();

% Plot the Tracks & overlay velocity
figure; 
PlotTracks2(tracks_analysis);
h=msgbox('Press OK when you''re ready to move on','Tracks analysis');
waitfor(h);
close();

%Plot the velocity distribution over time
hFig=figure; 
clf; 
PlotParticleVel2(final_tracks);
title('Velocity over time');
if saveFlag==1
    savefig(hFig,'velocity_over_time.fig');    
end
h=msgbox('Press OK when you''re ready to move on','Tracks analysis');
waitfor(h);
close(hFig);

% y_field='Intensity';
% figure; 
% clf; 
% PlotHist(final_tracks,y_field)
% h=msgbox('Press OK when you''re ready to move on','Tracks analysis');
% waitfor(h);
% close();
% Look at the overall tracking result (with fitted positions)
% TestTrack(FileStruct,PTA,fps,ConversionFactor,FilterParameters)
%green - the start of a new track
%red - the end of the track

%% plot number of tracks over time after trimming
trackNum=arrayfun(@(Q) length(Q.TrackID),final_tracks)'; %array of cell numbers per frame
hFig=figure; 
clf; 
plot(trackNum);
title('Tracks over time');
if saveFlag==1
    savefig(hFig,'tracks_over_time.fig'); 
    print('tracks_over_time','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','Tracking');
waitfor(h);
close(hFig);

%% View the final tracking
pauseTime=0.2;
TestTrack2(BFfilt,final_tracks,pauseTime);
h=msgbox('Press OK when you''re ready to move on','Tracks analysis');
waitfor(h);
close();
close();

% PlotMyTrack(BFfilt,final_tracks,cellsMask,pauseTime)
% h=msgbox('Press OK when you''re ready to move on','Tracks analysis');
% waitfor(h);
% close();

%% 12. analysis

%% 12.1 add the time post treatment to the tracking structure - as number
framesArray=1:nFrames;
% [d_num,t_num]=split(vars.Treat_dT{1},{'days','time'});
H_post_treat1=vars.H_post_treat1;
for i=1:length(tracks_analysis)
    for j=1:length(tracks_analysis(i).Frame)
        frameIdx=framesArray==tracks_analysis(i).Frame(j);
        tracks_analysis(i).Treat1_dT(j,1)=vars.Treat_dT{1}(frameIdx);
        tracks_analysis(i).Treat1_Hours(j,1)=vars.H_post_treat1(frameIdx);
        tracks_analysis(i).Treat1_dT_label(j,1)=vars.Treat_dT_label{1}(frameIdx);
    end
end

% if clearFlag==1
%     clear d_str H_str MN_str sign signInd d_num H_num MN_num
% end

%% 12.2 Sytox

%get the timepoints of the sytox treatment, and a specific timepoint to
%be used for labeling the cells "dead" or "alive".
idxSyt=(vars.timeArray>=vars.treatTime(2));%get the index of the timepoints after sytox treatment
idxSytStart=find(vars.timeArray>=vars.treatTime(2),1);%the index of the first frame of the sytox treatment

%let the user choose the timepoint to be used for sytox analysis
prompt=sprintf('Select %s treatment timepoint:\n',vars.treatLables{2});
list=vars.Treat_dT_label{2}(idxSyt);
sytAnswer='No'; %for the while loop initiation
scrsz = get(groot,'ScreenSize'); %get the screen size for the plot

while strcmp(sytAnswer,'No')    
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
    
    idxSytF=find(strcmp(vars.Treat_dT_label{2}, list(Selection))); %the number of the selected sytox frame. This option is better for the analysis later.

    %view the chosen frames with the two next to it
%     scrsz = get(groot,'ScreenSize');
    h=figure('Position',[scrsz(3)*0.02 scrsz(4)*0.05 scrsz(3)*0.95 scrsz(4)*0.86]);
    % h=figure('Position', [150, 50, size(final488,2).*2, size(final488,1).*1.8]);
    h1=subplot(1,3,1);
    p = get(h1, 'pos');
    p(1) = p(1)-0.12;
    p(3) = p(3) + 0.1;
    p(4) = p(4) + 0.1;
    set(h1, 'pos', p);
    imshow(final488(:,:,idxSytF-1),'InitialMagnification',150);
    axis image
    titleStr=sprintf('channel 488 frame %g',idxSytF-1);
    title(titleStr);

    h2=subplot(1,3,2);
    p = get(h2, 'pos');
    p(1) = p(1)-0.07;
    p(3) = p(3) + 0.1;
    p(4) = p(4) + 0.1;
    set(h2, 'pos', p);
    imshow(final488(:,:,idxSytF),'InitialMagnification',150);
    axis image
    titleStr=sprintf('channel 488 frame %g (chosen)',idxSytF);
    title(titleStr);

    h3=subplot(1,3,3);
    p = get(h3, 'pos');
    p(1) = p(1)-0.02;
    p(3) = p(3) + 0.1;
    p(4) = p(4) + 0.1;
    set(h3, 'pos', p);
    imshow(final488(:,:,idxSytF+1),'InitialMagnification',150);
    axis image
    titleStr=sprintf('channel 488 frame %g',idxSytF+1);
    title(titleStr);
    
    %ask the user to confirm the choice
    qstring = 'Are you happy with the chosen frame?';
    sytAnswer = questdlg(qstring,'Sytox frame');
    close(h);
end

% close(h);

% idxSytF=strcmp(vars.Treat_dT_label{2}, list(Selection)); %the index of the selected sytox frame.
% sytoxStack=final488(:,:,idxSyt); %stack of all the sytox data (after sytox treatment)
Im_syt=final488(:,:,idxSytF); %the image to be used for the analysis



fprintf('Sytox treatment started at %s, frame: %g\n',datestr(vars.timeArray(idxSytStart)),idxSytStart);
fprintf('The frame chosen for sytox analysis is: %g,  %s post sytox treatment\n',idxSytF,vars.Treat_dT_label{2}{idxSytF});

if clearFlag==1
    clear h h1 h2 h3 p qstring sytAnswer titleStr prompt list
    
end

%% View the chosen frame overlayed on BF
hFig=figure;
titleStr='Sytox and bright field overlay';
cmap = [0,1,0]; %colormap
rgbImg = falseColor(Im_syt,cmap);
imshow(BFfilt(:,:,idxSytF),'InitialMagnification', 150);
% h1.AlphaData=0.5;
hold on
h2=imshow(rgbImg, 'InitialMagnification', 150);
h2.AlphaData=0.7;
axis image;
title(titleStr);
hMsg=msgbox('Press OK when you''re ready to move on','Sytox');%Wait for user to view the image
waitfor(hMsg);
close(hFig);

clear h1 h2 hFig

%% Sytox threshold 
hFig=figure;
[thr_sytox,vars.thrSytLow,vars.thrSytUp]=simpleThreshold(Im_syt,vars.thrSytLow,vars.thrSytUp,'Sytox threshold',1);
hMsg=msgbox('Press OK when you''re ready to move on','Sytox threshold');%Wait for user to view the image
waitfor(hMsg);
% [figH] = viewFrame(roGFPexpress, t, cRange, 'roGFP expression', ColorMap);
close(hFig);

if saveFlag==1
    saveTiffStack(Im_syt,'Sytox_frame',output_folder,'uint16','none'); 
    save('ImgData.mat','idxSyt','idxSytStart','idxSytF','Im_syt','thr_sytox','-append'); 
end
%% Sytox analysis
vars.minOverlap=2;
%assign the "live" or "dead" label based on co-localization of the sytox
%signal and the cell mask.
% vars.minOverlap=2; %choose the minimum pixel overlap of the sytox and the cell 
    %mask to decide whether the cell was stained or not. Example: 
    %if minOverlap=2, atleast two pixels of the cell mask and the sytox
    %mask should overlap.
for i=1:length(tracks_analysis) %loop through the cells
    frameIdx=tracks_analysis(i).Frame==idxSytF;%get the index of the sytox timepoint. This can be adapted to multiple timepoints in the future. 
    if sum(frameIdx)==0 %the cell wasn't detected in the sytox frame
        tracks_analysis(i).cellFate='unknown'; %assign unknown fate
        tracks_analysis(i).SytoxOverlap=NaN; %assign NaN for sytox overlap
        tracks_analysis(i).fateColor=[0,0,0];%black color for unknown
%         tracks_analysis(i).fateColor2=[0,0,0];%black color for unknown
    elseif sum(frameIdx)==1 %the cell was detected in the sytox frame
        cellIdx=tracks_analysis(i).PixelIdxList{frameIdx,1}; %get the cell mask indexes of this timepoint
        if isnan(cellIdx) %If there is no cellIndx for that frame - because this cell was linked (missing frame linking)
            tracks_analysis(i).cellFate='unknown'; %assign unknown fate
            tracks_analysis(i).SytoxOverlap=NaN; %assign NaN for sytox overlap
            tracks_analysis(i).fateColor=[0,0,0];%black color for unknown
%             tracks_analysis(i).fateColor2=[0,0,0];%black color for unknown
            continue %go to the next loop
        end
        %Create a diluted (larger) cell mask
        cell_i_mask=false(size(thr_sytox));
        cell_i_mask(cellIdx)=true;
        se = strel('square',5);%structuring element for dilation.
        dilated = imdilate(cell_i_mask,se); %each cell is dilated by 2 pixels (5X5 square around each "positive" pixel)
        tracks_analysis(i).SytoxOverlap=sum(thr_sytox(dilated));%get the sum of the overlaping pixels.
        
        %Other options for dilation/ellipse:
        %{
%         se = strel('square',3);%5 %structuring element for dilation.-dilate 1 pixel in all directions
%         dilated = imdilate(cell_i_mask,se); %each cell is dilated by 2 pixels (5X5 square around each "positive" pixel)
%         se2 = strel('line',7,tracks_analysis(i).Ang(frameIdx)); %dilate more pixels of the major axis according to the cell's angle (since the cells are elongated)
%         dilated = imdilate(dilated,se2);
        %To view each cell before and after dilation uncomment this part:
%         hFig=figure;      
%         ellipse_position=[tracks_analysis(i).X(frameIdx),tracks_analysis(i).Y(frameIdx),
%             [xmin ymin width height].
        
%         h1=imshowpair(dilated,cell_i_mask,'ColorChannels','green-magenta');%'montage'
%         hold on
%         h2=imshow(BFfilt(:,:,idxSytF));
%         h2.AlphaData=0.7;
%         title('dilated, raw');

%         DrawEllipse(tracks_analysis(i).MajAx(frameIdx)*3, tracks_analysis(i).MinAx(frameIdx)*2,tracks_analysis(i).Ang(frameIdx), tracks_analysis(i).X(frameIdx), tracks_analysis(i).Y(frameIdx), 'b');
%         %Create ellipse mask - not working well yet
%         X0=tracks_analysis(i).X(frameIdx); %Coordinate X
%         Y0=tracks_analysis(i).Y(frameIdx); %Coordinate Y
%         l=tracks_analysis(i).MajAx(frameIdx); %Length (half)
%         w=tracks_analysis(i).MinAx(frameIdx); %Width (half)
%         phi=tracks_analysis(i).Ang(frameIdx); %Degree you want to rotate
%         [X1,Y1] = meshgrid(1:size(cell_i_mask,2),1:size(cell_i_mask,1)); %make a meshgrid: use the size of your image instead
%         ellipse = ((X1-X0)/l).^2+((Y1-Y0)/w).^2<=1; %Your Binary Mask which you multiply to your image, but make sure you change the size of your mesh-grid
%         RotateEllipse = imrotate(ellipse,phi);
% %         figure;
%         h4=imshow(RotateEllipse);
%         h4.AlphaData=0.5;
%         
%         imellipse
%         pause(0.5);
%         tracks_analysis(i).SytoxOverlap=sum(thr_sytox(cellIdx));%get the sum of the overlaping pixels.
        %}

        if tracks_analysis(i).SytoxOverlap<vars.minOverlap %live cells (smaller overlap than the minimum required)
            tracks_analysis(i).cellFate='live';
            tracks_analysis(i).fateColor=[0,0,1];%blue color for live cells
%             tracks_analysis(i).fateColor2=[0,1,1];%cyan
        else %dead cells (at least minOverlap pixels overlap)
            tracks_analysis(i).cellFate='dead';
            tracks_analysis(i).fateColor=[1,0,0];%red color for dead cells
%             tracks_analysis(i).fateColor2=[1,0,1];%magenta
        end
    
    else
        error('More than one matching timepoint was found for the sytox treatment'); 
        %actually, this error should never occour. However, in the future
        %the script can be adapted to look for matching across several timepoints. 
        %for example, create a mini-stack of 3 sytox timepoint and look for 
        %sytox co-localization in any of these frames in order to be sure 
        %that no cell is missed out because of out-of-focus etc. 
    end
%     cellIdx=tracks_analysis(i).PixelIdxList{idxSytF};%get the pixels of the cells in the frame of the sytox idx
%     cellIdx=tracks_analysis(i).PixelIdxList{idxSytF};%get the pixels of the cells in the frame of the sytox idx
end

if clearFlag==1
    clear dilated se cell_i_mask cellIdx
end



%% view the cell fate as overlay on the sytox image
% finalImg = img;
% finalImg(~thrImg) = 0;
hFig=figure;
titleStr='Sytox with cell fate. Blue = live cells ; Red = dead cells, black = unknown fate.';
cmap = [0,1,0]; %colormap
rgbImg = falseColor(Im_syt,cmap);
imshow(BFfilt(:,:,idxSytF),'InitialMagnification', 150);
% h1.AlphaData=0.5;
hold on
h2=imshow(rgbImg,'InitialMagnification', 150);
h2.AlphaData=0.7;
axis image;
title(titleStr);

for i=1:length(tracks_analysis)
    frameInd=find(tracks_analysis(i).Frame==idxSytF);
    if max(frameInd)==0 
        continue
    else
        plot(tracks_analysis(i).XFit(frameInd),tracks_analysis(i).YFit(frameInd),...
            'o','Color',(tracks_analysis(i).fateColor),'MarkerSize',6); %without trackID
%         text(tracks_analysis(i).XFit(frameInd),tracks_analysis(i).YFit(frameInd), num2str(tracks_analysis(i).TrackID(1)),'FontSize',10,'Color',(tracks_analysis(i).fateColor),'HorizontalAlignment','center'); %with trackID
    end
end

if saveFlag==1
    savefig(hFig,'sytox_bf_fate.fig');
    print('sytox_bf_fate','-dpng');
end

h=msgbox('Press OK when you''re ready to move on','Sytox Analysis');
waitfor(h);
close(hFig);

%% 12.3 plots & intensity analysis
%% Trim tracks - only full tracks with known cell fate
%Trim short tracks - strict
% tracks_analysis_trimmed=tracks_analysis;
minFramesPerTrack=idxSytF-7; %nFrames %minimum track length for this analysis 
Track_Length=arrayfun(@(Q) length(Q.X),tracks_analysis); %Find track lengths
tracks_analysis_trimmed=tracks_analysis(Track_Length>minFramesPerTrack); %Trim tracks with less than desired length

%Trim unknown cell fate
Track_Fate=arrayfun(@(Q) Q.cellFate,tracks_analysis_trimmed,'UniformOutput',0); %Find track fate
tracks_analysis_trimmed=tracks_analysis_trimmed(~strcmp(Track_Fate,'unknown')); %Trim tracks with less than desired length

%Trim tracks that start late
% firstFramePerTrack=arrayfun(@(Q) min(Q.Frame),tracks_analysis_trimmed);
% first_frame=2;
% tracks_analysis_trimmed=tracks_analysis_trimmed(firstFramePerTrack<=first_frame);%trim tracks that don't start at the first frame (or before) 

if saveFlag==1
    save('TrackData.mat','tracks_analysis_trimmed','-append');
end

    
%% plot oxidation over time - with cell fate
vars.time_limits=[min(H_post_treat1) H_post_treat1(idxSytStart-1)];
x_lim=vars.time_limits;
y_lim=[-0.1 1.3];
x_label=sprintf('Time post %s treatment (hours)',vars.treatLables{1});
y_label='mean oxD per cell';
titlestr='Oxidation per cell over time. Blue = live cells ; Red = dead cells, black = unknown fate.';
% [hFig]=plotMeasurement(tracks_struct,y_fieldName,x_fieldName,colorMap,x_lim,y_lim,x_label,y_label,titlestr);
[hFig]=plotMeasurement(tracks_analysis,'AvgInt','Treat1_Hours','fateColor',x_lim,y_lim,x_label,y_label,titlestr);%vars.Treat_dT_label{1}

if saveFlag==1
    savefig(hFig,'cells_ox_time_fate.fig');
    print('cells_ox_time_fate','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','Analysis');
waitfor(h);
close(hFig);

%{
% hFig=figure('Position', [150, 50, size(final488,2).*2, size(final488,1).*1.8]);
% hold on
% for i=1:length(tracks_analysis)
% %     plot(tracks_analysis(i).Frame,tracks_analysis(i).AvgInt,'.-','Color',tracks_analysis(i).fateColor)
%     indx=~isnan(tracks_analysis(i).AvgInt);
%     plot(tracks_analysis(i).Treat1_Hours(indx),...
%         tracks_analysis(i).AvgInt(indx),...
%         'o-','Color',tracks_analysis(i).fateColor)
% end
% title('Mean oxidation per cell over time. Blue = live cells ; Red = dead cells, black = unknown fate.');
% ylim([-0.2,1.4]);
% x_lim=[min(H_num_total) H_num_total(idxSytStart-1)];
% xlim(x_lim); %only show frames before sytox treatment
% ylabel('mean oxD per cell');
% xlabel('Time post treatment (hours)');
% if saveFlag==1
%     savefig(hFig,'oxidation_cellFate_time.fig');    
% end
% h=msgbox('Press OK when you''re ready to move on','Analysis');
% waitfor(h);
% close(hFig);
%}

%% plot oxidation over time - with cell fate - zoom in on the first 2Hr
x_lim=[vars.time_limits(1),2];
y_lim=[0 1.2];
[hFig]=plotMeasurement(tracks_analysis,'AvgInt','Treat1_Hours','fateColor',x_lim,y_lim,x_label,y_label,titlestr);%vars.Treat_dT_label{1}
if saveFlag==1
    savefig(hFig,'cells_ox_fate_first2hr.fig');
    print('cells_ox_fate_first2hr','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','Analysis');
waitfor(h);
close(hFig);

%% plot oxidation over time - with cell fate - only full tracks after trimming!
x_lim=[min(H_post_treat1) H_post_treat1(idxSytStart-1)];
y_lim=[-0.1 1.2];
x_label=sprintf('Time post %s treatment (hours)',vars.treatLables{1});
y_label='mean oxD per cell';
titlestr='Oxidation per cell over time. Blue = live cells ; Red = dead cells, black = unknown fate.';
% [hFig]=plotMeasurement(tracks_struct,y_fieldName,x_fieldName,colorMap,x_lim,y_lim,x_label,y_label,titlestr);
[hFig]=plotMeasurement(tracks_analysis_trimmed,'AvgInt','Treat1_Hours','fateColor',x_lim,y_lim,x_label,y_label,titlestr);%vars.Treat_dT_label{1}

if saveFlag==1
    savefig(hFig,'cells_ox_time_fate_trimmed.fig');
    print('cells_ox_time_fate_trimmed','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','Analysis');
waitfor(h);
close(hFig);

%% plot oxidation over time - with cell fate - zoom in on the first 2Hr only full tracks after trimming!
x_lim=[vars.time_limits(1),2];
y_lim=[0 1.2];
x_label=sprintf('Time post %s treatment (hours)',vars.treatLables{1});
y_label='mean oxD per cell';
titlestr='Oxidation per cell over time. Blue = live cells ; Red = dead cells, black = unknown fate.';
% [hFig]=plotMeasurement(tracks_struct,y_fieldName,x_fieldName,colorMap,x_lim,y_lim,x_label,y_label,titlestr);
[hFig]=plotMeasurement(tracks_analysis_trimmed,'AvgInt','Treat1_Hours','fateColor',x_lim,y_lim,x_label,y_label,titlestr);%vars.Treat_dT_label{1}

if saveFlag==1
    savefig(hFig,'cells_ox_time_fate_trimmed_2hr.fig');
    print('cells_ox_time_fate_trimmed_2hr','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','Analysis');
waitfor(h);
close(hFig);

%% view a movie of oxD with cell fate
cRange = [-0.1 1.2]; %color range
h = figure;
pauseTime=0.3;
% titlestr=sprintf('oxD. Time post %s treatment:  %s  ',vars.treatLables{1},vars.Treat_dT_label{1}{i});
% figH = viewFrame(oxDstack, i, cRange, titlestr); 
% % figH = viewFrame(oxDstack, i, cRange, 'oxD'); 
% hold on
% pause(pauseTime);
% position=[10,10];
for i=1:nFrames
    if i~=1
        cla(figH,'reset')
    end
%     titlestr=sprintf('oxD: Time post %s treatment:  %s  ',vars.treatLables{1},vars.Treat_dT_label{1}{i});
    titlestr=sprintf('oxD: time stamp = time post %s treatment',vars.treatLables{1});
    text_str=vars.Treat_dT_label{1}{i};
%     I=oxDstack(:,:,i);
%     text_str=sprintf('Time post %s treatment:  %s  ',vars.treatLables{1},vars.Treat_dT_label{1}{i});
%     RGB = insertText(I,position,text_str,'FontSize',16,'BoxColor',...
%         'yellow','BoxOpacity',0.4,'TextColor','white');
%     figH = viewFrame(RGB, 1, cRange, titlestr);
    figH = viewFrame(oxDstack, i, cRange, titlestr);
    text(7,10,text_str,'Color','white','FontSize',14);
    for j=1:length(tracks_analysis)
        frameInd=find(tracks_analysis(j).Frame==i);
        if max(frameInd)==0 
            continue
        else
            text(tracks_analysis(j).XFit(frameInd),tracks_analysis(j).YFit(frameInd),...
                num2str(tracks_analysis(j).TrackID(1)),'FontSize',10,'Color',tracks_analysis(j).fateColor*0.7,...
                'FontWeight','bold','HorizontalAlignment','center'); %trackID
        end

%         DrawEllipse(tracks_analysis(j).MajAx(frameInd)*1.2,tracks_analysis(j).MinAx(frameInd)*1.2,...
%             tracks_analysis(j).Ang(frameInd),tracks_analysis(j).XFit(frameInd),...
%             tracks_analysis(j).YFit(frameInd),'b'); %tracks_analysis(j).fateColor
    end
        
%         DrawEllipse(PTA(n).MajAx*1.2, PTA(n).MinAx*1.2, PTA(n).Ang,PTA(n).XFit,PTA(n).YFit,'b')
%     figH = viewFrame(oxDstack, i, cRange, 'oxD'); 
    if i==1
        hold on
    end
    pause(pauseTime);   
end
hMsg=msgbox('Press OK when you''re ready to move on','oxD');%Wait for user to view the image
waitfor(hMsg);
close(h);

%% projectories - with cell fate
% titlestr='Projectories of the tracks with cell fate. Blue = live cells ; Red = dead cells, black = unknown fate.';
% % [hFig]=plotMeasurement(tracks_struct,y_fieldName,x_fieldName,colorMap,x_lim,y_lim,x_label,y_label,titlestr);
% [hFig]=plotMeasurement(tracks_analysis,'YFit','XFit','fateColor',[],[],[],[],titlestr);%vars.Treat_dT_label{1}
% 
% if saveFlag==1
%     savefig(hFig,'tracks_projectories_fate.fig');    
% end
% h=msgbox('Press OK when you''re ready to move on','Analysis');
% waitfor(h);
% close(hFig);

% 
hFig=figure('Position', [150, 50, size(final488,2).*2, size(final488,1).*1.8]);
hold on
for i=1:length(tracks_analysis)
    plot(tracks_analysis(i).XFit,tracks_analysis(i).YFit,'.-','Color',tracks_analysis(i).fateColor)
end
title('Projectories of the tracks with cell fate. Blue = live cells ; Red = dead cells, black = unknown fate.');
if saveFlag==1
    savefig(hFig,'tracks_projectories_fate.fig');
    print('tracks_projectories_fate','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','Projectory');
waitfor(h);
close(hFig);
%%






%% plot oxidation over time - each cell in a different color
x_lim=[min(H_post_treat1) H_post_treat1(idxSytStart-1)];
% x_lim=[];
y_lim=[-0.1 1.3];
x_label=sprintf('Time post %s treatment (hours)',vars.treatLables{1});
y_label='mean oxD per cell';
titlestr='Oxidation per cell over time';
% [hFig]=plotMeasurement(tracks_struct,y_fieldName,x_fieldName,colorMap,x_lim,y_lim,x_label,y_label,titlestr);
[hFig]=plotMeasurement(tracks_analysis,'AvgInt','Treat1_Hours',[],x_lim,y_lim,x_label,y_label,titlestr);%vars.Treat_dT_label{1}

if saveFlag==1
    savefig(hFig,'cells_oxidation_over_time.fig');
    print('cells_oxidation_over_time','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','Analysis');
waitfor(h);
close(hFig);

% hFig=figure('Position', [150, 50, size(final488,2).*2, size(final488,1).*1.8]);
% hold on
% for i=1:length(tracks_analysis)
%     plot(tracks_analysis(i).Frame,tracks_analysis(i).AvgInt,'.-')
% end
% title('Mean oxidation per cell over time. ');
% ylim([-0.2,1.4]);
% xlim([0 (idxSytStart-1)]);
% ylabel('mean oxD per cell');
% xlabel('Frame');
% if saveFlag==1
%     savefig(hFig,'cells_oxidation_over_time.fig');    
% end
% h=msgbox('Press OK when you''re ready to move on','Analysis');
% waitfor(h);
% close(hFig);

%% plot max oxidation over time - each cell in a different colour
x_lim=[min(H_post_treat1) H_post_treat1(idxSytStart-1)];
% x_lim=[];
y_lim=[-0.1 1.4];
x_label=sprintf('Time post %s treatment (hours)',vars.treatLables{1});
y_label='max oxD per cell';
titlestr='Max oxidation per cell over time';
% [hFig]=plotMeasurement(tracks_struct,y_fieldName,x_fieldName,colorMap,x_lim,y_lim,x_label,y_label,titlestr);
[hFig]=plotMeasurement(tracks_analysis,'MaxInt','Treat1_Hours',[],x_lim,y_lim,x_label,y_label,titlestr);%vars.Treat_dT_label{1}

if saveFlag==1
    savefig(hFig,'cells_max_oxidation_over_time.fig');
    print('cells_max_oxidation_over_time','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','Analysis');
waitfor(h);
close(hFig);

%% plot min oxidation over time - each cell in a different colour
x_lim=[min(H_post_treat1) H_post_treat1(idxSytStart-1)];
% x_lim=[];
y_lim=[-0.1 1.4];
x_label=sprintf('Time post %s treatment (hours)',vars.treatLables{1});
y_label='min oxD per cell';
titlestr='Min oxidation per cell over time';
% [hFig]=plotMeasurement(tracks_struct,y_fieldName,x_fieldName,colorMap,x_lim,y_lim,x_label,y_label,titlestr);
[hFig]=plotMeasurement(tracks_analysis,'MinInt','Treat1_Hours',[],x_lim,y_lim,x_label,y_label,titlestr);%vars.Treat_dT_label{1}

if saveFlag==1
    savefig(hFig,'cells_min_oxidation_over_time.fig');
    print('cells_min_oxidation_over_time','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','Analysis');
waitfor(h);
close(hFig);

%% projectories
hFig=figure('Position', [150, 50, size(final488,2).*2, size(final488,1).*1.8]);
hold on
for i=1:length(tracks_analysis)
    plot(tracks_analysis(i).XFit,tracks_analysis(i).YFit,'.-')
end
title('Projectories of the tracks');
if saveFlag==1
    savefig(hFig,'tracks_projectories.fig');    
end
h=msgbox('Press OK when you''re ready to move on','Projectory');
waitfor(h);
close(hFig);



%% Plot other features: work in progress

%% get 488 over time
vars.minOverlap_roGFP=4; %at least 4 pixels per cell
% roGFPmask=thr_expression;
[tracks_analysis]=add_measurement(tracks_analysis,'int488',final488,roGFPmask,vars.minOverlap_roGFP,'mean'); %measure the 488 intensity
%% plot 488 over time
% x_lim=[0 (idxSytStart-1)];
x_lim=[min(H_post_treat1) H_post_treat1(idxSytStart-1)];
% x_lim=[];
y_lim=[];
x_label=sprintf('Time post %s treatment (hours)',vars.treatLables{1});
y_label='Mean roGFP488 intensity per cell (AU)';
titlestr='roGFP488 intensity per cell over time';
cell_color=[]; %For color based on cell fate use 'fateColor', otherwise leave empty. 
[hFig]=plotMeasurement(tracks_analysis,'int488','Treat1_Hours','fateColor',x_lim,[],x_label);%vars.Treat_dT_label{1}
% [hFig]=plotMeasurement(tracks_struct,y_fieldName,x_fieldName,colorMap,x_lim,y_lim,x_label,y_label,titlestr);
% [hFig]=plotMeasurement(tracks_analysis,'int488','Treat1_Hours',cell_color,x_lim,y_lim,x_label,y_label,titlestr);%vars.Treat_dT_label{1}

if saveFlag==1
    savefig(hFig,'roGFP488_time.fig');
    print('roGFP488_time','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','Projectory');
waitfor(h);
close(hFig);
% plotMeasurement(tracks_analysis,'int488','fateColor',x_lim)
% plotMeasurement(tracks_struct,y_fieldName,colorMap,x_lim,y_lim,x_labels)
% if saveFlag==1
%     savefig(hFig,'oxidation_cellFate_time.fig');    
% end
% h=msgbox('Press OK when you''re ready to move on','Analysis');
% waitfor(h);
% close(hFig);

%% get chl over time
[tracks_analysis]=add_measurement(tracks_analysis,'intChl',finalChl,thrChl,vars.minOverlap,'mean'); %measure the chl intensity
%% plot chl over time
x_lim=[min(H_post_treat1) H_post_treat1(idxSytStart-1)];
% y_lim=[-0.1 1.4];
% x_lim=[];
y_lim=[];
x_label=sprintf('Time post %s treatment (hours)',vars.treatLables{1});
y_label='mean Chl intensity per cell';
titlestr='Chlorophyll intensity per cell over time';
cell_color=[]; %For color based on cell fate use 'fateColor', otherwise leave empty. 
% [hFig]=plotMeasurement(tracks_struct,y_fieldName,x_fieldName,colorMap,x_lim,y_lim,x_label,y_label,titlestr);
[hFig]=plotMeasurement(tracks_analysis,'intChl','Treat1_Hours','fateColor',x_lim,y_lim,x_label,y_label,titlestr);%vars.Treat_dT_label{1}
% [hFig]=plotMeasurement(tracks_analysis,'intChl','Treat1_Hours',cell_color,x_lim,y_lim,x_label,y_label,titlestr);%vars.Treat_dT_label{1}

if saveFlag==1
    savefig(hFig,'cells_chl_time_fate.fig');
    print('cells_chl_time_fate','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','Analysis');
waitfor(h);
close(hFig);


%% get AF over time
[tracks_analysis]=add_measurement(tracks_analysis,'AF',AFstack,thrChl,vars.minOverlap,'mean'); %measure the AF 405/chl intensity
%% plot AF over time
x_lim=[min(H_post_treat1) H_post_treat1(idxSytStart-1)];
% x_lim=[];
y_lim=[];
x_label=sprintf('Time post %s treatment (hours)',vars.treatLables{1});
y_label='mean 405/Chl ratio per cell';
titlestr='405/Chl ratio intensity per cell over time';
cell_color='fateColor';%[]; %For color based on cell fate use 'fateColor', otherwise leave empty =[]. 
[hFig]=plotMeasurement(tracks_analysis,'AF','Treat1_Hours',cell_color,x_lim,y_lim,x_label,y_label,titlestr);%vars.Treat_dT_label{1}

if saveFlag==1
    savefig(hFig,'cells_AF_time_fate.fig');    
%     print('cells_AF_time_fate','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','Analysis');
waitfor(h);
close(hFig);


%% get mean roGFP ratio over time
% vars.minOverlap_roGFP=4; %at least 4 pixels per cell
[tracks_analysis]=add_measurement(tracks_analysis,'roGFP_ratio',ratioStack,roGFPmask,vars.minOverlap_roGFP,'mean'); %measure the roGFP ratio 405/488 intensity
%% plot mean roGFP ratio over time
x_lim=[min(H_post_treat1) H_post_treat1(idxSytStart-1)];
% x_lim=[];
y_lim=[vars.Rred*0.8,vars.Rox*1.2];
% y_lim=[];
x_label=sprintf('Time post %s treatment (hours)',vars.treatLables{1});
y_label='mean roGFP ratio per cell';
titlestr='roGFP ratio per cell over time';
cell_color='fateColor'; %For color based on cell fate use 'fateColor', otherwise leave empty. 
[hFig]=plotMeasurement(tracks_analysis,'roGFP_ratio','Treat1_Hours',cell_color,x_lim,y_lim,x_label,y_label,titlestr);%vars.Treat_dT_label{1}

if saveFlag==1
    savefig(hFig,'mean_roGFP_ratio_time.fig');    
    print('mean_roGFP_ratio_time','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','Analysis');
waitfor(h);
close(hFig);

%% get max roGFP ratio over time
% [tracks_analysis]=add_measurement(tracks_analysis,'max_roGFP',ratioStack,roGFPmask,vars.minOverlap_roGFP,'max'); %measure the roGFP ratio 405/488 intensity
%% plot max roGFP ratio over time
% x_lim=[min(H_post_treat1) H_post_treat1(idxSytStart-1)];
% % x_lim=[];
% y_lim=[vars.Rred*0.8,vars.Rox*1.5];
% % y_lim=[];
% x_label=sprintf('Time post %s treatment (hours)',vars.treatLables{1});
% y_label='max roGFP ratio per cell';
% titlestr='max roGFP ratio per cell over time';
% % [hFig]=plotMeasurement(tracks_struct,y_fieldName,x_fieldName,colorMap,x_lim,y_lim,x_label,y_label,titlestr);
% % [hFig]=plotMeasurement(tracks_analysis,'AF','Treat1_Hours','fateColor',x_lim,[],x_label,y_label,titlestr);%vars.Treat_dT_label{1}
% [hFig]=plotMeasurement(tracks_analysis,'max_roGFP','Treat1_Hours',[],x_lim,y_lim,x_label,y_label,titlestr);%vars.Treat_dT_label{1}
% 
% if saveFlag==1
%     savefig(hFig,'max_roGFP_ratio_time.fig');    
%     print('max_roGFP_ratio_time','-dpng');
% end
% h=msgbox('Press OK when you''re ready to move on','Analysis');
% waitfor(h);
% close(hFig);

%% get min roGFP ratio over time
% [tracks_analysis]=add_measurement(tracks_analysis,'min_roGFP',ratioStack,roGFPmask,vars.minOverlap_roGFP,'min'); %measure the roGFP ratio 405/488 intensity
%% plot min roGFP ratio over time
% % x_lim=[min(H_post_treat1) H_post_treat1(idxSytStart-1)];
% x_lim=[];
% % y_lim=[vars.Rred*0.9,vars.Rox*1.5];
% y_lim=[];
% x_label=sprintf('Time post %s treatment (hours)',vars.treatLables{1});
% y_label='min roGFP ratio per cell';
% titlestr='min roGFP ratio per cell over time';
% % [hFig]=plotMeasurement(tracks_struct,y_fieldName,x_fieldName,colorMap,x_lim,y_lim,x_label,y_label,titlestr);
% % [hFig]=plotMeasurement(tracks_analysis,'AF','Treat1_Hours','fateColor',x_lim,[],x_label,y_label,titlestr);%vars.Treat_dT_label{1}
% [hFig]=plotMeasurement(tracks_analysis,'min_roGFP','Treat1_Hours',[],x_lim,y_lim,x_label,y_label,titlestr);%vars.Treat_dT_label{1}
% 
% if saveFlag==1
%     savefig(hFig,'min_roGFP_ratio_time.fig');    
%     print('min_roGFP_ratio_time','-dpng');
% end
% h=msgbox('Press OK when you''re ready to move on','Analysis');
% waitfor(h);
% close(hFig);

%% get 405 over time
vars.minOverlap_roGFP=4; %at least 4 pixels per cell
[tracks_analysis]=add_measurement(tracks_analysis,'int405',final405,roGFPmask,vars.minOverlap_roGFP,'mean'); %measure the 488 intensity
%% plot 405 over time
% x_lim=[0 (idxSytStart-1)];
x_lim=[min(H_post_treat1) H_post_treat1(idxSytStart-1)];
% x_lim=[];
y_lim=[];
x_label=sprintf('Time post %s treatment (hours)',vars.treatLables{1});
y_label='Mean roGFP405 intensity per cell (AU)';
titlestr='roGFP405 intensity per cell over time';
cell_color='fateColor'; %For color based on cell fate use 'fateColor', otherwise leave empty. 
% [hFig]=plotMeasurement(tracks_analysis,'int488','Treat1_Hours','fateColor',x_lim,[],x_label);%vars.Treat_dT_label{1}
% [hFig]=plotMeasurement(tracks_struct,y_fieldName,x_fieldName,colorMap,x_lim,y_lim,x_label,y_label,titlestr);
[hFig]=plotMeasurement(tracks_analysis,'int405','Treat1_Hours',cell_color,x_lim,y_lim,x_label,y_label,titlestr);%vars.Treat_dT_label{1}

if saveFlag==1
    savefig(hFig,'roGFP405_time.fig');
    print('roGFP405_time','-dpng');
end
h=msgbox('Press OK when you''re ready to move on','roGFP405');
waitfor(h);
close(hFig);
% plotMeasurement(tracks_analysis,'int488','fateColor',x_lim)
% plotMeasurement(tracks_struct,y_fieldName,colorMap,x_lim,y_lim,x_labels)
% if saveFlag==1
%     savefig(hFig,'oxidation_cellFate_time.fig');    
% end
% h=msgbox('Press OK when you''re ready to move on','Analysis');
% waitfor(h);
% close(hFig);


%% 14. output, saving and cleanup
%save the data
if saveFlag==1
    save('TrackData.mat','tracks_analysis','final_tracks','-append');%'cellsProps',
    save('vars.mat','vars'); 
    cd(oldPath); %return to the previous path
end

if CloseFlag==0
    MIJ.exit; %make sure to close Miji before ending the session.
end

%% 
disp('Congratulations! myroGFP function had reached the end! =)');

%%
% end

%% other codes and tests

%% cell centers according to BF - optional 
%{
% %BF filt without background
% BFfinal = BFfilt;
% BFfinal(~colocalizationMat)=NaN; %remove background pixels
% BFfinal=BFfinal./max(BFfinal(:)); %normalize to max value
% 
% %view BF centers
% t=5;
% cRange = [min(BFfinal(:)), max(BFfinal(:))]; %color range
% [figH] = viewFrame(BFfinal, t, cRange, 'BF with co-localization');
% close();
% 
% % cell centers according to BF
% %calculate the threshold mask and plot it as an overlay:
% thrLow = min(BFfinal(:))+((max(BFfinal(:))-min(BFfinal(:)))/2);
% thrUp = Inf;
% % [thrStack]=simpleThreshold(stack, thrLow, thrUp, stackName);
% [BFcenters]=simpleThreshold(BFfinal, thrLow, thrUp, 'BF final');
% BF_CC = bwconncomp(BFcenters,8);
% BFcentroid=regionprops(BF_CC,'Centroid');
% BFcentroid.X= arrayfun(@(x) round(x.Centroid(:,1)),BFcentroid);
% BFcentroid.Y= arrayfun(@(x) round(x.Centroid(:,2)),BFcentroid);
% BFcentroid.C= arrayfun(@(x) round(x.Centroid(:,3)),BFcentroid);
% BFcentroid.T= arrayfun(@(x) round(x.Centroid(:,4)),BFcentroid);
% BFcenterImg = zeros(size(BFfinal));
% BFcenterImg(BFcentroid.Centroid)=1;
% 
%} 

%% cell center 488 mask - optional
%{
% creat a cell mask based on the 488 stack, normalized to itself in each
% frame
centers488 = final488;
for i=1:size(ratioStack,4);
    Im=final488(:,:,:,i);
    centers488(:,:,:,i)=Im./max(Im(:)); %normalize to the maximum of each frame
end

[centersMask488]=simpleThreshold(centers488, 0.5, Inf, '488 centers');
close();
centersMask488(~colocalizationMat)=0; %remove pixels that are not co-localized with the 405.

%view the final centers of a different timepoint
t=10;
thrOverlay = imoverlay(centers488(:,:,:,t), centersMask488(:,:,:,t), [1 0 0]); %mask in red
imshow(thrOverlay, 'InitialMagnification', 150);
titleStr=sprintf('488 centers overlay of frame %g',t);
title(titleStr);
axis image;
%}


%% segmentation options
%{
% L = watershed(A,conn);

% %cellLables = bwconncomp(coloalizationMat,8);
% I = coloalizationMat(:,:,:,1);
% labeledImage = bwlabel(I, 8); 
% %imshow(I);
% axis image;
% coloredLabels = label2rgb (labeledImage, 'hsv', 'k', 'shuffle'); % pseudo random color labels
% imshow(coloredLabels);
% axis image; % Make sure image is not artificially stretched because of screen's aspect ratio.

%stack=bg488;
% segStackColor = zeros(size(bg488,1),size(bg488,2),3,size(bg488,4));
% [I_segmented,I_segColor]=mySegmentation(stack, coloalizationMat, t)
%}

%% test - get labels...
% I = segStack;
% I(segStack==1)=0;
% labeledImage = bwlabel(I(:,:,:,20), 8);
% imshow(label2rgb(labeledImage,'jet',[.5 .5 .5]));

%%
% TestTrack2(BFfilt,P_Tracks_Trim,pauseTime);

%% testing
% stack = norm_expression; 
% stackfilt=stdfilt(stack);
% t=10;
% figure;
% % subplot(2,1,1)
% imshow(stack(:,:,t),'InitialMagnification',150);
% % subplot(2,1,2)
% figure;
% imshow(stackfilt(:,:,t),'InitialMagnification',150);
% 
% BW = imregionalmin(stackfilt(:,:,t));
% BW(~colocalizationMat(:,:,t))=0;
% figure;
% imshow(BW,'InitialMagnification',150);
% 
% figure;
% imshow(BFfilt(:,:,t),'InitialMagnification',150);
%%

%% to play oxD video:
%{
fps=3; %frames per second
%hVid=implay;
%set(hVid, 'Position', [0 0 imgData.sizeX imgData.sizeY]);
hVid = implay(oxDstack,fps);
%}

%% a loop to go over all the images in the stack
%{
% for i =1:imgData.sizeT
%     oxDImg = oxDstack(:,:,:,i);
%     figH = imshow(oxDImg);
%     titleStr = sprintf('oxD image of timepoint %d',i);
%     title(titleStr);
%     colormap jet
%     set(figH, 'AlphaData', ~isnan(oxDImg)) %set NaN as transparent
%     axis image;
%     axis on;
%     % Make a black axis for black background (NaN values)
%     set(gca, 'XColor', 'none', 'yColor', 'none', 'xtick', [], 'ytick', [], 'Color', 'black');
%     caxis([0 1]); %the range of oxidation is 0 to 1
%     colorbar;
%     timeout = 3; %sec
%     
%     h= msgbox('Press OK when you''re ready to move on', 'oxD', 'modal');
%     waitfor(h);
%     %close();
% end
%     
%}

%% chl normalization and thresholding
%{
%normalize each frame to the local max

% 
% for t=1:nFrames
%     Im = imgMat(:,:,vars.ChlInd,t);
%     imgMat(:,:,vars.ChlInd,t)= (Im-min(Im(:)))./(max(Im(:))-min(Im(:)));
% end

%threshold the chl channel
% t=10;
% [finalChl, thrChl] = imgThreshold('chl', vars.thrChlLow, vars.thrChlUp, imgMat, vars, t);
% chlCenters = finalChl;
% chlCenters(~thrChl)=0;

% figure('Position',[100,50,1500,900]);
% subplot(2,2,1)
% imshow(thrChl(:,:,:,t));
% subplot(2,2,2)
% imshow(finalChl(:,:,:,t));
% subplot(2,2,3)
% imshow(BFfilt(:,:,:,t));
% subplot(2,2,4)
% imshow(imgMat(:,:,3,t));
% axis image
%}

%% segment the cells
% switch vars.segType 
%     case 'mySegmentation' 
%         %% use mySegmentation function
%         % If you want to use only co-localization without watershed - skip this and
%         % the following sections!
%         % [I_segmented]=mySegmentation(stack, colocalizationMat, t, filtType, sigma)
%         segStack = zeros(size(maskStack));%create empty stack for the segmented image
%         sigma = vars.sigma; %for gaussian filter within the segmentation
%         % sigma=0;
%         filtType = vars.filtType; %'gaussian', 'median', 'no filt'
%         % filtType = 'median';
%         % filtType = 'no filt';
%         IntStack=final405; %finalChl %final405 %norm_expression %intensity stack, used to find the local maxima. can be final488, final405, BFfilt, roGFPexpress etc...
%         % maskStack = colocalizationMat; %cell mask to be used as the boundries of the cells.
% %         maskStack=colocalizationMat; %cell mask to be used as the boundries of the cells.
%         connec=4;
% 
%         %loop over the stack and segment frame by frame
%         for t = 1:nFrames
%             if ismember(t,[1,round(nFrames/2),nFrames]) %let the user modify sigma in the first frame
%                 %run segmentation on the 1st frame
%                 [segStack(:,:,t)]=mySegmentation(IntStack, maskStack, t,filtType, sigma,connec);
% 
%                 %view the first frame (pseudocolor)
%                 I_segColor = label2rgb(segStack(:,:,t),'jet',[.5 .5 .5]);
%                 figH = figure;
%                 imshow(I_segColor,'InitialMagnification',150)
%                 title(sprintf('Watershed transform of roGFP488, frame %g, sigma %g',t, sigma));
% 
%                 %ask the user about segmentation
%                 qstring = 'Are you happy with that segmentation?';
%                 segAnswer = questdlg(qstring,'Watershed segmentation');
%                 waitfor(segAnswer);
% 
%                 while strcmp(segAnswer,'No')
%                     %get new sigma value
%                     prompt = {'Enter new sigma:','Enter new connectivity (4 or 8)',...
%                         'Enter filter type (''gaussian'', ''median'',''no filt''):'};
%                     dlg_title = 'Watershed transform input';
%                     num_lines = 1;
%                     defaultans = {num2str(sigma), num2str(connec), filtType};
%                     answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
%                     sigma = str2double(answer{1});
%                     connec = str2double(answer{2});
%                     filtType = answer{3};
% 
%                     %run segmentation with new sigma 
%                     [segStack(:,:,t)]=mySegmentation(IntStack, maskStack, t,filtType, sigma,connec);
% 
%                     %view the new segmentation
%                     I_segColor = label2rgb(segStack(:,:,t),'jet',[.5 .5 .5]);
%                     imshow(I_segColor,'InitialMagnification',150)
%                     title(sprintf('Watershed transform of roGFP488, frame %g, sigma %g',t, sigma));
% 
%                     %ask the user again
%                     qstring = 'Are you happy with that segmentation?';
%                     segAnswer = questdlg(qstring,'Watershed segmentation');
%                 end %while        
%                 close(figH);
% 
%             else %t>1
%                 %run segmentation on the rest of the stack
%                 [segStack(:,:,t)]=mySegmentation(IntStack, maskStack, t,filtType, sigma,connec);        
%             end % if t==1   
%         end %t loop
%         
%         cellsMask = segStack;
%         cellsMask(cellsMask<=1)=0;
%         cellsMask(cellsMask>1)=1;
%    
%     case 'Fiji' 
%         %% FIJI segmentation.
%         %requires FIJI (imageJ) and MIJI (see the imageStabilizer function for
%         %details).
%         %This function uses the maskStack to create the cell mask. 
%         %It performs 'erode' depending on vars.erode_num, and then uses watershed. 
%         OpenFlag=0; %MIJI open choice: 0=don't open, 1=open.
%         CloseFlag=1; %MIJI close choice: 0=don't close, 1=close.
%         ErodeNum=vars.erode_num;
% %         ErodeNum=1;
% %         maskStack=thr_expression;
%         cellsMask = FijiWatershed(maskStack,ErodeNum, OpenFlag,CloseFlag);
%         % cd(output_folder);
%         
%         
%     case 'Mask only'
%         %%
%         cellsMask = maskStack;
%         
%     otherwise
%         warning('segmentation type was not recognized');
%         cellsMask = maskStack;
% end