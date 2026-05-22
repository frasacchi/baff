function obj = BuildBaff(obj,opts)
arguments
    obj
    opts.Retracted = true;
    opts.WingBeamElements = obj.WingBeamElements;
    opts.PAX = 180;
end
%% calculate fuselage

FuelMass = obj.MTOM * 0.1871;

% estimate fuselage size
[L_c,D_c] = cabin(opts.PAX,N_sr=obj.N_seatsPerRow); % enforce 6 seats per row
[fus,Ls] = fuselage(L_c+D_c,D_c);
L_f = Ls(end);

M_dg = obj.MTOM*2.2; % design mass (taking at M_TOC)
M_ldg = obj.MTOM*0.84*2.2;

% mass of fuselage (Torenbeek 8.3)
m_f = (60*D_c^2*(L_f+1.5)+160*(1.5*2.5)^0.5*D_c*L_f)./9.81*1;
% mass of furniture (Torenbeek 8.10)
m_furn = (12*L_f*D_c*(3*D_c+0.5*1+1)+3500)./9.81*1.0;
% Systems Mass (Torenbeek 8.9)
m_sys = (270*D_c+150)*L_f/9.81-300;
% operator Equipment (Torenbeek Table 8.1)
m_op = (350*opts.PAX)./9.81;

% distribute masses on the fuselage
fus.DistributeMass(m_f+m_sys,14,"tag","fus_struct");
fus.DistributeMass(m_furn + m_op,14,"tag","fus_cabin","Etas",Ls(2:3)./L_f);
fus.DistributeMass(19e3,14,"tag","fus_Payload","isPayload",true,"Etas",Ls(2:3)./L_f);

%% create wings
% get common properties
[Connector_RHS,Wing_RHS,FFWT_RHS,fuelCap_RHS,obj.L_ldg,obj.Masses] = obj.BuildWing(true,D_c,"Retracted",opts.Retracted,"BeamElements",opts.WingBeamElements);
fus.add(Connector_RHS);
[Connector_LHS,Wing_LHS,FFWT_LHS,fuelCap_LHS,obj.L_ldg,obj.Masses] = obj.BuildWing(false,D_c,"Retracted",opts.Retracted,"BeamElements",opts.WingBeamElements);
fus.add(Connector_LHS);
obj.MainWingRHS = [Connector_RHS,Wing_RHS,FFWT_RHS];
obj.MainWingLHS = [Connector_LHS,Wing_LHS,FFWT_LHS];

% if not enough capaicty in wings add a fuel tank in fuselage
fus_fuel_mass = max(0,(FuelMass - fuelCap_RHS - fuelCap_LHS));
if fus_fuel_mass>0
    N_fuelTank = 4;
    % add fuel mass
    fus_fuel = baff.Fuel(fus_fuel_mass*1.01,"eta",0,"Name",'Fuselage Fuel Tank');
else
    %dummy extra fuel incase we need to add some.
    fus_fuel = baff.Fuel(0,"eta",0,"Name",'Fuselage Fuel Tank');
    N_fuelTank = 3;
end
fus_fuel.Offset = [0;0;0];
Connector_RHS.add(fus_fuel);
%fuel system mass Torenbeek(10.1007/s13272-022-00601-6 Eq. 8)
V_t = FuelMass/785*1000;
m_fuelsys = (36.3*(2+N_fuelTank-1)+4.366*N_fuelTank^0.5*V_t^(1/3));
f_tank = baff.Mass(m_fuelsys,"eta",0,"Name","FuelSystemMass");
f_tank.Offset = [0;0;0];
Connector_RHS.add(f_tank);
obj.Masses.FuelSys = m_fuelsys;
obj.Masses.FuelTanks = 0;

%% add ballast mass
if obj.BallastMass>0
    ballast = baff.Mass(obj.BallastMass,"eta",0,"Name","BallastMass");
    ballast.Offset = [0;0;0];
    Connector_RHS.add(ballast);
    obj.Masses.FuelSys = obj.Masses.FuelSys + obj.BallastMass;
end

%% add nose landing gear

