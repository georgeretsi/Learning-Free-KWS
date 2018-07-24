function opts = loadModernICFHR14(path)

% e.g. : path = '/home/george/Desktop/WS_Journal_Experiments/Modern/'
opts.dataset = 'ModernICFHR14';

opts.datasetPath = ['./temp_' opts.dataset '_words/'];
opts.queriesPath = ['./temp_' opts.dataset '_queries/'];

if ~exist(opts.datasetPath,'dir')
    mkdir(opts.datasetPath);
    
    wpath = [path 'TRACK_I_Modern_Dataset/'];
    fnames = dir([wpath '*.xml']);

    cnt = 1;
    for i = 1:numel(fnames)    
        xml_name = fnames(i).name;

        name_c = strsplit(xml_name,'.');
        name = name_c{1};    

        I = imread([wpath name '.tif']);

        filetext = fileread([wpath xml_name]);
        str_id = regexp(filetext,'(?<=id="[^\w]*)(\w*)-(\w*)','match');
        x = cellfun(@str2num,regexp(filetext,'(?<=x="[^\w]*)([0-9]*)','match'));
        y = cellfun(@str2num,regexp(filetext,'(?<=y="[^\w]*)([0-9]*)','match'));
        w = cellfun(@str2num,regexp(filetext,'(?<=width="[^\w]*)([0-9]*)','match'));
        h = cellfun(@str2num,regexp(filetext,'(?<=height="[^\w]*)([0-9]*)','match'));
        for j = 1:numel(str_id)
            timg = I(y(j):y(j)+ h(j),x(j):x(j)+ w(j));
            if (numel(timg) < 1000)
                continue;
            end

            iname = [sprintf('%.6d',cnt) '.png'];
            imwrite(timg,[opts.datasetPath iname]);
            words(cnt).iname = iname;
            words(cnt).id = str_id{j};
            
            did = regexp(words(cnt).id,'(\w*)(?=-)','match');
            words(cnt).name = strjoin({did{1},num2str(x(j)),num2str(y(j)),num2str(w(j)),num2str(h(j))},'-');
            
            cnt = cnt+1;     
        end
    end
    

    save([opts.datasetPath 'tmpwordstruct'],'words');
end

if ~exist(opts.queriesPath,'dir')
    mkdir(opts.queriesPath);
    
    
    qpath = [path, 'ICFHR2014_TRACK_I_Modern_Queries/images/'];
    fnames = dir([qpath '*.png']);
    
    for i = 1:numel(fnames)
        
        tname = fnames(i).name;
        timg = rgb2gray(imread([qpath tname]));
        name_c = strsplit(tname,'.');
        name = name_c{1}; 
        queries(i).id = name;
        
        iname = [sprintf('q%.6d',i) '.png'];
        imwrite(timg,[opts.queriesPath iname]);
        queries(i).iname = iname;
    end
    
    gt_xml = 'TRACK_I_Modern_ICFHR2014.RelevanceJudgements.xml';
    filetext = fileread([path gt_xml]);
    
    s = strfind(filetext,'<GTRel');
    e = strfind(filetext,'</GTRel>');


    for i = 1:numel(s)

        tmp_text = filetext(s(i):(e(i)-1));

        q_id = regexp(tmp_text,'(?<=queryid="[^\w]*)(\w*)','match');

        str_id = regexp(tmp_text,'(?<=document="[^\w]*)(\w*)','match');
        x = regexp(tmp_text,'(?<=x="[^\w]*)([0-9]*)','match');
        y = regexp(tmp_text,'(?<=y="[^\w]*)([0-9]*)','match');
        w = regexp(tmp_text,'(?<=width="[^\w]*)([0-9]*)','match');
        h = regexp(tmp_text,'(?<=height="[^\w]*)([0-9]*)','match');

        xml_dat = [str_id ; x ; y ; w ; h];

        clear qnames;
        for j = 1:numel(x)
           qnames{j} = strjoin(xml_dat(:,j)','-'); 
        end

        gt_queries(i).id = q_id{1};
        gt_queries(i).relevant_list = qnames;
    end
    
    load([opts.datasetPath 'tmpwordstruct']);
    winames = {words.iname};
    wnames = {words.name};
    for i = 1:numel(queries)
        ii = find(ismember({gt_queries.id},queries(i).id),1,'first'); 
        rel_list = ismember(wnames,gt_queries(ii).relevant_list);
        
        queriesInfo(i).relevantList = winames(rel_list); 
        queriesInfo(i).name = queries(i).iname;
        queriesInfo(i).self = [];
    end
    
    save([opts.queriesPath 'RelevantList'],'queriesInfo');
end