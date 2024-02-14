% PlotOTB

% Open the .sig files and create a temporary directory
% then plots the desired channels in time(seconds)

% Close all figures and clear all variables
close all
clear all


% Settings
fsamp = 2048;          % Sample frequency in Hz
Acquired_Ch = 201;     % Number of acquired channels
Plotted_Ch = 64;       % Number of channell that will be plotted
Gain = 150;            % Gain used during acquisition
Offset_plot = 0;       % Offset uset to separate the channels in the plot in mV

% Ask the user to choose a signal file
[file_name, file_path] = uigetfile('*.otb', '*.otb+'); 
OTBfilename = [file_path file_name];


% Creates a temporary directory
mkdir('Temp');
cd Temp;

% Extract the .sig files in the temporary directory
unzip(OTBfilename);

% Search for *.sig files
Sig_Files = dir('*.sig');
Num_files = length(Sig_Files);

% For each *.sig file reads it
for ind = 1:Num_files

    % Open the file for read
    hh=fopen(Sig_Files(ind).name,'r');    
    
    % Read the file in small blocks to avoid memory problems
    Raw_sig = fread(hh,[Acquired_Ch, inf],'short');
    
    % Extract Matrix dimentions
    [nch Sig_dur] = size(Raw_sig);      
    
    % ---------  SIGNAL CONVERSION ------------
    Sig = Raw_sig*5/2^16/Gain*1000;	% Estimates the amplitude on the skin:
    % 5 is the A/D input range in V
    % 2^12 take into account the resolution of the A/D
    % Gain: provide the amplidute on the skin
    % 1000: convert the amplitude in mV
    
    t = linspace(0, Sig_dur/fsamp, Sig_dur); % Time vector in s
    
    % Plot the desired channels
    for i = 1 : Plotted_Ch          
        plot(t, Sig(i,:) + Offset_plot*(i-1))
        hold on; 
    end
    
    xlabel('Time (s)');                      % Definition of abscissa axis 
    ylabel('Signals amplitude (mV)');        % Definition of ordinate axis
    
    %pause   
end

% Close all files
fclose all;

% Remove the Temp Directory
cd ..
rmdir('Temp', 's')


