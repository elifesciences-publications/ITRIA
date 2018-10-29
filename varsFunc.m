%% varsFunc
%{
function for initiation of the variables structure.
you can modify here all the initial variables and parameters.

to add user interactions you can use this function:
answer = inputdlg(prompt,dlg_title,num_lines,defAns);
%}

function [vars] = varsFunc()

vars = struct(); %structure with all the variables and definitions

%% general 
%concatenation choice
vars.concatChoice = 'yes'; %whther to concatenate the stacks. choose 'yes' or 'no'.

%% strain
strain_list={'chl','wt','other'};
prompt='Select the strain:';
[Selection,ok] = listdlg('Name','Strain','PromptString',prompt,...
    'SelectionMode','single','ListString',strain_list);
if ok~=1
    warning('You have to choose one strain!');
    while ok==0
        [Selection,ok] = listdlg('Name','Strain','PromptString',prompt,...
            'SelectionMode','single','ListString',strain_list);
    end
end
vars.strain=strain_list{Selection}; %choose: 'wt','chl' or any other strain

%% image parameters
vars.imgSufix = '*.vsi'; %sufix of the image files. this script is adapted for .vsi files, but might also work with other formats.
%channels order - the options are: '405', '488', 'chl', 'bf', 'other'. The
%order is according to the imaging order.
vars.channels = {'405','488','chl','bf'};
vars.chColor = {[0 1 1],[0 1 0], [1 0 0], 'gray'}; %{cyan,green,red,gray}
vars.nChannels = length(vars.channels); %number of channels

%find channel index:
vars.ind405 = find(ismember(vars.channels,'405'));
vars.ind488 = find(ismember(vars.channels,'488'));
vars.indChl = find(ismember(vars.channels,'chl'));
vars.indBF = find(ismember(vars.channels,'bf'));
% vars.chOtherind = find(ismember(vars.channels,'other'));

vars.bitDepth = 14; %14bit images
vars.minRange = 0; %min pixel value
vars.maxRange = 2^vars.bitDepth; %max pixel value
vars.timepoints = 0;
vars.convFactor = 1; %0.645; %conversion from pixel to um. Use 1 for pixel size.
vars.frameRate = 3; %frame rate, frame per hour

%% Treatment parameters and time stamp variables
vars.treatLables={'80uM H2O2','Sytox'};
vars.treatTimeLabels={'07/12/2016,12:47','08/12/2016,10:21'};% time format:'dd/MM/yyyy,HH:mm'
vars.treatTime=datetime(vars.treatTimeLabels,'InputFormat','dd/MM/yyyy,HH:mm');

%% get the timepoints of the treatment
% prompt = {'Enter start time (HH:MM):','Enter start date (dd/mm):','Enter deltaT (HH:MM):'};
% dlg_title = 'Aquisition time input';
% num_lines = 1;
% defaultans = {'00:00','00/00','00:00'};
% answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
% vars.Treat1Label = imgData.AcquisitionDate;
% vars.startT(i) = datenum(answer{1},'HH:MM');
% vars.startD(i) = datenum(answer{2},'dd/mm');
% vars.deltaT(i) = datenum(answer{3},'HH:MM');          
% vars.timeStampArray=cell(imgData.sizeT,1);
% vars.timeArray=zeros(1,imgData.sizeT);
% vars.timeArray(1)=vars.startT(i);
% vars.timeStampArray{1}=datestr(vars.timeArray(1),'HH:MM');

%% pre-processing
% vars.mean_pix_r = 0; %average the image by x pixels. 

%% Background subtraction
vars.bgMethod='roi';%'bgImage';%choose 'bgImage' to load a background image for subtraction or 'roi' to subtract background based on the ROI
% vars.method_option='subtract'; %choose 'subtract' or 'divide'. relevant only for bgMethod 'bgImage'.


%% bandPass filter parameters (for BF image)
vars.lowPass = 0.2;
vars.highPass = 2;
vars.filterSize = 40; %30 
vars.filtChoice = 'manual'; %choose 'manual' in order to view thew first 
% frame and change filter parameters before filtering the whole stack.

%% threshold
vars.thrChoice = 'manual'; %manual or auotomated threshold. choose 'auto' or 'manual'. ("Do you want to set the threshold manually per image?", newArray("no","yes"));
vars.thr405low = 0.03; %user defined minimum. 400 for 14-bit not normalized
vars.thr405up = (vars.maxRange-1)/vars.maxRange; %avoid saturated pixels. 16383 for 14-bit not normalized
vars.thr405lowCells = 0.013; %user defined minimum. 400 for 14-bit not normalized
vars.thr405upCells = Inf; %avoid saturated pixels. 16383 for 14-bit not normalized
vars.thr488low = 0.01; %user defined minimum. 400 for 14-bit not normalized
vars.thr488up = (vars.maxRange-1)/vars.maxRange;%avoid saturated pixels. 16383 for 14-bit not normalized
vars.thrChlLow = 0.03; %chlorophyll threshold
vars.thrChlUp = (vars.maxRange-1)/vars.maxRange; %chlorophyll threshold
vars.thrExprLow = 0.001; %roGFP expression low threshold
vars.thrExprUp = Inf;%roGFP expression high threshold
vars.thrSytLow=0.11; %sytox threshold
vars.thrSytUp=Inf;%sytox threshold

