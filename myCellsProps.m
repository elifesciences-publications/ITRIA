%% myTracking function
% This function takes the cell mask input, and gets the properties of each
% cell. The output is the structure cellsProps. cellsProps(t) holds the
% properties of the cells in frame t of the cellMask stack. you can access
% a specific property as follows:
% cellsProps(t).PixelIdxList{i} = pixel indexes of cell i
% cellsProps(t).X(i)= X coordinates of weighted center of particle i
% cellsProps(t).Y(i)= Y coordinates of weighted center of particle i
% cellsProps(t).Xcenter(i)= X coordinates of centroid of particle i
% cellsProps(t).Ycenter(i)= Y coordinates of centroid of particle i
% cellsProps(t).A= area
% cellsProps(t).AvgInt= average intensity
% cellsProps(t).MaxInt= max intensity
% cellsProps(t).MinInt= min intensity
% cellsProps(t).SumInt= sum intensity
% cellsProps(t).Ecc= Eccentricity
% cellsProps(t).MajAx= MajorAxisLength 
% cellsProps(t).MinAx= MinorAxisLength 
% cellsProps(t).Ang= Orientation 
% cellsProps(t).Frame= frame
% cellsProps(t).Conv= Conversion factor from pixel to um


function [cellsProps] = myCellsProps(stack,intStack,cellsMask,ConvFactor,frameRate)

if nargin<5; frameRate=1; end
if nargin<4; ConvFactor=1; end

%% for testing:
%{
stack = oxDstack;
intStack = final488;
cellsMask = cellsMask;
ConvFactor = 1; %1 for pixel size
frameRate =3;
%}

%% preparations
cellsProps=struct(); %initiate empty structure for the cells in each image
nFrames = size(cellsMask,3);

%% loop over the frames and get all the properties of the cells
for t=1:nFrames
    I =stack(:,:,t); %image for output measurements
    I_int = intStack(:,:,t); %intensity image of frame t >> just for finding the object centroid. for roGFP use either chlorophyll or 488 signal. optional - use BF.
    I_mask = cellsMask(:,:,t); %cell mask image of frame t
    I_CC = bwconncomp(I_mask,8); %cells of frame t
    tempXY=regionprops(I_CC,'PixelList','PixelIdxList','Area','Eccentricity','MajorAxisLength','MinorAxisLength','Orientation','Centroid');%get object properties of the cells in frame t
    
    cellsProps(t).PixelIdxList={tempXY.PixelIdxList}';
    cellsProps(t).X=arrayfun(@(x) sum(x.PixelList(:,1).*I_int(x.PixelIdxList))/sum(I_int(x.PixelIdxList)),tempXY).*ConvFactor; %X location of centroid based on weighted average intensity
    cellsProps(t).Y=arrayfun(@(x) sum(x.PixelList(:,2).*I_int(x.PixelIdxList))/sum(I_int(x.PixelIdxList)),tempXY).*ConvFactor; %Y location of centroid based on weighted average intensity
    cellsProps(t).Xcentroid = arrayfun(@(x) x.Centroid(:,1),tempXY); %centroid X index
    cellsProps(t).Ycentroid = arrayfun(@(x) x.Centroid(:,2),tempXY); %centroid Y index 
    cellsProps(t).A=arrayfun(@(x) x.Area,tempXY).*ConvFactor^2; %area
    cellsProps(t).AvgInt=arrayfun(@(x) mean(I(x.PixelIdxList),'omitnan'),tempXY); %mean intensity per cell (excluding NaN values)
    cellsProps(t).MaxInt=arrayfun(@(x) max(I(x.PixelIdxList)),tempXY); %max intensity per cell
    cellsProps(t).MinInt=arrayfun(@(x) min(I(x.PixelIdxList)),tempXY); %min intensity per cell
    cellsProps(t).SumInt=arrayfun(@(x) sum(I(x.PixelIdxList)),tempXY); %intensity sum per cell
    cellsProps(t).Ecc=arrayfun(@(x) x.Eccentricity,tempXY); %eccentricity
    cellsProps(t).MajAx=arrayfun(@(x) x.MajorAxisLength,tempXY).*ConvFactor; %major axis
    cellsProps(t).MinAx=arrayfun(@(x) x.MinorAxisLength,tempXY).*ConvFactor; %minor axis
    cellsProps(t).Ang=arrayfun(@(x) x.Orientation,tempXY); %orientation
    cellsProps(t).Frame=t; %frame number
    cellsProps(t).Conv=ConvFactor; %conversion factor from pixel to um
    cellsProps(t).FPS=frameRate; %frame per hour. I kept the use of "FPS" from Vicente in order for it to fit the other functions.
    
end % t frames loop

    
end