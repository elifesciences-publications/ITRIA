%% image reader
%{
for explenation on the bio-formats image reader:
http://www.openmicroscopy.org/site/support/bio-formats5.2/developers/matlab-dev.html
%}


%% easy reader
function [imgMat, imgData, omeMeta]=imgRead(vars,file_path)

%reader = bfGetReader('C:\Users\aviam\Documents\MATLAB\test\Process_5589.vsi');
reader = bfGetReader(file_path);
omeMeta = reader.getMetadataStore();
imgData = struct();
% deltaT=vars.deltaT;
%check that the channels input by the user is the same as here
imgData.sizeC = omeMeta.getChannelCount(0);
if imgData.sizeC~=vars.nChannels 
    error('there are %d channles instead of %d',imgData.sizeC, vars.nChannels);
end

%check that the z axis = 1
imgData.sizeZ = omeMeta.getPixelsSizeZ(0).getValue(); % number of Z slices
if imgData.sizeZ ~= 1
    error('there are %d Z slices',imgData.sizeZ);
end

%build the image structure. 
imgData.sizeX = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
imgData.sizeY = omeMeta.getPixelsSizeY(0).getValue();
imgData.planes = omeMeta.getPlaneCount(0);

if mod(imgData.planes, imgData.sizeC)~=0 %check if the planes are divided according to the number of channels
    error('the number of planes doesn''t fit the number of channels');
end
imgData.sizeT = imgData.planes./imgData.sizeC;
imgData.AcquisitionDate = omeMeta.getImageAcquisitionDate(0);


%% Image data type
% If you want to normalize the image to a range of [0,1] use this:
% imgMat = zeros(imgData.sizeY, imgData.sizeX, imgData.sizeC, imgData.sizeT); 

%%if you want the data in a 16-bit format use this:
imgMat = zeros(imgData.sizeY, imgData.sizeX, imgData.sizeC, imgData.sizeT, 'uint16');


%% 
%imgData = zeros(SizeY, SizeX, sizeC, sizeT, SizeZ); %for multiple Z slices
reader.setSeries(0);

%loop through the channels and import the data
for iC = 1:imgData.sizeC %loop over the channels
    for iT = 1:imgData.sizeT %loop over timepoints
        iPlane = reader.getIndex(0, iC-1, iT-1) + 1; %iPlane = reader.getIndex(iZ - 1, iC -1, iT - 1) + 1;
        %I = bfGetPlane(reader, iPlane);
        %imgData(:,:,iC,iT) = I(:,:);
        imgMat(:,:,iC,iT) = bfGetPlane(reader, iPlane);
    end %timepoints
end %channels

%% If you want to normalize the image to a range of [0,1] use this:
% imgMat = imgMat./vars.maxRange;


end

%get specific planes:
%series1_plane1 = bfGetPlane(reader, 1);
%series1_plane2 = bfGetPlane(reader, 2);

% Read plane from series iSeries at Z, C, T coordinates (iZ, iC, iT)
% All indices are expected to be 1-based
%reader.setSeries(0); %reader.setSeries(iSeries - 1);
%iPlane = reader.getIndex(0, 0, 0) + 1; %iPlane = reader.getIndex(iZ - 1, iC -1, iT - 1) + 1;
%I = bfGetPlane(reader, iPlane);

%% ------------------------------------------------------------------------

