# Retinal_Blood_Vessel_Extraction-
Developed a MATLAB-based retinal blood vessel segmentation system using the DRIVE dataset, combining CLAHE, multi-scale matched filtering, optimized Otsu thresholding, and morphological refinement for vessel detection and evaluation.

## Overview
This project implements an automatic retinal blood vessel segmentation system using MATLAB and the DRIVE dataset. It uses classical image-processing techniques to enhance and identify retinal blood vessels for computer-aided retinal image analysis.

## Methodology
1. **Green Channel Extraction:** Extracts the green channel for better vessel contrast.
2. **CLAHE Enhancement:** Improves local contrast and vessel visibility.
3. **Multi-Scale Matched Filtering:** Detects vessels of different widths and orientations.
4. **Otsu Thresholding:** Estimates the initial segmentation threshold.
5. **Threshold Optimization:** Selects the optimal threshold factor based on the training Dice score.
6. **Morphological Refinement:** Removes small isolated regions and refines the vessel map.
7. **Performance Evaluation:** Compares segmentation results using standard evaluation metrics.

## Dataset
- **Dataset:** DRIVE (Digital Retinal Images for Vessel Extraction)
- **Total Images:** 40
- **Image Resolution:** 768 × 584 pixels
- **Processing Resolution:** 512 × 512 pixels

## Technologies Used
- MATLAB
- Image Processing Toolbox
- CLAHE
- Multi-Scale Matched Filtering
- Otsu Thresholding
- Morphological Image Processing

## Performance Metrics
- Dice Coefficient
- Sensitivity
- Specificity
- Precision
- F1-Score
- Matthews Correlation Coefficient (MCC)
- Accuracy
- Intersection over Union (IoU)
- ROC-AUC
- PR-AUC

## Experimental Results

| Metric | Proposed Method |
|---|---:|
| Dice | 0.64264 |
| Sensitivity | 0.70693 |
| Specificity | 0.95114 |
| Precision | 0.61025 |
| MCC | 0.61442 |
| Accuracy | 0.92966 |
| IoU | 0.47345 |
| ROC-AUC | 0.9038 |
| PR-AUC | 0.6115 |

**Optimal Threshold Factor:** 0.80

## Additional Experiments
- Single-scale vs. multi-scale matched filtering
- Threshold optimization and ablation study
- Hessian-based vessel enhancement
- Matched-filter and Hessian response fusion

## Project Objective
To develop an efficient classical image-processing framework for retinal blood vessel segmentation that can support further retinal image analysis and computer-aided ophthalmic applications.

## Future Scope
- Testing on additional retinal datasets.
- Exploring advanced vessel enhancement techniques.
- Improving thin-vessel detection.
- Integrating deep-learning-based refinement.

## Author
Developed as an academic research project using MATLAB.
