function [final_Stack,SNR_stack,bgROI,bgMean]=subtractBackground(rawStack,t,method,bgROI,bgImg)
%This function saubtracts background from a raw stack and outputs the stack 
%after background subtraction. It can use two methods:
%1.'roi' - user defined background ROI in which the mean value is calculated
%and then subtracted from the whole stack. This is the default.
%2.'bgImage' - background subtraction is based on a background image that
%was taken before or calculated before.
%final_Stack = raw stack after background subtraction.
%SNR_stack = signal-to-noise ratio stack, raw stack divided by the background.

%% initiation
if nargin<3 || isempty(bgImg)
    method='roi';
end
% if strcmp(method,'bgImage') && (narging<6 || isempty(method_option)) 
%     method_option='subtract';
if strcmp(method,'roi') && nargin<4
    bgROI=[];
end
if nargin<2 || isempty(t) || t>size(rawStack,3)
    t=1;
end
stackName=inputname(1);

%% switch between methods + method options
switch method
    case 'roi'  %subtract background based on user defined ROI 
        %% Get the roi from the user
        Img=rawStack(:,:,t);
        if isempty(bgROI) %no input of bg roi    
            msgTitleStr = sprintf('background ROI - stack "%s"',stackName);
            i=0;

            while i<4
                i=i+1;
                h=msgbox('Please select a background ROI',msgTitleStr, 'modal');
                waitfor(h);
                bgROI = roipoly(Img);

                if max(bgROI(:))>0
                    break
                elseif i==4
                    bgROI=0;
                    warning(['clealrly you do not want to choose a background ROI.',...
                        '\nBackground value was set by the min of the stack.']);
                end
            end
        end

        %% get the mean background value
        if max(bgROI(:)) == 0
            bgMean = min(Img(:)); %global minimum of the image
        else
            bgMean = mean(Img(bgROI)); %mean of the background roi
        end
        fprintf('background value:  %d\n', bgMean);

        %% subtract the background and show the results
        fprintf('max initial:  %d\n',max(Img(:)));
        final_Stack = rawStack-bgMean; %bgStack is the same stack after bg substraction
        SNR_stack = rawStack./bgMean;
        final_Stack(final_Stack<0)=0; %turn negative values to zero
        % bgStack = bgStack.*(cRange(2)/(cRange(2)-bgMean)); %normalizing data to the new max
        Img = final_Stack(:,:,t);
        % figH = figure();
        % figH = imshow(img,'InitialMagnification', 150); 
        color_range=[min(Img(:)),max(Img(:))];
        scrsz = get(groot,'ScreenSize'); %get the screen size for the plot
        hFig=figure('Position',[scrsz(3)*0.02 scrsz(4)*0.05 scrsz(3)*0.95 scrsz(4)*0.86]);
        imshow(Img,color_range,'InitialMagnification', 150); %view with colour range
        titleStr=sprintf('stack "%s" after background subtraction',stackName);
        title(titleStr);
        axis image; % Make sure image is not artificially stretched because of screen's aspect ratio.
        h=msgbox('Press OK when you''re ready to move on','Background Subtraction');
        waitfor(h);
        SNR_Img=SNR_stack(:,:,t);
        color_range=[min(SNR_Img(:)),max(SNR_Img(:))];
        imshow(SNR_Img,color_range,'InitialMagnification', 150); %view with colour range
        titleStr=sprintf('SNR of stack "%s"',stackName);
        title(titleStr);
        axis image; % Make sure image is not artificially stretched because of screen's aspect ratio.  
        colormap jet
        colorbar;
        h=msgbox('Press OK when you''re ready to move on','SNR');
        waitfor(h);
        close(hFig);        
        
        fprintf('max end:  %d\n--- bg subtraction channel %s end ---\n',max(Img(:)),stackName);
        close();
        
    case 'bgImage' %use a background image
        bgROI=[];
        bgMean=mean(bgImg(:));
        final_Stack=zeros(size(rawStack));
        SNR_stack=zeros(size(rawStack));
        nFrames=size(rawStack,3);       
        %% Subtract background and calculate SNR stack frame by frame
        for i=1:nFrames
            final_Stack(:,:,i)=rawStack(:,:,i)-bgImg;
            SNR_stack(:,:,i)=rawStack(:,:,i)./bgImg;
        end
        
        %% view the final result - final_stack
        scrsz = get(groot,'ScreenSize'); %get the screen size for the plot
        hFig=figure('Position',[scrsz(3)*0.02 scrsz(4)*0.05 scrsz(3)*0.95 scrsz(4)*0.86]);
        h1=subplot(1,3,1);
        p = get(h1, 'pos');
        p(1) = p(1)-0.12;
        p(3) = p(3) + 0.1;
        p(4) = p(4) + 0.1;
        set(h1, 'pos', p);
        imshow(rawStack(:,:,t));
        titleStr=sprintf('raw "%s", frame %g',stackName,t);
        title(titleStr);
        h2=subplot(1,3,2);
        p = get(h2, 'pos');
        p(1) = p(1)-0.07;
        p(3) = p(3) + 0.1;
        p(4) = p(4) + 0.1;
        set(h2, 'pos', p);
        imshow(final_Stack(:,:,t));
        titleStr=sprintf('"%s" after background subtraction, frame %g',stackName,t);
        title(titleStr);        
        h3=subplot(1,3,3);
        p = get(h3, 'pos');
        p(1) = p(1)-0.02;
        p(3) = p(3) + 0.1;
        p(4) = p(4) + 0.1;
        set(h3, 'pos', p);
        imshow(bgImg,[min(bgImg(:)),max(bgImg(:))]);
        title('Background Image (normalized range)');
        h=msgbox('Press OK when you''re ready to move on','Background Subtraction');
        waitfor(h);
