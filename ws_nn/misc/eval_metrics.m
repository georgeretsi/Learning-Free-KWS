function [ap,pa5] = eval_metrics(ids)

%ids = ids(2:end);
N = sum(ids);


r = cumsum(ids)/sum(ids);
pr = cumsum(ids)./(1:numel(ids));

pri = fliplr(cummax(fliplr(pr)));
%pri = cummax(pr);

ap = sum(pri.*r) - sum(pri(2:end).*r(1:end-1)); 

v5 = min(N,5);
sids = find(ids);
pa5 = sum(sids<=v5)/v5;
end