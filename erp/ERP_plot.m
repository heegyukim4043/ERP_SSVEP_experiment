eeglab;
ft_defaults;
clc;
clear;
close all;
%%
% filter param.
filt_band = [1 30] ;
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
eeg = pop_chanedit(eeg,'lookup');
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
data = eeg.data;

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
%% ERP topo
erp_cond1 = mean(ep_data{1}, 3);   % ch x time
erp_cond2 = mean(ep_data{2}, 3);   % ch x time

erp_compare = cat(3, erp_cond1, erp_cond2);  % ch x time x 2

figure;
plottopo(erp_compare, ...
    'chanlocs', eeg.chanlocs, ...
    'frames', size(erp_compare,2), ...
    'limits', [-200 800 -25 25], ...
    'title', 'ERP comparison', ...
    'colors', {'b', 'r'}, ...
    'legend', {'Condition 1', 'Condition 2'}, ...
    'ydir', 1);

%% erp stack trials

for idx_class  = 1 : length(class_marker)
    figure,
    erp_data =ep_data{idx_class};
    erpimage(squeeze(erp_data(ismember(ch_locs,'P4'),:,:)),[],...
        [window_size(1)*1000, diff(window_size)*eeg.srate, eeg.srate],...
         'example', 5, 1, 'erp', 'on');
end

%% erp class comparision

class_color = {'r','b'};


for idx_class = 1 :length(class_marker)
    erp_data =ep_data{idx_class};
    avg_erp(idx_class,:)  = squeeze(mean(erp_data(ismember(ch_locs,'P4'),:,:),3));
end

figure;
for idx_class = 1 :length(class_marker)
    hold on;
    time_x = [window_size(1)*eeg.srate:window_size(2)*eeg.srate-1]/eeg.srate;
    plot(time_x,avg_erp(idx_class,:),'LineWidth',1,'color',class_color{idx_class});
    
end
hold off;
grid;
xline(0,'k','LineWidth',1.5);
yline(0,'k','LineWidth',1.5);
% legend

%%
%% baseline correction 

time_ep = [window_size(1)*eeg.srate:window_size(2)*eeg.srate-1];
baseline_idx = time_ep >= -300 & time_ep <= 0;


for idx_class = 1: length(class_marker)
    
    erp_data =ep_data{idx_class};
    clear erp_corr_data;
    for idx_trial = 1: size(erp_data,3)
        for idx_ch = 1 :  size(erp_data,1)
            clear base_mean;
            base_mean = mean(erp_data(idx_ch, baseline_idx,idx_trial));
            erp_corr_data(idx_ch, :,idx_trial) = erp_data(idx_ch, :,idx_trial) - base_mean;
        end
    end
    ep_data_corr{idx_class} = erp_corr_data;
end

%% erp stack trials 
for idx_class  = 1 : length(class_marker)
    figure,
    erp_data =ep_data_corr{idx_class};
    
    erpimage(squeeze(erp_data(ismember(ch_locs,'Pz'),:,:)),[],...
        [window_size(1)*1000, diff(window_size)*eeg.srate, eeg.srate],...
         'example', 5, 1, 'erp', 'on');
end

%% erp class comparision

class_color = {'r','b'};


for idx_class = 1 :length(class_marker)
    erp_data =ep_data_corr{idx_class};
    avg_erp(idx_class,:)  = squeeze(mean(erp_data(ismember(ch_locs,'Pz'),:,:),3));
end

figure;
for idx_class = 1 :length(class_marker)
    hold on;
    time_x = [window_size(1)*eeg.srate:window_size(2)*eeg.srate-1]/eeg.srate;
    plot(time_x,avg_erp(idx_class,:),'LineWidth',1,'color',class_color{idx_class});
    
end
hold off;
grid;
xline(0,'k','LineWidth',1.5);
yline(0,'k','LineWidth',1.5);
%% topo erp


for idx_class = 1 :length(class_marker)
    figure,
    erp_data =ep_data_corr{idx_class};
    times = linspace(window_size(1)*1000, window_size(2)*1000, size(erp_data,2));
    plottopo(mean(erp_data,3),'chanlocs',eeg.chanlocs,'frames',size(erp_data, 2),'limits',[-200 800 -15 15]);
end


