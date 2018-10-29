function [HOut,binOut]=PlotHist(PTA,y_field)
%from Vicente, Stocker lab. 
%Adapted for the Itria 11/12/2016, Avia Mizrachi
% xField=getfield(PTA,x_field);
%for testing:
% PTA=final_tracks;
% y_field = 'Intensity';

fps=PTA(1).FPS;

for t=1:length(PTA)
    yField{t}=getfield(PTA(t),y_field);
end
y_value=yField';


figure(gcf)
% Tm=cell2mat(arrayfun(@(Q) Q.Frame*ones(size(Q.X)),PTA,'UniformOutput',0))/fps;
% Vel=cell2mat(arrayfun(@(Q) (sqrt(Q.VelX.^2+Q.VelY.^2)),PTA,'UniformOutput',0));
% y_value=cell2mat(yField);

ybin=min(y_value(:)):(max(y_value(:))-min(y_value(:)))/29:max(y_value(:))+1;
for n=1:length(PTA)
    HnT = histc(y_value,ybin);
    Hn(:,n)=HnT;
end
clf
imagesc(([1:length(PTA)])/fps,ybin,Hn)
hold on
axis xy
plot(([1:length(PTA)])/fps,arrayfun(@(Q) median(sqrt(Q.VelX.^2+Q.VelY.^2)),PTA),'k')
xlabel(x_field)
ylabel(y_field)

if nargout
    HOut=Hn;
    binOut=ybin;
end
    