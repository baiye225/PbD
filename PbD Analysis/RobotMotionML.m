% Machine Learning For Robot Motion
classdef RobotMotionML  
    properties
        % main database samples
        Path1 = fullfile('..', 'Data');

        % backup data samples
        Path2 = fullfile('..', 'Other Data', 'BackUpData5');

        % import SavePathImg class
        obj2  = SavePathImg;

        % switch between binary and multiple classification
        % eg: ["Simple", "Complicated"]
        ClassMethod = "Complicated"
        
        % manually change the number of data points(0 denotes no action)
        SetPtsNumSwitch = "True";
        DataPointNum = 20;
        
        %{
        special partition of data path
        1. divide a whole path into part1 and part2;
        2. part each part with designated ratio;
        %}
        SetPartitionSwitch = "False";
        PartitionPara = [0.8, 0.05;
                         0.1, 0.9;
                         0.1, 0.05];

        % grade division percentitle
        DivisionMethod          = "Grade" % "Time" or "Grade"
        GradeDivisionPercentile = [0.05 0.85];

        % the number of set of train-test data by random division
        NumSet = 1000;
        NumKFoldSet = 100;

        % paramter for data set waitbar text
        Para = {["ANN", "Random Division"];
                ["SVM", "Random Division"]; 
                ["ANN", "K-Fold"];
                ["SVM", "K-Fold"]};
    end

    methods (Static)
        %% function: read success and failure data respectively
        function [Position, DataSize] = ReadAllData(obj, Path)
            % read success data
            PathSuccess = fullfile(Path, 'success');
            [PositionSuccess, DataSizeSuccess] =....
                                            obj.ReadData(obj, PathSuccess);

            % read failure data
            PathFailure = fullfile(Path, 'failure');
            [PositionFailure, DataSizeFailure] =...
                                            obj.ReadData(obj, PathFailure);

            % merge two of them
            Position.success = PositionSuccess;
            Position.failure = PositionFailure;
            DataSize = [DataSizeSuccess; DataSizeFailure];  
        end

        %% function: read and pre-process all data in a single folder
        function [Position, DataSize] = ReadData(obj, Path)
            % list all file
            FolderPath = dir(Path);
            FolderList = FolderPath(3:end); %  skip the 1st is ".", 2nd is ".."
            FileSize = size(FolderList, 1);
            
            % sort folderlist by filename
            [~, reindex] = sort( str2double( regexp( {FolderList.name},...
                                '\d+', 'match', 'once' )));
            FolderList = FolderList(reindex);

            % read all data 
            Position = {FileSize, 1};       % store all data
            DataSize = zeros(FileSize, 1);  % store the size of each data
         
            % read all samples one by one
                for i = 1: 1: FileSize
            
                    % generate the path of the current data file    
                    DataPath = fullfile(FolderList(i).folder,...
                                    FolderList(i).name);
            
                    % read csv file without the 1st row(title)
                    Data = readmatrix(DataPath, 'Range', 2);

                    % read data
                    Position{i} = obj.PreProcessData(Data(:, [1,8:10]));
                    DataSize(i) = length(Data(:, 1));
                end
        end
        
        %% function: pre-process single sample of data (coordinate transformation)
        function data = PreProcessData(data)
            % set up start time and start position as 0
            data = data - data(1,:);
        
            % set up start time as 0 and convert ms into s
            time = data(:,1) / 10^6;
        
            % swap x, y, z
            x = data(:, 2); 
            y = -data(:, 4); 
            z = data(:, 3);
        
            % integrate the results
            data = [time, x, y, z];
        end
        
        %% function: interpolation of single type of position data
        function DataNew = InterPosAll(obj, Data, DataSize)
            % check if MeanSize is manually set or not
            if obj.SetPtsNumSwitch == "True"    
                DataSize = obj.DataPointNum;
                fprintf("-> Set up Data Size as %d Points\n", DataSize)
            elseif obj.SetPtsNumSwitch == "False"
                disp("-> No DataNum Command")
            else
                disp("-> Cannot Confirm Partition, No Action Required")
            end
            DataNew.success = obj.InterPos(Data.success, DataSize);        
            DataNew.failure = obj.InterPos(Data.failure, DataSize); 
        end

        %% function: interpolation of single type of position data
        function PositionNew = InterPos(Position, DataSize)
            % prepare parameters
            PositionNew = {length(Position), 1}; % store all resampled data
            MeanSize = round(mean(DataSize));
          
            % interpolate all data
                for i = 1 : 1 : length(Position)
                    time = transpose(Position{i}(:, 1));
                    timeNew = linspace(0, time(end), MeanSize);
                    DataNew(:, 1) = timeNew';
                    for j = 2 : 1 : 4
                        SinglePos = transpose(Position{i}(:, j));          
                        SinglePosNew = interp1(time, SinglePos, timeNew);
                        DataNew(:, j) = SinglePosNew';
                    end
                    PositionNew{i} = DataNew;
                end
        end
        
        %% function: interpolation of single type of position data(partition)
        function DataNew = InterPosPartAll(obj, Data)
            if obj.SetPartitionSwitch == "True"
                [DataNew.success, PartResult] = obj.InterPosPart(obj, Data.success);        
                [DataNew.failure, ~] = obj.InterPosPart(obj, Data.failure); 
                obj.DisplayPartitionMethod(PartResult);
            elseif obj.SetPartitionSwitch == "False"
                DataNew = Data;
                disp("-> No Partition Command")
            else
                DataNew = Data;
                disp("-> Cannot Confirm Partition, No Action Required")
            end
        end

        %% function: interpolation of special partition
        function [PositionNew, PartResult] = InterPosPart(obj, Position)
            % prepare parameters
            PositionNew = {length(Position), 1}; % store all resampled data
            PositionSize = length(Position{1}(:, 1));

            % get the number of points at each part and each part ratio
            n = length(obj.PartitionPara(:, 1));
            PartNum = zeros(n, 1);
            RatioNum = zeros(n, 1);
            for i = 1: 1: n
                PartNum(i) = round(PositionSize * obj.PartitionPara(i, 1));
                RatioNum(i) = round(PartNum(i, 1) * obj.PartitionPara(i, 2));
            end
            
            % interpolate all data            
            for i = 1 : 1 : length(Position)
                time = transpose(Position{i}(:, 1));
                PartIndex = 1;
                DataTimeNew = [];

                % prepare time
                for j = 1: 1: length(PartNum)
                    StartIndex  = PartIndex;
                    EndIndex    = PartIndex + PartNum(j) - 1;
                    timePartOld{j} = time(StartIndex: EndIndex);
                    timePartNew{j} = linspace(timePartOld{j}(1), timePartOld{j}(end), RatioNum(j));
                    PartIndex = PartIndex + PartNum(j);
                    DataTimeNew = [DataTimeNew timePartNew{j}];
                end

                % integrate new time in the Data
                DataNew(:, 1) = DataTimeNew';
                
                % interpolate position
                for k = 2 : 1 : 4
                    SinglePos = transpose(Position{i}(:, k));
                    PartIndex = 1;
                    DataSinglePosNew = [];
                    for j = 1: 1: length(PartNum)
                        StartIndex   = PartIndex;
                        EndIndex     = PartIndex + PartNum(j) - 1;
                        SinglePosOld = SinglePos(StartIndex: EndIndex);
                        SinglePosNew = interp1(timePartOld{j}, SinglePosOld, timePartNew{j});
                        PartIndex = PartIndex + PartNum(j);
                        DataSinglePosNew = [DataSinglePosNew, SinglePosNew];
                    end
                    DataNew(:, k) = DataSinglePosNew';
                end

                % integrate new position in the Data
                PositionNew{i} = DataNew;
            end
                
            %
            PartResult.PartPercent = obj.PartitionPara;
            PartResult.ParNum = [PartNum, RatioNum];
        end

        %% function: Display Partition Method
        function DisplayPartitionMethod(PartResult)
            % display title line
            fprintf("------interpolation with Designated Partition\n");  
            fprintf("------Divison Part:------\n")

            % display all partitions
            for i = 1: 1: length(PartResult.PartPercent(:, 1))
                fprintf("<%d>: %d%%(%d Pts): %d%%(%d Pts) of the Part\n",...
                        i, PartResult.PartPercent(i, 1) * 100,...
                        PartResult.ParNum(i, 1),...
                        PartResult.PartPercent(i, 2) * 100,...
                        PartResult.ParNum(i, 2));   
            end
            fprintf("\n");
        end
        
        %% function: resample position data
        function PositionNew = ResamplePos(Position, DataSize)
            % prepare parameters
            PositionNew = {length(Position), 1};       % store all resampled data
            MeanSize = round(mean(DataSize));
        
            % resample all data
            for i = 1 : 1 : length(Position)
                for j = 1 : 1 : 4
                    DataNew(:, j) = ...
                        resample(Position{i}(:,j), MeanSize, DataSize(i));
                end
                PositionNew{i} = DataNew;
            end
        
        end
        
        %% function: test single data
        function PlotSingleData(Position, PositionNew)
            figure
            x0 = Position(:,2);
            y0 = Position(:,3);
            z0 = Position(:,4); 
        
            x = PositionNew(:,2);
            y = PositionNew(:,3);
            z = PositionNew(:,4);
            plot3(x0, y0, z0, '.-')
        
            hold on
            plot3(x, y, z, 'o-')
        
            grid on
            title("Comparison between original data and resampled data")
            legend("Oringinal", "Resampled")
        end

        %% function: plot success and failure data respectively
        function PlotAllData(Position)            
            % prepare all data and parameters         
            DataNum.success = length(Position.success);
            DataNum.failure = length(Position.failure);
            DataNum.all     = DataNum.success + DataNum.failure;

            % start to plot all position
            figure
            
            % success
            for i =  1: 1: DataNum.success
                x = Position.success{i}(:, 2);
                y = Position.success{i}(:, 3);
                z = Position.success{i}(:, 4);
                h.success{i} = plot3(x, y, z, '.-g');
                hold on
            end
            
            % failure
            for i = 1: 1: DataNum.failure
                x = Position.failure{i}(:, 2);
                y = Position.failure{i}(:, 3);
                z = Position.failure{i}(:, 4);
                h.failure{i} = plot3(x, y, z, '.-r');
                hold on;
            end
                        
