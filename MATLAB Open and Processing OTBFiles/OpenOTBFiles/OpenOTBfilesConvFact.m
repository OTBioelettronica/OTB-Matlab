% Reads files of type OTB+, extrapolating the information on the signal,
% in turn uses the xml2struct function to read file.xml 
% and allocate them in an easily readable Matlab structure.
% Isn't possible to read OTB files because the internal structure of these
% files is different.

clear all
close all
fclose all
clc

FILTERSPEC = {'*.otb+','OTB+ files'; '*.otb','OTB file'; '*.zip', 'zip file'};
[FILENAME, PATHNAME] = uigetfile(FILTERSPEC,'titolo');

% Make new folder
mkdir('tmpopen');  
%cd('tempopen');

% Extract contents of tar file
untar([PATHNAME FILENAME],'tmpopen');

nCh = 1;
% Unzip([PATHNAME FILENAME]);
signals=dir(fullfile('tmpopen','*.sig')); %List folder contents and build full file name from parts
for nSig=1%:length(signals)
    %PowerSupply{nSig} = 4.8;
    abstracts{nSig}=[signals(nSig).name(1:end-4) '.xml'];
    abs = xml2struct(fullfile('.','tmpopen',abstracts{nSig}));
    for nAtt=1:length(abs.Device.Attributes)
        for ad = 1:length(abs.Device.Channels.Adapter)
            device{nSig} = textscan(abs.Device.Attributes.Name, '%s', 1, 'Delimiter', ';');
            device{nSig} = device{1}{1};
            adapter{ad} = abs.Device.Channels.Adapter{nSig,ad};
            adapter{ad} = textscan(adapter{nSig,ad}.Attributes.ID, '%s', 1, 'Delimiter', ';');
            adapter{ad} = adapter{1,ad}{1,1};
            Fsample{nSig}=str2num(abs.Device.Attributes.SampleFrequency);
            nChannel{nSig}=str2num(abs.Device.Attributes.DeviceTotalChannels);
            nADBit{nSig}=str2num(abs.Device.Attributes.ad_bits);
        end
    end

    vett=zeros(1,nChannel{nSig});
    Gains{nSig}=vett;
    for nChild=1:length(abs.Device.Channels.Adapter)
        localGain{nSig}=str2num(abs.Device.Channels.Adapter{nChild}.Attributes.Gain);
        startIndex{nSig}=str2num(abs.Device.Channels.Adapter{nChild}.Attributes.ChannelStartIndex);

        Channel = abs.Device.Channels.Adapter{nChild}.Channel;
        for nChan=1:length(Channel)
            if iscell(Channel)
                ChannelAtt = Channel{nChan}.Attributes;
            elseif isstruct(Channel)
                ChannelAtt = Channel(nChan).Attributes;
            end
            idx=str2num(ChannelAtt.Index);
            Gains{nSig}(startIndex{nSig}+idx+1)=localGain{nSig};

        end
    end

    h=fopen(fullfile('tmpopen',signals(nSig).name),'r');
    data=fread(h,[nChannel{nSig} Inf],'short'); 
    fclose(h);

    processed(signals);
   
    Data{nSig}=data;
    figs{nSig}=figure;
    for nad=1:length(abs.Device.Channels.Adapter)
        if strcmp(device{nSig},'QUATTROCENTO')|| strcmp(device{nSig},'QUATTRO')
            if strcmp(adapter{nSig,nad},'Direct connection')
                for i=1:length(abs.Device.Channels.Adapter{nSig,nad}.Channel)
                    data(nCh,:)=data(nCh,:)*0.1526;       % = ConvFact = PowerSupply{nSig}/(2^nADBit{nSig})*1000/Gains{nSig}(nCh);   PowerSupply=5; nADBit=16; Gain=0.5;
                    nCh = nCh+1;
                end
            elseif strcmp(adapter{nSig,nad},'AdapterControl')
                for i=1:length(abs.Device.Channels.Adapter{nSig,nad}.Channel)
                    data(nCh,:)=data(nCh,:);        
                    nCh = nCh+1;
                end
            else
                for i=1:length(abs.Device.Channels.Adapter{nSig,nad}.Channel)
                    data(nCh,:)=data(nCh,:)*0.00050863;   % = ConvFact = PowerSupply{nSig}/(2^nADBit{nSig})*1000/Gains{nSig}(nCh);   PowerSupply=5; nADBit=16; Gain=150;
                    nCh = nCh+1;
                end
            end
        elseif (strcmp(device{nSig},'DUE+') || strcmp(device{nSig},'QUATTRO+'))
            if (strcmp(adapter{nSig,nad},'AdapterControl')|| strcmp(adapter{nSig,nad},'AdapterQuaternions'))
                for i=1:length(abs.Device.Channels.Adapter{nSig,nad}.Channel)
                    data(nCh,:)=data(nCh,:);
                    nCh = nCh+1;
                end
            else
                for i=1:length(abs.Device.Channels.Adapter{nSig,nad}.Channel)
                    data(nCh,:)=data(nCh,:)*0.00024928;       % = ConvFact = PowerSupply{nSig}/(2^nADBit{nSig})*1000/Gains{nSig}(nCh);   PowerSupply=3.3; nADBit=16; Gain=202;
                    nCh = nCh+1;
                end
            end
        elseif strcmp(device{nSig},'DUE')
            if (strcmp(adapter{nSig,nad},'AdapterControl')|| strcmp(adapter{nSig,nad},'AdapterQuaternions'))
                for i=1:length(abs.Device.Channels.Adapter{nSig,nad}.Channel)
                    data(nCh,:)=data(nCh,:);
                    nCh = nCh+1;
                end
            else
                for i=1:length(abs.Device.Channels.Adapter{nSig,nad}.Channel)
                    data(nCh,:)=data(nCh,:)*0.00038147;       % = ConvFact = PowerSupply{nSig}/(2^nADBit{nSig})*1000/Gains{nSig}(nCh);   PowerSupply=5; nADBit=16; Gain=200;
                    nCh = nCh+1;
                end
            end
        elseif (strcmp(device{nSig},'SYNCSTATION'))
            if (strcmp(adapter{nSig,nad},'Due+') || strcmp(adapter{nSig,nad},'Quattro+'))
                for i=1:length(abs.Device.Channels.Adapter{nSig,nad}.Channel)
                    data(nCh,:)=data(nCh,:)*0.00024928;   % = ConvFact = PowerSupply{nSig}/(2^nADBit{nSig})*1000/Gains{nSig}(nCh);   PowerSupply=3.3; nADBit=16; Gain=202;
                    nCh = nCh+1;
                end
            elseif strcmp(adapter{nSig,nad},'Direct connection to Syncstation Input')
                for i=1:length(abs.Device.Channels.Adapter{nSig,nad}.Channel)
                    data(nCh,:)=data(nCh,:)*0.1526;       % = ConvFact = PowerSupply{nSig}/(2^nADBit{nSig})*1000/Gains{nSig}(nCh);   PowerSupply=5; nADBit=16; Gain=0.5;
                    nCh = nCh+1;
                end
            elseif strcmp(adapter{nSig,nad},'AdapterLoadCell')
                for i=1:length(abs.Device.Channels.Adapter{nSig,nad}.Channel)
                    data(nCh,:)=data(nCh,:)*0.00037217;   % = ConvFact = PowerSupply{nSig}/(2^nADBit{nSig})*1000/Gains{nSig}(nCh);   PowerSupply=5; nADBit=16; Gain=205;
                    nCh = nCh+1;
                end
            elseif (strcmp(adapter{nSig,nad},'AdapterControl') || strcmp(adapter{nSig,nad},'AdapterQuaternions'))
                for i=1:length(abs.Device.Channels.Adapter{nSig,nad}.Channel)
                    data(nCh,:)=data(nCh,:);
                    nCh = nCh+1;
                end
            else
                for i=1:length(abs.Device.Channels.Adapter{nSig,nad}.Channel)
                    data(nCh,:)=data(nCh,:)*0.00028610;   % = ConvFact = PowerSupply{nSig}/(2^nADBit{nSig})*1000/Gains{nSig}(nCh);   PowerSupply=4.8; nADBit=16; Gain=256;
                    nCh = nCh+1;
                end
            end   
        else
            if (strcmp(adapter{nSig,nad},'AdapterControl')|| strcmp(adapter{nSig,nad},'AdapterQuaternions'))
                for i=1:length(abs.Device.Channels.Adapter{nSig,nad}.Channel)
                    data(nCh,:)=data(nCh,:);
                    nCh = nCh+1;
                end
            else
                for i=1:length(abs.Device.Channels.Adapter{nSig,nad}.Channel)
                    data(nCh,:)=data(nCh,:)*0.00028610;       % = ConvFact = PowerSupply{nSig}/(2^nADBit{nSig})*1000/Gains{nSig}(nCh);   PowerSupply=4.8; nADBit=16; Gain=256;
                                                              %                                                                          PowerSupply=4.8; nADBit=24; Gain=1;  
                    nCh = nCh+1;
                end
            end
        end                                                      
    end  

    MyPlotNormalized(figs{nSig},[1:length(data(1,:))]/Fsample{nSig},data);
    MyPlot(figure,[1:length(data(1,:))]/Fsample{nSig},data,0.5);
end

rmdir('tmpopen','s');

% % theFiles = dir;
% % for k = 1 : length(theFiles)
% %   baseFileName = theFiles(k).name;
% %   fprintf(1, 'Now deleting %s\n', baseFileName);
% %   delete(baseFileName);
% % end
% % 
% % cd ..;
% % rmdir('tempopen','s');

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
    maximus=max(max(abs(y)));
    for ii=1:size(y,1)
        plot(x,y(ii,:)-ii*shift);
        hold on
    end
end
