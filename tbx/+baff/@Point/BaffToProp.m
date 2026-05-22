function BaffToProp(obj,filepath,loc)
Fs = h5read(filepath,sprintf('%s/Force',loc));
Ms = h5read(filepath,sprintf('%s/Moment',loc));
for i = 1:length(obj)
    obj(i).Force = Fs(:,i);
    obj(i).Moment = Ms(:,i);
end
BaffToProp@baff.Element(obj,filepath,loc)
end