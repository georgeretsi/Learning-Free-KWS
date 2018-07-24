function [desc,img] = word_slw_pog(I,nl,step_choice,simple)


    rect_win = 60;
    img = imresize(double(I),round([rect_win (nl/2)*rect_win]),'bilinear');

    [h,w] = size(img); 
    [xc,xw0] = equally_split(w,nl,step_choice);

    
    %scales = .6:.2:1.4;
    %xw = round(xw0*scales);
    xw = round(xw0);% + (-8:4:8));
    
    if simple == 1
        ss = round(step_choice/2); 
        xc = xc(ss:step_choice:end);
        xw = xw0;
    end
    
    padx(1) = max(0,max(xw)-xc(1)+1);
    padx(2) = max(0,-w+max(xw)+xc(end));
    xc = xc+padx(1);
 
    if step_choice > 1 %exist('padx','var');
        img = padarray(img,[0 padx(1)],0,'pre');
        img = padarray(img,[0 padx(2)],0,'post');
    end
     
   
    s0 =1.5;
    desc = seg_pog(img,xc,xw,s0);
    
    
end

function desc_d = seg_pog(img,xc,xw,sf)

    img = imfilter(img,fspecial('gaussian',(2*ceil(3*sf)+1)*[1 1],sf),'symmetric');

    [gx,gy] = imgradientxy(double(img),'sobel');
    mgn = sqrt(gx.^2+gy.^2);
    orient = atan2d(gy,gx);
    
    bw = mgn ~= 0 ;
    %bw = imdilate(edge(img,'log'),strel('disk',1));
    
    orient(~bw) = 640; % not possible values for background
    orientu = orient;
    orientu(orient<0) = orientu(orient<0)+180; 
   
    
    desc_d = zeros(numel(xc),numel(pog(zeros(20),zeros(20),4,0)));
 
    for i = 1:numel(xc)
        xsd = xc(i)-xw;
        xed = xc(i)+xw;
        tmgn = mgn(:,xsd:xed);
        %torient = orient(:,xsd:xed);
        torientu = orientu(:,xsd:xed);

        desc_d(i,:) = pog(tmgn,torientu,4,0);
    end
    
end


function f = pog(mgn,orient,K,radon_th_init)

%bw = medfilt2(bw);
theta_init = radon_th_init;

unsigned = double(sum(sum(orient<0)) == 0);

s = 2-unsigned;
if unsigned
    theta = linspace(0,180,K+1);
else
    theta = linspace(-180,180,K+1);    
end

sigma = .5*(theta(2) - theta(1));
step = 2*ceil(3*sigma)+1;

th_n = 8;
cut = 7;
f = zeros(th_n*cut*3,K);
for i = 1:K
    %theta_init = 0;%adapt_angle(bw,theta(i));
    tmp_ind1 = abs(orient-theta(i)-theta_init)<=step/2;
    tmp_ind2 = abs(orient-theta(i)-theta_init-s*180)<=step/2;
    orient_ind = zeros(size(mgn));

    orient_ind(tmp_ind1) = mgn(tmp_ind1).* gaussmf(orient(tmp_ind1),[sigma theta(i)+theta_init]);
    orient_ind(tmp_ind2) = mgn(tmp_ind2).*gaussmf(orient(tmp_ind2)-s*180,[sigma theta(i)+theta_init]);
    
    f(:,i) = adapt_sgrad(orient_ind,th_n,cut,radon_th_init);
end

f = f(:)';

end

function desc = adapt_sgrad(bw,th_n,cut,th_init)

if (nargin == 1)
th_init = 0;
end

theta = th_init+linspace(0,180,th_n+1); %+1
theta = theta(1:end-1);


R = radon(bw,theta);
R = R/(eps+sum(sum(bw)));

N = size(R,1);
v = zeros(th_n,cut);
for i = 1:th_n
    rproj = R(:,i)';
    tmp = fft(rproj);
    v(i,:) = tmp(1+(1:cut));
end
v = reshape(v',[],1)';  

desc = [abs(v) real(v) imag(v)]; 
desc = desc/(norm(desc,2)+eps);

end

function [xc,xw] = equally_split(w,nl,nstep)

dw = w/nl;
K = nstep*ceil(nl);

ovrlp = .3;
pad = ovrlp*dw;

xw = round(.5*dw+pad);

xc0 = linspace(1,w,K+1);
xc = round(.5*(xc0(1:end-1)+xc0(2:end)));

end