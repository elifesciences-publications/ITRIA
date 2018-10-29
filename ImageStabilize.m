
function [stableStack1,stableStack2,stableStack3,stableStack4] = ImageStabilize(outputDir,stack1,stack2,stack3,stack4)

%% for testing
% stack1=rawChl;
% stack2=raw488;
% stack3=raw405;
% stack4=rawBF;
% outputDir = output_folder;
%% initialization
if size(stack1,3)<=1
    warning('this is not a stack');
end

%% setup - only for installation.
% javaaddpath 'C:\Program Files\MATLAB\R2015b\java\mij.jar'
% javaaddpath 'C:\Program Files\MATLAB\R2015b\java\ij.jar'
% MIJ.start;
%%
% Miji; %open imagej. requires MIJI!
% Miji(false);%open imagej without the gui.
MIJ.start;
MIJ.createImage(stack1); %open the first stack
MIJ.run('Image Stabilizer', ['transformation=Translation maximum_pyramid_levels=1 '...
    'template_update_coefficient=0.9 maximum_iterations=200 error_tolerance=0.0000001'...
    ' log_transformation_coefficients']); %run the image stabilizer
stableStack1 = MIJ.getCurrentImage; %get the stable stack

%% save the log file
MIJ.selectWindow('Import.log');
saveStr = ['save=',outputDir,'\stabilizer_log.txt'];
MIJ.run('Text...', saveStr);
% reg_log=MIJ.getLog();
% MIJ.saveAs('Text', );
% fprintf(reg_log);
%% apply the stabilization on the other stacks
if nargin>2 %at least 2 stacks
    MIJ.createImage(stack2);
    MIJ.run('Image Stabilizer Log Applier', ' ');
    stableStack2 = MIJ.getCurrentImage;
end
if nargin>3 %at least 3 stacks
    MIJ.createImage(stack3);
    MIJ.run('Image Stabilizer Log Applier', ' ');
    stableStack3 = MIJ.getCurrentImage;
end
if nargin>4 %at least 4 stacks
    MIJ.createImage(stack4);
    MIJ.run('Image Stabilizer Log Applier', ' ');
    stableStack4 = MIJ.getCurrentImage;
end
% 	selectWindow("rawImg #3");
% 	rename("rawChl");
% 	run("Red");
% 	//resetMinAndMax();
% 	setMinAndMax(0, 16383);//for 14-bit image
% 	if(timePoints>1){
% 		run("Image Stabilizer", "transformation=Translation maximum_pyramid_levels=1 "+
% 		"template_update_coefficient=0.9 maximum_iterations=200 error_tolerance=0.0000001"+
% 		" log_transformation_coefficients");//stabilize Chl channel
% 	}	
% 
% 	selectWindow("rawImg #4");
% 	rename("rawBF");
% 	run("Grays");
% 	//resetMinAndMax();
% 	setMinAndMax(0, 16383);//for 14-bit image
% 	if(timePoints>1){
% 		run("Image Stabilizer Log Applier", " "); //apply stabilization
% 	}

%% close everything
MIJ.closeAllWindows;
% MIJ.run('Close All');
MIJ.exit;
end