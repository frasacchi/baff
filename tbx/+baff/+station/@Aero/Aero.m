classdef Aero < baff.station.Base  
    %BEAMSTATION Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Chord = 1;
        Twist = 0;
        BeamLoc = 0.25;
        Airfoil = baff.Airfoil.NACA_sym;
        ThicknessRatio = 0.12;
        LiftCurveSlope = 2*pi;

        %inertial properties
        LinearDensity  = 0;               % wings linear density
        LinearInertia (3,3,:) double = zeros(3);  % spanwise moment of inertia matrix
        MassLoc = 0.5;                   %location of mass as percentage of chord
    end
    methods
        function set.Chord(obj,val)
            if size(val,2)~= obj.N
                error('Columns of Chord must be equal to one of the number of stations')
            end
            obj.Chord = val;
        end
        function set.Twist(obj,val)
            if size(val,2)~= obj.N
                error('Columns of Twist must be equal to one of the number of stations')
            end
            obj.Twist = val;
        end
        function set.BeamLoc(obj,val)
            if size(val,2)~= obj.N
                error('Columns of BeamLoc must be equal to one of the number of stations')
            end
            obj.BeamLoc = val;
        end
        function set.Airfoil(obj,val)
            switch size(val,2)
                case obj.N
                    obj.Airfoil = val;
                case 1
                    obj.Airfoil = repmat(val,1,obj.N);
                otherwise
                    error('Columns of Airfoil must be equal to one of the number of stations')
            end
        end
        function set.LinearDensity(obj,val)
            if size(val,2)~= obj.N
                error('Columns of LinearDensity must be equal to one of the number of stations')
            end
            obj.LinearDensity = val;
        end
        function set.LinearInertia(obj,val)
            if size(val,3)~= obj.N
                error('pages of LinearInertia must be equal to one of the number of stations')
            end
            obj.LinearInertia = val;
        end
        function set.MassLoc(obj,val)
            if size(val,2)~= obj.N
                error('Columns of MassLoc must be equal to one of the number of stations')
            end
            obj.MassLoc = val;
        end
    end
    
    methods (Static)
        obj = FromBaff(filepath,loc);
        TemplateHdf5(filepath,loc);
    end
    methods
        function obj = Aero(eta,chord,beamLoc,opts)
            %AERO - constructor for an Aero wing Station
            arguments
                eta
                chord = 1;
                beamLoc = 0.25;
                opts.Twist = 0;
                opts.EtaDir = [1;0;0];
                opts.StationDir = [0;1;0];
                opts.Airfoil = baff.Airfoil.NACA_sym;
                opts.ThicknessRatio = 1;
                opts.LiftCurveSlope = 2*pi;
                opts.LinearDensity = 0;
                opts.MassLoc = 0.5;
                opts.LinearInertia = zeros(3);
            end
            obj = obj@baff.station.Base(eta);
            N = obj.N;
            obj.Chord = SetStationProp(chord,N);
            obj.BeamLoc = SetStationProp(beamLoc,N);
            obj.Twist = SetStationProp(opts.Twist,N);
            obj.EtaDir = SetStationProp(opts.EtaDir,N);
            obj.StationDir = SetStationProp(opts.StationDir,N);
            obj.Airfoil = SetStationProp(opts.Airfoil,N);
            obj.ThicknessRatio = SetStationProp(opts.ThicknessRatio,N);
            obj.LiftCurveSlope = SetStationProp(opts.LiftCurveSlope,N);
            obj.LinearInertia = SetStationMatrixProp(opts.LinearInertia,N);
            obj.MassLoc = SetStationProp(opts.MassLoc,N);
            obj.LinearDensity = SetStationProp(opts.LinearDensity,N);
        end
    end
    methods(Static)
        function obj = Blank(N)
            %BLANK Create default station Array of N stations
            obj = baff.station.Aero(zeros(1,N));
        end
    end
    % operator overloading
    methods
        function obj = horzcat(varargin)
            Ni = 0;
            for i = 1:numel(varargin)
                Ni = Ni + varargin{i}.N;
            end
            obj = baff.station.Aero.Blank(Ni);
            idx = 1;
            for i = 1:numel(varargin)
                ii = idx:(idx+varargin{i}.N-1);
                idx = ii(end)+1;
                obj.Eta(ii) = varargin{i}.Eta;
                obj.EtaDir(:,ii) = varargin{i}.EtaDir;
                obj.StationDir(:,ii) = varargin{i}.StationDir;
                obj.Chord(ii) = varargin{i}.Chord;
                obj.Twist(ii) = varargin{i}.Twist;
                obj.BeamLoc(ii) = varargin{i}.BeamLoc;
                obj.Airfoil(ii) = varargin{i}.Airfoil;
                obj.ThicknessRatio(ii) = varargin{i}.ThicknessRatio;
                obj.LiftCurveSlope(ii) = varargin{i}.LiftCurveSlope;
                obj.LinearDensity(ii) = varargin{i}.LinearDensity;
                obj.LinearInertia(:,:,ii) = varargin{i}.LinearInertia;
                obj.MassLoc(ii) = varargin{i}.MassLoc;
            end
        end
        function val = eq(obj1,obj2)
            val = isa(obj2,'baff.station.Aero') && obj1.N == obj2.N && ...
                all(obj1.Eta == obj2.Eta) && all(obj1.EtaDir == obj2.EtaDir,"all") ...
                && all(obj1.Chord == obj2.Chord) && all(obj1.Twist == obj2.Twist) ...
                && all(obj1.BeamLoc == obj2.BeamLoc) && all(obj1.Airfoil == obj2.Airfoil) ...
                && all(obj1.ThicknessRatio == obj2.ThicknessRatio) && all(obj1.LiftCurveSlope == obj2.LiftCurveSlope) ...
                && all(obj1.LinearDensity == obj2.LinearDensity) && all(obj1.LinearInertia == obj2.LinearInertia,"all") ...
                && all(obj1.MassLoc == obj2.MassLoc) && all(obj1.StationDir == obj2.StationDir,"all");
        end 
        function out = GetIndex(obj,i)
            if any(i>obj.N | i<1)
                error('Index must be valid')
            end
            out = baff.station.Aero(obj.Eta(i));
            out.EtaDir = obj.EtaDir(:,i);
            out.StationDir = obj.StationDir(:,i);

            out.Chord = obj.Chord(i);
            out.BeamLoc = obj.BeamLoc(i);
            out.Twist = obj.Twist(i);
            out.Airfoil = obj.Airfoil(i);
            out.ThicknessRatio = obj.ThicknessRatio(i);
            out.LiftCurveSlope = obj.LiftCurveSlope(i);
            out.LinearDensity = obj.LinearDensity(i);
            out.LinearInertia = obj.LinearInertia(:,:,i);
            out.MassLoc = obj.MassLoc(i);
        end
        function obj = SetIndex(obj,i,val)
            if any(i>obj.N | i<1)
                error('Index must be valid')
            end
            obj.Eta(i) = val.Eta;
            obj.EtaDir(:,i) = val.EtaDir;
            obj.StationDir(:,i) = val.StationDir;
            
            obj.Chord(i) = val.Chord;
            obj.BeamLoc(i) = val.BeamLoc;
            obj.Twist(i) = val.Twist;         
            obj.Airfoil(i) = val.Airfoil;
            obj.ThicknessRatio(i) = val.ThicknessRatio;
            obj.LiftCurveSlope(i) = val.LiftCurveSlope;
            obj.LinearDensity(i) = val.LinearDensity;
            obj.LinearInertia(:,:,i) = val.LinearInertia;
            obj.MassLoc(i) = val.MassLoc;
        end
    end
    methods
        function obj = Duplicate(obj,EtaArray)
            %DUPLICATE make copies of a scaler Station
            if obj.N~=1
                error('Length of station obj must be 1')
            end
            obj = baff.station.Aero(EtaArray,obj.Chord,obj.BeamLoc,Twist=obj.Twist,...
                EtaDir=obj.EtaDir,StationDir=obj.StationDir,Airfoil=obj.Airfoil,...
                ThicknessRatio=obj.ThicknessRatio,LiftCurveSlope=obj.LiftCurveSlope,...
                LinearDensity=obj.LinearDensity,LinearInertia=obj.LinearInertia,MassLoc=obj.MassLoc);
        end
        function val = HasMass(obj)
            %HASMASS - returns boolean value dependent on if stations have mass
            val = any(obj.LinearDensity > 0) | any(obj.LinearInertia > 0);
        end
        function out = interpolate(obj,N,method,PreserveOld)
            %INTERPOLATE interpolate stations at different etas
            % INTERPOLATE - interpolates in one of three methods depending
            % on "method":
            % "eta": N is an array of etas to interpolate at
            % "linear": N is a scalar of the number of linear distributed
            % points to interpolate at
            % "cosine": same as linear but with cosine distribution
            %
            % the argument PereserveOld will ensure the original Etas are
            % in the output if set to true (default false)
            arguments
                obj
                N
                method string {mustBeMember(method,["eta","linear","cosine"])} = "eta";
                PreserveOld logical = false;
            end
            % calc list of etas
            [etas,idx_low,idx_high,alpha] = obj.InterpolateEtas(N,method,PreserveOld);

            out = baff.station.Aero(etas);
            beta = 1-alpha;
            out.Chord = obj.Chord(idx_low) .* beta + obj.Chord(idx_high) .* alpha;
            out.BeamLoc = obj.BeamLoc(idx_low) .* beta + obj.BeamLoc(idx_high) .* alpha;
            out.Twist = obj.Twist(idx_low) .* beta + obj.Twist(idx_high) .* alpha;
            out.EtaDir = obj.EtaDir(:,idx_low);
            out.StationDir = obj.StationDir(:,idx_low);
            out.Airfoil = obj.Airfoil(idx_low);
            out.ThicknessRatio = obj.ThicknessRatio(idx_low) .* beta + obj.ThicknessRatio(idx_high) .* alpha;
            out.LiftCurveSlope = obj.LiftCurveSlope(idx_low);
            out.LinearDensity = obj.LinearDensity(idx_low) .* beta + obj.LinearDensity(idx_high) .* alpha;
            out.LinearInertia = obj.LinearInertia(:,:,idx_low) .* permute(beta,[1,3,2]) + obj.LinearInertia(:,:,idx_high) .* permute(alpha,[1,3,2]);
            out.MassLoc = obj.MassLoc(idx_low) .* beta + obj.MassLoc(idx_high) .* alpha;
        end
        function X = GetPos(obj,eta,pChord)
            %GETPOS - gets Norm. X pos of a point and eta and pChord % Chord
            arguments
                obj baff.station.Aero
                eta (1,:) double
                pChord (1,:) double
            end
            if ~isscalar(eta) && ~isscalar(pChord)
                error("Either pChord or Eta must be Scalar, Otherwise output order would be unknown")
            end
            
            if obj.N == 1
                stDir = obj.StationDir;
                chord = obj.Chord;
                beamLoc = obj.BeamLoc;
                twist = obj.Twist;
                etaDir = obj.EtaDir;
            else
                [ii,idx] = ismember(eta,obj.Eta);
                if all(ii)
                    stDir = obj.StationDir(:,idx);
                    chord = obj.Chord(idx);
                    beamLoc = obj.BeamLoc(idx);
                    twist = obj.Twist(idx);
                    etaDir = obj.EtaDir(:,idx);
                else
                    [~,idx_low,idx_high,alpha] = obj.InterpolateEtas(eta);
                    beta = 1-alpha;
                    
                    stDir = obj.StationDir(:,idx_low);
                    chord = obj.Chord(idx_low) .* beta + obj.Chord(idx_high) .* alpha;
                    beamLoc = obj.BeamLoc(idx_low) .* beta + obj.BeamLoc(idx_high) .* alpha;
                    twist = obj.Twist(idx_low) .* beta + obj.Twist(idx_high) .* alpha;
                    etaDir = obj.EtaDir(:,idx_low);
                end
            end
            
            stDir = stDir./vecnorm(stDir);
            z = cross(etaDir./vecnorm(etaDir), stDir);
            perp = cross(stDir,z);
            
            if isscalar(eta)
                points = repmat(stDir,1,length(pChord)).*(beamLoc - pChord);
                X = dcrg.geom.Rodrigues(perp,deg2rad(twist))*points.*chord;
            else
                points = stDir.*(beamLoc - pChord).*chord;
                X = pagemtimes(dcrg.geom.Rodrigues(reshape(perp,3,1,[]),reshape(deg2rad(twist),1,1,[])),reshape(points,3,1,[]));
                X = reshape(X,3,[]);
            end
        end
        function area = GetNormArea(obj)
            %GETNORMAREA - Gets span normalised planfrom area
            area = sum(obj.GetNormAreas);
        end
        function areas = GetNormAreas(obj)
            %GETNORMAREAs - Gets span normalised planfrom areas between each station
            if obj.N<2
                areas = 0;
                return
            end
            spans = obj.Eta(2:end)-obj.Eta(1:end-1);
            mChord = (obj.Chord(2:end)+obj.Chord(1:end-1))/2;
            areas = mChord.*spans;
        end

        function areas = GetNormWettedAreas(obj)
            %GetNormWettedAreas - gets span normailsed surface area of wing sections
            if length(obj)<2
                areas = 0;
                return
            end
            perimeters = obj.Airfoil.Perimeter(obj.Chord,obj.ThicknessRatio);
            deltaEta = obj.Eta(2:end)-obj.Eta(1:end-1);
            areas = 0.5*(perimeters(1:end-1)+perimeters(2:end)).*deltaEta;
        end
        function area = GetNormWettedArea(obj)
            %GetNormWettedArea - gets span normailsed surface area of wing
            area = sum(obj.GetNormWettedAreas);
        end
        function area = getSubNormArea(obj,x)
            %getSubNormArea - gets span normalised planform area upto an eta of x
            Etas = obj.Eta;
            area = obj.interpolate([Etas(Etas<x),x]).GetNormArea();
        end
        function c_bar = GetMeanChord(obj)
            %GetMeanChord - Wing mean chord
            c_bar = GetNormArea(obj)./(obj.Eta(end) - obj.Eta(1));
        end
        function [mgc,eta_mgc] = GetMGC(obj,target)
            %GETMGCS - get wing mean geometric chord
            % MGC is the chord at half wing section area.
            arguments
                obj
                target = 0.5
            end
            area = obj.GetNormArea();
            etas = obj.Eta;
            chords = obj.Chord;
            function a = half_area(x)
                chord_i = interp1(etas,chords,x);
                ei = [etas(etas<x),x];
                ci = [chords(etas<x),chord_i];
                a = trapz(ei,ci); 
            end
            eta_mgc = fminsearch(@(x)(half_area(max(x,0.01))/area-target)^2,target);
            mgc = obj.interpolate(eta_mgc).Chord;
        end
        
        function [mgcs,thicknessRatios] = GetMGCs(obj)
            %GETMGCS - get wing mean geometric chord between each station
            % MGC is the chord at half wing section area.
            tr = obj.Chord(2:end)./obj.Chord(1:end-1);
            mgcs = 2/3*obj.Chord(1:end-1).*(1+tr+tr.^2)./(1+tr);
            thicknessRatios = (obj.ThicknessRatio(1:end-1) + obj.ThicknessRatio(2:end))/2;
        end

        function vol = GetNormVolume(obj,cEtas,Etas)
            %GETNORMVOLUME get wing normalised volume
            % get wing norm. volume with arguments
            % - cEtas (Default = [0 1]): chordwise pos to integrate between
            % - Etas (Default [nan nan]): spanwise pos to integrate. nan
            % mean take min / max value of stations.
            arguments
                obj
                cEtas (1,2) double = [0 1]
                Etas (1,2) double = [nan nan]
            end
            vol = sum(obj.GetNormVolumes(cEtas,Etas));
        end
        function vols = GetNormVolumes(obj,cEtas,Etas)
            %GETNORMVOLUME get wing normalised volumes
            % get wing norm. volumes with arguments
            % - cEtas (Default = [0 1]): chordwise pos to integrate between
            % - Etas (Default [nan nan]): spanwise pos to integrate. nan
            % mean take min / max value of stations.
            arguments
                obj
                cEtas (1,2) double = [0 1]
                Etas (1,2) double = [nan nan]
            end
            if obj.N<2
                vols = 0;
                return
            end
            if ~isnan(Etas(1))
                idx = obj.Eta>Etas(1) & obj.Eta<Etas(2);
                obj = obj.interpolate([Etas(1),obj.Eta(idx),Etas(2)]);
            end
            A = obj.Airfoil.Area(obj.Chord,obj.ThicknessRatio,cEtas');
            A1 = A(2:end);
            A2 = A(1:end-1);
            z = obj.Eta(2:end)-obj.Eta(1:end-1);
            vols = 1/3*z.*(A2+sqrt(A2.*A1)+A1);
        end
    end
end

