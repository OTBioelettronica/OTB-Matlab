% Example script for communication with devices through SyncStation
%
% This script builds the communication command starting from the values
% of few variables, open a socket for the connection with SyncStation and, 
% when the Sync is connected, sends the command and starts receiving data
%
% OT Bioelettronica
% v. 2.0

close all
clear all
clc

TCPPort = 54320;
NumCycles = 10;
OffsetEMG = 1000;
PlotTime = 1;
% ---------- Muovi 1 ------------------------------------------------------
DeviceEN(1) = 0;    % 1=Muovi enabled, 0=Muovi disabled
EMG(1) = 1;         % 1=EMG, 0=EEG
Mode(1) = 0;        % 0=32Ch Monop, 1=16Ch Monop, 2=32Ch ImpCk, 3=32Ch Test
% ---------- Muovi 2 ------------------------------------------------------
DeviceEN(2) = 0;    % 1=Muovi enabled, 0=Muovi disabled
EMG(2) = 1;         % 1=EMG, 0=EEG
Mode(2) = 3;        % 0=32Ch Monop, 1=16Ch Monop, 2=32Ch ImpCk, 3=32Ch Test
% ---------- Muovi 3 ------------------------------------------------------
DeviceEN(3) = 0;    % 1=Muovi enabled, 0=Muovi disabled
EMG3 = 1;           % 1=EMG, 0=EEG
Mode3 = 0;          % 0=32Ch Monop, 1=16Ch Monop, 2=32Ch ImpCk, 3=32Ch Test
% ---------- Muovi 4 ------------------------------------------------------
DeviceEN(4) = 0;    % 1=Muovi enabled, 0=Muovi disabled
EMG(4) = 1;         % 1=EMG, 0=EEG
Mode(4) = 3;        % 0=32Ch Monop, 1=16Ch Monop, 2=32Ch ImpCk, 3=32Ch Test
% ---------- Sessantaquattro 1 /Muovi+ 1 ----------------------------------
DeviceEN(5) = 0;    % 1=Sessantaquattro enabled, 0=Sessantaquattro disabled
EMG(5) = 1;         % 1=EMG, 0=EEG
Mode(5) = 0;        % 0=64Ch Monop, 1=32Ch Monp, 2=64Ch ImpCk, 3=64Ch Test
% ---------- Sessantaquattro 2 /Muovi+ 2-----------------------------------
DeviceEN(6) = 0;    % 1=Sessantaquattro enabled, 0=Sessantaquattro disabled
EMG(6) = 1;         % 1=EMG, 0=EEG
Mode(6) = 3;        % 0=64Ch Monop, 1=32Ch Monop, 2=64Ch ImpCk, 3=64Ch Test
% ---------- Dueplus 1 ----------------------------------------------------
DeviceEN(7) = 0;    % 1=Due+ enabled, 0=Due+ disabled
EMG(7) = 1;         % 1=EMG(just this mode is available)
Mode(7) = 0;      
% ---------- Dueplus 2 ----------------------------------------------------
DeviceEN(8) = 0;    % 1=Due+ enabled,0=Due+ disabled
EMG(8) = 1;         % 1=EMG(just this mode is available)
Mode(8) = 3;    
% ---------- Dueplus 3 ----------------------------------------------------
DeviceEN(9) = 1;    % 1=Due+ enabled, 0=Due+ disabled
EMG(9) = 1;         % 1=EMG(just this mode is available)
Mode(9) = 3;     
% ---------- Dueplus 4 ----------------------------------------------------
DeviceEN(10) = 0;   % 1=Due+ enabled, 0=Due+ disabled
EMG(10) = 1;        % 1=EMG(just this mode is available)
Mode(10) = 3;       
% ---------- Dueplus 5 ----------------------------------------------------
DeviceEN(11) = 0;   % 1=Due+ enabled, 0=Due+ disabled
EMG(11) = 1;        % 1=EMG(just this mode is available)
Mode(11) = 3;       
% ---------- Dueplus 6 ----------------------------------------------------
DeviceEN(12) = 1;   % 1=Due+ enabled, 0=Due+ disabled
EMG(12) = 1;        % 1=EMG(just this mode is available)
Mode(12) = 3;       
% ---------- Dueplus 7 ----------------------------------------------------
DeviceEN(13) = 0;   % 1=Due+ enabled, 0=Due+ disabled
EMG(13) = 1;        % 1=EMG(just this mode is available)
Mode(13) = 3;       
% ---------- Dueplus 8 ----------------------------------------------------
DeviceEN(14) = 0;   % 1=Due+ enabled, 0=Due+ disabled
EMG(14) = 1;        % 1=EMG(just this mode is available)
Mode(14) = 3;       
% ---------- Quattroplus 1 ------------------------------------------------
DeviceEN(15) = 0;   % 1=Quattro+ enabled, 0=Quattro+ disabled
EMG(15) = 1;        % 1=EMG(just this mode is available)
Mode(15) = 3;       
% ---------- Quattroplus 2 ------------------------------------------------
DeviceEN(16) = 0;   % 1=Quattro+ enabled, 0=Quattro+ disabled
EMG(16) = 1;        % 1=EMG(just this mode is available)
Mode(16) = 3;       

