function nbw = deslant(bw)

a = tand(-25:2.5:25);

for i = 1:numel(a)
    %a = 1.2*(1 - rand());
    %%{
    T = maketform('affine', [1 0 0; a(i) 1 0; 0 0 1] );
    %T = affine2d([1 0 0; a(i) 1 0; 0 0 1] );
    R = makeresampler({'cubic','nearest'},'fill');
    tbw = imtransform(bw,T,R,'FillValues',0);
    %tbw = imwarp(bw,T);
    vp(i) = sum(sum(tbw).^2);
end

[~,mx_id] = max(vp);
T = maketform('affine', [1 0 0; a(mx_id) 1 0; 0 0 1] );
R = makeresampler({'cubic','nearest'},'fill');
nbw = imtransform(bw,T,R,'FillValues',0);
%T = affine2d([1 0 0; a(mx_id) 1 0; 0 0 1] );
%nbw = imwarp(bw,T);

%nbw = bwareaopen(nbw,50);

%[Y,X] = find(nbw == 1);
%nbw = nbw(min(Y):max(Y),min(X):max(X));