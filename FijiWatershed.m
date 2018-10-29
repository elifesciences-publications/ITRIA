
function segStack = FijiWatershed(MaskStack,ErodeNum, OpenFlag,CloseFlag)
%This function uses MIJI (operating ImageJ/FIJI from Matlab) in order to
%erode the cell mask and then perform watershed segmentation. The output
%segStack is a binary cell mask stack.

%% Initialization
if nargin<2
    ErodeNum=0;
end
if nargin<3
    OpenFlag=1;
end
if nargin<4
    CloseFlag=1;
end
%% For testing:
% MaskStack = thr_expression;
% % MaskStack = colocalizationMat;
% ErodeNum=0;
% OpenFlag=0;
% CloseFlag=0;

%% Open Miji and the stack
if OpenFlag==1
    Miji; %open MIJI (imageJ)
end
mask_uint8 = uint8(MaskStack.*2^8); %convert to 8-bit image for imageJ
MIJ.createImage(mask_uint8); %open the mask stack
%% Erode the cell mask
if ErodeNum>0
    for i=1:ErodeNum
        MIJ.run('Erode', 'stack');
    end   
end

%% perform watershed segmentation
MIJ.run('Watershed', 'stack');
segStack = MIJ.getCurrentImage;

%% close everything and exit MIJI
hMsg=msgbox('Press OK when you''re ready to move on','Watershed segmentation');%Wait for user to view the image
waitfor(hMsg);
MIJ.closeAllWindows;
% MIJ.run('Close All');
if CloseFlag==1
    MIJ.exit;
end

end
% 	if (erode_num>0){
% 		for (i=0; i<erode_num; i++){
% 		run("Erode"); //erode is repeated erode_num times to avoid pixels on the edge of the cell
% 		}
% 	}
% 	
% 	run("Watershed");