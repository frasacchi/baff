function v = get_version()
%GET_VERSION Return current baff toolbox version string from version.txt.
here = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
vfile = fullfile(here, 'version.txt');
if isfile(vfile)
    v = strtrim(fileread(vfile));
else
    v = 'unknown';
end
end
