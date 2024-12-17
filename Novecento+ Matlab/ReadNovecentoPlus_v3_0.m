% Routine for the direct communication with Novecento+
% It opens a TCP socket, set the configuration of Novecento+ and reads back
% data at the desired sampling frequency.
%
% OT Bioelettronica
% November 18th 2024
% v 3.0
%

close all
clear all

NumCycles = 100;       % How many times matlab reads data from Novecento+
PlotTime = 1;         % Plot time in s

WiFi = 0;

offset = 500;

IN_Active = zeros(10,1);
Mode = zeros(10,1);
Gain = zeros(10,1);
HRES = zeros(10,1);
HPF = zeros(10,1);
Fsamp = zeros(10,1);
NumChan = zeros(10,1);
Ptr_IN = zeros(11,1);
Size_IN = zeros(11,1);

ChVsType = [0 14 22 38 46 70 102 0 0 0 0 0 0 0 0 0];

% Input1 ---------------------
IN_Active(1) = 1;
Mode(1) = 0;
Gain(1) = 1;
HRES(1) = 1;
HPF(1)  = 1;
Fsamp(1)= 0;

% Input2 ---------------------
IN_Active(2) = 0;
Mode(2) = 0;
Gain(2) = 1;
HRES(2) = 0;
HPF(2)  = 1;
Fsamp(2)= 0;

% Input3 ---------------------
IN_Active(3) = 0;
Mode(3) = 0;
Gain(3) = 0;
HRES(3) = 0;
HPF(3)  = 1;
Fsamp(3)= 1;

% Input4 ---------------------
IN_Active(4) = 0;
Mode(4) = 0;
Gain(4) = 0;
HRES(4) = 0;
HPF(4)  = 1;
Fsamp(4)= 1;

% Input 5 ---------------------
IN_Active(5) = 0;
Mode(5) = 0;
Gain(5) = 1;
HRES(5) = 0;
HPF(5)  = 1;
Fsamp(5)= 1;

% Input 6 ---------------------
IN_Active(6) = 0;
Mode(6) = 0;
Gain(6) = 0;
HRES(6) = 0;
HPF(6)  = 1;
Fsamp(6)= 0;

% Input 7 ---------------------
IN_Active(7) = 0;
Mode(7) = 0;
Gain(7) = 0;
HRES(7) = 0;
HPF(7)  = 1;
Fsamp(7)= 1;

% Input 8 ---------------------
IN_Active(8) = 0;
Mode(8) = 0;
Gain(8) = 0;
HRES(8) = 0;
HPF(8)  = 1;
Fsamp(8)= 1;

% Input 9 ---------------------
IN_Active(9) = 0;
Mode(9) = 0;
Gain(9) = 0;
HRES(9) = 0;
HPF(9)  = 1;
Fsamp(9)= 1;

% Input 10 --------------------
IN_Active(10) = 0;
Mode(10) = 0;
Gain(10) = 0;
HRES(10) = 0;
HPF(10)  = 1;
Fsamp(10)= 1;

AuxFsamp = [0 16 32 48];    % Codes to set the sampling frequency for AUX Channels
% Sampling frequency values
FsampVal = [500 2000 4000 8000];
SizeAux = [16 64 128 256];
FSelAux = 2;
% FSselAux  = 1 -> 500 Hz
% FSselAux  = 2 -> 2000 Hz
% FSselAux  = 3 -> 4000 Hz
% FSselAux  = 4 -> 8000 Hz
AnOutINSource = 0;        % Source input for analog output:
% 0 = the analog output signal came from IN1
% 1 = the analog output signal came from IN2
% 2 = the analog output signal came from IN3
% 3 = the analog output signal came from IN4
% 4 = the analog output signal came from IN5
% 5 = the analog output signal came from IN6
% 6 = the analog output signal came from IN7
% 7 = the analog output signal came from IN8
% 8 = the analog output signal came from MULTIPLE IN1
% 9 = the analog output signal came from MULTIPLE IN2
% 10 = the analog output signal came from MULTIPLE IN3
% 11 = the analog output signal came from MULTIPLE IN4
% 12 = the analog output signal came from AUX IN
AnOutChan = 1;          % Channel for analog output
AnOutGain = bin2dec('00000000');
% bin2dec('00000000') = Gain on the Analog output equal to 1
% bin2dec('00010000') = Gain on the Analog output equal to 2
% bin2dec('00100000') = Gain on the Analog output equal to 4
% bin2dec('00110000') = Gain on the Analog output equal to 16

