classdef Body < baff.station.Beam
    %BEAMSTATION Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Radius = 1;
    end
    methods
        function set.Radius(obj,val)
            if size(val,1) ~= 1
                error('Radius must have one row')
            end
            switch size(val,2)
                case obj.N
                    obj.Radius = val;
                case 1
                    obj.Radius = repmat(val,1,obj.N);
                otherwise
                    error('Columns of Radius must be equal to one of the number of stations')
            end
        end
    end
    methods (Static)
        obj = FromBaff(filepath,loc);
        TemplateHdf5(filepath,loc);
    end
    % constructor
    methods
        function obj = Body(eta,BodyOpts,opts)
            arguments
                eta
                BodyOpts.radius = 1;
                opts.Mat = baff.Material.Stiff;
                opts.A = 1;
                opts.I = eye(3);
                opts.J = 1;
                opts.tau = eye(3);
                opts.EtaDir = [1;0;0];
                opts.StationDir = [0;1;0];
            end
            args = namedargs2cell(opts);
            obj = obj@baff.station.Beam(eta,args{:});
            obj.Radius = SetStationProp(BodyOpts.radius,obj.N);
        end
    end
    methods(Static)
        function obj = Blank(N)
            %BLANK Create default station Array of N stations
            obj = baff.station.Body(zeros(1,N));
        end
    end
    %operator overloading
    methods
        function obj = horzcat(varargin)
            Ni = 0;
            for i = 1:numel(varargin)
                Ni = Ni + varargin{i}.N;
            end
            obj = baff.station.Body.Blank(Ni);
            idx = 1;
            for i = 1:numel(varargin)
                ii = idx:(idx+varargin{i}.N-1);
                idx = ii(end)+1;
                obj.Eta(ii) = varargin{i}.Eta;
                obj.EtaDir(:,ii) = varargin{i}.EtaDir;
                obj.StationDir(:,ii) = varargin{i}.StationDir;
                obj.A(ii) = varargin{i}.A;
                obj.J(ii) = varargin{i}.J;
                obj.Mat(ii) = varargin{i}.Mat;
                obj.I(:,:,ii) = varargin{i}.I;
                obj.tau(:,:,ii) = varargin{i}.tau;
                obj.Radius(ii) = varargin{i}.Radius;
            end
        end
        function val = eq(obj1,obj2)
            val = isa(obj2,'baff.station.Body') && eq@baff.station.Beam(obj1,obj2) && all(obj1.Radius == obj2.Radius);
        end
        function out = GetIndex(obj,i)
            if any(i>obj.N | i<1)
                error('Index must be valid')
            end
            out = baff.station.Body(obj.Eta(i));
            out.EtaDir = obj.EtaDir(:,i);
            out.StationDir = obj.StationDir(:,i);
            out.A = obj.A(i);
            out.I = obj.I(:,:,i);
            out.J = obj.J(i);
            out.tau = obj.tau(:,:,i);
            out.Radius = obj.Radius(i);
        end
        function obj = SetIndex(obj,i,val)
            if any(i>obj.N | i<1)
                error('Index must be valid')
            end
            obj.Eta(i) = val.Eta;
            obj.EtaDir(:,i) = val.EtaDir;
            obj.StationDir(:,i) = val.StationDir;

            obj.A(i) = val.A;
            obj.J(i) = val.J;
            obj.I(:,:,i) = val.I;
            obj.tau(:,:,i) = val.tau;
            obj.Radius(i) = val.Radius;
        end
    end
    methods
        function obj = Duplicate(obj,EtaArray)
            %DUPLICATE make copies of a scaler Station
            if obj.N~=1
                error('Length of station obj must be 1')
            end
            obj = baff.station.Body(EtaArray,EtaDir=obj.EtaDir,StationDir=obj.StationDir,...
                A=obj.A,I=obj.I,J=obj.J,tau=obj.tau,Mat=obj.Mat,radius=obj.Radius);
        end

        function Vol = NormVolume(obj,etaLim)
            arguments
                obj
                etaLim = [0,1]
            end
            Vol = sum(NormVolumes(obj,etaLim));
        end
        function Vol = NormVolumes(obj,etaLim)
            arguments
                obj
                etaLim = [nan,nan]
            end
            etas = obj.Eta;
            Rs = obj.Radius;
            if ~isnan(etaLim(1))
                idx = etas>etaLim(1) & etas<etaLim(2);
                Rs = [interp1(etas,Rs,etaLim(1)),Rs(idx),interp1(etas,Rs,etaLim(2))];
                etas = [etaLim(1),etas(idx),etaLim(2)];
            end
            A1 = Rs(2:end);
            A2 = Rs(1:end-1);
            z = etas(2:end)-etas(1:end-1);
            Vol = 1/3*z*pi.*(A2.^2+A2.*A1+A1.^2);
        end
        function Area = NormWettedArea(obj)
            etas = obj.Eta;
            Rs = obj.Radius;
            span = etas(2:end)-etas(1:end-1);
            Area = sum(span.*pi.*(Rs(1:end-1)+Rs(2:end)));
            % add area at start and end
            Area = Area + pi*Rs(1)^2 + pi*Rs(end)^2;
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
            out = baff.station.Body(etas);

            % Manual linear interpolation for scalar properties
            beta = 1-alpha;
            out.A = obj.A(idx_low) .* beta + obj.A(idx_high) .* alpha;
            out.J = obj.J(idx_low) .* beta + obj.J(idx_high) .* alpha;
            out.Radius = obj.Radius(idx_low) .* beta + obj.Radius(idx_high) .* alpha;

            beta3 = permute(beta,[1,3,2]);
            alpha3 = permute(alpha,[1,3,2]);
            out.I = obj.I(:, :, idx_low) .* beta3 + obj.I(:, :, idx_high) .* alpha3;
            out.tau = obj.tau(:, :, idx_low) .* beta3 + obj.tau(:, :, idx_high) .* alpha3;

            % Direction vectors and materials use "previous" method (no interpolation)
            out.EtaDir = obj.EtaDir(:, idx_low);
            out.StationDir = obj.StationDir(:, idx_low);
            out.Mat = obj.Mat(idx_low);
        end
    end
end

