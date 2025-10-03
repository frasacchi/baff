function TemplateHdf5(filepath,loc)
    %create placeholders
    h5create(filepath,sprintf('%s/BeamStations/Eta',loc),[1 inf],"Chunksize",[1,10]);
    h5create(filepath,sprintf('%s/BeamStations/EtaDir',loc),[3 inf],"Chunksize",[3,10]);
    h5create(filepath,sprintf('%s/BeamStations/StationDir',loc),[3 inf],"Chunksize",[3,10]);
    h5create(filepath,sprintf('%s/BeamStations/A',loc),[1 inf],"Chunksize",[1,10]);
    h5create(filepath,sprintf('%s/BeamStations/I',loc),[9 inf],"Chunksize",[9,10]);
    h5create(filepath,sprintf('%s/BeamStations/J',loc),[1 inf],"Chunksize",[1,10]);
    h5create(filepath,sprintf('%s/BeamStations/Tau',loc),[9 inf],"Chunksize",[9,10]);
    h5create(filepath,sprintf('%s/BeamStations/E',loc),[1 inf],"Chunksize",[1,10]);
    h5create(filepath,sprintf('%s/BeamStations/G',loc),[1 inf],"Chunksize",[1,10]);
    h5create(filepath,sprintf('%s/BeamStations/rho',loc),[1 inf],"Chunksize",[1,10]);
    h5create(filepath,sprintf('%s/BeamStations/nu',loc),[1 inf],"Chunksize",[1,10]);
end

