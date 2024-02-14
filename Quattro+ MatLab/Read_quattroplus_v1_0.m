% Example script for direct communication with quattroplus
%
% This script builds the communication command starting from the values
% of few variables, open a socket for the connection of due+ and, when the
% due+ is connected, send the command and start receiving data
%
% OT Bioelettronica
% v 1.0

close all
clear all

% settings 
NumCycles = 10;  
OffsetEMG = 2;
PlotTime = 1;

% -------------------------------------------------------------------------
% Refer to the communication protocol for details about these variables:
ProbeEN = 1;    % 1=Probe enabled, 0 = probe disabled
EMG = 1;        % 1=EMG, 0=EEG
Mode = 1;       % 0=2Ch Diff, 1=2Ch Diff, 2=2Ch Diff, 3=2Ch Test
TCPPort = 54320;

% Conversion factor for the bioelectrical signals to get the values in mV
ConvFact = 0.000249;

% Number of acquired channel depending on the acquisition mode
NumChanVsMode = [10 10 10 10];

%checking errors
if ProbeEN > 1
    disp("Error, set ProbeEN values equal to 0 or 1")
    return;
end

if EMG > 1
    disp("Error, set EMGX values equal to 0 or 1")
    return;
end

if Mode > 3
    disp("Error, set ModeX values between 0 and 7")
    return;
end

% Create the command to send to dueplus
Command = 0;
if ProbeEN == 1
    Command = 0 + EMG * 8 + Mode * 2 + 1;
    NumChan = NumChanVsMode(Mode+1);
    sampFreq = 2000;
end

dec2bin(Command)

% Open the TCP socket as server
t = tcpserver(54321,"ByteOrder","big-endian");            %if Matlab version before 2022: t = tcpip('0.0.0.0', 54321, 'NetworkRole', 'server');

% Wait into this function until a client is connected
while(t.Connected < 1)
    pause(0.1)
end

disp('Connected to the Socket')

time = linspace(0, PlotTime, sampFreq*PlotTime);

%EMG subplot
subplot(3,1,1)
EMG = plot(0);
xlim([0 PlotTime])
%ylim([-1000 5000])

%IMU subplot
subplot(3,1,2)
IMU = plot(0);
xlim([0 PlotTime])
ylim([-33000 33000])

%Buffer subplot
subplot(3,3,7)
Buf = plot(0);
xlim([0 PlotTime])
ylim([0 100])
xlabel("Time (s)")
ylabel("Buffer use (%)")

%Trigger subplot
subplot(3,3,8)
Trig = plot(0);
xlim([0 PlotTime])
ylim([0 1.1])
xlabel("Time (s)")
ylabel("Trigger (A.U.)")

%Ramp subplot
subplot(3,3,9)
Ramp = plot(0);
xlim([0 PlotTime])
ylim([-33000 33000])
xlabel("Time (s)")
ylabel("Sample counter (A.U.)")

% Send the command to due+
write(t, Command, 'uint8');

if ProbeEN == 0
    % Wait to be sure the command is received before closing the socket
    pause(0.5);
    clear t;
    return;
end

% Main plot loop
for i = 1 : NumCycles
    
    i
    
    % Read one second of data into signed integer
    Temp = read(t, NumChan*sampFreq*PlotTime, 'int16');
    data = reshape(Temp, NumChan, sampFreq*PlotTime);

    % Plot the EMG signals
    subplot(3,1,1)
    hold off
    for j = 1 : NumChan-6
        plot(time, data(j,:)*ConvFact + OffsetEMG*(j-1))
        hold on
    end
    ylim([-OffsetEMG 5*OffsetEMG])
    xlabel("Time (s)")
    ylabel("EMG (mV)")

    % Plot the IMU
    subplot(3,1,2)
    hold off
    for j = NumChan-5 : NumChan-2
        %set(IMU, 'YData', data(j,:));
        plot(time, data(j,:))
        hold on
    end
    xlabel("Time (s)")
    ylabel("Quaternion (A.U.)")

    %redefenition of Trigger and Buffer and plot
    ind = find(data(NumChan-1,:) < 0);
    Trigger = zeros(sampFreq, 1);
    Trigger(ind) = 1;
    Buffer = data(NumChan-1,:);
    Buffer(ind) = data(NumChan-1,ind) + 32768;

    subplot(3,3,7)
    set(Buf, 'YData', Buffer);
    set(Buf, 'XData', time);

    subplot(3,3,8)
    set(Trig, 'YData', Trigger);
    set(Buf, 'XData', time);

    subplot(3,3,9)
    set(Ramp, 'YData', data(NumChan,:));
    set(Buf, 'XData', time);

    drawnow;
end


% Stop the data transfer
write(t, Command-1, 'uint8');

% Wait to be sure the command is received before closing the socket
pause(0.5);

% Close the TCP socket
clear t;