function stage6_group_analysis(processed_subjects, out_paths, custom_groups)
% STAGE6_GROUP_ANALYSIS - Cohort Group Analysis by Arch Index & SPSS Export
%
% Inputs:
%   processed_subjects - Cell array of subject IDs (e.g. {'R_t000', 'R_t001', ...})
%   out_paths          - Structure of paths from resolve_output_dir
%   custom_groups      - Optional struct defining custom group lists

if isempty(processed_subjects)
    fprintf('   [Stage 6] Tidak ada subjek untuk analisis grup.\n');
    return;
end

fprintf('   [Stage 6] Running Cohort Group Analysis & SPSS formatting ... \n');

% Default Arch Index Classification cohorts
if nargin < 3 || isempty(custom_groups)
    groups = struct();
    groups.Higharch = {'R_t001', 'R_t012', 'R_t013', 'R_t019', 'R_t022', 'R_t050', 'R_t052', 'R_t053', 'R_t054', 'R_t055', 'R_t058'};
    groups.Normal   = {'R_t002', 'R_t003', 'R_t015', 'R_t016', 'R_t021', 'R_t026', 'R_t029', 'R_t032', 'R_t033', 'R_t040', 'R_t041', 'R_t046'};
    groups.Flatfoot = {'R_t004', 'R_t005', 'R_t020', 'R_t023', 'R_t024', 'R_t028', 'R_t031', 'R_t038', 'R_t063', 'R_t065', 'R_t068', 'R_t069', 'R_t070', 'R_t071', 'R_t072', 'R_t073', 'R_t074'};
else
    groups = custom_groups;
end

group_names = fieldnames(groups);

for g = 1:length(group_names)
    g_name = group_names{g};
    target_subs = groups.(g_name);
    
    % Match with available processed subjects
    matched_subs = intersect(processed_subjects, target_subs);
    if isempty(matched_subs)
        % If specific cohort matching is empty, fallback to using all available subjects for a general group
        if g == 1 && length(processed_subjects) < 5
            matched_subs = processed_subjects;
            g_name = 'All_Processed_Subjects';
        else
            continue;
        end
    end
    
    fprintf('      Cohort: %s (%d subjects) ... ', g_name, length(matched_subs));
    
    grp_f = []; grp_a = []; grp_p = []; grp_semp = [];
    g_count = 0;
    
    for s = 1:length(matched_subs)
        s_id = matched_subs{s};
        f_file = fullfile(out_paths.stage5_fap, sprintf('foot_fap_mean_fN_%s.txt', s_id));
        a_file = fullfile(out_paths.stage5_fap, sprintf('foot_fap_mean_area_%s.txt', s_id));
        p_file = fullfile(out_paths.stage5_fap, sprintf('foot_fap_mean_pressure_%s.txt', s_id));
        semp_file = fullfile(out_paths.stage5_timing, sprintf('box12_start_end_max_peak_%s.txt', s_id));
        
        if exist(f_file, 'file') && exist(a_file, 'file') && exist(p_file, 'file')
            g_count = g_count + 1;
            grp_f(:, :, g_count) = load(f_file);
            grp_a(:, :, g_count) = load(a_file);
            grp_p(:, :, g_count) = load(p_file);
            if exist(semp_file, 'file')
                grp_semp(:, :, g_count) = load(semp_file);
            end
        end
    end
    
    if g_count > 0
        mean_grp_f = mean(grp_f, 3);
        std_grp_f  = std(grp_f, 0, 3);
        
        % Reshape SPSS matrix: [start_1..12, end_1..12, max_x_1..12, peak_y_1..12]
        if ~isempty(grp_semp)
            spss_matrix = zeros(g_count, 48);
            for sub_i = 1:g_count
                sub_s = grp_semp(:, :, sub_i);
                spss_matrix(sub_i, :) = [sub_s(:, 1)', sub_s(:, 2)', sub_s(:, 3)', sub_s(:, 4)'];
            end
            save(fullfile(out_paths.stage6_group, sprintf('%s_box12_group_semp_spss.txt', g_name)), 'spss_matrix', '-ascii');
        end
        
        % Plot Group Figures
        fig = figure('Visible', 'off');
        for b = 1:12
            subplot(3, 4, b);
            plot(0:100, mean_grp_f(:, b), 'b-', 'linewidth', 1.5); hold on;
            plot(0:100, mean_grp_f(:, b) + std_grp_f(:, b), 'b:', 'linewidth', 0.5);
            plot(0:100, mean_grp_f(:, b) - std_grp_f(:, b), 'b:', 'linewidth', 0.5);
            title(sprintf('Box %d', b)); grid on;
        end
        saveas(fig, fullfile(out_paths.stage6_group, sprintf('%s_box_group', g_name)), 'jpg');
        close(fig);
        
        fprintf('OK (SPSS matrix & plots exported)\n');
    else
        fprintf('SKIPPED\n');
    end
end

end
