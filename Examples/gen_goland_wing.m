function model = gen_goland_wing(opts)
arguments
    opts.b = 6.096;
    opts.m = 35.71;
    opts.c = 1.8288;
    opts.EI = 9.77e6;
    opts.GJ = 0.99e6;
    opts.x_f = 0.33;
    opts.x_m = 0.43;
    opts.Ix = 8.64;
    opts.NAeroStations = 10;
    opts.NBeamStations = 2;

    opts.LiftCurveSlope = 2*pi;

    opts.EtaTwist = [0,1];
    opts.Twist = [0,0];
end
% make beam stations
Mat = baff.Material.Unity().ZeroDensity();
beamStations = baff.station.Beam(linspace(0,1,opts.NBeamStations),Mat=Mat,I=diag([0,opts.EI,0]),A=1,J=opts.GJ);
%create end aero station
aeroStations = baff.station.Aero(linspace(0,1,opts.NAeroStations),opts.c,opts.x_f,LiftCurveSlope=opts.LiftCurveSlope,...
    LinearDensity=opts.m,LinearInertia=diag([opts.Ix,0,0]),MassLoc=opts.x_m);
%gen wing
wing = baff.Wing(aeroStations);
wing.EtaLength = opts.b;
% add beam station Info
wing.Stations = beamStations;
wing.Name = 'GolandWing';
wing.AeroStations.Twist = interp1(opts.EtaTwist,opts.Twist,wing.AeroStations.Eta);

% Add Root Constraint
con = baff.Constraint("ComponentNums",123456,"eta",0,"Name","Root Connection");
con.add(wing);
wing.A = dcrg.rotzd(90);

% make the model
model = baff.Model;
model.AddElement(con);
model.UpdateIdx();
end

