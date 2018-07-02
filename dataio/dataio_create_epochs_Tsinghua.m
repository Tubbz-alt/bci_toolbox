function [] = dataio_create_epochs_Tsinghua(epoch_length, filter_band)
%DATAIO_CREATE_EPOCHS_TSINGHUA Summary of this function goes here
%   Detailed explanation goes here
% created 20-03-2018
% last modified : -- -- --
% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz>

% fs 250 hz
% stim freq: 8:0.2:15.8
% data dim : [64, 1500, 40, 6] [ch samples targets blocks]

% EEG structure: epochs     : struct
%                           :       : signal :  [samples channels trials]
%                           :       : events :  [1 trials]
%                           :       : y      :  [1 trials]
%                fs         : sampling rate
%                montage    : clab
%                classes    : classes {F1,...Fn}
%                paradigm   : struct
%                           :        : title : [str]
%                           :        : stimulation 1
%                           :        : pause 1
%                           :        : stimuli_count 1
%                           :        : type [str]
%                           :        : stimuli [1 stimuli_count]
%                subject    : (depending on the availability of info about
%                                 the subject)

% dataset paradigm:
% joint frequency-phase modulation (JFPM) -0.5s, 5s, +0.5s


tic
disp('Creating epochs for Tsinghua lab JPFM SSVEP dataset');

set_path = 'datasets\tsinghua_jfpm';
dataSetFiles = dir([set_path '\S*.mat']);
dataSetFiles = {dataSetFiles.name};
% EEG montage
montage = fileread([set_path '\64-channels.loc']);
montage = strsplit(montage, '\n');
montage = cellfun(@deblank, montage, 'Uniformoutput', 0);
montage(end-1:end) = [];
clab = cellfun(@(x)x(end-2:end), montage,'Uniformoutput', 0);
% Subjects info
subjects_info = fileread([set_path '\Sub_info.txt']);
subjects_info = strsplit(subjects_info, '\n');
subjects_info([1,2,end]) = [];
%
freqPhase = load([set_path '\Freq_Phase.mat']);
paradigm.title = 'Tsinghua-SSVEP';
paradigm.stimulation = 5000;
paradigm.pause = 0.5;
paradigm.stimuli_count = 40;
paradigm.type = 'SSVEP-JFPM';
paradigm.stimuli = freqPhase.freqs;
paradigm.phase = freqPhase.phases; %0 pi/2 pi 3pi/2
%
classes_r = cellfun(@num2str,num2cell(paradigm.stimuli),'UniformOutput',0);
%
nSubj = 35;
trainEEG = cell(1, nSubj);
testEEG = cell(1, nSubj);
%
fs = 250;
filter_order = 6;
wnd = (epoch_length * fs) / 10^3;
nTrainBlocks = 4;
nTestBlocks = 2;
classes = 1:40;
for subj=1:nSubj
    %     load data, subject info
    disp(['Loading data for subject S0' num2str(subj)]);
    subject_path = [set_path '\' dataSetFiles{subj}];
    rawData = load(subject_path);
    eeg = permute(rawData.data, [2 1 3 4]);
    [~, ~, targets, blocks] = size(eeg);
    disp(['Filtering data for subject S0' num2str(subj)]);
    % filter data
    for block=1:blocks
        eeg(:,:,:,block) = eeg_filter(eeg(:,:,:,block), ...
            fs,...
            filter_band(1),...
            filter_band(2),...
            filter_order...
            );
    end
    %     segment data
    eeg = eeg(wnd(1):wnd(2),:,:,:);
    %     split data
    disp(['Spliting data for subject S0' num2str(subj)]);
    %     trainEEG{subj}.epochs.signal = eeg(:,:,:,1:nTrainBlocks); %needs a reshape
    %     trainEEG{subj}.epochs.events = repmat(paradigm.stimuli, 1, nTrainBlocks);
    %     trainEEG{subj}.epochs.y = repmat(classes, 1, nTrainBlocks);
    %
    %     testEEG{subj}.epochs.signal = eeg(:,:,:,nTrainBlocks+1:end); %needs a reshape
    %     testEEG{subj}.epochs.events = repmat(paradigm.stimuli, 1, nTestBlocks);
    %     testEEG{subj}.epochs.y = repmat(classes, 1, nTestBlocks);
    
    trainEEG{subj}.epochs.signal = reshape(eeg(:,:,:,1:nTrainBlocks), [samples channels nTrainBlocks*targets]);
    trainEEG{subj}.epochs.events = repmat(paradigm.stimuli, 1, nTrainBlocks);
    trainEEG{subj}.epochs.y = repmat(classes, 1, nTrainBlocks);
    
    testEEG{subj}.epochs.signal = reshape(eeg(:,:,:,nTrainBlocks+1:end), [samples channels nTestBlocks*targets]);
    testEEG{subj}.epochs.events = repmat(paradigm.stimuli, 1, nTestBlocks);
    testEEG{subj}.epochs.y = repmat(classes, 1, nTestBlocks);
    %     construct data structures
    trainEEG{subj}.fs = fs;
    trainEEG{subj}.montage.clab = clab;
    trainEEG{subj}.classes = classes_r;
    trainEEG{subj}.paradigm = paradigm;
    subj_info = strsplit(subjects_info{subj}, ' ');
    trainEEG{subj}.subject.id = subj_info{2};
    trainEEG{subj}.subject.gender = subj_info{3};
    trainEEG{subj}.subject.age = subj_info{4};
    trainEEG{subj}.subject.handedness = subj_info{5};
    trainEEG{subj}.subject.group = subj_info{6};
    
    testEEG{subj}.fs = fs;
    testEEG{subj}.montage.clab = clab;
    testEEG{subj}.classes = classes_r;
    testEEG{subj}.paradigm = paradigm;
    testEEG{subj}.subject = trainEEG{subj}.subject;
    %     save data
end

% save
disp('Saving dataset TSINGHUA-SSVEP');
Config_path = 'datasets\epochs\tsinghua_jfpm\';

if(~exist(Config_path,'dir'))
    mkdir(Config_path);
end

save([Config_path '\trainEEG.mat'],'trainEEG','-v7.3');
clear trainEEG
save([Config_path '\testEEG.mat'],'testEEG','-v7.3');
clear testEEG
disp('Data epoched saved in:');
disp(Config_path);
end

