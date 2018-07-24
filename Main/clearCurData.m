function clearCurData(opts)

tpath = {opts.datasetPath,opts.queriesPath,opts.descPath}; 
for i = 1:numel(tpath)
    delete([tpath{i} '*']);
    rmdir(tpath{i});
end
