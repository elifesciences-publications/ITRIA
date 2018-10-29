
function maskStack=BFsegmentation(rawStack)
%This function segments BF images.

%% for testing:
% rawStack=BFfilt;
rawStack=BFfilt;
% thrStack=thrBF;
sigma=1;
rawStack2 = imgaussfilt(rawStack,sigma);


%% creating & subtracting background
t=10;
sigma=20;
BfBg= imgaussfilt(rawStack2,sigma);
figure;
imshowpair(BfBg(:,:,t),rawStack2(:,:,t),'montage');
% imshowpair(BfBg(:,:,t),BFfilt(:,:,t),'ColorChannels','green-magenta');

BF_noBg=rawStack2-BfBg;
% BF_noBg(BF_noBg<0)=0;
figure;
imshowpair(BF_noBg(:,:,t),rawStack2(:,:,t),'montage');

%% normalize after BG
% sigma=1;
normStack = normalizeImage(BF_noBg,'local');
% normStack = imgaussfilt(normStack,sigma);
figure;
imshowpair(normStack(:,:,t),rawStack(:,:,t),'montage');
%%

%% threshold
BF_noBg=normStack;
t=1;
%under background
thrLow=-Inf;
thrUp=0;
BFthr1=simpleThreshold(BF_noBg, thrLow, thrUp, 'Under background',t);
figure;
imshow(BFthr1(:,:,t));
figure;
imshowpair(BFthr1(:,:,t),rawStack(:,:,t),'montage');

%above background
thrLow=0.05;
thrUp=Inf;
BFthr2=simpleThreshold(BF_noBg, thrLow, thrUp, 'Under background',t);
figure;
imshow(BFthr2(:,:,t));
figure;
imshowpair(BFthr2(:,:,t),rawStack(:,:,t),'montage');

%% both thresholds together
t=1;
BFthr3 = BFthr1 | BFthr2;
figure;
imshow(BFthr3(:,:,t));
figure;
imshowpair(BFthr3(:,:,t),rawStack(:,:,t),'montage');
maskOverlay = imoverlay(rawStack(:,:,t), BFthr3(:,:,t), [1 0 0]);
figure;
imshow(maskOverlay);
%% dilate
% t=1;
% R=2;
% N=4;
% se = strel('disk', R, N);
se = strel('rectangle',[2,2]);
dilated = imdilate(BFthr3,se);
figure;
imshowpair(dilated(:,:,t),BFthr3(:,:,t),'montage');
title('dilated, raw');
% figure;
% imshowpair(dilatedThr3(:,:,t),BFthr3(:,:,t),'montage');
% title('dilated, thr');

%% fill
conn=4;
filled= imfill(dilated,conn,'holes');
figure;
imshowpair(filled(:,:,t),BFthr3(:,:,t),'montage');
title('filled, thr');

%% erode
% R=2;
% N=4;
% se = strel('disk', R, N);
se = strel('rectangle',[3,3]);
eroded = imerode(dilated,se);
% figure;
% imshowpair(erodedThr3(:,:,t),BFthr3(:,:,t),'ColorChannels','green-magenta');
figure;
imshowpair(eroded(:,:,t),BFthr3(:,:,t),'montage');
title('eroded, raw');

maskOverlay = imoverlay(rawStack(:,:,t), eroded(:,:,t), [1 0 0]);
figure;
imshow(maskOverlay);
%%
t=1;
I=rawStack(:,:,t);
BW1 = edge(I,'sobel');
% BW1 = edge(I,'log');
cthr=[0.01,0.5];
BW2= edge(I,'Canny',cthr);

% BW2 = edge(I,'canny');
figure;
imshowpair(BW1,BW2,'montage')
title('Sobel Filter                                   Canny Filter');

%% dilate
t=1;
se = strel('rectangle',[3,3]);
dilatedBF = imdilate(rawStack,se);
figure;
imshowpair(dilatedBF(:,:,t),rawStack(:,:,t),'montage');
figure;
imshowpair(thrStack(:,:,t),rawStack(:,:,t),'montage');

