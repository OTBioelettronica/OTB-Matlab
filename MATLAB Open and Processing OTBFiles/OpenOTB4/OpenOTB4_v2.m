%% OTB4 FILE READER
%
% Reads:
% - Tracks_000.xml, Tracks_001.xml, etc.
% - TrapezoidalTracks_000.xml, etc.
% - SIG and SIP files
% - int16, int24, int32 and float64 streams
% - EMG, EEG, AUX, Load Cell, processed and trapezoidal tracks
%
% Main output variables:
% - TrackData{k}: data of the k-th track
% - TrackInfo{k}: metadata of the k-th track
% - ForceVoltage: Load Cell signal in volts, when present
% - TrapezoidalPerformed: performed path in %MVC, when present
% - TrapezoidalOriginal: original target path in %MVC, when present
%
% Requirement:
% - xml2struct.m must be available in the current folder or MATLAB path.
% - Only .otb4 not .otb+ since they have a different structure

clear
close all
fclose('all')
clc

%% Select OTB4 file

FILTERSPEC = {'*.otb4','OTB4 files'; '*.zip','ZIP files'};

[FILENAME,PATHNAME] = uigetfile(FILTERSPEC,'Select an OTB4 file');

if isequal(FILENAME,0)
    disp('File selection cancelled.')
    return
end

OTB4File = fullfile(PATHNAME,FILENAME);

%% Check xml2struct availability

if isempty(which('xml2struct'))
    error('The function xml2struct was not found. Add xml2struct.m to the current folder or MATLAB path.');
end

%% Create temporary extraction folder

TempFolder = tempname;
mkdir(TempFolder);

CleanupObject = onCleanup(@() removeTempFolder(TempFolder));

%% Extract OTB4 archive

try
    untar(OTB4File,TempFolder);
catch ME
    error('Unable to extract the OTB4 file:\n%s',ME.message);
end

%% Find all metadata XML files

MainTrackFiles = dir(fullfile(TempFolder,'Tracks_*.xml'));
TrapezoidalTrackFiles = dir(fullfile(TempFolder,'TrapezoidalTracks_*.xml'));

AllMetadataFiles = [MainTrackFiles; TrapezoidalTrackFiles];

if isempty(AllMetadataFiles)
    error('No Tracks_*.xml or TrapezoidalTracks_*.xml metadata files were found in the OTB4 archive.');
end

%% Read all metadata files

AllTracks = {};
TrackSourceXML = {};

for fileIndex = 1:numel(AllMetadataFiles)

    XMLName = AllMetadataFiles(fileIndex).name;
    XMLPath = fullfile(TempFolder,XMLName);

    fprintf('Reading metadata: %s\n',XMLName);

    Metadata = xml2struct(XMLPath);

    if ~isfield(Metadata,'ArrayOfTrackInfo') || ~isfield(Metadata.ArrayOfTrackInfo,'TrackInfo')
        fprintf('No valid TrackInfo elements found in %s.\n',XMLName);
        continue
    end

    CurrentTracks = Metadata.ArrayOfTrackInfo.TrackInfo;

    if ~iscell(CurrentTracks)
        CurrentTracks = {CurrentTracks};
    end

    for k = 1:numel(CurrentTracks)
        AllTracks{end+1} = CurrentTracks{k}; %#ok<SAGROW>
        TrackSourceXML{end+1} = XMLName; %#ok<SAGROW>
    end
end

Tracks = AllTracks;
NumberOfTracks = numel(Tracks);

if NumberOfTracks == 0
    error('No valid tracks were found in the OTB4 file.');
end

%% Find the signal stream associated with each track

StreamPaths = cell(1,NumberOfTracks);

for k = 1:NumberOfTracks
    StreamPaths{k} = getXMLText(Tracks{k},'SignalStreamPath','');
end

ValidPaths = ~cellfun(@isempty,StreamPaths);
UniqueStreams = unique(StreamPaths(ValidPaths),'stable');

if isempty(UniqueStreams)
    error('No signal stream paths were found in the metadata.');
end

%% Initialize output variables

TrackData = cell(1,NumberOfTracks);
TrackInfo = cell(1,NumberOfTracks);

%% Read every signal stream

