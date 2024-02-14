% Example script for direct communication with Sessantaquattro
% Include the "ACCELEROMETER" mode
%
% This script builds the communication command, open a socket for the
% connection of Sessantaquattro and, when the Sessantaquattro is connected,
% sends the command and starts receiving data
% 
% OT Bioelettronica
% v 4.0

close all
clear all

% Initialization
FSAMP = 2;      % if MODE != 3: 0 = 500 Hz,  1 = 1000 Hz, 2 = 2000 Hz
                % if MODE == 3: 0 = 2000 Hz, 1 = 4000 Hz, 2 = 8000 Hz
NCH  = 3;       % 0 = 8 channels, 1 = 16 channels, 2 = 32 channels, 3 = 64 channels
MODE = 0;       % 0 = Monopolar, 1 = Bipolar, 2 = Differential, 3 = Accelerometers, 6 = Impedance check, 7 = Test Mode
HRES = 0;       % 0 = 16 bits, 1 = 24 bits
HPF  = 1;       % 0 = DC coupled, 1 = High pass filter active
EXTEN = 0;      % 0 = standard input range, 1 = double range, 2 = range x 4, 3 = range x 8
TRIG = 0;       % 0 = Data transfer and REC on SD controlled remotely, 3 = REC on SD controlled from the pushbutton
REC  = 0;       % 0 = Stop data recording on SD card, 1 = start data recording on SD card
GO   = 1;       % 0 = just send the settings, 1 = send settings and start the data transfer

NumCycle = 10;

% Conversion factor for the bioelectrical signals to get the values in mV
ConvFact = 0.000286;

% -------------------------------------------------------------------------
% Create the command to send to Sessantaquattro
Command = 0;
Command = Command + GO;
Command = Command + REC * 2;
Command = Command + TRIG * 4;
Command = Command + EXTEN * 16;
Command = Command + HPF * 64;
Command = Command + HRES * 128;
Command = Command + MODE * 256;
Command = Command + NCH * 2048;
Command = Command + FSAMP * 8192;

% Conversion from decimal integer to its binary representation
dec2bin(Command)

% Set the variables for the script
switch NCH
    case 0
        if(MODE == 1)
            NumChan = 8;
        else
            NumChan = 12;
        end
    case 1
        if(MODE == 1)
            NumChan = 12;
        else
            NumChan = 20;
        end
    case 2
        if(MODE == 1)
            NumChan = 20;
        else
            NumChan = 36;
        end
    case 3
        if(MODE == 1)
            NumChan = 36;
        else
            NumChan = 68;
        end
end

switch FSAMP
    case 0
        if(MODE == 3)
            sampFreq = 2000;
        else
            sampFreq = 500;
        end
    case 1
        if(MODE == 3)
            sampFreq = 4000;
        else
            sampFreq = 1000;
        end
    case 2
        if(MODE == 3)
            sampFreq = 8000;
        else
            sampFreq = 2000;
        end
    case 3
        if(MODE == 3)
            sampFreq = 16000;
        else
            sampFreq = 4000;
        end
    otherwise
        disp('wrong value for FSAMP')
end

% The function tcpip is substituted by the functions
% tcpserver/tcpclient from Matlab version 2022a

if verLessThan('matlab','9.12')
    % Open the TCP socket as server
    t = tcpip('0.0.0.0', 45454, 'NetworkRole', 'server');
    % Increase the input buffer size
    t.InputBufferSize = 500000; %190152;
    % Wait into this function until a client is connected
    fopen(t)
else
    % Open the TCP socket as server
    t = tcpserver(45454,"ByteOrder","big-endian");
    % Increase the input buffer size
    t.InputBufferSize = 500000; %190152;
    % Wait into this function until a client is connected
    fopen(t)
    while(t.Connected < 1)
       pause(0.1)
    end
end

disp('Connected to the Socket')

% Send the command to Sessantaquattro
fwrite(t, Command, 'int16');

if(GO == 0)
    
    % Wait for 10 seconds
    pause(10)
    % Stop the recording on MicroSD cards
    fwrite(t, Command-2, 'int16');

else     
   
    % If the high resolution mode (24 bits) is active
    if(HRES == 1)
        % One second of data: 3 bytes * channels * Sampling frequency
        blockData = 3*NumChan*sampFreq;
        
        ChInd = (1:3:NumChan*3);
    
        % Main plot loop
        for i = 1 : 10
        
            i
        
            % Wait here until one second of data has been received
            while(t.BytesAvailable < blockData)
            end

            % Read one second of data into single bytes
            Temp = fread(t, NumChan*3*sampFreq, 'uint8');
            Temp1 = reshape(Temp, [NumChan*3, sampFreq]);

            % Combine 3 bytes to a 24 bit value
            data{i} = Temp1(ChInd,:)*65536 + Temp1(ChInd+1,:)*256 + Temp1(ChInd+2,:);

            % Search for the negative values and make the two's complement
            ind = find(data{i} >= 8388608);
            data{i}(ind) = data{i}(ind) - (16777216);
        
            % Plot the EEG signals
            subplot(4,1,1:2)
            % Plot the data received
            hold off
            for j = 1 : 4
                plot(data{i}(j,:)*ConvFact + 0.1*(j-1));
                hold on
            end
        
        drawnow;
        end   
    else
        % If the low resolution mode (16 bits) is active
    
        % One second of data: 2 bytes * channels * Sampling frequency
     blockData = 2*NumChan*sampFreq;

        % Main plot loop
        for i = 1 : 10
        
            i
        
            % Wait here until one second of data has been received
            while(t.BytesAvailable < blockData)
            end

            % Read one second of data into signed integer
            Temp = fread(t, NumChan*sampFreq, 'int16');
            data{i} = reshape(Temp, [NumChan, sampFreq]);

            % Plot the EMG signals
            subplot(2,1,1)
            hold off
            for j = 1 : NumChan-4
                plot(data{i}(j,:)*ConvFact + 0.5*(j-1));
                hold on
            end
            
            subplot(2,1,2)
            plot(data{i}(NumChan-1,:));

            drawnow;
        end
    end

    % Stop the data transfer and eventually the recording on MicroSD card
    if (REC == 1)
        fwrite(t, Command-3, 'int16');
    else
        fwrite(t, Command-1, 'int16');
    end
end

% Wait to be sure the command is received before closing the socket
pause(0.5);

% Close the TCP socket
clear t


