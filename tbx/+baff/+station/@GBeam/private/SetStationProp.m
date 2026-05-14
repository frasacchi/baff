function out = SetStationProp(val,N)
if size(val,2) == 1 && N>1
    out = repmat(val,1,N);
else
    out = val;
end
end

