% --------------------------------------------------------------
% Author:   Rino Beeli
% Created:  12.2019
%
% Copyright (c) <2019>, <rinoDOTbeeli(at)uzhDOTch>
%
% All rights reserved.
% --------------------------------------------------------------

% clear variables and command window
clc; clear; close all force;

% import files in classes folder
addpath('classes');

% import all library objects
lData = libdata();
lCov = libcovariance();
lVis = libvis();

% lecture dataset
[datasetName, rets, frequency] = lData.readLectureDataset();

% % Dow Jones Industrial Average 30
% [datasetName, rets, frequency] = lData.readDJIA30Dataset();

% last 4 years
rets4Y = rets((size(rets, 1) - 5*12):end, :);

% remove columns with NaN values
rets4Y = rets4Y(:, sum(isnan(rets4Y{:,:}), 1) == 0);
            
            
% sample covariance
sampleCov = lCov.sampleCov(rets4Y{:,:}) * 1000;

% OAS shrunk covariance
shrunkCov = lCov.sampleCovShrinkageOAS(rets4Y{:,:}) * 1000;

labels = rets4Y.Properties.VariableNames;
labels = cellfun(@(str) str(1:min(length(str), 18)), labels, 'uniformoutput',0);


f = lVis.newFigure('Sample covariance vs. Shrinkage', 200, 200, 1800, 600);
tiledlayout(1, 3, 'Padding','compact');
nexttile; plotCovMat('Sample covariance matrix', sampleCov, labels, labels);
nexttile; plotCovMat('Shrunk covariance matrix', shrunkCov, labels, []);
nexttile; plotCovMat('Difference: Shrunk - Sample covariance matrix', shrunkCov - sampleCov, labels, []);

% print to PDF
lVis.printFigure(gcf, sprintf("output/dataset=%s-covariance_analysis.pdf", datasetName));



function plotCovMat(titleStr, covMat, xLabels, yLabels)
    n = size(covMat, 1);
    imagesc(covMat); % plot the matrix
    set(gca, 'XTick', 1:n); % center x-axis ticks on bins
    set(gca, 'YTick', 1:n); % center y-axis ticks on bins
    set(gca, 'XTickLabelRotation', 90'),
    set(gca, 'XTickLabel', xLabels); % set x-axis labels
    set(gca, 'YTickLabel', yLabels); % set y-axis labels
    title(titleStr, 'FontSize', 14); % set title
    colormap('jet')
    colorbar;
end


