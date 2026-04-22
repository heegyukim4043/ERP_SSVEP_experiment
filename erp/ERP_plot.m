eeglab;
ft_defaults;
clc;
clear;
close all;
%%

class_marker = 31:34;
window_size = [-0.5 1];

%%
eeg = pop_biosig('record-[2026.04.22-15.25.51].gdf');

data = eeg.data;
data = ft_preproc_bandpassfilter(data,eeg.srate,[1 15]);


% event = eeg.event.type;

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

for idx_class = 1 : 4
    temp_marker =find(event==class_marker(idx_class));
    onset = latency(temp_marker);
    
    for idx_trial = 1 : length(onset)
        window_set = onset(idx_trial) + [window_size(1)*eeg.srate:window_size(2)*eeg.srate-1];
        ep_data(:,:,idx_class,idx_trial) = data(:,window_set);
         
    end
end

%% erp stack trials
for idx_class  = 1 :4
    figure,
    erpimage(squeeze(ep_data(1,:,idx_class,:)),[],[window_size(1)*1000, diff(window_size)*eeg.srate, eeg.srate],...
         'example', 5, 1, 'erp', 'on');
end

%% erp class comparision

class_color = {'r','b','g','y'};


for idx_class = 1 :4
    avg_erp(idx_class,:)  = squeeze(mean(ep_data(1,:,idx_class,:),4));
end

figure;
for idx_class = 1 :4
    hold on;
    time_x = [window_size(1)*eeg.srate:window_size(2)*eeg.srate-1];
    plot(time_x,avg_erp(idx_class,:),'LineWidth',1,'color',class_color{idx_class});
    
end
hold off;
grid;
xline(0,'k','LineWidth',1.5);
yline(0,'k','LineWidth',1.5);
%%
%% baseline correction 

time_ep = [window_size(1)*eeg.srate:window_size(2)*eeg.srate-1];
baseline_idx = time_ep >= -200 & time_ep <= 0;

for idx_trial = 1: size(ep_data,4)
    for idx_class = 1:size(ep_data,3)
        for idx_ch = 1 :  size(ep_data,1)
            clear base_mean;
            base_mean = mean(ep_data(idx_ch, baseline_idx, idx_class,idx_trial));
            erp_corr_data(idx_ch, :, idx_class,idx_trial) = ep_data(idx_ch, :, idx_class,idx_trial) - base_mean;
        end
    end
end

%% erp stack trials 
for idx_class  = 1 :4
    figure,
    erpimage(squeeze(erp_corr_data(1,:,idx_class,:)),[],[window_size(1)*1000, diff(window_size)*eeg.srate, eeg.srate],...
         'example', 5, 1, 'erp', 'on');
end

%% erp class comparision

class_color = {'r','b','g','y'};


for idx_class = 1 :4
    avg_erp(idx_class,:)  = squeeze(mean(erp_corr_data(1,:,idx_class,:),4));
end

figure;
for idx_class = 1 :4
    hold on;
    time_x = [window_size(1)*eeg.srate:window_size(2)*eeg.srate-1];
    plot(time_x,avg_erp(idx_class,:),'LineWidth',1,'color',class_color{idx_class});
    
end
hold off;
grid;
xline(0,'k','LineWidth',1.5);
yline(0,'k','LineWidth',1.5);

