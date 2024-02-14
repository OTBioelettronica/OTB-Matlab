%Matlab code used to display offline auxiliary signals acquired with the DueBio system

% Close all figures and clear all variables
close all
clear all


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
    
    val=fread(hh,'uint16',0,'l');       %to use with .sig files compatible with OT Biolab
    
    %close the file handle
    fclose('all');
end 

%variables initialization: plot a gui (graphical user interface) in which is possible to set ADC
%resolution [bit], ADC dynamic [V], Front-end gain [V/V] and Sampling
%frequency [Hz]
plotPrompt={'ADC resolution [bit]:','ADC dynamic [V]:','Front-end gain [V/V]:','Sampling frequency [Hz]:'};
name='Plotting parameters';
numlines=1;
%Defaults values to fill the gui
plotDefaultanswer={'16','3.3','1','2048'};%set default answers inside text fields
options.Resize='on';%make the just open window resizable

%when the user press OK button, the values are recorded from the gui
plotAnswer=inputdlg(plotPrompt,name,numlines,plotDefaultanswer,options);%put in answer the data just inserted from user

%parameters initialization from the gui
adcRes=str2double(plotAnswer{1});
din=str2double(plotAnswer{2});
gain=str2double(plotAnswer{3});
fs=str2double(plotAnswer{4});

ch1=val(1:2:end);
ch2=val(2:2:end);

%calculate the time interval
Tint=1/fs;
%calculate the number of ADC levels
maxLev=2^adcRes;

ch1=(val(1:2:end)/maxLev)*din;
ch2=(val(2:2:end)/maxLev)*din;

%makes the time variable in order to plot the signal in the time axes
t=0:Tint:(min([length(ch1), length(ch2)])-1)*Tint;

res_g = 4;   %resolution (+-2g)
acc = (ch2/maxLev)*res_g - res_g/2;

%plot the selected signal
figure,
ax(1)=subplot(2,1,1);
plot(t,ch1);
grid on
ylabel('Channel 1 - acceleration (g)','fontweight','b');
% title('Seat Position','fontweight','b');
ax(2)=subplot(2,1,2);
plot(t,ch2);
grid on
xlabel('time (s)','fontweight','b');
ylabel('Channel 2 (a.u.)','fontweight','b');
linkaxes(ax,'x');