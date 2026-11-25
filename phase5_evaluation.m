clc;
clear;
close all;

%% =========================================================
% RETINAL BLOOD VESSEL DETECTION
% PHASE 5 - QUANTITATIVE EVALUATION
% ==========================================================

%% Project folder

codeFolder = fileparts(mfilename('fullpath'));
projectFolder = fileparts(codeFolder);

%% Load Phase 4 results

resultFile = fullfile( ...
    projectFolder, ...
    'results', ...
    'phase4_results.mat');

if ~isfile(resultFile)
    error(['Phase 4 results not found. ', ...
           'Run phase4_segmentation first.']);
end

load(resultFile);

fprintf('\n============================================\n');
fprintf('       PHASE 5 - QUANTITATIVE EVALUATION\n');
fprintf('============================================\n');

%% =========================================================
% EVALUATE OTSU + MORPHOLOGY
% ==========================================================

prediction = vesselOtsuClean;
reference = groundTruth;

%% Restrict evaluation to FOV

prediction = prediction & fovMask;
reference = reference & fovMask;

%% =========================================================
% CONFUSION MATRIX COMPONENTS
% ==========================================================

TP = sum(prediction(:) & reference(:));

TN = sum(~prediction(:) & ~reference(:));

FP = sum(prediction(:) & ~reference(:));

FN = sum(~prediction(:) & reference(:));

%% =========================================================
% METRICS
% ==========================================================

Accuracy = (TP + TN) / ...
    (TP + TN + FP + FN);

Sensitivity = TP / ...
    (TP + FN + eps);

Specificity = TN / ...
    (TN + FP + eps);

Precision = TP / ...
    (TP + FP + eps);

F1 = 2 * TP / ...
    (2 * TP + FP + FN + eps);

Dice = 2 * TP / ...
    (2 * TP + FP + FN + eps);

%% Matthews Correlation Coefficient

MCC = ((TP * TN) - (FP * FN)) / ...
    sqrt((TP+FP) * (TP+FN) * ...
         (TN+FP) * (TN+FN) + eps);

%% =========================================================
% DISPLAY RESULTS
% ==========================================================

fprintf('\n--------------------------------------------\n');
fprintf('CONFUSION MATRIX\n');
fprintf('--------------------------------------------\n');

fprintf('True Positive  (TP): %d\n', TP);
fprintf('True Negative  (TN): %d\n', TN);
fprintf('False Positive (FP): %d\n', FP);
fprintf('False Negative (FN): %d\n', FN);

fprintf('\n--------------------------------------------\n');
fprintf('PERFORMANCE METRICS\n');
fprintf('--------------------------------------------\n');

fprintf('Accuracy    : %.4f (%.2f%%)\n', ...
    Accuracy, Accuracy*100);

fprintf('Sensitivity : %.4f (%.2f%%)\n', ...
    Sensitivity, Sensitivity*100);

fprintf('Specificity : %.4f (%.2f%%)\n', ...
    Specificity, Specificity*100);

fprintf('Precision   : %.4f (%.2f%%)\n', ...
    Precision, Precision*100);

fprintf('F1 Score    : %.4f\n', F1);

fprintf('Dice        : %.4f\n', Dice);

fprintf('MCC         : %.4f\n', MCC);

fprintf('\n============================================\n');
fprintf('PHASE 5 COMPLETED\n');
fprintf('============================================\n');

%% =========================================================
% CONFUSION MATRIX VISUALIZATION
% ==========================================================

confusionMatrix = [
    TP FP;
    FN TN
];

figure('Name','Confusion Matrix', ...
       'NumberTitle','off');

imagesc(confusionMatrix);

axis image;

xticks([1 2]);
yticks([1 2]);

xticklabels({'Predicted Vessel', ...
             'Predicted Background'});

yticklabels({'Actual Vessel', ...
             'Actual Background'});

title('Vessel Segmentation Confusion Matrix');

colorbar;

%% Display numerical values

for i = 1:2
    for j = 1:2

        text(j, i, ...
            num2str(confusionMatrix(i,j)), ...
            'HorizontalAlignment','center', ...
            'FontSize',12, ...
            'FontWeight','bold');

    end
end