% Example script to open and plot signals recorded on a SD card
% by Sessantaquattro+. The script read all the necessary information
% from the file header (Sampling frequency, number of channels, gain ...)
%
% v.1.0

% Initialization ----------------------------------------------------------

clearvars
close all
clc

% File open ---------------------------------------------------------------
% Ask the user to select a file
[file_name, file_path]=uigetfile('*.bio','Select the Signal file to plot');
filename = [file_path file_name];
hh=fopen(filename,'r');

% Read and decode the information in the file header ----------------------
FirmVersion = fgetl(hh);
FirmDate = fgetl(hh);
Fsamp = str2num(fgetl(hh));

i = 0;
[Value,IsANumber] = str2num(fgetl(hh));
while(IsANumber)
    i = i + 1;
    ConvFact{i} = Value;
    Offset{i} = str2num(fgetl(hh));
    Resolution{i} = str2num(fgetl(hh));
    NumChan{i} = str2num(fgetl(hh));
    MeasUnit{i} = fgetl(hh);
    RangeMin{i} = str2num(fgetl(hh));
    RangeMax{i} = str2num(fgetl(hh));
    Mode{i} = str2num(fgetl(hh));
    
    [Value,IsANumber] = str2num(fgetl(hh));
end

NumTypeSig = i;
TotNumChan = 0;
for i = 1 : NumTypeSig
    TotNumChan = TotNumChan + NumChan{i};
end

fclose all;

% Read and discard the file header ----------------------------------------
hh=fopen(filename,'r');
sig = fread(hh,512,'char');
clear sig;

% Reads data from the file ------------------------------------------------
if(Resolution{1} == 2)
    sig = fread(hh,[TotNumChan,inf],'int16','b');
else
    %sig = fread(hh,[TotNumChan,inf],'bit24');

    ChInd = (1:3:TotNumChan*3);
    Temp = fread(hh, [TotNumChan * 3, inf], 'uint8');
    sig = Temp(ChInd,:)*65536 + Temp(ChInd+1,:)*256 + Temp(ChInd+2,:);
    ind = find(sig >= 8388608);
    sig(ind) = sig(ind) - (16777216);
end

fclose all;

% Convert data in the correct unit ----------------------------------------
FirstCh = 1;
for j = 1 : NumTypeSig
    sig(FirstCh:FirstCh+NumChan{j}-1,:) = (sig(FirstCh:FirstCh+NumChan{j}-1,:)*ConvFact{j})-Offset{j};
    FirstCh = FirstCh + NumChan{j};
end

% Estimate the acquisition length -----------------------------------------
sig_dur = length(sig(1,:));

% Time vector in seconds --------------------------------------------------
t = linspace(0, sig_dur/Fsamp, sig_dur);

% Signal plot -------------------------------------------------------------
figure
FirstCh = 1;
for j = 1 : NumTypeSig
    subplot(NumTypeSig,1,j)
    for i = FirstCh : FirstCh+NumChan{j}-1
        plot(t, sig(i,:) + i * 0.0001);
        hold on
    end
    xlabel('Time [s]')
    ylabel(['Sig Amplitude [' MeasUnit{j} ']'])
    
    FirstCh = i + 1;
end
