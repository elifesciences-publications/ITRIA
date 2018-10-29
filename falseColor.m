% 
% False color image
% I = grayscale image
% cmpa = color map = false color array of 3 ellements: [R G B].
% example: cyan is [0 1 1]. red is [1 0 0].
% this function works both for stacks and for individual images.

function rgbImg = falseColor(I,cmap)

redChannel = I.*(cmap(1));
greenChannel = I.*(cmap(2));
blueChannel = I.*(cmap(3));
rgbImg = cat(3, redChannel, greenChannel, blueChannel);

%% optional - view the output
%imshow(rgbImage)
end