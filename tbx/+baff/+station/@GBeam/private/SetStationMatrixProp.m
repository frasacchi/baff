function out = SetStationMatrixProp(val,N)
if size(val,3) == 1 && N>1
    out = repmat(val,1,1,N);
else
    out = val;
end
end

