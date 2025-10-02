clc
close all
clear all

% Open a dialog box to select the video file
[fileName, folderPath] = uigetfile('*.mp4', 'Select an MP4 video file');

% Check if the user canceled the selection
if fileName == 0
    disp('File selection canceled.');
    return;
end

% Construct the full path to the selected video
videoFile = fullfile(folderPath, fileName);

% Create a VideoReader object
v = VideoReader(videoFile);

% Read all frames of the video
numFrames = v.NumFrames;
videoFrames = cell(1, numFrames);
for k = 1:numFrames
    videoFrames{k} = readFrame(v);
end

% Get the frame rate of the video
frame_rate = v.FrameRate;

% Close the VideoReader object
delete(v);

% Initialize the figure
hFig = figure;
ax = axes('Position', [0.1 0.3 0.8 0.6]);

% Display the first frame
currentFrame = 1;
imshow(videoFrames{currentFrame}, 'Parent', ax);
title(['Frame ', num2str(currentFrame), '/', num2str(numFrames)]);

% Add a slider to select the frame
slider = uicontrol('Style', 'slider', 'Min', 1, 'Max', numFrames, ...
    'Value', 1, 'SliderStep', [1/(numFrames-1) 10/(numFrames-1)], ...
    'Position', [100 50 300 20], 'Callback', {@updateFrame, ax});

% Add a label above the slider
uicontrol('Style', 'text', 'Position', [230 70 40 20], 'String', 'Frame');

% Add the first text box to enter a number
uicontrol('Style', 'text', 'Position', [450 110 100 30], 'String', 'Toe off frame:');
textBox1 = uicontrol('Style', 'edit', 'Position', [550 110 100 30], 'Max', 2);

% Add the second text box to enter a number
uicontrol('Style', 'text', 'Position', [450 70 100 30], 'String', 'Landing frame:');
textBox2 = uicontrol('Style', 'edit', 'Position', [550 70 100 30], 'Max', 2);

% Add a button to save the values of the text boxes
saveButton = uicontrol('Style', 'pushbutton', 'String', 'Save', ...
    'Position', [550 30 100 30], 'Callback', {@saveValues, frame_rate});

% Add a text box to display the jump height
uicontrol('Style', 'text', 'Position', [670 70 100 30], 'String', 'Jump height (cm):');
jumpHeightBox = uicontrol('Style', 'edit', 'Position', [670 30 100 30], 'Enable', 'inactive');

% Set the window size
set(gcf, 'Position', [100, 100, 800, 600]);

% Save references to the text boxes and video frames in the figure data
handles = struct('textBox1', textBox1, 'textBox2', textBox2, 'jumpHeightBox', jumpHeightBox, 'videoFrames', {videoFrames});
guidata(hFig, handles);

% Function to update the frame display
function updateFrame(source, ~, ax)
    % Retrieve the data from the figure
    handles = guidata(gcf);
    videoFrames = handles.videoFrames;
    
    % Get the current value of the slider
    currentFrame = round(get(source, 'Value'));
    
    % Display the corresponding frame
    imshow(videoFrames{currentFrame}, 'Parent', ax);
    title(['Frame ', num2str(currentFrame), '/', num2str(length(videoFrames))]);
end

% Function to save the values of the text boxes
function saveValues(~, ~, frame_rate)
    % Retrieve the data from the figure
    handles = guidata(gcf);
    
    % Retrieve the values of the text boxes
    fr_to = str2double(get(handles.textBox1, 'String'));
    fr_lan = str2double(get(handles.textBox2, 'String'));
    
    % Calculate the jump height
    jump_height = 9.81 / 8 * ((fr_to - fr_lan) / frame_rate)^2 * 100; % cm
    
    % Display the jump height in the text box
    set(handles.jumpHeightBox, 'String', num2str(jump_height));
end