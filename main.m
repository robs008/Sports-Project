clc;  % Clear the command window
close all;  % Close all figure windows
clear all;  % Clear all variables from the workspace

%% Loading data

addpath('DATA\')  % Add the DATA directory to the path
addpath("FUNCTIONS\")  % Add the FUNCTIONS directory to the path

main_folder = 'DATA';  % Define the main data folder
subfolders = dir(main_folder);  % List all items in the main data folder
subfolders = subfolders([subfolders.isdir] & ~startsWith({subfolders.name}, '.'));  % Filter out non-directories and hidden files
data = struct();  % Initialize an empty structure to hold the data

% Loop through each subfolder (representing each person)
for i = 1:length(subfolders)
    
    subfolder_name = subfolders(i).name;  % Get the name of the subfolder
    subfolder_path = fullfile(main_folder, subfolder_name);  % Get the full path of the subfolder
    
    day_folders = dir(subfolder_path);  % List all items in the subfolder
    day_folders = day_folders([day_folders.isdir] & ~startsWith({day_folders.name}, '.'));  % Filter out non-directories and hidden files
    
    person_data = struct();  % Initialize an empty structure for each person's data
    h_acc.(subfolder_name) = [];  % Initialize an empty array for acceleration data for each person
    
    % Loop through each day folder within the person's subfolder
    for j = 1:length(day_folders)
        day_folder_name = day_folders(j).name;  % Get the name of the day folder
        day_folder_path = fullfile(subfolder_path, day_folder_name);  % Get the full path of the day folder
        
        mat_files = dir(fullfile(day_folder_path, '*.mat'));  % List all .mat files in the day folder
        
        % Loop through each .mat file in the day folder
        for k = 1:length(mat_files)
            mat_file_name = mat_files(k).name;  % Get the name of the .mat file
            mat_file_path = fullfile(day_folder_path, mat_file_name);  % Get the full path of the .mat file
            load(mat_file_path);  % Load the .mat file
            
            % Store acceleration data in the structure
            data.(subfolder_name).acc.(day_folder_name).axyz = table2array(Acceleration(:, 1:3));
            
            % Store position data in the structure
            pos = table2array(Position);
            data.(subfolder_name).pos.(day_folder_name).lat = double(pos(:, 1));
            data.(subfolder_name).pos.(day_folder_name).long = double(pos(:, 2));
            
            % Store the last column of the position data into h_acc structure
            h_acc.(subfolder_name) = [h_acc.(subfolder_name); double(pos(:, end))];
        end
    end
end

filter_flag = true;  % Flag for filtering

% Define body masses for each person
data.roby.body_mass = 61; % (kg)
data.chiara.body_mass = 55; % (kg)
data.salvo.body_mass = 55; % (kg)
T = 30; % (s) period over which acceleration is to be integrated

person_name = fieldnames(data);  % Get the names of all persons in the data

sf = 50;  % Hz sampling frequency

%data.salvo.acc.day_1.axyz=resample(data.salvo.acc.day_1.axyz,sf,200);

% Loop through each person in the data
for pers_name = 1:numel(person_name)
    day_name=fieldnames(data.(person_name{pers_name}).acc);
    % Loop through each day for the person
    for day = 1:numel(day_name)

        % Loop through each sample in the acceleration data for the day
        for i = 1:size(data.(person_name{pers_name}).acc.(day_name{day}).axyz, 1)    
            if mod(i, T * sf) == 0
                % Compute Integrated Absolute Acceleration (IAA) over the period T
                data.(person_name{pers_name}).acc.(day_name{day}).IAA(round(i / (T * sf))) = ...
                    fromBufferedAccToIaaTot(data.(person_name{pers_name}).acc.(day_name{day}).axyz(i - T * sf + 1:i, :), ...
                    filter_flag, sf);
                
                % Compute Energy Expenditure (EE) based on IAA
                if i == T * sf
                    data.(person_name{pers_name}).acc.(day_name{day}).EE(round(i / (T * sf))) = ...
                    fromIaaTotToEnergyExpenditure(data.(person_name{pers_name}).acc.(day_name{day}).IAA(round(i / (T * sf))), ...
                    data.(person_name{pers_name}).body_mass, 0);
                else
                    data.(person_name{pers_name}).acc.(day_name{day}).EE(round(i / (T * sf))) = ...
                    fromIaaTotToEnergyExpenditure(data.(person_name{pers_name}).acc.(day_name{day}).IAA(round(i / (T * sf))), ...
                    data.(person_name{pers_name}).body_mass);
                end
            end
        end
        
        % Store the total energy expenditure for the day
        data.(person_name{pers_name}).acc.(day_name{day}).EE_tot = data.(person_name{pers_name}).acc.(day_name{day}).EE(end);

        % Compute distances from latitude and longitude data
        data.(person_name{pers_name}).pos.(day_name{day}).dist = ...
            computeDistances(data.(person_name{pers_name}).pos.(day_name{day}).lat, ...
            data.(person_name{pers_name}).pos.(day_name{day}).long);
        
        % Sum the distances to get the total distance for the day
        data.(person_name{pers_name}).pos.(day_name{day}).tot_dist = ...
            sum(data.(person_name{pers_name}).pos.(day_name{day}).dist);
        
        % Compute the mean velocity (km/h)
        data.(person_name{pers_name}).pos.(day_name{day}).mean_velocity = ...
            data.(person_name{pers_name}).pos.(day_name{day}).tot_dist / (20 / 60);  % Assume total time is 20 minutes
    end
end

% Creating the figure
for i = 1:10
    day_name{i} = ['day_', num2str(i)];
end
total_distance=zeros(3,10);
EE_TOT=zeros(3,10);
for pers_name=1:3
    for day=1:10
        if isfield(data.(person_name{pers_name}).pos,day_name{day})
            total_distance(pers_name,day)=data.(person_name{pers_name}).pos.(day_name{day}).tot_dist;
            EE_TOT(pers_name,day)=data.(person_name{pers_name}).acc.(day_name{day}).EE_tot;
        end
    end
end

% Total distance
figure()
subplot(2,1,1)
for pers_name=1:3
    plot(total_distance(pers_name,:)/total_distance(pers_name,1),'--o');
    hold on;
end
set(gca, 'XTickLabel', []);
ylabel('Normolazide distance');
legend("Active subject","Sedentary subject 1","Sedentary subject 2");
subplot(2,1,2)
for pers_name=1:3
    plot(total_distance(pers_name,:),'--o');
    hold on;
end
xlabel('Day');
ylabel('Distance (km)');
subjects = {'Active subject','Sedentary subject 1', 'Sedentary subject 2'};

% EE_tot
figure
for pers_name = 1:3
    % First column: original plot
    subplot(3, 3, [3*(pers_name)-2,3*pers_name-1])
    yyaxis right;
    plot(EE_TOT(pers_name,:), 'r--o');
    ylabel('Energy burned (kcal)');
    hold on;
    yyaxis left;
    plot(total_distance(pers_name,:), 'b--x');
    ylabel('Distance (km)');
    hold off;
    xlabel('Day');
    title(subjects{pers_name})
    
    % Second column: regression line
    subplot(3, 3, 3*pers_name)
    x = total_distance(pers_name,:);
    y = EE_TOT(pers_name,:);
    % Calculation of regression line
    p = polyfit(x, y, 1);
    yfit = polyval(p, x);
    % Calculation of R-squared
    rsq = 1 - sum((yfit-y).^2)/sum((y-mean(y)).^2);
    % Plotting data and regression line
    plot(x, y, 'bo');
    hold on;
    plot(x, yfit, 'r-');
    hold off;
    xlabel('Distance (km)');
    ylabel('Energy burned (kcal)');
    title(['R^2 = ', num2str(rsq)])
end

% Plotting jump height
load('jump_data.mat')
j_h_pre = mean(j_h.pre);
j_h_post = mean(j_h.post);
j_h_plot = [j_h_pre', j_h_post'];
% Creating histogram
figure; hold on;
bar(j_h_plot)
% Customizing x-axis
xticks(1:3); 
xticklabels(subjects); 
ylabel('Jump height (cm)')
legend('Pre aerobic training program', 'Post aerobic training program');
hold off;

