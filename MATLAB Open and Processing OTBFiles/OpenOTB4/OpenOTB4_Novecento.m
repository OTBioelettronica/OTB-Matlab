% Reads files of type OTB4, extrapolating the information on the signal,
% in turn uses the xml2struct function to read file.xml 
% and allocate them in an easily readable Matlab structure.
% It isn't possible to read OTB and OTB+ files because the 
% internal structure of these files is different.

clear all
close all
fclose all
clc

FILTERSPEC = {'*.otb4','OTB4 files'; '*.zip', 'zip file'};
[FILENAME, PATHNAME] = uigetfile(FILTERSPEC,'titolo');

% Make new folder
mkdir('tmpopen');  
%cd('tempopen');

% Extract contents of tar file
untar([PATHNAME FILENAME],'tmpopen');
% Unzip([PATHNAME FILENAME]);
signals=dir(fullfile('tmpopen','*.sig')); %List folder contents and build full file name from parts

nChannel{1}=0;
nCh=zeros(1,length(signals)-1);
Fs=zeros(1,length(signals)-1);
abstracts=['Tracks_000.xml'];
abs = xml2struct(fullfile('.','tmpopen',abstracts));
for ntype=1:length(abs.ArrayOfTrackInfo.TrackInfo)
    for nAtt=1:length(fieldnames(abs.ArrayOfTrackInfo.TrackInfo{:,ntype}))
        device = textscan(abs.ArrayOfTrackInfo.TrackInfo{1,1}.Device.Text, '%s', 1, 'Delimiter', ';');
        device = device{1}{1};
        Gains{ntype}=str2num(abs.ArrayOfTrackInfo.TrackInfo{1,ntype}.Gain.Text);
        nADBit{ntype}=str2num(abs.ArrayOfTrackInfo.TrackInfo{1,ntype}.ADC_Nbits.Text);
        PowerSupply{ntype}=str2num(abs.ArrayOfTrackInfo.TrackInfo{1,ntype}.ADC_Range.Text);
        Fsample{ntype}=str2num(abs.ArrayOfTrackInfo.TrackInfo{1,ntype}.SamplingFrequency.Text);
        Path{ntype}=abs.ArrayOfTrackInfo.TrackInfo{1,ntype}.SignalStreamPath.Text;
        nChannel{ntype+1}=str2num(abs.ArrayOfTrackInfo.TrackInfo{1,ntype}.NumberOfChannels.Text);
        startIndex{ntype}=str2num(abs.ArrayOfTrackInfo.TrackInfo{1,ntype}.AcquisitionChannel.Text);
    end
end 
TotCh = sum(cell2mat(nChannel));

if strcmp(device,'Novecento+')
    for i = 2:length(signals)
        for j = 1:length(Path)
            if(strcmp(Path(j), signals(i).name))
                nCh(i-1) = nCh(i-1) + nChannel{j+1};
                Fs(i-1) = Fsample{j};
                Psup(i-1) = PowerSupply{j};
                ADbit(i-1) = nADBit{j};
                Gain(i-1) = Gains{j};
            end
        end
        
        h=fopen(fullfile('tmpopen', signals(i).name),'r');
        data = fread(h,[nCh(i-1) Inf],'int32');
        fclose(h);

        Data{i-1}=data;
        figs{i-1}=figure;
        for Ch=1:nCh(i-1)
            data(Ch,:)=data(Ch,:)*Psup(i-1)/(2^ADbit(i-1))*1000/Gain(i-1);
        end
        MyPlot(figure,[1:length(data(1,:))]/Fs(i-1),data,0.5);
        MyPlotNormalized(figs{i-1},[1:length(data(1,:))]/Fs(i-1),data);
    end
else
    for nSig = 1%:length(signals)
        h=fopen(fullfile('tmpopen', signals(nSig).name),'r');
        data=fread(h,[TotCh Inf],'short'); 
        fclose(h);
     
        Data{nSig}=data;
        figs{nSig}=figure;

        sumidx = nChannel{1};
        idx = zeros(1, length(nChannel));
        idx(1) = sumidx;
        for i = 2:length(nChannel)
            sumidx = sumidx + nChannel{i};
            idx(i) = sumidx;
        end
        for ntype=2:length(abs.ArrayOfTrackInfo.TrackInfo)+1
            for nCh=idx(ntype-1)+1:idx(ntype)
                data(nCh,:)=data(nCh,:)*PowerSupply{ntype-1}/(2^nADBit{ntype-1})*1000/Gains{ntype-1};
            end
        end

        MyPlot(figure,[1:length(data(1,:))]/Fsample{nSig},data,0.5);
        MyPlotNormalized(figs{nSig},[1:length(data(1,:))]/Fsample{nSig},data);
    end   
end

rmdir('tmpopen','s');

function []=MyPlotNormalized(fig,x,y)
    figure(fig);
    maximus=max(max(abs(y)));
    for ii=1:size(y,1)
        plot(x,y(ii,:)/2/maximus-ii);
        hold on
    end
end

function []=MyPlot(fig,x,y,shift)
    figure(fig);
    for ii=1:size(y,1)
        plot(x,y(ii,:)-ii*shift);
        hold on
    end
end