function plot_erp_cluster(ep_data, result, varargin)
% plot_erp_cluster  Visualize ERP cluster permutation test results
%
% Usage:
%   plot_erp_cluster(ep_data, result)                      % all channels
%   plot_erp_cluster(ep_data, result, 'channel', 'Cz')    % single ch by name
%   plot_erp_cluster(ep_data, result, 'channel', 3)        % single ch by index
%   plot_erp_cluster(ep_data, result, 'channel', 'all')    % all channels
%
% Required inputs:
%   ep_data  - {1x2} cell, each [n_ch x n_times x n_trials]
%   result   - struct returned by erp_cluster_perm()
%
% Optional name-value parameters:
%   'channel'  - channel name (string), index (number), or 'all' (default: 'all')
%   'amp_ylim' - ERP y-axis limits [µV]  (default: [-15 15])

% ---- Parse inputs ----
pr = inputParser;
addRequired(pr,  'ep_data');
addRequired(pr,  'result');
addParameter(pr, 'channel',  'all');
addParameter(pr, 'amp_ylim', [-15 15]);
parse(pr, ep_data, result, varargin{:});

ch_sel   = pr.Results.channel;
amp_ylim = pr.Results.amp_ylim;

% ---- Unpack result ----
time_vec    = result.time_vec;
t_obs       = result.t_obs;
sig_mask    = result.sig_mask;
t_crit_unc  = result.t_crit_unc;
t_crit_bonf = result.t_crit_bonf;
null_pos    = result.null_pos;
null_neg    = result.null_neg;
ch_labels   = result.ch_labels;
cond_labels = result.cond_labels;
n_perm      = result.n_perm;
alpha_thresh = result.alpha_thresh;
alpha_sig   = result.alpha_sig;

n_ch = size(ep_data{1}, 1);
erp1 = mean(ep_data{1}, 3);   % [n_ch x n_times]
erp2 = mean(ep_data{2}, 3);

unc_mask  = abs(t_obs) > t_crit_unc;
bonf_mask = abs(t_obs) > t_crit_bonf;

% ---- Resolve channel selection ----
if ischar(ch_sel) && strcmpi(ch_sel, 'all')
    ch_list = 1:n_ch;
elseif ischar(ch_sel)
    idx = find(strcmpi(ch_labels, ch_sel));
    if isempty(idx)
        error('plot_erp_cluster: channel "%s" not found in ch_labels.', ch_sel);
    end
    ch_list = idx;
else
    ch_list = ch_sel;   % numeric index
    if any(ch_list < 1) || any(ch_list > n_ch)
        error('plot_erp_cluster: channel index out of range [1, %d].', n_ch);
    end
end

% ---- Dispatch ----
if numel(ch_list) == 1
    plot_single(ch_list, erp1, erp2, t_obs, sig_mask, unc_mask, bonf_mask, ...
        time_vec, t_crit_unc, t_crit_bonf, null_pos, null_neg, ...
        ch_labels, cond_labels, amp_ylim, n_perm, alpha_thresh, alpha_sig);
else
    plot_all(ch_list, erp1, erp2, t_obs, sig_mask, unc_mask, bonf_mask, ...
        time_vec, t_crit_unc, t_crit_bonf, null_pos, null_neg, ...
        ch_labels, cond_labels, amp_ylim, n_perm, alpha_thresh, alpha_sig);
end

end % plot_erp_cluster

% ==========================================================================

function plot_single(ch, erp1, erp2, t_obs, sig_mask, unc_mask, bonf_mask, ...
        time_vec, t_crit_unc, t_crit_bonf, null_pos, null_neg, ...
        ch_labels, cond_labels, amp_ylim, n_perm, alpha_thresh, alpha_sig)

t_ch  = t_obs(ch, :);
t_max = max(max(abs(t_ch)) * 1.3, t_crit_bonf * 1.2);

fig = figure('Name', sprintf('Channel: %s', ch_labels{ch}), ...
             'Position', [200 100 680 780]);
tl  = tiledlayout(fig, 5, 1, 'TileSpacing','compact', 'Padding','compact');

