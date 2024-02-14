clear all
clc
close all

% Load data
[file_name, file_path]=uigetfile('*.otb+','Select the Signal file');
filename = [file_path file_name];
[RawData,samplingFrequency,ChanType,evt]=loadOTB(filename);

% Time construction
Time=1:length(RawData(1,:));
Time=Time/samplingFrequency;

% REMOVE BAD SIGNALS
Data=RawData';
range = std(Data);
% Data(:,range>0.05) = [];   %0.1

% BANDPASS FILTER 
Data = bst_bandpass_hfilter(Data',samplingFrequency,.1,[])';

% NOTCH FILTER
 notch_freq = [50,100,150,200];
 Data = bst_bandstop(Data', samplingFrequency, notch_freq,2.5,'fieldtrip_firws')';

% REMOVE DC 
% Data = bsxfun(@minus,Data,mean(Data));

% AVERAGE REF 
% Data = bsxfun(@minus,Data,mean(Data,2));
% SINGLE ELECTRODE REF
% Data = bsxfun(@minus,Data,Data(:,2));

% STACKED SIGNAL FOR PLOTTING
% offset=median(std(Data));
offset=0;
Data = bsxfun(@plus,Data,offset*[0:size(Data,2)-1]);

% Plot the results
figure
plot(Time,Data(:,[1 3 5 7]))
xlabel('time [s]')
ylabel('Voltage [microV]')
