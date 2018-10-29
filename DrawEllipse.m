function [Xo,Yo]=DrawEllipse(MajAx, MinAx, Ang, X, Y, Cspec)

if nargin<6
    Cspec='b';
end

[MajAx,nshifts] = shiftdim(MajAx/2);
[MinAx,nshifts] = shiftdim(MinAx/2);
[Ang,nshifts] = shiftdim(-Ang/180*pi);
[X,nshifts] = shiftdim(X);
[Y,nshifts] = shiftdim(Y);

t=[0:.02:1]'*2*pi;
N=length(t);
Xe=ones(N,1)*X'+cos(t)*(MajAx.*cos(Ang))'-sin(t)*(MinAx.*sin(Ang))';
Ye=ones(N,1)*Y'+cos(t)*(MajAx.*sin(Ang))'+sin(t)*(MinAx.*cos(Ang))';

if nargout==2
    Xo=Xe;
    Yo=Ye;
else
    figure(gcf)
    if isstr(Cspec)
        plot(Xe,Ye,Cspec)
    else
        plot(Xe,Ye,'Color',Cspec)
    end
end

