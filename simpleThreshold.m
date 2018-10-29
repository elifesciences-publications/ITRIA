%% simpleThreshold

function [thrStack,thrLow,thrUp]=simpleThreshold(stack, thrLow, thrUp, stackName,t)

if nargin<5
    t=1;
end

%% threshold frame t and validate

I = stack(:,:,t);
thrI = I > thrLow & I < thrUp; 
thrOverlay = imoverlay(I, thrI, [1 0 0]); %mask in red
% figH = imshow(thrOverlay, 'InitialMagnification', 150);
titleStr = sprintf('stack "%s" with threshold overlay,  timepoint %d',stackName,t);
imshow(thrOverlay, 'InitialMagnification', 150);
title(titleStr);
axis image; % Make sure image is not artificially stretched because of screen's aspect ratio.

%% validate the threshold with the user
qstring = 'Are you happy with that threshold?';
qTitle = sprintf('"%s" Threshold',stackName);
thrAnswer = questdlg(qstring,qTitle);

while strcmp(thrAnswer,'No') 
    %get new threshold values
    prompt = {'Enter lower threshold:','Enter upper threshold:'};
    dlg_title = 'Threshold input';
    num_lines = 1;
    defaultans = {num2str(thrLow),num2str(thrUp)};
    answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
    thrLow = str2double(answer{1});
    thrUp = str2double(answer{2});

    %calculate the new thrshold and display it
    thrI = I > thrLow & I < thrUp; 
    thrOverlay = imoverlay(I, thrI, [1 0 0]); %mask in red
    figH = imshow(thrOverlay, 'InitialMagnification', 150);
    title(titleStr);
    axis image;

    %ask again the user if the threshold is satisfying
    qstring = 'Are you happy with that threshold?';
    thrAnswer = questdlg(qstring,'Manual Threshold');
end

%% calculate the thresholded stack

thrStack = stack > thrLow & stack < thrUp;
sprintf('"%s" lower threshold:  %g',stackName,thrLow);
sprintf('"%s" upper threshold:  %g',stackName,thrUp);

end