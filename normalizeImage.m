function [outputStack] = normalizeImage(stack,norm_method)
%This function normalizes the image according to the normalization method:
% norm_method = 'global' -> normalize to the global max and min of the stack
% norm_method = 'local' -> normalize each frame to its local max and min

if nargin<2
    norm_method='global';
end

switch norm_method
    case 'global'
        outputStack = (stack-min(stack(:)))./(max(stack(:))-min(stack(:)));
        
    case 'local'
        outputStack = zeros(size(stack));
        for t=1:size(stack,3) %loop over the frames and normalize each one
            Im = stack(:,:,t);
            outputStack(:,:,t)=(Im-min(Im(:)))./(max(Im(:))-min(Im(:)));    
        end %t loop over frames
    
    otherwise
        error('normalization method wasn''t recognized');
        
end %switch

end %function
