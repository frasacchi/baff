function obj = FromBaff(filepath,loc)
%FROMBAFF Summary of this function goes here
%   Detailed explanation goes here
Qty = h5readatt(filepath,[loc,'/GBeamStations/'],'Qty');

if Qty == 0
    obj = baff.station.GBeam.Blank(0);
    return;
end
obj = baff.station.GBeam.Blank(Qty);
%% create Mats
aIdx = h5readatt(filepath,[loc,'/'],'MatsIdx');
Mats = baff.Material.FromBaff(filepath,loc);
obj.Mat = Mats(aIdx);
%% create aerostations
obj.Eta = h5read(filepath,sprintf('%s/GBeamStations/Eta',loc));
obj.EtaDir = h5read(filepath,sprintf('%s/GBeamStations/EtaDir',loc));
obj.StationDir = h5read(filepath,sprintf('%s/GBeamStations/StationDir',loc));
obj.A = h5read(filepath,sprintf('%s/GBeamStations/A',loc));
obj.I = reshape(h5read(filepath,sprintf('%s/GBeamStations/I',loc)),3,3,[]);
obj.J = h5read(filepath,sprintf('%s/GBeamStations/J',loc));
obj.tau = reshape(h5read(filepath,sprintf('%s/GBeamStations/Tau',loc)),3,3,[]);
obj.K45 = h5read(filepath,sprintf('%s/GBeamStations/K45',loc));
end

