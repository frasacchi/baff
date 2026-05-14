function TemplateHdf5(filepath,loc)
    %create placeholders
    h5create(filepath,sprintf('%s/GBeamStations/Eta',loc),[1 inf],"Chunksize",[1,10]);
    h5create(filepath,sprintf('%s/GBeamStations/EtaDir',loc),[3 inf],"Chunksize",[3,10]);
    h5create(filepath,sprintf('%s/GBeamStations/StationDir',loc),[3 inf],"Chunksize",[3,10]);
    h5create(filepath,sprintf('%s/GBeamStations/A',loc),[1 inf],"Chunksize",[1,10]);
    h5create(filepath,sprintf('%s/GBeamStations/I',loc),[9 inf],"Chunksize",[9,10]);
    h5create(filepath,sprintf('%s/GBeamStations/J',loc),[1 inf],"Chunksize",[1,10]);
    h5create(filepath,sprintf('%s/GBeamStations/Tau',loc),[9 inf],"Chunksize",[9,10]);
    h5create(filepath,sprintf('%s/GBeamStations/K45',loc),[1 inf],"Chunksize",[1,10]);
    %create placeholders for materials
    baff.Material.TemplateHdf5(filepath,loc);
end

