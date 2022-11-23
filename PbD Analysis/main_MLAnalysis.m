clear, clc, close all

%% main

% initialize the class
obj1 = RobotMotionML; 

% Machine learning analysis
Path                    = obj1.Path1;                                       % 1. Get directory
[Position, DataSize]    = obj1.ReadAllData(obj1, Path);                     % 2. Read data           
PositionNew             = obj1.InterPosAll(obj1, Position, DataSize);       % 3. Resample data
PositionNew             = obj1.InterPosPartAll(obj1, PositionNew);          % 3.2 Partition(optional)
obj1.PlotAllData(PositionNew);                                              % 4. Plot data
Result                  = obj1.MLAnalysis(obj1, PositionNew);               % 5. Machine Learning analysis
% obj1.MVRAnalysis(obj1, PositionNew);                                        % 6. Multivariate Regression
beep;




















