eeglab;
ft_defaults;
clc;
clear;
close all;
%%
clear; clc;
% Note: ft_preproc_bandpassfilter contains filtfilt() for zero-phase
% forward-reverse IIR filter
freq_stop = [59.5 60.5];
nbHarmonics = 4;


% ch_select = {'P1','P2','PZ','PO3','PO4','PO7','PO8','POZ','O1','O2','OZ'};

ch_select = {'O1','O2','OZ'};
% ch_select = {'P4','P3','PZ','O1','O2'};
% FB_sub = [13 70;27 70;41 70];
grid_var = 0:0.25:2;
% frame = [0.1 5.1] ;
stim_freq = [];
for run_idx = 1 : 5
    stim_freq = cat(2,stim_freq, [14:21]+0.2*(run_idx-1) );
end

stim_freq = floor(stim_freq*10)/10;
% FB_sub = [stim_freq(1)-1 nbHarmonics*ceil(stim_freq(end))+1;...
%     2*stim_freq(1)-1 nbHarmonics*ceil(stim_freq(end))+1;...
%     3*stim_freq(1)-1 nbHarmonics*ceil(stim_freq(end))+1;...
%     4*stim_freq(1)-1 nbHarmonics*ceil(stim_freq(end))+1];
for fb_idx =1 : nbHarmonics
    FB_sub(fb_idx,:) =[ fb_idx*stim_freq(1)-1, nbHarmonics*ceil(stim_freq(end))+1];
end
stim_type = 11: 50;
window_size = [0, 5] ;

%%

eeg = pop_biosig('run_feedback-[2026.04.22-18.45.10].gdf');

data = ft_preproc_bandpassfilter(eeg.data,eeg.srate, [13 23] );

if isstr([eeg.event.type])
    event_temp = {eeg.event.type};
    event_temp = erase(event_temp,'condition ');
    for i =1 : length(event_temp)
        event(i) = str2num(event_temp(i));
    end
    latency = [eeg.event.latency];
else
    event = [eeg.event.type];
    latency = [eeg.event.latency];
end


for idx_class = 1 : length(stim_type)
    temp_marker =find(event==stim_type(idx_class));
    onset = latency(temp_marker);
    
    for idx_trial = 1 : length(onset)
        window_set = onset(idx_trial) + [window_size(1)*eeg.srate:window_size(2)*eeg.srate-1];
        ep_data(:,:,idx_class,idx_trial) = data(:,window_set);
         
    end
end



Fs  = eeg.srate;
T = 1/Fs;  
L = size(ep_data,2);                     % Length of signal
t = (0:L-1)*T;    
f = Fs/L*(0:(L/2));

for idx_class = 1 : length(stim_type)
    Y  = fft(ep_data(:,:,idx_class)');
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1,:);
    P1(2:end-1,:) = 2*P1(2:end-1,:);
    
    fft_data(:,:,idx_class) = P1';
end


figure('position',[0 0 1920 1080]);
for idx_class = 1 : length(stim_type)
    subplot(5,8,idx_class)
    plot(f,fft_data(:,:,idx_class));
    grid;
    xline(stim_freq(idx_class),'--b');
    xline(stim_freq(idx_class)*2,'--r');
    xlim([min(stim_freq), ceil(max(stim_freq))*2]);
end