% Number of acquired channel depending on the acquisition mode
NumChan = [38 38 38 38 70 70 8 8 8 8 8 8 8 8 10 10];

Error = 0;
for i = 1 : 16
    if(DeviceEN(i) > 1)
        Error = 1;
    end
end

if(Error == 1)
    disp("Error, set DeviceEN values equal to 0 or 1")
    return;
end

Error = 0;
for i = 1 : 16
    if(EMG(i) > 1)
        Error = 1;
    end
end

if(Error == 1)
    disp("Error, set EMG values equal to 0 or 1")
    return;
end
      

Error = 0;
for i = 1 : 16
    if(Mode(i) > 3)
        Error = 1;
    end
end

if(Error == 1)
    disp("Error, set Mode values between to 0 and 3")
    return;
end

SizeComm = 0;
for i = 1 : 16
    SizeComm = SizeComm + DeviceEN(i);
end
     
NumEMGChanMuovi = 0;
NumAUXChanMuovi = 0;
NumEMGChanSessn = 0;
NumAUXChanSessn = 0;
NumEMGChanDuePl = 0;
NumAUXChanDuePl = 0;
NumEMGChanQuattroPl = 0;
NumAUXChanQuattroPl = 0;
muoviEMGChan = double.empty;
muoviAUXChan = double.empty;
sessnEMGChan = double.empty;
sessnAUXChan = double.empty;
duePlEMGChan = double.empty;
duePlAUXChan = double.empty;
quattroPlEMGChan = double.empty;
quattroPlAUXChan = double.empty;

sampFreq = 2000;
TotNumChan = 0;
TotNumByte = 0;
ConfStrLen = 2;
ConfString = zeros(18,1);

ConfString(1) = SizeComm*2 + 1;

for i = 1 : 16
    if DeviceEN(i) == 1
        ConfString(ConfStrLen) = (i-1)*16 + EMG(i)*8 + Mode(i)*2 + 1;
        
        if(i < 5)
            muoviEMGChan = [muoviEMGChan, TotNumChan+1:TotNumChan+32];
            muoviAUXChan = [muoviAUXChan, TotNumChan+33:TotNumChan+38];
            NumEMGChanMuovi = NumEMGChanMuovi + 32;
            NumAUXChanMuovi = NumAUXChanMuovi + 6;
        elseif(i > 6)
            duePlEMGChan = [duePlEMGChan, TotNumChan+1:TotNumChan+2];
            duePlAUXChan = [duePlAUXChan, TotNumChan+3:TotNumChan+8];
            NumEMGChanDuePl = NumEMGChanDuePl + 2;
            NumAUXChanDuePl = NumAUXChanDuePl + 6;
        else
            sessnEMGChan = [sessnEMGChan, TotNumChan+1:TotNumChan+64];
            sessnAUXChan = [sessnAUXChan, TotNumChan+65:TotNumChan+70];
            NumEMGChanSessn = NumEMGChanSessn + 64;
            NumAUXChanSessn = NumAUXChanSessn + 6;
        end
       
        TotNumChan = TotNumChan + NumChan(i);
        
        if(EMG(i) == 1)
            TotNumByte = TotNumByte + NumChan(i) * 2;
        else
            TotNumByte = TotNumByte + NumChan(i) * 3;
        end

        if EMG(i) == 1
            sampFreq = 2000;
        end
        ConfStrLen = ConfStrLen+1;
    end
