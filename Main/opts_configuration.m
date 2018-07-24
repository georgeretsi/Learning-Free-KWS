% opts !!!
function opts = opts_configuration(opts,descriptor,method,ismulti)

%opts.datasetName = 'GW';

opts.action = {'dataset_features','queries_features','matching_n_evaluation','clear_all'};

%opts.descriptor = {'POG'};
opts.descriptor = descriptor;
if ~strcmp(opts.descriptor,'POG')
    disp('Supported Descriptors : POG');
end

%opts.method = {'Global','Sequential'};
opts.method = method;
if ~strcmp(opts.method,'Global') && ~strcmp(opts.method,'Sequential')
    disp('Supported Descriptor Variants : Global & Sequential');
end

%opts.seq = [nl ns];
opts.seq = [6 5];

if ismulti
    opts.multi = linspace(.7,1.4,7);
else
    opts.multi = 1;
end

% PCA
opts.pcaNref = 150; 
opts.pcaN = 60;

% percentage of ref decriptor
opts.percRef = .1;

% define paths
opts.descPath = './temp_descriptors/';


% defined on loadDATASET
%opts.datasetPath = ;
%opts.queriesPath = ;

% function paths
opts.preprocFunctionPath = '../ws_nn/preprocessing/';
opts.featuresFunctionPath = '../ws_nn/FeatureExtraction/';
opts.matchingFunctionPath = '../ws_nn/matching/';
opts.miscFunctionPath = '../ws_nn/misc/';


% batch load mat
opts.batchsize = 500;

end
