clc, clear, close all

% main
obj                     = RobotMotionML;                                    % initialize the class
obj2                    = SavePathImg;                                      % ~~~
obj2.MainFolder         = "DataJPG_Complicated_20Pts_5_85";

Path                    = obj.Path1;                                        % 1. Get directory
[Position, DataSize]    = obj.ReadAllData(obj, Path);                       % 2. Read data
PositionNew             = obj.InterPosAll(obj, Position, DataSize);         % 3. Resample data
obj2.PlotAndSave(obj, obj2, PositionNew);                                        % 4. Plot and save images


