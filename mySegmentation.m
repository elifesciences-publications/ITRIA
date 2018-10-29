
function [I_segmented]=mySegmentation(stack, colocalizationMat, t, filtType, sigma,connec,distType)
%% mySegmentation function
%[I_segmented]=mySegmentation(stack, colocalizationMat, t, filtType, sigma,connec)
% filtType: 'gaussian', 'no filt', 'median'
% 1. get the stack and image of frame t
% 2. filter the image (only if sigma>0).
% 3. find local maximum within the co-localization pixels
% 4. calculate distances from local max
% 5. preform watershed transform

%% for testing
%{
% t=1;
% sigma=0.8;
% % sigma=0;
% stack = final488; 
% % stack = BFfinal;
% % colocalizationMat = BFcenters;
% filtType = 'median';
% % filtType = 'no filt';
% filtType  = 'gaussian';
%}

%% validate input variables
if nargin<7
    distType='intensity'; %choose either 'intensity', 'distance' or 'combined'. 
end
if nargin<6
    connec=8;
end
if nargin<5
    sigma=0;
end
if nargin<4
    filtType = 'gaussian';
end

if size(stack)~=size(colocalizationMat)
    warning('The size of the input stack and colocalization stack does not match');
end    

%% initiation
%r = vars.r; %cell radius
I = stack (:,:,t); % frame t of the stack
I(isnan(I))=0; %remove NaNs in case there are any. This enables to use images with NaN as background.
coI = colocalizationMat(:,:,t); % frame t of the colocalizationMat 

%% filtering: switch between filtering methods
switch filtType
    case 'gaussian'        
        % filter using a gaussian filter
        %choose gaussian and/or median filter
        % sigma=0.9;
        if sigma>0
            I_filt = imgaussfilt(I,sigma); %gaussian filter
        else
            I_filt = I;
        end

    case 'median'
        I_filt = medfilt2(I); %median filter
        
    case 'no filt'
        I_filt = I;
       
    otherwise
        warning('filter type not specified correctly, no filter was applied');
        I_filt = I;
end %switch filter type


%% switch according to distance type
%choose either 'intensity', 'distance' or 'combined'
%intensity: based only on intensity gradient
%distance: based on distance from local maxima within the cell mask
%combined: average of the two above.
switch distType
    case 'intensity'
        I_final=1./I_filt; %invert I_filt
        I_final(~coI)=-Inf; %apply the mask
        
    case 'distance'
        I_filt(~coI)=0;
        I_localMax = imregionalmax(I_filt);% finding local maxima
        I_final = bwdist(I_localMax);% create a distance matrix for the local maxima
        I_final(~coI) = -Inf;
    case 'combined'
        %local maxima
        I_filt(~coI)=0;
        I_localMax = imregionalmax(I_filt);
        I_dist = bwdist(I_localMax);
        I_dist_norm=I_dist./max(I_dist(:)); %normalize
        
        %inverted intensity
        I_filt_inverted=1./I_filt;
        I_filt_inverted=I_filt_inverted./max(I_filt_inverted(:)); %normalize
        
        %calculate the mean
        I_final=(I_filt_inverted+I_dist_norm)./2; %mean of the two 
        I_final(~coI)=-Inf;
    otherwise
        error('unknown distance type for cell segmentation');
end

%% finding local maxima
% I_filt(~coI)=0; %only colocalized pixels
% I_localMax = imregionalmax(I_filt); %find local maxima

%% create a distance matrix for the local maxima
% I_dist = bwdist(I_localMax);
% I_dist(~coI) = -Inf; % make the background pixels -Inf %%I've commented
% that line since it's not required.
%{
%create distance matrix for the distance from the edge of the objects
% I_dist2 = bwdist(~coI);
% % I_dist2 = -I_dist2;
% %create a conbined distance matrix
% I_dist3 = I_dist + I_dist2;
% I_dist4 = -(I_filt.*I_dist2);
% % make the background pixels -Inf
% I_dist2(~coI) = -Inf;
% I_dist3(~coI) = -Inf;
% I_dist4(~coI) = -Inf;

%plot the different figs
% figure;
% subplot(2,2,1);
% imshow(I);
% title('I');
% subplot(2,2,2);
% imshow(I_dist);
% title('I_dist');
% subplot(2,2,3);
% imshow(I_dist4);
% title('I_dist4');
% subplot(2,2,4);
% imshow(I_dist3);
% title('I_dist3');

% figure
% imshow(I_dist,[],'InitialMagnification','fit')
% title('Distance transform of ~I_center')
%}    

