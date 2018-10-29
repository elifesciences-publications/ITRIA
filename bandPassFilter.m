% bandPassFilter
%{
This function takes an input stack, does
%}

function [filteredStack,lowPass, highPass, filterSize] = bandPassFilter(stack, lowPass, highPass, filterSize, manualChoice,t)

%% check number of input variables
if nargin<4
    manualChoice='auto';
end
if nargin<5
    t=1;
end
%% for testing
% stack = imgMat(:,:,4,:);
% lowPass = 0.2;
% highPass = 2;
% manualChoice = 'manual';
% filterSize = 30;

%% initiating
if length(size(stack))==4
    I = stack(:,:,:,t); %the frame t for visualization
elseif length(size(stack))==3
    I = stack(:,:,t);%the frame t for visualization
elseif length(size(stack))==2
    I=stack;
    warning('The input stack has 2 dimensions and was processed as a single frame');
else
    error('the input stack has unfamiliar structure, not 3 or 4 dimensions.')
end
%%filter generator
%from vicente - the stocker lab tracking script
%file name "FilterGen_V.m"
%original function:
%{
function [h_obj, h_noise] = FilterGen_V(h_obj, h_noise, F_size, filt_shape)

% "h_obj"   = PxP matrix to be used as a filter; if set equal to a number,
%             h_obj is treated as diameter for a top hat filter;
%             'default'->11
% "h_noise" = diameter of noise response function (Gaussian); 'default'->1
% "F_size"  = size of the filters



if nargin < 3 || isequal(filt_shape,'default'); filt_shape='gaussian'; end;
if nargin < 2 || isequal(h_noise,'default'); h_noise=1; end;
if nargin < 1 || isequal(h_obj,'default'); h_obj=11; end; 

if mod(F_size,2) == 0; F_size=F_size+1; end;

if or(F_size<2*h_noise,all([F_size<2*h_obj,~isinf(h_obj)]))
    error('Filter size too small')
end
if h_obj<=h_noise
    error('Highpass cutoff must be larger than lowpass cutoff')
end

x = -(F_size-1)/2:(F_size-1)/2;
[xx,yy] = meshgrid(x,x);
rr = sqrt(xx.^2+yy.^2);


if isinf(h_obj)
    h_obj=zeros(F_size);
elseif isequal(filt_shape, 'gaussian')
    h_obj=fspecial('Gaussian',F_size,h_obj);
    h_obj = h_obj/sum(h_obj(:));
else
    h_obj=rr <= h_obj;
    h_obj = h_obj/sum(h_obj(:));
end


if h_noise==0
    h_noise=zeros(F_size);
    h_noise(rr==0)=1;
elseif isequal(filt_shape, 'gaussian')
    h_noise=fspecial('Gaussian',F_size,h_noise);
else
    h_noise=rr <= h_noise;
end
h_noise = h_noise/sum(h_noise(:));
%}

h_obj = highPass;
h_noise = lowPass;

if mod(filterSize,2) == 0; filterSize=filterSize+1; end;

% x = -(filterSize-1)/2:(filterSize-1)/2;
% [xx,yy] = meshgrid(x,x);
% rr = sqrt(xx.^2+yy.^2);

h_obj=fspecial('Gaussian',filterSize,h_obj);
h_obj = h_obj/sum(h_obj(:));
h_noise=fspecial('Gaussian',filterSize,h_noise);
h_noise = h_noise/sum(h_noise(:));

%% Filter and display the first image

Im_Filt=imfilter(I,h_noise-h_obj,'replicate');

r = groot;
screenSize = r.ScreenSize;
figSize = [screenSize(3)*0.05, screenSize(4)*0.1, screenSize(3)*0.8, screenSize(4)*0.8];
% figure('Position',[84,340,836,358]);
figure('Position',figSize);
clf
h1=subplot(121);
imshow(I)
colormap gray
axis image
axis off
title('Original')
h2=subplot(122);
imagesc(Im_Filt)
colormap gray
axis image
axis off
linkaxes([h1,h2],'xy')
title(sprintf('low: %g, high: %g, size: %g, Gaussian',lowPass, highPass,filterSize))

