classdef Mass < baff.Point
    %MASS Summary of this class goes here
    %   Detailed explanation goes here
    properties
        mass (1,1) double; % mass of the point mass
        InertiaTensor (3,3) double= zeros(3); % {(3,3) double} inertia tensor of the point mass
    end
    methods(Static)
        obj = FromBaff(filepath,loc);
        TemplateHdf5(filepath,loc);
    end
    methods
        function val = getType(obj)
            %getType returns the type of the object as a string.
            val ="Mass";
        end
    end
    
    methods
        function val = GetElementMass(obj)
            %GetElementMass returns the mass of the mass element (excluding children).
            val = [obj.mass];
        end
        function [Xs,masses] = GetElementCoM(obj)
            %GetElementCoM returns the center of mass and masses of the mass element (excluding children).
            masses = [obj.mass];
            Xs = zeros(3,length(obj));
            % for i = 1:length(obj)
            %     Xs(:,i) = obj(i).GetGlobalPos(0,0);
            % end
        end
        function val = eq(obj1,obj2)
            %overloads the == operator to check the equality of two Mass objects.
            if length(obj1)~= length(obj2) || ~isa(obj2,'baff.Mass')
                val = false;
                return
            end
            val = eq@baff.Element(obj1,obj2);
            for i = 1:length(obj1)
                val = val && obj1(i).mass == obj2(i).mass;
                val = val && all(obj1(i).InertiaTensor == obj2(i).InertiaTensor,'all');
            end
        end
        function obj = Mass(mass,opts,CompOpts)
            %MASS Construct an instance of this class
            %Args:
            %   mass (double): Mass of the point mass
            %   opts.Ixx (double): Inertia tensor component Ixx
            %   opts.Iyy (double): Inertia tensor component Iyy
            %   opts.Izz (double): Inertia tensor component Izz
            %   opts.Ixy (double): Inertia tensor component Ixy
            %   opts.Ixz (double): Inertia tensor component Ixz
            %   opts.Iyz (double): Inertia tensor component Iyz
            %   CompOpts.Eta (double): Eta value for the mass
            %   CompOpts.Offset (3,1) double: Offset of the mass element from its parent
            %   CompOpts.Name (string): Name of the mass element
            %   CompOpts.Force (3,1) double: Force applied to the mass
            %   CompOpts.Moment (3,1) double: Moment applied to the mass

            arguments
                mass
                opts.Ixx = 0;
                opts.Iyy = 0;
                opts.Izz = 0;
                opts.Ixy = 0;
                opts.Ixz = 0;
                opts.Iyz = 0;

                CompOpts.Eta = 0
                CompOpts.Offset
                CompOpts.Name = "Point Mass" 
                CompOpts.Force = nan(3,1);
                CompOpts.Moment = nan(3,1);
            end
            CompStruct = namedargs2cell(CompOpts);
            obj = obj@baff.Point(CompStruct{:});
            obj.mass = mass;
            obj.InertiaTensor = [opts.Ixx,opts.Ixy,opts.Ixz;...
                                opts.Ixy,opts.Iyy,opts.Iyz;...
                                opts.Ixz,opts.Iyz,opts.Izz];
        end
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
                opts.Type string {mustBeMember(opts.Type,["stick","surf","mesh"])} = "stick";
            end
            Origin = opts.Origin + opts.A*(obj.Offset);
            Rot = opts.A*obj.A;
            %plot mass
            p = plot3(Origin(1,:),Origin(2,:),Origin(3,:),'^');
            p.MarkerFaceColor = 'b';
            p.Color = 'b';
            p.Tag = 'Mass';
            % if norm(obj.Force)>0
            %     v = Rot*obj.Force(:).*obj.VectorPltScaling;
            %     o = [Origin(1,1);Origin(2,1);Origin(3,1)];
            %     vo = [o,o+v];
            %     p = plot3(vo(1,:),vo(2,:),vo(3,:),'-r','LineWidth',1.5);
            %     p.Tag = 'Force';
            % end
            if norm(obj.Force) > 0
                v = Rot * obj.Force(:) .* obj.VectorPltScaling;
                ox = Origin(1,1);
                oy = Origin(2,1);
                oz = Origin(3,1);
                p = quiver3(ox, oy, oz, v(1), v(2), v(3), 0, '-r', 'LineWidth', 1.5);
                p.Tag = 'Force';
                p.MaxHeadSize = 0.5; 
            end
            %plot children
            optsCell = namedargs2cell(opts);
            plt_obj = draw@baff.Element(obj,optsCell{:});
            p = [p,plt_obj];
        end
    end
end

