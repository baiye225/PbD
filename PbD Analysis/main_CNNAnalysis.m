clc, close all

% % get csv file folder
% FileFolder = fullfile('.', 'Results', 'MatFiles');
% 
% % get file name
% FileName = 'Result_SIA_Multiple_10pts.mat';
% 
% % get path
% DataPath = fullfile(FileFolder, FileName);
% 
% % get table
% load(DataPath);
% 
% % get results
% resultsTable = Result_SIA_Multiple_10pts;
netName             = resultsTable.(5).(1);
TrainingAccuracy    = resultsTable.(6).(1);
ValidationAccuracy  = resultsTable.(6).(3);


% create CNN accuracy table
ResultTable = [netName, TrainingAccuracy/100, ValidationAccuracy/100]';

% % bar plot
% figure
% x   = 1: 1: length(netName); 
% y1  = TrainingAccuracy';
% y2  = ValidationAccuracy';
% b   = bar(x, [y1; y2]);
% 
% 
% % setup parameters of the figure
% b(1).FaceColor  = "red";
% b(2).FaceColor  = "yellow";
% b(1).BarWidth   = 0.4;
% b(2).BarWidth   = 0.4;
% text((1:length(netName)) - 0.1, y1, num2str(round(y1')),...
%     'vert', 'bottom', 'horiz', 'right');
% text((1:length(netName)) + 0.05, y2, num2str(round(y2')),...
%     'vert', 'bottom', 'horiz', 'left');
% grid minor;
% axis padded
% set(gca, 'xticklabel', netName);
% set(get(gca, 'XAxis'), 'FontWeight', 'bold');
% xlabel("Pre-trained Network")
% ylabel("Accuracy %")
% % set(get(gca, 'XAxis'), 'TickLabelRotation', 90)
% legend("training accuracy", "validation accuracy", "Location", "southeast")
% title("accuracy of pre-trained networks", "Independent 2D plot")
% % title("accuracy of pre-trained networks", "Integrated 2D plot")