%% Manual adjustments
if strcmp(manualChoice,'manual')
    %if manual - ask the user whether the filter is OK
    qstring = 'Are you happy with that filter?';
    filtAnswer = questdlg(qstring,'Manual Filter');   
    
    while strcmp(filtAnswer,'No') 
        %get new threshold values
        prompt = {'Enter low pass:','Enter high pass:', 'Enter filter size:'};
        dlg_title = 'Filter input';
        num_lines = 1;
        defaultans = {num2str(lowPass), num2str(highPass), num2str(filterSize)};
        answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
        lowPass = str2double(answer{1});
        highPass = str2double(answer{2});
        filterSize = str2double(answer{3});
        
        %calculate the new filter and display it
        h_obj = highPass;
        h_noise = lowPass;

        if mod(filterSize,2) == 0; filterSize=filterSize+1; end;

%         x = -(filterSize-1)/2:(filterSize-1)/2;
%         [xx,yy] = meshgrid(x,x);
%         rr = sqrt(xx.^2+yy.^2);

        h_obj=fspecial('Gaussian',filterSize,h_obj);
        h_obj = h_obj/sum(h_obj(:));
        h_noise=fspecial('Gaussian',filterSize,h_noise);
        h_noise = h_noise/sum(h_noise(:));
        
        %calculate & display the new filter
        close();
        Im_Filt=imfilter(I,h_noise-h_obj,'replicate');
        
        figure('Position',figSize);
        clf
        h1=subplot(121);
        imshow(I)
        colormap gray
        axis image
        axis off
        title('Original')
        h2=subplot(122);
        imagesc(Im_Filt)
        colormap gray
        axis image
        axis off
        linkaxes([h1,h2],'xy')
        title(sprintf('low: %g, high: %g, size: %g, Gaussian',lowPass, highPass,filterSize))

        %ask again the user if the threshold is satisfying
        qstring = 'Are you happy with that threshold?';
        filtAnswer = questdlg(qstring,'Manual Threshold');
        
    end %wait
    
else % not manual
    h=msgbox('Press OK when you''re ready to move on','band pass filter');
    waitfor(h);
end %manual choice

close();
%% filter the whole stack
filteredStack = zeros(size(stack));
if length(size(stack))==4
    for i = 1:size(stack,4)
    I = stack(:,:,:,i);
    filteredImg=imfilter(I,h_noise-h_obj,'replicate');
    filteredStack(:,:,:,i)=filteredImg;
    end
elseif length(size(stack))==3
    for i = 1:size(stack,3)
    I = stack(:,:,i);
    filteredImg=imfilter(I,h_noise-h_obj,'replicate');
    filteredStack(:,:,i)=filteredImg;
    end

end


%calibrate the image
minValue = min(filteredStack(:)); %new min value
filteredStack = filteredStack-minValue; %substract the new min
maxValue = max(filteredStack(:)); %new max values
filteredStack = filteredStack./maxValue; %normalize stack according to the new max value

%% view a timepoint from the stack
% t=5;
% I = stack(:,:,:,t);
% Im_Filt = filteredStack(:,:,:,t);
% 
% figure('Position',figSize);
% clf
% h1=subplot(121);
% imshow(I)
% colormap gray
% axis image
% axis off
% title('Original')
% h2=subplot(122);
% imshow(Im_Filt);
% colormap gray
% axis image
% axis off
% linkaxes([h1,h2],'xy')
% title(sprintf('low: %g, high: %g, size: %g, Gaussian',lowPass, highPass,filterSize))
% 
% %% wait for the user before closing and moving on
% h=msgbox('Press OK when you''re ready to move on','band pass filter');
% waitfor(h);
% close all
end