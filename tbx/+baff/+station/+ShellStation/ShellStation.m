classdef ShellStation
    properties
        Eta1 = 0;
        Eta2 = 1;
        EtaDir = [1;0;0];
        StationDir = [0;1;0];
        Origin = 0;
        nodes(:,3) double = [];
        Shell(:,1) baff.station.ShellStation.Shell = baff.station.ShellStation.Shell.empty;
    end
    % methods (Static)
    %     obj = FromBaff(filepath,loc);
    %     TemplateHdf5(filepath,loc);
    % end
    methods

        function out = plus(obj,delta_eta)
            if length(delta_eta) == 1
                delta_eta = repmat(delta_eta,1,length(obj));
            end
            if length(obj) == 1
                out = repmat(obj,1,length(delta_eta)-1);
            elseif length(delta_eta) ~= length(obj)+1
                error('length of obj must be 1 or equal to length of delta_eta')
            else
                out = obj;
            end
            for i = 1:length(delta_eta)-1
                out(i).Eta1 = out(i).Eta1 + delta_eta(i);
                out(i).Eta2 = out(i).Eta1 + (delta_eta(i+1)-delta_eta(i));
            end

        end

        function out = minus(obj,delta_eta)
            if length(delta_eta) == 1
                delta_eta = repmat(delta_eta,1,length(obj));
            end
            if length(obj) == 1
                out = repmat(obj, 1, length(delta_eta) - 1);
            elseif length(delta_eta) ~= length(obj) + 1
                error('For array operations, length of delta_eta must be one greater than length of obj.');
            else
                out = obj;
            end
            %- TODO -- Fix minus logic!
            for i = 1:length(delta_eta) - 1
                out(i).Eta1 = out(i).Eta1 - delta_eta(i);
                out(i).Eta2 = out(i).Eta2 - delta_eta(i+1);
            end
        end

        function obj = ShellStation(eta,opts)
            arguments
                eta
                opts.EtaDir = [1;0;0]
                opts.StationDir = [0;1;0];
                opts.Origin = 0;
                opts.nodes(:,3) double = [];
                opts.Shell(:,1) baff.station.ShellStation.Shell = baff.station.ShellStation.Shell.empty;
            end
            obj.Eta1 = eta(1);
            obj.Eta2 = eta(2);
            obj.EtaDir = opts.EtaDir;
            obj.StationDir = opts.StationDir;
            obj.Origin = opts.Origin;
            obj.Shell = opts.Shell;
            obj.nodes = opts.nodes;
        end

        function stations = interpolate(obj,etas)
            old_eta = [obj.Eta1];
            EtaDirs = interp1(old_eta,[obj.EtaDir]',etas,"previous")';
            StationDirs = interp1(old_eta,[obj.StationDir]',etas,"previous")';

            stations = baff.station.ShellStation.empty;
            for i = 1:length(etas)-1
                stations(i).Eta1 = etas(i);
                stations(i).Eta2 = etas(i+1);
                stations(i).EtaDir = EtaDirs(:,i);
                stations(i).StationDir = StationDirs(:,i);

                %- TODO -- implement node + shell interp
                stations(i).Shell = baff.station.Shell.empty;
                stations(i).nodes = [];
            end
        end

        function p = draw(obj,opts)
            arguments
                obj
                opts.Origin (3,1) double = [0,0,0];
                opts.A (3,3) double = eye(3);
            end
            p = plot3(opts.Origin(1,:),opts.Origin(2,:),opts.Origin(3,:),'o');
            p.MarkerFaceColor = 'c';
            p.Color = 'c';
            p.Tag = 'Beam';
        end
    end
end