%% full reader
%{
function [data, omeMeta]=imgRead(vars,file_path)

%% open the file
data = bfopen(file_path);

%% ome metadata  -same for all formats
omeMeta = data{1, 4};

%check that the channells number is the same as the user defined number
sizeC = omeMeta.getChannelCount(0); %num of channels in the stack
if sizeC~=vars.nChannels %check that the channels input by the user is the same as here
    error('there are %d channles instead of %d',sizeC, vars.nChannels);
end

%check that the z axis = 1
if SizeZ ~= 1
    error('there are %d Z slices',SizeZ);
end

%get metadata values examples
%{
%stackSizeX = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
%stackSizeY = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
%stackSizeZ = omeMeta.getPixelsSizeZ(0).getValue(); % number of Z slices
%channelName = omeMeta.getChannelName(0,0);%get the name of the first channel
%channelName = omeMeta.getChannelName(0,3);%get the name of the forth channel
%channelID = omeMeta.getChannelID(0,3);
%%timestamps = omeMeta.getTimestampAnnotationCount(); %doesn't work - check
%planes = omeMeta.getPlaneCount(0);
%sizeT = planes./channelCount;
%theT = omeMeta.getPlaneTheT(0,16); timepoint of plane 17 (=16+1) in image 1 (=0+1).


voxelSizeXdefaultValue = omeMeta.getPixelsPhysicalSizeX(0).value();           % returns value in default unit
voxelSizeXdefaultUnit = omeMeta.getPixelsPhysicalSizeX(0).unit().getSymbol(); % returns the default unit type
voxelSizeX = omeMeta.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER); % in µm
voxelSizeXdouble = voxelSizeX.doubleValue();                                  % The numeric value represented by this object after conversion to type double
voxelSizeY = omeMeta.getPixelsPhysicalSizeY(0).value(ome.units.UNITS.MICROMETER); % in µm
voxelSizeYdouble = voxelSizeY.doubleValue();                                  % The numeric value represented by this object after conversion to type double
%voxelSizeZ = omeMeta.getPixelsPhysicalSizeZ(0).value(ome.units.UNITS.MICROMETER); % in µm
%voxelSizeZdouble = voxelSizeZ.doubleValue();                                  % The numeric value represented by this object after conversion to type double
%}

%% create matrix for the image, each timepoint
series1 = data{1, 1};
metadataList = data{1, 2};
series1_plane1 = series1{1, 1};
series1_label1 = series1{1, 2};
imgWidth = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
imgHeight = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
planes = omeMeta.getPlaneCount(0);
timepoints = planes./sizeC;

stackMat = zeros(imgWidth, imgHeight, nChannels, timepoints);


%% for testing:
%{
%data = bfopen('C:\Users\aviam\Documents\MATLAB\test\Process_5589.vsi');

%testing

seriesCount = size(data, 1);
series1 = data{1, 1};
%series2 = data{2, 1};
%series3 = data{3, 1};
metadataList = data{1, 2};
% etc
series1_planeCount = size(series1, 1);
series1_plane1 = series1{1, 1};
series1_label1 = series1{1, 2};
series1_plane2 = series1{2, 1};
series1_label2 = series1{2, 2};
series1_plane3 = series1{3, 1};
series1_label3 = series1{3, 2};
series1_plane4 = series1{4, 1};
series1_label4 = series1{4, 2};

%view image - series1 plane1
series1_colorMaps = data{1, 3};
figure('Name', series1_label1);
if (isempty(series1_colorMaps{1}))
  colormap(gray);
else
  colormap(series1_colorMaps{1}(1,:));
end
imagesc(series1_plane1);


%view image - series1 plane1
imshow(series1_plane1, []);
%}

%%view as movie
%{
cmap = gray(256);
for p = 1 : size(series1, 1)
  M(p) = im2frame(uint8(series1{p, 1}), cmap);
end
if feature('ShowFigureWindows')
  movie(M);
end
%} 

%metadata testing
%metadata = data{1, 2};

%% To print out all of the metadata key/value pairs for the first series:
%{
metadataKeys = metadata.keySet().iterator();
for i=1:metadata.size()
  key = metadataKeys.nextElement();
  value = metadata.get(key);
  fprintf('%s = %s\n', key, value)
end
%}

%% Query some metadata fields (keys are format-dependent)
%{
numericalAperture = metadata.get('Microscope Numerical Aperture #1');
maxFrameSize = metadata.get('Microscope Camera Maximum Frame Size #1');
chName1 = metadata.get('Channel name #1');
chName2 = metadata.get('Channel name #2');
chName3 = metadata.get('Channel name #3');
chName4 = metadata.get('Channel name #4');
chName5 = metadata.get('Channel name #5');
imgName = metadata.get('Global Document Name #1');
creationTime = metadata.get('Global Document Creation Time #1');
magnification = metadata.get('Microscope Objective Description');
%}