%             % optimal success path(optional)
%             x = Position.OptPath(:, 2);
%             y = Position.OptPath(:, 3);
%             z = Position.OptPath(:, 4);
%             h.optimal = plot3(x, y, z, '-hk', 'LineWidth', 2);

            % setup parameters
            hold off;
            grid on
            axis equal;
            xlabel("x (mm)");
            ylabel("y (mm)");
            zlabel("z (mm)");           
            legend([h.success{end}, h.failure{1}],...
                    {'success', 'failure'},...
                    'Location', 'northeast',...
                    'FontSize', 20);
            titleline = ["Hand Motion of Insertion Assembly Task";
                         compose("(%d samples: %d success + %d failure)",...
                         DataNum.all, DataNum.success, DataNum.failure)];
            title(titleline(1), titleline(2));

        end
             
        %% function: plot all data in a single folder
        function PlotData(Position)
            DataNum = length(Position);

            % start to plot all position
            figure
            for i = 1: 1: DataNum
                x = Position{i}(:, 2);
                y = Position{i}(:, 3);
                z = Position{i}(:, 4);
                plot3(x, y, z);
                hold on
            end
            hold off

            % setup parameters
            grid on
            xlabel("x (mm)")
            ylabel("y (mm)")
            zlabel("z (mm)")
            axis equal
            title({"Hand Motion of Insertion Assembly Task"...
                "<" + num2str(DataNum) + " samples" + ">"})
        end

        %% function: Machine Learning Analysis
        function ResultTable = MLAnalysis(obj, Data)

            % -----------------Pre Process Data----------------------------
            % step1-1: strech (x,y,z) from 3 x N into 1 x 3N
            DataANN = obj.MLPreProcessAll(obj, Data);
            
            % step1-2: add output for all data
            DataANN = obj.MLAddOutputAll(obj, DataANN);
            