TCPPort = 23456;
GainFactor = 0.2861;        % Provide amplitude in mV
AuxGainFactor = 5/2^16/0.5; % Gain factor to convert Aux Channels in V

ConfString(1) = bin2dec('10000000') + AuxFsamp(FSelAux) + IN_Active(10)*2 + IN_Active(9);

ConfString(2) = 0;
for i = 1 : 8
    ConfString(2) = ConfString(2) + IN_Active(i)*(2^(i-1));
end

ConfString(3) = AnOutGain + AnOutINSource;
ConfString(4) = AnOutChan;

for i = 1 : 10
    ConfString(4+i) = Mode(i)*64 + Gain(i)*16 + HPF(i)*8 + HRES(i)*4 + Fsamp(i);
end

ConfString(15) = CRC8(ConfString, 14);

% Open the TCP socket
if(WiFi == 1)
    tcpScoket = tcpclient('192.168.1.1', TCPPort);
else
    tcpScoket = tcpclient('169.254.1.10', TCPPort);
end
tcpScoket.ByteOrder = "little-endian";
tcpScoket.Timeout = 100;

disp('Connected to the Socket')

% -------------------------------------------------------------------------
% Firmware version config request
% -------------------------------------------------------------------------

GetSetCmd(1) = 2;
GetSetCmd(2) =  CRC8(GetSetCmd, 1);

% Request to get the hardwar connections to Novecento+
write(tcpScoket, GetSetCmd, 'uint8');

% Read the type of probes connected to the 10 inputs of Dieci
Settings = read(tcpScoket, 20, 'uint8')';

char(Settings(2:end))

% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Battery level request
% -------------------------------------------------------------------------

GetSetCmd(1) = 3;
GetSetCmd(2) =  CRC8(GetSetCmd, 1);

% Request to get the hardwar connections to Novecento+
write(tcpScoket, GetSetCmd, 'uint8');

% Read the type of probes connected to the 10 inputs of Dieci
Settings = read(tcpScoket, 20, 'uint8')';

sprintf('Battery Level: %d%%', Settings(2))

% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Hardware config request
% -------------------------------------------------------------------------

GetSetCmd(1) = 1;
GetSetCmd(2) =  CRC8(GetSetCmd, 1);

% Request to get the hardwar connections to Novecento+
write(tcpScoket, GetSetCmd, 'uint8');

% Read the type of probes connected to the 10 inputs of Dieci
Settings = read(tcpScoket, 20, 'uint8')';

% The last byte indicates if an error has been detected in the command
% sent
if Settings(20) == 0
    disp('Error None')
else
    if Settings(20) == 255
        disp('Error CRC')
    end
end

% Other bytes reppresent the type of probes connected
disp('Probes configuration:')
Settings(2:11)

pause(0.2)

% -------------------------------------------------------------------------

% Send the configuration to Novecento+
write(tcpScoket, ConfString, 'uint8');

NumActInputs = 0;
Ptr_IN(1) = 1;
for i = 1 : 10
    % Decode the number of channel for each probe
    NumChan(i) = ChVsType(Settings(i+1)+1);
    if NumChan(i) == 0  % If a probe has 0 channels, it means that is not connected
        IN_Active(i) = 0;
    end

    if IN_Active(i) == 1 %Se il corrispondente ingresso è attivo aggiunge il numero di byte ricevuto in un blocco
        Size_IN(i) = (HRES(i)+1)*FsampVal(Fsamp(i)+1)/500*NumChan(i);
        NumActInputs = NumActInputs + 1;
    end

	Ptr_IN(i+1) = Ptr_IN(i) + Size_IN(i);
end

PacketSize1Block = Ptr_IN(11)-1 + SizeAux(FSelAux) + 128;

blockData = PacketSize1Block*500*PlotTime*2;

