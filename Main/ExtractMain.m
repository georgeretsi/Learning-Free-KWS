% Extract Main

function ExtractMain(opts,isQuery)

% define functions
addpath(genpath(opts.preprocFunctionPath));
addpath(opts.featuresFunctionPath);
if strcmp(opts.descriptor,'POG') 
    if strcmp(opts.method,'Global')
        desc_ref_func = @(I) pog(imresize(I,[50 50],'bilinear'),4); 
    elseif strcmp(opts.method,'GlobalZoned')
        %desc_ref_func = @(I) reshape(word_slw_pog(I,opts.seq(1),opts.seq(2),1),1,[]);
        desc_ref_func = @(I) word_slw_pog(I,opts.seq(1),opts.seq(2),1);
    elseif strcmp(opts.method,'Sequential') %|| strcmp(opts.method,'SequentialB') || strcmp(opts.method,'SequentialBU')
        desc_ref_func = @(I) pog(imresize(I,[50 50],'bilinear'),4); 
        desc_func = @(I,s) word_slw_pog(I,opts.seq(1),opts.seq(2),s);
    end

preprocessing = @(I,l) imgNormalize(I,1.5,l);

% define paths and names
destinationPath = opts.descPath;
if (isQuery)
    imagePath = opts.queriesPath;    
    ismulti = (numel(opts.multi) > 1);
    %if strcmp(opts.method,'SequentialB') || strcmp(opts.method,'SequentialBU')
    %    ismulti = 0;
    %end
    descName = ['queries_' opts.descriptor '_' opts.method '_' num2str(ismulti)];
else 
    imagePath = opts.datasetPath;
    descName = ['words_' opts.descriptor '_' opts.method];
end

if strcmp(opts.method,'Sequential') && isQuery
    lp = opts.multi;
else
    lp = 1;
end

if ~exist(destinationPath,'dir')
    mkdir(destinationPath);
end

if (exist([destinationPath descName '.mat'],'file'))
    delete([destinationPath descName '.mat']);
end

descmat = matfile([destinationPath descName],'Writable',true);

% Extract Features
fnames = dir([imagePath '*.png']);
N = numel(fnames);

descmat.descriptors(1,N) = {[]};
descmat.names(1,N) = {[]};

srd = numel(desc_ref_func(zeros(50))); 

descmat.refDescriptors(1,N) = {[]};

variant = strcmp(opts.method,'Global')|strcmp(opts.method,'GlobalZoned');

sd1 = 0; sd2 = 0;
sample_selection = 0; % SequentialB
if ~variant
    %if strcmp(opts.method,'SequentialB')
    %    sample_selection = 0;
    %else
    if strcmp(opts.method,'Sequential') %|| strcmp(opts.method,'SequentialBU')
        sample_selection = 1-isQuery;
    end
    [sd1,sd2] = size(desc_func(zeros(50),sample_selection)); 
end

% imread outside and batch parallel ??

batchsize = opts.batchsize;%500;

%%% PCA
%rind = randperm(numel(words));
rind = 1:min(N,1000);
trdesc = cell([1 numel(rind)]);%zeros(numel(rind),srd);
tdesc = cell([1 numel(rind)]);

if variant
    
    poolobj = parpool;
    tic;
    cnt = 1;
    while (cnt <= N)
        %if(mod(cnt,1000) == 0)
            disp(['processed images: ' num2str(cnt-1)]);
        %end
        
        range = cnt:min(N,cnt+batchsize-1);
        cnt = cnt + batchsize;    
        tnames = cell([1 numel(range)]);        
        trefdesc = cell([1 numel(range)]); %zeros(numel(range),srd);
        refaspect = zeros(numel(range),1);
        parfor i = 1:numel(range)
            imgName = fnames(range(i)).name;
            tnames{i} = imgName;  
            img = im2double(imread([imagePath imgName]));
            
            timg = preprocessing(img,1);
            refaspect(i) = size(timg,2)/size(timg,1);
            %trefdesc(i,:) = desc_ref_func(timg);
            trefdesc{i} = desc_ref_func(timg);
        end
        tind1 = ismember(range,rind);
        tind2 = ismember(rind,range);
        %trdesc(tind2,:) = trefdesc(tind1,:);
        trdesc(tind2) = trefdesc(tind1);
        
        descmat.refaspect(range,1) = refaspect;
        %descmat.refDescriptors(range,:) = trefdesc;
        descmat.refDescriptors(1,range) = trefdesc;
        descmat.names(1,range) = tnames;
    end
    toc;
    delete(poolobj)