L_ldg_nose = obj.L_ldg -D_c/4 + D_c*0.1;
ldg = baff.Mass(obj.m_nose_ldg,"eta",5/fus.EtaLength,"Name","ldg_nose");
if opts.Retracted
    ldg.Offset = [L_ldg_nose/2;0;-0.4*D_c];
else
    ldg.Offset = [0;0;-(L_ldg_nose+0.4*D_c)];
end
fus.add(ldg);
obj.Masses.LandingGear = obj.Masses.LandingGear + obj.m_nose_ldg;



%% inner loop to size and HTP and VTP and place Wing
mgc = obj.MainWingRHS.GetMGC(0.25);
%% add HTP
% etaHTP =0.87*37.57/fuselage.EtaLength;
etaHTP = (fus.EtaLength-(0.13*37.57))/fus.EtaLength; % start ~same distance away from end of fuselage as a320

sweep_qtr = real(acosd(0.75.*obj.Mstar./0.8));
tc_tip = obj.HTP_TCR_root - 0.03;

%enforce TE of HTP to be 2m away from tail
eta_te = (fus.EtaLength-2)/fus.EtaLength;
tr = 0.32;
idx = 0;
AR = 4.93;
while idx==0 || (abs((1-eta_te)*fus.EtaLength) - 2)^2 >0.05
    etaHTP = etaHTP + ((1-eta_te) - 2/fus.EtaLength);
    obj.HTPArea = obj.WingArea*mgc*obj.V_HT/(fus.EtaLength*(etaHTP-obj.AftEta));
    b_HT = sqrt(AR*obj.HTPArea);
    c_r = obj.HTPArea/(b_HT*(1+tr)/2);
    eta_te = etaHTP + c_r*0.75/fus.EtaLength;
    idx = 1;
end
sweep_le = atand(c_r/4*(1-tr)/(b_HT/2)+tand(sweep_qtr));
sweep_te = atand(tand(sweep_qtr)+3/4*c_r*(tr-1)/(b_HT/2));
mgc = 2/3*c_r*(1+tr+tr^2)/(1+tr);
y_mgc_ht = b_HT/6*(1+2*tr)/(1+tr);
x_mgc_ht = y_mgc_ht*tan(sweep_qtr)+mgc*0.25;

m_HT = 0.016*(1.5*2.5*M_dg)^0.414*(2.2/3.28^2*(0.4*0.5*(300*0.8)^2))^0.168*(obj.HTPArea*3.28^2)^0.896*...
    (100*(obj.HTP_TCR_root+tc_tip)/2/cosd(sweep_le))^-0.12*(AR/cosd(sweep_le)^2)^0.043*tr^-0.02;
m_HT = m_HT./2.2;


HT_RHS = baff.Wing.FromLETESweep(b_HT/2,c_r,[0 1],sweep_le,sweep_te,0.25,...
    baff.Material.Stiff,"ThicknessRatio",[obj.HTP_TCR_root,tc_tip]);
HT_RHS.A = dcrg.rotzd(90)*dcrg.rotxd(180);
HT_RHS.Eta = etaHTP;
HT_RHS.Offset = [0;0;0];
HT_RHS.DistributeMass(m_HT/2,10,"Method","ByVolume","tag","HTP_RHS_mass","BeamOffset",-0.15);
HT_RHS.Name = 'HTP_RHS';
HT_RHS.AeroStations = HT_RHS.AeroStations.interpolate(0:0.2:1);
fus.add(HT_RHS);

% create elevator RHS
HT_RHS.ControlSurfaces = baff.ControlSurface('ele_RHS',[0.2 1],[0.4 0.4]);

HT_LHS = baff.Wing.FromLETESweep(b_HT/2,c_r,[0 1],sweep_le,sweep_te,0.25,...
    baff.Material.Stiff,"ThicknessRatio",[obj.HTP_TCR_root,tc_tip]);
HT_LHS.Stations.EtaDir(1,:) = -HT_LHS.Stations.EtaDir(1,:);

