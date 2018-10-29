function P=ParticleTracks2Time2(P0)
%from Vicente, Stocker lab. Adapted for the Itria 11/12/2016

Fmin=min(arrayfun(@(Q) min(Q.Frame),P0));
Fmax=max(arrayfun(@(Q) max(Q.Frame),P0));
FRange=[Fmin:Fmax];

names=fieldnames(P0(1));
names0=names;
names(strcmp(names,'Frame'))=[];
names(strcmp(names,'Fit'))=[];
names(strcmp(names,'FPS'))=[];
names(strcmp(names,'Conv'))=[];
% names(strcmp(names,'PixelIdxList'))=[]; %cell inside a cell is problematic


tic

h = waitbar(0,['Converting ...']);
FrameField=cell2mat(arrayfun(@(Q) Q.Frame,P0,'UniformOutput',0));
P=[];
CellTemp=cell(length(names),length(FRange));
for m=1:length(names)
    waitbar(m/length(names),h)
%     TempField=cell2mat(arrayfun(@(Q) getfield(Q,names{m}),P0,'UniformOutput',0));
    if strcmp(names(m),'PixelIdxList')
        disp('x');
        FrameField2=arrayfun(@(Q) Q.Frame,P0,'UniformOutput',0);
        TempField2=arrayfun(@(Q) Q.PixelIdxList,P0,'UniformOutput',0);                       
        for n=1:length(FRange);
            a=cell(length(TempField2),1);
            for i=1:length(TempField2)
                ind=FrameField2{i}==FRange(n);
                if max(ind)>0
                    b=TempField2{i}{FrameField2{i}==FRange(n)};
                else
                    b=[];
                end
                if isempty(b)
                    a{i,1}=[];
                else
                    a{i,1}=b;
                end
    %             ind=find(FrameField==FRange(n));
    %             a=TempField2{ind,1};
    %             CellTemp{m,n}=
    %             cellIndTemp=arrayfun(@TempField2{ind};
    %             TempField_n=cell
    %             TempField_n=(TempField{FrameField==FRange(n),1});
    %             CellTemp{m,n}=cellfun(@(Q) Q{FrameField==FRange(n),1},TempField);
    %             a=cell(1,1);
    %             a{1,1}=TempField{ind,1};
    %             CellTemp{m,n}=TempField{ind,1};
            end
            a = a(~cellfun(@isempty, a));%remove empty cells
            CellTemp{m,n}=a;
        end
        
    else %for all the other fields
        TempField=cell2mat(arrayfun(@(Q) Q.(names{m}),P0,'UniformOutput',0));
        for n=1:length(FRange);
            CellTemp{m,n}=TempField(FrameField==FRange(n));
        end
    end
end
CellTemp(m+1,1:length(FRange))=num2cell(FRange);
names{length(names)+1}='Frame';

% Reintroduce single valued fields
if max(strcmp(names0,'Fit'))
    CellTemp(length(names)+1,1:length(FRange))=num2cell(ones(size(FRange))*P0(1).Fit);
    names{length(names)+1}='Fit';
end

if max(strcmp(names0,'FPS'))
    CellTemp(length(names)+1,1:length(FRange))=num2cell(ones(size(FRange))*P0(1).FPS);
    names{length(names)+1}='FPS';
end

if max(strcmp(names0,'Conv'))
    CellTemp(length(names)+1,1:length(FRange))=num2cell(ones(size(FRange))*P0(1).Conv);
    names{length(names)+1}='Conv';
end

P=cell2struct(CellTemp,names,1);
close(h)
    

% informational
mytime = toc;
disp(['Elapsed Time: ', num2str(mytime), ' seconds'])
disp('  ')