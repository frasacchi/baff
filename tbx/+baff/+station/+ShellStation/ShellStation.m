classdef ShellStation < baff.station.Base
    properties
        Nodes(:,3) double = [];
        Shell(:,1) baff.station.ShellStation.Shell = baff.station.ShellStation.Shell.empty;
        SecondaryEta(1,:) double = 0;
        SecondaryNodes(:,4) = [];
        ConstrainedEta(1,:) = [];
        ConstrainedNodes(:,:) = [];
        Mat = baff.Material.Stiff;
    end

    % methods (Static)
    %     obj = FromBaff(filepath,loc);
    %     TemplateHdf5(filepath,loc);
    % end

    methods(Static)
        function obj = Blank(N)
            %BLANK Create default station Array of N stations
            obj = baff.station.ShellStation.ShellStation(zeros(1,N));
        end
    end

    methods
        function obj = ShellStation(eta,opts)
            arguments
                eta
                opts.EtaDir = [1;0;0]
                opts.StationDir = [0;1;0];
                opts.Mat = baff.Material.Stiff;
                opts.Nodes(:,3) double = [];
                opts.Shell(:,1) baff.station.ShellStation.Shell = baff.station.ShellStation.Shell.empty;
                opts.SecondaryEta(1,:) double = 0;
                opts.SecondaryNodes(:,4) = [];
                opts.ConstrainedEta(1,:) = [];
                opts.ConstrainedNodes(:,:) = [];
            end
            obj = obj@baff.station.Base(eta);
            N = obj.N;
            % set other properties
            obj.EtaDir = SetStationProp(opts.EtaDir,N);
            obj.StationDir = SetStationProp(opts.StationDir,N);
            obj.Mat = SetStationProp(opts.Mat,N);
            % set optional properties
            obj.Shell = opts.Shell;
            obj.Nodes = opts.Nodes;
            obj.SecondaryEta = opts.SecondaryEta;
            obj.SecondaryNodes = opts.SecondaryNodes;
            obj.ConstrainedEta = opts.ConstrainedEta;
            obj.ConstrainedNodes = opts.ConstrainedNodes;
        end

        function obj = Duplicate(obj,EtaArray)
            %DUPLICATE make copies of a scaler Station
            if obj.N~=1
                error('Length of station obj must be 1')
            end
            obj = baff.station.ShellStation(EtaArray,EtaDir=obj.EtaDir,StationDir=obj.StationDir,Nodes=obj.Nodes,Shell=obj.Shell,Mat=obj.Mat,SecondaryEta=obj.SecondaryEta,SecondaryNodes=obj.SecondaryNodes,ConstrainedNodes=obj.ConstrainedNodes);
        end

        function out = interpolate(obj,N,method,PreserveOld)
            %INTERPOLATE interpolate stations at different etas
            % INTERPOLATE - interpolates in one of three methods depending
            % on "method":
            % "eta": N is an array of etas to interpolate at
            % "linear": N is a scalar of the number of linear distributed
            % points to interpolate at
            %
            % the argument PereserveOld will ensure the original Etas are
            % in the output if set to true (default false)
            arguments
                obj
                N
                method string {mustBeMember(method,["eta","linear"])} = "eta";
                PreserveOld logical = false;
            end

            % calc list of etas
            [etas,idx_low,idx_high,alpha] = obj.InterpolateEtas(N,method,PreserveOld);

            % Create output object
            out = baff.station.ShellStation.ShellStation(etas);

            % Manual linear interpolation for scalar properties
            %- TODO -- implement node + shell interp
            %stations(i).Shell = baff.station.Shell.empty;
            %stations(i).Nodes = [];

            % Direction vectors and materials use "previous" method (no interpolation)
            out.EtaDir = obj.EtaDir(:, idx_low);
            out.StationDir = obj.StationDir(:, idx_low);
            out.Mat = obj.Mat(idx_low);
        end

        function p = draw(obj,opts)
            arguments
                obj
                opts.Origin (3,1) double = [0,0,0];
                opts.A (3,3) double = eye(3);
            end
            p = plot3(opts.Origin(1,:),opts.Origin(2,:),opts.Origin(3,:),'square-');
            p.MarkerFaceColor = 'k';
            p.Color = 'k';
            p.Tag = 'Shell';
        end
    end

    % operator overloading
    methods
        function obj = horzcat(varargin)
            Ni = 0;
            for i = 1:numel(varargin)
                Ni = Ni + varargin{i}.N;
            end
            obj = baff.station.ShellStation.ShellStation.Blank(Ni);
            idx = 1;
            for i = 1:numel(varargin)
                ii = idx:(idx+varargin{i}.N-1);
                idx = ii(end)+1;
                obj.Eta(ii) = varargin{i}.Eta;
                obj.EtaDir(:,ii) = varargin{i}.EtaDir;
                obj.StationDir(:,ii) = varargin{i}.StationDir;
                obj.Mat(ii) = varargin{i}.Mat;
                obj.Nodes = [obj.Nodes; varargin{i}.Nodes];
                obj.Shell = [obj.Shell; varargin{i}.Shell];
                obj.SecondaryEta = [obj.SecondaryEta, varargin{i}.SecondaryEta];
                obj.SecondaryNodes = [obj.SecondaryNodes; varargin{i}.SecondaryNodes];
                obj.ConstrainedEta = [obj.ConstrainedEta, varargin{i}.ConstrainedEta];
                obj.ConstrainedNodes = [obj.ConstrainedNodes, varargin{i}.ConstrainedNodes];
            end
        end

        function val = eq(obj1,obj2)
            val = isa(obj2,'baff.station.ShellStation') && obj1.N == obj2.N && ...
                all(obj1.Eta == obj2.Eta) && all(obj1.EtaDir == obj2.EtaDir,"all") ...
                && all(obj1.StationDir == obj2.StationDir,"all") ...
                && all(obj1.Nodes == obj2.Nodes, "all") ...
                && all(obj1.Shell == obj2.Shell);
        end
    end
end