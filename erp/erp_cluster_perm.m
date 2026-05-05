function result = erp_cluster_perm(ep_data, time_vec, varargin)
% erp_cluster_perm  Cluster-based permutation test for two-condition ERP data
%   Maris & Oostenveld (2007), J. Neurosci. Methods 164(1):177-190
%
% Usage:
%   result = erp_cluster_perm(ep_data, time_vec)
%   result = erp_cluster_perm(ep_data, time_vec, 'Name', Value, ...)
%
% Required inputs:
%   ep_data    - {1x2} cell, each [n_ch x n_times x n_trials]
%   time_vec   - [1 x n_times] time axis in seconds
%
% Optional name-value parameters:
%   'n_perm'       - permutation count            (default: 1000)
%   'alpha_thresh' - cluster-forming threshold    (default: 0.1)
%   'alpha_sig'    - cluster significance level   (default: 0.1)
%   'ch_labels'    - {1 x n_ch} channel labels   (default: 'Ch1','Ch2',...)
%   'cond_labels'  - {1x2} condition label strings(default: {'Cond 1','Cond 2'})
%
% Output struct fields:
%   .sig_mask    [n_ch x n_times]  cluster-based significance mask
%   .t_obs       [n_ch x n_times]  observed t-statistic map
%   .null_pos    [n_perm x 1]      positive permutation null distribution
%   .null_neg    [n_perm x 1]      negative permutation null distribution
%   .t_crit_unc  scalar            uncorrected critical t-value  (alpha=0.05)
%   .t_crit_bonf scalar            Bonferroni-corrected critical t-value
%   .time_vec    [1 x n_times]     time axis
%   .ch_labels   {1 x n_ch}        channel labels
%   .cond_labels {1x2}             condition labels
%   .n_perm      scalar            permutation count used
%   .alpha_thresh scalar           cluster-forming threshold used
%   .alpha_sig   scalar            cluster significance level used

% ---- Parse inputs ----
pr = inputParser;
addRequired(pr,  'ep_data');
addRequired(pr,  'time_vec');
addParameter(pr, 'n_perm',       1000);
addParameter(pr, 'alpha_thresh', 0.1);
addParameter(pr, 'alpha_sig',    0.1);
addParameter(pr, 'ch_labels',    {});
addParameter(pr, 'cond_labels',  {'Cond 1', 'Cond 2'});
parse(pr, ep_data, time_vec, varargin{:});

n_perm       = pr.Results.n_perm;
alpha_thresh = pr.Results.alpha_thresh;
alpha_sig    = pr.Results.alpha_sig;
ch_labels    = pr.Results.ch_labels;
cond_labels  = pr.Results.cond_labels;

n_ch    = size(ep_data{1}, 1);
n_times = size(ep_data{1}, 2);
n1      = size(ep_data{1}, 3);
n2      = size(ep_data{2}, 3);

if isempty(ch_labels)
    ch_labels = arrayfun(@(i) sprintf('Ch%d',i), 1:n_ch, 'UniformOutput',false);
end

% ---- Step 1: Observed t-statistic map ----
t_thresh   = tinv(1 - alpha_thresh/2, n1 + n2 - 2);
all_trials = cat(3, ep_data{1}, ep_data{2});
t_obs      = tstat2(ep_data{1}, ep_data{2});

% ---- Step 2: Observed cluster statistics ----
[obs_ps, obs_ns, obs_pl, obs_nl] = get_clusters(t_obs, t_thresh);

% ---- Step 3: Permutation null distribution ----
null_pos = zeros(n_perm, 1);
null_neg = zeros(n_perm, 1);

fprintf('Permuting (%d iterations): ', n_perm);
rng('shuffle');
for p = 1:n_perm
    if mod(p, 200) == 0, fprintf('%d ', p); end
    idx = randperm(n1 + n2);
    t_p = tstat2(all_trials(:,:,idx(1:n1)), all_trials(:,:,idx(n1+1:end)));
    [ps, ns, ~, ~] = get_clusters(t_p, t_thresh);
    if ~isempty(ps), null_pos(p) = max(ps); end
    if ~isempty(ns), null_neg(p) = min(ns); end
end
fprintf('Done.\n\n');

% ---- Step 4: Identify significant clusters ----
sig_mask  = false(n_ch, n_times);
found_any = false;

fprintf('===== Cluster-based Permutation Test =====\n');
fprintf('%s (n=%d) vs %s (n=%d) | Permutations: %d\n\n', ...
    cond_labels{1}, n1, cond_labels{2}, n2, n_perm);

for c = 1:numel(obs_ps)
    pv = mean(null_pos >= obs_ps(c));
    if pv < alpha_sig
        mask_c = obs_pl == c;
        sig_mask(mask_c) = true;
        t_range = time_vec(any(mask_c, 1));
        fprintf('[+] Cluster %d | stat = %8.2f | p = %.4f | time = [%+.3f, %+.3f] s\n', ...
            c, obs_ps(c), pv, min(t_range), max(t_range));
        found_any = true;
    end
end

for c = 1:numel(obs_ns)
    pv = mean(null_neg <= obs_ns(c));
    if pv < alpha_sig
        mask_c = obs_nl == c;
        sig_mask(mask_c) = true;
        t_range = time_vec(any(mask_c, 1));
        fprintf('[-] Cluster %d | stat = %8.2f | p = %.4f | time = [%+.3f, %+.3f] s\n', ...
            c, obs_ns(c), pv, min(t_range), max(t_range));
        found_any = true;
    end
end

if ~found_any
    fprintf('No significant clusters found (alpha = %.2f).\n', alpha_sig);
end
fprintf('==========================================\n\n');

% ---- Build result struct ----
df           = n1 + n2 - 2;
t_crit_unc   = tinv(1 - 0.05/2, df);
t_crit_bonf  = tinv(1 - 0.05/(2*n_ch*n_times), df);

result.sig_mask    = sig_mask;
result.t_obs       = t_obs;
result.null_pos    = null_pos;
result.null_neg    = null_neg;
result.t_crit_unc  = t_crit_unc;
result.t_crit_bonf = t_crit_bonf;
result.time_vec    = time_vec;
result.ch_labels   = ch_labels;
result.cond_labels = cond_labels;
result.n_perm      = n_perm;
result.alpha_thresh = alpha_thresh;
result.alpha_sig   = alpha_sig;

end % erp_cluster_perm

% ========== Local functions ==========

function t = tstat2(d1, d2)
% Welch two-sample t-statistic map: [n_ch x n_times]
    n1 = size(d1,3);  n2 = size(d2,3);
    m1 = mean(d1,3);  m2 = mean(d2,3);
    s1 = var(d1,0,3); s2 = var(d2,0,3);
    t  = (m1 - m2) ./ (sqrt(s1/n1 + s2/n2) + eps);
end

function [pos_stats, neg_stats, pos_lbl, neg_lbl] = get_clusters(t_map, thresh)
% 2D connected-component clusters in channel x time t-map (4-connectivity)
    [pos_lbl, np] = bwlabel(t_map >  thresh, 4);
    [neg_lbl, nn] = bwlabel(t_map < -thresh, 4);
    pos_stats = arrayfun(@(c) sum(t_map(pos_lbl == c)), 1:np);
    neg_stats = arrayfun(@(c) sum(t_map(neg_lbl == c)), 1:nn);
end
