function Ig = illumination_norm_t(I,ws)

img_norm = @(img) (img-min(min(img)))/(max(max(img))-min(min(img)));

I = double(I);
I = img_norm(I);

% dafualt sauvola parameters
if nargin ==1
    ws = 91;
end
k = .1;

h = ones(ws);
h = h/numel(h);

% Mean value
mean = imfilter(I,h,'replicate');

% Standard deviation
mean2 = imfilter(I.^2,h,'replicate');
deviation = (mean2 - mean.^2).^0.5;

% Sauvola
R = max(deviation(:));
threshold = mean.*(1 + k * (deviation / R-1));


Ig = 1-mytmf(I,threshold-1.5*deviation,threshold+.3*deviation);

end

function Y = mytmf(X,A,B)

Y = zeros(size(X));

Y0 = (X-A)./(B-A);
ind = (A <= X);
Y(ind) = Y0(ind);

ind = (X >= B);
Y(ind) = 1;

end