for streamIndex = 1:numel(UniqueStreams)

    StreamName = UniqueStreams{streamIndex};

    fprintf('\nReading stream: %s\n',StreamName);

    TrackIndexes = find(strcmp(StreamPaths,StreamName));
    FirstTrack = Tracks{TrackIndexes(1)};

    TotalChannels = getXMLNumber(FirstTrack,'TotalChannelsInFile',NaN);
    SampleSize = getXMLNumber(FirstTrack,'SampleSize',NaN);

    if isnan(TotalChannels) || TotalChannels <= 0
        error('Invalid TotalChannelsInFile for stream %s.',StreamName);
    end

    if isnan(SampleSize)
        error('SampleSize is missing for stream %s.',StreamName);
    end

    SignalFile = fullfile(TempFolder,StreamName);

    if ~isfile(SignalFile)
        error('Signal file not found: %s',StreamName);
    end

    %% Read complete interlaced stream

    StreamData = readSignalFile(SignalFile,TotalChannels,SampleSize);

    fprintf('Total channels: %d\n',TotalChannels);
    fprintf('Samples: %d\n',size(StreamData,2));
    fprintf('Sample size: %d bytes\n',SampleSize);

    %% Extract individual tracks

    for k = TrackIndexes

        CurrentTrack = Tracks{k};

        Title = getXMLText(CurrentTrack,'Title',sprintf('Track %d',k));
        SubTitle = getXMLText(CurrentTrack,'SubTitle','');
        Device = getXMLText(CurrentTrack,'Device','');
        Unit = getXMLText(CurrentTrack,'UnitOfMeasurement','A.U.');

        FirstChannelZeroBased = getXMLNumber(CurrentTrack,'AcquisitionChannel',0);
        NumberOfChannels = getXMLNumber(CurrentTrack,'NumberOfChannels',1);
        SamplingFrequency = getXMLNumber(CurrentTrack,'SamplingFrequency',NaN);
        ADCBits = getXMLNumber(CurrentTrack,'ADC_Nbits',0);
        ADCRange = getXMLNumber(CurrentTrack,'ADC_Range',1);
        Gain = getXMLNumber(CurrentTrack,'Gain',1);
        UnitFactor = getXMLNumber(CurrentTrack,'UnitOfMeasurementFactor',1);

        IsControl = getXMLLogical(CurrentTrack,'IsControl',false);
        IsProcessing = getXMLLogical(CurrentTrack,'IsProcessing',false);

        %% Extract correct channel range

        FirstChannelMATLAB = FirstChannelZeroBased + 1;
        LastChannelMATLAB = FirstChannelMATLAB + NumberOfChannels - 1;

        if FirstChannelMATLAB < 1 || LastChannelMATLAB > TotalChannels
            error('Invalid channel range for track "%s". Requested channels %d-%d, but stream "%s" contains %d channels.',Title,FirstChannelMATLAB,LastChannelMATLAB,StreamName,TotalChannels);
        end

        RawData = StreamData(FirstChannelMATLAB:LastChannelMATLAB,:);

        %% Convert raw data into physical values

        if SampleSize == 8

            ConvertedData = RawData;

        elseif ADCBits > 0

            if Gain == 0
                fprintf('Gain is zero for track "%s". Raw values will be returned.\n',Title);
                ConvertedData = RawData;
            else
                ScaleFactor = (ADCRange / (2^ADCBits)) / Gain * UnitFactor;
                ConvertedData = RawData .* ScaleFactor;
            end

        else

            ConvertedData = RawData .* UnitFactor;

        end

        %% Save track data and metadata

        TrackData{k} = ConvertedData;

        TrackInfo{k} = struct('TrackNumber',k,'SourceXML',TrackSourceXML{k},'Title',Title,'SubTitle',SubTitle,'Device',Device,'SignalStreamPath',StreamName,'AcquisitionChannel',FirstChannelZeroBased,'NumberOfChannels',NumberOfChannels,'TotalChannelsInFile',TotalChannels,'SamplingFrequency',SamplingFrequency,'SampleSize',SampleSize,'ADCBits',ADCBits,'ADCRange',ADCRange,'Gain',Gain,'UnitFactor',UnitFactor,'Unit',Unit,'IsControl',IsControl,'IsProcessing',IsProcessing);

        fprintf('Track %d: %s',k,Title);

        if ~isempty(SubTitle)
            fprintf(' - %s',SubTitle);
        end

        fprintf(' | %d channel(s) | %g Hz | %s\n',NumberOfChannels,SamplingFrequency,Unit);

        %% Classify track for plotting

        SearchText = lower([Title,' ',SubTitle]);

        IsTrapezoidalTrack = startsWith(TrackSourceXML{k},'TrapezoidalTracks_','IgnoreCase',true);
        IsLoadCellTrack = contains(SearchText,'load cell') || contains(SearchText,'force');
        IsBufferTrack = contains(SearchText,'buffer');
        IsRampControlTrack = contains(SearchText,'ramp') && ~IsTrapezoidalTrack;
        IsControlSignalTrack = IsControl || contains(SearchText,'control signal');
        IsOptionalPlot = IsBufferTrack || IsRampControlTrack || IsControlSignalTrack;

        %% Plot tracks

        if IsTrapezoidalTrack

            % Trapezoidal tracks are plotted together later.

        elseif IsLoadCellTrack

            % Load Cell tracks are plotted later.

        elseif IsOptionalPlot

            % 
            % COMMENT/UNCOMMENT the following line to hide/display Control Signal, Ramp and Buffer data plot:
            %
             plotSingleTrack(TrackInfo{k},TrackData{k});

        else

            % EMG, AUX, quaternion, processed and other standard tracks.
            plotSingleTrack(TrackInfo{k},TrackData{k});

        end
    end
