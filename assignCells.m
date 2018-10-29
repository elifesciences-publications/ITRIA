function [cellsStruct]=assignCells(trackStruct, propertyMask,propertyStack)
%This function takes a segmented property binary mask, for example roGFP
%expression, and assigns for each segmented object the track ID from the
%trackStruct, based on co-localization of the cells pixels. The
%colocalization doesn't have to be perfect. If one segmented object
%overlaps with more than 1 cell, than it is assigned to the cell with most
%pixels co-localized, and the rest of the pixels are removed.

%% testing
% trackStruct=final_tracks;
% propertyMask=roGFP_mask;
% propertyStack=oxDstack;

%%
cellsStruct=struct;
nFrames=size(propertyMask,3);
LabelMat = bwlabel(propertyMask);

end