end

SyncStatChan = TotNumChan+1:TotNumChan+6;
TotNumChan = TotNumChan + 6;
TotNumByte = TotNumByte + 12;

ConfString(ConfStrLen) = CRC8(ConfString, ConfStrLen-1);
                
% Open the TCP socket
if verLessThan('matlab','9.12')
    tcpSocket = tcpip('192.168.76.1', TCPPort, 'NetworkRole', 'client');
    tcpSocket.InputBufferSize = TotNumChan * sampFreq * 3; % 2 s of data with all ch @ 2kHz
    fopen(tcpSocket);
    set(tcpSocket, 'ByteOrder', 'littleEndian');
else
   % Open the TCP socket as client
    tcpSocket = tcpclient('192.168.76.1',TCPPort);
    tcpSocket.InputBufferSize = TotNumChan * sampFreq * 3; % 2 s of data with all ch @ 2kHz
    fopen(tcpSocket);
    set(tcpSocket, 'ByteOrder', 'little-endian');
end

% One second of data: 2 bytes * channels * Sampling frequency
% blockData = 2*TotNumChan*sampFreq*PlotTime;
blockData = TotNumByte*sampFreq*PlotTime;

% Estimate how many plots have to be generated 
NumHorplot = 3;

NoMuoviConnected = 0;
if(NumEMGChanMuovi == 0)
    NumHorplot = NumHorplot-1;
    NoMuoviConnected = 1;
end

NoSessanConnected = 0;
if(NumEMGChanSessn == 0)
    NumHorplot = NumHorplot-1;
    NoSessanConnected = 1;
end

NoDuePlusConnected = 0;
if(NumEMGChanDuePl == 0)
    NumHorplot = NumHorplot-1;
    NoDuePlusConnected = 1;
end

% EMG/EEG plots for muovi -------------------------------------------------
Count = 1;

if(NoMuoviConnected == 0)
    MuoviEMG = subplot(2,NumHorplot,Count);
    xlim([0 sampFreq*PlotTime])
    ylim([-OffsetEMG (OffsetEMG*NumEMGChanMuovi)])
    
    Count = Count + 1;
end

% EMG/EEG Plots for sessantaquattro ---------------------------------------
if(NoSessanConnected == 0)
    SessnEMG = subplot(2,NumHorplot,Count);
    xlim([0 sampFreq*PlotTime])
    ylim([-OffsetEMG (OffsetEMG*NumEMGChanSessn)])
    
    Count = Count + 1;
end

% EMG Plots for dueBio ----------------------------------------------------
if(NoDuePlusConnected == 0)
    DuePlEMG = subplot(2,NumHorplot,Count);
    xlim([0 sampFreq*PlotTime])
    ylim([-OffsetEMG (OffsetEMG*NumEMGChanDuePl)])
    
    Count = Count + 1;
end

Count = (Count*2)-1;

% AUX Plots for muovi -----------------------------------------------------
if(NoMuoviConnected == 0)
    MuoviAUX = subplot(4,NumHorplot,Count);
    xlim([0 sampFreq*PlotTime])
    ylim([-33000 33000])
    
    Count = Count + 1;
end    

% AUX Plots for sessantaquattro -------------------------------------------
if(NoSessanConnected == 0)
    SessnAUX = subplot(4,NumHorplot,Count);
    xlim([0 sampFreq*PlotTime])
    ylim([-33000 33000])
end

% AUX Plots for duePlus ---------------------------------------------------
if(NoDuePlusConnected == 0)
    DuePlAUX = subplot(4,NumHorplot,Count);
    xlim([0 sampFreq*PlotTime])
    ylim([-33000 33000])