tcpScoket.InputBufferSize = blockData * 2;

tstart = tic;
a = 0;

figure %('units','normalized','outerposition',[0 0 1 1])

for i = 1 : NumCycles
    i
    
%     % Wait here until one second of data has been received
%     while(tcpScoket.BytesAvailable < blockData)
%     end
    
    tstart = tic;
    
    if(i==2)
        GetSetCmd(1) = 7;
        GetSetCmd(2) = CRC8(GetSetCmd, 1);
        
        % Request to get the hardwar connections to Novecento+
        write(tcpScoket, GetSetCmd, 'uint8');
    end

    if(i==7)
        GetSetCmd(1) = 6;
        GetSetCmd(2) = CRC8(GetSetCmd, 1);
        
        % Request to get the hardwar connections to Novecento+
        write(tcpScoket, GetSetCmd, 'uint8');
    end

    % Read data
    %Temp = read(tcpScoket, PacketSize1Block*2*500*PlotTime, 'uint8')';
    Temp = read(tcpScoket, PacketSize1Block*500*PlotTime, 'int16')';
    Data = reshape(Temp, PacketSize1Block, PlotTime*500);

    for i = 1 : 10
        if IN_Active(i) == 1
            if(HRES(i) == 0)
                Temp1 = reshape(Data(Ptr_IN(i):Ptr_IN(i+1)-1, :), 1, NumChan(i)*FsampVal(Fsamp(i)+1)*PlotTime);
                Sig_IN{i} = GainFactor*(int32(reshape(Temp1, NumChan(i), FsampVal(Fsamp(i)+1)*PlotTime)));
            else
                Temp1 = reshape(Data(Ptr_IN(i):Ptr_IN(i+1)-1, :), 1, NumChan(i)*FsampVal(Fsamp(i)+1)*PlotTime*2);
                Temp2 = typecast(Temp1, 'int32'); % Combine two values on 16-bits into one 32-bit
                Sig_IN{i} = GainFactor*(int32(reshape(Temp2, NumChan(i), FsampVal(Fsamp(i)+1)*PlotTime)));                
                clear Temp2;
            end
            clear Temp1;
        end
    end

    clear Temp;

    Temp = reshape(Data(Ptr_IN(11):end-128, :), 1, 16*FsampVal(FSelAux)*PlotTime);
    Sig_AUX = int32(reshape(Temp, 16, FsampVal(FSelAux)*PlotTime));

    clear Temp;

    Temp = int16(reshape(Data(end-127:end, :), 1, 8*8000*PlotTime));
    Temp1 = typecast(Temp, 'int32');
    Sig_Accessory = reshape(Temp1, 4, 8000*PlotTime);

    clear Temp Temp1;
    PlotID = 1;
    for In = 1 : 10
        if IN_Active(In) == 1
            subplot(NumActInputs+1,1,PlotID)
            hold off;
            for Ch = 1 : (NumChan(In) - 6)
                plot(Sig_IN{In}(Ch,:) + offset*Ch)
                hold on;
            end
            PlotID = PlotID + 1;
            xlim([0 FsampVal(Fsamp(In)+1)*PlotTime])
            %ylim([-offset offset*(NumChan(In) - 5)])
        end
    end

    subplot(NumActInputs+1,2,NumActInputs*2+1)
    hold off;
    for Ch = 1 : 16
        plot(Sig_AUX(Ch,:) + 35000*(15-Ch))
        hold on
    end
    xlim([0 FsampVal(FSelAux)*PlotTime])

    subplot(NumActInputs+1,2,NumActInputs*2+2)
    hold off;
    for Ch = 2
        plot(Sig_Accessory(Ch,:))
        hold on
    end
    xlim([0 8000*PlotTime])

    drawnow
end

% Stop data transfer.
% !!! Important !!!
% During debug always stop data transfer before start a new
% session otherwise the sinchronization with dieci is lost.

ConfString(1) = bin2dec('00000000');    % First byte that stop the data transer
ConfString(15) = CRC8(ConfString, 14);  % Estimates the new CRC
write(tcpScoket, ConfString, 'uint8');

pause (1)

% Close the communication
clear tcpScoket;


