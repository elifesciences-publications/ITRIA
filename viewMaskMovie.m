
function viewMaskMovie(intStack,maskStack,pauseTime,maskTitle,saveFlag,output_folder)
%This function shows a movie of the maskStack in red overlayed on the 
%intStack. If the saveFlag is 1 and output_folder isn't empty then the
%function saves the overlay as an 8bit RGB stack.

%% Preparations and initiation
if nargin<3
    pauseTime=0.3;
end
if nargin<4
    maskTitle='Mask overlay';
end
if nargin<5
    saveFlag=0;
end
if nargin<6 || isempty(output_folder)
    output_folder=[];
    saveFlag=0;
end
if size(maskStack)~=size(intStack)
    error('stacks do not match in their dimensions')
end

%% looping over the frames
h=figure;

if saveFlag==1 %save the stack
%     overlayName = [inputname(maskStack),'_',inputname(intStack),'_overlay'];
    oldPath=cd(output_folder);
%     maskOverlay=zeros(size(intStack,1),size(intStack,2),3,size(intStack,3),'uint8');
    i=1; %in the first frame create the file
    fileName=[maskTitle,'.tiff'];
    maskOverlay = imoverlay(intStack(:,:,i), maskStack(:,:,i), [1 0 0]);
    imshow(maskOverlay,'InitialMagnification', 150);
    titleStr=sprintf('%s, frame: %g',maskTitle,i);
    title(titleStr);
    imwrite(maskOverlay, fileName,'tiff');
%     imwrite(maskOverlay, fileName,'tiff');

    pause(pauseTime); 
    
    for i=2:size(intStack,3)    
        maskOverlay = imoverlay(intStack(:,:,i), maskStack(:,:,i), [1 0 0]);
        imshow(maskOverlay,'InitialMagnification', 150);
        titleStr=sprintf('%s, frame: %g',maskTitle,i);
        title(titleStr);
        imwrite(maskOverlay, fileName,'tiff','writemode', 'append'); %add the rest of the frames to the existing file
%         imwrite(maskOverlay, fileName,'tiff','writemode', 'append'); %add the rest of the frames to the existing file
        pause(pauseTime);   
    end
%     saveTiffStack(maskOverlay,maskTitle,output_folder,'none','none');
    cd(oldPath);

else %no saving
    for i=1:size(intStack,3)    
        maskOverlay = imoverlay(intStack(:,:,i), maskStack(:,:,i), [1 0 0]);
        imshow(maskOverlay,'InitialMagnification', 150);
        titleStr=sprintf('%s, frame: %g',maskTitle,i);
        title(titleStr);
        pause(pauseTime);   
    end   
end

%%

hMsg=msgbox('Press OK when you''re ready to move on',maskTitle);%Wait for user to view the image
waitfor(hMsg);
close(h);

end