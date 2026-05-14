function ToBaff(obj,filepath,loc)
    %% write mass specific items
    Ne = obj.N;
    if Ne == 0
        h5writeatt(filepath,[loc,'/GBeamStations/'],'Qty', 0);
        return
    end
    h5write(filepath,sprintf('%s/GBeamStations/Eta',loc),obj.Eta,[1 1],[1 Ne]);
    h5write(filepath,sprintf('%s/GBeamStations/EtaDir',loc),obj.EtaDir,[1 1],[3 Ne]);
    h5write(filepath,sprintf('%s/GBeamStations/StationDir',loc),obj.StationDir,[1 1],[3 Ne]);
    h5write(filepath,sprintf('%s/GBeamStations/A',loc),obj.A,[1 1],[1 Ne]);
    h5write(filepath,sprintf('%s/GBeamStations/I',loc),reshape(obj.I,9,[]),[1 1],[9 Ne]);
    h5write(filepath,sprintf('%s/GBeamStations/J',loc),obj.J,[1 1],[1 Ne]);
    h5write(filepath,sprintf('%s/GBeamStations/Tau',loc),reshape(obj.tau,9,[]),[1 1],[9 Ne]);
    h5write(filepath,sprintf('%s/GBeamStations/K45',loc),obj.K45,[1 1],[1 Ne]);

    h5writeatt(filepath,[loc,'/GBeamStations/'],'Qty', Ne);

    %% sort out Material
    Mats = [obj.Mat];
    % only save unique Materials
    [~,ia,ic] = unique([Mats.Hash]);
    Mats(ia).ToBaff(filepath,loc);
    h5writeatt(filepath,sprintf('%s/',loc),'MatsIdx', ic);
end