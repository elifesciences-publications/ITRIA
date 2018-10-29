function [HOut,binOut]=PlotParticleVel2(PTA)
%from Vicente, Stocker lab. 
%Adapted for the Itria 11/12/2016, Avia Mizrachi

fps=PTA(1).FPS;

figure(gcf)
Tm=cell2mat(arrayfun(@(Q) Q.Frame*ones(size(Q.X)),PTA,'UniformOutput',0))/fps;
Vel=cell2mat(arrayfun(@(Q) (sqrt(Q.VelX.^2+Q.VelY.^2)),PTA,'UniformOutput',0));

bin=min(Vel):(max(Vel)-min(Vel))/29:max(Vel)+1;
for n=1:length(PTA)
    HnT = histc(sqrt(PTA(n).VelX.^2+PTA(n).VelY.^2),bin);
    Hn(:,n)=HnT;
end
clf
imagesc(([1:length(PTA)])/fps,bin,Hn)
hold on
axis xy
plot(([1:length(PTA)])/fps,arrayfun(@(Q) median(sqrt(Q.VelX.^2+Q.VelY.^2)),PTA),'k')
xlabel('Time (s)')
ylabel('Velocity (units/s)')

if nargout
    HOut=Hn;
    binOut=bin;
end
    