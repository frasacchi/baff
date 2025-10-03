function obj = FromBaff(filepath,loc)
%FROMBAFF Summary of this function goes here
%   Detailed explanation goes here
Qty = h5readatt(filepath,[loc,'/BeamStations/'],'Qty');
obj = baff.station.Beam.empty;
if Qty == 0    
    return;
end
%% create aerostations
etas = h5read(filepath,sprintf('%s/BeamStations/Eta',loc));
etaDirs = h5read(filepath,sprintf('%s/BeamStations/EtaDir',loc));
stationDirs = h5read(filepath,sprintf('%s/BeamStations/StationDir',loc));
As = h5read(filepath,sprintf('%s/BeamStations/A',loc));
Is = h5read(filepath,sprintf('%s/BeamStations/I',loc));
Js = h5read(filepath,sprintf('%s/BeamStations/J',loc));
taus = h5read(filepath,sprintf('%s/BeamStations/Tau',loc));
Es = h5read(filepath,sprintf('%s/BeamStations/E',loc));
rhos = h5read(filepath,sprintf('%s/BeamStations/rho',loc));
nus = h5read(filepath,sprintf('%s/BeamStations/nu',loc));
for i = 1:Qty
    mat = baff.Material(Es(i),nus(i),rhos(i));
    obj(i) = baff.station.Beam(etas(i),"EtaDir",etaDirs(:,i),...
    "StationDir",stationDirs(:,i),"Mat",mat,"J",Js(i));
    obj(i).A = As(i);
    obj(i).I = reshape(Is(:,i),3,3);
    obj(i).tau = reshape(taus(:,i),3,3);
end
end

