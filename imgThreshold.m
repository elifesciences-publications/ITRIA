
function [bgStack,thrStack,thrLow,thrUp,bgROI] = imgThreshold(channelName,thrLow,thrUp,stack,vars,timepoint,bgROI)
%% function imgThreshold
%{
takes a multi channel multi timepoints image stack, finds the required
channel, and then substracts background based on user defined ROI. 
Then, the threshold is calculated (auto or manual options).

output:
bgStack - the original stack after bg substraction
thrStack - thresholded stack (binary)
%}

%% for testeing:
%{
channelName = '488';
thrLow = 0.017;
thrUp = (2^14-1)./(2^14);
timepoint = 1;
%}
%{
%find the index of the channel
%channelName='488';
%timepoint = 1;
%colorMap = cell2mat(vars.chColor(1,indCh)); %%%check how to put the color map
%colormap jet;
%colormap green;
%}

%% open the image for bg calculation:
indCh = find(ismember(vars.channels,channelName)); %get the channel number
% stack = imgMat(:,:,indCh,:); %get the stack
img = stack(:,:,timepoint); %get the first image of the stack
%figH = figure();

%% Image color setup
%get color map and color range
% cmap = vars.chColor{indCh};
% rgbImg = falseColor(img,cmap);
%{
% rgbStack = falseColor(stack,cmap);
% imshow(rgbStack(:,:,:,22));

% cmap = [0 1 1];
% cmap = jet;
% redChannel = img.*(cmap(1));
% greenChannel = img.*(cmap(2));
% blueChannel = img.*(cmap(3));
% rgbImage = cat(3, redChannel, greenChannel, blueChannel);
% imshow(rgbImage);
%}
%% Check if the image is normalized to [0 1] and set color axis:
if max(img(:))<=1
    cRange = [0 1];
else
    cRange = [vars.minRange, vars.maxRange];
end

%% view the image
titleStr = sprintf('channel "%s",  timepoint %d',channelName,timepoint);

figH = figure;
imshow(img, 'DisplayRange', cRange);
axis image; % Make sure image is not artificially stretched because of screen's aspect ratio.
title(titleStr);

fprintf('max initial:  %d\n',max(img(:)));

%{

% axis image; % Make sure image is not artificially stretched because of screen's aspect ratio.
%figH.OuterPosition = get(groot, 'ScreenSize').*[10 55 0.97 0.95];
% figH.Colormap = cmap;


% imshow(img, 'InitialMagnification', 150, 'DisplayRange', cRange);
% % imshow(img,'InitialMagnification', 'fit', 'Colormap', cmap), 'DisplayRange', cRange);

% title(titleStr);
% axis image; % Make sure image is not artificially stretched because of screen's aspect ratio.

% axisH = gca;
% figSize = figH.OuterPosition;
% imgSize = axisH.OuterPosition;
% hold on;
%imshow(imgMat(:,:,indCh,timepoint),colorMap); 
%imshow(img,colorMap));

% caxis(cRange);
% set(gca, 'CLim', cRange);
% if max(img(:))>1
%     %set the min and max values according to the image bit-depth
%     set(gca, 'CLim', [vars.minRange, vars.maxRange]);
% end
%}
%% let the user select background ROI for BG substration
if nargin<7 %no input of bg roi    
    msgTitleStr = sprintf('background ROI - channel "%s"',channelName);
    i=0;

    while i<4
        i=i+1;
        h=msgbox('Please select a background ROI',msgTitleStr, 'modal');
        waitfor(h);
        bgROI = roipoly(img);

        if max(bgROI(:))>0
            break
        elseif i==4
            warning('clealrly you do not want to choose a background ROI');
            bgROI=0;
        end
    end
end

%% get the mean background value
if bgROI == 0
    bgMean = min(img(:)); %global minimum of the image
else
    bgMean = mean(img(bgROI)); %mean of the background roi
end
fprintf('bgMean:  %d\n', bgMean);

%draw the ROI on the image 
%{
hold on;
boundaries = bwboundaries(bgROI);
boundaries = boundaries{1};
%numberOfBoundaries = size(boundaries, 1);
plot(boundaries(:,2), boundaries(:,1), 'r', 'LineWidth', 1);
%}

%% substract the background from the stack
bgStack = stack-bgMean; %bgStack is the same stack after bg substraction
bgStack(bgStack<0)=0; %turn negative values to zero
% bgStack = bgStack.*(cRange(2)/(cRange(2)-bgMean)); %normalizing data to the new max
img = bgStack(:,:,timepoint);
% figH = figure();
% figH = imshow(img,'InitialMagnification', 150); 
color_range=[min(img(:)),max(img(:))];
imshow(img,color_range,'InitialMagnification', 150); %view with colour range
title(titleStr);
axis image; % Make sure image is not artificially stretched because of screen's aspect ratio.
fprintf('max end:  %d\n',max(img(:)));

%% threshold the image
%for auto threshold and the first step in manual threshold
%calculate the threshold mask and plot it as an overlay:
thrImg = img > thrLow & img < thrUp; 
thrOverlay = imoverlay(img, thrImg, [1 0 0]); %mask in red
% figH = imshow(thrOverlay, 'InitialMagnification', 150);
imshow(thrOverlay, 'InitialMagnification', 150);
title(titleStr);
axis image; % Make sure image is not artificially stretched because of screen's aspect ratio.

%for plotting the boundries of the threshold
%{
% title('Outlines, from bwboundaries()'); 
% axis image; % Make sure image is not artificially stretched because of screen's aspect ratio.
% hold on;
% boundaries = bwboundaries(thrImg);
% numberOfBoundaries = size(boundaries, 1);
% for k = 1 : numberOfBoundaries
% 	thisBoundary = boundaries{k};
% 	plot(thisBoundary(:,2), thisBoundary(:,1), 'r', 'LineWidth', 1);
% end
% hold off;
%}

%% For manual thresholding
if strcmp(vars.thrChoice,'manual')
    %if manual - ask the user whether the threshold is OK
    qstring = 'Are you happy with that threshold?';
    thrAnswer = questdlg(qstring,'Manual Threshold');
    
    while strcmp(thrAnswer,'No') 
        %get new threshold values
        prompt = {'Enter lower threshold:','Enter upper threshold:'};
        dlg_title = 'Threshold input';
        num_lines = 1;
        defaultans = {num2str(thrLow),num2str(thrUp)};
        answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
        thrLow = str2double(answer{1});
        thrUp = str2double(answer{2});
        
        %calculate the new thrshold and display it
        thrImg = img > thrLow & img < thrUp; 
        thrOverlay = imoverlay(img, thrImg, [1 0 0]);
        figH = imshow(thrOverlay, 'InitialMagnification', 150);
        title(titleStr);
        axis image;
        
        %ask again the user if the threshold is satisfying
        qstring = 'Are you happy with that threshold?';
        thrAnswer = questdlg(qstring,'Manual Threshold');
    end
end

%% view the thresholded result in false color
finalImg = img;
finalImg(~thrImg) = 0;
cmap = vars.chColor{indCh}; %colormap
rgbImg = falseColor(finalImg,cmap);
imshow(rgbImg, 'InitialMagnification', 150);
title(titleStr);
axis image;
h=msgbox('Press OK when you''re ready to move on','Threshold');
waitfor(h);
close();

%% calculate the whole stack threshold once the values are final
thrStack = bgStack > thrLow & bgStack < thrUp;

fprintf('%s lower threshold:  %g\n',channelName,thrLow);
fprintf('%s upper threshold:  %g\n',channelName,thrUp);

%cleanup
close all;

end