%             % ------------------Train and Test-----------------------------
%             %{ 
%               step2-1: randomly split training and testing data, success
%             and failure data 
%             %}
%             [TrainData, TestData] = obj.GetTrainTestData(DataANN);
%             
%             % step2-2: ANN train and test data
%             Result.ANN = obj.MLTrainTest(obj, @obj.ANNTrainTest,...
%                                          TrainData, TestData);
%             obj.DisplayAndPlotResults(obj, Result.ANN)
% 
%             % step2-3: SVM train and test data
%             Result.SVM = obj.MLTrainTest(obj, @obj.SVMTrainTest,...
%                                          TrainData, TestData);
%             obj.DisplayAndPlotResults(obj, Result.SVM)
% 
% 
%             -------------------Train and Test K-Fold---------------------
%             step3-1: Get train and test data by k-fold
%             [KTrainData, KTestData] = obj.GetTrainTestDataKFold(DataANN);
% 
%             step3-2: ANN train and test data by using K-fold
%             Result.ANNKFold = obj.MLTrainTestKFold(obj, @obj.ANNTrainTest,...
%                                                     KTrainData, KTestData);
%             obj.DisplayKFoldResults(Result.ANNKFold)
% 
%             step3-3: SVM train and test data by using K-fold
%             Result.SVMKFold = obj.MLTrainTestKFold(obj, @obj.SVMTrainTest,...
%                                                     KTrainData, KTestData);
%             obj.DisplayKFoldResults(Result.SVMKFold)

            % --------------------Train and Test Set-----------------------
            % step4-1: Get train and test data set
            [TrainSet, TestSet] = obj.GetTrainTestDataSet(obj,...
                                                      DataANN, obj.NumSet);

            % step4-2: ANN train and test data set
            Result.ANNSet = obj.MLTrainTestSet(obj, @obj.MLTrainTest,...
                                                    @obj.ANNTrainTest,....
                                                    TrainSet, TestSet, ...
                                                    obj.Para{1, :});
            % step4-3: SVM train and test data set
            Result.SVMSet = obj.MLTrainTestSet(obj, @obj.MLTrainTest,...
                                                    @obj.SVMTrainTest,....
                                                    TrainSet, TestSet, ...
                                                    obj.Para{2, :});

            % -------------------Train and Test Set K-Fold-----------------
            [KTrainSet, KTestSet] =...
               obj.GetTrainTestDataKFoldSet(obj, DataANN, obj.NumKFoldSet);

            % step4-2: ANN train and test K-Fold data set
            Result.ANNKFoldSet = obj.MLTrainTestSet(obj, @obj.MLTrainTestKFold,...
                                                         @obj.ANNTrainTest,....
                                                         KTrainSet, KTestSet, ...
                                                         obj.Para{3});
            % step4-3: SVM train and test K-Fold data set
            Result.SVMKFoldSet = obj.MLTrainTestSet(obj, @obj.MLTrainTestKFold,...
                                                         @obj.SVMTrainTest,....
                                                         KTrainSet, KTestSet, ...
                                                         obj.Para{4});

            % step5: integrate as as result table
            ResultTable = obj.GetResultTable(Result);
        end
        
        %% function: ANN all data pre-process (step1)
        function DataANN = MLPreProcessAll(obj, Data)
            % get label if multiple classifications is needed(optional)
            if obj.DivisionMethod == "Time"
                ResultLabel = obj.GetTimeLabel(obj, Data);
            elseif obj.DivisionMethod == "Grade"
                ResultLabel = obj.GetPathLabel(obj, Data);
            else
                disp("Error: Cannot confirm the classification method!!!")
            end
            
            % integrade label in Data struct
            DataANN.successLabel = ResultLabel.success;
            DataANN.failureLabel = ResultLabel.failure;

            % pre-process all success data
            for i = 1: 1: length(Data.success)
                DataANN.success(i, :) = obj.MLPreProcess(Data.success{i});
%                 DataANN.successTime(:, i) = Data.success{i}(:, 1);
            end
 
            % pre-process all failure data
            for j = 1: 1: length(Data.failure)
                DataANN.failure(j, :) = obj.MLPreProcess(Data.failure{j});
