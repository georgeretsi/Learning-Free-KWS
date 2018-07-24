function [Pa5,AP] = EvaluateMain(opts)

load([opts.queriesPath 'RelevantList'],'queriesInfo');
qmatname = ['queries_' opts.descriptor '_' opts.method '_' num2str(numel(opts.multi) > 1)];
wmatname = ['words_' opts.descriptor '_' opts.method];
queriesmat = matfile([opts.descPath qmatname]);
wordsmat = matfile([opts.descPath wmatname]);

qnames = queriesmat.names;
N = numel(qnames);
wnames = wordsmat.names;

percRef = opts.percRef;

% Method Variant
variant = strcmp(opts.method,'Global')|strcmp(opts.method,'GlobalB');
ns = opts.seq(2);

wrefaspect = wordsmat.refaspect;

% PCA
Aref = wordsmat.Aref;
if ~variant
    A = wordsmat.A;
end

if exist([opts.descPath 'temp.mat'],'file')
    delete([opts.descPath 'temp.mat']);
end
if strcmp(opts.method,'GlobalB')
    %refNdim = opts.seq(1)*opts.seq(2)*size(Aref,2);
    refNdim = opts.seq(1)*size(Aref,2);
else
    refNdim = size(Aref,2);
end
tmpmat = matfile([opts.descPath 'temp'],'Writable',true);
tmpmat.wRefDescriptors(numel(wnames),refNdim) = 0;
%tmpmat.qRefDescriptors(numel(qnames),size(Aref,2)) = 0;
%tmpmat.wRefDescriptors(1,numel(wnames)) = {[]};
tmpmat.qRefDescriptors(1,numel(qnames)) = {[]};
tmpmat.wDescriptors(1,numel(wnames)) = {[]};
tmpmat.qDescriptors(1,numel(qnames)) = {[]};


batchsize = 200;%opts.batchsize;
% words pca
cnt = 1;
while (cnt <= numel(wnames))
    range = cnt:min(numel(wnames),cnt+batchsize-1);
    cnt = cnt + batchsize;    
    
    %tmpmat.wRefDescriptors(range,:) = wordsmat.refDescriptors(range,:)*Aref;
    %tmpmat.wRefDescriptors(1,range) = cellfun(@(x) x*Aref,wordsmat.refDescriptors(1,range),'uniformoutput',0);
    tmpbatchrefdesc = wordsmat.refDescriptors(1,range);
    if strcmp(opts.method,'GlobalB')
        tmpbatchrefdesc = cellfun(@(x) reshape(x*Aref,1,[]),tmpbatchrefdesc,'uniformoutput',0);
        tmpmat.wRefDescriptors(range,:) = cat(1,tmpbatchrefdesc{:});
    else
        tmpmat.wRefDescriptors(range,:) = cat(1,tmpbatchrefdesc{:})*Aref; 
    end
   
    if ~variant
        tmpmat.wDescriptors(1,range) = cellfun(@(x) x*A,wordsmat.descriptors(1,range),'uniformoutput',0);
    end
end

% queries pca
cnt = 1;
while (cnt <= numel(qnames))
    range = cnt:min(numel(qnames),cnt+batchsize-1);
    cnt = cnt + batchsize;    
    
    %tmpmat.qRefDescriptors(range,:) = queriesmat.refDescriptors(range,:)*Aref;
    if strcmp(opts.method,'GlobalB')
        tmpmat.qRefDescriptors(1,range) = cellfun(@(x) reshape(x*Aref,1,[]),queriesmat.refDescriptors(1,range),'uniformoutput',0);
    else
        tmpmat.qRefDescriptors(1,range) = cellfun(@(x) x*Aref,queriesmat.refDescriptors(1,range),'uniformoutput',0);
    end
    
    if ~variant
        tmpmat.qDescriptors(1,range) = cellfun(@(x) x*A,queriesmat.descriptors(1,range),'uniformoutput',0);
    end
end

wrdesc = tmpmat.wRefDescriptors;
if strcmp(opts.method,'GlobalB')
   lAref = pca(wrdesc,'NumComponents',opts.pcaNref); 
   wrdesc = wrdesc*lAref;
end
if ~variant
    wdesc = tmpmat.wDescriptors;
end

AP = zeros(1,N);
Pa5 = zeros(1,N);



addpath(opts.matchingFunctionPath);
addpath(opts.miscFunctionPath);


tic;
for i = 1:N
    if (mod(i,500) == 0)
        disp(['query: ' num2str(i)]);
        disp(['MAP: ' num2str(mean(AP(1:i)))]);
    end
    
    % Matching
    tcnt = mod(i,opts.batchsize);
    if  tcnt == 1
        iu = min(N,i+opts.batchsize-1);
        %batchtr = tmpmat.qRefDescriptors(i:iu,:);
        batchtr = tmpmat.qRefDescriptors(1,i:iu);
        if ~ variant
            batcht = tmpmat.qDescriptors(1,i:iu);
        end
        batchta = queriesmat.refaspect(i:iu,1);
    end
    if  tcnt == 0
        tcnt = opts.batchsize;
    end
    
    
    %trquery = batchtr(tcnt,:); %queriesmat.refDescriptors(i,:);
    trquery = batchtr{tcnt};
    if strcmp(opts.method,'GlobalB')
        trquery = trquery*lAref;
    end
    
    qaspect = batchta(tcnt);
    %Daspect = pdist2(1/qaspect,1./wrefaspect);
    paspect = ones(size(wrefaspect))';%
    %paspect = 1.2 - .2*gaussmf(wrefaspect,[2 qaspect])';%(1+Daspect);
    
    Dist = pdist2(trquery,wrdesc);
    Dist = min(reshape(Dist,[numel(Dist)/numel(wnames) numel(wnames)]),[],1);
    
    if ~ variant
        [~,sorted_id] = sort(Dist.*paspect);
        tquery = batcht{tcnt};
        %tquery = tquery*A;
        Kbest = round(percRef*numel(wnames));
        f_sorted_id = sorted_id(1:Kbest);
        
        
        wordDescBatch = wdesc(f_sorted_id);
        
        tdist = zeros(1,Kbest);
        for j = 1:Kbest
            %tdesc = wordsmat.descriptors(1,f_sorted_id(j));
            %tdesc = tdesc{1};
            tdesc = wordDescBatch{j};
            if strcmp(opts.method,'Sequential')
                tdist(j) = valid_sequence_weighted_multi(tquery,tdesc,ns); 
            end
            %if strcmp(opts.method,'SequentialB') || strcmp(opts.method,'SequentialBU')
            %    tdist(j) = dtw_c(tquery,tdesc,ns); 
            %end
        end
        

        [~,t_sorted_id] = sort(tdist);
        %[~,t_sorted_id] = sort(tdist.*paspect(f_sorted_id));
        sorted_id = [f_sorted_id(t_sorted_id) sorted_id(Kbest+1:end)];
    else
        [~,sorted_id] = sort(Dist);
    end
    
    % Evaluate 
    tqname = qnames{i}; 
    ii = find(ismember({queriesInfo.name},tqname),1,'first');
    relevant_list = queriesInfo(ii).relevantList;
    swnames = wnames(sorted_id);
    if (~isempty(queriesInfo(ii).self))
        is = ismember(swnames,queriesInfo(ii).self);
        swnames(is) = [];
    end
    ids = ismember(swnames,relevant_list);

    %ids = find(ids);
    %ids = sort(ids);
    
    [AP(i),Pa5(i)] = eval_metrics(ids);
end
toc;

delete([opts.descPath 'temp.mat']);
clear('wdesc');

end