%% open the image - another bio formats reader
%{
%[imageStack]=imreadBF(datname,zplanes,tframes,channel);
%[metadata]=imreadBFmeta;
%}

end
%}

% -----------------------------------------------------------------

% % function metadata = createMinimalOMEXMLMetadata(I, varargin)
% % CREATEMINIMALOMEXMLMETADATA Create an OME-XML metadata object from an input matrix
% % 
% %    createMinimalOMEXMLMetadata(I) creates an OME-XML metadata object from
% %    an input 5-D array. Minimal metadata information is stored such as the
% %    pixels dimensions, dimension order and type. The output object is a
% %    metadata object of type loci.formats.ome.OMEXMLMetadata.
% % 
% %    createMinimalOMEXMLMetadata(I, dimensionOrder) specifies the dimension
% %    order of the input matrix. Default valuse is XYZCT.
% % 
% %    Examples:
% % 
% %        metadata = createMinimalOMEXMLMetadata(zeros(100, 100));
% %        metadata = createMinimalOMEXMLMetadata(zeros(10, 10, 2), 'XYTZC');
% % 
% % See also: BFSAVE
% % 
% % OME Bio-Formats package for reading and converting biological file formats.
% % 
% % Copyright (C) 2012 - 2015 Open Microscopy Environment:
% %   - Board of Regents of the University of Wisconsin-Madison
% %   - Glencoe Software, Inc.
% %   - University of Dundee
% % 
% % This program is free software: you can redistribute it and/or modify
% % it under the terms of the GNU General Public License as
% % published by the Free Software Foundation, either version 2 of the
% % License, or (at your option) any later version.
% % 
% % This program is distributed in the hope that it will be useful,
% % but WITHOUT ANY WARRANTY; without even the implied warranty of
% % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% % GNU General Public License for more details.
% % 
% % You should have received a copy of the GNU General Public License along
% % with this program; if not, write to the Free Software Foundation, Inc.,
% % 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
% % 
% % Not using the inputParser for first argument as it copies data
% % assert(isnumeric(I), 'First argument must be numeric');
% % 
% % Input check
% % ip = inputParser;
% % ip.addOptional('dimensionOrder', 'XYZCT', @(x) ismember(x, getDimensionOrders()));
% % ip.parse(varargin{:});
% % 
% % Create metadata
% % toInt = @(x) javaObject('ome.xml.model.primitives.PositiveInteger', ...
% %                         javaObject('java.lang.Integer', x));
% % OMEXMLService = javaObject('loci.formats.services.OMEXMLServiceImpl');
% % metadata = OMEXMLService.createOMEXMLMetadata();
% % metadata.createRoot();
% % metadata.setImageID('Image:0', 0);
% % metadata.setPixelsID('Pixels:0', 0);
% % if is_octave()
% %     java_true = java_get('java.lang.Boolean', 'TRUE');
% % else
% %     java_true = java.lang.Boolean.TRUE;
% % end
% % metadata.setPixelsBinDataBigEndian(java_true, 0, 0);
% % 
% % Set dimension order
% % dimensionOrderEnumHandler = javaObject('ome.xml.model.enums.handlers.DimensionOrderEnumHandler');
% % dimensionOrder = dimensionOrderEnumHandler.getEnumeration(ip.Results.dimensionOrder);
% % metadata.setPixelsDimensionOrder(dimensionOrder, 0);
% % 
% % Set pixels type
% % pixelTypeEnumHandler = javaObject('ome.xml.model.enums.handlers.PixelTypeEnumHandler');
% % if strcmp(class(I), 'single')
% %     pixelsType = pixelTypeEnumHandler.getEnumeration('float');
% % else
% %     pixelsType = pixelTypeEnumHandler.getEnumeration(class(I));
% % end
% % metadata.setPixelsType(pixelsType, 0);
% % 
% % Read pixels size from image and set it to the metadat
% % sizeX = size(I, 2);
% % sizeY = size(I, 1);
% % sizeZ = size(I, find(ip.Results.dimensionOrder == 'Z'));
% % sizeC = size(I, find(ip.Results.dimensionOrder == 'C'));
% % sizeT = size(I, find(ip.Results.dimensionOrder == 'T'));
% % metadata.setPixelsSizeX(toInt(sizeX), 0);
% % metadata.setPixelsSizeY(toInt(sizeY), 0);
% % metadata.setPixelsSizeZ(toInt(sizeZ), 0);
% % metadata.setPixelsSizeC(toInt(sizeC), 0);
% % metadata.setPixelsSizeT(toInt(sizeT), 0);
% % 
% % Set channels ID and samples per pixel
% % for i = 1: sizeC
% %     metadata.setChannelID(['Channel:0:' num2str(i-1)], 0, i-1);
% %     metadata.setChannelSamplesPerPixel(toInt(1), 0, i-1);
% % end
% % 
% % end
% % 
% % function dimensionOrders = getDimensionOrders()
% % List all values of DimensionOrder
% % dimensionOrderValues = javaMethod('values', 'ome.xml.model.enums.DimensionOrder');
% % dimensionOrders = cell(numel(dimensionOrderValues), 1);
% % for i = 1 :numel(dimensionOrderValues),
% %     dimensionOrders{i} = char(dimensionOrderValues(i).toString());
% % end
% % end

