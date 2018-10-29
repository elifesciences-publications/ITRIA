%% test

nFrames=size(BFfilt,3);
BF_normalized=zeros(size(BFfilt));
for i=1:nFrames
    Im=BFfilt(:,:,i);
    BF_normalized(:,:,i)=Im./median(Im(:));
    imshowpair(BF_normalized(:,:,i),Im,'montage');
    pause(0.2);
end
%% 
%% threshold
BF_noBg=BF_normalized;
rawStack=BFfilt;
t=1;
%% under background
thrLow=-Inf;
thrUp=0;
BFthr1=simpleThreshold(BF_noBg, thrLow, thrUp, 'Under background',t);
figure;
imshow(BFthr1(:,:,t));
figure;
imshowpair(BFthr1(:,:,t),rawStack(:,:,t),'montage');

%% above background
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



%%
se = strel('rectangle',[3,3]);
dilated = imdilate(BFthr3,se);
figure;
imshowpair(dilated(:,:,t),BFthr3(:,:,t),'montage');
title('dilated, raw');

%%
conn=4;
filled= imfill(dilated,conn,'holes');
figure;
imshowpair(filled(:,:,t),BFthr3(:,:,t),'montage');
title('filled, thr');

%%
se = strel('rectangle',[2,2]);
eroded = imerode(dilated,se);
% figure;
% imshowpair(erodedThr3(:,:,t),BFthr3(:,:,t),'ColorChannels','green-magenta');
figure;
imshowpair(eroded(:,:,t),BFthr3(:,:,t),'montage');
title('eroded, raw');

maskOverlay = imoverlay(rawStack(:,:,t), eroded(:,:,t), [1 0 0]);
figure;
imshow(maskOverlay);


%% view a movie
for t=1:nFrames
    maskOverlay = imoverlay(rawStack(:,:,t), eroded(:,:,t), [1 0 0]);
    imshow(maskOverlay);
    pause(0.2);
end


%%
kmeansStack=zeros(size(BFfilt,1),size(BFfilt,2),3,size(BFfilt,3));
k=4;
size1=size(BFfilt,1);
size2=size(BFfilt,2);
size3=size(BFfilt,3);
Im_reshape=reshape(BFfilt,size1.*size2.*size3,1);
[idx,c]=kmeans(Im_reshape,k);
idx_reshape=reshape(idx,size1,size2,size3);

%% 
for t=1:nFrames
    rgm_Im=label2rgb(idx_reshape(:,:,t));
    imshow(rgm_Im,'InitialMagnification',150);
    pause(0.2);
end
%%
%%
%%
%%
kmeansStack=zeros(size(BFfilt,1),size(BFfilt,2),3,size(BFfilt,3));
k=4;
size1=size(BFfilt,1);
size2=size(BFfilt,2);
size3=size(BFfilt,3);
Im_reshape=reshape(BF_normalized,size1.*size2.*size3,1);
[idx,c]=kmeans(Im_reshape,k);
idx_reshape2=reshape(idx,size1,size2,size3);

%% 
for t=1:nFrames
    rgm_Im=label2rgb(idx_reshape2(:,:,t));
    imshow(rgm_Im,'InitialMagnification',150);
    pause(0.2);
end
%%
save('BF_segmentationTest.mat','idx_reshape2','idx_reshape','c','BF_normalized','eroded','dilated','filled','BFthr3');

%%
% for t=1:nFrames
%     Im=BFfilt(:,:,t);
%     Im_reshape=reshape(Im,size1.*size2,1);
%     [idx,c]=kmeans(Im_reshape,k);
%     idx_reshape=reshape(idx,size1,size2);
%     rgm_Im=label2rgb(idx_reshape);
%     kmeansStack(:,:,:,t)=rgm_Im;
%     imshow(rgm_Im);
%     pause(0.2);
% end
%%