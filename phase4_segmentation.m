clc;
clear;
close all;

%% =========================================================
% RETINAL BLOOD VESSEL DETECTION
% PHASE 4 - VESSEL SEGMENTATION
%
% Green Channel
%       ↓
% CLAHE
%       ↓
% Multi-scale enhancement
%       ↓
% Otsu + Adaptive Thresholding
%       ↓
% Morphological refinement
%
% =========================================================

%% =========================================================
% PROJECT PATH
% ==========================================================

codeFolder = fileparts(mfilename('fullpath'));
projectFolder = fileparts(codeFolder);

imageFolder = fullfile(projectFolder, ...
    'dataset', 'archive', ...
    'drive-train', 'training', 'images');

maskFolder = fullfile(projectFolder, ...
    'dataset', 'archive', ...
    'drive-train', 'training', 'mask');

manualFolder = fullfile(projectFolder, ...
    'dataset', 'archive', ...
    'drive-train', 'training', '1st_manual');

%% =========================================================
% LOAD FILES
% ==========================================================

imageFiles = dir(fullfile(imageFolder, '*.tif'));
maskFiles = dir(fullfile(maskFolder, '*.gif'));
manualFiles = dir(fullfile(manualFolder, '*.gif'));

if isempty(imageFiles)
    error('No retinal images found.');
end

%% Select image

imageIndex = 1;

filename = fullfile( ...
    imageFiles(imageIndex).folder, ...
    imageFiles(imageIndex).name);

img = im2double(imread(filename));

%% =========================================================
% GREEN CHANNEL
% ==========================================================

greenChannel = img(:,:,2);

%% =========================================================
% CLAHE
% ==========================================================

enhancedImage = adapthisteq(greenChannel);

%% =========================================================
% MULTI-SCALE VESSEL ENHANCEMENT
% ==========================================================

scales = [1 2 3];

angles = 0:15:165;

vesselResponse = zeros(size(enhancedImage));

fprintf('\n============================================\n');
fprintf('MULTI-SCALE VESSEL ENHANCEMENT\n');
fprintf('============================================\n');

for s = 1:length(scales)

    sigma = scales(s);

    fprintf('Processing scale %.1f...\n', sigma);

    L = ceil(4*sigma);

    [X,Y] = meshgrid(-L:L, -L:L);

    %% Matched filter

    kernel = -exp(-(X.^2)/(2*sigma^2));

    kernel(abs(Y) > 3*sigma) = 0;

    %% Zero mean

    kernel = kernel - mean(kernel(:));

    %% Normalize

    kernel = kernel ./ ...
        (sum(abs(kernel(:))) + eps);

    %% Different orientations

    for a = 1:length(angles)

        angle = angles(a);

        rotatedKernel = imrotate( ...
            kernel, ...
            angle, ...
            'bilinear', ...
            'crop');

        response = imfilter( ...
            enhancedImage, ...
            rotatedKernel, ...
            'symmetric', ...
            'same');

        %% Keep positive response

        response(response < 0) = 0;

        %% Maximum response

        vesselResponse = max( ...
            vesselResponse, ...
            response);

    end

end

%% Normalize

vesselResponse = mat2gray(vesselResponse);

%% =========================================================
% LOAD FOV MASK
% ==========================================================

fovMask = imread(fullfile( ...
    maskFiles(imageIndex).folder, ...
    maskFiles(imageIndex).name));

fovMask = fovMask > 0;

%% Apply FOV

vesselResponse(~fovMask) = 0;

%% =========================================================
% METHOD 1 - OTSU THRESHOLD
% ==========================================================

otsuThreshold = graythresh(vesselResponse);

vesselOtsu = imbinarize( ...
    vesselResponse, ...
    otsuThreshold);

%% Restrict to FOV

vesselOtsu(~fovMask) = 0;

%% =========================================================
% METHOD 2 - ADAPTIVE THRESHOLD
% ==========================================================

adaptiveThreshold = adaptthresh( ...
    vesselResponse, ...
    0.50);

vesselAdaptive = imbinarize( ...
    vesselResponse, ...
    adaptiveThreshold);

%% Restrict to FOV

vesselAdaptive(~fovMask) = 0;

%% =========================================================
% MORPHOLOGICAL REFINEMENT
% ==========================================================

%% Remove very small isolated regions

vesselOtsuClean = bwareaopen( ...
    vesselOtsu, 10);

vesselAdaptiveClean = bwareaopen( ...
    vesselAdaptive, 10);

%% Morphological closing

se = strel('disk', 1);

vesselOtsuClean = imclose( ...
    vesselOtsuClean, se);

vesselAdaptiveClean = imclose( ...
    vesselAdaptiveClean, se);

%% Fill small gaps

vesselOtsuClean = bwmorph( ...
    vesselOtsuClean, ...
    'bridge');

vesselAdaptiveClean = bwmorph( ...
    vesselAdaptiveClean, ...
    'bridge');

%% Apply FOV again

vesselOtsuClean(~fovMask) = 0;
vesselAdaptiveClean(~fovMask) = 0;

%% =========================================================
% LOAD GROUND TRUTH
% ==========================================================

groundTruth = imread(fullfile( ...
    manualFiles(imageIndex).folder, ...
    manualFiles(imageIndex).name));

groundTruth = groundTruth > 0;

groundTruth(~fovMask) = 0;

%% =========================================================
% DISPLAY RESULTS
% ==========================================================

figure( ...
    'Name','Phase 4 - Vessel Segmentation', ...
    'NumberTitle','off');

subplot(2,3,1);

imshow(img);

title('Original Image');

subplot(2,3,2);

imshow(vesselResponse);

title('Vessel Response');

subplot(2,3,3);

imshow(groundTruth);

title('Ground Truth');

subplot(2,3,4);

imshow(vesselOtsu);

title(sprintf('Otsu (T = %.3f)', otsuThreshold));

subplot(2,3,5);

imshow(vesselOtsuClean);

title('Otsu + Morphology');

subplot(2,3,6);

imshow(vesselAdaptiveClean);

title('Adaptive + Morphology');

%% =========================================================
% BASIC RESULTS
% ==========================================================

fprintf('\n============================================\n');
fprintf('SEGMENTATION RESULTS\n');
fprintf('============================================\n');

fprintf('Image: %s\n', ...
    imageFiles(imageIndex).name);

fprintf('\nOtsu threshold: %.4f\n', ...
    otsuThreshold);

fprintf('\nNumber of detected vessel pixels:\n');

fprintf('Otsu:              %d\n', ...
    nnz(vesselOtsuClean));

fprintf('Adaptive:          %d\n', ...
    nnz(vesselAdaptiveClean));

fprintf('Ground truth:      %d\n', ...
    nnz(groundTruth));
%% =========================================================
% SAVE RESULTS FOR PHASE 5
% ==========================================================

save(fullfile(projectFolder, 'results', ...
    'phase4_results.mat'), ...
    'vesselOtsu', ...
    'vesselOtsuClean', ...
    'vesselAdaptive', ...
    'vesselAdaptiveClean', ...
    'groundTruth', ...
    'fovMask', ...
    'vesselResponse', ...
    'otsuThreshold');

fprintf('\nPhase 4 results saved successfully.\n');
fprintf('\n============================================\n');
fprintf('PHASE 4 COMPLETED\n');
fprintf('============================================\n');