HT_LHS.A = dcrg.rotzd(90)*dcrg.rotxd(180);
HT_LHS.Eta = etaHTP;
HT_LHS.Offset = [0;0;0];
HT_LHS.DistributeMass(m_HT/2,10,"Method","ByVolume","tag","HTP_LHS_mass","BeamOffset",-0.15);
HT_LHS.Name = 'HTP_LHS';
HT_LHS.AeroStations = HT_LHS.AeroStations.interpolate(0:0.2:1);
fus.add(HT_LHS);
% create elevator LHS
HT_LHS.ControlSurfaces = baff.ControlSurface('ele_LHS',[0.2 1],[0.4 0.4]);
HT_LHS.ControlSurfaces.LinkedSurface = HT_RHS.ControlSurfaces(1);
HT_LHS.ControlSurfaces.LinkedCoefficent = 1;

%% add VTP
etaVTP = (fus.EtaLength-(0.17*37.57))/fus.EtaLength; % start ~same distance away from end of fuselage as a320

%enforce TE of VTP to be 2.15m away from tail
eta_te = (fus.EtaLength-2.15)/fus.EtaLength;
tr = 0.33;
idx = 0;
AR = 3.1;
while idx==0 || (abs((1-eta_te)*fus.EtaLength) - 2.15)^2 >0.05
    etaVTP = etaVTP + ((1-eta_te) - 2.15/fus.EtaLength);
    obj.VTPArea =  obj.WingArea*obj.Span*obj.V_VT/(fus.EtaLength*(etaVTP-obj.AftEta));
    if obj.VTPArea>obj.WingArea/3
        obj.VTPArea = obj.WingArea/3; % Ensure VTP area does not exceed one-third of wing area
    end
    b_VT = sqrt(AR*obj.VTPArea*2)/2;
    c_r = obj.VTPArea/(b_VT*(1+tr)/2);
    eta_te = etaVTP + c_r*0.75/fus.EtaLength;
    idx = 1;
end

mgc = 2/3*c_r*(1+tr+tr^2)/(1+tr);
y_mgc_vt = b_VT/6*(1+2*tr)/(1+tr);
sweep_qtr = 35;
sweep_le = atand(c_r/4*(1-tr)/(b_VT)+tand(sweep_qtr));
sweep_te = atand(tand(sweep_qtr)+3/4*c_r*(tr-1)/b_VT);
x_mgc_vt = y_mgc_vt*tan(sweep_le)+mgc*0.25;

VT = baff.Wing.FromLETESweep(b_VT,c_r,[0 1],sweep_le,sweep_te,0.25,...
    baff.Material.Stiff,"ThicknessRatio",[obj.HTP_TCR_root,tc_tip]);
VT.A = dcrg.rotzd(90)*dcrg.rotxd(180)*dcrg.rotyd(90);
VT.Eta = etaVTP;
R = fus.Stations.interpolate(etaVTP).Radius;
VT.Offset = [0;0;R];
m_VT = 0.073*(1+0.2*0)*(1.5*2.5*M_dg)^0.376*(2.2/3.28^2*(0.4*0.5*(300*0.8)^2))^0.122*(obj.VTPArea*3.28^2)^0.873*...
    (100*(obj.HTP_TCR_root+tc_tip)/2/cosd(sweep_le))^-0.49*(AR/cosd(sweep_le)^2)^0.357*tr^0.039;
m_VT = m_VT./2.2;
VT.DistributeMass(m_VT,10,"Method","ByVolume","tag","VTP_mass","BeamOffset",-0.15);
VT.Name = 'VTP';
VT.AeroStations = VT.AeroStations.interpolate(0:0.2:1);
fus.add(VT);

%% create model
obj.Baff = baff.Model;
obj.Baff.AddElement(fus);

if isempty(obj.WingBoxParams)
    obj.SetupWings();
else
    old_params = obj.WingBoxParams;
    obj.WingBoxParams = cast.size.WingBoxSizing.empty; % set as empty so new one created when setting up wing
    obj.SetupWings(); % build new WingBoxParams
    obj.InterpOldParams(old_params); % interp old params onto new params
end
obj.ApplyWingParams();

% rebuild to ensure tree is correct / all items accounted for at top-level
obj.Baff = obj.Baff.Rebuild();
obj.Baff.UpdateIdx();
obj.OEM = obj.Baff.GetOEM;

