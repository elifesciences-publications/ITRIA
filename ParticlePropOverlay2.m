%% This function was adapted from Vicente's function 'ParticlePropOverlay' (Stocker lab).
% It has some minore changes to suit the Itria.
% P = cells properties
% t = frame number
function ParticlePropOverlay2(stack,P,t,PropField)

% if nargin<5
%     cx=[];
% end
% if nargin<5
%     FilterParam=[];
% end
% DiffType = 'Single';

%% for testing
%{
stack = final488;
P = cellsProps;
t=1;
PropField = 'A';
%}
%% get the first image of the stack (similar to case 'single' in the original function).
Im = stack(:,:,t); %get the image

%% get the property
PN=find([P.Frame]==t);
D=getfield(P(PN),PropField);

%% plot the property overlayed on the input image
hfig = figure;
set(hfig, 'Position', [150, 50, size(Im,2).*2, size(Im,1).*1.8])
clf

%rescale the image
Im(Im==0)=NaN; %remove 0 values to get better dynamic range
Im=(Im-min(Im(:)))./(max(Im(:))-min(Im(:))); %normalize the image to itself
Im(isnan(Im))=0;
ImScaled = Im.*(max(D)-min(D))+max(D)+0.0001; %normalize the values of the image to the values of the property. add something in order to differentiate the colors.
imagesc(ImScaled);
hold on
% scatter(P(PN).X/P(1).Conv,P(PN).Y/P(1).Conv,RescaleMatrix(D,4,100),D);
% imagesc(RescaleMatrix(Im,max(D)+1,max(D)+1+(max(D)-min(D))))
% hold on

%overlay the properties
scatter(P(PN).X/P(1).Conv,P(PN).Y/P(1).Conv,RescaleMatrix(D,4,100),D);
colormap([jet(64);gray(64)])
axis image
H2=colorbar;
set(H2,'YLim',[min(D),max(D)])
titlestr = sprintf('Property: %s,  frame: %g.   min value: %g, max value: %g',PropField,t,min(D),max(D));
title(titlestr)
drawnow
hold off
end

%% rescale matrix function:
% MR=RescaleMatrix(M,LL,UL)
% 
% ML=min(M(:));
% MU=max(M(:));
% 
% MR=(M-ML)/(MU-ML)*(UL-LL)+LL;
