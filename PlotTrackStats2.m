function PlotTrackStats2(PTracks)
%From Vicente, Stocker lab. Adapted for the Itria 11/12/2016
AvgA=arrayfun(@(X) nanmean(X.Area),PTracks);
AvgI=arrayfun(@(X) nanmean(X.AvgInt),PTracks);
TrL=arrayfun(@(X) length(X.X),PTracks);
TrF=arrayfun(@(X) X.Frame(1),PTracks);
MedV=arrayfun(@(X) median(sqrt(X.VelX.^2+X.VelY.^2)),PTracks);

figure(gcf)
set(gcf,'Position',[360 78 526 620])
clf
subplot(211)
scatter(AvgA,AvgI,TrL,TrF)
xlabel('Avg Area')
ylabel('Avg Intensity')
title('Size ~ Track Length, Color ~ Start Frame')

subplot(223)
scatter(AvgA,MedV,TrL,TrF)
xlabel('Avg Area')
ylabel('Avg Velocity')
% title('Color ~ Start Frame')
title('Size ~ Track Length, Color ~ Start Frame')

subplot(224)
scatter(TrL,MedV,12,TrF)
xlabel('Track Length')
ylabel('Avg Velocity')
title('Color ~ Start Frame')