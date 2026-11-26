clc;
clear;
close all;

%% =========================================================
% RETINAL BLOOD VESSEL DETECTION
% PHASE 6 - THRESHOLD OPTIMIZATION
% =========================================================

%% Project folder

codeFolder = fileparts(mfilename('fullpath'));
projectFolder = fileparts(codeFolder);

%% Load Phase 4 results

resultFile = fullfile( ...
    projectFolder, ...
    'results', ...
    'phase4_results.mat');

if ~isfile(resultFile)
    error('Run phase4_segmentation first.');
end

load(resultFile);

%% =========================================================
% INPUT DATA
% ==========================================================

response = vesselResponse;
reference = groundTruth;
validRegion = fovMask;

%% Restrict to field of view

response(~validRegion) = 0;
reference(~validRegion) = 0;

%% =========================================================
% OTSU BASE THRESHOLD
% ==========================================================

otsuThreshold = graythresh(response);

fprintf('\n============================================\n');
fprintf('      PHASE 6 - THRESHOLD OPTIMIZATION\n');
fprintf('============================================\n');

fprintf('\nOtsu threshold = %.4f\n', otsuThreshold);

%% Threshold factors

factors = [0.70 0.80 0.90 1.00 1.10 1.20 1.30];

thresholds = otsuThreshold .* factors;

%% Storage

Accuracy = zeros(size(thresholds));
Sensitivity = zeros(size(thresholds));
Specificity = zeros(size(thresholds));
Precision = zeros(size(thresholds));
F1 = zeros(size(thresholds));
Dice = zeros(size(thresholds));
MCC = zeros(size(thresholds));

%% =========================================================
% TEST EACH THRESHOLD
% ==========================================================

for k = 1:length(thresholds)

    T = thresholds(k);

    %% Binary segmentation

    prediction = response >= T;

    %% Restrict to FOV

    prediction(~validRegion) = 0;

    %% Remove tiny components

    prediction = bwareaopen(prediction, 10);

    %% Morphological closing

    se = strel('disk', 1);

    prediction = imclose(prediction, se);

    %% Bridge small gaps

    prediction = bwmorph(prediction, 'bridge');

    %% Apply FOV again

    prediction(~validRegion) = 0;

    %% =====================================================
    % CONFUSION MATRIX
    % =====================================================

    TP = sum(prediction(:) & reference(:));

    TN = sum(~prediction(:) & ~reference(:));

    FP = sum(prediction(:) & ~reference(:));

    FN = sum(~prediction(:) & reference(:));

    %% =====================================================
    % METRICS
    % =====================================================

    Accuracy(k) = ...
        (TP + TN) / ...
        (TP + TN + FP + FN + eps);

    Sensitivity(k) = ...
        TP / ...
        (TP + FN + eps);

    Specificity(k) = ...
        TN / ...
        (TN + FP + eps);

    Precision(k) = ...
        TP / ...
        (TP + FP + eps);

    F1(k) = ...
        2*TP / ...
        (2*TP + FP + FN + eps);

    Dice(k) = ...
        2*TP / ...
        (2*TP + FP + FN + eps);

    MCC(k) = ...
        ((TP*TN) - (FP*FN)) / ...
        sqrt((TP+FP)*(TP+FN)* ...
             (TN+FP)*(TN+FN) + eps);

end

%% =========================================================
% DISPLAY TABLE
% ==========================================================

ResultsTable = table( ...
    factors', ...
    thresholds', ...
    Accuracy', ...
    Sensitivity', ...
    Specificity', ...
    Precision', ...
    F1', ...
    Dice', ...
    MCC', ...
    'VariableNames', { ...
    'Factor', ...
    'Threshold', ...
    'Accuracy', ...
    'Sensitivity', ...
    'Specificity', ...
    'Precision', ...
    'F1', ...
    'Dice', ...
    'MCC'});

disp(ResultsTable);

%% =========================================================
% FIND BEST THRESHOLD
% ==========================================================

[bestDice, bestIndex] = max(Dice);

bestThreshold = thresholds(bestIndex);

fprintf('\n============================================\n');
fprintf('BEST THRESHOLD\n');
fprintf('============================================\n');

fprintf('Best factor    : %.2f\n', ...
    factors(bestIndex));

fprintf('Best threshold : %.4f\n', ...
    bestThreshold);

fprintf('Best Dice      : %.4f\n', ...
    bestDice);

fprintf('Best F1        : %.4f\n', ...
    F1(bestIndex));

fprintf('Sensitivity    : %.4f\n', ...
    Sensitivity(bestIndex));

fprintf('Specificity    : %.4f\n', ...
    Specificity(bestIndex));

fprintf('Precision      : %.4f\n', ...
    Precision(bestIndex));

fprintf('MCC            : %.4f\n', ...
    MCC(bestIndex));

%% =========================================================
% CREATE BEST SEGMENTATION
% ==========================================================

bestSegmentation = response >= bestThreshold;

bestSegmentation(~validRegion) = 0;

bestSegmentation = bwareaopen( ...
    bestSegmentation, 10);

bestSegmentation = imclose( ...
    bestSegmentation, ...
    strel('disk',1));

bestSegmentation = bwmorph( ...
    bestSegmentation, ...
    'bridge');

bestSegmentation(~validRegion) = 0;

%% =========================================================
% DISPLAY THRESHOLD COMPARISON
% ==========================================================

figure( ...
    'Name','Threshold Optimization', ...
    'NumberTitle','off');

subplot(2,4,1);

imshow(reference);

title('Ground Truth');

for k = 1:length(thresholds)

    prediction = response >= thresholds(k);

    prediction(~validRegion) = 0;

    prediction = bwareaopen( ...
        prediction, 10);

    prediction = imclose( ...
        prediction, ...
        strel('disk',1));

    prediction = bwmorph( ...
        prediction, 'bridge');

    prediction(~validRegion) = 0;

    subplot(2,4,k+1);

    imshow(prediction);

    title(sprintf('T=%.3f\nDice=%.3f', ...
        thresholds(k), Dice(k)));

end

%% =========================================================
% PERFORMANCE CURVES
% ==========================================================

figure( ...
    'Name','Threshold Performance', ...
    'NumberTitle','off');

plot(thresholds, Dice, '-o', ...
    'LineWidth', 2);

hold on;

plot(thresholds, Sensitivity, '-s', ...
    'LineWidth', 2);

plot(thresholds, Precision, '-^', ...
    'LineWidth', 2);

plot(thresholds, Specificity, '-d', ...
    'LineWidth', 2);

grid on;

xlabel('Threshold');

ylabel('Performance');

title('Segmentation Performance vs Threshold');

legend( ...
    'Dice', ...
    'Sensitivity', ...
    'Precision', ...
    'Specificity', ...
    'Location','best');

%% =========================================================
% SAVE RESULTS
% ==========================================================

save(fullfile(projectFolder, ...
    'results', ...
    'phase6_threshold_results.mat'), ...
    'ResultsTable', ...
    'bestThreshold', ...
    'bestSegmentation', ...
    'bestDice', ...
    'thresholds', ...
    'Dice', ...
    'Sensitivity', ...
    'Specificity', ...
    'Precision', ...
    'F1', ...
    'MCC');

fprintf('\nPhase 6 results saved successfully.\n');

fprintf('\n============================================\n');
fprintf('PHASE 6 COMPLETED\n');
fprintf('============================================\n');