end

%% Display complete track summary

fprintf('\n');
fprintf('--------------------------------------------------\n');
fprintf('TRACK SUMMARY\n');
fprintf('--------------------------------------------------\n');

for k = 1:NumberOfTracks

    if isempty(TrackInfo{k})
        continue
    end

    fprintf('TrackData{%d}: %s',k,TrackInfo{k}.Title);

    if ~isempty(TrackInfo{k}.SubTitle)
        fprintf(' - %s',TrackInfo{k}.SubTitle);
    end

    fprintf(' | %d channel(s) | %g Hz | %s | %s\n',TrackInfo{k}.NumberOfChannels,TrackInfo{k}.SamplingFrequency,TrackInfo{k}.Unit,TrackInfo{k}.SourceXML);
end

%% Find Load Cell tracks

ForceTrackIndexes = [];

for k = 1:NumberOfTracks

    if isempty(TrackInfo{k})
        continue
    end

    SearchText = lower([TrackInfo{k}.Title,' ',TrackInfo{k}.SubTitle]);

    if contains(SearchText,'load cell') || contains(SearchText,'force')
        ForceTrackIndexes(end+1) = k; %#ok<SAGROW>
    end
end

%% Find trapezoidal tracks

TrapezoidalTrackIndexes = [];

for k = 1:NumberOfTracks

    if isempty(TrackInfo{k})
        continue
    end

    if startsWith(TrackInfo{k}.SourceXML,'TrapezoidalTracks_','IgnoreCase',true)
        TrapezoidalTrackIndexes(end+1) = k; %#ok<SAGROW>
    end
end

%% Identify Performed Path and Original Path

PerformedTrackIndex = [];
OriginalTrackIndex = [];

for k = TrapezoidalTrackIndexes

    SearchText = lower([TrackInfo{k}.Title,' ',TrackInfo{k}.SubTitle]);

    if contains(SearchText,'performed')
        PerformedTrackIndex = k;
    end

    if contains(SearchText,'original')
        OriginalTrackIndex = k;
    end
end

%% Initialize force and trapezoidal variables

ForceVoltage = [];
TimeForce = [];
FsForce = [];

TrapezoidalPerformed = [];
TimeTrapezoidalPerformed = [];
FsTrapezoidalPerformed = [];

TrapezoidalOriginal = [];
TimeTrapezoidalOriginal = [];
FsTrapezoidalOriginal = [];

%% Extract first Load Cell track

