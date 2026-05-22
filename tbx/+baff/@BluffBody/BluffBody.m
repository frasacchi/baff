classdef BluffBody < baff.Element
    %Baff class to represent a BluffBody Element
    %   This class is used to represent a bluff body element in the baff framework.
    %   It is based on the notion of body stations defined in the Stations property.
    %   These stations describe the variation in properties of a 1D body line through space. Each station describes the properties of the body at a specific normilised point (Eta) along its length.
    properties
        Stations (1,1) baff.station.Body = [baff.station.Body(0),baff.station.Body(1)];  % Body Station properties
    end
    methods(Static)
        obj = FromBaff(filepath,loc);
        TemplateHdf5(filepath,loc);
    end
    methods
        function val = getType(obj)
            %getType returns the type of the object as a string.
            val ="BluffBody";
        end
    end
    methods
        function val = eq(obj1,obj2)
            %overloads the == operator to check the equality of two BluffBody objects.
            if length(obj1)~= length(obj2) || ~isa(obj2,'baff.BluffBody')
                val = false;
                return
            end
            val = eq@baff.Element(obj1,obj2);
            for i = 1:length(obj1)
                val = val && obj1(i).Stations == obj2(i).Stations;
            end
        end
        function out = plus(obj1,obj2)
            %overloads the + operator to concatenate two BluffBody objects.
            if isa(obj2,'baff.BluffBody')
                eta1 = obj1.Stations.Eta;
                eta1 = eta1 - eta1(1);
                eta2 = [obj2.Stations.Eta];
                eta2 = eta2 - eta2(1);
                len1 = eta1(end)*obj1.EtaLength;
                len2 = eta2(end)*obj2.EtaLength;
                newLength = len1 + len2;
                f1 = len1/newLength;
                f2 = len2/newLength;
                % create new body
                out = baff.BluffBody();
                out.Stations = [obj1.Stations*f1,obj2.Stations*f2+f1];
                out.EtaLength = newLength;
            else
                error('Can not add %s to a bluff body',class(obj2))
            end
        end
    end
    methods
        function obj = BluffBody(opts)
            %BLUFFBODY Construct an instance of the BluffBody Baff element class
            arguments
                opts.eta = 0 % Eta value for the bluff body
                opts.Offset = [0;0;0]; % Offset of the bluff body element from its parent
                opts.Name = "Beam" % Name of the bluff body element
                opts.Stations = [baff.station.Body(0),baff.station.Body(1)]; % Body stations to be used for the bluff body element
                opts.EtaLength = 1; % Length of the bluff body element.
            end
            obj = obj@baff.Element(eta=opts.eta,Offset=opts.Offset,Name=opts.Name,EtaLength=opts.EtaLength);
            obj.Stations = opts.Stations;
        end
        function X = GetPos(obj,eta)
            %GetPos returns the position of the bluff body at a given eta.
            %   This function returns the position of the bluff body at a given eta, in the body coordinate system.
            %Returns:
            %   X: position of the bluff body at the given eta, in the body coordinate system
            X = obj.Stations.GetPos(eta)*obj.EtaLength;
        end
        function Area = WettedArea(obj)
            %WettedArea returns the wetted surface area of the bluff body element.
            %Returns:
            %   Area: wetted surface area of the bluff body element
            Area = obj.Stations.NormWettedArea()*obj.EtaLength;            
        end
        function Vol = Volume(obj,etaLims)
            %Volume returns the volume of the bluff body element within specified eta limits.
            %Args:
            %   etaLims: eta limits for volume calculation [default: [0,1]]
            %Returns:
            %   Vol: volume of the bluff body element within the specified limits
            arguments
                obj
                etaLims = [0,1]
            end                
            if isscalar(obj)
                Vol = obj.Stations.NormVolume(etaLims)*obj.EtaLength;
            else
                Vol = zeros(size(obj));
                for i = 1:length(obj)
                    Vol(i) = obj(i).Stations.NormVolume(etaLims)*obj(i).EtaLength;
                end
            end
        end
    end
    methods(Static)
        function obj = FromEta(len,eta,radius,opts)
            %FromEta creates a bluff body element from eta positions and radii.
            %Args:
            %   len: Length of the bluff body element
            %   eta: Eta positions along the body
            %   radius: Radius values at each eta position
            %   opts.Material: Material of the bluff body element [default: baff.Material.Stiff]
            %   opts.Density: Density for station spacing
            %   opts.NStations: Number of stations [default: 10]
            %Returns:
            %   obj: BluffBody object with the specified properties
            arguments
                len (1,1) double
                eta (:,1) double
                radius  (1,:) double
                opts.Material = baff.Material.Stiff;
                opts.Density = nan;
                opts.NStations = 10;
            end
            if isnan(opts.Density) && isnan(opts.NStations)
                error('Either Density of NStations must be non zero')
            end
            
            stations = baff.station.Body(eta,radius=radius,Mat=opts.Material);

            delta = eta(2:end)-eta(1:end-1);
            if ~isnan(opts.NStations)
                Ns = round(delta*(opts.NStations-1)); 
            else
                Ns = round(delta*len/opts.Density);
            end
            if Ns == 0
                Ns = 1;
            end
            tmp_etas = [0];
            for i = 1:(length(eta)-1)
                tmp = linspace(eta(i),eta(i+1),Ns(i)+1);
                tmp_etas = [tmp_etas,tmp(2:end)];
            end
            obj = baff.BluffBody(Stations=stations.interpolate(tmp_etas), EtaLength=len);
        end

        function obj = Cylinder(len,radius,opts)
            %Cylinder creates a cylindrical bluff body element with constant radius.
            %Args:
            %   len: Length of the cylinder
            %   radius: Radius of the cylinder
            %   opts.Material: Material of the cylinder [default: baff.Material.Stiff]
            %   opts.NStations: Number of stations [default: 10]
            %Returns:
            %   obj: BluffBody object representing a cylinder
            arguments
                len
                radius
                opts.Material = baff.Material.Stiff;
                opts.NStations = 10;
            end
            stations = baff.station.Body(linspace(0,1,opts.NStations),radius=radius,Mat=opts.Material);
            obj = baff.BluffBody(Stations=stations, EtaLength=len);
        end

        function obj = SemiSphere(len,radius,opts)
            %SemiSphere creates a semi-spherical bluff body element.
            %Args:
            %   len: Length of the semi-sphere
            %   radius: Maximum radius of the semi-sphere
            %   opts.Material: Material of the semi-sphere [default: baff.Material.Stiff]
            %   opts.NStations: Number of stations [default: 10]
            %   opts.Inverted: Whether the semi-sphere is inverted [default: false]
            %   opts.EtaFrustrum: Eta position for frustrum start [default: 0]
            %Returns:
            %   obj: BluffBody object representing a semi-sphere
            arguments
                len
                radius
                opts.Material = baff.Material.Stiff;
                opts.NStations = 10;
                opts.Inverted = false;
                opts.EtaFrustrum = 0;
            end
            stations = baff.station.Body(linspace(0,1,opts.NStations),radius=radius,Mat=opts.Material);
            dFrustrum = 1-opts.EtaFrustrum;
            if ~opts.Inverted
                rad = @(eta,a,b)b*sin(acos(1-(eta*dFrustrum+opts.EtaFrustrum)));
            else
                rad = @(eta,a,b)b*sin(acos(eta*dFrustrum));
            end
            stations.Radius = rad(stations.Eta,len,radius);
            obj = baff.BluffBody(Stations=stations, EtaLength=len);
        end
        function obj = Parabola(len,radius,opts)
            %Parabola creates a parabolic bluff body element.
            %Args:
            %   len: Length of the parabolic body
            %   radius: Maximum radius of the parabolic body
            %   opts.Material: Material of the parabolic body [default: baff.Material.Stiff]
            %   opts.NStations: Number of stations [default: 10]
            %   opts.Dir: Direction parameter for parabola [default: 0]
            %Returns:
            %   obj: BluffBody object representing a parabolic body
            arguments
                len
                radius
                opts.Material = baff.Material.Stiff;
                opts.NStations = 10;
                opts.Dir = 0;
            end
            etas = linspace(0,1,opts.NStations);
            stations = baff.station.Body(etas,...
                radius=radius*sqrt((etas-opts.Dir)),Mat=opts.Material);
            obj = baff.BluffBody(Stations=stations, EtaLength=len);
        end
        function obj = Cone(len,radius_start,radius_end,opts)
            %Cone creates a conical bluff body element with linearly varying radius.
            %Args:
            %   len: Length of the cone
            %   radius_start: Radius at the start of the cone
            %   radius_end: Radius at the end of the cone
            %   opts.Material: Material of the cone [default: baff.Material.Stiff]
            %   opts.NStations: Number of stations [default: 10]
            %Returns:
            %   obj: BluffBody object representing a cone
            arguments
                len
                radius_start
                radius_end
                opts.Material = baff.Material.Stiff;
                opts.NStations = 10;
            end
            r = linspace(radius_start,radius_end,opts.NStations);
            stations = baff.station.Body(linspace(0,1,opts.NStations),radius=r,Mat=opts.Material);
            obj = baff.BluffBody(Stations=stations, EtaLength=len);
        end
    end
end

