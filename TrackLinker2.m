function [ParticleTracks] = TrackLinker2(ParticleTracks, trackmode_link, trackmode_fill, R_max, fitlength, T_miss_max)

% From Vicente, Stocker lab. adapted for the Itria 11/12/2016.
% Jeffrey Guasto
% 1/10/2012
% MIT
%
% "trackmode_link" = use nearest neighbors or predictive methods to link broken tracks ['position', 'velocity', or 'acceleration']
% "trackmode_fill" = use nearest neighbors or predictive methods to fill in missing data['position', 'velocity', or 'acceleration']
% "R_max" = maximum search radius to consider particle matches [0, inf]
% "fitlength" = half-width of window over which to compute velocity/acceleration [0, 1, 2, ...]
% "T_miss_max" = >1; if T_miss_max=1, this means that a particle has gone missing for 1 frame.

%% input/output
  if nargin < 2  || isequal(trackmode_link,'default');     trackmode_link = 'position'; end
  if nargin < 3  || isequal(trackmode_fill,'default');     trackmode_fill = 'position'; end
  if nargin < 4  || isequal(R_max,'default');         R_max = inf; end
  if nargin < 5  || isequal(fitlength,'default') || fitlength<2;     fitlength = 2; end
  if nargin < 6  || isequal(T_miss_max,'default');   T_miss_max = 1; end
  
%% testing
% ParticleTracks=tracks_analysis;
% R_max=DistanceLimit;
% fitlength=FitLength;
% T_miss_max=MaxMissed;

%%
  
% pre-compute & initialize
  R_max2 = R_max^2;    
  N = T_miss_max;
  
% mend tracks
  h = waitbar(0,['Stitching Trajectories Together. Missing Frames: ', num2str(1),'/',num2str(N)]);
  cc=0;  
  for ii = 1:N        
    % prelim        
      cc=cc+1;
      waitbar(0, h, ['Stitching Trajectories Together. Missing Frames: ', num2str(ii),'/',num2str(N)]);
      N_tracks = length(ParticleTracks);
      R_max2_now = R_max2*(ii+1)^2;          
    % track info
      track_info = zeros(N_tracks,9); % [1.tr_num 2.start_time 3.stop_time 4.x_start 5.y_start 6.x_end 7.y_end 8.x_est 9.y_est]
      
      for jj = 1:N_tracks
        dummy = TrackFutureEstimate([ParticleTracks(jj).X,ParticleTracks(jj).Y], trackmode_link, ii+1, fitlength+1); % estimated future position       
        track_info(jj,:) = [jj reshape(ParticleTracks(jj).Frame([1,end]),1,[]) [ParticleTracks(jj).X(1),ParticleTracks(jj).Y(1)] [ParticleTracks(jj).X(end),ParticleTracks(jj).Y(end)] dummy]; 
      end %jj      
    % loop over unique end times
      t_stop_unique = unique(track_info(:,3));
        N_t_stop_unique = length(t_stop_unique);
      ind_track_info_del = [];
      for jj = 1:N_t_stop_unique 
        waitbar(jj/N_t_stop_unique, h);
        % find tracks to match
          ind_now = find(track_info(:,3) == t_stop_unique(jj));
            N_now = length(ind_now);
          ind_next = find(track_info(:,2) == t_stop_unique(jj)+(ii+1));
            N_next = length(ind_next);
          if isempty(ind_now) || isempty(ind_next); continue; end
        % compute costs from prediction to next possible particles
          [x_est, x] = meshgrid(track_info(ind_now,8), track_info(ind_next,4));
          [y_est, y] = meshgrid(track_info(ind_now,9), track_info(ind_next,5));
          cost = (x-x_est).^2 + (y-y_est).^2;        
        % compute distance from current position to next possible position
          [x_curr, x] = meshgrid(track_info(ind_now,6), track_info(ind_next,4));
          [y_curr, y] = meshgrid(track_info(ind_now,7), track_info(ind_next,5)); 
          dist_limit = (x-x_curr).^2 + (y-y_curr).^2;
        % find matches
          [r,c] = find(cost <= R_max2 & dist_limit <= R_max2_now);
          if isempty(c); continue; end
          N_poss = length(c);
          ind_rc = sub2ind([N_next N_now], r, c);
          cost = cost(ind_rc);
          for kk=1:N_poss
            % find subsequent matches
              if isempty(c); break; end
              ind_match = find(cost == min(cost),1);   
              if isempty(ind_match); break; end
            % fill in data for gaps, mate tracks cells and empty old cells
              cc = cc+1;
              tr_num_match_now = track_info(ind_now(c(ind_match)),1);
              tr_num_match_next = track_info(ind_next(r(ind_match)),1);
%                   if tr_num_match_now==3843
%                       tr_num_match_now
%                   end
              ParticleTracks(tr_num_match_next) = TrackGapFill(ParticleTracks(tr_num_match_now), ParticleTracks(tr_num_match_next), ...
                                                               trackmode_fill, fitlength+1, track_info(ind_now(c(ind_match)),8:9));
