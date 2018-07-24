function desc = pog(I,K)

s0 = 1.5;
desc = pog_single(I,K,s0);

end


function f = pog_single(I,K,sf)

s = 0; %signed or unsigned

theta_init = 0;
f = [];

I = imfilter(I,fspecial('gaussian',(2*ceil(3*sf)+1)*[1 1],sf),'symmetric');

[gx,gy] = imgradientxy(double(I),'centraldifference');
mgn = sqrt(gx.^2+gy.^2);

orient = atan2d(gy,gx);
orient(orient<0) = orient(orient<0)+(s+1)*180; 

theta = linspace(0,(s+1)*180,K+1);
sigma = .5*(theta(2) - theta(1));
step = 2*ceil(3*sigma)+1;

for i = 1:K
    tmp_ind1 = abs(orient-theta(i)-theta_init)<=step/2;
    tmp_ind2 = abs(orient-theta(i)-theta_init-(s+1)*180)<=step/2;
    orient_ind = zeros(size(orient));
    orient_ind(tmp_ind1) = mgn(tmp_ind1).*gaussmf(orient(tmp_ind1),[sigma theta(i)]);
    orient_ind(tmp_ind2) = mgn(tmp_ind2).*gaussmf(orient(tmp_ind2)-(s+1)*180,[sigma theta(i)]);
    f = [f oriented_projection(orient_ind)];
end


end

function desc = oriented_projection(I)

th_init = 0;
th_n = 8;
cut = 7*ones(1,th_n);

theta = th_init+linspace(0,180,th_n+1); %+1
theta = theta(1:end-1);

R = radon(I,theta);
R = R/(eps+sum(sum(I)));

N = size(R,1);

v = [];
for i = 1:th_n
    rproj = R(:,i)';
    tmp = fft(rproj);
    v = [v tmp(1+(1:cut(i)))];
end
desc = [abs(v) real(v) imag(v)]; 
desc = desc/norm(desc,2);

end