% (a) ERP amplitude  [height 2]
ax_a = nexttile(1, [2 1]);
h1 = plot(time_vec, erp1(ch,:), 'k-',  'LineWidth',1.5); hold on;
h2 = plot(time_vec, erp2(ch,:), 'k--', 'LineWidth',1.5);
xline(0, 'Color',[0.6 0.6 0.6], 'LineWidth',0.8, 'HandleVisibility','off');
yline(0, 'Color',[0.6 0.6 0.6], 'LineWidth',0.8, 'HandleVisibility','off');
xlim([time_vec(1) time_vec(end)]);
ylim(amp_ylim);
ylabel('\muV', 'FontSize',9);
title(sprintf('(a)  %s', ch_labels{ch}), 'FontSize',10, 'FontWeight','bold');
legend([h1 h2], cond_labels, 'FontSize',8, 'Location','northeast');
set(ax_a, 'FontSize',8, 'XTickLabel',[], 'Box','off');

% (b) t-statistic  [height 2]
ax_t = nexttile(3, [2 1]);
s_on  = find(diff([0 unc_mask(ch,:)]) ==  1);
s_off = find(diff([unc_mask(ch,:) 0]) == -1);
for k = 1:numel(s_on)
    patch([time_vec(s_on(k)) time_vec(s_off(k)) time_vec(s_off(k)) time_vec(s_on(k))], ...
          [-t_max -t_max t_max t_max], [0.75 0.75 0.75], ...
          'FaceAlpha',0.55, 'EdgeColor','none');
    hold on;
end
plot(time_vec, t_ch, 'k', 'LineWidth',1.5);
yline( t_crit_unc,  'k:',  'LineWidth',1.2, 'HandleVisibility','off');
yline(-t_crit_unc,  'k:',  'LineWidth',1.2, 'HandleVisibility','off');
yline( t_crit_bonf, 'k--', 'LineWidth',1.2, 'HandleVisibility','off');
yline(-t_crit_bonf, 'k--', 'LineWidth',1.2, 'HandleVisibility','off');
xline(0, 'Color',[0.6 0.6 0.6], 'LineWidth',0.8, 'HandleVisibility','off');
yline(0, 'Color',[0.6 0.6 0.6], 'LineWidth',0.8, 'HandleVisibility','off');
xlim([time_vec(1) time_vec(end)]);
ylim([-t_max t_max]);
ylabel('t-statistic', 'FontSize',9);
title('(b)', 'FontSize',10, 'FontWeight','bold');
set(ax_t, 'FontSize',8, 'XTickLabel',[], 'Box','off');

legend('off');

% (c) Significance bars  [height 1]
ax_b = nexttile(5, [1 1]);
hold on;
methods   = {unc_mask(ch,:), bonf_mask(ch,:), sig_mask(ch,:)};
bar_names = {'uncorrected', 'Bonferroni-corrected', 'cluster-based'};
bar_clr   = {[0.65 0.65 0.65], [0.35 0.35 0.35], [0.05 0.05 0.05]};
y_pos     = [3, 2, 1];

for m = 1:3
    plot([time_vec(1) time_vec(end)], [y_pos(m) y_pos(m)], ...
         '-', 'Color',[0.85 0.85 0.85], 'LineWidth',6);
    m_on  = find(diff([0 methods{m}]) ==  1);
    m_off = find(diff([methods{m} 0]) == -1);
    for k = 1:numel(m_on)
        patch([time_vec(m_on(k)) time_vec(m_off(k)) time_vec(m_off(k)) time_vec(m_on(k))], ...
              [y_pos(m)-0.38 y_pos(m)-0.38 y_pos(m)+0.38 y_pos(m)+0.38], ...
              bar_clr{m}, 'EdgeColor','none');
    end
end
xline(0, 'Color',[0.6 0.6 0.6], 'LineWidth',0.8);
xlim([time_vec(1) time_vec(end)]);
ylim([0.5 3.5]);
yticks(sort(y_pos)); yticklabels(fliplr(bar_names));
xlabel('Time (s)', 'FontSize',9);
title('(c)', 'FontSize',10, 'FontWeight','bold');
set(ax_b, 'FontSize',8, 'Box','off');

