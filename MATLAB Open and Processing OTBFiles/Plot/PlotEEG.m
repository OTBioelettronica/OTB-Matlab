% PlotEEG

% Close all figures and clear all variables
close all
clear all

[file_name, file_path] = uigetfile('*.mat','Select the Signal file to plot');
filename = [file_path file_name];
load (filename)

time = cell2mat(Time);
data = cell2mat(Data);
Data = double(data);
offset=1;
Amp = 0.1;

% HP Signals Filtering 0.1Hz
[B,A]=butter(4,0.1/250,'high');
Data=filtfilt(B,A,Data);
Data=bsxfun(@minus,Data,Data(:,13)); % Differential Signals wrt 13(Fz) electrode
offset=median(std(Data));
Data=bsxfun(@plus,Amp*Data,offset*[1:size(Data,2)]);

% Plot
plot(time,Data);

% PSD Welch
Fs=500;
figure
pwelch(Data,1000,500,[0:200],Fs)

% PSD MTM
[p,f]=pmtm(Data,3,[0:200],Fs);
figure
plot(f,p)

% figure
% plot(Time, bsxfun(@plus,bsxfun(@minus,Data,0*mean(Data,2)),0.05*offset))
% %#ok<NBRAK> %GrandAverage (0xmean for raw signal) and Data(:,[chosen channels]) for few signals)
% hold on



