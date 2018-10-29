function PTrim=ParticleTrim2(P,field,UpperL,LowerL)
% from Vicente, Stocker lab
%TRIMMED = ParticleTrim(P,FIELD,LOWERL,UPPERL)
%   P - Structure of particles found in each frame, with different fields
%       describing characteristics
%   FIELD - A string corresponding to a field in the structure P which will
%           be used to restrict the particles
%   LOWERL - A numerical value indicating the lower bound for the specified
%            field name, use '-inf' to skip.
%   UPPERL - A numerical value indicating the upper bound for the specified
%            field name, use 'inf' to skip.
%
%   TRIMMED - The output is in the same structure array form as the input
%             structure P,  but with only the valid particles.
%% for testing:
% P=cellsProps;
% field = 'A';
% LowerL = 5;
% UpperL = 100;

%% get variable names
fNames=fieldnames(P(1));
fNames(strcmp(fNames,'Frame'))=[];
fNames(strcmp(fNames,'Conv'))=[];
fNames(strcmp(fNames,'FPS'))=[];
fNames(strcmp(fNames,'Time'))=[];
fNames(strcmp(fNames,'Thrsh'))=[];

PTrim=P;

for n=1:length(P) %loop over the frames and remove the trimmed objects
    D=getfield(P(n),field);
    f=find(and(D>LowerL,D<UpperL));
    for m=1:length(fNames) %loop over the fields and keep only the untrimmed objects
        tempField=getfield(P(n),fNames{m});
        PTrim(n)=setfield(PTrim(n),fNames{m},tempField(f));
    end
end

end