sgtitle(fig, sprintf('n_{perm}=%d  |  \\alpha_{thresh}=%.2f  |  \\alpha_{sig}=%.2f', ...
    n_perm, alpha_thresh, alpha_sig), 'FontSize',10);
end

% ==========================================================================

function plot_all(ch_list, erp1, erp2, t_obs, sig_mask, unc_mask, bonf_mask, ...
        time_vec, t_crit_unc, t_crit_bonf, null_pos, null_neg, ...
        ch_labels, cond_labels, amp_ylim, n_perm, alpha_thresh, alpha_sig)

n_ch   = numel(ch_list);
n_cols = ceil(sqrt(n_ch));
n_rows = ceil(n_ch / n_cols);

% ---- Figure 1: Per-channel ERP + t-stat + significance bars ----
fig1 = figure('Name','Per-channel ERP & t-stat', 'Position',[0 0 1920 1080]);
tl   = tiledlayout(fig1, 3*n_rows, n_cols, 'TileSpacing','compact', 'Padding','compact');

for i = 1:n_ch
    ch  = ch_list(i);
    r   = floor((i-1) / n_cols);
    col = mod(i-1, n_cols);
    amp_idx = r * 3 * n_cols + col + 1;
    tst_idx = amp_idx + n_cols;
    bar_idx = tst_idx + n_cols;

    t_ch  = t_obs(ch, :);
    t_max = max(max(abs(t_ch)) * 1.3, t_crit_bonf * 1.2);

    % (a) ERP
    ax_a = nexttile(amp_idx);
    h1 = plot(time_vec, erp1(ch,:), 'k-',  'LineWidth',1.2); hold on;
    h2 = plot(time_vec, erp2(ch,:), 'k--', 'LineWidth',1.2);
    xline(0, 'Color',[0.6 0.6 0.6], 'LineWidth',0.6, 'HandleVisibility','off');
    yline(0, 'Color',[0.6 0.6 0.6], 'LineWidth',0.6, 'HandleVisibility','off');
    xlim([time_vec(1) time_vec(end)]);
    ylim(amp_ylim);
    ylabel('\muV', 'FontSize',6);
    title(ch_labels{ch}, 'FontSize',8, 'FontWeight','bold');
    set(ax_a, 'FontSize',7, 'XTickLabel',[], 'Box','off');
    if i == 1
        legend([h1 h2], cond_labels, 'FontSize',6, 'Location','northeast');
    end

    % (b) t-statistic
    ax_t = nexttile(tst_idx);
    s_on  = find(diff([0 unc_mask(ch,:)]) ==  1);
    s_off = find(diff([unc_mask(ch,:) 0]) == -1);
    for k = 1:numel(s_on)
        patch([time_vec(s_on(k)) time_vec(s_off(k)) time_vec(s_off(k)) time_vec(s_on(k))], ...
              [-t_max -t_max t_max t_max], [0.75 0.75 0.75], ...
              'FaceAlpha',0.55, 'EdgeColor','none');
        hold on;
    end
    plot(time_vec, t_ch, 'k', 'LineWidth',1.2);
    yline( t_crit_unc,  'k:',  'LineWidth',1.0, 'HandleVisibility','off');
    yline(-t_crit_unc,  'k:',  'LineWidth',1.0, 'HandleVisibility','off');
    yline( t_crit_bonf, 'k--', 'LineWidth',1.0, 'HandleVisibility','off');
    yline(-t_crit_bonf, 'k--', 'LineWidth',1.0, 'HandleVisibility','off');
    xline(0, 'Color',[0.6 0.6 0.6], 'LineWidth',0.6, 'HandleVisibility','off');
    yline(0, 'Color',[0.6 0.6 0.6], 'LineWidth',0.6, 'HandleVisibility','off');
    xlim([time_vec(1) time_vec(end)]);
    ylim([-t_max t_max]);
    ylabel('t-statistic', 'FontSize',6);
    set(ax_t, 'FontSize',7, 'XTickLabel',[], 'Box','off');

    % (c) Significance bars
    ax_b = nexttile(bar_idx);
    hold on;
    methods   = {unc_mask(ch,:), bonf_mask(ch,:), sig_mask(ch,:)};
    bar_names = {'uncorrected', 'Bonferroni-corrected', 'cluster-based'};
    bar_clr   = {[0.65 0.65 0.65], [0.35 0.35 0.35], [0.05 0.05 0.05]};
    y_pos     = [3, 2, 1];
    for m = 1:3
        plot([time_vec(1) time_vec(end)], [y_pos(m) y_pos(m)], ...
             '-', 'Color',[0.85 0.85 0.85], 'LineWidth',5);
        m_on  = find(diff([0 methods{m}]) ==  1);
        m_off = find(diff([methods{m} 0]) == -1);
        for k = 1:numel(m_on)
            patch([time_vec(m_on(k)) time_vec(m_off(k)) time_vec(m_off(k)) time_vec(m_on(k))], ...
                  [y_pos(m)-0.35 y_pos(m)-0.35 y_pos(m)+0.35 y_pos(m)+0.35], ...
                  bar_clr{m}, 'EdgeColor','none');
        end
    end
    xline(0, 'Color',[0.6 0.6 0.6], 'LineWidth',0.6);
    xlim([time_vec(1) time_vec(end)]);
    ylim([0.5 3.5]);
    yticks(sort(y_pos)); yticklabels(fliplr(bar_names));
    xlabel('Time (s)', 'FontSize',7);
    set(ax_b, 'FontSize',6, 'Box','off');
