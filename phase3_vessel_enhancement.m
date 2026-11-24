clc;
clear;
close all;

%% =========================================================
% RETINAL BLOOD VESSEL DETECTION
% PHASE 3 - MULTI-SCALE VESSEL ENHANCEMENT
%
% Method:
% Green Channel
%       ↓
% CLAHE
%       ↓
% Multi-scale matched filtering
%       ↓
% Multi-orientation filtering
%       ↓
% Maximum response
%
% ==========================================================

%% =========================================================
% PROJECT PATH
% ==========================================================

codeFolder = fileparts(mfilename('fullpath'));
projectFolder = fileparts(codeFolder);

%% DRIVE training image folder

imageFolder = fullfile(projectFolder, ...
    'dataset', 'archive', ...
    'drive-train', 'training', 'images');

%% DRIVE training mask folder

maskFolder = fullfile(projectFolder, ...
    'dataset', 'archive', ...
    'drive-train', 'training', 'mask');

%% Find images

imageFiles = dir(fullfile(imageFolder, '*.tif'));

if isempty(imageFiles)
    error('No retinal images found.');
end

%% =========================================================
% SELECT IMAGE
% ==========================================================

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
% MULTI-SCALE PARAMETERS
% ==========================================================

% Different vessel widths

scales = [1 2 3];

% Orientations in degrees

angles = 0:15:165;

%% Initialize final response

vesselResponse = zeros(size(enhancedImage));

%% =========================================================
% MULTI-SCALE AND MULTI-ORIENTATION FILTERING
% ==========================================================

fprintf('\n============================================\n');
fprintf('   MULTI-SCALE VESSEL ENHANCEMENT\n');
fprintf('============================================\n');

for s = 1:length(scales)

    sigma = scales(s);

    fprintf('\nProcessing scale %d, sigma = %.1f\n', ...
        s, sigma);

    %% Kernel size

    L = ceil(4 * sigma);

    [X,Y] = meshgrid(-L:L, -L:L);

    %% Matched filter kernel
    %
    % X represents direction perpendicular
    % to vessel.
    %
    % Y represents vessel direction.

    kernel = -exp(-(X.^2) / ...
        (2*sigma^2));

    %% Limit kernel length

    kernel(abs(Y) > 3*sigma) = 0;

    %% Make zero mean

    kernel = kernel - mean(kernel(:));

    %% Normalize

    kernel = kernel ./ ...
        (sum(abs(kernel(:))) + eps);

    %% Orientation filtering

    for a = 1:length(angles)

        angle = angles(a);

        %% Rotate kernel

        rotatedKernel = imrotate( ...
            kernel, ...
            angle, ...
            'bilinear', ...
            'crop');

        %% Filter image

        response = imfilter( ...
            enhancedImage, ...
            rotatedKernel, ...
            'symmetric', ...
            'same');

        %% Keep strongest positive response

        response(response < 0) = 0;

        %% Update maximum response

        vesselResponse = max( ...
            vesselResponse, ...
            response);

    end

end

%% =========================================================
% NORMALIZE RESPONSE
% ==========================================================

vesselResponse = mat2gray(vesselResponse);

%% =========================================================
% APPLY FOV MASK
% ==========================================================

maskFiles = dir(fullfile(maskFolder, '*.gif'));

if ~isempty(maskFiles)

    fovMask = imread(fullfile( ...
        maskFiles(imageIndex).folder, ...
        maskFiles(imageIndex).name));

    fovMask = fovMask > 0;

    vesselResponse(~fovMask) = 0;

else

    warning('FOV mask not found. Skipping mask operation.');

end

%% =========================================================
% DISPLAY RESULTS
% ==========================================================

figure( ...
    'Name','Phase 3 - Vessel Enhancement', ...
    'NumberTitle','off');

subplot(1,3,1);

imshow(greenChannel);

title('Green Channel');

subplot(1,3,2);

imshow(enhancedImage);

title('CLAHE Enhanced');

subplot(1,3,3);

imshow(vesselResponse);

title('Multi-Scale Vessel Response');

%% =========================================================
% DISPLAY STRONGER RESPONSE
% ==========================================================

figure( ...
    'Name','Enhanced Blood Vessel Structure', ...
    'NumberTitle','off');

imshow(vesselResponse);

title('Multi-Scale Multi-Orientation Vessel Enhancement');

%% =========================================================
% INFORMATION
% ==========================================================

fprintf('\n============================================\n');
fprintf('RESULT INFORMATION\n');
fprintf('============================================\n');

fprintf('Image: %s\n', imageFiles(imageIndex).name);

fprintf('Number of scales      : %d\n', ...
    length(scales));

fprintf('Scales used            : ');

fprintf('%.1f ', scales);

fprintf('\n');

fprintf('Number of orientations : %d\n', ...
    length(angles));

fprintf('Orientation step       : 15 degrees\n');

fprintf('\nVessel enhancement completed.\n');

fprintf('============================================\n');
fprintf('PHASE 3 COMPLETED\n');
fprintf('============================================\n');