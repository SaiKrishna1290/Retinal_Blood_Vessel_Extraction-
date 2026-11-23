clc;
clear;
close all;

fprintf('====================================\n');
fprintf('   DRIVE DATASET LOCATION CHECK\n');
fprintf('====================================\n\n');

%% Project folder

codeFolder = fileparts(mfilename('fullpath'));
projectFolder = fileparts(codeFolder);

datasetFolder = fullfile(projectFolder, 'dataset');

fprintf('Dataset folder being checked:\n');
fprintf('%s\n\n', datasetFolder);

%% Check dataset folder

if ~isfolder(datasetFolder)

    fprintf('ERROR: dataset folder does not exist.\n');
    fprintf('Create/place the dataset here:\n\n');
    fprintf('%s\n', datasetFolder);

    return;
end

%% List contents

fprintf('Contents of dataset folder:\n');
fprintf('----------------------------\n');

items = dir(datasetFolder);

for k = 1:length(items)

    name = items(k).name;

    if strcmp(name,'.') || strcmp(name,'..')
        continue;
    end

    if items(k).isdir
        fprintf('[FOLDER] %s\n', name);
    else
        fprintf('[FILE]   %s\n', name);
    end

end

fprintf('\n====================================\n');
fprintf('CHECK COMPLETED\n');
fprintf('====================================\n');