%                 DataANN.failureTime(:, i) = Data.failure{i}(:, 1);
            end

        end

        %% function: label all success path referred time
        function TimeLabel = GetTimeLabel(obj, Data)
            % get elapsed time of all path
            MotionTime = obj.GetElapsedMotionTime(Data);

            % filter them as multiple types
            TimeLabel = obj.GetLabel(obj, Data, MotionTime.success, [3, 2, 1]);
        end

        %% collect elapsed time label of all motion        
        function MotionTime = GetElapsedMotionTime(Position)

            % prepare classification type
            ClassTypes   = ["success", "failure"];  
        
            % initialize motion time and motion time lable
            MotionTime.success      = zeros(length(Position.success), 1);
            MotionTime.failure      = zeros(length(Position.failure), 1);
              
            % start to collect motion time
            for i = 1: 1: length(ClassTypes)            
                % get the current data type (success or failure)
                CurrentType = ClassTypes(i);
                n = 0;

                % start to find max and min x,y,z
                for j =  1: 1: length(Position.(CurrentType))
            
                    % get elapsed time of the current motion
                    n = n + 1;
                    MotionTime.(CurrentType)(n, 1) =...
                                        Position.(CurrentType){j}(end, 1);
                end
            end

            % motion time histogram
            figure
            histogram(MotionTime.success);
            xlabel("Elapsed Time (s)")
            ylabel("Count")
            title("Histogram of Assembly Task", "Elapsed Time")
         
        end

        %% function: label all success path referred optimal path
        function GradeLabel = GetPathLabel(obj, Data)
          % get the optimal path
          OptimalPath = obj.CalculateOptimalPath(Data.success);
          
          % get grade of all path
          DataGrade = obj.GetAllPathGrade(obj, Data.success, OptimalPath);

          % filter them as multiple types
          GradeLabel = obj.GetLabel(obj, Data, DataGrade, [1, 2, 3]);

          % plot different labels of success path(optional)
          obj.PlotAllDataInGradeLabel(obj, Data, OptimalPath, GradeLabel.success)
         end
         
        %% function: calculate grade of all path
        function DataGrade = GetAllPathGrade(obj, Data, OptimalPath)
            % get the number of data samples
            DataNum = length(Data);

            % get the number of data points
            n = length(Data{1}(:, 1));
            
            % get threshold of each time point
            NumStd = 1; % the number of standard diviation (mean +/- std * 2)
            PathThreshold = NumStd * OptimalPath.std3D;
            
            % initialize all Data detailed grade
            dataGrade = zeros(DataNum, n); % detailed grade

            % start to calculate accumulated points      
            for i = 1: 1: DataNum % each data sample

                % initialize each single data grade at each time points
                
                % start to check each grade point
                % if the point distance error is in the current threshold,
                % add 1 bonus point
                for j = 2: 1: n % each time point 
                    CurrentDistance = norm(Data{i}(j, 2:end) - OptimalPath.path(j, :));
                    dataGrade(i, j) = obj.GradeAlgorithm(CurrentDistance, PathThreshold(j));
                end               
            end
            
            % get overall grade of each path
            DataGrade = sum(dataGrade, 2);

            % data grade histogram
            figure
            histogram(DataGrade, 'FaceColor', 'red');
            xlabel("Motion Grade (pts)")
            ylabel("Count")
            title("Histogram of Assembly Task", "Motion Grade")
         end
        
        %% function: Get current grade via designated algorithm
        function grade = GradeAlgorithm(error, standard)
            if error < standard
                grade = 0.7 * (standard - error) / standard;
            elseif error > standard && error  < 2 * standard
                grade = 0.3 * (1 - (error - standard) / standard);
            else
