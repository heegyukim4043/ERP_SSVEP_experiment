eeglab;
ft_defaults;
clc;
clear;
close all;
%%
clear; clc;
% Note: ft_preproc_bandpassfilter contains filtfilt() for zero-phase
% forward-reverse IIR filter

% filter notch
freq_stop = [59 60];
% band pass filter 
freq_band = [1 45] ;

nbHarmonics = 4;

% channel selection
ch_select = {'O1','O2','OZ'};

% stimul param
stim_freq = [];
for run_idx = 1 : 5
    stim_freq = cat(2,stim_freq, [14:21]+0.2*(run_idx-1) );
end
stim_freq = floor(stim_freq*10)/10;

%filter bank 
for fb_idx =1 : nbHarmonics
    FB_sub(fb_idx,:) =[ fb_idx*stim_freq(1)-1, nbHarmonics*ceil(stim_freq(end))+1];
end

% event marker 
stim_type = 11: 50;

% epoch size
window_size = [0, 5] ;

%% Data load

eeg = pop_biosig('run_feedback-[2021.08.14-16.14.38].gdf');

[eeg.data  Chanlocs] = reref(eeg.data , [33,34]);
% filter 
% eeg = pop_eegfiltnew(eeg, 'locutoff',freq_band(1),'hicutoff',freq_band(2),'plotfreqz',1);
% eeg = pop_eegfiltnew(eeg, 'locutoff',freq_stop(1),'hicutoff',freq_stop(2),'revfilt',1,'plotfreqz',1);

eeg.data = ft_preproc_bandpassfilter(eeg.data,eeg.srate, freq_band);
eeg.data = ft_preproc_bandstopfilter(eeg.data,eeg.srate, freq_stop);



figure('position',[0 0 1920 1080]./2);
spectopo(eeg.data,0,eeg.srate);
xlim([0 75]);

eegplot(eeg.data,'srate',eeg.srate);
% figure

%% Epoching 

% pop_eegplot(eeg);

% find event marker & latency 
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

% epoching 
for idx_class = 1 : length(stim_type)
    temp_marker =find(event==stim_type(idx_class));
    onset = latency(temp_marker);
    
    for idx_trial = 1 : length(onset)
        window_set = onset(idx_trial) + [window_size(1)*eeg.srate:window_size(2)*eeg.srate-1];
        ep_data(:,:,idx_class,idx_trial) = eeg.data(:,window_set);
         
    end
end

%% FFT 

Fs  = eeg.srate; % srate
T = 1/Fs;        % timepoint bin
L = size(ep_data,2); % Length of signal
t = (0:L-1)*T;       % timepoint
f = Fs/L*(0:(L/2));  % frequency point bin

clear fft_data P1 P2 Y;
for idx_class = 1 : length(stim_type)
    clear P1 P2 Y;
    Y  = fft(ep_data(:,:,idx_class)');
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1,:);
    P1(2:end-1,:) = 2*P1(2:end-1,:);
    
    fft_data(:,:,idx_class) = P1';
end


%% FFT plot


figure('position',[0 0 1920 1080]);
for idx_class = 1 : length(stim_type)
    subplot(5,8,idx_class)
    plot(f,fft_data(:,:,idx_class));
    grid;
    xline(stim_freq(idx_class),'--g');
    xline(stim_freq(idx_class)*2,'--r');
    xlim([min(stim_freq)-1, ceil(max(stim_freq))*2+1]);
end

%% FFT with padding 
half_len = 5;
clear ep_data_padding;
for i= 1 : size(ep_data,3)
    temp_cat = [];
    temp_cat = cat(2,ep_data(:,:,i),zeros(size(ep_data,1),2*half_len*eeg.srate));
%     temp_cat = cat(2, zeros(size(ep_data,1),half_len*eeg.srate),ep_data(:,:,i));
%     temp_cat = cat(2, temp_cat, zeros(size(ep_data,1),half_len*eeg.srate));
    
    ep_data_padding(:,:,i) = temp_cat;
end

eegplot(temp_cat,'srate',eeg.srate);

Fs  = eeg.srate; % srate
T = 1/Fs;        % timepoint bin
L = size(ep_data,2); % Length of signal
t = (0:L-1)*T;       % timepoint

L2 = size(ep_data_padding,2);
f_padding = Fs/L2*(0:(L2/2));  % frequency point bin

clear fft_padding P1 P2 Y;
for idx_class = 1 : length(stim_type)
    clear P1 P2 Y;
    Y  = fft(ep_data_padding(:,:,idx_class)');
    P2 = abs(Y/L);
    P1 = P2(1:L2/2+1,:);
    P1(2:end-1,:) = 2*P1(2:end-1,:);
    
    fft_padding(:,:,idx_class) = P1';
end


%% FFT plot

plot_xlim_val = [1 10];
plot_ylim_val = [0 1.5];

figure
subplot(3,1,1)
stem(f,fft_data(1,:,1),'filled');
xlim(plot_xlim_val);
ylim(plot_ylim_val);

grid;
subplot(3,1,2)
hold on ;
stem(f_padding,fft_padding(1,:,1));
stem(f_padding,fft_padding(1,:,1));
hold off;
xlim(plot_xlim_val);
ylim(plot_ylim_val);

grid;
subplot(3,1,3)
hold on ;
stem(f,fft_data(1,:,1),'filled');
stem(f_padding,fft_padding(1,:,1));
hold off;
xlim(plot_xlim_val);
ylim(plot_ylim_val);
grid;


figure('position',[0 0 1920 1080]);
for idx_class = 1 : length(stim_type)
    subplot(5,8,idx_class)
    plot(f_padding,fft_padding(:,:,idx_class));
    grid;
    xline(stim_freq(idx_class),'--g');
    xline(stim_freq(idx_class)*2,'--r');
    xlim([min(stim_freq)-1, ceil(max(stim_freq))*2+1]);
end
%% CCA

clear Y_ref ;
Fs  = eeg.srate; % srate
T = 1/Fs;        % timepoint bin
L = size(ep_data,2); % Length of signal
t = (0:L-1)*T;       % timepoint
% gen reference
for idx_class = 1 : 40
    for idx_har = 1: nbHarmonics
        Y_ref(2*idx_har-1,:,idx_class) = sin(2*pi*stim_freq(idx_class)*t*idx_har);
        Y_ref(2*idx_har,:,idx_class) = cos(2*pi*stim_freq(idx_class)*t*idx_har);
    end
end

% max corr.
for idx_class = 1 : 40
    for idx_class_2 = 1 : 40
        [~,~,r] = canoncorr(ep_data(:,:,idx_class_2)',Y_ref(:,:,idx_class)');
        R_max(idx_class,idx_class_2) = max(r);
    end
end

figure
stem(R_max(:,1),'filled');
xlim([-0.5 40.5]);
xline(1,'r--','linewidth',2);

figure
for idx_class = 1 : 40
    subplot(5,8,idx_class)
    stem(R_max(:,idx_class),'filled');
    xlim([-0.5 40.5]);
    xline(idx_class,'r--','linewidth',2);
    yline(max(R_max(:,idx_class)),'g--','linewidth',2);
end

idx_true = 1 : 40;
[~,idx_pred]=max(R_max,[],1);

C = confusionmat(idx_true,idx_pred);
confusionchart(C)