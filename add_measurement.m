
function [tracks_struct]=add_measurement(tracks_struct,fieldName,intStack,maskStack,minOverlap,functionName)
%This function loops through the cells in the tracking structure and gets
%their pixel index (according to the cell mask that was used for
%segmentation). Then, it looks for overlap with the mask at each timepoint. 
%Then, it measures the mean intensity in intStack in the overlapping pixels. 
%minOverlap - minimum number of overlapping pixels in order to get a value.
%functionName - which function to use. options: mean, median, max, min
%% initiation
if nargin<5 || isempty(minOverlap)
    minOverlap=2; 
end
if nargin<6 || isempty(functionName)
    functionName='mean'; 
end
%% test
% tracks_struct=tracks_analysis;
% fieldName='int488';
% intStack=final488;
% maskStack=thr_expression;
% minOverlap=2; 

%% 
overlap_fieldName=[fieldName,'_overlap'];
cellsNum=length(tracks_struct);
for i=1:cellsNum
    frames=tracks_struct(i).Frame;
    for j=1:length(frames)
        cellIdx=tracks_struct(i).PixelIdxList{j,1}; %get the pixel idx list of cell i at frame j        
        if isnan(cellIdx) %If there is no cellIndx for that frame - because this cell was linked (missing frame linking)
            tracks_struct(i).(overlap_fieldName)(j,1)=NaN;
            tracks_struct(i).(fieldName)(j,1)=NaN; 
            continue %go to the next loop
        end 
        frameIdx=frames(j,1); %get the frame number
        Im_mask=maskStack(:,:,frameIdx); %get the mask image of that frame
        tracks_struct(i).(overlap_fieldName)(j,1)=sum(Im_mask(cellIdx));
        if tracks_struct(i).(overlap_fieldName)(j,1)<minOverlap %not enough overlap
            tracks_struct(i).(fieldName)(j,1)=-inf; %assign -inf for not enough overlap (to differentiate from cells that weren't detected)
        else %there's enough overlap
            Im_int=intStack(:,:,frameIdx);
            Im_cell=zeros(size(Im_int));
            Im_cell(cellIdx)=1;
            Im_coLocalization=Im_mask&Im_cell;            
            switch functionName
                case 'mean'
                    tracks_struct(i).(fieldName)(j,1)=nanmean(Im_int(Im_coLocalization));%get the mean value within the cell index, avoid NaN values
                case 'median'
                    tracks_struct(i).(fieldName)(j,1)=nanmedian(Im_int(Im_coLocalization));%get the median value within the cell index, avoid NaN values
                case 'max'
                    tracks_struct(i).(fieldName)(j,1)=nanmax(Im_int(Im_coLocalization));%get the median value within the cell index, avoid NaN values
                case 'min'
                    tracks_struct(i).(fieldName)(j,1)=nanmin(Im_int(Im_coLocalization));%get the median value within the cell index, avoid NaN values
                otherwise
                    error('functionName ''%s'' wasn''t recognized.\nfunctionName options are: ''mean'', ''median'', ''max'', ''min''.\n',functionName);
            end
        end
        
    end
        
end

end
