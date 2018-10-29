function [cellsMask,segStack,vars]=stackSegmentation(maskStack,IntStack,segType,vars,distType)
%This function loops over the stack and segment it frame by frame according
%to the segmentation choice of the user.
%There are 3 options: 'mySegmentation', 'Fiji' or 'Mask only'.
%All use a mask stack, which depends on maskType.
%options for mask type: 'expression', 'co-localization', 'Chl', '405'. 
%Only 'mySegmentation' uses also an intensity stack.
%segStack is an output only in 'mySegmentation' mode.
%
%'mySegmentation': uses an intensity stack and a mask stack in order to 
%find local maxima and also to find the edges, in combinaton with distance 
%matrix from local maxima.
%'Fiji':Fiji requires MIJI! It uses erode and watershed functions from
%imageJ (FIJI).
%'Mask only': uses only the mask and actuaaly does nothing.

%% segment the cells
switch segType 
    case 'mySegmentation' 
        %% use mySegmentation function
        if nargin<5
            distType='intensity'; %choose either 'intensity', 'distance' or 'combined'. 
        end
        % If you want to use only co-localization without watershed - skip this and
        % the following sections!
        % [I_segmented]=mySegmentation(stack, colocalizationMat, t, filtType, sigma)
        segStack = zeros(size(maskStack));%create empty stack for the segmented image
%         sigma = vars.sigma; %for gaussian filter within the segmentation
        % sigma=0;
%         filtType = vars.filtType; %'gaussian', 'median', 'no filt'
        % filtType = 'median';
        % filtType = 'no filt';
        % maskStack = colocalizationMat; %cell mask to be used as the boundries of the cells.
%         maskStack=colocalizationMat; %cell mask to be used as the boundries of the cells.
%         vars.connec=4;
        nFrames=size(maskStack,3);

        %loop over the stack and segment frame by frame
        for t = 1:nFrames
            if ismember(t,[1,round(nFrames/2)]) %let the user modify sigma in the first frame and again in the middle
                %run segmentation on the 1st frame
                [segStack(:,:,t)]=mySegmentation(IntStack, maskStack, t,vars.filtType, vars.sigma,vars.connec,distType);

                %view the first frame (pseudocolor)
                I_segColor = label2rgb(segStack(:,:,t),'jet',[.5 .5 .5]);
                figH = figure;
                imshow(I_segColor,'InitialMagnification',150)
                title(sprintf('Watershed transform, frame %g, sigma %g',t, vars.sigma));

                %ask the user about segmentation
                qstring = 'Are you happy with that segmentation?';
                segAnswer = questdlg(qstring,'Watershed segmentation');
                waitfor(segAnswer);

                while strcmp(segAnswer,'No')
                    %get new sigma value
                    prompt = {'Enter new sigma:','Enter new connectivity (4 or 8)',...
                        'Enter filter type (''gaussian'', ''median'',''no filt''):'};
                    dlg_title = 'Watershed transform input';
                    num_lines = 1;
                    defaultans = {num2str(vars.sigma), num2str(vars.connec), vars.filtType};
                    answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
                    vars.sigma = str2double(answer{1});
                    vars.connec = str2double(answer{2});
                    vars.filtType = answer{3};

                    %run segmentation with new sigma 
                    [segStack(:,:,t)]=mySegmentation(IntStack, maskStack, t,vars.filtType, vars.sigma,vars.connec,distType);

                    %view the new segmentation
                    I_segColor = label2rgb(segStack(:,:,t),'jet',[.5 .5 .5]);
                    imshow(I_segColor,'InitialMagnification',150)
                    title(sprintf('Watershed transform of roGFP488, frame %g, sigma %g',t, vars.sigma));

                    %ask the user again
                    qstring = 'Are you happy with that segmentation?';
                    segAnswer = questdlg(qstring,'Watershed segmentation');
                end %while        
                close(figH);

            else %t>1
                %run segmentation on the rest of the stack
                [segStack(:,:,t)]=mySegmentation(IntStack, maskStack, t,vars.filtType, vars.sigma,vars.connec,distType);        
            end % if t==1   
        end %t loop
        
        cellsMask = segStack;
        cellsMask(cellsMask<=1)=0;
        cellsMask(cellsMask>1)=1;
   
    case 'Fiji' 
        %% FIJI segmentation.
        %requires FIJI (imageJ) and MIJI (see the imageStabilizer function for
        %details).
        %This function uses the maskStack to create the cell mask. 
        %It performs 'erode' depending on vars.erode_num, and then uses watershed. 
        OpenFlag=1; %MIJI open choice: 0=don't open, 1=open.
        CloseFlag=1; %MIJI close choice: 0=don't close, 1=close.
        ErodeNum=vars.erode_num;
%         ErodeNum=1;
%         maskStack=thr_expression;
        cellsMask = FijiWatershed(maskStack,ErodeNum, OpenFlag,CloseFlag);
        % cd(output_folder);
        segStack=[];
             
    case 'Mask only'
        %%
        cellsMask = maskStack;
        segStack=[];
        
    otherwise
        warning('segmentation type was not recognized');
        cellsMask = maskStack;
        segStack=[];
end

end