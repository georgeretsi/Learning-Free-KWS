% segmentation based ws on bentham w

disp('-----Dataset Loading-----');
%opts = loadGWsetupB();

%opts = loadBenthamICFHR14('/home/george/Desktop/WS_Journal_Experiments/Bentham/');
opts = loadModernICFHR14('/home/george/Desktop/WS_Journal_Experiments/Modern/');

% descriptor: POG
% method: Global, GlobalZoned or Sequential (Proposed)
% multiplte instances option: 0 or 1 (supported only for Sequential)
opts = opts_configuration(opts,'POG','Sequential',1);

opts.percRef = .1; % SeqPOG percentage
opts.action = {'dataset_features','queries_features','matching_n_evaluation'}; 

%---------------

if ismember('dataset_features',opts.action)
    disp('-----Words Features-----');
    isQuery = 0;
    ExtractMain(opts,isQuery);
end

%---------------

if ismember('queries_features',opts.action)
    disp('-----Queries Features-----');
    isQuery = 1;
    ExtractMain(opts,isQuery);
end

%---------------

if ismember('matching_n_evaluation',opts.action)
    disp('-----Matching-----');
    [Pa5,AP] = EvaluateMain(opts);
    disp('-----Results-----');
    disp([' P@5 : ', num2str(mean(Pa5))]);
    disp([' MAP : ', num2str(mean(AP))]);
end

%---------------
%{
if ismember('clear_all',opts.action)
    disp('-----Clear All-----');
    clearAllData(opts);
end
%}
