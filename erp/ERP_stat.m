eeglab;
ft_defaults;
clc;
clear;
close all;
%%
% filter param.
filt_band = [2 30] ;
filt_notch = [59 61];

class_marker = 31:32;
window_size = [-0.5 1];

reject_ch = {'X1','X2','X3','A1','A2'};

%%
% data load 
eeg = pop_biosig('record-[2026.04.23-14.32.52].gdf');
% ch reject 
ch_locs = {eeg.chanlocs.labels};
eeg = pop_select( eeg, 'nochannel',reject_ch);
% load ch locs info.
% eeg = pop_chanedit(eeg,'lookup');
eeg = pop_chanedit(eeg,'lookup','C:\Users\Bio_lab_HG\Documents\MATLAB\eeglab2019_0\plugins\dipfit\standard_BESA\standard-10-5-cap385.elp');

% reref

eeg = pop_reref(eeg,[]); % average reference


% filt data 
eeg = pop_eegfiltnew(eeg, 'locutoff',filt_band(1),'hicutoff',filt_band(2),'plotfreqz',1);
% eeg = pop_eegfiltnew(eeg, 'locutoff',filt_notch(1),'hicutoff',filt_notch(2),'revfilt',1,'plotfreqz',1);
% data = ft_preproc_bandpassfilter(data,eeg.srate,filt_band);

% spectopo(eeg.data,0,eeg.srate)
% xlim([0 25]);
% eegplot(eeg.data,'srate',eeg.srate);
data = eeg.data;   % V → µV 변환

%% Epoching 

% event marker 
if isstr([eeg.event.type])
    event_temp = {eeg.event.type};
    event_temp = erase(event_temp,'condition ');
    for i =1 : length(event_temp)
        event(i) = str2num(event_temp{i});
    end
    latency = [eeg.event.latency];
else
    event = [eeg.event.type];
    latency = [eeg.event.latency];
end


% epoching
clear ep_data;
for idx_class = 1 : length(class_marker)
    temp_marker =find(event==class_marker(idx_class));
    onset = latency(temp_marker);
    
    temp_data = [];
    for idx_trial = 1 : length(onset)
        window_set = onset(idx_trial) + [window_size(1)*eeg.srate:window_size(2)*eeg.srate-1];
         temp_data = cat(3,temp_data,data(:,window_set));      
    end
    
    ep_data{idx_class} = temp_data;
end

%% ERP Statistical Analysis — Cluster-based Permutation Test
% Maris & Oostenveld (2007), J. Neurosci. Methods 164(1):177-190

% ---- param ----
n_perm       = 1000;
alpha_thresh = 0.3;
alpha_sig    = 0.3;
amp_ylim     = [-25 25];   %  ERP y scale [µV]

time_vec  = window_size(1) + (0:size(ep_data{1},2)-1) / eeg.srate;
ch_labels = {eeg.chanlocs.labels};

% Statistical Analysis
result = erp_cluster_perm(ep_data, time_vec, ...
    'n_perm',       n_perm,                                 ...
    'alpha_thresh', alpha_thresh,                           ...
    'alpha_sig',    alpha_sig,                              ...
    'ch_labels',    ch_labels,                              ...
    'cond_labels',  {sprintf('NT %d',class_marker(1)), ...
                     sprintf('T %d',class_marker(2))});

% Visualize — all
% plot_erp_cluster(ep_data, result, 'amp_ylim', amp_ylim);

% Visualize — single channel 
plot_erp_cluster(ep_data, result, 'channel', 'O1', 'amp_ylim', amp_ylim);
% plot_erp_cluster(ep_data, result, 'channel', 1,    'amp_ylim', amp_ylim);