dilatedThr = imdilate(thrStack,se);
figure;
imshowpair(thrStack(:,:,t),dilatedThr(:,:,t),'montage');

%fill
t=10;
conn=4;
filledThr= imfill(dilatedThr,conn,'holes');
figure;
imshowpair(dilatedThr(:,:,t),filledThr(:,:,t),'montage');

% erode
se = strel('rectangle',[5,5]);
eroded = imerode(filledThr,se);
% t=40;
figure;
imshowpair(eroded(:,:,t),filledThr(:,:,t),'montage');
maskOverlay = imoverlay(rawStack(:,:,t), eroded(:,:,t), [1 0 0]);
figure;
imshowpair(maskOverlay,I,'montage');
%%
cthrLow=0.001;
cthrUp=0.03;
cthr=[cthrLow,cthrUp];
t=1;
BF_noBg2 = BF_noBg;
BF_noBg2(BF_noBg<0)=0;
I=normStack(:,:,t);
BW=edge(I,'Canny',cthr);

hFig=figure;
title('Canny');
imshowpair(BW,I,'montage');
% imshow(BW,'InitialMagnification', 150);
qstring = 'Are you happy with that threshold?';
thrAnswer = questdlg(qstring,'Manual Threshold');

while strcmp(thrAnswer,'No') 
%     get new threshold values
    prompt = {'Enter lower threshold:','Enter upper threshold:'};
    dlg_title = 'Threshold input';
    num_lines = 1;
    defaultans = {num2str(cthrLow),num2str(cthrUp)};
    answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
    cthrLow = str2double(answer{1});
    cthrUp = str2double(answer{2});
    

%     calculate the new thrshold and display it
    cthr=[cthrLow,cthrUp];
    BW= edge(I,'Canny',cthr);
%     imshow(BW,'InitialMagnification', 150);
    imshowpair(BW,I,'montage')
    title('Canny');
    axis image;

%     ask again the user if the threshold is satisfying
    qstring = 'Are you happy with that threshold?';
    thrAnswer = questdlg(qstring,'Manual Threshold');
end

%% calculate the canny stack
CannyStack=zeros(size(BF_noBg));
for i=1:size(BF_noBg,3)
    CannyStack(:,:,i)=edge(normStack(:,:,i),'Canny',cthr);
end

%% dilate
% t=1;
% R=1;
% N=4;
% se = strel('disk', R, N);
se = strel('rectangle',[2,2]);
dilated = imdilate(CannyStack,se);
figure;
imshowpair(dilated(:,:,t),CannyStack(:,:,t),'montage');
title('dilated, raw');
% figure;
% imshowpair(dilatedThr3(:,:,t),BFthr3(:,:,t),'montage');
% title('dilated, thr');

%% fill
conn=4;
filled= imfill(dilated,conn,'holes');
figure;
imshowpair(filled(:,:,t),CannyStack(:,:,t),'montage');
title('filled, thr');
%% erode
se = strel('rectangle',[5,5]);
eroded = imerode(filled,se);
% t=40;
figure;
imshowpair(eroded(:,:,t),CannyStack(:,:,t),'montage');
maskOverlay = imoverlay(rawStack(:,:,t), eroded(:,:,t), [1 0 0]);
figure;
imshowpair(maskOverlay,I,'montage');

%% view movie
% stackView = CannyStack;
% pauseTime = 0.3;
% figure;
% for i=1:20 %size(stackView,3)
%     imshow(stackView(:,:,i),'InitialMagnification', 150);
%     titleStr=sprintf('Frame: %g',i);
%     title(titleStr);
%     pause(pauseTime);
% end

%% view mask movie
stack1=rawStack;
stack2=BFthr2;
pauseTime = 0.3;
% maskOverlay=zeros(size(stack1,1),size(stack1,2),3,size(stack1,3));
figure;
for i=1:size(stack1,3)
    maskOverlay = imoverlay(stack1(:,:,i), stack2(:,:,i), [1 0 0]);
