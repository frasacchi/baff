classdef Beam < baff.Element
    %Baff class to represent a Beam Element
    %   This class is used to represent a beam element in the baff framework.
    %   It is based on the notion of beam stations defined in the Stations property.
    %   These stations describe the variation in properties of a 1D beam line through space. Each station describes the properties of the beam at a specific normilised point (Eta) along its length.
    properties
        Stations (1,1) baff.station.Beam = baff.station.Beam([0,1]);  % Beam Station properties
    end

    methods(Static)
        obj = FromBaff(filepath,loc);
        TemplateHdf5(filepath,loc);
    end
    methods
        function val = getType(obj)
            %getType returns the type of the object as a string.
            val ="Beam";
        end
    end
    methods
        function val = eq(obj1,obj2)
            %overloads the == operator to check the equality of two Beam objects.
            if length(obj1)~= length(obj2) || ~isa(obj2,'baff.Beam')
                val = false;
                return
            end
            val = eq@baff.Element(obj1,obj2);
            for i = 1:length(obj1)
                val = val && obj1(i).Stations == obj2(i).Stations;
            end
        end
        
        function obj = Beam(CompOpts,opts)
            %BEAM Construct an instance of the Beam Baff element class
            arguments
                CompOpts.eta = 0; % Eta value for the beam
                CompOpts.Offset (3,1) double = [0,0,0]; % Offset of the beam element from its parent
                CompOpts.Name = "Beam"; % Name of the beam element
                opts.Stations = baff.station.Beam.empty; % Beam stations to be used for the beam element
                opts.EtaLength (1,1) double = 1; % Length of the beam element.

            end
            CompStruct = namedargs2cell(CompOpts);
            obj = obj@baff.Element(CompStruct{:});
            if ~isempty(opts.Stations)
                obj.Stations = opts.Stations;
            end
            obj.EtaLength = opts.EtaLength;
        end
        function x = GetBeamLength(obj)
            %GetBeamLength returns the length of the beam locus.
            %This is the length of the beam locus. It can be differnt to EtaLength if:
            %- stations Etas do not start and end at 0 and 1
            %- EtaDir at stations is not a unit vector ( useful for swept wings where you want EtaLength to set the span)
            %Returns:
            %   x: length of the beam locus   
            x = zeros(1,length(obj));
            for i = 1:length(obj)
                x(i) = obj(i).Stations.GetLocus()*obj(i).EtaLength;
            end
        end
        function X = GetPos(obj,eta)
            %GetPos returns the position of the beam at a given eta.
            %   This function returns the position of the beam at a given eta, in the beam coordinate system.
            %Returns:
            %   X: position of the beam at the given eta, in the beam coordinate system
            X = obj.Stations.GetPos(eta)*obj.EtaLength;
        end
        function mass = GetElementMass(obj)
            %GetElementMass returns the mass of the beam element (excluding children).
            mass = zeros(size(obj));
            for i = 1:length(obj)
                mass(i) = sum(obj(i).Stations.GetEtaMass().*obj(i).EtaLength);
            end
        end
        function [Xs,masses] = GetElementCoM(obj)
            %GetElementCoM returns the center of mass of the beam element (excluding children).
            masses = zeros(1,length(obj));
            Xs = zeros(3,length(obj));
            for i = 1:length(obj)
                [EtaCoM,mass] = obj(i).Stations.GetEtaCoM();
                masses(i) = mass.*obj(i).EtaLength;
                % Xs(:,i) = obj(i).GetGlobalPos(EtaCoM);
                Xs(:,i) = obj(i).GetPos(EtaCoM);
            end
        end
    end
    methods(Static)
        function obj = Bar(length,height,width,Material)
            %Bar creates a beam element with a rectangular cross section.
            %Args:
            %   length: Length of the beam element
            %   height: Height of teh vbeam cross section
            %   width: Width of the beam cross section
            %   Material: Material of the beam element
            %Returns:
            %   obj: Beam object with the specified properties  
            arguments
                length (1,1) double = 1; % Length of the beam element
                height (1,1) double = 0.1; % Height of the beam element
                width (1,1) double = 0.1; % Width of the beam element
                Material baff.Material = baff.Material(); % Material of the beam element
            end
            obj = baff.Beam();
            obj.EtaLength = length;
            station = baff.BeamStation.Bar(0,height,width,Mat=Material);
            obj.Stations = station.Duplicate([0 1]);
        end
    end
end