%% combine the distance matrix with the intensity matrix 
%to create the final segmentation matrix
% I_dist_norm=I_dist./max(I_dist(:)); %normalize I_dist
% I_dist_norm=I_dist;
% I_filt_inverted=1./I_filt; %invert I_filt
% % I_filt_inverted=I_filt_inverted./max(I_filt_inverted(:)); %normalize
% % I_combined=(I_filt_inverted+I_dist_norm)./2; %mean of the two 
% I_combined=I_filt_inverted;
% I_combined(~coI)=-Inf;
% figure;
% imshowpair(I_filt_inverted,I_dist,'ColorChannels','green-magenta');
% title('I_filt_inverted=green,   I_dist=magenta');
% h=msgbox('Press OK when you''re ready to move on','segmentation');
% waitfor(h);

%% use watershed transform to segment the cells
I_segmented = watershed(I_final,connec);
% I_segmented = watershed(I_dist,8);
%{
% I_seg2 = watershed(I_dist2);
% I_seg3 = watershed(I_dist3);
% I_seg4 = watershed(I_dist4);
%in I_segmented:
% 1 = background
% 0 = boundry
% n>1 = cell label
%}

%% view the segmented frame in pseusocolor
% I_segColor = label2rgb(I_segmented,'jet',[.5 .5 .5]);
% imshow(I_segColor);
%{
% I_segColor = label2rgb(I_segmented,'jet',[.5 .5 .5]);
% I_segColor2 = label2rgb(I_seg2,'jet',[.5 .5 .5]);
% I_segColor3 = label2rgb(I_seg3,'jet',[.5 .5 .5]);
% I_segColor4 = label2rgb(I_seg4,'jet',[.5 .5 .5]);

%plot the different figs
% figure;
% subplot(2,2,1);
% imshow(I);
% title('I');
% subplot(2,2,2);
% imshow(I_segColor);
% title('I_segColor');
% subplot(2,2,3);
% imshow(I_segColor4);
% title('I_segColor4');
% subplot(2,2,4);
% imshow(I_segColor3);
% title('I_segColor3');

%plot the segmentation
% figure
% imshow(I_segColor,'InitialMagnification',150)
% title('Watershed transform')
% h=msgbox('Press OK when you''re ready to move on','band pass filter');
% waitfor(h);
%}

end


 %% create a matrix with three layers: 1=background, 2=cells, 3= local maxima
% 
% I2=zeros(size(I));
% I2(~coI) = 1;
% I2(coI) = 2;
% I2(I_center) = 3;
% imshow(I2);
% 
% x= watershed(I2);
% imshow(x);

%% 
% t=20;
% I=finalChl(:,:,t);
% figure;
% imshow(I);
% sigma=2;
% I=imgaussfilt(I,sigma);
% coI=thr_normChl(:,:,t);
% I_localMax = imregionalmax(I);
% I_dist = bwdist(I_localMax);
% I_dist(~coI)=0;
% % I_dist=I_dist./max(I_dist(:));
% I2=1./I;
% I2(~coI)=0;
% % I2=I2./max(I2(:));
% % I3=(I_dist+I2)./2;
% I3=(I_dist+I2);
% I3(~coI)=-Inf;
% % I_dist(~coI)=-Inf;
% % I2(~coI)=-Inf;
% 
% I_segmented = watershed(I3,4);
% I_segColor = label2rgb(I_segmented,'jet',[.5 .5 .5]);
% figure
% imshow(I_segColor);
% title('segmented');
% figure;
% imshowpair(I2,I_dist,'ColorChannels','green-magenta');

%% test
% D = bwdist(~coI);
% figure
% imshow(D,[],'InitialMagnification','fit')
% title('Distance transform of ~bw')
% 
% D = -D;
% D(~bw) = -Inf;
% 
% L = watershed(D);
% rgb = label2rgb(L,'jet',[.5 .5 .5]);
% figure
% imshow(rgb,'InitialMagnification','fit')
% title('Watershed transform of D')