% Close all figures and clear all variables
close all
clear all
clc

% Choose the file
[file_name, file_path] = uigetfile('*.mat','Select the Signal file to plot');
filename = [file_path file_name];
load (filename)

data = cell2mat(Data);
time = cell2mat(Time);

% Data Plot
for i = 1: length(data(1,:))
    plot(time, data(:,i))
    hold on
end 
