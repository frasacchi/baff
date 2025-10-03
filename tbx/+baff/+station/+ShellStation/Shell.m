classdef Shell
    properties
        G(4,1) double
        Mat baff.Material
        Thickness double
        ExportType string {mustBeMember(ExportType,["PCOMP","PSHELL"])} = "PSHELL"
        ply baff.station.ShellStation.Ply = baff.station.ShellStation.Ply.empty;
        Tag = "";
    end
    methods (Static)
        % obj = FromBaff(filepath,loc);
        % TemplateHdf5(filepath,loc);
    end
    methods
        function obj = Shell(G,Mat,Thickness,ExportType,opts)
            arguments
                G(4,1) double
                Mat baff.Material
                Thickness double
                ExportType string {mustBeMember(ExportType,["PCOMP","PSHELL"])} = "PSHELL"
                opts.ply baff.station.ShellStation.Ply = baff.station.ShellStation.Ply.empty;
                opts.Tag = "";
            end
            obj.G=G;
            obj.Mat = Mat;
            obj.Thickness = Thickness;
            obj.ExportType = ExportType;
            obj.ply = opts.ply;
            obj.Tag = opts.Tag;
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