if ~isempty(ForceTrackIndexes)

    ForceTrackIndex = ForceTrackIndexes(1);

    ForceVoltage = TrackData{ForceTrackIndex}(1,:);
    FsForce = TrackInfo{ForceTrackIndex}.SamplingFrequency;
    TimeForce = (0:numel(ForceVoltage)-1) / FsForce;

end

%% Extract Performed Path

if ~isempty(PerformedTrackIndex)

    TrapezoidalPerformed = TrackData{PerformedTrackIndex}(1,:);
    FsTrapezoidalPerformed = TrackInfo{PerformedTrackIndex}.SamplingFrequency;
    TimeTrapezoidalPerformed = (0:numel(TrapezoidalPerformed)-1) / FsTrapezoidalPerformed;

end

%% Extract Original Path

if ~isempty(OriginalTrackIndex)

    TrapezoidalOriginal = TrackData{OriginalTrackIndex}(1,:);
    FsTrapezoidalOriginal = TrackInfo{OriginalTrackIndex}.SamplingFrequency;
    TimeTrapezoidalOriginal = (0:numel(TrapezoidalOriginal)-1) / FsTrapezoidalOriginal;

end

%% Plot Load Cell and trapezoidal tracks

if ~isempty(ForceVoltage) || ~isempty(TrapezoidalPerformed) || ~isempty(TrapezoidalOriginal)

    figure('Name','Load Cell and trapezoidal tracks','NumberTitle','off');

    PlotHandles = gobjects(0);
    PlotLabels = {};

    %% Left axis: Load Cell in volts

    if ~isempty(ForceVoltage)

        yyaxis left

        ForcePlot = plot(TimeForce,ForceVoltage,'Color',[0.10 0.35 0.80],'LineWidth',1);

        ylabel('Load-cell output [V]');

        PlotHandles(end+1) = ForcePlot;
        PlotLabels{end+1} = 'Load Cell';

    end

    %% Right axis: trapezoidal paths in %MVC

    if ~isempty(TrapezoidalPerformed) || ~isempty(TrapezoidalOriginal)

        yyaxis right
        hold on

        if ~isempty(TrapezoidalPerformed)

            PerformedPlot = plot(TimeTrapezoidalPerformed,TrapezoidalPerformed,'Color',[0.85 0.20 0.15],'LineWidth',1.5);

            PlotHandles(end+1) = PerformedPlot;
            PlotLabels{end+1} = 'Performed Path';

        end

        if ~isempty(TrapezoidalOriginal)

            OriginalPlot = plot(TimeTrapezoidalOriginal,TrapezoidalOriginal,'--','Color',[0.15 0.60 0.25],'LineWidth',1.5);

            PlotHandles(end+1) = OriginalPlot;
            PlotLabels{end+1} = 'Original Path';

        end

        ylabel('Force [%MVC]');
        hold off

    end

    xlabel('Time [s]');
    title('Load Cell and trapezoidal feedback');
    grid on

    if ~isempty(PlotHandles)
        legend(PlotHandles,PlotLabels,'Location','best');
    end

else

    % This is a valid condition.
    % The file may contain only EMG, AUX or other signals.

end

%% Display special output variables

if ~isempty(ForceVoltage)

    fprintf('\nLoad Cell variables:\n');
    fprintf('ForceVoltage\n');
    fprintf('TimeForce\n');
    fprintf('FsForce\n');

end

if ~isempty(TrapezoidalPerformed)

    fprintf('\nPerformed trapezoidal path variables:\n');
    fprintf('TrapezoidalPerformed\n');
    fprintf('TimeTrapezoidalPerformed\n');
    fprintf('FsTrapezoidalPerformed\n');

end

if ~isempty(TrapezoidalOriginal)

    fprintf('\nOriginal trapezoidal path variables:\n');
    fprintf('TrapezoidalOriginal\n');
    fprintf('TimeTrapezoidalOriginal\n');
    fprintf('FsTrapezoidalOriginal\n');

end

fprintf('\nOTB4 file successfully imported.\n');

%% LOCAL FUNCTIONS