else
    poolobj = parpool;
    tic;
    cnt = 1;
    while (cnt <= N)
        %if(mod(cnt,1000) == 0)
            disp(['processed images: ' num2str(cnt-1)]);
        %end
        
        range = cnt:min(N,cnt+batchsize-1);
        cnt = cnt + batchsize;    
        tnames = cell([1 numel(range)]);
        descriptors = cell([1 numel(range)]);
        trefdesc = cell([1 numel(range)]); %zeros(numel(range),srd);
        refaspect = zeros(numel(range),1);
        parfor i = 1:numel(range)
            imgName = fnames(range(i)).name;
            tnames{i} = imgName;  
            img = im2double(imread([imagePath imgName]));
            timg = preprocessing(img,1);
            refaspect(i) = size(timg,2)/size(timg,1);
            %trefdesc(i,:) = desc_ref_func(timg);
            ldesc = zeros([numel(lp)*sd1 sd2]);
            rdesc = zeros([numel(lp) srd]);
            for j = 1:numel(lp)       
                timg = preprocessing(img,lp(j));
                ldesc(j:numel(lp):end,:) = desc_func(timg,sample_selection); 
                rdesc(j,:) = desc_ref_func(timg);
            end
            descriptors{i} = ldesc;
            trefdesc{i} = rdesc;
        end
        
        tind1 = ismember(range,rind);
        tind2 = ismember(rind,range);
        %trdesc(tind2,:) = trefdesc(tind1,:);
        trdesc(tind2) = trefdesc(tind1);
        tdesc(tind2) = descriptors(tind1);
        
        descmat.refaspect(range,1) = refaspect;
        descmat.descriptors(1,range) = descriptors;
        descmat.refDescriptors(1,range) = trefdesc;
        %descmat.refDescriptors(range,:) = trefdesc;
        descmat.names(1,range) = tnames;
    end
    toc;
    delete(poolobj)
end


% PCA !!!

%{
Aref = []; A = [];
pcaNref = opts.pcaNref; pcaN = opts.pcaN;
if ~isQuery
    %rind = randperm(numel(words));
    rind = 1:min(N,1000);
    
    tdesc = refDescriptors(rind,:);
    Aref = pca(tdesc,'NumComponents',pcaNref);
    refDescriptors = refDescriptors*Aref;
    if ~variant
        tdesc = cat(1,descriptors{rind});
        A = pca(tdesc,'NumComponents',pcaN);
        descriptors = cellfun(@(x) x*A,descriptors,'uniformoutput',0);
    end
    
end
%}

pcaNref = opts.pcaNref; pcaN = opts.pcaN;
if ~isQuery
    descmat.Aref = pca(cat(1,trdesc{:}),'NumComponents',pcaNref);
    %refDescriptors = refDescriptors*Aref;
    if ~variant
        descmat.A = pca(cat(1,tdesc{:}),'NumComponents',pcaN);
        %descriptors = cellfun(@(x) x*A,descriptors,'uniformoutput',0);
    end
    
end

%{
if ~exist(destinationPath,'dir')
    mkdir(destinationPath);
end


if variant
    save([destinationPath descName],'refDescriptors','Aref','names','-v7.3');
else
    save([destinationPath descName],'refDescriptors','Aref','descriptors','A','names','-v7.3');
end
%}
    
end
