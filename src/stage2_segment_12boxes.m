function [success_tags] = stage2_segment_12boxes(trial_tags, out_paths, aux_data_dir, ratio_c)
% STAGE2_SEGMENT_12BOXES - Computes 12 Functional Anatomical Regions on the Foot
%
% Dynamically adapts to Foot Laterality (Left vs Right):
% - Left Foot:  Medial (Hallux, MT1, Mid Med, Heel Med) is on the RIGHT (larger X)
% - Right Foot: Medial (Hallux, MT1, Mid Med, Heel Med) is on the LEFT (smaller X)
%
% Inputs:
%   trial_tags   - Cell array of trial tags, e.g. {'R_t000_1', 'L_t000_1', 'R_kanan_kiri_1'}
%   out_paths    - Structure of paths from resolve_output_dir
%   aux_data_dir - Optional folder containing manual landmark files (anatomy_p, xy_cop_i100)
%   ratio_c      - Partition ratio for metatarsals (default: [30, 20, 20])

if nargin < 4 || isempty(ratio_c)
    ratio_c = [30, 20, 20];
end
if nargin < 3
    aux_data_dir = '';
end

ratio_cc = [ratio_c(1), ratio_c(1)+ratio_c(2), ratio_c(1)+ratio_c(2)+ratio_c(3)];
success_tags = {};

level_1 = 90; level_2 = 70; level_3 = 69; level_4 = 68;

box_color = [
    0.6   0.6   1.0;   % 1 Toe 1 (Hallux)
    0.0   0.7   0.0;   % 2 Toe 2
    1.0   0.5   0.0;   % 3 Toe 3
    1.0   1.0   0.0;   % 4 Toe 4-5
    1.0   0.0   0.0;   % 5 MT 1
    1.0   0.0   1.0;   % 6 MT 2
    0.5   0.5   0.5;   % 7 MT 3
    0.0   0.9   0.9;   % 8 MT 4-5
    0.5   0.0   0.0;   % 9 Mid med
    0.0   1.0   0.0;   % 10 Mid lat
    0.7   0.0   0.7;   % 11 Heel med
    0.0   0.0   0.9    % 12 Heel lat
];

text_list = [
    ' 1:Toe 1   ';
    ' 2:Toe 2   ';
    ' 3:Toe 3   ';
    ' 4:Toe 4-5 ';
    ' 5:MT 1    ';
    ' 6:MT 2    ';
    ' 7:MT 3    ';
    ' 8:MT 4-5  ';
    ' 9:Mid med ';
    '10:Mid lat ';
    '11:Heel med';
    '12:Heel lat'
];

