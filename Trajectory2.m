function [OutputStruct] = Trajectory2(ParticleTracks,fitlength,fps)

% Jeffrey Guasto
% 5/9/2011
% MIT
% modified 9/12/12
% from Vicente, Stocker lab. Adapted for the Itria 11/12/2016

if nargin<3
    fps=1;
end

OutputStruct=ParticleTracks;
for n=1:length(ParticleTracks)  
  xy = [ParticleTracks(n).X,ParticleTracks(n).Y];
  clear output
  if fitlength == 0        % use first order differences 
    output(:,1:2) = xy;
    try
        dummy = circshift(xy,[-1,0])-xy;                             % 1stO FD, forward first derivative
        output(:,3:4) = [dummy(1:end-1,:)    ; ...               % 1stO FD, forward first derivative
                           xy(end,:)-xy(end-1,:)];                 % 1stO FD, backward first derivative
    catch err
        output(:,3:4)=xy*NaN;
    end
                     
    try
        dummy = circshift(xy,[-1,0])-2*xy+circshift(xy,[1,0]);           % 2ndO FD, central second derivative
        output(:,5:6) = [xy(1,:)-2*xy(2,:)+xy(3,:) ; ...         % 1stO FD, forward second derivative
                           dummy(2:end-1,:)          ; ...         % 2ndO FD, central second derivative
                           xy(end,:)-2*xy(end-1,:)+xy(end-2,:)];   % 1stO FD, backward second derivative
    catch err
        output(:,5:6)=xy*NaN;
    end
    
  elseif fitlength == 1    % use second order differences
    output(:,1:2) = xy;
    try
        dummy = 0.5*circshift(xy,[-1,0])-0.5*circshift(xy,[+1,0]);                       % 2ndO FD, central first derivative
          output(:,3:4) = [-1.5*xy(1,:)+2*xy(2,:)-0.5*xy(3,:) ; ...                % 2ndO FD, forward first derivative
                           dummy(2:end-1,:)    ; ...                               % 2ndO FD, central first derivative
                           1.5*xy(end,:)-2*xy(end-1,:)+0.5*xy(end-2,:) ];          % 2ndO FD, backward first derivative
    catch err
        output(:,3:4)=xy*NaN;
    end

    try
        dummy = circshift(xy,[-1,0])-2*xy+circshift(xy,[1,0]);                           % 2ndO FD, central second derivative
          output(:,5:6) = [2*xy(1,:)-5*xy(2,:)+4*xy(3,:)-xy(4,:); ...              % 2ndO FD, forward second derivative
                           dummy(2:end-1,:)          ; ...                         % 2ndO FD, central second derivative
                           2*xy(end,:)-5*xy(end-1,:)+4*xy(end-2,:)-xy(end-3,:)];   % 2ndO FD, backward second derivative    
    catch err
        output(:,5:6)=xy*NaN;
    end
  else                     % use rolling quadratic polynomial fitting     
    t = -[-fitlength:fitlength]';
    q_inv = pinv([ones(length(t),1), t, t.^2])';
      b_x = [conv(xy(:,1), q_inv(:,1), 'same'), ...
             conv(xy(:,1), q_inv(:,2), 'same'), ...
             conv(xy(:,1), q_inv(:,3), 'same')];
      b_y = [conv(xy(:,2), q_inv(:,1), 'same'), ...
             conv(xy(:,2), q_inv(:,2), 'same'), ...
             conv(xy(:,2), q_inv(:,3), 'same')];           
    output = [b_x(:,1) b_y(:,1) b_x(:,2) b_y(:,2) 2*b_x(:,3) 2*b_y(:,3)];
    % treat boundaries
      t = flipud(t);      
      % x, y: beginning
        t_mat = [ones(fitlength,1), t(1:fitlength), t(1:fitlength).^2];
        output(1:fitlength,1) = t_mat*b_x(fitlength+1,:)';
          output(1:fitlength,2) = t_mat*b_y(fitlength+1,:)';
      % x, y: ending
        t_mat = [ones(fitlength,1), t(fitlength+2:end), t(fitlength+2:end).^2];
        output(end-fitlength+1:end,1)   = t_mat*b_x(end-fitlength,:)';
          output(end-fitlength+1:end,2) = t_mat*b_y(end-fitlength,:)';
      % u, v: beginning
        t_mat = [ones(fitlength,1), 2*t(1:fitlength)];
        output(1:fitlength,3)   = t_mat*b_x(fitlength+1,2:3)';
          output(1:fitlength,4) = t_mat*b_y(fitlength+1,2:3)';
      % u, v: ending
        t_mat = [ones(fitlength,1), 2*t(fitlength+2:end)];
        output(end-fitlength+1:end,3)   = t_mat*b_x(end-fitlength,2:3)';
          output(end-fitlength+1:end,4) = t_mat*b_y(end-fitlength,2:3)';
      % a_x, a_y: beginning        
        output(1:fitlength,5)   = 2*repmat(b_x(fitlength+1,3), [fitlength 1]);
          output(1:fitlength,6) = 2*repmat(b_y(fitlength+1,3), [fitlength 1]);
      % a_x, a_y: ending
        output(end-fitlength+1:end,5)   = 2*repmat(b_x(end-fitlength,3), [fitlength 1]);
          output(end-fitlength+1:end,6) = 2*repmat(b_y(end-fitlength,3), [fitlength 1]);
  end
%   OutputStruct(n)=struct('XFit',output(:,1),'YFit',output(:,2),'VelX',output(:,3),...
%                          'VelY',output(:,4),'AccX',output(:,5),'AccY',output(:,6),...
%                          'Fit',fitlength); 
  OutputStruct(n).XFit=output(:,1);
  OutputStruct(n).YFit=output(:,2);
  OutputStruct(n).VelX=output(:,3)*fps;
  OutputStruct(n).VelY=output(:,4)*fps;
  OutputStruct(n).AccX=output(:,5)*fps^2;
  OutputStruct(n).AccY=output(:,6)*fps^2;
  OutputStruct(n).Fit=fitlength;                      
  OutputStruct(n).FPS=fps;
end
  
  
end