%% adjust wing position to have CoM at 35% of MAC
eta_old = obj.MainWingRHS(1).Eta;
obj.AdjustCoM(obj.StaticMargin);
delta_wing_eta = abs(eta_old-obj.MainWingRHS(1).Eta);
obj.WingEta = obj.MainWingRHS(1).Eta;

% get aft most CG position
xs = obj.GetCoMRange();
x_aft = max(xs);
delta_com = abs(x_aft/fus.EtaLength - obj.AftEta);
obj.AftEta = x_aft/fus.EtaLength;

if max(delta_wing_eta,delta_com)>0.001
    optsCell = namedargs2cell(opts);
    obj.BuildBaff(optsCell{:});
end
end


function [L,D] = cabin(PAX,opts)
arguments
    PAX (1,1) double {mustBeInteger}    % passengers
    opts.N_sr (1,1) double {mustBeInteger} = 0 % seats per row
end
% retruns estimated cabin length and diameter based on number of passengers
% PAX = number of passengers
% L = length in meters
% D = diameter in meters

%estimate number of seats per row, aisles, armrests, and rows
if opts.N_sr == 0
    N_sr = max(6,round(0.45*sqrt(PAX)));
else
    N_sr = opts.N_sr;
end
N_a = dcrg.tern(N_sr>6,2,1);   % number of aisles
N_arm = N_sr+1+N_a;                 % number of armrests
Nr = ceil(PAX/N_sr);                % number of rows

% constants based on existing aircraft
if N_a >1
    % A350 Like
    k_cabin = 1.17;
    delta_d = 0.46;
else
    % A320 like
    k_cabin = 0.7456;
    delta_d = 0.48;
end

% calculate cabin length and diameter
L = Nr*k_cabin;
% constants from a320 charteristics
D = (N_sr*18 + N_arm*1.5 + N_a*19)./39.37 + delta_d; % fuselage diameter
end

function [fuselage,Ls] = fuselage(L_cabin,D_cabin,opts)
% returns fuselage length and diameter based on cabin dimensions
% L_cabin = cabin length in meters
% D_cabin = cabin diameter in meters
% opts.L_cp = cockpit length in meters
% opts.L_tail = tail length in meters
% output:
% fuselage = baff.BluffBody object
% Ls postion of nosecabin start and end;
arguments
    L_cabin (1,1) double {mustBeNumeric} % cabin length in meters
    D_cabin (1,1) double {mustBeNumeric} % cabin diameter in meters
    opts.L_cp (1,1) double {mustBeNumeric} = 4 % cockpit length in meters
    opts.L_tail = D_cabin*1.6733 % tail length in meters
end
L_f = L_cabin + opts.L_cp + opts.L_tail;  % fuselage length

x_c = D_cabin*1.3;              % transition point from cockpit to cabin
x_tail = L_f-D_cabin*2.5;         % transition point from cabin to tail

% make cockpit object
cockpit = baff.BluffBody.SemiSphere(x_c,D_cabin/2);
cockpit.Stations.EtaDir = [1;0;tand(4)];
% make cabin object
cabin = baff.BluffBody.Cylinder(x_tail-x_c,D_cabin/2);
% make tail object
tail = baff.BluffBody.SemiSphere(L_f-x_tail,D_cabin/2,"Inverted",true,"EtaFrustrum",0.05);
% tweak tail so top of fuselage in straight line
dEta = tail.Stations.Eta(2:end)-tail.Stations.Eta(1:end-1);
dRadius = tail.Stations.Radius(1:end-1) - tail.Stations.Radius(2:end);
tail.Stations.EtaDir(:,1:end-1) = [repmat([1;0],1,tail.Stations.N-1);dRadius./dEta./tail.EtaLength];

% conbine into a fuselage
fuselage = cockpit + cabin + tail;
fuselage.Name = "fuselage";
fuselage.A = dcrg.rotzd(180);
fuselage.Stations.EtaDir(1,:) = -fuselage.Stations.EtaDir(1,:);
fuselage.Stations.StationDir = [0;0;1];
% make fuselage contribute to Drag
Ls = [0,opts.L_cp, opts.L_cp+L_cabin, L_f];
end