end

% sgtitle(fig1, ...
%     sprintf('ERP & t-stat  |  dotted=uncorr (t_{crit}=%.2f)  |  dashed=Bonf (t_{crit}=%.2f)', ...
%     t_crit_unc, t_crit_bonf), 'FontSize',10);

% ---- Figure 2: t-map + null distributions ----
t_lim   = max(abs(t_obs(:)));
all_chs = 1:size(t_obs, 1);

figure('Name',' Null dist.', 'Position',[50 50 1000 480]);

% ax2 = subplot(1,2,1);
% imagesc(time_vec, all_chs, t_obs, [-t_lim t_lim]);
% set(ax2, 'YDir','normal');
% hold on;
% if any(sig_mask(:))
%     contour(time_vec, all_chs, double(sig_mask), [0.5 0.5], 'k', 'LineWidth',2);
% end
% colormap(ax2, bwr_cmap(256));
% cb = colorbar; ylabel(cb, 't-statistic');
% xline(0, 'w--', 'LineWidth',1);
% xlabel('Time (s)'); ylabel('Channel');
% yticks(all_chs); yticklabels(ch_labels(all_chs));
% title('t-statistic map  (black = sig. cluster)');

ax3 = subplot(1,2,[1,2]);
histogram(null_pos, 30, 'FaceColor',[0.2 0.4 0.8], 'FaceAlpha',0.6, 'EdgeColor','none'); hold on;
histogram(null_neg, 30, 'FaceColor',[0.8 0.2 0.2], 'FaceAlpha',0.6, 'EdgeColor','none');
xline(prctile(null_pos, 95), 'b--', 'LineWidth',1.5);
xline(prctile(null_neg,  5), 'r--', 'LineWidth',1.5);
xlabel('Max cluster statistic'); ylabel('Count');
title('Null distributions');
legend({'Positive','Negative'}, 'Location','best');
grid on; box off;

sgtitle(sprintf('Cluster-based Permutation Test  |  n_{perm}=%d  |  \\alpha_{thresh}=%.2f  |  \\alpha_{sig}=%.2f', ...
    n_perm, alpha_thresh, alpha_sig));
end

% ==========================================================================

function cmap = bwr_cmap(n)
% Blue-White-Red diverging colormap
    if nargin < 1, n = 256; end
    h = floor(n/2);
    r = [linspace(0,1,h), ones(1,n-h)];
    g = [linspace(0,1,h), linspace(1,0,n-h)];
    b = [ones(1,h),        linspace(1,0,n-h)];
    cmap = [r(:), g(:), b(:)];
end
