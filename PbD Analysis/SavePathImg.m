classdef SavePathImg
    properties
        % xy, xz, yz folders and success/failure folders(3 x 2)
        Action1 = "SingleInSingle";

        % xy, xz, yz in success/failure folders(2 x 1)
        Action2 = "SingleInAll";

        % integrated xy_xz_yz in in success/failure folders(2 x 1)
        Action3 = "AllInAll";

        % switch between binary and multiple classification
        % eg: ["Simple", "Complicated"]
        ClassMethod = "Complicated"

        % main folder name
        MainFolder;
    end

    methods (Static)
        %% Start to Plot and Save all figures
        function PlotAndSave(obj, obj2, Position)
            % initialize waitbar paramters
            n = 0;
            N = length(Position.success) + length(Position.failure);
            f = waitbar(0, "Plot and Save Image...");
            
            % initialize constant parameters
            ClassTypes    = ["success", "failure"];
            FigOption     = obj2.GetAxisRange(Position);
    
            % get label if multiple classifications is needed(optional)
            if obj.DivisionMethod == "Time"
                ResultLabel = obj.GetTimeLabel(obj, Position);
            elseif obj.DivisionMethod == "Grade"
                ResultLabel = obj.GetPathLabel(obj, Position);
            else
                disp("Error: Cannot confirm the classification method!!!")
            end

            % start notification
            disp("------Start to Plot and Save Image------")
            
            % start to plot all figures 
            for i = 1: 1: length(ClassTypes)
                % get the current option
                CurrentClass   = ClassTypes(i);
                CurrentOption1 = obj2.GetOption(obj2.Action1, CurrentClass);
                CurrentOption2 = obj2.GetOption(obj2.Action2, CurrentClass);
                CurrentOption3 = obj2.GetOption(obj2.Action3, CurrentClass);
               
                for j =  1: 1: length(Position.(CurrentClass))
                    % update waitbar
                    n = n + 1;
                    msg = sprintf("Process %s motion path: (%d/%d)",...
                                    CurrentClass, n, N);
                    waitbar(n/N, f, msg);
            
                    % get x, y, z from motion path
                    x = Position.(CurrentClass){j}(:, 2);
                    y = Position.(CurrentClass){j}(:, 3);
                    z = Position.(CurrentClass){j}(:, 4);
                    
                    % get the current label and add it to CurrentOption
                    CurrentOption1.Label = ResultLabel.(CurrentClass)(j);
                    CurrentOption2.Label = ResultLabel.(CurrentClass)(j);
                    CurrentOption3.Label = ResultLabel.(CurrentClass)(j);
                    

                    % plot 2d motion independently
                    Figures = obj2.PlotSingle(x, y, z, FigOption);
        
                    % plot 2d motion together
                    Figure = obj2.PlotAll(x, y, z, FigOption);
             
                    % save figures as jpg file
                    obj2.SaveSIS(obj2, Figures, j, CurrentOption1)
                    obj2.SaveSIA(obj2, Figures, j, CurrentOption2)
                    obj2.SaveAIA(obj2, Figure, j, CurrentOption3)
        
                    % close all figures
                    close all
                end
            end
        
            % close waitbar
            close(f)
            disp('------Finished------')
        end

        %% get current save image options
        function CurrentOption = GetOption(Action, CurrentClassType)
                        
            % select all options
            switch Action
                case "SingleInSingle"
                    MotionTypes     = ["xy", "xz", "yz"];
                    SubFolderTypes  = ["xy", "xz", "yz"];
                case "SingleInAll"
                    MotionTypes     = ["xy", "xz", "yz"];
                    SubFolderTypes  = "xy_xz_yz";
                case "AllInAll"
                    MotionTypes     = "all_in_one";
                    SubFolderTypes  = "all_in_one";
                otherwise
                    disp("Undefined type of action to process figures as images");
            end
        
            % integrate all options
            CurrentOption.CurrentClassType  = CurrentClassType;
            CurrentOption.MotionTypes       = MotionTypes;
            CurrentOption.SubFolderTypes    = SubFolderTypes;
            CurrentOption.Label             = -1; % 1 kind of success if -1
        end
        
        %% confirmed fixed axis range
        function FigOption = GetAxisRange(Position)
            % prepare classification type
            ClassTypes   = ["success", "failure"];
            
            % initialize max and min x,y,z
            MaxX = -inf; MinX = inf;
            MaxY = -inf; MinY = inf;
            MaxZ = -inf; MinZ = inf;
        
            for i = 1: 1: length(ClassTypes)
                % get the current data type (success or failure)
                CurrentType = ClassTypes(i);
        
                % start to find max and min x,y,z
                for j =  1: 1: length(Position.(CurrentType))
        
                    % get x, y, z from motion path
                    x = Position.success{j}(:, 2);
                    y = Position.success{j}(:, 3);
                    z = Position.success{j}(:, 4);
        
                    % update max and min x,y,z
                    MaxX = max(MaxX, max(x)); MinX = min(MinX, min(x));
                    MaxY = max(MaxY, max(y)); MinY = min(MinY, min(y));
                    MaxZ = max(MaxZ, max(z)); MinZ = min(MinZ, min(z));
                end
            end
            
            % integrate all axis range
            FigOption = struct('MaxX', MaxX, 'MinX', MinX,...
                               'MaxY', MaxY, 'MinY', MinY,...
                               'MaxZ', MaxZ, 'MinZ', MinZ);
        end


        %% PlotSingle
        function Figures = PlotSingle(x, y, z, FigOption)
            % plot 2d motion independently
            figure 
            hxy = plot(x, y, '.-r'); 
            axis([FigOption.MinX FigOption.MaxX...
                  FigOption.MinY FigOption.MaxY]); 
        
            figure
            hxz = plot(x, z, '.-r'); 
            axis([FigOption.MinX FigOption.MaxX...
                  FigOption.MinZ FigOption.MaxZ]); 
        
            figure 
            hyz = plot(y, z, '.-r'); 
            axis([FigOption.MinY FigOption.MaxY...
                  FigOption.MinZ FigOption.MaxZ]);
        
            Figures = [hxy, hxz, hyz];
        end
        
        %% PlotAll
        function Figure = PlotAll(x, y, z, FigOption)
            % subplot 2d motion together
            figure
        
            subplot(3, 1, 1)
            plot(x, y, '.-r'); 
                axis([FigOption.MinX FigOption.MaxX...
                  FigOption.MinY FigOption.MaxY]); 
        
        
            subplot(3, 1, 2)
            plot(x, z, '.-r'); 
            axis([FigOption.MinX FigOption.MaxX...
                  FigOption.MinZ FigOption.MaxZ]); 
        
        
            subplot(3, 1, 3)
            plot(y, z, '.-r'); 
            axis([FigOption.MinY FigOption.MaxY...
                  FigOption.MinZ FigOption.MaxZ]);
        
            Figure = gcf;
            % evenly plot a figure(optional)
        %             pbaspect([1 1 1]); 
        end
        
        %% Save SingleInSingle
        function SaveSIS(obj, Figures, DataIndex, Option)
            for i = 1: 1: length(Figures)
                obj.SaveImage(obj, Figures(i), Option.CurrentClassType,...
                                Option.SubFolderTypes(i),...
                                Option.MotionTypes(i), DataIndex,...
                                Option.Label)
            end
        end
        
        %% Save SingleInAll
        function SaveSIA(obj, Figures, DataIndex, Option)
            for i = 1: 1: length(Figures)
                obj.SaveImage(obj, Figures(i), Option.CurrentClassType,...
                                Option.SubFolderTypes,...
                                Option.MotionTypes(i), DataIndex,...
                                Option.Label)
            end
        end
        
        %% Save AllInAll
        function SaveAIA(obj, Figure, DataIndex, Option)
                obj.SaveImage(obj, Figure, Option.CurrentClassType,...
                                Option.SubFolderTypes,...
                                Option.MotionTypes, DataIndex,...
                                Option.Label)
        end
        
        %% save single Image
        function SaveImage(obj, Figure, ClassType, SubFolderType, MotionType,...
                            DataIndex, Label)
            % get the current folder
            % (eg: "DataJPG/success_xy/data_xy_1")
            
            % check if 1 success or more
            ClassTypes2 = ["_poor", "_intermediate", "_good"];
            switch Label
                case {-1, 0}
                    ClassType2 = "";
                case {1, 2, 3}
                    ClassType2 = ClassTypes2(Label);
            end
            ClassType = ClassType + ClassType2;
            
            % integrate save path
            MainFolder  = obj.MainFolder;
            SubFolder   = ClassType + "_" + SubFolderType;
            FileName    = "data" + "_" + MotionType + "_" + num2str(DataIndex) + ".jpg";
            Path        = fullfile(".", MainFolder, SubFolder, FileName);
        
            % make new folder if applicable
            FolderPath = fullfile(".", MainFolder, SubFolder);
            if ~exist(FolderPath, 'dir')
                mkdir(FolderPath)
            end
            
            % save files
            saveas(Figure, Path)
        end

         
    end
end