end

% Plots for SyncStation ---------------------------------------------------

SyncSta = subplot(4,1,4);
xlim([0 sampFreq*PlotTime])
ylim([-33000 33000])

% Send the configuration to muovi station
fwrite(tcpSocket, ConfString(1:ConfStrLen), 'uint8');

for i = 1 : NumCycles
    i

    ChanReady = 1;
    
    % Wait here until one second of data has been received
    while(tcpSocket.BytesAvailable < blockData)
    end
    
    Temp = fread(tcpSocket, [TotNumByte, sampFreq*PlotTime], 'uint8');
    
    for DevId = 1 : 16
        if DeviceEN(DevId) == 1
            if(EMG(DevId) == 1)
                ChInd = (1:2:NumChan(DevId)*2);
                DataSubMatrix = Temp(ChInd,:)*256 + Temp(ChInd+1,:);

                % Search for the negative values and make the two's complement
                ind = find(DataSubMatrix >= 32768);
                DataSubMatrix(ind) = DataSubMatrix(ind) - 65536;
                
                data(ChanReady:ChanReady+NumChan(DevId)-1,:) = DataSubMatrix;
                Temp(1:NumChan(DevId)*2,:) = [];
            else
                ChInd = (1:3:NumChan(DevId)*3);
                DataSubMatrix = Temp(ChInd,:)*65536 + Temp(ChInd+1,:)*256 + Temp(ChInd+2,:);
                
                                
                % Search for the negative values and make the two's complement
                ind = find(DataSubMatrix >= 8388608);
                DataSubMatrix(ind) = DataSubMatrix(ind) - (16777216);
                
                data(ChanReady:ChanReady+NumChan(DevId)-1,:) = DataSubMatrix;
                Temp(1:NumChan(DevId)*3,:) = [];
            end
            
            clear ChInd;
            clear ind;
            clear DataSubMatrix;
            ChanReady = ChanReady + NumChan(DevId);
        end
    end

    ChInd = (1:2:12);
    DataSubMatrix = Temp(ChInd,:)*256 + Temp(ChInd+1,:);

    % Search for the negative values and make the two's complement
    ind = find(DataSubMatrix >= 32768);
    DataSubMatrix(ind) = DataSubMatrix(ind) - 65536;

    data(ChanReady:ChanReady+5,:) = DataSubMatrix;
    clear ind;
    clear DataSubMatrix;

    k = 0;
    
    if exist('MuoviEMG','var')
        k = 0;
        subplot(MuoviEMG)
        hold off
        for j = muoviEMGChan
            plot(data(j,:) + OffsetEMG*k)
            hold on
            k = k + 1;
        end
    end
    
    if exist('SessnEMG','var')
        k = 0;
        subplot(SessnEMG)
        hold off
        for j = sessnEMGChan
            plot(data(j,:) + OffsetEMG*k)
            hold on
            k = k + 1;
        end
    end
    
    if exist('DuePlEMG','var')
        k = 0;
        subplot(DuePlEMG)
        hold off
        for j = duePlEMGChan
            plot(data(j,:) + OffsetEMG*k)
            hold on
            k = k + 1;
        end
    end
    
    if exist('MuoviAUX','var')
        subplot(MuoviAUX)
        hold off
        for j = muoviAUXChan
            plot(data(j,:))
            hold on
        end
    end
    
    if exist('SessnAUX','var')
        subplot(SessnAUX)
        hold off
        for j = sessnAUXChan
            plot(data(j,:))
            hold on
        end
    end
    
    if exist('DuePlAUX','var')
        subplot(DuePlAUX)
        hold off
        for j = duePlAUXChan
            plot(data(j,:))
            hold on
        end
    end

    subplot(SyncSta)
    hold off
    for j = SyncStatChan
        plot(data(j,:))
        hold on
        k = k + 1;
    end
    
    drawnow
end

clear ConfString;
ConfString(1) = 0;
ConfString(2) = CRC8(ConfString, 1);

% Send the configuration to muovi station
fwrite(tcpSocket, ConfString, 'uint8');

clear 'tcpSocket';
