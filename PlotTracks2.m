function PlotTracks2(P,g)

if nargin<2
    g='.-k';
end

figure(gcf)
hold on

if isfield(P,'XFit')
    X=cell2mat(arrayfun(@(X) X.XFit,P,'UniformOutput',0));
    Y=cell2mat(arrayfun(@(X) X.YFit,P,'UniformOutput',0));
end

for n=1:length(P)
    plot(P(n).X,P(n).Y,g)
end

axis equal