clc, clear, close all

% get csv file path
DataPath = fullfile('.', 'Results', 'Accuracy Results.xlsx');

% read csv file without the 1st row(title)
Data = readmatrix(DataPath, 'Sheet', '600 times Data Pts 200 to 5', 'Range', 'C3:F34');

% pick up accuracy
NumPts   = [200; 180; 160; 150; 120; 100; 40; 20; 15; 10; 5];
LabelPts = transpose(string(NumPts));
DataAccuracy = zeros(length(NumPts), 4);
for i = 1: 1: length(NumPts)
    DataAccuracy(i, :) = Data(2 + 3 * (i - 1), :) * 100;
end

ANN      = DataAccuracy(:, 1);
ANNKFold = DataAccuracy(:, 2);
SVM      = DataAccuracy(:, 3);
SVMKFold = DataAccuracy(:, 4);

% plot accuracy trend
figure
hold on
plot(NumPts, ANN, '-*');
plot(NumPts, ANNKFold, '-*');
plot(NumPts, SVM, '-o');
plot(NumPts, SVMKFold, '-o');
hold off

% setup parameters
grid minor;
xtickName = flip(LabelPts);
set(gca, 'xlim', [5 200])
% set(gca, 'XTickLabel', xtickName);
xticks(flip(NumPts'));
xticklabels(xtickName);
set(gca, 'xdir', 'reverse');
xlabel('The Number of Data Points', FontWeight='bold');
ylabel('Validation Accuracy (%)', FontWeight='bold');
legend('ANN', 'ANN K-Fold', 'SVM', 'SVM F-Fold', 'Location','best');
title('Accuracy Trend in Different Number of Data Points')