for w = 1:length(trial_tags)
    tag = trial_tags{w};
    fprintf('   [Stage 2] Partitioning 12 boxes: %s ... ', tag);
    
    max_txt_path = fullfile(out_paths.stage1_level, sprintf('map_level_max_%s.txt', tag));
    if ~exist(max_txt_path, 'file')
        fprintf('SKIPPED (map_level_max not found)\n');
        continue;
    end
    map_level_max = load(max_txt_path);
    [n_len, n_wid] = size(map_level_max);
    
    % Try loading manual or curated landmark files if available
    anatomy_p = [];
    xy_cop_i100 = [];
    
    cand_anatomy = {
        fullfile(out_paths.stage2_xy, sprintf('anatomy_p_%s.txt', tag)), ...
        fullfile(out_paths.root, sprintf('anatomy_p_%s.txt', tag)), ...
        fullfile(aux_data_dir, sprintf('anatomy_p_%s.txt', tag))
    };
    for k = 1:length(cand_anatomy)
        if exist(cand_anatomy{k}, 'file')
            loaded_p = load(cand_anatomy{k});
            if ~isempty(loaded_p) && size(loaded_p, 1) >= 4
                anatomy_p = loaded_p;
                break;
            end
        end
    end
    
    cand_cop = {
        fullfile(aux_data_dir, sprintf('xy_cop_i100_3_%s.txt', tag)), ...
        fullfile(out_paths.stage2_xy, sprintf('xy_cop_i100_3_%s.txt', tag)), ...
        fullfile(out_paths.root, sprintf('xy_cop_i100_3_%s.txt', tag))
    };
    for k = 1:length(cand_cop)
        if exist(cand_cop{k}, 'file')
            loaded_c = load(cand_cop{k});
            if ~isempty(loaded_c)
                xy_cop_i100 = loaded_c;
                break;
            end
        end
    end
    
    % --- 1. Robust Anatomical Landmark Discovery with Laterality Detection ---
    if isempty(anatomy_p) || size(anatomy_p, 1) < 4
        rows_active = find(any(map_level_max > 0, 2));
        cols_active = find(any(map_level_max > 0, 1));
        
        if isempty(rows_active)
            rows_active = (round(n_len*0.1):round(n_len*0.9))';
            cols_active = (round(n_wid*0.2):round(n_wid*0.8))';
        end
        
        y_min = min(rows_active);
        y_max = max(rows_active);
        total_h = max(10, y_max - y_min + 1);
        
        % Compute active column bounds per row
        c_min_per_r = zeros(n_len, 1);
        c_max_per_r = zeros(n_len, 1);
        for r = y_min:y_max
            r_cols = find(map_level_max(r, :) > 0);
            if ~isempty(r_cols)
                c_min_per_r(r) = min(r_cols);
                c_max_per_r(r) = max(r_cols);
            else
                c_min_per_r(r) = min(cols_active);
                c_max_per_r(r) = max(cols_active);
            end
        end
        
        % Determine Foot Laterality (Strict Prefix Check: 'L_' vs 'R_')
        is_foot_right = false;
        if startsWith(tag, 'R_', 'IgnoreCase', true)
            is_foot_right = true;
        elseif startsWith(tag, 'L_', 'IgnoreCase', true)
            is_foot_right = false;
        elseif contains(tag, '_R_', 'IgnoreCase', true) || endsWith(tag, '_R', 'IgnoreCase', true)
            is_foot_right = true;
        elseif contains(tag, '_L_', 'IgnoreCase', true) || endsWith(tag, '_L', 'IgnoreCase', true)
            is_foot_right = false;
        else
            % Automatic morphological detection from Hallux peak
            forefoot_rows = max(1, round(y_min + 0.50 * total_h)):y_max;
            forefoot_patch = map_level_max(forefoot_rows, :);
            [~, max_lin_idx] = max(forefoot_patch(:));
            [~, peak_col] = ind2sub(size(forefoot_patch), max_lin_idx);
            mid_col = mean(cols_active);
            is_foot_right = (peak_col < mid_col);
        end
        
        % Heel zone (bottom 0% to 22%)
        heel_rows = y_min:min(y_max, round(y_min + 0.22 * total_h));
        y_heel_base = y_min;
        
        % Metatarsal zone: Distal MT line / Base of toes at 78% of foot height
        mt_rows = max(y_min, round(y_min + 0.55 * total_h)):min(y_max, round(y_min + 0.78 * total_h));
        y_mt_distal = round(y_min + 0.78 * total_h);
        
        if is_foot_right
            % Right Foot: Medial is on the LEFT (smaller X), Lateral on RIGHT (larger X)
            x_med_real = min(c_min_per_r(heel_rows));
            x_lat_real = max(c_max_per_r(heel_rows));
            
            x_med_for  = min(c_min_per_r(mt_rows));
            x_lat_for  = max(c_max_per_r(mt_rows));
        else
            % Left Foot:  Medial is on the RIGHT (larger X), Lateral on LEFT (smaller X)
            x_med_real = max(c_max_per_r(heel_rows));
            x_lat_real = min(c_min_per_r(heel_rows));
            
            x_med_for  = max(c_max_per_r(mt_rows));
            x_lat_for  = min(c_min_per_r(mt_rows));
        end
        
        x_heel_c = (x_med_real + x_lat_real) / 2;
        x_mt_c   = (x_med_for  + x_lat_for)  / 2;
        
        % Toe apex zone (78% to 100%)
        toe_rows = max(y_min, round(y_min + 0.78 * total_h)):y_max;
        t_weights = map_level_max(toe_rows, :);
        [t_r, t_c] = find(t_weights > 0);
        if ~isempty(t_c)
            t_w = zeros(size(t_c));
            for k = 1:length(t_c)
                t_w(k) = t_weights(t_r(k), t_c(k));
            end
            if sum(t_w) > 0
                x_toe_c = sum(t_c .* t_w) / sum(t_w);
            else
                x_toe_c = mean(t_c);
            end
        else
            x_toe_c = x_mt_c;
        end
        y_toe_top = y_max;
        
        % Standard Definition of anatomy_p:
        % Row 1: Medial Line  -> [x_med_real, x_med_for, y_med_real, y_med_for]
        % Row 2: Lateral Line -> [x_lat_real, x_lat_for, y_lat_real, y_lat_for]
        % Row 3: Foot Axis    -> [x_heel,     x_toe,     y_heel,     y_toe]
        % Row 4: MT Landmark  -> [x_mt,       y_mt,      ArchIndex,  ArchIndex]
        anatomy_p = [
            x_med_real, x_med_for, y_heel_base + 1, y_mt_distal;
            x_lat_real, x_lat_for, y_heel_base + 1, y_mt_distal;
            x_heel_c,   x_toe_c,   y_heel_base,     y_toe_top;
            x_mt_c,     y_mt_distal, 0.23,          0.23
        ];
    end
    
    % --- 2. Extract Real COP Trajectory from Stage 1 3D Roll-Off ---
    if isempty(xy_cop_i100)
        mat_path = fullfile(out_paths.stage1_level, sprintf('map_level_%s.mat', tag));
        if exist(mat_path, 'file')
            loaded_mat = load(mat_path);
            map_3d = loaded_mat.map_level;
            n_f = size(map_3d, 3);
            raw_cop = zeros(n_f, 2);
            [grid_c, grid_r] = meshgrid(1:size(map_3d, 2), 1:size(map_3d, 1));
            
            for f_i = 1:n_f
                f_mat = map_3d(:, :, f_i);
                sum_f = sum(f_mat(:));
                if sum_f > 0
                    raw_cop(f_i, 1) = sum(sum(f_mat .* grid_c)) / sum_f;
                    raw_cop(f_i, 2) = sum(sum(f_mat .* grid_r)) / sum_f;
                end
            end
            
            valid_cop = raw_cop(raw_cop(:, 1) > 0 & raw_cop(:, 2) > 0, :);
            if size(valid_cop, 1) >= 5
                x_in = linspace(0, 100, size(valid_cop, 1))';
                x_out = linspace(0, 100, 101)';
                xy_cop_i100 = interp1(x_in, valid_cop, x_out, 'linear');
            end
        end
    end
    
    if isempty(xy_cop_i100)
        xy_cop_i100 = [
            linspace(anatomy_p(3, 1), anatomy_p(3, 2), 101)', ...
            linspace(anatomy_p(3, 3), anatomy_p(3, 4), 101)'
        ];
    end
    
    % --- 3. Exact loop2 Geometric Foot Axis & Partitioning ---
    xy_lat_for  = [anatomy_p(2,2); anatomy_p(2,4)];
    xy_lat_real = [anatomy_p(2,1); anatomy_p(2,3)];
    xy_med_for  = [anatomy_p(1,2); anatomy_p(1,4)];
    xy_med_real = [anatomy_p(1,1); anatomy_p(1,3)];
    xy_toe      = [anatomy_p(3,2); anatomy_p(3,4)];
    xy_mt       = [anatomy_p(4,1); anatomy_p(4,2)];
    xy_heel     = [anatomy_p(3,1); anatomy_p(3,3)];
    
    x_a = [xy_med_real(1), xy_med_for(1)]; % Line A: Always Medial
    y_a = [xy_med_real(2), xy_med_for(2)];
    x_b = [xy_lat_real(1), xy_lat_for(1)]; % Line B: Always Lateral
    y_b = [xy_lat_real(2), xy_lat_for(2)];
    
    x_ct_p  = xy_toe(1);  y_ct_p  = xy_toe(2);
    x_cd1_p = xy_mt(1);   y_cd1_p = xy_mt(2);
    x_ch_p  = xy_heel(1); y_ch_p  = xy_heel(2);
    
    x_cm = [(x_a(1)+x_b(1))/2, (x_a(2)+x_b(2))/2];
    y_cm = [(y_a(1)+y_b(1))/2, (y_a(2)+y_b(2))/2];
    
    ploy_a  = polyfit(x_a, y_a, 1);
    ploy_b  = polyfit(x_b, y_b, 1);
    ploy_cm = polyfit(x_cm, y_cm, 1);
    
    % Longitudinal divisions between heel (cd3) and MT base (cd1)
    x_cd2_p = (x_ch_p - x_cd1_p)/3 + x_cd1_p;
    y_cd2_p = (y_ch_p - y_cd1_p)/3 + y_cd1_p;
    x_cd3_p = (x_ch_p - x_cd1_p)/3*2 + x_cd1_p;
    y_cd3_p = (y_ch_p - y_cd1_p)/3*2 + y_cd1_p;
    
    x_c = [x_ch_p, x_ct_p, x_cd3_p, x_cd2_p, x_cd1_p, x_cm(1), x_cm(2)];
    y_c = [y_ch_p, y_ct_p, y_cd3_p, y_cd2_p, y_cd1_p, y_cm(1), y_cm(2)];
    
    x_vc_a = zeros(1, length(x_c)); y_vc_a = zeros(1, length(x_c));
    x_vc_b = zeros(1, length(x_c)); y_vc_b = zeros(1, length(x_c));
    
    for i = 1:length(x_c)
        constant_vc = ploy_cm(1)*y_c(i) + x_c(i);
        ploy_vc = [-1/ploy_cm(1), constant_vc/ploy_cm(1)];
        
        function_vc_a = [-ploy_a(1), 1; -ploy_vc(1), 1];
        constant_vc_a = [ploy_a(2); ploy_vc(2)];
        if abs(det(function_vc_a)) > 1e-12
            vc_a = function_vc_a \ constant_vc_a;
        else
            vc_a = [x_a(1); y_c(i)];
        end
        
        function_vc_b = [-ploy_b(1), 1; -ploy_vc(1), 1];
        constant_vc_b = [ploy_b(2); ploy_vc(2)];
        if abs(det(function_vc_b)) > 1e-12
            vc_b = function_vc_b \ constant_vc_b;
        else
            vc_b = [x_b(1); y_c(i)];
        end
        
        x_vc_a(i) = vc_a(1); y_vc_a(i) = vc_a(2);
        x_vc_b(i) = vc_b(1); y_vc_b(i) = vc_b(2);
    end
    
    % Metatarsal transversal division (Level 4 to Level 5) from Medial to Lateral
    x_aa = [x_vc_a(4), x_vc_b(4)]; y_aa = [y_vc_a(4), y_vc_b(4)];
    x_bb = [x_vc_a(5), x_vc_b(5)]; y_bb = [y_vc_a(5), y_vc_b(5)];
    
    x_cc = zeros(1, length(ratio_cc));
    y_cc = zeros(1, length(ratio_cc));
    for i = 1:length(ratio_cc)
        x_cc(i) = (x_aa(2) - x_aa(1))/100*ratio_cc(i) + x_aa(1);
        y_cc(i) = (y_aa(2) - y_aa(1))/100*ratio_cc(i) + y_aa(1);
    end
    
    [x_dd, y_dd] = func_perpendical_point_to_line(x_aa, y_aa, x_bb, y_bb, x_cc, y_cc);
    x_cd2_d = x_cc; y_cd2_d = y_cc;
    x_cd3_d = x_dd; y_cd3_d = y_dd;
    
    % Toe transversal division (Level 5 to Level 2) from Medial to Lateral
    x_bb_toe = [x_vc_a(2), x_vc_b(2)]; y_bb_toe = [y_vc_a(2), y_vc_b(2)];
    [x_dd_toe, y_dd_toe] = func_perpendical_point_to_line(x_aa, y_aa, x_bb_toe, y_bb_toe, x_cc, y_cc);
    x_ct_d = x_dd_toe; y_ct_d = y_dd_toe;
    
    % --- 4. Construct 12 Boxes (Exact loop2 Definition: 1=Toe1..4=Toe4-5, 5=MT1..8=MT4-5) ---
    x_a_v = x_vc_a;   y_a_v = y_vc_a;
    x_b_v = x_vc_b;   y_b_v = y_vc_b;
    x_c_v = x_c;      y_c_v = y_c;
    x_t   = x_ct_d;   y_t   = y_ct_d;
    x_3   = x_cd3_d;  y_3   = y_cd3_d;
    x_2   = x_cd2_d;  y_2   = y_cd2_d;
    
    box = zeros(12, 8);
    box(1, :)  = [x_t(1),   y_t(1),   x_a_v(2), y_a_v(2), x_a_v(5), y_a_v(5), x_3(1),   y_3(1)  ];
    box(2, :)  = [x_t(2),   y_t(2),   x_t(1),   y_t(1),   x_3(1),   y_3(1),   x_3(2),   y_3(2)  ];
    box(3, :)  = [x_t(3),   y_t(3),   x_t(2),   y_t(2),   x_3(2),   y_3(2),   x_3(3),   y_3(3)  ];
    box(4, :)  = [x_b_v(5), y_b_v(5), x_t(3),   y_t(3),   x_3(3),   y_3(3),   x_b_v(7), y_b_v(7)];
    box(5, :)  = [x_3(1),   y_3(1),   x_a_v(5), y_a_v(5), x_a_v(4), y_a_v(4), x_2(1),   y_2(1)  ];
    box(6, :)  = [x_3(2),   y_3(2),   x_3(1),   y_3(1),   x_2(1),   y_2(1),   x_2(2),   y_2(2)  ];
    box(7, :)  = [x_3(3),   y_3(3),   x_3(2),   y_3(2),   x_2(2),   y_2(2),   x_2(3),   y_2(3)  ];
    box(8, :)  = [x_b_v(7), y_b_v(7), x_3(3),   y_3(3),   x_2(3),   y_2(3),   x_b_v(4), y_b_v(4)];
    box(9, :)  = [x_c_v(4), y_c_v(4), x_a_v(4), y_a_v(4), x_a_v(3), y_a_v(3), x_c_v(3), y_c_v(3)];
    box(10, :) = [x_b_v(4), y_b_v(4), x_c_v(4), y_c_v(4), x_c_v(3), y_c_v(3), x_b_v(3), y_b_v(3)];
    box(11, :) = [x_c_v(3), y_c_v(3), x_a_v(3), y_a_v(3), x_a_v(1), y_a_v(1), x_c_v(1), y_c_v(1)];
    box(12, :) = [x_b_v(3), y_b_v(3), x_c_v(3), y_c_v(3), x_c_v(1), y_c_v(1), x_b_v(1), y_b_v(1)];
    
    % Save box coordinates
    save(fullfile(out_paths.stage2_xy, sprintf('xy_box12_%s.txt', tag)), 'box', '-ascii');
    
    % --- 5. Render & Save Plot Exactly Matching loop2 / Sisipan 1 ---
    fig = figure('Visible', 'off');
    surf(map_level_max); hold on;
    
    % COP Trajectory
    x_copi = xy_cop_i100(:, 1); y_copi = xy_cop_i100(:, 2);
    cop_zi = x_copi(:, 1).*0 + level_1;
    plot3(x_copi, y_copi, cop_zi, 'w', 'linewidth', 3); hold on; grid on;
    plot3(x_copi, y_copi, cop_zi, 'r.-', 'linewidth', 1); hold on; grid on;
    
    % Medial & Lateral Boundary lines and levels
    z_vc = x_vc_a(1, :).*0 + level_3;
    plot3(x_a, y_a, [level_1, level_1], 'yo-', 'linewidth', 1); hold on;
    plot3(x_b, y_b, [level_1, level_1], 'yo-', 'linewidth', 1); hold on;
    plot3([x_a(1), x_b(1)], [y_a(1), y_b(1)], [level_1, level_1], 'y-o', 'linewidth', 1);
    plot3([x_a(2), x_b(2)], [y_a(2), y_b(2)], [level_1, level_1], 'y-o', 'linewidth', 1);
    plot3(x_cm(1), y_cm(1), [level_2, level_2], 'k^', 'linewidth', 2);
    plot3(x_cm(2), y_cm(2), [level_2, level_2], 'ksquare', 'linewidth', 2);
    plot3(x_vc_a, y_vc_a, z_vc, 'k-^', 'linewidth', 1); hold on;
    plot3(x_vc_b, y_vc_b, z_vc, 'k-^', 'linewidth', 1); hold on;
    plot3([x_ch_p, x_ct_p], [y_ch_p, y_ct_p], [level_4, level_4], 'k-o', 'linewidth', 2); hold on;
    
    for i = 1:length(x_vc_a)-1
        plot3([x_vc_a(i), x_vc_b(i)], [y_vc_a(i), y_vc_b(i)], [z_vc(i), z_vc(i)], 'c-^', 'linewidth', 2); hold on;
    end
    
    for i = 1:length(x_cc)
        plot3([x_cd2_d(i), x_ct_d(i)], [y_cd2_d(i), y_ct_d(i)], [z_vc(i), z_vc(i)], 'y-', 'linewidth', 3);
    end
    
    % Left side legend list (matching loop2)
    x_text = -10;
    y_text = 30;
    y_space = -2;
    box_level_1 = [box(1, 1:2:8), box(1, 1)]*0 + level_1;
    
    for i = 1:length(box(:, 1))
        text(x_text, y_text + i*y_space, text_list(i, :), 'BackgroundColor', box_color(i, :), 'fontsize', 8.5, 'FontWeight', 'bold');
        plot3([box(i, 1:2:8), box(i, 1)], [box(i, 2:2:8), box(i, 2)], box_level_1, 'c-', 'linewidth', 2); hold on;
        plot3([box(i, 1:2:8), box(i, 1)], [box(i, 2:2:8), box(i, 2)], box_level_1, 'k-', 'linewidth', 1); hold on;
    end
    
    view(0, 90); grid on; axis equal;
    
    % Box badges inside foot
    for i = 1:length(box(:, 1))
        center_x = (box(i, 1) + box(i, 3)) / 2;
        center_y = (box(i, 4) + box(i, 6)) / 2;
        text(center_x, center_y, level_1, text_list(i, 1:2), 'BackgroundColor', box_color(i, :), 'fontsize', 8, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end
    
    xlim([-14, n_wid + 4]);
    ylim([-2, n_len + 3]);
    
    title(sprintf('%s [%d] %d %d %d', strrep(tag, '_', '\_'), w, ratio_c(1), ratio_c(2), ratio_c(3)));
    saveas(fig, fullfile(out_paths.stage2_xy, sprintf('xy_box12_%s', tag)), 'jpg');
    close(fig);
    
    success_tags{end+1} = tag; %#ok<AGROW>
    fprintf('OK\n');
end

end
