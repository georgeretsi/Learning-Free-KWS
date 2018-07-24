function clearAllData()


dnames = dir('./temp*');

for i = numel(dnames)
    tpath = ['./' dnames(i).name '/'];
    delete([tpath '*']);
    rmdir(tpath);
end

end