%         close(hFig);
        
        %show histogram
%         hFig=figure('Position',[scrsz(3)*0.02 scrsz(4)*0.05 scrsz(3)*0.95 scrsz(4)*0.86]);
        subplot(1,3,1);
        imhist(rawStack(:,:,t)./max(max(rawStack(:,:,t))));
        titleStr=sprintf('raw "%s", frame %g',stackName,t);
        title(titleStr);
        subplot(1,3,2);
        imhist(final_Stack(:,:,t)./max(max(final_Stack(:,:,t))));
        titleStr=sprintf('"%s" after background subtraction, frame %g',stackName,t);
        title(titleStr);        
        subplot(1,3,3);
        imhist(bgImg./max(max(rawStack(:,:,t))));
        title('Background Image (normalized to raw image max)');
        h=msgbox('Press OK when you''re ready to move on','Background Subtraction');
        waitfor(h);
%         close(hFig);
        
        %% view the final result - SNR_stack
%         scrsz = get(groot,'ScreenSize'); %get the screen size for the plot
%         hFig=figure('Position',[scrsz(3)*0.02 scrsz(4)*0.05 scrsz(3)*0.95 scrsz(4)*0.86]);
        h1=subplot(1,2,1);
        p = get(h1, 'pos');
        p(1) = p(1)-0.12;
        p(3) = p(3) + 0.1;
        p(4) = p(4) + 0.1;
        set(h1, 'pos', p);
        imshow(rawStack(:,:,t));
        colorbar
        titleStr=sprintf('raw "%s", frame %g',stackName,t);
        title(titleStr);
        h2=subplot(1,2,2);
        p = get(h2, 'pos');
        p(1) = p(1)-0.07;
        p(3) = p(3) + 0.1;
        p(4) = p(4) + 0.1;
        set(h2, 'pos', p);
        colorRange=[min(SNR_stack(:)),max(SNR_stack(:))];
        imshow(SNR_stack(:,:,t),colorRange);
        colormap(h2,jet);
        colorbar
        titleStr=sprintf('"%s" SNR, frame %g',stackName,t);
        title(titleStr);        
%         h3=subplot(1,3,3);
%         p = get(h3, 'pos');
%         p(1) = p(1)-0.02;
%         p(3) = p(3) + 0.1;
%         p(4) = p(4) + 0.1;
%         set(h3, 'pos', p);
%         imshow(bgImg,[min(bgImg(:)),max(bgImg(:))]);
%         colorbar
%         title('Background Image (normalized range)');
        h=msgbox('Press OK when you''re ready to move on','Background Subtraction');
        waitfor(h);
        close(hFig);
        
        %show histogram
%         hFig=figure('Position',[scrsz(3)*0.02 scrsz(4)*0.05 scrsz(3)*0.95 scrsz(4)*0.86]);
%         subplot(1,3,1);
%         imhist(rawStack(:,:,t)./max(max(rawStack(:,:,t))));
%         titleStr=sprintf('raw "%s", frame %g',stackName,t);
%         title(titleStr);
%         subplot(1,3,2);
%         imhist(SNR_stack(:,:,t)./max(max(SNR_stack(:,:,t))));
%         titleStr=sprintf('"%s" SNR, frame %g',stackName,t);
%         title(titleStr);        
%         subplot(1,3,3);
%         imhist(bgImg./max(max(rawStack(:,:,t))));
%         title('Background Image (normalized to raw image max)');
%         h=msgbox('Press OK when you''re ready to move on','Background Subtraction');
%         waitfor(h);
%         close(hFig);
        
    otherwise
        warning('The subtraction method ("roi" or "bgImage") wasn''t specified correctly');
        
end %switch method
    
end %function