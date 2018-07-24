function d = valid_sequence_weighted_multi(x,t,b)

% 'cityblock' or 'euclidean'
D = pdist2(t,x,'euclidean');

%t = flipud(t);
%x = flipud(x);
%D = mypdist(t,x);

if (size(t,1) == 1)
    d = min(D);
    return;
end

k = floor(.5*b);

usemex = 1;
if usemex == 0

    pow = 2;
    mr = 10;
    range = linspace(-mr,mr,2*k+1);
    w = 1+.2*abs(range).^(pow)/(mr^pow);
    %w = ones(1,numel(range));


    N = (size(t,1)*b);
    R = size(x,1)/N;

    %ws = 1 + .5*abs(linspace(-R/2,R/2,R))/(R/2);
    wd = ones([1 size(D,1)]);
    %wd = fspecial('gaussian',[1 size(D,1)],size(D,1));

    A = reshape(D(1,:),[R N]);
    for n = 1:size(D,1)-1

        mA = inf*ones([R N]);
        for i = 1:N

            trange = (i-b-k):(i-b+k);
            tid = find(trange >= 1 & trange <= N);

            if isempty(tid)
                mA(:,i) = inf;
            else
                %ww = repmat(w(tid),[R 1]);
                %ww = ws'*w(tid);
                for j = 1:R
                    ws = 1+.05*abs((1:R) - j); 
                    %ws = ones([1 R]);
                    ww = ws'*w(tid);
                    mA(j,i) = min(min(ww.*A(:,trange(tid))));
                end
            end
        end
        A =  reshape(D(n+1,:),[R N]) + mA;%repmat(mA,[R 1]);
        %A =  bsxfun(@max,reshape(D(n+1,:),[R N]),mA);%repmat(mA,[R 1]));

    end

    d = min(min(A));
else 
    
    d = inner_valid_seq_multi(D,b,k);
    
end
%toc;

end