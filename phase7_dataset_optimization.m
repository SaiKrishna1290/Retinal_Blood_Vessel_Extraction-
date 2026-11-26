clc;
clear;
close all;

%% =========================================================
% RETINAL BLOOD VESSEL DETECTION
% PHASE 7
% DATASET-WIDE THRESHOLD OPTIMIZATION
%
% Uses all 20 DRIVE training images
% =========================================================

%% Project folder

codeFolder = fileparts(mfilename('fullpath'));
projectFolder = fileparts(codeFolder);

%% DRIVE folders

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
% GET FILES
% =========================================================

imageFiles = dir(fullfile(imageFolder, '*.tif'));
manualFiles = dir(fullfile(manualFolder, '*.gif'));
maskFiles = dir(fullfile(maskFolder, '*.gif'));

numImages = length(imageFiles);

fprintf('\n============================================\n');
fprintf(' DATASET-WIDE THRESHOLD OPTIMIZATION\n');
fprintf('============================================\n');

fprintf('\nTraining images found: %d\n', numImages);

if numImages ~= 20
    warning('Expected 20 training images, but found %d.', ...
        numImages);
end

%% =========================================================
% THRESHOLD FACTORS
% ==========================================================

factors = [0.70 0.75 0.80 0.85 0.90 ...
           0.95 1.00 1.05 1.10 1.15 1.20];

numThresholds = length(factors);

%% Storage

allDice = zeros(numImages, numThresholds);
allSensitivity = zeros(numImages, numThresholds);
allSpecificity = zeros(numImages, numThresholds);
allPrecision = zeros(numImages, numThresholds);

%% =========================================================
% PROCESS EACH TRAINING IMAGE
% ==========================================================

for imageIndex = 1:numImages

    fprintf('\n--------------------------------------------\n');
    fprintf('Processing image %d / %d\n', ...
        imageIndex, numImages);
    fprintf('File: %s\n', imageFiles(imageIndex).name);

    %% Read retinal image

    filename = fullfile( ...
        imageFiles(imageIndex).folder, ...
        imageFiles(imageIndex).name);

    img = im2double(imread(filename));

    %% Green channel

    greenChannel = img(:,:,2);

    %% CLAHE

    enhancedImage = adapthisteq(greenChannel);

    %% =====================================================
    % MULTI-SCALE VESSEL ENHANCEMENT
    % ======================================================

    scales = [1 2 3];

    angles = 0:15:165;

    vesselResponse = zeros(size(enhancedImage));

    for s = 1:length(scales)

        sigma = scales(s);

        L = ceil(4*sigma);

        [X,Y] = meshgrid(-L:L, -L:L);

        kernel = -exp(-(X.^2)/(2*sigma^2));

        kernel(abs(Y) > 3*sigma) = 0;

        kernel = kernel - mean(kernel(:));

        kernel = kernel ./ ...
            (sum(abs(kernel(:))) + eps);

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

            response(response < 0) = 0;

            vesselResponse = max( ...
                vesselResponse, ...
                response);

        end
    end

    %% Normalize

    vesselResponse = mat2gray(vesselResponse);

    %% =====================================================
    % LOAD FOV MASK
    % ======================================================

    fovMask = imread(fullfile( ...
        maskFiles(imageIndex).folder, ...
        maskFiles(imageIndex).name));

    fovMask = fovMask > 0;

    vesselResponse(~fovMask) = 0;

    %% =====================================================
    % LOAD GROUND TRUTH
    % ======================================================

    groundTruth = imread(fullfile( ...
        manualFiles(imageIndex).folder, ...
        manualFiles(imageIndex).name));

    groundTruth = groundTruth > 0;

    groundTruth(~fovMask) = 0;

    %% =====================================================
    % TEST ALL THRESHOLDS
    % ======================================================

    for k = 1:numThresholds

        %% Otsu threshold for this image

        otsuThreshold = graythresh(vesselResponse);

        %% Dataset threshold factor

        T = otsuThreshold * factors(k);

        %% Binary segmentation

        prediction = vesselResponse >= T;

        prediction(~fovMask) = 0;

        %% Remove small objects

        prediction = bwareaopen( ...
            prediction, 10);

        %% Morphological closing

        prediction = imclose( ...
            prediction, ...
            strel('disk',1));

        %% Bridge gaps

        prediction = bwmorph( ...
            prediction, ...
            'bridge');

        prediction(~fovMask) = 0;

        %% =================================================
        % CONFUSION MATRIX
        % ==================================================

        TP = sum(prediction(:) & groundTruth(:));

        TN = sum(~prediction(:) & ~groundTruth(:));

        FP = sum(prediction(:) & ~groundTruth(:));

        FN = sum(~prediction(:) & groundTruth(:));

        %% =================================================
        % METRICS
        % ==================================================

        allDice(imageIndex,k) = ...
            2*TP / ...
            (2*TP + FP + FN + eps);

        allSensitivity(imageIndex,k) = ...
            TP / ...
            (TP + FN + eps);

        allSpecificity(imageIndex,k) = ...
            TN / ...
            (TN + FP + eps);

        allPrecision(imageIndex,k) = ...
            TP / ...
            (TP + FP + eps);

    end

    fprintf('Best Dice for image: %.4f\n', ...
        max(allDice(imageIndex,:)));

