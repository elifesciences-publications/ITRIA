function [h_obj, h_noise] = FilterGen_V_stocker(h_obj, h_noise, F_size, filt_shape)
%from Vicente (stocker lab)
% "h_obj"   = PxP matrix to be used as a filter; if set equal to a number,
%             h_obj is treated as diameter for a top hat filter;
%             'default'->11
% "h_noise" = diameter of noise response function (Gaussian); 'default'->1
% "F_size"  = size of the filters



if nargin < 3 || isequal(filt_shape,'default'); filt_shape='gaussian'; end;
if nargin < 2 || isequal(h_noise,'default'); h_noise=1; end;
if nargin < 1 || isequal(h_obj,'default'); h_obj=11; end; 

if mod(F_size,2) == 0; F_size=F_size+1; end;

if or(F_size<2*h_noise,all([F_size<2*h_obj,~isinf(h_obj)]))
    error('Filter size too small')
end
if h_obj<=h_noise
    error('Highpass cutoff must be larger than lowpass cutoff')
end

x = -(F_size-1)/2:(F_size-1)/2;
[xx,yy] = meshgrid(x,x);
rr = sqrt(xx.^2+yy.^2);


if isinf(h_obj)
    h_obj=zeros(F_size);
elseif isequal(filt_shape, 'gaussian')
    h_obj=fspecial('Gaussian',F_size,h_obj);
    h_obj = h_obj/sum(h_obj(:));
else
    h_obj=rr <= h_obj;
    h_obj = h_obj/sum(h_obj(:));
end


if h_noise==0
    h_noise=zeros(F_size);
    h_noise(rr==0)=1;
elseif isequal(filt_shape, 'gaussian')
    h_noise=fspecial('Gaussian',F_size,h_noise);
else
    h_noise=rr <= h_noise;
end
h_noise = h_noise/sum(h_noise(:));