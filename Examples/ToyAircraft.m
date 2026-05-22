clear all
fus_rad = 0.055;
span = 1.5;
hinge_eta = 0.8;
beam_loc = 0.25;
Chord = 0.12;
flare = 20;
fold = deg2rad(10);

%empenage setting
hSpan = 0.4;
hChord = 0.07;
vSpan = 0.15;
vChord = 0.07;

%% create fuselage
cockpit = baff.BluffBody.SemiSphere(0.15,0.055);

fus_body = baff.BluffBody.Cylinder(0.652-0.082,0.055);

fus_tail = baff.BluffBody.Cone(0.14,0.055,0.02);
[fus_tail.Stations.EtaDir] = deal([0.14;0;0.005-0.02-0.005]./0.14);

fuselage = cockpit + fus_body + fus_tail;
for i = 1:length(fuselage.Stations)
    fuselage.Stations(i).EtaDir(1) = -fuselage.Stations(i).EtaDir(1);
    fuselage.Stations(i).StationDir = [0;0;1];
end
%% create Wing
Wing = baff.Wing.UniformWing(span*hinge_eta,0.1,0.1,...
    baff.Material.Stiff,Chord,beam_loc,"NAeroStations",11);
Wing.A = dcrg.rotzd(-90)*dcrg.rotxd(180);
Wing.Eta = 0.5;
Wing.Offset = [0;span*hinge_eta*0.5;fus_rad*0.66];
fuselage.add(Wing);

% Add Control Surface
Wing.ControlSurfaces(1) =  baff.ControlSurface("Ail_R",[0.8 0.95],[0.25 0.25]);
Wing.ControlSurfaces(2) =  baff.ControlSurface("Ail_L",[0.05 0.2],[0.25 0.25]);

%% create RHS Wingtip
hinge_rhs = baff.Hinge();
hinge_rhs.HingeVector = dcrg.rotzd(-flare)*[0;1;0];
hinge_rhs.Rotation = -fold;
hinge_rhs.Eta = 1;
hinge_rhs.Offset = [0;(beam_loc-0.5)*Chord;0];
hinge_rhs.Name = 'SAH_RHS';
Wing.add(hinge_rhs);

Wingtip_rhs = baff.Wing.UniformWing(span*(1-hinge_eta)*0.5,0.1,0.1,...
    baff.Material.Stiff,Chord,beam_loc,"NAeroStations",5);
Wingtip_rhs.Offset = [0;-(beam_loc-0.5)*Chord;0];
hinge_rhs.add(Wingtip_rhs);

%% create LHS Wingtip
hinge_lhs = baff.Hinge();
hinge_lhs.HingeVector = dcrg.rotzd(flare)*[0;1;0];
hinge_lhs.Rotation = fold;
hinge_lhs.Eta = 0;
hinge_lhs.Offset = [0;(beam_loc-0.5)*Chord;0];
hinge_lhs.Name = 'SAH_lhs';
Wing.add(hinge_lhs);

Wingtip_lhs = baff.Wing.UniformWing(span*(1-hinge_eta)*0.5,0.1,0.1,...
    baff.Material.Stiff,Chord,beam_loc,"NAeroStations",5);
Wingtip_lhs.Offset = [0;-(beam_loc-0.5)*Chord;0];
Wingtip_lhs.A = dcrg.rotyd(180);
hinge_lhs.add(Wingtip_lhs);


%% create htp
Htp = baff.Wing.UniformWing(hSpan,0.1,0.1,...
    baff.Material.Stiff,hChord,beam_loc,"NAeroStations",11);
Htp.A = dcrg.rotzd(-90)*dcrg.rotxd(180);
Htp.Eta = 0.93;
Htp.Offset = [0;hSpan*0.5;-fus_rad*0.25];
fuselage.add(Htp);

Htp.ControlSurfaces(1) =  baff.ControlSurface("Ele_R",[0.6 0.95],[0.3 0.3]);
Htp.ControlSurfaces(2) =  baff.ControlSurface("Ele_L",[0.05 0.4],[0.3 0.3]);

%% create vtp
Vtp = baff.Wing.UniformWing(vSpan,0.1,0.1,...
    baff.Material.Stiff,vChord,beam_loc,"NAeroStations",11);
Vtp.A = dcrg.rotyd(90)*dcrg.rotxd(-90);
Vtp.Eta = 0.93;
Vtp.Offset = [0;0;-fus_rad*0.25];
fuselage.add(Vtp);

Vtp.ControlSurfaces(1) =  baff.ControlSurface("Rud_R",[0.3 0.95],[0.25 0.25]);

%% create model
delete test.h5
baff.Model.GenTempHdf5('test.h5');

tic;
model = baff.Model;
model.AddElement(fuselage);
model.UpdateIdx();
model.ToBaff('test.h5');
toc;

f = figure(1);
clf;
hold on
model.draw(f)
ax = gca;
ax.Clipping = false;
% ax.ZAxis.Direction = "reverse";
axis equal

%% read file and plot again
tic;
model2 = baff.Model.FromBaff('test.h5');
toc;
f = figure(2);
clf;
hold on
model2.draw(f);
ax = gca;
ax.Clipping = false;
ax.ZAxis.Direction = "reverse";
axis equal