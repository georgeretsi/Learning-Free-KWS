function I = delete_unwanted_cc(I)

level = graythresh(I)-.1;
bw = im2bw(I,level); % !!!!
%figure(1); imshow(I);
bw = imclose(bw,strel('disk',1));
%figure(2); imshow(bw);
CC= bwconncomp(bw);

stats = regionprops(CC,'Area','MajorAxisLength','MinorAxisLength','Orientation');
cc_areas = [stats.Area];

% vertical or horizontal useless lines
cc_pr = cc_areas./(([stats.MajorAxisLength]).*([stats.MinorAxisLength]));
% vertical condition
condv = ((abs([stats.Orientation]-90) < 5) | (abs([stats.Orientation]+90) < 5)) & ([stats.MajorAxisLength] > .95*size(bw,1));
% horizontal condition
condh =  (abs([stats.Orientation]) < 5) & ([stats.MajorAxisLength] > .95*size(bw,2));
vhid = (condv | condh) & (cc_pr > .7);

% throw away small ccs
id = cc_areas < .001*numel(bw);
%id = cc_areas < .2*median(cc_areas(vhid));
id = id | vhid;
cc_areas = cc_areas(~id);
bw(cat(1,CC.PixelIdxList{id})) = 0;

I(cat(1,CC.PixelIdxList{id})) = 0;


N = sum(1-id);
CC.NumObjects = N;
CC.PixelIdxList = CC.PixelIdxList(~id);
%cc_pxls = CC.PixelIdxList;

% is bound and CC corresponding??
%bound = bwboundaries(bw,'noholes');
%for i = 1:N
%    [y,x] =  ind2sub(size(bw),cc_pxls{i});
%    cc_pxls{i} = [y x]; 
%end

%distMat = zeros(N);
%for i = 1:N    
%    distMat(i,:) = cellfun(@(a) min(min(pdist2(cc_pxls{i},a))),cc_pxls); 
%end

L = labelmatrix(CC);

%%{
nLabels = max(L(:));

if (nLabels >= 1)

    %// find the distance between each label and all other labels

    distMat = zeros(nLabels, nLabels);

    for iLabel = 1:nLabels
        %// distance transform - every pixel is the distance to the nearest 
        %//   non-zero pixel, i.e. the location of label iLabel

        %dist = bwdist(L==iLabel);
        dist = graydist(1-I,L==iLabel,'quasi-euclidean');

        %// use accumarray b/c we can
        %// get rid of the zeros in labeledImage, though, as there is no index 0

        distMat(:,iLabel) = accumarray(L(L>0),dist(L>0),[],@min);
    end
    %%}

    thres = .1*size(bw,2);



    Adj = distMat > 0 & distMat < thres;
    G = sparse(Adj);
    [~,lid] = graphconncomp(G);

    nn = max(lid);
    for i = 1:nn
        tid = lid == i;
        acArea(i) = sum(cc_areas(tid)); 
    end

    [~,mi] = max(acArea);

    for i = 1:N
        if (lid(i) ~= mi)
            bw(CC.PixelIdxList{i}) = 0;
            I(CC.PixelIdxList{i}) = 0;
        end
    end

    cc_pxls = cat(1,CC.PixelIdxList{lid==mi});
    [ii,jj] = ind2sub(size(I),cc_pxls);
    I = I(min(ii):max(ii),min(jj):max(jj));
end
    
end