%               ParticleTracks(tr_num_match_now).Frame = ones(size(ParticleTracks(tr_num_match_now).Frame))*-1;                   
%               ParticleTracks(tr_num_match_now)=[];
            % update track info
             track_info(ind_next(r(ind_match)),[2 4 5]) = track_info(ind_now(c(ind_match)),[2 4 5]);  %Update beginning stats
             ind_track_info_del = [ind_track_info_del ; ind_now(c(ind_match))];
            % delete particles from r, c, ind_rc, cost
              ind_del = find(r == r(ind_match) | c == c(ind_match));
              r(ind_del) = []; c(ind_del) = []; ind_rc(ind_del) = []; cost(ind_del) = [];            
          end % kk                  
      end  % jj        
      track_info(ind_track_info_del,:) = [];
      ParticleTracks(ind_track_info_del)=[];
      TL=arrayfun(@(Q) length(Q.X),ParticleTracks);
      [~,I]=sort(TL,1,'descend');
      ParticleTracks = ParticleTracks(I);
  end % ii
  close(h);

  
end

%%%%%-----------------------------------------------------------------%%%%%
function output = TrackFutureEstimate(xy, trackmode, N_future, fitlength)
  N_past = length(xy(:,1));
     
  if nargin<2; trackmode = 'acceleration'; end
  if nargin<3; N_future=1; end
  if nargin<4; fitlength=3; end
  
  if N_past<3 || isequal(trackmode,'position') || isequal(trackmode,'velocity')
    myfitorder = 1;   
  elseif N_past >= 3 && isequal(trackmode,'acceleration')      
    myfitorder = 2;
  end
  
  if N_past == 1 || isequal(trackmode,'position')
    output = xy(end,:);
  elseif N_past == 2 && ~isequal(trackmode,'position')
    output = xy(end,:) + N_future*(xy(end,:)-xy(end-1,:));
  elseif (N_past == 3 && isequal(trackmode,'acceleration')) || (fitlength==3 && N_past > 2)
    output = xy(end,:) + N_future*0.5*(3*xy(end,:)-4*xy(end-1,:)+xy(end-2,:)) - ...
                         N_future^2*0.5*(-xy(end,:)+2*xy(end-1,:)-xy(end-2,:));
  elseif N_past > myfitorder+1 && fitlength > myfitorder+1 
    dummy = min(N_past,fitlength);
    N_vec = length(xy(1,:));
    output = zeros(1,N_vec);
    for ii=1:N_vec
      coeffs = polyfit([(1-dummy):0]', xy(end-dummy+1:end,ii), myfitorder);
      output(ii) = polyval(coeffs, N_future);
    end %ii
  end
end


%%%%%-----------------------------------------------------------------%%%%%
function outtemp = TrackGapFill(b1, b2, trackmode, fitlength, b_pred)
%modified by Avia 4.1.2017
%output = TrackGapFill(b1, b2, trackmode, fitlength, b_pred)

  if nargin<3; trackmode = 'acceleration'; end
  if nargin<4; fitlength=3; end
  if nargin<5; b_pred = b1(end,1:2); end

  N1 = size(b1.X,1);
    ind_b1 = N1-min(N1,fitlength)+1 : N1;
  N2 = size(b2.X,1);
    ind_b2 = 1 : min(N2,fitlength);
  N_avail = length(ind_b1)+length(ind_b2);       
  t_missing = [(b1.Frame(end)+1):(b2.Frame(1)-1)]';
    N_missing = length(t_missing);
  
%   b = zeros(N_missing,7);
%     b(:,7) = t_missing;
%     b(:,3:6) = repmat(mean([b1(:,3:6) ; b2(:,3:6)],1),N_missing,1);
  if N_avail<3 || isequal(trackmode,'position') || isequal(trackmode,'velocity')
    myfitorder = 1;   
  elseif N_avail >= 3 && isequal(trackmode,'acceleration')      
    myfitorder = 2;
  end
  
  nms=fieldnames(b1);
  outtemp=b1;
  outtemp.Frame=(b1.Frame(1):b2.Frame(end))';
%   outtemp=setfield(outtemp,'Frame',[b1.Frame(1):b2.Frame(end)]');
  nms(strcmp(nms,'Frame'))=[];
    coeffs = polyfit([b1.Frame(ind_b1) ; b2.Frame(ind_b2)], [b1.X(ind_b1) ; b2.X(ind_b2)], myfitorder);
    Xnew = polyval(coeffs, t_missing);
%     b_hr = polyval(coeffs, linspace(b1(ind_b1(1),7),b2(ind_b2(end),7),1000)');
  outtemp.X=[b1.X;Xnew;b2.X];
%   outtemp=setfield(outtemp,'X',[b1.X;Xnew;b2.X]);

  nms(strcmp(nms,'X'))=[];
    coeffs = polyfit([b1.Frame(ind_b1) ; b2.Frame(ind_b2)], [b1.Y(ind_b1) ; b2.Y(ind_b2)], myfitorder);
    Ynew = polyval(coeffs, t_missing); 
  outtemp.Y=[b1.Y;Ynew;b2.Y];

%   outtemp=setfield(outtemp,'Y',[b1.Y;Ynew;b2.Y]);
%     b_hr = [b_hr polyval(coeffs, linspace(b1(ind_b1(1),7),b2(ind_b2(end),7),1000)')];
  nms(strcmp(nms,'Y'))=[];
  
  %fill NaN for the gap of PixIdx 
  emptyPixIdx=NaN(size(Xnew));
  emptyPixIdx=num2cell(emptyPixIdx);
  outtemp.PixelIdxList=[b1.PixelIdxList;emptyPixIdx;b2.PixelIdxList];    
%   outtemp=setfield(outtemp,'PixelIdxList',[b1.PixelIdxList;emptyPixIdx;b2.PixelIdxList]);    
  nms(strcmp(nms,'PixelIdxList'))=[]; 
  
  %set the track ID
  Track_ID=ones(size(outtemp.Frame)); %create an array for the track ID
  TrackID_now=min(b1.TrackID(1),b2.TrackID(1));%find the number of the track id
  Track_ID=Track_ID.*TrackID_now; %fill the track id
%   outtemp=setfield(outtemp,'TrackID',Track_ID);
  outtemp.TrackID=Track_ID;

  nms(strcmp(nms,'TrackID'))=[]; 
%   missingTrackID=;
%   TrackID
  
  if find(strcmp(nms,'Fit'))
      nms(strcmp(nms,'Fit'))=[];
  end
  nms(strcmp(nms,'FPS'))=[];
  nms(strcmp(nms,'Conv'))=[];
  
  missing_values_array=NaN(size(Xnew));

  for n=1:length(nms)
      if ismember(nms(n),{'XFit','YFit','VelX','VelY','AccX','AccY','MajAx','MinAx','Ang'}) %use interpolation for these features
          b1f=b1.(nms{n});
          b2f=b2.(nms{n});
          outtemp.(nms{n})=interp1([b1.Frame;b2.Frame],[b1f;b2f],[b1.Frame(1):b2.Frame(end)])';
%           b1f=getfield(b1,nms{n});            
%           b2f=getfield(b2,nms{n});
%           outtemp=setfield(outtemp,nms{n},interp1([b1.Frame;b2.Frame],[b1f;b2f],[b1.Frame(1):b2.Frame(end)])');
      else %for other fields fill NaN for the missing frame     
        outtemp.(nms{n})=[b1.(nms{n});missing_values_array;b2.(nms{n})];
      end
%       b1f=getfield(b1,nms{n});
%       b2f=getfield(b2,nms{n});
%       outtemp=setfield(outtemp,nms{n},interp1([b1.Frame;b2.Frame],[b1f;b2f],[b1.Frame(1):b2.Frame(end)])');
%{
      %       if strcmp(nms(n),'PixelIdxList')%different approach for the pixelIdxList because it's a cell array
%         nPixIdx=min(length(b1f{1,1}),length(b2f{1,1}));
%         b1f_2=b1f{1:nPixIdx};
%         b2f_2=b2f{1:nPixIdx};
%         try
% %             b1f_2=mean(cell2mat(b1f));
% %             b2f_2=mean(cell2mat(b2f));
%             b_test=interp1([b1.Frame;b2.Frame],[b1f_2;b2f_2],[b1.Frame(1):b2.Frame(end)])';
% %           outtemp=setfield(outtemp,nms{n},interp1([b1.Frame;b2.Frame],[0;0],[b1.Frame(1):b2.Frame(end)])');
%             outtemp=setfield(outtemp,nms{n},b_test);
% %             [outtemp.PixelIdxList]=deal([pixelIdxTracks{:,1},); %add the pixel index list at the end
% %             outtemp=setfield(outtemp,nms{n},interp1([b1.Frame;b2.Frame],[{b1f};{b2f}],[b1.Frame(1):b2.Frame(end)])');
%         catch
%             warning('a');
%             continue
%         end  
% 
%       else          
%       end
%}
  end

  %%
%   disp('x');
%   output=outtemp;
  
%   figure(1); 
%     plot(b_hr(:,1),b_hr(:,2),'-c',output(:,1),output(:,2),'-gx',b1(:,1),b1(:,2),'-b.',b2(:,1),b2(:,2),'-r.',b_pred(1),b_pred(2),'bs',b1(ind_b1,1),b1(ind_b1,2),'bo',b2(ind_b2,1),b2(ind_b2,2),'ro');
%     daspect([1 1 1]);
%     pause;
  
end


