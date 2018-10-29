%% Cells filter function


function [filt_cells,minValue,maxValue] = cellsFilter(cellsProps,filtFeature,minValue,maxValue,stack,t)

%% for testing
%{
cellsProps = cellsProps;
filtFeature = 'A'; %area
minValue = 5; 
maxValue = 50;
stack = final488;
t=10;
%}

%% get image of frame t in stack:
% I=stack(:,:,t);

%% overlay the filtered property
% ParticlePropOverlay2(stack,P,t,PropField);
ParticlePropOverlay2(stack,cellsProps,t,filtFeature);

%% get trimming values from the user
prompt = {'Enter upper limit ("Inf" for no limit):','Enter lower limit (0 for no limit):'};
dlg_title = 'Feature Trimming Boundaries';
num_lines = 1;
defaultans = {num2str(maxValue),num2str(minValue)};
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
maxValue = str2double(answer{1});
minValue = str2double(answer{2});

%% show the trimmed image 
% ParticleTrimOverlay2(stack,P,t,PropField,UpperBound,LowerBound);
ParticleTrimOverlay2(stack,cellsProps,t,filtFeature,maxValue,minValue);
%%%% write the particle trim overlay 2 function!!

% ask the user whether to continue or repeat
qstring = 'Are you happy with that trimming?';
trimAnswer = questdlg(qstring,'Feature Trimming');
close();

%% while the user isn't content - keep on trimming this feature
while strcmp(trimAnswer,'No') 
    %get new trimming values
    prompt = {'Enter upper limit ("Inf" for no limit):','Enter lower limit (0 for no limit):'};
    dlg_title = 'Feature Trimming Boundaries';
    num_lines = 1;
    defaultans = {answer{1},answer{2}};
    answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
    maxValue = str2double(answer{1});
    minValue = str2double(answer{2});

    %display the new trimming
    ParticleTrimOverlay2(stack,cellsProps,t,filtFeature,maxValue,minValue);

    %ask again the user if the threshold is satisfying
    qstring = 'Are you happy with that trimming?';
    trimAnswer = questdlg(qstring,'Feature Trimming');
    close();
end

close();

%% when the user is happy trim the cells
% PTrim=ParticleTrim2(P,field,UpperL,LowerL)
filt_cells=ParticleTrim2(cellsProps,filtFeature,maxValue,minValue);

end