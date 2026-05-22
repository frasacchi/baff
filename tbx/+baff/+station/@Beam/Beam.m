classdef Beam < baff.station.Base
    %BEAMSTATION Creates a beam station
    %   x direction along beam

    properties
        A (1,:) double = 1;        % cross sectional area
        I (3,3,:) double = eye(3);   % 2nd Moment of Area tensor
        J (1,:) double = 1         % Torsional Constant
        tau (3,3,:) double = eye(3); % elongation tensor
        Mat = baff.Material.Stiff;
        DMIG = struct('Name',{},'DOFs',{},'A0',{},'B0',{},'IFO',{},'NCOL',{},'A',{},'B',{},'idx0',{},'idx',{}); % Direct Matrix Input - K2GG,M2GG,B2GG
    end
    methods
        function set.A(obj,val)
            if size(val,2)~= obj.N
                error('Columns of A must be equal to one of the number of stations')
            end
            obj.A = val;
        end
        function set.J(obj,val)
            if size(val,2)~= obj.N
                error('Columns of J must be equal to one of the number of stations')
            end
            obj.J = val;
        end
        function set.Mat(obj,val)
            switch size(val,2)
                case obj.N
                    obj.Mat = val;
                case 1
                    obj.Mat = repmat(val,1,obj.N);
                otherwise
                    error('Columns of Mat must be equal to one of the number of stations')
            end
        end
        function set.I(obj,val)
            if size(val,1) ~= 3 || size(val,2) ~= 3
                error('I must must be 3x3xN')
            end
            if size(val,3)~= obj.N
                error('pages of I must be equal to one of the number of stations')
            end
            obj.I = val;
        end
        function set.tau(obj,val)
            if size(val,1) ~= 3 || size(val,2) ~= 3
                error('tau must must be 3x3xN')
            end
            if size(val,3)~= obj.N
                error('pages of tau must be equal to one of the number of stations')
            end
            obj.tau = val;
        end
    end
    methods (Static)
        obj = FromBaff(filepath,loc);
        TemplateHdf5(filepath,loc);
    end
    % constructor
    methods
        function obj = Beam(eta,opts)
            %BEAM - Constructor for a Beam Station
            arguments
                eta
                opts.EtaDir = [1;0;0]
                opts.StationDir = [0;1;0];
                opts.Mat = baff.Material.Stiff;
                opts.A = 1;
                opts.I = eye(3);
                opts.J = 1;
                opts.tau = eye(3);
                opts.DMIG = struct('Name',{},'DOFs',{},'A0',{},'B0',{},'IFO',{},'NCOL',{},'A',{},'B',{},'idx0',{},'idx',{}); % Direct Matrix Input - K2GG,M2GG,B2GG
            end
            obj = obj@baff.station.Base(eta);
            N = obj.N;
            % set other properties
            obj.EtaDir = SetStationProp(opts.EtaDir,N);
            obj.StationDir = SetStationProp(opts.StationDir,N);
            obj.A = SetStationProp(opts.A,N);
            obj.I = SetStationMatrixProp(opts.I,N);
            obj.J = SetStationProp(opts.J,N);
            obj.tau = SetStationMatrixProp(opts.tau,N);
            obj.Mat = SetStationProp(opts.Mat,N);
            obj.DMIG = SetStructDMIG(opts.DMIG,N);
        end
    end
    methods(Static)
        function obj = Blank(N)
            %BLANK Create default station Array of N stations
            obj = baff.station.Beam(zeros(1,N));
        end
    end
    % operator overloading
    methods
        function obj = horzcat(varargin)
            Ni = 0;
            for i = 1:numel(varargin)
                Ni = Ni + varargin{i}.N;
            end
            obj = baff.station.Beam.Blank(Ni);
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
            end
        end
        function val = eq(obj1,obj2)
            val = isa(obj2,'baff.station.Beam') && obj1.N == obj2.N && ...
                all(obj1.Eta == obj2.Eta) && all(obj1.EtaDir == obj2.EtaDir,"all") ...
                && all(obj1.StationDir == obj2.StationDir,"all") && all(obj1.A == obj2.A) ...
                && all(obj1.J == obj2.J) && all(obj1.I == obj2.I,"all") ...
                && all(obj1.tau == obj2.tau,"all");
        end
        function out = GetIndex(obj,i)
            if any(i>obj.N | i<1)
                error('Index must be valid')
            end
            out = baff.station.Beam(obj.Eta(i));
            out.EtaDir = obj.EtaDir(:,i);
            out.StationDir = obj.StationDir(:,i);
            out.A = obj.A(i);
            out.I = obj.I(:,:,i);
            out.J = obj.J(i);
            out.tau = obj.tau(:,:,i);
        end
        function obj = SetIndex(obj,i,val,opts)
            arguments
                obj 
                i 
                val 
                opts.UpdateEta = true;
            end
            if any(i>obj.N | i<1)
                error('Index must be valid')
            end
            if opts.UpdateEta
                obj.Eta(i) = val.Eta;
            end
            obj.EtaDir(:,i) = val.EtaDir;
            obj.StationDir(:,i) = val.StationDir;

            obj.A(i) = val.A;
            obj.J(i) = val.J;
            obj.I(:,:,i) = val.I;
            obj.tau(:,:,i) = val.tau;
            obj.Mat(i) = val.Mat;
        end
    end
    % extra Methods
    methods
        function obj = Duplicate(obj,EtaArray)
            %DUPLICATE make copies of a scaler Station
            if obj.N~=1
                error('Length of station obj must be 1')
            end
            obj = baff.station.Beam(EtaArray,EtaDir=obj.EtaDir,StationDir=obj.StationDir,...
                A=obj.A,I=obj.I,J=obj.J,tau=obj.tau,Mat=obj.Mat);
        end
    
        function [EtaCoM,mass] = GetEtaCoM(obj)
            if obj.N<2
                mass = 0;
                EtaCoM = 0;
                return;
            end
            z = obj.Eta(2:end)-obj.Eta(1:end-1);
            A1 = obj.A(1:end-1);
            A2 = obj.A(2:end);
            rho = [obj.Mat(1:end-1).rho];
            % set default values
            etaCoMs = obj.Eta(1:end-1) + z/2;
            masses = A1.*z.*rho.*vecnorm(obj.EtaDir(:,1:end-1));
            % if a frustrum
            idx = abs(A1-A2)>1e-10;
            if nnz(idx)>0
                A1 = A1(idx);
                A2 = A2(idx);
                z = z(idx);
                z_p = sqrt(A1).*z./(sqrt(A1)-sqrt(A2));
                vol_p = z_p./3.*A1;
                z_bar = z_p-z;
                vol_bar = z_bar./3.*A2;
                vol = vol_p-vol_bar;
                etaCoMs(idx) = (vol_p.*z_p./4-vol_bar.*(z+z_bar./4))./vol + obj.Eta(:,[idx false]);
                masses(idx) = vol.*rho(idx).*vecnorm(obj.EtaDir(:,[idx false]));
            end
            mass = sum(masses);
            if mass == 0
                EtaCoM = 0;
            else
                EtaCoM = sum(masses.*etaCoMs)/mass;
            end
        end

        function mass = GetEtaMass(obj)
            if obj.N<2
                mass = 0;
                return;
            end
            z = obj.Eta(2:end)-obj.Eta(1:end-1);
            A1 = obj.A(1:end-1);
            A2 = obj.A(2:end);
            vol = z/3.*(A1+A2+sqrt(A1.*A2));
            rho = [obj.Mat(1:end-1).rho];
            % set default values
            mass = vol.*rho.*vecnorm(obj.EtaDir(:,1:end-1));
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
            out = baff.station.Beam(etas);
            
            % Manual linear interpolation for scalar properties
            beta = 1-alpha;
            out.A = obj.A(idx_low) .* beta + obj.A(idx_high) .* alpha;
            out.J = obj.J(idx_low) .* beta + obj.J(idx_high) .* alpha;
            
            beta3 = permute(beta,[1,3,2]);
            alpha3 = permute(alpha,[1,3,2]);
            out.I = obj.I(:, :, idx_low) .* beta3 + obj.I(:, :, idx_high) .* alpha3;
            out.tau = obj.tau(:, :, idx_low) .* beta3 + obj.tau(:, :, idx_high) .* alpha3;
            
            % Direction vectors and materials use "previous" method (no interpolation)
            out.EtaDir = obj.EtaDir(:, idx_low);
            out.StationDir = obj.StationDir(:, idx_low);
            out.Mat = obj.Mat(idx_low);

            % DMIG interpolation
            if~isempty(obj.DMIG)
            NCouplings = size(obj.DMIG, 1);  
            for c=1:NCouplings
                DMIG(c) = obj.DMIG(c, 1);
            end
            DMIG  = rmfield(DMIG, {'idx', 'A'});
            out.DMIG = SetStructDMIG(DMIG,length(N));
            end
        end
    end
    methods(Static)
        function obj = Bar(eta,height,width,opts)
            arguments
                eta
                height
                width
                opts.Mat = baff.Material.Stiff;
                opts.EtaDir = [1;0;0];
                opts.DMIG = struct('Name',{},'DOFs',{},'A0',{},'B0',{},'IFO',{},'NCOL',{},'A',{},'B',{},'idx0',{},'idx',{}); % Direct Matrix Input - K2GG,M2GG,B2GG
            end
            Iyy = height^3*width/12;
            Izz = width^3*height/12;
            Ixx = Iyy + Izz;
            if height>=width
                a = height;
                b = width;
            else
                a = width;
                b = height;
            end
            J = a*b^3*(1/3-0.2085*(b/a)*(1-(b^4)/(12*a^4)));
            I = diag([Ixx,Iyy,Izz]);
            obj = baff.station.Beam(eta, I=I, A=height*width, J=J, Mat=opts.Mat,EtaDir=opts.EtaDir, DMIG=opts.DMIG);
        end
        function obj = Rod(eta,diameter,opts)
            arguments
                eta
                diameter
                opts.Mat = baff.Material.Stiff;
                opts.DMIG = struct('Name',{},'DOFs',{},'A0',{},'B0',{},'IFO',{},'NCOL',{},'A',{},'B',{},'idx0',{},'idx',{}); % Direct Matrix Input - K2GG,M2GG,B2GG
            end
            r = diameter/2;
            A = pi*r^2;
            I = pi.*r^4.*diag([0.25,0.25,0.5]);
            J = pi*diameter^4/32;
            obj = baff.station.Beam(eta, I=I, A=A, J=J, Mat=opts.Mat, DMIG=opts.DMIG);
        end
        function obj = Annulus(eta,outer_diameter,inner_diameter,opts)
            arguments
                eta
                outer_diameter
                inner_diameter
                opts.Mat = baff.Material.Stiff;
                opts.DMIG = struct('Name',{},'DOFs',{},'A0',{},'B0',{},'IFO',{},'NCOL',{},'A',{},'B',{},'idx0',{},'idx',{}); % Direct Matrix Input - K2GG,M2GG,B2GG
            end
            r_outer = outer_diameter/2;
            r_inner = inner_diameter/2;
            A = pi*(r_outer^2 - r_inner^2);
            I = pi.*(r_outer^4 - r_inner^4).*diag([0.25,0.25,0.5]);
            J = pi/2*(r_outer^4 - r_inner^4);
            obj = baff.station.Beam(eta, I=I, A=A, J=J, Mat=opts.Mat, DMIG=opts.DMIG);
        end
        function obj = HollowRect(eta,height,width,thickness,opts)
            arguments
                eta
                height
                width
                thickness
                opts.Mat = baff.Material.Stiff;
                opts.DMIG = struct('Name',{},'DOFs',{},'A0',{},'B0',{},'IFO',{},'NCOL',{},'A',{},'B',{},'idx0',{},'idx',{}); % Direct Matrix Input - K2GG,M2GG,B2GG
            end
            if thickness*2>=min(height,width)
                error('Thickness is too large for given dimensions')
            end
            A = height*width - (height-2*thickness)*(width-2*thickness);
            Iyy = (height*width^3 - (height-2*thickness)*(width-2*thickness)^3)/12;
            Izz = (width*height^3 - (width-2*thickness)*(height-2*thickness)^3)/12;
            Ixx = Iyy + Izz;
            if height>=width
                a = height;
                b = width;
            else
                a = width;
                b = height;
            end
            t = thickness;
            J = 2*t^2*(b-t)^2*(a-t)^2/(a*t+b*t-2*t^2);
            I = diag([Ixx,Iyy,Izz]);
            obj = baff.station.Beam(eta, I=I, A=A, J=J, Mat=opts.Mat, DMIG=opts.DMIG);
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
                etaLim = [0,1]
            end
            etas = obj.Eta;
            As = obj.A;
            if any(~ismember(etaLim,etas))
                idx = etas_full>=etaLim(1) & etas_full<=etaLim(2);
                As = [interp1(etas,As,etaLim(1)),As(idx),interp1(etas,As,etaLim(2))];
                etas = [etaLim(1),etas(idx),etaLim(2)];
            end
            A1 = As(2:end);
            A2 = As(1:end-1);
            z = etas(2:end)-etas(1:end-1);
            Vol = 1/3*z.*(A2+sqrt(A2.*A1)+A1);
        end
    end
end

