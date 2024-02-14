function[] = processed(signals)

% Reads processed files of type OTB+, extrapolating the information on the signal,
% in turn uses the xml2struct function to read file.pro
% and allocate them in an easily readable Matlab structure.

signals=dir(fullfile('tmpopen','*.sip')); %List folder contents and build full file name from parts
for nSig=1:length(signals)
    abstracts{nSig}=[signals(nSig).name(1:end-4) '.pro'];
    abs{nSig} = xml2struct(fullfile('.','tmpopen',abstracts{nSig}));

    h=fopen(fullfile('tmpopen',signals(nSig).name),'r');
    data{:,nSig} = fread(h, 'double');
    fclose(h);

    plot(data{:,nSig})
    hold on
end



