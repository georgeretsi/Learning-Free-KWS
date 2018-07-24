function v = interpAveragePrecision(actual,predicted)


ids = ismember(predicted,actual);



r = cumsum(ids)/numel(actual);
pr = cumsum(ids)./(1:numel(predicted));

pri = cummax(pr);

v = sum(pri.*r) - sum(pri(2:end).*r(1:end-1)); 

end

function am = cummax(a)

am = a;
for i = (numel(a)-1):-1:1
    am(i) = max(am(i+1),a(i));
end

end