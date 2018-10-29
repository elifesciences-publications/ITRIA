function saveTiffStack(stack,stackName,outputPath,conversionType,NormalizeChoice,maxRange)
%This function saves a 3D mat as a .tiff image stack. It can normalize and
%convert the input stack into 16uint or 8uint stack, depending on the input
%choice. 
%stack: input stack of 3D (x,y,t)
%conversionType: 'none','8uint','16uint'. default is 'none'. In the case of
%'none' and if the stack data type is double, the function assumes that the
%dynamic range is [0,1] and automatically scales the data by 255 before 
%writing it to the file as 8-bit values. For other data type look at the
%imwrite function description.
%in the case of '8uint' the values are multiplied by 2^8 before saving.
%in the case of '16uint' the values are multiplied by 2^16 before saving.
%NormalizeChoice: 'none','global','local','max range'. default is 'none'.
%in case of 'max range': if there's maxRange input variable use that, if
%not use the maximum of the stack.
%in all cases, NaN values are converted to zeros.

%% for testing
% stack=oxDstack;
% stackName='oxD';
% outputPath=output_folder;

%% Initialization
oldPath=cd(outputPath); %change folder to outputPath
if nargin<4
    conversionType='none';
end
if nargin<5
    NormalizeChoice='none';
end

%% normalization
if strcmp(NormalizeChoice,'global')
    stack=normalizeImage(stack,'global');
elseif strcmp(NormalizeChoice,'local')
    stack=normalizeImage(stack,'local');
elseif strcmp(NormalizeChoice,'max range')
    if nargin<6
        maxRange=max(stack(:));
    end
    stack = (stack./maxRange);
end 

%% conversion
switch conversionType
    case 'none'
        outStack=stack;
    case 'uint16' 
        stack=stack.*(2^16);
        outStack=uint16(stack); %convert to uint16
    case 'uint8'
        stack=stack.*(2^8);
        outStack=uint8(stack); %convert to uint8
end

%% saving as .tiff
stack_name = [stackName,'.tiff'];
imwrite(outStack(:,:,1),stack_name); %save the first frame
for i = 2:size(outStack,3) %loop through the rest of the frames and add them to the stack
    imwrite(outStack(:,:,i), stack_name, 'writemode', 'append');
end

%%
cd(oldPath)

end