eeglab;
ft_defaults;
clc; clear; close all;
%% data info.

% data size: 19 x 108000 [ch x time points]
% srate: 300
% 108000 timepoints: concatenate - session1[trial 1 to 10],  session2[trial 1 to 10], ...
% single trial: [instruction(-2~0s) + task cue(0~4s) + feedback(4~7s)]
% 
% behavioral score: 1(coop), 2(defect)
% 
% preproc.
% 	- band pass filer at 1 to 55 Hz and notch at 59 to 61 Hz
% 	- Remove eyeball and muscle artifacts using IC label (p>0.75) 
% 	- refernce: A1


%% param

path_task = './gen_task/dataset';
path_score = './gen_task/behavioral_score';

ch_select = {'Pz','Cz','Fz','O1','O2','Fp1','Fp2'};

ep_type = 'feed' ;% 'int', 'task', 'feed';

filt_type = 'low'; % 'high', 'low' ,'pass' , stop;
filt_highcut = 50;
filt_lowcut = 1;

ch_locs_path = 'C:\Users\pq\Documents\MATLAB\eeglab2022.0\plugins\dipfit\standard_BEM\elec\standard_1005.elc';

method_ica = 'amica';
ICA_prob = 0.75;

ep_len = [-1 2];

%%

for group_idx = 1
    clear file_path;
    file_path = sprintf('%s/group_G%d_score.mat',path_score,group_idx);
    load(file_path); %cat_behavior
    decision_score(:,:,group_idx) = cat_behavior;

    % heatmap(decision_score(:,:,11)')
    
    for sub_idx = 1 
        clear file_path;
        file_path = sprintf('%s/G%d_task_subj_%d.mat',path_task,group_idx,sub_idx);      

        load(file_path); % EEG_struct
        srate = EEG_struct.srate;
        ch_info = {EEG_struct.chanlocs.labels};
    end
end

%% task load & preproc

for group_idx = 1: 11
    clear file_path;
    file_path = sprintf('%s/group_G%d_score.mat',path_score,group_idx);
    load(file_path); %cat_behavior
    decision_score(:,:,group_idx) = cat_behavior;

    % heatmap(decision_score(:,:,11)')
    

    for sub_idx = 1 : 3
        clear file_path;
        file_path = sprintf('%s/G%d_task_subj_%d.mat',path_task,group_idx,sub_idx);      

        load(file_path); % EEG_struct
        srate = EEG_struct.srate;
        ch_info = {EEG_struct.chanlocs.labels};

        switch filt_type
            case 'low'
                EEG_struct.data = ft_preproc_lowpassfilter(EEG_struct.data,srate,filt_highcut);
            case 'high'
                EEG_struct.data = ft_preproc_highpassfilter(EEG_struct.data,srate,filt_lowcut);
            case 'pass'
                EEG_struct.data = ft_preproc_bandpassfilter(EEG_struct.data,srate,[filt_lowcut, filt_highcut]);
            case 'stop'
                EEG_struct.data = ft_preproc_bandstopfilter(EEG_struct.data,srate,[filt_lowcut, filt_highcut]);
        end

        for trial_idx =1 : 40
            switch ep_type

                case 'int'
                    time_range = [1:2*srate] + 9*srate*(trial_idx-1);

                case 'task'
                    time_range = [(2+ep_len(1))*srate+1:(2+ep_len(2))*srate] + 9*srate*(trial_idx-1);

                case 'feed'
                    time_range = [(6+ep_len(1))*srate+1:(6+ep_len(2))*srate] + 9*srate*(trial_idx-1);
            end
            check_ep = EEG_struct.data(:,time_range);

            clear EEG_struct_preproc;
            EEG_struct_preproc = struct;

            EEG_struct_preproc = EEG_set(EEG_struct_preproc,check_ep,srate,ch_info);
            EEG_struct_preproc = pop_chanedit(EEG_struct_preproc,'lookup',ch_locs_path);

            switch method_ica
                case 'jader'
                    EEG_struct_preproc = pop_runica(EEG_struct_preproc, 'icatype', 'jader');
                case 'amica'
                    EEG_struct_preproc = pop_runamica(EEG_struct_preproc,'indir',[]);
                case 'fastica'
                    EEG_struct_preproc = pop_runica(EEG_struct_preproc, 'fastica');
                case 'defaults'
                    EEG_struct_preproc = pop_runica(EEG_struct_preproc, 'extended', 1);
                otherwise
                    disp('error: method selection');
                    % break ;
            end

            EEG_struct_preproc = iclabel(EEG_struct_preproc);
            EEG_struct_preproc = pop_icflag(EEG_struct_preproc, [0 0;ICA_prob 1; ICA_prob 1; ICA_prob 1; ICA_prob 1; ICA_prob 1; ICA_prob 1]);
            %                                   Brain, Muscle,  Eye,  Heart, Linenoise,Channelnoise,Other
            %             EEG_struct = pop_selectcomps(EEG_struct, [1:size(EEG_struct.data,1)] );
            EEG_struct_preproc = pop_subcomp( EEG_struct_preproc, [], 0);% [] means removing components flagged for rejection


            
            ep_data(:,:,trial_idx,group_idx,sub_idx ) = EEG_struct_preproc.data ;
        end

    end
end

file_name = sprintf('%s_save_1-11group_filt_%.01f_%0.1f_%s.mat',ep_type,filt_lowcut,filt_highcut,method_ica);
save(file_name,"ep_data",'-v7.3');

% output: decision_score, ep_data


%% 
% outerp_pre_coop
% outerp_pre_def
% outerp_post_coop
% outerp_post_def


t= linspace(-1*1000,1*1000,size(outerp_pre_def,2)+1);
t(end) = [];
figure('Position',[0 0 1920 1080]);
for ch_idx =1 : length(ch_select)
    % dat_plot = [outerp_pre_coop(ch_idx, :);outerp_pre_def(ch_idx, :);outerp_post_coop(ch_idx, :);outerp_post_def(ch_idx, :) ];
    dat_plot = [outerp_pre_coop(ch_idx, :);outerp_post_coop(ch_idx, :);outerp_post_def(ch_idx, :) ];
    % 
    subplot(2,4,ch_idx)
    plot(t,dat_plot,'LineWidth',1.5 );
    grid;
    title(sprintf('ch:%s',ch_select{ch_idx}));
    xlim([-500 1000]);
    ylim([-0.9 0.9]);

    hold on;
    plot(200:10:500,zeros(1,length(200:10:500)) ,'r','LineWidth',2.5 );
    hold off;
    
    
end
% legend({'pre coop','pre def','post coop','post def'});
legend({'pre coop','post coop','post def'});

saveas(gca,sprintf('ERP_comparison.png'));
close all;

%% div condition

for group_idx = 1: 11
    clear file_path;
    file_path = sprintf('%s/group_G%d_score.mat',path_score,group_idx);
    load(file_path); %cat_behavior
    decision_score(:,:,group_idx) = cat_behavior;
end
 
% dat = load('task_save_1-11group_filt_1.0_10.0_amica.mat');
dat = load('feed_save_1-11group_filt_1.0_10.0_amica.mat');
srate  = 300;


flag_task_feed = 1;
flag_z_norm = 1 ;
% flag_face_blind = 0;


if flag_z_norm ==1
    erp_range =[-2, 2];
else
    erp_range =[-15, 15];
end

time_re_epoch = [-1, 2];



for group_idx =1: 11
    flag_decisinon =  [false, false, false];
    trial_flag_list = 0;
    group_score_list =decision_score (:,:,group_idx) ;

    for trial_idx= 1 : 40
        flag_change = false; 
        check_decision = find(group_score_list(trial_idx,:) ==2);
        if ~isempty(check_decision)
            flag_decisinon(check_decision) = true;
            flag_change = true;
        end
        
        if flag_change == true & ...
                ((flag_decisinon(1)==true & flag_decisinon(2)==true)|...
                (flag_decisinon(1)==true & flag_decisinon(3)==true)|...
                (flag_decisinon(2)==true & flag_decisinon(3)==true))

                    
            trial_flag_list = trial_idx;
            break;

        end   
    end
   
    
    for sub_idx =1 :  3
        cat_maintain_coop = [];
        cat_pre_coop = [];
        cat_pre_def = [];
        cat_post_coop = [];
        cat_post_def = [];

            
        if flag_z_norm ==1
            temp_sub_data = dat.ep_data(:,:,:,group_idx,sub_idx );
            z_norm_mean = mean(temp_sub_data,[2,3]);
            z_norm_std = std(temp_sub_data,[],[2,3]);
            temp_sub_data = (temp_sub_data - z_norm_mean)./z_norm_std;

            % temp_rest_data = rest.ep_data(:,:,:,group_idx,sub_idx );
            % z_norm_mean = mean(temp_rest_data,[2,3]);
            % z_norm_std = std(temp_rest_data,[],[2,3]);
            % temp_rest_data = (temp_rest_data - z_norm_mean)./z_norm_std;
        else
            temp_sub_data = dat.ep_data(:,:,:,group_idx,sub_idx );
            % temp_rest_data = rest.ep_data(:,:,:,group_idx,sub_idx );
        end


        for trial_idx =1 : 40
  
            % [1:diff(time_re_epoch)*srate] + (time_re_epoch(1) - ep_len(1))*srate;

            temp_data = temp_sub_data(:,...
                [1:diff(time_re_epoch)*srate]+(time_re_epoch(1) - ep_len(1))*srate,...
                trial_idx);

            % cat_rest_data = temp_rest_data(:,:,trial_idx);
            

            if trial_flag_list == 0
 
                cat_maintain_coop = cat(3,cat_maintain_coop,temp_data);
                % cat_maintain_rest = 


            elseif trial_flag_list > trial_idx
                if group_score_list(trial_idx,sub_idx) == 1
                    cat_pre_coop = cat(3,cat_pre_coop,temp_data);
                else
                    cat_pre_def = cat(3,cat_pre_def,temp_data);
                end

            elseif trial_flag_list <= trial_idx
                if group_score_list(trial_idx,sub_idx) ==1
                    cat_post_coop = cat(3,cat_post_coop,temp_data);
                else
                    cat_post_def = cat(3,cat_post_def,temp_data);
                end

            end

        end
        
        results.maintain{group_idx,sub_idx} = cat_maintain_coop;
        results.pre_coop{group_idx,sub_idx} = cat_pre_coop;
        results.pre_def{group_idx,sub_idx} = cat_pre_def;
        results.post_coop{group_idx,sub_idx} = cat_post_coop;
        results.post_def{group_idx,sub_idx} = cat_post_def;
        results.baseline_trial{group_idx} = trial_flag_list;
        resuts.ep_len = time_re_epoch ; 

    
    end
end

%% rest 
rest = load('rest_save_1-11group_filt_1.0_10.0_amica.mat'); 
for group_idx =1: 11
    for sub_idx =1 : 3
        if flag_z_norm ==1
            temp_sub_data  = rest.ep_data(:,:,:,group_idx,sub_idx);
            z_norm_mean = mean(temp_sub_data,[2,3]);
            z_norm_std = std(temp_sub_data,[],[2,3]);
            results.rest{group_idx,sub_idx} = (temp_sub_data - z_norm_mean)./z_norm_std;
        else
            results.rest{group_idx,sub_idx} = rest.ep_data(:,:,:,group_idx,sub_idx);
        end
    end
end

if flag_z_norm ==1
    plot_rest = reshape(ep_data(:,:,:,[1+flag_face_blind: 2: 11],:),size(ep_data,1),size(ep_data,2),[]);
    z_norm_mean = mean(plot_rest,[2,3]);
    z_norm_std = std(plot_rest,[],[2,3]);
    plot_rest = (plot_rest -z_norm_mean )./z_norm_std;
else
    plot_rest = reshape(ep_data(:,:,:,[1+flag_face_blind: 2: 11],:),size(ep_data,1),size(ep_data,2),[]);
end

%%
plot_maintain = [] ;
plot_pre_coop = [] ;
plot_post_coop = [];
plot_pre_def = [] ;
plot_post_def = [] ;

for group_idx =[1: 11]
    for sub_idx =1 : 3

        if ~isempty(results.maintain{group_idx,sub_idx})
            plot_maintain = cat(3, plot_maintain, results.maintain{group_idx,sub_idx} ); % ch x time x trial
        end

        if ~isempty(results.pre_coop{group_idx,sub_idx})
            plot_pre_coop = cat(3, plot_pre_coop, results.pre_coop{group_idx,sub_idx} );
        end

        if ~isempty(results.pre_def{group_idx,sub_idx})
            plot_pre_def = cat(3, plot_pre_def, results.pre_def{group_idx,sub_idx} );
        end

        if ~isempty(results.post_coop{group_idx,sub_idx})
            plot_post_coop = cat(3, plot_post_coop, results.post_coop{group_idx,sub_idx} );
        end

        if ~isempty(results.post_def{group_idx,sub_idx})
            plot_post_def = cat(3, plot_post_def, results.post_def{group_idx,sub_idx} );
        end

    end
end
%% erp permut

dep_sample = false;
p_threshold = 0.001;
num_permutations = 1000;
two_sided = true;
num_clusters = [];

% G{1} = plot_rest;
G{2} = plot_pre_coop;
G{3} = plot_pre_def;
G{4} = plot_post_coop;
G{5} = plot_post_def;

% % cluster rest
% for ch_idx =1 : 19
% 
%     G1 = squeeze(plot_rest(ch_idx,:,:));
% 
%     G2 = squeeze(plot_pre_coop(ch_idx,:,:));
%     G3 = squeeze(plot_pre_def(ch_idx,:,:));
%     G4 = squeeze(plot_post_coop(ch_idx,:,:));
%     G5 = squeeze(plot_post_def(ch_idx,:,:));
% 
%     [clusters_rest{1,ch_idx}, p_values, t_sums, permutation_distribution ] = permutest( G2, G1, dep_sample, ...
%         p_threshold, num_permutations, two_sided, num_clusters );
%     [clusters_rest{2,ch_idx}, p_values, t_sums, permutation_distribution ] = permutest( G3, G1, dep_sample, ...
%         p_threshold, num_permutations, two_sided, num_clusters );
%     [clusters_rest{3,ch_idx}, p_values, t_sums, permutation_distribution ] = permutest( G4, G1, dep_sample, ...
%         p_threshold, num_permutations, two_sided, num_clusters );
%     [clusters_rest{4,ch_idx}, p_values, t_sums, permutation_distribution ] = permutest( G5, G1, dep_sample, ...
%         p_threshold, num_permutations, two_sided, num_clusters );
% end




C  = nchoosek(2:5,2);


for ch_idx =1 : length(ch_info)

    % G1 = squeeze(plot_rest(ch_idx,:,:));

    G2 = squeeze(plot_pre_coop(ch_idx,:,:));
    G3 = squeeze(plot_pre_def(ch_idx,:,:));
    G4 = squeeze(plot_post_coop(ch_idx,:,:));
    G5 = squeeze(plot_post_def(ch_idx,:,:));

    [clusters_task{1,ch_idx}, p_values, t_sums, permutation_distribution ] = permutest( G2, G3, dep_sample, ...
        p_threshold, num_permutations, two_sided, num_clusters );
    [clusters_task{2,ch_idx}, p_values, t_sums, permutation_distribution ] = permutest( G2, G4, dep_sample, ...
        p_threshold, num_permutations, two_sided, num_clusters );
    [clusters_task{3,ch_idx}, p_values, t_sums, permutation_distribution ] = permutest( G2, G5, dep_sample, ...
        p_threshold, num_permutations, two_sided, num_clusters );
    [clusters_task{4,ch_idx}, p_values, t_sums, permutation_distribution ] = permutest( G3, G4, dep_sample, ...
        p_threshold, num_permutations, two_sided, num_clusters );
    [clusters_task{5,ch_idx}, p_values, t_sums, permutation_distribution ] = permutest( G3, G5, dep_sample, ...
        p_threshold, num_permutations, two_sided, num_clusters );
    [clusters_task{6,ch_idx}, p_values, t_sums, permutation_distribution ] = permutest( G4, G5, dep_sample, ...
        p_threshold, num_permutations, two_sided, num_clusters );

end

beep;
%% permut erp rest - each conditions


% cond_str = {'Pre-coop','Pre-def','Post-coop','Post-def'};
% face_blind_str = {'face','blind'};
% dec_feed_str ={'decision','feedback'};
% 
% t= linspace(-1*1000,2*1000,size(plot_pre_coop,2)+1);
% t(end) = [];
% 
% 
% for cond_idx =1 : 4
%     figure('Position',[0 0 1920 1080]);
%     for ch_idx =1 : length(ch_select)
% 
%         subplot(4,2,ch_idx)
% 
%         check_cluster = clusters_rest{cond_idx,ismember(ch_info,ch_select(ch_idx))};
% 
%         cat_cluster = [];
%         for clus_idx = 1 : length(check_cluster)
%             temp_val = cell2mat(check_cluster(clus_idx));
%             for i = 1 : length(temp_val)
%                 cat_cluster = cat(1,cat_cluster,temp_val(i));
%             end
% 
%         end
% 
%         plot_val_a = squeeze( G{1}(ismember(ch_info,ch_select(ch_idx)),:,:));
%         plot_val_b = squeeze( G{1+cond_idx}(ismember(ch_info,ch_select(ch_idx)),:,:));
% 
%         dat_plot = [mean(plot_val_a,2),mean(plot_val_b,2) ];
% 
%         hold on;
%         plot(t,dat_plot,'LineWidth',1.5 );
%         grid;
%         title(sprintf('ch:%s',ch_info{ismember(ch_info,ch_select(ch_idx))}));
%         xlim([-500 1000]);
%         ylim([-0.9 0.9]);
% 
%         if ~isempty(cat_cluster)
%             scatter(t(cat_cluster),zeros(size(cat_cluster)),'g','*' ,'LineWidth',1.5);
%         else
%             scatter(ones(1,1),NaN(1,1),'filled','g');
%         end
% 
%         xlabel('Time(ms)','FontSize',12);
%         hold off;
% 
% 
%     end
%     hSub = subplot(4,2,8);
%     hold on;
%     scatter(ones(2,2),NaN(2,2),'filled'); 
%     scatter(ones(1,1),NaN(1,1),'filled','g'); 
%     hold off;
%     set(hSub, 'Visible', 'off');
%     lgd = legend({cond_str{cond_idx},'Rest','Permut'},'Location','northwest',...
%     'Orientation','horizontal','FontSize',12);
% 
%     % saveas(gca,sprintf('ERP_comparison_%s_%s_%s.png',dec_feed_str{flag_task_feed+1},face_blind_str{flag_face_blind+1},cond_str{cond_idx}));
%     % close all;
% end

%% topo_rest is sig
% figure('Position',[0 0 1920/2 1080]);
% for cond_idx =1 : 4
%     subplot(2,2,cond_idx);
%      for ch_idx =1 : length(ch_info)
%          check_cluster = clusters_rest{cond_idx,ch_idx};
% 
%          cat_cluster = [];
%          for clus_idx = 1 : length(check_cluster)
%              temp_val = cell2mat(check_cluster(clus_idx));
%              for i = 1 : length(temp_val)
%                  cat_cluster = cat(1,cat_cluster,temp_val(i));
%              end
% 
%          end
% 
%          find(t(cat_cluster)>= -500 & t(cat_cluster) <= 1000 );
% 
%          vec_isch_list(ch_idx) = ~isempty(t(cat_cluster)>= -500 & t(cat_cluster) <= 1000 );
%      end
% 
%     topoplot(vec_isch_list,EEG_struct.chanlocs);
%     caxis([0 1]);
%     colorbar('hot');
%     title(cond_str{cond_idx});
% end
% saveas(gca,sprintf('Topo_rest_comparison_%s_%s.png',dec_feed_str{flag_task_feed+1},face_blind_str{flag_face_blind+1}));
% close all;



%% permut erp pairwise


cond_str = {'Pre-coop','Pre-def','Post-coop','Post-def'};
face_blind_str = {'face','blind'};
dec_feed_str ={'decision','feedback'};

t= linspace(-1*1000,2*1000,size(plot_pre_coop,2)+1);
t(end) = [];

% C  = nchoosek(2:5,2);

for cond_idx =1 : 6
    figure('Position',[0 0 1920/2 1080]);
    for ch_idx =1 : length(ch_select)

        subplot(4,2,ch_idx)

        check_cluster = clusters_task{cond_idx,ismember(ch_info,ch_select(ch_idx))};

        cat_cluster = [];
        for clus_idx = 1 : length(check_cluster)
            temp_val = cell2mat(check_cluster(clus_idx));
            for i = 1 : length(temp_val)
                cat_cluster = cat(1,cat_cluster,temp_val(i));
            end

        end

        plot_val_a = squeeze( G{C(cond_idx,1)}(ismember(ch_info,ch_select(ch_idx)),:,:));
        plot_val_b = squeeze( G{C(cond_idx,2)}(ismember(ch_info,ch_select(ch_idx)),:,:));

        dat_plot = [mean(plot_val_a,2),mean(plot_val_b,2) ];
 
        hold on;
        plot(t,dat_plot,'LineWidth',3.5 );
        grid;
        title(sprintf('EEG Chan:%s',ch_info{ismember(ch_info,ch_select(ch_idx))}));
        xlim([-500 1000]);
        ylim([-0.9 0.9]);

        if ~isempty(cat_cluster)
            scatter(t(cat_cluster),zeros(size(cat_cluster)),'g','*' ,'LineWidth',2.5);
        else
            scatter(ones(1,1),NaN(1,1),'filled','g');
        end

        xlabel('Time(ms)','FontSize',12);
        hold off;


    end
    hSub = subplot(4,2,8);
    hold on;
    scatter(ones(2,1),NaN(2,1),'filled'); 
    scatter(ones(2,1),NaN(2,1),'filled'); 
    scatter(ones(1,1),NaN(1,1),'filled','g'); 
    hold off;
    set(hSub, 'Visible', 'off');
    lgd = legend({cond_str{C(cond_idx,1)-1},cond_str{C(cond_idx,2)-1},'Permut-Sig'},'Location','northwest',...
    'Orientation','horizontal','FontSize',12);

    saveas(gca,sprintf('ERP_comparison_%s_%s_%s.png',dec_feed_str{flag_task_feed+1},face_blind_str{flag_face_blind+1},...
        strcat(cond_str{C(cond_idx,1)-1},cond_str{C(cond_idx,2)-1} )));
    close all;
end

%% permut erp pairwise - 


cond_str = {'Pre-coop','Pre-def','Post-coop','Post-def'};
face_blind_str = {'face','blind'};
dec_feed_str ={'decision','feedback'};

t= linspace(-1*1000,2*1000,size(plot_pre_coop,2)+1);
t(end) = [];

% C  = nchoosek(2:5,2);

ch_select={'P3','P4','O2','F7','F8','T5','Fp1'};

for cond_idx =1 : 6
    figure('Position',[0 0 1920/2 1080]);
    for ch_idx =1 : length(ch_select)

        subplot(4,2,ch_idx)

        check_cluster = clusters_task{cond_idx,ismember(ch_info,ch_select(ch_idx))};

        cat_cluster = [];
        for clus_idx = 1 : length(check_cluster)
            temp_val = cell2mat(check_cluster(clus_idx));
            for i = 1 : length(temp_val)
                cat_cluster = cat(1,cat_cluster,temp_val(i));
            end

        end

        plot_val_a = squeeze( G{C(cond_idx,1)}(ismember(ch_info,ch_select(ch_idx)),:,:));
        plot_val_b = squeeze( G{C(cond_idx,2)}(ismember(ch_info,ch_select(ch_idx)),:,:));

        dat_plot = [mean(plot_val_b,2),mean(plot_val_a,2) ];
 
        hold on;
        plot(t,dat_plot,'LineWidth',3.5 );
        grid;
        title(sprintf('EEG Chan:%s',ch_info{ismember(ch_info,ch_select(ch_idx))}));
        xlim([-500 1000]);
        ylim([-0.9 0.9]);

        if ~isempty(cat_cluster)
            scatter(t(cat_cluster),zeros(size(cat_cluster)),'g','*' ,'LineWidth',2.5);
        else
            scatter(ones(1,1),NaN(1,1),'filled','g');
        end

        xlabel('Time(ms)','FontSize',12);
        hold off;


    end
    hSub = subplot(4,2,8);
    hold on;
    scatter(ones(2,1),NaN(2,1),'filled'); 
    scatter(ones(2,1),NaN(2,1),'filled'); 
    scatter(ones(1,1),NaN(1,1),'filled','g'); 
    hold off;
    set(hSub, 'Visible', 'off');
    lgd = legend({cond_str{C(cond_idx,1)-1},cond_str{C(cond_idx,2)-1},'Permut-Sig'},'Location','northwest',...
    'Orientation','horizontal','FontSize',12);

    saveas(gca,sprintf('ERP_comparison_%s_%s_%s.png',dec_feed_str{flag_task_feed+1},face_blind_str{flag_face_blind+1},...
        strcat(cond_str{C(cond_idx,1)-1},cond_str{C(cond_idx,2)-1} )));
    close all;
end


%% topo_pairwise distance 

cond_str = {'Pre-coop','Pre-def','Post-coop','Post-def'};
win_list = [0 300; 200 350; 400 800]./1000;
fs =srate;
bin = 10; % samples per bin (adjust as needed)



for win_idx =1 : size(win_list,1)
    winP3 = win_list(win_idx,: );
    idx = [round(winP3(1)*fs):round(winP3(2)*fs)]+300;
    for ch_idx = 1: length(ch_info)
        X_MC = squeeze(G{2}(ch_idx,idx,:));
        X_BC = squeeze(G{4}(ch_idx,idx,:));
        X_BD = squeeze(G{5}(ch_idx,idx,:));
        X_MD = squeeze(G{3}(ch_idx,idx,:));


        % --- 3) z-score features (optional, across trials pooled)
        Z = [X_MC'; X_BC'; X_BD'; X_MD'];
        muZ = mean(Z,1); 
        sdZ = std(Z,[],1)+1e-12;

        
        X_MC = (X_MC' - muZ)./sdZ;
        X_BC = (X_BC' - muZ)./sdZ;
        X_BD = (X_BD' - muZ)./sdZ;
        X_MD = (X_MD' - muZ)./sdZ;

        % --- 4) pooled covariance with ridge
        pool_cov = @(A,B) ((size(A,1)-1)*cov(A) + (size(B,1)-1)*cov(B)) / (size(A,1)+size(B,1)-2);

        ridge_lambda = @(S) 0.05 * trace(S) / size(S,2);

        mu_MC = mean(X_MC,1);

        mu_BC = mean(X_BC,1);
        S_BC  = pool_cov(X_MC, X_BC);
        lamBC = ridge_lambda(S_BC);
        M_BC  = S_BC + lamBC*eye(size(S_BC,2));
        d_BC  = (mu_BC - mu_MC);
        D2_BC = d_BC / M_BC * d_BC.';   % scalar

        mu_BD = mean(X_BD,1);
        S_BD  = pool_cov(X_MC, X_BD);
        lamBD = ridge_lambda(S_BD);
        M_BD  = S_BD + lamBD*eye(size(S_BD,2));
        d_BD  = (mu_BD - mu_MC);
        D2_BD = d_BD / M_BD * d_BD.';   % scalar

        mu_MD = mean(X_MD,1);
        S_MD  = pool_cov(X_MC, X_MD);
        lamMD = ridge_lambda(S_MD);
        M_MD  = S_MD + lamMD*eye(size(S_MD,2));
        d_MD  = (mu_MD - mu_MC);
        D2_MD = d_MD / M_MD * d_MD.';   % scalar

        % disp('Mahalanobis D^2 to MC (mean-vs-mean):');
        ch_distance(ch_idx,win_idx,:)= [D2_BC, D2_BD, D2_MD];


    end
end

%%%%
for win_idx =1 : size(win_list,1)
    figure('Position',[0 0 1920/2 1080]);
    for cond_idx =1 : 3
        subplot(1,3,cond_idx);

        topoplot(ch_distance(:,win_idx,cond_idx)+eps,EEG_struct.chanlocs);
        caxis([0 1]);
        colorbar('hot');
        title(strcat(cond_str{C(cond_idx,1)-1},cond_str{C(cond_idx,2)-1}));
    end
    saveas(gca,sprintf('Topo_pairwise_comparison_%s_%s_win_%d.png',dec_feed_str{flag_task_feed+1},face_blind_str{flag_face_blind+1},win_idx));
    close all;
end

%%
% ---------------------------------------------
% ch_distance: [nCh x nWin x nCond]  (이미 계산됨)
% cond 순서: 1=BC, 2=BD, 3=MD  (위 코드와 동일)
% win_list: [nWin x 2] (초 단위 시작/끝)
% ---------------------------------------------

[nCh, nW, nC] = size(ch_distance);
cond_names = {'M-C vs B-C','M-C vs B-D','M-C vs M-D'}; % 필요시 수정
colors     = [0.20 0.60 0.90; 0.85 0.33 0.10; 1.00 0.75 0.05]; % 파랑/오렌지/골드

figure('Position',[0 0 1200 900]);
tl = tiledlayout(nC, nW, "TileSpacing","compact","Padding","compact");

for wi = 1:nW
    % --- 윈도우별 공통 bin 경계 (Freedman–Diaconis)
    % 채널 값 전부 모아 분포 경계를 정함
    allD = [];
    for ci = 1:nC
        allD = [allD; ch_distance(:,wi,ci)];
    end
    % 이상치 꼬리 잘라 스케일 안정 (선택)
    y_min = prctile(allD, 1);
    y_max = prctile(allD,99);
    nAll  = numel(allD);
    hFD   = 2*iqr(allD) * nAll^(-1/3);
    if hFD<=0 || ~isfinite(hFD)
        hFD = max((y_max - y_min)/15, eps);
    end
    edges = y_min:hFD:y_max;

    % --- 같은 열(=윈도우)에서 cond를 위→아래로 그림
    for ci = 1:nC
        nexttile(ci + (wi-1)*nC); hold on

        D = ch_distance(:,wi,ci);    % [nCh x 1] 채널별 D^2

        % 순수 히스토그램 (세로축 = D^2, 가로축 = 빈도)
        histogram(D, edges, ...
            'Normalization','pdf', ...
            'Orientation','horizontal', ...
            'FaceColor', colors(ci,:), ...
            'EdgeColor','none', ...
            'FaceAlpha', 0.65);

        % 중앙값/사분위 보조선
        med = median(D); q1 = quantile(D,0.25); q3 = quantile(D,0.75);
        xlim auto; xl = xlim;
        plot([xl(1) xl(2)], [med med], 'k-', 'LineWidth',1.4);
        plot([xl(1)+0.05*(xl(2)-xl(1)) xl(1)+0.35*(xl(2)-xl(1))], [q1 q1], 'k-', 'LineWidth',1.0);
        plot([xl(1)+0.05*(xl(2)-xl(1)) xl(1)+0.35*(xl(2)-xl(1))], [q3 q3], 'k-', 'LineWidth',1.0);

        ylim([y_min y_max]); grid on; box off
%         if ci < nC, set(gca,'XTickLabel',[]); end    % 위 행들 x tick 숨김
%         if wi > 1, set(gca,'YTickLabel',[]); end     % 오른쪽 열들 y tick 숨김

        if ci==1
            title(sprintf('%d–%d ms', round(win_list(wi,1)*1000), round(win_list(wi,2)*1000)));
        end
        if wi==1
            ylabel(cond_names{ci}, 'Interpreter','none');
        end
        if ci==nC
            xlabel('Density (pdf)');
        end
    end
end

title(tl,'Channel-wise Mahalanobis D^2 (mean-vs-mean) — Vertical Histograms (Condition × Window)');
saveas(gcf,'Hist_Channelwise_D2_CondByWindow.png');

%%
[nCh,nW,nC] = size(ch_distance);
cond_names = {'M-C vs B-C','M-C vs B-D','M-C vs M-D'};
colors = [0.20 0.60 0.90; 0.85 0.33 0.10; 1.00 0.75 0.05]; % 파랑/오렌지/골드

% 채널 평균만 계산
stat_mean = squeeze(mean(ch_distance,1,'omitnan'));   % [nW x nC]

figure('Position',[0 0 1100 380]);
tiledlayout(1,nW,'TileSpacing','compact','Padding','compact');

for wi = 1:nW
    nexttile; hold on
    b = bar(1:nC, stat_mean(wi,:), 0.7, 'FaceColor','flat');
    b.CData = colors;
    set(gca,'XTick',1:nC,'XTickLabel',cond_names,'XTickLabelRotation',25,...
            'TickDir','out'); box off
    ylabel('Mean Mahalanobis D^2');
    title(sprintf('%d–%d ms', round(win_list(wi,1)*1000), round(win_list(wi,2)*1000)));
    ylim([0, max(stat_mean(:))*1.15]);
    grid;
end




%%

% -----------------------------
% 세로 히스토그램 (위아래로), 바이올린 아님
% 행=컨디션(위→아래), 열=윈도우(좌→우)
% 각 서브플롯: y축=D², x축=빈도
% -----------------------------

cond_names = {'M-C / B-C','M-C / B-D','M-C / M-D'}; % 예시
colors     = [0.20 0.60 0.90; 0.85 0.33 0.10; 1.00 0.75 0.05]; % 파랑/오렌지/골드

nW = size(D2_trials,1);
nC = size(D2_trials,2);

tl = tiledlayout(nC, nW, "TileSpacing","compact","Padding","compact");

for wi = 1:nW
    % --- (1) 윈도우별 공통 bin 경계 (Freedman–Diaconis)
    allD  = cell2mat(D2_trials(wi,:).');
    y_min = prctile(allD,1);      % 꼬리 절단(선택)
    y_max = prctile(allD,99);
    n     = numel(allD);
    hFD   = 2*iqr(allD)*n^(-1/3);
    if hFD<=0 || ~isfinite(hFD)
        hFD = max((y_max-y_min)/20, eps); % fallback
    end
    edges = y_min:hFD:y_max;

    % --- (2) 같은 열(윈도우) 안의 cond 플롯: 위(1)→아래(nC)
    for ci = 1:nC
        nexttile(ci + (wi-1)*nC); hold on  % 행-열 인덱싱을 수동으로

        D = D2_trials{wi,ci};

        % 순수 히스토그램 (세로축=y=D², 막대 가로=빈도)
        histogram(D, edges, ...
                  'Normalization','pdf', ...
                  'FaceColor',colors(ci,:), ...
                  'EdgeColor','none', ...
                  'FaceAlpha',0.65, ...
                  'Orientation','horizontal');

        % 중앙값/사분위 보조선 (y에 위치, x는 빈도축)
        med = median(D); q1 = quantile(D,0.25); q3 = quantile(D,0.75);
        xlim auto; xl = xlim;
        plot([xl(1) xl(2)], [med med], 'k-', 'LineWidth',1.4); % median 라인 진하게
        plot([xl(1)+0.05*(xl(2)-xl(1)) xl(1)+0.35*(xl(2)-xl(1))], [q1 q1], 'k-', 'LineWidth',1.0);
        plot([xl(1)+0.05*(xl(2)-xl(1)) xl(1)+0.35*(xl(2)-xl(1))], [q3 q3], 'k-', 'LineWidth',1.0);

        % 축/레이블
        ylim([y_min y_max]);
        if ci<nC, set(gca,'XTickLabel',[]); end  % 위 패널은 x tick 숨김
        if wi>1,  set(gca,'YTickLabel',[]); end  % 오른쪽 열은 y tick 숨김
        grid on; box off

        if ci==1
            title(sprintf('%d–%d ms', round(win_list(wi,1)*1000), round(win_list(wi,2)*1000)));
        end
        if wi==1
            ylabel(cond_names{ci});
        end
        if ci==nC
            xlabel('Density (pdf)');
        end
    end
end

title(tl,'Trial-wise whole-brain Mahalanobis D^2 — vertical histograms (Condition × Window)');
saveas(gcf,'Hist_Vertical_ConditionRows_WindowCols.png');


%% topo_pairwise is sig
figure('Position',[0 0 1920/2 1080]);

% win_list = [0 200; 200 350; 400 800];


% for wind_idx =1 : 4
    for cond_idx =1 : 6
        subplot(2,3,cond_idx);
        for ch_idx =1 : length(ch_info)
            check_cluster = clusters_task{cond_idx,ch_idx};
            
            cat_cluster = [];
            for clus_idx = 1 : length(check_cluster)
                temp_val = cell2mat(check_cluster(clus_idx));
                for i = 1 : length(temp_val)
                    cat_cluster = cat(1,cat_cluster,temp_val(i));
                end
                
            end
            
            find(t(cat_cluster)>= -500 & t(cat_cluster) <= 1000 );
            
            vec_isch_list(ch_idx) = ~isempty(t(cat_cluster)>= -500 & t(cat_cluster) <= 1000 );
        end
        
        topoplot(vec_isch_list+eps,EEG_struct.chanlocs);
        caxis([0 1]);
        colorbar('hot');
        title(strcat(cond_str{C(cond_idx,1)-1},cond_str{C(cond_idx,2)-1}));
    end
    saveas(gca,sprintf('Topo_pairwise_comparison_%s_%s.png',dec_feed_str{flag_task_feed+1},face_blind_str{flag_face_blind+1}));
    close all;
% end
%% topo_pairwise is sig each win


win_list = [0 300; 200 350; 400 800];


for wind_idx =1 : size(win_list,1)
    figure('Position',[0 0 1920/2 1080]);
    for cond_idx =1 : 6
        subplot(2,3,cond_idx);
        
        vec_isch_list = zeros(1,19);
%         clear vec_isch_list;
        for ch_idx =1 : length(ch_info)
%             check_cluster = clusters_task{cond_idx,ch_idx};
            check_cluster = clusters_task{cond_idx,ch_idx};
            
            cat_cluster = [];
            for clus_idx = 1 : length(check_cluster)
                temp_val = cell2mat(check_cluster(clus_idx));
                for i = 1 : length(temp_val)
                    cat_cluster = cat(1,cat_cluster,temp_val(i));
                end
                
            end
            
%             disp(find(t(cat_cluster)>= win_list(wind_idx,1) & t(cat_cluster) <= win_list(wind_idx,2) ))
            
% (t(cat_cluster)>= win_list(wind_idx,1))

%             vec_isch_list(ch_idx) = ~isempty(t(cat_cluster)>= -500 & t(cat_cluster) <= 1000 );
            vec_isch_list(ch_idx) = any((t(cat_cluster)>= win_list(wind_idx,1)) & (t(cat_cluster) <= win_list(wind_idx,2)));
        end
        
        topoplot(vec_isch_list+eps,EEG_struct.chanlocs);
        caxis([0 1]);
        colorbar('hot');
        title(strcat(cond_str{C(cond_idx,1)-1},cond_str{C(cond_idx,2)-1}));
    end
    saveas(gca,sprintf('Topo_pairwise_comparison_%s_%s_win_%d.png',dec_feed_str{flag_task_feed+1},face_blind_str{flag_face_blind+1},wind_idx));
    close all;
end

%%
% cat_ch_info = {};
% for ch_idx =1 : length(ch_info)
%     cat_ch_info =  cat(2,cat_ch_info, ch_info(ismember(ch_info,ch_select{ch_idx})) );
% end
cat_ch_info = ch_info;


% pre coop
check_struct_rest=struct_ft_format(reshape(plot_pre_coop,size(plot_pre_coop,1),[]),diff(time_re_epoch),srate,cat_ch_info);
cfg           = [];
cfg.method    = 'mtmfft';
% cfg.trial     =  'all';
cfg.taper     = 'dpss';
cfg.output    = 'fourier';
cfg.tapsmofrq = 1;

freq = ft_freqanalysis(cfg, check_struct_rest);


cfg           = [];
cfg.method    = 'coh';
coh           = ft_connectivityanalysis(cfg, freq);
conn_pre_coop.coh = coh;

cfg           = [];
cfg.method    = 'plv';
plv           = ft_connectivityanalysis(cfg, freq);

conn_pre_coop.plv = plv;

% pre def
check_struct_rest=struct_ft_format(reshape(plot_pre_def,size(plot_pre_def,1),[]),diff(time_re_epoch),srate,cat_ch_info);
cfg           = [];
cfg.method    = 'mtmfft';
% cfg.trial     =  'all';
cfg.taper     = 'dpss';
cfg.output    = 'fourier';
cfg.tapsmofrq = 1;

freq = ft_freqanalysis(cfg, check_struct_rest);

cfg           = [];
cfg.method    = 'coh';
coh           = ft_connectivityanalysis(cfg, freq);
conn_pre_def.coh = coh;

cfg           = [];
cfg.method    = 'plv';
plv           = ft_connectivityanalysis(cfg, freq);

conn_pre_def.plv = plv;

% post coop
check_struct_rest=struct_ft_format(reshape(plot_post_coop,size(plot_post_coop,1),[]),diff(time_re_epoch),srate,cat_ch_info);
cfg           = [];
cfg.method    = 'mtmfft';
% cfg.trial     =  'all';
cfg.taper     = 'dpss';
cfg.output    = 'fourier';
cfg.tapsmofrq = 1;

freq = ft_freqanalysis(cfg, check_struct_rest);

cfg           = [];
cfg.method    = 'coh';
coh           = ft_connectivityanalysis(cfg, freq);
conn_post_coop.coh = coh;

cfg           = [];
cfg.method    = 'plv';
plv           = ft_connectivityanalysis(cfg, freq);

conn_post_coop.plv = plv;

% post def
check_struct_rest=struct_ft_format(reshape(plot_post_def,size(plot_post_def,1),[]),diff(time_re_epoch),srate,cat_ch_info);
cfg           = [];
cfg.method    = 'mtmfft';
% cfg.trial     =  'all';
cfg.taper     = 'dpss';
cfg.output    = 'fourier';
cfg.tapsmofrq = 1;

freq = ft_freqanalysis(cfg, check_struct_rest);

cfg           = [];
cfg.method    = 'coh';
coh           = ft_connectivityanalysis(cfg, freq);
conn_post_def.coh = coh;

cfg           = [];
cfg.method    = 'plv';
plv           = ft_connectivityanalysis(cfg, freq);

conn_post_def.plv = plv;

f = freq.freq;

%%

% f
% conn_pre_coop
% conn_pre_def
% conn_post_coop
% conn_post_def

band_range = [1,4;4,8;8,12;12,30;30,50]; 

for band_idx =1 : size(band_range,1)
    band_list = find(f>=band_range(band_idx,1) &f<=band_range(band_idx,2));

    coh_val(band_idx).pre_coop = mean(conn_pre_coop.coh.cohspctrm(:,:,band_list),3);

    coh_val(band_idx).post_coop = mean(conn_post_coop.coh.cohspctrm(:,:,band_list),3);

    coh_val(band_idx).pre_def = mean(conn_pre_def.coh.cohspctrm(:,:,band_list),3);

    coh_val(band_idx).post_def = mean(conn_post_def.coh.cohspctrm(:,:,band_list),3);
end

figure, 
for band_idx =1 : 5
    coh_val(band_idx)
end

%%


cat_ch_info = ch_info;


% pre coop
check_struct_rest=struct_ft_format(reshape(plot_pre_coop,size(plot_pre_coop,1),[]),diff(time_re_epoch),srate,cat_ch_info);
cfg           = [];
cfg.method    = 'mtmfft';
% cfg.trial     =  'all';
cfg.taper     = 'dpss';
cfg.output    = 'fourier';
cfg.tapsmofrq = 1;

freq = ft_freqanalysis(cfg, check_struct_rest);
%%

data = temp_data;
ep_en = size(temp_data,2);
srate = srate;
ch_info = cat_ch_info;
% ep_vec = 
% ep_data ch time trial group subj
for group_idx =1
    for sub_idx =1
        temp_data = ep_data(:,:,:,group_idx,sub_idx);
        ft_data = struct_ft_format2(temp_data,ep_len,srate,cat_ch_info,ch_locs_path);

        cfg=[];
        cfg.toilim = [-1 0];
        cfg.trial = 40;
        datapre = ft_redefinetrial(cfg,ft_data);

        cfg.toilim = [0 2];
        cfg.trial = 40;
        datapst = ft_redefinetrial(cfg,ft_data);


        cfg              = [];
        cfg.output       = 'pow';
        cfg.method       = 'mtmconvol';
        cfg.taper        = 'hanning';
        cfg.foi          = 0:50;
        cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5;
        cfg.toi          = -1:.05:0;
        cfg.keeptrials ='yes';
        tfrpre= ft_freqanalysis(cfg,  datapre);

        cfg.foi          = 0:50;
        cfg.toi          = 0:.05:2;
        tfrpst= ft_freqanalysis(cfg,  datapst);

        tfrpre.time = tfrpst.time;
        tfrpre.freq = round(tfrpre.freq);
        tfrpst.freq = round(tfrpst.freq);

        cfg = [];
        cfg.channel          = {'eeg'};
        cfg.latency          = [0 1];
        cfg.method           = 'montecarlo';
        cfg.statistic        = 'ft_statfun_actvsblT';
        cfg.correctm         = 'cluster';
        cfg.clusteralpha     = 0.05;
        cfg.clusterstatistic = 'maxsum';
        cfg.minnbchan        = 2;
        cfg.tail             = 0;
        cfg.clustertail      = 0;
        cfg.alpha            = 0.05;
        cfg.numrandomization = 500;
        % prepare_neighbours determines what sensors may form clusters
        cfg_neighb.method    = 'distance';
        cfg.neighbours       = ft_prepare_neighbours(cfg_neighb, tfrpre);

        ntrials = size(tfrpst.powspctrm,1);
        design  = zeros(2,2*ntrials);
        design(1,1:ntrials) = 1;
        design(1,ntrials+1:2*ntrials) = 2;
        design(2,1:ntrials) = [1:ntrials];
        design(2,ntrials+1:2*ntrials) = [1:ntrials];

        cfg.design   = design;
        cfg.ivar     = 1;
        cfg.uvar     = 2;

        cfg.design           = design;
        cfg.ivar             = 1;

        [stat] = ft_freqstatistics(cfg, tfrpst, tfrpre);




    end
end

%%
