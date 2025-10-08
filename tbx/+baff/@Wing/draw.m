function p = draw(obj,opts)
arguments
    obj
    opts.Origin (3,1) double = [0,0,0];
    opts.A (3,3) double = eye(3);
    opts.Type string {mustBeMember(opts.Type,["stick","surf","mesh"])} = "surf";
end
Origin = opts.Origin + opts.A*(obj.Offset);
Rot = opts.A*obj.A;

%get central points
N = obj.Stations.N;
points = repmat(Origin,1,N) + Rot*obj.GetPos(obj.Stations.Eta);

%plot beam
if isa(obj.Stations,'baff.station.ShellStation.ShellStation')
    p = plot3(points(1,:),points(2,:),points(3,:),'-','Marker','square');
    p.Color = 'k';
    p.MarkerFaceColor = 'k';
    p.Tag = 'Shell';
elseif isa(obj.Stations,'baff.station.Beam')
    p = plot3(points(1,:),points(2,:),points(3,:),'-o');
    p.Color = 'c';
    p.MarkerFaceColor = 'c';
    p.Tag = 'Beam';
end

N = obj.AeroStations.N;
etas = obj.AeroStations.Eta;
beamPos = obj.Stations.GetPos(etas).*obj.EtaLength;

%create surface
LeVec = obj.AeroStations.GetPos(etas,0);
TeVec = obj.AeroStations.GetPos(etas,1);
O = repmat(Origin,1,2);
[X,Y,Z] = deal(zeros(2,N));
for i = 1:N
    ps = beamPos(:,[i i]) + [LeVec(:,i),TeVec(:,i)];
    ps = O + Rot*ps;
    X(:,i) = ps(1,:)';
    Y(:,i) = ps(2,:)';
    Z(:,i) = ps(3,:)';
end

switch opts.Type
    case "stick"
        %plot Beam Stations
        for i = 1:N
            plt_obj = plot3(X(:,i),Y(:,i),Z(:,i),'-o');
            plt_obj.Color = 'k';
            plt_obj.Tag = 'WingSection';
            p = [p,plt_obj];
        end
    case "surf"
        % create mesh
        p(end+1) = surf(X, Y, Z, FaceColor=[1 1 1]*0.9, EdgeColor='k');
        p(end).Tag = 'AeroSurface';
    case "mesh"
        Ns = 15;
        [X,Y,Z] = deal(zeros(2*Ns-1,N));
        beamPos = obj.Stations.GetPos(obj.AeroStations.Eta).*obj.EtaLength;
        for i = 1:N
            xs = obj.AeroStations.Airfoil(i).Etas;
            xi = linspace(0,1,Ns)';
            ys = obj.AeroStations.Airfoil(i).Ys;
            yi = interp1(xs,ys,xi);
            ei = [xi;flipud(xi(1:end-1))];
            yi = [yi(:,1);flipud(yi(1:end-1,2))].*obj.AeroStations.ThicknessRatio(i).*obj.AeroStations.Chord(i);
            
            V = obj.AeroStations.GetPos(obj.AeroStations.Eta(i),ei);
            ps = repmat(Origin,1,2*Ns-1) + Rot*(repmat(beamPos(:,i),1,2*Ns-1) + V + [zeros(2,2*Ns-1);yi']);
            X(:,i) = ps(1,:)';
            Y(:,i) = ps(2,:)';
            Z(:,i) = ps(3,:)';
        end
        % create mesh
        p(end+1) = surf(X, Y, Z, FaceColor=[1 1 1]*0.9, EdgeColor='k');
        p(end).Tag = 'AeroSurface';
end

% plot control Surfaces
plt_obj = obj.ControlSurfaces.draw(obj,Origin=Origin,A=Rot);
p = [p,plt_obj];

%plot children
optsCell = namedargs2cell(opts);
plt_obj = draw@baff.Element(obj,optsCell{:});
p = [p,plt_obj];
end