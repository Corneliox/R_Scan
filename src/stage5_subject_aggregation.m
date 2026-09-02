function [success_subjects] = stage5_subject_aggregation(subjects_info, out_paths, bodyweight_kg)
% STAGE5_SUBJECT_AGGREGATION - Averages N Trials per Subject (Mean & SD)
%
% Inputs:
%   subjects_info - Array of subject structures from scan_subject_trials
%   out_paths     - Structure of paths from resolve_output_dir
%   bodyweight_kg - Subject bodyweight in kg (default: 70 kg)

if nargin < 3 || isempty(bodyweight_kg)
    bodyweight_kg = 70;
end
success_subjects = {};

for s = 1:length(subjects_info)
    subj = subjects_info(s);
    subj_id = subj.id;
    
    fprintf('   [Stage 5] Aggregating trials for subject: %s ... ', subj_id);
    
    valid_f = []; valid_a = []; valid_p = []; valid_semp = [];
    v_count = 0;
    
    for t_idx = 1:length(subj.trial_tags)
        tag = subj.trial_tags{t_idx};
        
        fap_file = fullfile(out_paths.stage3_fap, sprintf('box12_data_101_f12_p12_m1_s1_%s.txt', tag));
        area_file = fullfile(out_paths.stage4_timing, sprintf('data_area_%s.txt', tag));
        pres_file = fullfile(out_paths.stage4_timing, sprintf('data_pressure_%s.txt', tag));
        semp_file = fullfile(out_paths.stage4_timing, sprintf('step_start_end_max_peak_%s.txt', tag));
        
        if exist(fap_file, 'file') && exist(area_file, 'file') && exist(pres_file, 'file')
            v_count = v_count + 1;
            d_fap = load(fap_file);
            valid_f(:, :, v_count) = d_fap(:, 1:12);
            valid_a(:, :, v_count) = load(area_file);
            valid_p(:, :, v_count) = load(pres_file);
            if exist(semp_file, 'file')
                valid_semp(:, :, v_count) = load(semp_file);
            end
        end
    end
    
    if v_count == 0
        fprintf('SKIPPED (No valid trials)\n');
        continue;
    end
    
    mean_data_f = mean(valid_f, 3);
    std_data_f  = std(valid_f, 0, 3);
    mean_data_a = mean(valid_a, 3);
    std_data_a  = std(valid_a, 0, 3);
    mean_data_p = mean(valid_p, 3);
    std_data_p  = std(valid_p, 0, 3);
    
    if ~isempty(valid_semp)
        mean_semp = mean(valid_semp, 3);
    else
        mean_semp = zeros(12, 4);
    end
    
    data_101_mean_sum = sum(mean_data_f, 1);
    
    % Save Aggregated Outputs
    save(fullfile(out_paths.stage5_fap, sprintf('foot_fap_mean_fN_%s.txt', subj_id)), 'mean_data_f', '-ascii');
    save(fullfile(out_paths.stage5_fap, sprintf('foot_fap_std_fN_%s.txt', subj_id)), 'std_data_f', '-ascii');
    save(fullfile(out_paths.stage5_fap, sprintf('foot_fap_mean_area_%s.txt', subj_id)), 'mean_data_a', '-ascii');
    save(fullfile(out_paths.stage5_fap, sprintf('foot_fap_std_area_%s.txt', subj_id)), 'std_data_a', '-ascii');
    save(fullfile(out_paths.stage5_fap, sprintf('foot_fap_mean_pressure_%s.txt', subj_id)), 'mean_data_p', '-ascii');
    save(fullfile(out_paths.stage5_fap, sprintf('foot_fap_std_pressure_%s.txt', subj_id)), 'std_data_p', '-ascii');
    
    save(fullfile(out_paths.stage5_timing, sprintf('box12_start_end_max_peak_%s.txt', subj_id)), 'mean_semp', '-ascii');
    save(fullfile(out_paths.stage5_timing, sprintf('box12_data_101_mean_sum_%s.txt', subj_id)), 'data_101_mean_sum', '-ascii');
    
    % Render & Save Multi-Plot Figure
    fig = figure('Visible', 'off');
    subplot(3, 1, 1);
    plot(0:100, mean_data_f, 'linewidth', 1.5);
    ylabel('Force (N)'); grid on;
    title(sprintf('Subject %s (%d Trials Mean \\pm SD)', strrep(subj_id, '_', '\_'), v_count));
    
    subplot(3, 1, 2);
    plot(0:100, mean_data_a, 'linewidth', 1.5);
    ylabel('Area (cm^2)'); grid on;
    
    subplot(3, 1, 3);
    plot(0:100, mean_data_p, 'linewidth', 1.5);
    xlabel('% Stance Phase'); ylabel('Pressure (N/cm^2)'); grid on;
    
    saveas(fig, fullfile(out_paths.stage5_fap, sprintf('foot_fap_%s', subj_id)), 'jpg');
    close(fig);
    
    success_subjects{end+1} = subj_id; %#ok<AGROW>
    fprintf('OK (%d trials averaged)\n', v_count);
end

end
