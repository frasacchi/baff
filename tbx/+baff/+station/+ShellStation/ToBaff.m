function ToBaff(obj,filepath,loc)
    %% write mass specific items
    N = length(obj);
    h5writeatt(filepath,[loc,'/BeamStations/'],'Qty', N);
    if N == 0
        return
    end
    h5write(filepath,sprintf('%s/BeamStations/Eta',loc),[obj.Eta],[1 1],[1 N]);
    h5write(filepath,sprintf('%s/BeamStations/EtaDir',loc),[obj.EtaDir],[1 1],[3 N]);
    h5write(filepath,sprintf('%s/BeamStations/StationDir',loc),[obj.StationDir],[1 1],[3 N]);
    h5write(filepath,sprintf('%s/BeamStations/A',loc),[obj.A],[1 1],[1 N]);
    h5write(filepath,sprintf('%s/BeamStations/I',loc),reshape([obj.I],9,[]),[1 1],[9 N]);
    h5write(filepath,sprintf('%s/BeamStations/J',loc),[obj.J],[1 1],[1 N]);
    h5write(filepath,sprintf('%s/BeamStations/Tau',loc),reshape([obj.tau],9,[]),[1 1],[9 N]);
    h5write(filepath,sprintf('%s/BeamStations/E',loc),arrayfun(@(x)x.Mat.E,obj),[1 1],[1 N]);
    h5write(filepath,sprintf('%s/BeamStations/G',loc),arrayfun(@(x)x.Mat.G,obj),[1 1],[1 N]);
    h5write(filepath,sprintf('%s/BeamStations/rho',loc),arrayfun(@(x)x.Mat.rho,obj),[1 1],[1 N]);
    h5write(filepath,sprintf('%s/BeamStations/nu',loc),arrayfun(@(x)x.Mat.nu,obj),[1 1],[1 N]);
end