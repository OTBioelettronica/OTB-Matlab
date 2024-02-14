% Plot_sig_v1.3
%
% Plots EMG signals acquired using Quattrocento
% The following parameters have to be set:
% fsamp:        Sample frequency in Hz
% Acquired_Ch:  Number of acquired channels
% Plotted_Ch:   Number of channels that will be plotted
% Gain:         Gain used during acquisition
% Offset_plot:  Offset used to separate the channels in the plot in mV
%
% July 14th 2020
% Version: 1.3

% Close all figures and clear all variables
close all
clear all
clc

% Settings
fsamp = 2048;          % Sample frequency in Hz
Acquired_Ch = 1 + 8;   % Number of acquired channels (Quattrocento has 8
                       % additional accessory channels in all conditions)
Plotted_Ch = 1;        % Number of channels that will be plotted
Gain = 150;            % Gain used during acquisition (Quattrocento has a fixed gain og 150 V/V)
Offset_plot = 0.5;     % Offset used to separate the channels in the plot in mV

filesize = 6582667312; % If the filesize exceed this limit, the file is read in chunks of 120 s

% Ask the user to choose a signal file
[file_name, file_path] = uigetfile('*.sig','Select the Signal file to plot');
filename = [file_path file_name];

% ---------  SIGNAL INPUT -----------------
hh=fopen(filename,'r');

Raw_sig = fread(hh,[Acquired_Ch, 120*fsamp],'short');  
    
% ---------  SIGNAL CONVERSION ------------
Sig = Raw_sig *5/2^16/Gain*1000;	% Estimates the amplitude on the skin:
% 5 is the A/D input range in V
% 2^16 take into account the resolution of the A/D
% Gain: provide the amplidute on the skin
% 1000: convert the amplitude in mV

% Extract Matrix dimentions
[nch Sig_dur] = size(Sig); 

% Time vector in s
t = linspace(0, Sig_dur/fsamp, Sig_dur);
    
figure
% Plot the desired channels
for i = 1:height(Sig)-1
    plot(t, Sig(i,:) + Offset_plot*i)
    hold on;

    pause;
end
    
xlabel('Time (s)');                     % Definition of abscissa axis 
ylabel('Signals amplitude (mV)');       % Definition of ordinate axis

