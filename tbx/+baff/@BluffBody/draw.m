function p = draw(obj,opts)
%Draw draw an element in 3D Space
%Args:
%   opts.Origin: Origin of the beam element in 3D space
%   opts.A: Rotation matrix to beam coordinate system
%   opts.Type: plot type
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

% create mesh
th = 0:pi/10:2*pi;
Nth = length(th);
stDirs = obj.Stations.StationDir./vecnorm(obj.Stations.StationDir);
z = cross(obj.Stations.EtaDir./vecnorm(obj.Stations.EtaDir),stDirs);
perp = cross(stDirs,z);
% create mesh
[X,Y,Z] = deal(zeros(Nth,N));
for n = 1:N
    A = [stDirs(:,n),cross(perp(:,n),stDirs(:,n)),perp(:,n)];
    Xi = Rot*A*[obj.Stations.Radius(n).*cos(th);obj.Stations.Radius(n).*sin(th);th*0] + points(:,n);
    % Xi = Rot*Xi;
    X(:,n) = Xi(1,:)';
    Y(:,n) = Xi(2,:)';
    Z(:,n) = Xi(3,:)';
end
p = plot3(points(1,:),points(2,:),points(3,:),'-o');
p.Color = 'c';
p.MarkerFaceColor = 'c';
p.Tag = 'Body';
switch opts.Type
    case "stick"
        %plot Beam Stations
        for n = 1:N
            plt_obj = plot3(X(:,n),Y(:,n),Z(:,n),'-');
            plt_obj.Color = [0.4 0.4 0.4];
            plt_obj.Tag = 'Body';
            p(end+1) = plt_obj;
        end
    case "surf"
        % create mesh
        p(end+1) = surf(X, Y, Z, FaceColor=[1 1 1]*0.9, EdgeColor='k');
        p(end).Tag = 'BodySurface';
    case "mesh"
        % create mesh
        p(end+1) = surf(X, Y, Z, FaceColor=[1 1 1]*0.9, EdgeColor='k');
        p(end).Tag = 'BodySurface';
end


%plot children
optsCell = namedargs2cell(opts);
plt_obj = draw@baff.Element(obj,optsCell{:});
p = [p,plt_obj];
end