%                 grade = -0.3 * (error - 2 * standard) / standard;
                grade = 0;
            end
         end

        %% function: Get current grade via designated algorithm2
        function grade = GradeAlgorithm2(error, standard)
              if error <= standard 
                grade = 1;
              else
                  grade = 0;
              end
         end

        %% function: Get motion label based on motion grade or elapsed time
        function ResultLabel = GetLabel(obj, Data, DataPoint, Label)
            % set up division based on designated percentiles 
            CurrentPercentile = obj.GradeDivisionPercentile;
            GradeDivision = quantile(DataPoint, CurrentPercentile);
            fprintf("-> Division Method: %s\n", obj.DivisionMethod);
            fprintf("-> Division Percentile: %0.1f%% and %0.1f%%\n\n",...
                CurrentPercentile(1) * 100, CurrentPercentile(2) * 100);

            % initialize grade label
            ResultLabel.success = ones(length(Data.success), 1);
            ResultLabel.failure = -ones(length(Data.failure), 1);
            
            % assign grade lable based on grade division
            if obj.ClassMethod == "Complicated"
                % add 1, 2, 3 classifications to success and 0 to failure
                ResultLabel.success(DataPoint < GradeDivision(1)) = Label(1);
                ResultLabel.success(DataPoint >= GradeDivision(1) &...
                                   DataPoint <= GradeDivision(2)) = Label(2);
                ResultLabel.success(DataPoint > GradeDivision(2)) = Label(3);
            end
         end
        
        %% function: plot success and failure data respectively
        function PlotAllDataInGradeLabel(obj, Data, OptimalPath, GradeLabel)              
            % divide each kind of success path
            Data.good = Data.success(find(GradeLabel == 3));
            Data.intermediate = Data.success(find(GradeLabel == 2));
            Data.poor = Data.success(find(GradeLabel == 1));
            LabelNames = ["good", "intermediate", "poor"];

            % start to plot all position        
            % good success
            for i = 1: 1: 3
                figure
                % plot all paths in a kind
                LabelName = LabelNames(i); 
                for j =  1: 1: length(Data.(LabelName))
                    x = Data.(LabelName){j}(:, 2);
                    y = Data.(LabelName){j}(:, 3);
                    z = Data.(LabelName){j}(:, 4);
                    h.(LabelName){j} = plot3(x, y, z, '.-g');
                    hold on
                end

                % plot optimal path
                h.optimal = plot3(OptimalPath.path(:, 1), OptimalPath.path(:, 2),...
                                  OptimalPath.path(:, 3), '.-r');

                % plot threshold sphere
                h.thresholdSphere =....
                    obj.PlotThresholdSphere(OptimalPath.path, OptimalPath.std3D);

                hold off
                grid on
                axis equal;
                xlabel("x (mm)");
                ylabel("y (mm)");
                zlabel("z (mm)");
                legend([h.(LabelName){end}, h.optimal],...
                    {LabelName, 'optimal'},...
                    'Location', 'northeast',...
                    'FontSize', 20);
                titleline = ["Hand Motion of Insertion Assembly Task";
                compose("(%d samples: %d %s success)",...
                        length(Data.success), length(Data.(LabelName)),...
                        LabelName)];
                title(titleline(1), titleline(2));
            end     
           
        end
        
        %% function: plot threahold of each time point as a sphere
        function h = PlotThresholdSphere(center, radius)
            [x, y, z] = sphere;
            for i = 1: 1: length(center(:, 1))         
                xNow = x * radius(i);
                yNow = y * radius(i);
                zNow = z * radius(i);
                h{i} = surfl(xNow + center(i, 1), yNow + center(i, 2) , zNow + center(i, 3));
                set(h{i}, 'FaceAlpha', 0.5);
                shading interp;
            end
        end
        
        %% function: ANN single data pre-process (step1-1)
        function dataNew = MLPreProcess(data)
            % assemble 3 demention data into 1 demention
            dataNew = transpose([data(:,2); data(:,3); data(:,4)]);
        end
        
        %% function: ANN add output for all data (step2)
        function Data = MLAddOutputAll(obj, Data)       
            % determine simple success or complicated success
            if obj.ClassMethod == "Simple"
                % add output 1 as success
                Data.success(:, end + 1) = ones(length(Data.success(:, 1)), 1);

            elseif obj.ClassMethod == "Complicated"
                % add outputs(1,2,3) based on MotionLabels 
                Data.success(:, end + 1) = Data.successLabel;
            else
                disp("cannot confirm partial classification!!!");
            end


            % add output 0 as failure
            Data.failure(:, end + 1) = -ones(length(Data.failure(:, 1)), 1);
        end

        %% function: distribute sets of train-test data
        function [TrainSet, TestSet] = GetTrainTestDataSet(obj, Data, NumSet)
           % initialize set of train and test data
           TrainSet = cell(NumSet, 1);
           TestSet = cell(NumSet, 1);

           % start to generate set data
            for i = 1: 1: NumSet
                [Train, Test] = obj.GetTrainTestData(Data);
                TrainSet{i} = Train;
                TestSet{i} = Test;
            end
       end
        
        %% function: distribute training data and testing data  (step3)
        function [Train, Test] = GetTrainTestData(Data)
            % 300 success data: 270 training and 30 testing
            [TrainData.success, ~, TestData.success] =...
                                    dividerand(Data.success', 9/10, 0, 1/10);

            % 50 failure data: 40 training and 10 testing
            [TrainData.failure, ~, TestData.failure] =...
                                    dividerand(Data.failure', 9/10, 0, 1/10);

            % integrate training data and testing data
            TrainData    = [TrainData.success'; TrainData.failure'];
            TestData     = [TestData.success'; TestData.failure'];

            % get training input/output and test input/output
            Train.Input  = TrainData(:, 1:end-1);
            Train.Output = TrainData(:, end);
            Test.Input   = TestData(:, 1:end-1);
            Test.Output  = TestData(:, end);
        end
        
        %% function Train, Test, Analyze, Plot Data set
        function ResultSetAll = MLTrainTestSet(obj, MLTrainTestFunc, MLFunc, TrainDataSet, TestDataSet, Para)
            % initialize parameters
            n = length(TrainDataSet);
            ResultSet = cell(1, n);
            ModelTyple = Para(1);
            DataSelection = Para(2);

            % initialize waitbar paramters
            f = waitbar(0, "Train and Test Data Set...");

            % start get result set
            for i = 1: 1: n
                % train and test data
                ResultSet{i} = MLTrainTestFunc(obj, MLFunc,...
                                          TrainDataSet{i}, TestDataSet{i});

                ResultSetAll.ElapsedTime(i) = ResultSet{i}.ElapsedTime;
                ResultSetAll.TrainAccuracy(i) = ResultSet{i}.TrainAccuracy;
                ResultSetAll.TestAccuracy(i) = ResultSet{i}.TestAccuracy;

                % update waitbar
                MsgLine1 = sprintf("%s Process data set with %s",...
                                    ModelTyple, DataSelection);
                MsgLine2 = sprintf("%d/%d (%0.2f%%)", i, n, (i/n)*100);
                msg      = {MsgLine1, MsgLine2};
                waitbar(i/n, f, msg);
            end

            % close waitbar
            close(f)
            
            % integrate other result
            ResultSetAll.ModelType = ModelTyple;
            ResultSetAll.DataSelection = DataSelection;
            ResultSetAll.Num = n;
            ResultSetAll.DataPointNum = ResultSet{1}.DataPointNumNow;
            
            % display numerical result
            obj.DisplayNumericalResultsSet(ResultSetAll)
        end

        %% function: Train, Test, Analyze, Plot Data.
        function Result = MLTrainTest(obj, MLFunc, TrainData, TestData)
            [TrainPredict, TestPredict, OtherPara] =...
                                            MLFunc(TrainData, TestData);

            % Get numerical results
            Result = obj.GetTrainTestAccuracy(TrainData, TestData,...
                                              TrainPredict,TestPredict);
            Result.ModelType    = OtherPara.ModelType;
            Result.DataPointNumNow = length(TrainData.Input(1, :)) / 3;
            Result.ElapsedTime  = OtherPara.ElapsedTime;
            Result.TrainData    = TrainData;
            Result.TestData     = TestData;
            Result.TrainPredict = TrainPredict;
            Result.TestPredict  = TestPredict;

        end
        
        %% function Get Training and Testing accuracy
        function Result = GetTrainTestAccuracy(TrainData, TestData,...
                                               TrainPredict,TestPredict)
            % train analysis
            Result.Trainloss     = immse(TrainPredict, TrainData.Output);
            Result.RSquareTrain  = 1 - sum((TrainData.Output - TrainPredict).^2)/...
                            sum((TrainData.Output - mean(TrainData.Output)).^2);
            TrainError           = TrainData.Output - TrainPredict;
            Result.TrainAccuracy = mean(1 - abs(TrainError ./ TrainData.Output));
            
            % test analysis
            Result.TestMSE        = immse(TestPredict,TestData.Output);
            Result.RsquareTest   = 1 - sum((TestData.Output - TestPredict).^2)/...
                            sum((TestData.Output - mean(TestData.Output)).^2);
            TestError            = TestData.Output - TestPredict;
            Result.TestAccuracy  = mean(1 - abs(TestError ./ TestData.Output));

        end     

        %% ANN train and Test
        function [TrainPredict, TestPredict, OtherPara] =...
                                        ANNTrainTest(TrainData, TestData)
            % initialize parameters
            tStart          = cputime;
            ModelType       = "ANN";
            trainFcn        = 'trainlm';  % Levenberg-Marquardt backpropagation.
            hiddenLayerSize = 3;     
            net = feedforwardnet(hiddenLayerSize, trainFcn);
%             net = fitnet(hiddenLayerSize);

            % make division
            net.divideParam.trainRatio  = 90/100;
            net.divideParam.valRatio    = 10/100;
            net.divideParam.testRatio   = 0/100;
            net.trainParam.showWindow   = false;
            
            
            % train and test data
            [net, ~]      = train(net, TrainData.Input', TrainData.Output');
            TrainPredict  = net(TrainData.Input')';
            TestPredict   = net(TestData.Input')';

            % display elapsed time
            ElapsedTime = cputime - tStart;

            % integrate other parameters
            OtherPara.ModelType = ModelType;
            OtherPara.ElapsedTime = ElapsedTime;
        end

        %% SVM train and test
        function [TrainPredict, TestPredict, OtherPara] =...
                                        SVMTrainTest(TrainData, TestData)
            % initialize parameters
            tStart      = cputime;
            ModelType   = "SVM";           
            % train and test data
%             Model           = fitrsvm(TrainData.Input, TrainData.Output,...
%                                     'Standardize',true);
            Model         = fitrsvm(TrainData.Input, TrainData.Output,...
                            'KernelFunction','linear','Standardize',true);
            TrainPredict  = predict(Model, TrainData.Input);                
            TestPredict   = predict(Model, TestData.Input);  

            % display elapsed time
            ElapsedTime = cputime - tStart;
            
            % integrate other parameters
            OtherPara.ModelType = ModelType;
            OtherPara.ElapsedTime = ElapsedTime;
        end
        
        %% function: display and plot result(single train-test of random division)
        function DisplayAndPlotResults(obj, Result)
            % display numerical result
            obj.DisplayNumericalResult(Result)   

            % plot results
            obj.PlotResult(obj, Result)
        end
        
        %% function: display numerical results
        function DisplayNumericalResult(Result)
            % display numerical results
            fprintf("------%s------\n", Result.ModelType);
            fprintf("CPU Time is: %0.4fs \n", Result.ElapsedTime)
            fprintf("Training resub MSE is: %f \n", Result.Trainloss);
            fprintf("Training resub R2 is: %f \n", Result.RSquareTrain);
            fprintf("Test MSE is: %f \n", Result.TestMSE);
            fprintf("Test R2 is: %f \n", Result.RsquareTest);
            fprintf("Training accuracy: %0.2f%% \n", Result.TrainAccuracy * 100);
            fprintf("Test accuracy: %0.2f%% \n\n", Result.TestAccuracy * 100);

        end

        %% function: display numerical results set(dataset)
        function DisplayNumericalResultsSet(Result)

            % display numerical results
            fprintf("------%s------\n", Result.ModelType);
            fprintf("------%s------\n", Result.DataSelection);
            fprintf("------%d data points------\n", Result.DataPointNum);     
            fprintf("Train and Test: %d times\n", Result.Num)
            fprintf("CPU Time is: %0.4fs \n", sum(Result.ElapsedTime))
            fprintf("Average Training accuracy: %0.2f%% \n",...
                    mean(Result.TrainAccuracy) * 100);
            fprintf("Average Test accuracy: %0.2f%% \n\n",...
                    mean(Result.TestAccuracy) * 100);

        end

        %% function display numerical results of K-fold
        function DisplayKFoldResults(Result)
            % display K-fold result
            fprintf("------%s K-fold------\n", Result.ModelType);
            fprintf("CPU Time is: %0.4fs\n", Result.ElapsedTime);  
            fprintf("Data points number: %d\n", Result.DataPointNumNow);
            fprintf("Training accuracy: %0.2f%% \n", Result.MeanTrainAccuracy * 100);
            fprintf("Test accuracy: %0.2f%% \n\n", Result.MeanTestAccuracy * 100);

        end
        
        %% function: plot graphical result
        function PlotResult(obj, Result)
            % get train test result
            TrainData    = Result.TrainData;
            TestData     = Result.TestData;
            TrainPredict = Result.TrainPredict;
            TestPredict  = Result.TestPredict;

            % get other paramters
            ModelType = Result.ModelType;

            % comparison
            Result.Train = [TrainData.Output, TrainPredict];
            Result.Test  = [TestData.Output, TestPredict];
            Result       = obj.SortOutputClass(Result);
            
            % get optimal path
            [AllSuccessPath, OptimalPath] =...
                            obj.GetOptimalPath(obj, TestData, TestPredict);
            
            % plot optimal path
            figure
            for i =  1: 1: length(AllSuccessPath)
                x = AllSuccessPath{i}(:, 1);
                y = AllSuccessPath{i}(:, 2);
                z = AllSuccessPath{i}(:, 3);
                h.success{i} = scatter3(x, y, z, '.g');
                hold on
            end

            x = OptimalPath(:, 1);
            y = OptimalPath(:, 2);
            z = OptimalPath(:, 3);
            h1 = plot3(x, y, z, '.-k', 'LineWidth', 4);

            % setup parameters
            hold off;
            grid on
            axis equal;
            xlabel("x (mm)");
            ylabel("y (mm)");
            zlabel("z (mm)");           
            legend([h.success{end}, h1],...
                    {'success', 'optimal'}, 'Location', 'northeast');
            titleline = [compose("%s Model of Hand Motion Optimal Path", ModelType);
                         compose("(%d success + 1 optimal)",...
                         length(AllSuccessPath))];
            title(titleline(1), titleline(2));

            % plot graphical results(target vs predicted)
            figure
            plot(Result.Train, 'DisplayName','Result.Train')
            axis padded;
            grid minor;
            CurrentYTicks = transpose(unique(TrainData.Output));
            xlabel("Data sample")
            ylabel("Numerical classification")
            yticks(CurrentYTicks)
            legend('Target', 'Predict')
            title(compose('%s comparison between trainning sample and training net',...
                    ModelType), 'success/failure output vs real numerical result')
        
            figure
            plot(Result.Test, 'DisplayName','Result.Test')
            axis padded;
            grid minor;
            xlabel("Data sample")
            ylabel("Numerical classification")
            yticks(CurrentYTicks)
            legend('Target', 'Predict')
            title(compose('%s comparison between testing sample and training net',...
                    ModelType),'success/failure output vs real numerical result')

        end
        
        %% function: sort output classification of train and test data
        function Result = SortOutputClass(Result)
            % sort train and test target value
            [Result.Train(:, 1), IndexTrain] = sort(Result.Train(:, 1), 'descend');
            [Result.Test(:, 1), IndexTest]   = sort(Result.Test(:, 1), 'descend');

            % re-distribute train and test predict value based sorted index
            Result.Train(:, 2) = Result.Train(IndexTrain, 2);
            Result.Test(:, 2)  = Result.Test(IndexTest, 2);
        end
            
        %% function: Get tran and test day set by k-fold
        function [KTrainSet, KTestSet] = GetTrainTestDataKFoldSet(obj, Data, NumKFoldSet)
           % initialize set of train and test data
           KTrainSet = cell(NumKFoldSet, 1);
           KTestSet = cell(NumKFoldSet, 1);

           % start to generate set data
            for i = 1: 1: NumKFoldSet
                [KTrain, KTest] = obj.GetTrainTestDataKFold(Data);
                KTrainSet{i} = KTrain;
                KTestSet{i} = KTest;
            end
        end

        %% function: Get train and test data by k-fold
        function [Train, Test] = GetTrainTestDataKFold(Data)
            
            % get k-fold, the number of success and failure samples
            NumSuccess = length(Data.success(:, 1));
            NumFailure = length(Data.failure(:, 1));
            k = 10;
            
            % generate two k-fold model
            cvSuccess = cvpartition(NumSuccess, 'kfold', k);
            cvFailure = cvpartition(NumFailure, 'kfold', k);

            % start prepare all data
            % <training data = training success + training failure
            % testing data = testing success + testing failure>
            for i=1:k
                % get success/failure training/test index
                TrainIndex.success{i} = find(training(cvSuccess,i));
                TestIndex.success{i}  = find(test(cvSuccess,i));   
                TrainIndex.failure{i} = find(training(cvFailure,i));
                TestIndex.failure{i}  = find(test(cvFailure,i));

                % prepare training/test data at each fold
                TrainData = [Data.success(TrainIndex.success{i}, :);
                               Data.failure(TrainIndex.failure{i}, :)];
                TestData = [Data.success(TestIndex.success{i}, :);
                               Data.failure(TestIndex.failure{i}, :)];

                % split data into input and output
                Train.Input{i}  = TrainData(:, 1:end-1);
                Train.Output{i} = TrainData(:, end);
                Test.Input{i}   = TestData(:, 1:end-1);
                Test.Output{i}  = TestData(:, end);
            end
        end
        
        %% function: MLTrainTest K-fold
        function Result = MLTrainTestKFold(obj, MLFunc, KTrainData, KTestData)
            % initialize outputs
            n = length(KTrainData.Input);
            TrainAccuracy = zeros(1, n);
            TestAccuracy  = zeros(1, n);
            ElapsedTime   = zeros(1, n);

            % start train and test data
            for i = 1: 1: n
                     
                % train and test data
                TrainData.Input = KTrainData.Input{i}; % get the current fold
                TrainData.Output = KTrainData.Output{i};
                TestData.Input = KTestData.Input{i};
                TestData.Output = KTestData.Output{i};

                [TrainPredict, TestPredict, OtherPara] =...
                                            MLFunc(TrainData, TestData);


                % train and test analysis
                Result = obj.GetTrainTestAccuracy(TrainData, TestData,...
                                                  TrainPredict, TestPredict);

                % accumulate partial results
                TrainAccuracy(i) = Result.TrainAccuracy;
                TestAccuracy(i)  = Result.TestAccuracy;
                ElapsedTime(i) = OtherPara.ElapsedTime;
            end


            % integrate outputs
            Result.MeanTrainAccuracy = mean(Result.TrainAccuracy);
            Result.MeanTestAccuracy = mean(Result.TestAccuracy);
            Result.DataPointNumNow = length(TrainData.Input(1, :)) / 3;
            Result.ElapsedTime = sum(ElapsedTime);
            Result.ModelType = OtherPara.ModelType;
           
            % display result
%             obj.DisplayKFoldResults(Result)

        end
              
        %% function: multivariate linear model(sample is insufficient)
        function MVRAnalysis(obj, Data)
            % re-interpolate and down-sample data
            Data    = obj.InterPosAll(obj, Data, 80);

            % step1: strech (x,y,z) from N x 3 into 1 x 3N
            DataANN = obj.MLPreProcessAll(obj, Data);
            
            % step2: add ouput for all data
            DataANN = obj.MLAddOutputAll(obj, DataANN);
            
            %{ 
              step3: randomly split training and testing data, success
            and failure data 
            %}
            [TrainData, TestData] = obj.GetTrainTestData(DataANN);
            
            % step4: start to execute multivariate regression
            X = TrainData.Input;
            Y = TrainData.Output;

            Xcell = cell(1,length(X(:,1)));
            for i = 1: 1: length(X(:,1))
                Xcell{i} = X(i,:);
            end

            beta = mvregress(Xcell,Y);
            TrainPredict = TrainData.Input * beta;
            TestPredict = TestData.Input * beta;

            % display results
            obj.GetResultAndPlot(obj, "MVR", TrainData, TestData,...
                                    TrainPredict, TestPredict)

        end

        %% function: Get Success Path from Predicted Results
        function [AllSuccessPath, OptimalPath] =...
                            GetOptimalPath(obj, TestData, TestPredict)
            % collect all kinds of output class
            OutputClass = unique(TestData.Output);
            
            % setup range to filter success path
            FilterRange = obj.GetFilterRange(OutputClass);

            % get index of all success path
            SuccessIndex = obj.GetSuccessPathIndex(TestPredict, FilterRange);

            % get all success path
            AllSuccessPath = obj.IntegrateSuccessPath(TestData, SuccessIndex);
            
            % calculate optimal path based on the current success path
            OptimalPath = obj.CalculateOptimalPath(AllSuccessPath);
        end

        %% function: Get filter range to distinguish success path
        function FilterRange = GetFilterRange(OutputClass)
            % binaray classification
            if length(OutputClass) == 2
                FilterRange = [-1.5 -0.5;
                                0.5 1.5];

            % multiple(4) classification    
            elseif length(OutputClass) == 4
               FilterRange = [-1.5 -0.5;
                               0.5  3.5];
            end
     
        end

        %% function: use filger range to get all success path
        function SuccessIndex = GetSuccessPathIndex(TestPredict, FilterRange)
            LowerBound   = FilterRange(2, 1);
            UpperBound   = FilterRange(2, 2);
            SuccessIndex = find(TestPredict > LowerBound &...
                                TestPredict < UpperBound);
        end

        %% function: integrate all success data
        function Results = IntegrateSuccessPath(Data, Index)
            % pick up all success path
            DataSuccess = Data.Input(Index, :);

            % start to integrate all success path
            n = length(DataSuccess(:, 1)); % the number of samples
            m = length(DataSuccess(1, :)); % the number of data points
            Results = cell(1, n);

            for i = 1: 1: n
                % recover 3N x 1 into N x 3
                Results{i} = transpose([DataSuccess(i, 1: m/3);
                                        DataSuccess(i, m/3 + 1: 2*m/3);
                                        DataSuccess(i, 2*m/3 + 1: m)]);
            end

        end

        %% function: calculate optimal path from all success path
        function OptimalPath = CalculateOptimalPath(Data)
            % get the number of data samples
            DataNum = length(Data);

            % get the number of data points
            n = length(Data{1}(:, 1));

            % start to accumulate all value at each point
            x = zeros(n, DataNum);
            y = zeros(n, DataNum);
            z = zeros(n, DataNum);
            for i = 1: 1: DataNum
                x(:, i) = Data{i}(:, 2);
                y(:, i) = Data{i}(:, 3);
                z(:, i) = Data{i}(:, 4);  
            end
            
            % get mean and std of each data point
            OptimalPath.path = [mean(x, 2) mean(y, 2) mean(z, 2)];
            OptimalPath.std = [std(x, 0, 2) std(y, 0, 2) std(z, 0, 2)];
            OptimalPath.std3D = sqrt(std(x, 0, 2).^2 + std(y, 0, 2).^2 +...
                                     std(z, 0, 2).^2);

        end

        %% function: Integrate result accuracy as a table
        function ResultTable = GetResultTable(Result)
            % get accuracy
            ResultTableData(1, 1) = mean(Result.ANNSet.TrainAccuracy);
            ResultTableData(2, 1) = mean(Result.ANNSet.TestAccuracy);
            ResultTableData(1, 2) = mean(Result.ANNKFoldSet.TrainAccuracy);
            ResultTableData(2, 2) = mean(Result.ANNKFoldSet.TestAccuracy);
            ResultTableData(1, 3) = mean(Result.SVMSet.TrainAccuracy);
            ResultTableData(2, 3) = mean(Result.SVMSet.TestAccuracy);
            ResultTableData(1, 4) = mean(Result.SVMKFoldSet.TrainAccuracy);
            ResultTableData(2, 4) = mean(Result.SVMKFoldSet.TestAccuracy);
 
            % get headline
            title = sprintf("%d points", Result.ANNSet.DataPointNum);
            HeadLine.Vertical{1} = [title title title title];
            HeadLine.Vertical{2} = ["ANN" "ANN K-fold" "SVM", "SVM K-fold"];
            HeadLine.Horizontal = [""; ""; "Training Accuracy"; "Validation Accuracy"];
            
            % integrate them as a table
            ResultTable = [HeadLine.Vertical{1}; 
                           HeadLine.Vertical{2};
                           ResultTableData];
            ResultTable = [HeadLine.Horizontal ResultTable];
        end

         

    end

end















