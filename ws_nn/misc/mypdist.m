function D = mypdist(x,y)

xx = sum(x.*x,2);
yy = sum(y.*y,2)';
D = bsxfun(@plus,xx,yy)-2*x*y';
D = sqrt(D);
