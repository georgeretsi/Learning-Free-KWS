function [In,mh] = imgNormalize(I,r,lp)


% contrast normalization
Ig = illumination_norm_t(I);
Ig = delete_unwanted_cc(Ig); %!!!
[h_img,w_img] = size(Ig);

% short words parameter
lp = adjust_lp(lp,h_img,w_img);


rotations = (-8:1:8);

% projections of permitted rotations
R = radon(Ig,90-rotations);

for i = 1:numel(rotations)  
    tproj = R(:,i);
    l(i) = reg_parameter(tproj)*lp;
    h(i) = height_est(tproj,.95);
end

l0 = mean(l);
h0 = mean(h);

lwa = zeros(1,numel(rotations)); upa = zeros(size(lwa)); score = zeros(size(lwa));
for i = 1:numel(rotations)
    tproj = R(:,i);
    [lwa(i),upa(i),score(i)] = find_main_region_iter(tproj,h0,l0,l(i));
end

[~,mi] = max(score);

Ir = imrotate(Ig,rotations(mi),'bicubic');

[lw,up,~,del] = find_main_region_iter(sum(Ir,2),h0,l0,l(mi));
pad = 2;
for i = 1:size(del,1)
   Ir(max(1,del(i,1)-pad):min(size(Ir,1),del(i,2)+pad),:) = 0; 
end

%img_norm = @(img) (img-min(min(img)))/(max(max(img))-min(min(img)));
%Ir = img_norm(Ir);


% crop horizontally
Ip = Ir(up:lw,:);
%Ip(Ip < 0) = 0;
proj = sqrt(sum(Ip.^2,1)');
%proj = sum(Ip.^2,1)';


if sum(proj) > 0
    [w0,a,b] = height_est(proj,.90);
    
    ws = floor(w0/2);
    w0 = 2*ws+1;
    wpad = round(.25*ws);
    wf = [zeros(1,round(w0/5)) ones(1,w0) zeros(1,round(w0/5))];
    mm = round(w0/5); hh = exp(-(1/mm^2)*(-mm:mm).^2);
    wf = imfilter(wf,hh);

    [~,mi] = max(conv(proj,wf,'same'));
    Ir = Ir(:,max(1,mi-ws-wpad):min(numel(proj),mi+ws+wpad));
end

% find padding to constract centralized image

[h,w] = size(Ir);

m = r*(lw-up);
v_up = round(m - up);
if v_up >= 0
    pad_up = round(v_up);
    i_up = 1;
else 
    pad_up = 0;
    i_up = -v_up;
end
    
v_lw = round(m + lw - h);
if v_lw >= 0
    pad_lw = round(v_lw);
    i_lw = h;
else 
    pad_lw = 0;
    i_lw = h+v_lw;
end


In = Ir(i_up:i_lw,:);
pad_l =0;%max(0,max_x-max(cx-X));
pad_r =0;%max(0,max_x-max(X-cx));
In = padarray(In,[pad_up pad_l],0,'pre');
In = padarray(In,[pad_lw pad_r],0,'post');

mh = lw-up;

end

function [h,a,b] = height_est(proj,r)

proj = reshape(proj,[1 numel(proj)]);
sh = proj/sum(proj);
shc = [0 cumsum(sh)];
dh = bsxfun(@minus,shc,shc') > r;
[p1h,p2h] = find(dh);
[h,idxh] = min(abs(p2h-p1h+1));
a = p1h(idxh);
b = p2h(idxh);

end

function lp = adjust_lp(lp,h,w)

lw = 1*h;
up = 5*h;

bv = .1; % lp = lp - bv;
if w < lw
    v = bv;
elseif w < up;
    v = bv*(up-w)/(up-lw);
else
    v = 0;
end

lp = lp - v;

end

function l0 = reg_parameter(proj)

[h0,a,b] = height_est(proj,.90);
mproj = proj(a:b);

l0 = mean((mproj.^2)./(mean(mproj)^2));
%l0 = sqrt(l0);

end

function [lw,up,score,del] = find_main_region_iter(proj,h0,l0,l)

h = h0+0;

sproj = sum(proj);

del = [];
for iter = 1:3
    [lw,up,score] = find_main_region(proj,h,l);

    lw = round(lw);
    up = round(up);
    
    vcond = (lw-up)/h;
    vcond2 = sum(proj(up:lw))/sproj;
    if (vcond == 0) || (vcond > .1) || (vcond2 > .3) 
        break;
    end
    proj(up:lw) = 0; 
    del = [del; up lw];
end
    
    
if lw == up
    score = -1; % impossible
else
    score = sum(proj(up:lw))/sproj-l0*abs(lw-up)/h0;
end

end


function [lw,up,score] = find_main_region(proj,h0,r)

N = sum(proj);
K = numel(proj);

h = h0+0;%(-2:2);

for kk = 1:numel(h)
    l = r/h(kk);

    P = 1.0*cumsum(proj)/sum(proj) - l*(1:K)';

    tscore = P(2) - P(1);
    minv = P(1);
    %tlw = N;
    %tup = 1;
    for i = 2:K
        if (P(i) - minv > tscore)                              
          tscore = P(i) - minv;
          tlw = i;
        end
        if (P(i) < minv)
             minv = P(i);
        end
    end
    if ~exist('tlw','var')
        tlw = K;
        tup = 1;
    else
        [~,tup] = max(P(tlw)-P(1:tlw));
    end    

    score(kk) = tscore;
    %score(kk) = sum(proj(tup:tlw).^2)/sum(proj.^2)-r*abs(tlw-tup)/h0;
    up(kk) = tup;
    lw(kk) = tlw;

    clear tlw tup;
end

score = median(score);
up = median(up);
lw = median(lw);

end