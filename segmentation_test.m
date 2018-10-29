%% segmentation test

%% segemntation
t=1; %frame number.
filtType='gaussian'; %options: 'gaussian', 'median', 'no filt'
sigma=0.8; %for gaussian filter.
connec=4; %connectivity for watershed (choose 4 or 8)
stack=norm_expression_1; %Intensity stack/image. you can switch to final488_1
colocMat=expression_mask_1; %Mask stack/image. you can switch to colocalization_mask_1
I_segmented=mySegmentation(stack, colocMat, t, filtType, sigma,connec);

%% view the segmented image
I_segColor = label2rgb(I_segmented,'jet',[.5 .5 .5]);
figH = figure;
imshow(I_segColor,'InitialMagnification',150)
title(sprintf('Watershed transform, frame %g, sigma %g',t, sigma));

%% view BF image or other image
figure;
im = BFfilt_1;
imshow(im,'InitialMagnification',150)

%%