%% 
% bfUpgradeCheck;
% function bfUpgradeCheck(varargin)
% % Check for new version of Bio-Formats and update it if applicable
% %
% % SYNOPSIS: bfUpgradeCheck(autoDownload, 'STABLE')
% %
% % Input
% %    autoDownload - Optional. A boolean specifying of the latest version
% %    should be downloaded
% %
% %    versions -  Optional: a string sepecifying the version to fetch.
% %    Should be either trunk, daily or stable (case insensitive)
% %
% % Output
% %    none
% 
% % OME Bio-Formats package for reading and converting biological file formats.
% %
% % Copyright (C) 2012 - 2015 Open Microscopy Environment:
% %   - Board of Regents of the University of Wisconsin-Madison
% %   - Glencoe Software, Inc.
% %   - University of Dundee
% %
% % This program is free software: you can redistribute it and/or modify
% % it under the terms of the GNU General Public License as
% % published by the Free Software Foundation, either version 2 of the
% % License, or (at your option) any later version.
% %
% % This program is distributed in the hope that it will be useful,
% % but WITHOUT ANY WARRANTY; without even the implied warranty of
% % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% % GNU General Public License for more details.
% %
% % You should have received a copy of the GNU General Public License along
% % with this program; if not, write to the Free Software Foundation, Inc.,
% % 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
% % Check input
% ip = inputParser;
% ip.addOptional('autoDownload', false, @isscalar);
% versions = {'stable', 'daily', 'trunk'};
% ip.addOptional('version', 'STABLE', @(x) any(strcmpi(x, versions)))
% ip.parse(varargin{:})
% 
% % Create UpgradeChecker
% upgrader = javaObject('loci.formats.UpgradeChecker');
% if upgrader.alreadyChecked(), return; end
% 
% % Check for new version of Bio-Formats
% if is_octave()
%     caller = 'Octave';
% else
%     caller = 'MATLAB';
% end
% if ~ upgrader.newVersionAvailable(caller)
%     fprintf('*** bioformats_package.jar is up-to-date ***\n');
%     return;
% end
% 
% fprintf('*** A new stable version of Bio-Formats is available ***\n');
% % If appliable, download new version of Bioformats
% if ip.Results.autoDownload
%     fprintf('*** Downloading... ***');
%     path = fullfile(fileparts(mfilename('fullpath')), 'bioformats_package.jar');
%     buildName = [upper(ip.Results.version) '_BUILD'];
%     upgrader.install(loci.formats.UpgradeChecker.(buildName), path);
%     fprintf('*** Upgrade will be finished when MATLAB is restarted ***\n');
% end
