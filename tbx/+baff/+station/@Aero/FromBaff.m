function obj = FromBaff(filepath,loc)
%FROMBAFF Summary of this function goes here
%   Detailed explanation goes here
Qty = h5readatt(filepath,[loc,'/AeroStations/'],'Qty');
obj = baff.station.Aero.Blank(1);
if Qty == 0    
    return;
end
obj = baff.station.Aero.Blank(Qty);
%% create Airfoils
aIdx = h5readatt(filepath,[loc,'/'],'AirfoilsIdx');
Airfoils = baff.Airfoil.FromBaff(filepath,loc);
obj.Airfoil = Airfoils(aIdx);
%% create aerostations
obj.Eta = h5read(filepath,sprintf('%s/AeroStations/Eta',loc));
obj.EtaDir = h5read(filepath,sprintf('%s/AeroStations/EtaDir',loc));
obj.StationDir = h5read(filepath,sprintf('%s/AeroStations/StationDir',loc));
obj.Chord = h5read(filepath,sprintf('%s/AeroStations/Chord',loc));
obj.Twist = h5read(filepath,sprintf('%s/AeroStations/Twist',loc));
obj.BeamLoc = h5read(filepath,sprintf('%s/AeroStations/BeamLoc',loc));
obj.ThicknessRatio = h5read(filepath,sprintf('%s/AeroStations/ThicknessRatio',loc));
obj.LiftCurveSlope = h5read(filepath,sprintf('%s/AeroStations/LiftCurveSlope',loc));

obj.LinearDensity = h5read(filepath,sprintf('%s/AeroStations/LinearDensity',loc));
obj.LinearInertia = reshape(h5read(filepath,sprintf('%s/AeroStations/LinearInertia',loc)),3,3,[]);
obj.MassLoc = h5read(filepath,sprintf('%s/AeroStations/MassLoc',loc));
end