%% segmentation & masks
%segmentation mask - ask the user
segMask_list={'expression','co-localization','Chl','405'};
prompt=sprintf('Select the segmentation mask.\nThis determines the mask and intensity stacks to be used for segmentation.');
[Selection,ok] = listdlg('Name','Segmentation Mask','PromptString',prompt,...
    'SelectionMode','single','ListString',segMask_list);
if ok~=1
    warning('You have to choose one mask!');
    while ok==0
        [Selection,ok] = listdlg('Name','Segmentation Mask','PromptString',prompt,...
            'SelectionMode','single','ListString',segMask_list);
    end
end
vars.maskType=segMask_list{Selection}; %choose: 'wt','chl' or any other strain

%other masks and segmentation parameters- can be changed here:
vars.segType='mySegmentation'; %options: 'mySegmentation', 'Fiji', 'Mask only'.
vars.distType='intensity'; %distance matrix type to be used for segmentation (used only in mySegmentation!). 
    %options: 'intensity', 'distance' or 'combined'. 
    %'intensity'-distances based on intensity only (within the borders of the mask)
    %'distance'-based on distances from local maxima
    %'combined'-average between distance and intensity (after normalization)
vars.roGFP_maskType='expression'; %This is the mask for which the roGFP ratio and oxD are calculated. choose expression or co-localization
vars.sigma = 0.8; %sigma for gaussian filter
vars.filtType = 'gaussian'; %choose filtering type: 'gaussian', 'median','no filt'.
vars.connec=8; %connectivity for watershed segmentation. you must choose 4 or 8!
% vars.min_cell_r2 = 2; %minimum r^2 pixels per cell. recommendations:\n20x binning 2x2 - 2 pix\n40x no binning - 50 pix. 2
vars.erode_num = 1; %number of times to repeat erode. 0

%% cells properties (before tracking)
vars.centersStack='405';%stack for finding the centers of the cells, for tracking. 
    %options:'Chl','405','488','expression', or 'default'. the default is 
    %to use the same intStack that was used for segmentation.
vars.intStack ='oxD'; %intStack to be used to measure cells properties.
    %The default is to use the same intStack as for the segmentation part 
    %(e.g. final405, finalChl or roGFP expression). Options:
    %'oxD','405','488','AF' (ratio 405/488),'ratio' (roGFP ratio 405/488),
    %or 'default', which is the same intStack that was used for the
    %segmentation.

%% oxidation parameters
vars.extreme = 'no'; %extreme treatment? 'yes' or 'no'.
vars.Rox = 3.1296;%max ox ratio. mean of max ratio per cell exp 160901 using the matlab itria
vars.Rred = 0.5770;%max red ratio. mean of min ratio per cell exp 160901 using the matlab itria
vars.i488ox_red = 0.3802;%The ratio of I488ox/I488red. mean of mean i488 per cell exp 160901 using the matlab itria

%Previous oxidation parameters calculated by the FIJI itria version using the exp 160901:
%max ox ratio.  3.368
%max red ratio.  0.553
%Previous: 0.48127 %The ratio of I488ox/I488red. 
% vars.i488ox = %1645; %max ox 488 intensity.  1645 = mean of mean 488i per cell exp 160901
% vars.i488red = %3418; %max red 488 intensity.  3418 = mean of mean 488i per cell exp 160901

%% cell filtering
vars.minArea=4; %area
vars.maxArea=100;
vars.minEcc=0; %eccentricity (how round the cells are. 0=round, 1=not round, like a line.)
vars.maxEcc=Inf; 
vars.minMajAx=3; %major axis length
vars.maxMajAx=20;
vars.minMinAx=1; %minor axis length
vars.maxMinAx=10;

%% Tracking parameters
vars.TrackMode = 'position';   % Choice of {position, velocity, acceleration} to predict position based on previous behavior
vars.DistanceLimit = 15;%  %8          % Limit of distance a particle can travel between frames, in units defined by ConversionFactor
vars.MatchMethod = 'best';         % Choice of {best, single}
vars.FitLength=1;    %This describes the type and size of fitting for calculation, 
                % 0 - first order difference
                % 1 - second order difference
                % n>1 - polynomial fit, must be equal or larger than MinFrameLength
vars.maxMissed=2; %max missing frames for track linking. 
vars.trackmode_link = 'position';%for missing track linking
vars.trackmode_fill = 'position';%for missing track linking
vars.MinFrameLength=6;%6 %minimum frame length per track for track trimming. shorter tracks are trimmed.

%% sytox analysis
vars.minOverlap=2; %minimum pixel overlap between the cell mask and the sytox mask.

%% print the variables
%{
//print variables
print("\n \n***Variables and Parameters***\n ");
print("Extreme treatment?   "+extreme+"\ntime between frames: "+deltaT+"\n \n");
print("Pre-processing:\naveraging pixel radius: "+mean_pix_r+"\nDifferent threshold per image?   "+thrChoice+"\n \n");
print("Cell detection:\nmin r^2 pixel per cell: "+min_cell_r2+"\nerode times: "+erode_num+"\n \n");
print("Oxidation parameters:\nRox = "+Rox+"\ni488ox = "+i488ox+"\nRred = "+Rred+"\ni488red = "+i488red+
"\n \nOxD formula:\noxD = ((R-Rred)/((R-Rred)/((i488ox/i488red)*(Rox-R)+(R-Rred)))\n \n******");
%}

end