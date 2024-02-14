% Open the .sig files and create a temporary directory
% then plots the signals acquired with Due probes in time(seconds)

% Close all figures and clear all variables
close all
clear all

% Settings
Probes_num = 2;  % Number of acquired probes

% Ask the user to choose a signal file
[file_name, file_path] = uigetfile('*.otb','Select the Signal file to plot'); %'*.otb+', 'Select signal file to plot among otb+ files'
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
    
    hh=fopen(Sig_Files(ind).name,'r');    % Open the file for read
    
    % Read the file in small blocks to avoid memory problems
    Raw_sig = fread(hh,[Probes_num, inf],'short');
    
    [np, Sig_dur] = size(Raw_sig);      % Extract Matrix dimentions
    
    %put in the signal variable the file red
    signal1=Raw_sig(1:2:end);
    %put in the signal variable the file red
    signal2=Raw_sig(2:2:end);
    
    
    %variables initialization: plot a gui (graphical user interface) in which is possible to set ADC
    %resolution [bit], ADC dynamic [V], Front-end gain [V/V] and Sampling
    %frequency [Hz]
    plotPrompt={'ADC resolution [bit]:','ADC dynamic [V]:','Front-end gain [V/V]:','Sampling frequency [Hz]:'};
    name='Plotting parameters';
    numlines=1;
    %Defaults values to fill the gui
    plotDefaultanswer={'16','3.3','200','2048'};%set default answers inside text fields
    options.Resize='on';%make the just open window resizable

    %when the user press OK button, the values are recorded from the gui
    plotAnswer=inputdlg(plotPrompt,name,numlines,plotDefaultanswer,options);%put in answer the data just inserted from user

    %parameters initialization from the gui
    adcRes=str2double(plotAnswer{1});
    din=str2double(plotAnswer{2});
    gain=str2double(plotAnswer{3});
    fs=str2double(plotAnswer{4});


    %calculate the time interval
    Tint=1/fs;
    %calculate the number of ADC levels
    maxLev=2^adcRes-1;

    %converts the signal from level to Volts RTI (Referred To Input)
    signal1=((signal1/maxLev)*din)/gain;
    signal2=((signal2/maxLev)*din)/gain;

    %eliminate the offset from the signal
    signal1=signal1-mean(signal1);
    signal2=signal2-mean(signal2);
    
     %makes the time variable in order to plot the signal in the time axes
    t=0:Tint:(length(signal1)-1)*Tint;

    %plot the selected signal
    figure,
    subplot(2,1,1);
    % plot(t(30000:end),signal1(30000:end)*1000);
    plot(t,signal1*1000);
    grid on
    xlabel('time (s)','fontweight','b');
    ylabel('Amplitude (mV - RTI)','fontweight','b');
    title('Acquired Signal, channel 1','fontweight','b');
    subplot(2,1,2);
    plot(t,signal2*1000);
    grid on
    xlabel('time (s)','fontweight','b');
    ylabel('Amplitude (mV - RTI)','fontweight','b');
    title('Acquired Signal, channel 2','fontweight','b');

    %close the file handle
    fclose('all');
end 

