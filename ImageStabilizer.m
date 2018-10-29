
function [stableStack1,stableStack2,stableStack3,stableStack4] = ImageStabilizer(outputDir,stack1,stack2,stack3,stack4,OpenFlag,CloseFlag,saveFlag,fileName)

%% for testing
% stack1=rawChl;
% stack2=raw488;
% stack3=raw405;
% stack4=rawBF;
% outputDir = output_folder;
%% initialization
if size(stack1,3)<=1;   warning('this is not a stack'); end
if nargin<9 || isempty(fileName);   fileName='stabilizer_log'; end
if nargin<8;    saveFlag=0; end
if nargin<7;    CloseFlag=1; end
if nargin<6;    OpenFlag=1; end
if nargin<5;    stack4=[];  end
if nargin<4;    stack3=[];  end
if nargin<3;    stack2=[];  end
%% setup
% cd('C:\fiji\Fiji.app\scripts');
% javaaddpath 'C:/Program Files/MATLAB/R2015b/java/mij.jar'
% javaaddpath 'C:/Program Files/MATLAB/R2015b/java/ij.jar'
% MIJ.start;
%% Open MIJI
if OpenFlag==1
%     Miji; %open imagej. requires MIJI!
    Miji;%open imagej without the gui.

end
% ('C:\fiji\Fiji.app')
% Miji(false);%open imagej without the gui.
% MIJ.start;

%% stabilize the 1st stack
MIJ.createImage(stack1); %open the first stack
MIJ.run('Image Stabilizer', ['transformation=Translation maximum_pyramid_levels=1 '...
    'template_update_coefficient=0.9 maximum_iterations=200 error_tolerance=0.0000001'...
    ' log_transformation_coefficients']); %run the image stabilizer
stableStack1 = MIJ.getCurrentImage; %get the stable stack

%% save the log file
if saveFlag==1
    MIJ.selectWindow('Import.log');
    saveStr = ['save=[',outputDir,'\',fileName,'.log]']; %the square brackets enables the path to contain white spaces.
    MIJ.run('Text...', saveStr);
end

%% apply the stabilization on the other stacks
if ~isempty(stack2) %stack2 is not empty
    MIJ.createImage(stack2);
    MIJ.run('Image Stabilizer Log Applier', ' ');
    stableStack2 = MIJ.getCurrentImage;
end
if ~isempty(stack3) %stack3 is not empty
    MIJ.createImage(stack3);
    MIJ.run('Image Stabilizer Log Applier', ' ');
    stableStack3 = MIJ.getCurrentImage;
end
if ~isempty(stack4) %stack4 is not empty
    MIJ.createImage(stack4);
    MIJ.run('Image Stabilizer Log Applier', ' ');
    stableStack4 = MIJ.getCurrentImage;
end

%% close everything
msgStr=sprintf('You can review the stabilization now.\nPress OK when you''re ready to move on');
hMsg=msgbox(msgStr,'Image stabilization');%Wait for user to view the image
waitfor(hMsg);
MIJ.closeAllWindows;
% MIJ.run('Close All');
if CloseFlag==1
    MIJ.exit;
end

end