function SignalData = readSignalFile(FileName,TotalChannels,SampleSize)

    FileInfo = dir(FileName);
    FileSize = FileInfo.bytes;

    BytesPerTimeSample = TotalChannels * SampleSize;

    if mod(FileSize,BytesPerTimeSample) ~= 0
        error('The size of %s is not compatible with %d channels and SampleSize = %d bytes.',FileName,TotalChannels,SampleSize);
    end

    ExpectedSamples = FileSize / BytesPerTimeSample;

    FileID = fopen(FileName,'r','ieee-le');

    if FileID == -1
        error('Unable to open signal file: %s',FileName);
    end

    FileCleanup = onCleanup(@() fclose(FileID));

    switch SampleSize

        case 2

            SignalData = fread(FileID,[TotalChannels ExpectedSamples],'int16=>double');

        case 3

            RawBytes = fread(FileID,Inf,'uint8=>uint32');

            if mod(numel(RawBytes),3) ~= 0
                error('Invalid int24 file size: %s',FileName);
            end

            RawBytes = reshape(RawBytes,3,[]);

            Values = RawBytes(1,:) + bitshift(RawBytes(2,:),8) + bitshift(RawBytes(3,:),16);

            NegativeValues = Values >= 2^23;

            Values = double(Values);
            Values(NegativeValues) = Values(NegativeValues) - 2^24;

            SignalData = reshape(Values,TotalChannels,ExpectedSamples);

        case 4

            SignalData = fread(FileID,[TotalChannels ExpectedSamples],'int32=>double');

        case 8

            SignalData = fread(FileID,[TotalChannels ExpectedSamples],'double=>double');

        otherwise

            error('Unsupported SampleSize: %d bytes in file %s.',SampleSize,FileName);

    end

    if size(SignalData,2) ~= ExpectedSamples
        error('Incomplete signal data read from %s.',FileName);
    end
end

function Value = getXMLText(Structure,FieldName,DefaultValue)

    Value = DefaultValue;

    if ~isfield(Structure,FieldName)
        return
    end

    Field = Structure.(FieldName);

    if isstruct(Field) && isfield(Field,'Text')
        Value = Field.Text;
    elseif ischar(Field)
        Value = Field;
    elseif isstring(Field)
        Value = char(Field);
    end
end

function Value = getXMLNumber(Structure,FieldName,DefaultValue)

    TextValue = getXMLText(Structure,FieldName,'');

    if isempty(TextValue)
        Value = DefaultValue;
        return
    end

    Value = str2double(TextValue);

    if isnan(Value)
        Value = DefaultValue;
    end
end

function Value = getXMLLogical(Structure,FieldName,DefaultValue)

    TextValue = lower(getXMLText(Structure,FieldName,''));

    if isempty(TextValue)
        Value = DefaultValue;
    else
        Value = strcmp(TextValue,'true') || strcmp(TextValue,'1');
    end
end

function plotSingleTrack(Information,Data)

    SamplingFrequency = Information.SamplingFrequency;

    if ~isnan(SamplingFrequency) && SamplingFrequency > 0
        Time = (0:size(Data,2)-1) / SamplingFrequency;
    else
        Time = 0:size(Data,2)-1;
    end

    FigureName = Information.Title;

    if ~isempty(Information.SubTitle)
        FigureName = [Information.Title,' - ',Information.SubTitle];
    end

    figure('Name',FigureName,'NumberTitle','off');

    NumberOfChannels = size(Data,1);

    if NumberOfChannels == 1

        plot(Time,Data(1,:),'LineWidth',1);

    else

        ChannelAmplitude = max(abs(Data),[],2);
        ChannelAmplitude(ChannelAmplitude == 0) = 1;

        TypicalAmplitude = median(ChannelAmplitude);

        if TypicalAmplitude == 0 || isnan(TypicalAmplitude)
            TypicalAmplitude = 1;
        end

        VerticalSpacing = 2.5 * TypicalAmplitude;

        hold on

        for channel = 1:NumberOfChannels

            Offset = -(channel-1) * VerticalSpacing;

            plot(Time,Data(channel,:) + Offset);

        end

        hold off

    end

    xlabel('Time [s]');
    ylabel(Information.Unit);
    title(FigureName,'Interpreter','none');
    grid on
end

function removeTempFolder(FolderName)

    if isfolder(FolderName)
        rmdir(FolderName,'s');
    end
end