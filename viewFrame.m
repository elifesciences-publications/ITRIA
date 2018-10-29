%% function viewFraem
%{
This function opens frame t of the input stack using imshow.
It is viewed in pseudocolor ("jet"), and NaN values appear in black.
Actually, the NaN values are transparent and the background is black.
The input stack should have one channel.
%}

function [figH] = viewFrame(stack, t, cRange, stackName, ColorMap)

if nargin<5
    ColorMap = 'jet';
end

%for testing
%{
c=1;
t=5;
stack = ratioStack;
cmin = vars.Rred;
cmax = vars.Rox;
cRange = [cmin cmax];
stackName = 'roGFP ratio';
%}

I = stack(:,:,t); %frame t of channel c
figH = imshow(I, 'InitialMagnification', 150); %open image I
axis image %prevent the image from distorting due to screen resolution

colormap(ColorMap) %pseudocolor
%set the color range and add a colorbar
caxis(cRange)
colorbar
%colormap hot %another option

%set NaN as transparent & background as black
set(figH, 'AlphaData', ~isnan(I)) 

% Make a black axis for black background (NaN values)
axis on
set(gca, 'XColor', 'none', 'yColor', 'none', 'xtick', [], 'ytick', [], 'Color', 'black');

%title
titleStr = sprintf('%s, frame %d',stackName,t);
title(titleStr);

% drawnow

end