%     maskOverlay(:,:,:,i) = imoverlay(stack1(:,:,i), stack2(:,:,i), [1 0 0]);
    imshow(maskOverlay,'InitialMagnification', 150);
    titleStr=sprintf('Frame: %g',i);
    title(titleStr);
    pause(pauseTime);
end

%%
t=1;
stdfiltIm=stdfilt(BF_norm);
thrLow=0.3;
thrUp=Inf;
StdThr=simpleThreshold(stdfiltIm, thrLow, thrUp, 'Std filt',t);
imshow(StdThr(:,:,t));

%% dilate
% se = strel('line',3,90);
% dilatedBW = imdilate(BW,se);
% imshowpair(dilatedBW,BW,'montage');

%%
% conn=4;
% BW2= imfill(BW,conn,'holes');
% imshowpair(BW,BW2,'montage');

%% outer boundry of cells
thrLow=0;
thrUp=0.3;
BFthr1=simpleThreshold(rawStack, thrLow, thrUp, 'BF filt',t);
imshow(BFthr1(:,:,t));

%%
% se = strel('rectangle',[3,3]);
% dilatedThr1 = imdilate(BFthr1,se);
% imshowpair(dilatedThr1(:,:,t),BFthr1(:,:,t),'montage');

%%
% conn=4;
% BW3= imfill(dilatedBW1,conn,'holes');
% figure;
% imshowpair(dilatedBW1(:,:,t),BW3(:,:,t),'montage');


%% inner part of cells
thrLow=0.3;
thrUp=Inf;
BFthr2=simpleThreshold(rawStack, thrLow, thrUp, 'BF filt',t);
imshow(BFthr2(:,:,t));

%% dilate
% se = strel('rectangle',[2,2]);
% dilatedBW = imdilate(BFthr2,se);
% imshowpair(dilatedBW(:,:,t),BFthr2(:,:,t),'montage');

%% the two thresholds
BFthr3=BFthr2 | BFthr1;
figure;
imshowpair(I,BFthr3(:,:,t),'montage');

%%
%find local maxima within the regions
% stack_localMax=zeros(size(rawStack));
% stack_localMax(BFthr3)= imregionalmax(rawStack(BFthr3));
% imshowpair(I,stack_localMax(:,:,t),'montage');

%% dilate

se = strel('rectangle',[2,2]);
dilatedBW = imdilate(BFthr3,se);
imshowpair(dilatedBW(:,:,t),BFthr3(:,:,t),'montage');

%% fill
conn=4;
filledBW= imfill(dilatedBW,conn,'holes');
figure;
imshowpair(dilatedBW(:,:,t),filledBW(:,:,t),'montage');

%% erode
se = strel('rectangle',[5,5]);
eroded = imerode(filledBW,se);
t=40;
figure;
imshowpair(eroded(:,:,t),filledBW(:,:,t),'montage');
maskOverlay = imoverlay(rawStack(:,:,t), eroded(:,:,t), [1 0 0]);
figure;
imshowpair(maskOverlay,I,'montage');
% imshow(maskOverlay, 'InitialMagnification', 150);

%%
maskStack = eroded;
%% dilate the centers
% se = strel('rectangle',[4,4]);
% dilatedBW2 = imdilate(BFthr2,se);
% imshowpair(dilatedBW2(:,:,t),BFthr2(:,:,t),'montage');

%% remove the boundries
% resultStack=zeros(size(dilatedBW2));
% resultStack(~BFthr1)= dilatedBW2(~BFthr1);
% imshowpair(resultStack(:,:,t),dilatedBW2(:,:,t),'montage');

% erodedStack2 = imerode(dilatedBW,se);
% figure;
% imshowpair(dilatedBW(:,:,t),erodedStack2(:,:,t),'montage');
end