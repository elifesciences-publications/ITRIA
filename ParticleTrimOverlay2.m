function ParticleTrimOverlay2(stack,P,t,PropField,UpperBound,LowerBound)
% From Vicente, Stocker lab.
% same as 'ParticleTrimOverlay' only modified for the Itria input. 

% DiffType='Single';          
% [h_obj, h_noise] = FilterGen_V(FilterParam{1}(1), FilterParam{1}(2),FilterParam{1}(3), FilterParam{2});
% Im_Filt=imfilter(Im,h_noise-h_obj,'replicate');

%% get the image
%for tesnting:
%t=10;
%stack = final488;
Im = stack(:,:,t); %get the image
%% get the property
PN=find([P.Frame]==t);
D=getfield(P(PN),PropField);

%% plot the property overlay
hfig=figure;
clf
set(hfig, 'Position', [150, 50, size(Im,2).*2, size(Im,1).*1.8])
imagesc(Im)
colormap gray
hold on

f=find(D<LowerBound);
plot(P(PN).X(f)/P(1).Conv,P(PN).Y(f)/P(1).Conv,'bo');
f=find(D>UpperBound);
plot(P(PN).X(f)/P(1).Conv,P(PN).Y(f)/P(1).Conv,'ro');
f=find(and(D>=LowerBound,D<=UpperBound));
plot(P(PN).X(f)/P(1).Conv,P(PN).Y(f)/P(1).Conv,'go');
titlestr = sprintf('Property: %s, frame: %g.  blue=below limit, red=above limit, green=good',PropField,t);
title(titlestr)
end
