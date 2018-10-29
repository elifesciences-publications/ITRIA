
function PlotMyTrack(stack,PTA,cellMask,pauseTime,cRange)
%This function plots the track as an overlay over the stack (in grayscale).
% It is based on testTrack from Vicente, Stocker lab, and was modified by
% Avia 11/12/2016
% stack - BF or other grayscale image. 
% PTA - tracks structure
% cell mask - binary stack of cells
% track tyrajectory is ploted in black.
% track ID is color coded.
% point of track start - green.
% point of track end - red.

tic
names=fieldnames(PTA(1));
Conv=1;
cxRng=[];
axRng=[];
P=[];
Rec=0;

if nargin<5
    cRange=[min(stack(:)), max(stack(:))];
end
% if nargin<5
%     FilterParam=[];
% end
% if nargin<6
%     cxRng=[];
% end
% if nargin<7
%     axRng=[];
% end
% if nargin<8
%     P=[];
% end
% if nargin<9
%     Rec=0;
% end

%% for testing:
% stack = final488;
% stack = BFfilt;
% PTA = final_tracks;
% cellMask = cellsMask;
% pauseTime=0.1;
% cRange=[min(stack(:)), max(stack(:))];
% names=fieldnames(PTA(1));
% Conv=1;
% cxRng=[];
% axRng=[];
% P=[];
% Rec=0;
%% 
H = figure('Position', [150, 50, size(stack,2).*2, size(stack,1).*1.8]);
% H=figure('Position',[115 136 1005 812]);
TrackNum=[];
for n=1:length(PTA)-1
    frame=PTA(n).Frame;
    figure(H)
    clf
    Im = stack(:,:,frame);
%     Im=double(imread([FileStruct.Path.Root,sprintf(sprintf([FileStruct.Path.Base,'%%0%gg'],FileStruct.Path.Length),FileStruct.Path.Num)...
%                ,filesep,sprintf(sprintf([FileStruct.File.Base,'%%0%gg',FileStruct.File.Appnd],FileStruct.File.Length),PTA(n).Frame(1))]));
%     Im=Im(:,:,1);
%     if ~isempty(FilterParam)
%         [h_obj, h_noise] = FilterGen_V(FilterParam{1}(1), FilterParam{1}(2),FilterParam{1}(3), FilterParam{2});
%         Im=imfilter(Im,h_noise-h_obj,'replicate');
%     end
    figH=imagesc(Im); 
    colormap gray;
    caxis(cRange)%set the color range
    axis image;  %prevent the image from distorting due to screen resolution 
    axis on 
    
    hold on
    if sum(strcmp(names,'TrackID'))
        NewTrack=~ismember(PTA(n).TrackID,TrackNum);
        EndTrack=~ismember(PTA(n).TrackID,PTA(n+1).TrackID);
        
%         plot(PTA(n).XFit,PTA(n).YFit,'bo','MarkerSize',10)

        DrawEllipse(PTA(n).MajAx*1.2, PTA(n).MinAx*1.2, PTA(n).Ang,PTA(n).XFit,PTA(n).YFit,'b')
%         DrawEllipse(PTA(n).MajAx*1.2, PTA(n).MinAx*1.2, PTA(n).Ang,PTA(n).XFit,PTA(n).YFit,trackColor)
%         plot(PTA(n).XFit(~NewTrack),PTA(n).YFit(~NewTrack),'k.')
%         plot(PTA(n-1).XFit(~NewTrack),PTA(n-1).YFit(~NewTrack),'k.')
%         for j=1:length(PTA(n).TrackID)
%             if ~ismember(PTA(n).TrackID(j),NewTrack)
%                 for k=1:n
%                     plot(PTA(k).XFit(j),PTA(k).YFit(j),'.-k')
%                 end
%             end          
%         end
%         Xtrack=cell2mat(arrayfun(@(X) X(1:n).XFit,PTA,'UniformOutput',0));
%         Ytrack=cell2mat(arrayfun(@(X) X(1:n).YFit,PTA,'UniformOutput',0));
%         TrackColor = PTA(1:n).TrackID(~NewTrack);
%         plot(Xtrack,Ytrack,'k');
%         trackColor = (PTA(n).TrackID./max(PTA(n).TrackID))+1;
%         trackColor = PTA(n).TrackID;
%         trackColorR = arrayfun(@(Q)1./Q(n).TrackID,PTA);
%         trackColorB = arrayfun(@(Q) (1-(1./Q(n).TrackID)),PTA);
%         trackColor=[trackColorR,trackColorR.*0,trackColorB];
%         scatter(PTA(n).XFit,PTA(n).YFit,[],trackColor);
%         colormap([gray(64);jet(64)])
%         caxis(cRange+1)%set the color range
        plot(PTA(n).XFit(NewTrack),PTA(n).YFit(NewTrack),'g.')
        plot(PTA(n).XFit(EndTrack),PTA(n).YFit(EndTrack),'r.')
        TrackNum=[TrackNum;PTA(n).TrackID(NewTrack)];
        if ~isempty(P)
            for m=1:length(P)
                f=find(and(P(m).Frame<frame,P(m).Frame>frame-25));
                plot(P(m).XFit(f),P(m).YFit(f),'y','LineWidth',2)
                if and(frame-max(P(m).Frame)>0,frame-max(P(m).Frame)<25)
                   plot(P(m).XFit(end),P(m).YFit(end),'r.','MarkerSize',4) 
                end
            end
        end
    else
        plot(PTA(n).X,PTA(n).Y,'bo','MarkerSize',10)
    end
    axis image
    axis off
    if ~isempty(axRng)
        axis(axRng)
    end

    
%     title(sprintf('Frame %g',PTA(n).Frame))
    drawnow
    pause(pauseTime);
    if Rec
        export_fig(gcf,sprintf('Frame%03g',PTA(n).Frame),'-jpg','-q95','-r200','-nocrop')
    end
end
toc
end
