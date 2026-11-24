clc;
clear;
close all;

%% =========================================================
% RETINAL BLOOD VESSEL DETECTION
% PHASE 1 - FINAL DATASET VERIFICATION
% DRIVE DATASET
% ==========================================================

%% Project folder

codeFolder = fileparts(mfilename('fullpath'));
projectFolder = fileparts(codeFolder);

%% DRIVE training folders

imageFolder = fullfile(projectFolder, ...
    'dataset', 'archive', ...
    'drive-train', 'training', 'images');

manualFolder = fullfile(projectFolder, ...
    'dataset', 'archive', ...
    'drive-train', 'training', '1st_manual');

maskFolder = fullfile(projectFolder, ...
    'dataset', 'archive', ...
    'drive-train', 'training', 'mask');

%% =========================================================
% CHECK FOLDERS
% ==========================================================

fprintf('============================================\n');
fprintf('     DRIVE DATASET VERIFICATION\n');
fprintf('============================================\n\n');

fprintf('Training images:\n%s\n\n', imageFolder);
fprintf('Manual ground truth:\n%s\n\n', manualFolder);
fprintf('FOV mask:\n%s\n\n', maskFolder);

if ~isfolder(imageFolder)
    error('Training image folder not found.');
end

if ~isfolder(manualFolder)
    error('Manual ground-truth folder not found.');
end

if ~isfolder(maskFolder)
    error('Mask folder not found.');
end

fprintf('All required folders found successfully.\n\n');

%% =========================================================
% FIND FILES
% ==========================================================

imageFiles = dir(fullfile(imageFolder, '*.tif'));
manualFiles = dir(fullfile(manualFolder, '*.gif'));
maskFiles = dir(fullfile(maskFolder, '*.gif'));

fprintf('Training retinal images : %d\n', length(imageFiles));
fprintf('Manual ground truths    : %d\n', length(manualFiles));
fprintf('FOV masks               : %d\n\n', length(maskFiles));

%% =========================================================
% READ FIRST IMAGE
% ==========================================================

retinalImage = imread(fullfile( ...
    imageFiles(1).folder, imageFiles(1).name));

manualImage = imread(fullfile( ...
    manualFiles(1).folder, manualFiles(1).name));

fovMask = imread(fullfile( ...
    maskFiles(1).folder, maskFiles(1).name));

%% Convert manual image to logical if necessary

manualImage = manualImage > 0;
fovMask = fovMask > 0;

%% =========================================================
% DISPLAY
% ==========================================================

figure('Name','DRIVE Dataset Verification', ...
       'NumberTitle','off');

subplot(1,3,1);

imshow(retinalImage);

title('Original Retinal Image');

subplot(1,3,2);

imshow(manualImage);

title('Manual Vessel Ground Truth');

subplot(1,3,3);

imshow(fovMask);

title('Field of View Mask');

%% =========================================================
% INFORMATION
% ==========================================================

fprintf('============================================\n');
fprintf('           IMAGE INFORMATION\n');
fprintf('============================================\n');

fprintf('Image filename: %s\n', imageFiles(1).name);

fprintf('Image size: %d x %d\n', ...
    size(retinalImage,1), size(retinalImage,2));

fprintf('Number of image channels: %d\n', ...
    size(retinalImage,3));

fprintf('Manual ground truth size: %d x %d\n', ...
    size(manualImage,1), size(manualImage,2));

fprintf('FOV mask size: %d x %d\n', ...
    size(fovMask,1), size(fovMask,2));

fprintf('\n============================================\n');
fprintf('PHASE 1 COMPLETED SUCCESSFULLY\n');
fprintf('============================================\n');