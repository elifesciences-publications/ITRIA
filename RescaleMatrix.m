function MR=RescaleMatrix(M,LL,UL)
%from Vicente, Stocker lab
ML=min(M(:));
MU=max(M(:));

MR=(M-ML)/(MU-ML)*(UL-LL)+LL;