end

%% =========================================================
% AVERAGE PERFORMANCE
% ==========================================================

meanDice = mean(allDice,1);

meanSensitivity = mean(allSensitivity,1);

meanSpecificity = mean(allSpecificity,1);

meanPrecision = mean(allPrecision,1);

stdDice = std(allDice,0,1);

%% =========================================================
% RESULTS TABLE
% ==========================================================

ResultsTable = table( ...
    factors', ...
    meanDice', ...
    stdDice', ...
    meanSensitivity', ...
    meanSpecificity', ...
    meanPrecision', ...
    'VariableNames', { ...
    'ThresholdFactor', ...
    'MeanDice', ...
    'StdDice', ...
    'MeanSensitivity', ...
    'MeanSpecificity', ...
    'MeanPrecision'});

fprintf('\n============================================\n');
fprintf('       DATASET-WIDE RESULTS\n');
fprintf('============================================\n\n');

disp(ResultsTable);

%% =========================================================
% FIND GLOBAL BEST FACTOR
% ==========================================================

[bestMeanDice, bestIndex] = max(meanDice);

bestFactor = factors(bestIndex);

fprintf('\n============================================\n');
fprintf('       GLOBAL OPTIMAL PARAMETER\n');
fprintf('============================================\n');

fprintf('Best threshold factor : %.2f\n', ...
    bestFactor);

fprintf('Mean Dice             : %.4f\n', ...
    bestMeanDice);

fprintf('Mean Sensitivity      : %.4f\n', ...
    meanSensitivity(bestIndex));

fprintf('Mean Specificity      : %.4f\n', ...
    meanSpecificity(bestIndex));

fprintf('Mean Precision        : %.4f\n', ...
    meanPrecision(bestIndex));

fprintf('Std Dice              : %.4f\n', ...
    stdDice(bestIndex));

%% =========================================================
% PLOT DATASET-WIDE PERFORMANCE
% ==========================================================

figure( ...
    'Name','Dataset-Wide Threshold Optimization', ...
    'NumberTitle','off');

plot(factors, meanDice, '-o', ...
    'LineWidth',2);

hold on;

plot(factors, meanSensitivity, '-s', ...
    'LineWidth',2);

plot(factors, meanPrecision, '-^', ...
    'LineWidth',2);

plot(factors, meanSpecificity, '-d', ...
    'LineWidth',2);

grid on;

xlabel('Threshold Factor');

ylabel('Mean Performance');

title('DRIVE Training Set - Threshold Optimization');

legend( ...
    'Mean Dice', ...
    'Mean Sensitivity', ...
    'Mean Precision', ...
    'Mean Specificity', ...
    'Location','best');

%% =========================================================
% SAVE RESULTS
% ==========================================================

save(fullfile(projectFolder, ...
    'results', ...
    'phase7_dataset_optimization.mat'), ...
    'ResultsTable', ...
    'bestFactor', ...
    'bestMeanDice', ...
    'meanDice', ...
    'stdDice', ...
    'meanSensitivity', ...
    'meanSpecificity', ...
    'meanPrecision', ...
    'factors');

fprintf('\nResults saved successfully.\n');

fprintf('\n============================================\n');
fprintf('PHASE 7 COMPLETED\n');
fprintf('============================================\n');