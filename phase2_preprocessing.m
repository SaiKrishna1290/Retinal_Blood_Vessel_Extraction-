clc;
clear;
close all;

%% =========================================================
% RETINAL BLOOD VESSEL DETECTION
% PHASE 2 - GREEN CHANNEL EXTRACTION
% =========================================================

%% Project folder

codeFolder = fileparts(mfilename('fullpath'));
projectFolder = fileparts(codeFolder);

%% DRIVE training image folder

imageFolder = fullfile(projectFolder, ...
    'dataset', 'archive', ...
    'drive-train', 'training', 'images');

%% Get retinal images

imageFiles = dir(fullfile(imageFolder, '*.tif'));

if isempty(imageFiles)
    error('No retinal images found.');
end

%% Select first retinal image

filename = fullfile( ...
    imageFiles(1).folder, ...
    imageFiles(1).name);

img = imread(filename);

%% Convert to double

img = im2double(img);

%% =========================================================
% RGB CHANNEL EXTRACTION
% =========================================================

R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);

%% =========================================================
% DISPLAY RGB CHANNELS
% =========================================================

figure('Name','RGB Channel Comparison', ...
       'NumberTitle','off');

subplot(2,2,1);
imshow(img);
title('Original RGB Image');

subplot(2,2,2);
imshow(R);
title('Red Channel');

subplot(2,2,3);
imshow(G);
title('Green Channel');

subplot(2,2,4);
imshow(B);
title('Blue Channel');

%% =========================================================
% CONTRAST ENHANCEMENT
% =========================================================

greenChannel = G;

%% Histogram Equalization

histEq = histeq(greenChannel);

%% CLAHE

claheImage = adapthisteq(greenChannel);

%% =========================================================
% DISPLAY ENHANCEMENT METHODS
% =========================================================

figure('Name','Green Channel Enhancement', ...
       'NumberTitle','off');

subplot(1,3,1);

imshow(greenChannel);

title('Original Green Channel');

subplot(1,3,2);

imshow(histEq);

title('Histogram Equalization');

subplot(1,3,3);

imshow(claheImage);

title('CLAHE');

%% =========================================================
% IMAGE INFORMATION
% =========================================================

fprintf('\n============================================\n');
fprintf('       PHASE 2 - PREPROCESSING\n');
fprintf('============================================\n');

fprintf('Image: %s\n', imageFiles(1).name);

fprintf('Image size: %d x %d\n', ...
    size(img,1), size(img,2));

fprintf('\nGreen channel extracted successfully.\n');

fprintf('Histogram equalization completed.\n');

fprintf('CLAHE enhancement completed.\n');

fprintf('\n============================================\n');
fprintf('PHASE 2 COMPLETED\n');
fprintf('============================================\n');