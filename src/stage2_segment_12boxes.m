function [success_tags] = stage2_segment_12boxes(trial_tags, out_paths, aux_data_dir, ratio_c)
% STAGE2_SEGMENT_12BOXES - Computes 12 Functional Anatomical Regions on the Foot
%
% Inputs:
%   trial_tags   - Cell array of trial tags, e.g. {'R_t000_1', 't001_1'}
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

level_1 = 90;

box_color = [
    0.6  0.6  1.0;   % 1 Toe 1 (Hallux)
    0.0  0.7  0.0;   % 2 Toe 2
    1.0  0.5  0.0;   % 3 Toe 3
    1.0  1.0  0.0;   % 4 Toe 4-5
    1.0  0.0  0.0;   % 5 MT 1
    1.0  0.0  1.0;   % 6 MT 2
    0.5  0.5  0.5;   % 7 MT 3
    0.0  0.9  0.9;   % 8 MT 4-5
    0.5  0.0  0.0;   % 9 Mid Med
    0.0  1.0  0.0;   % 10 Mid Lat
    0.7  0.0  0.7;   % 11 Heel Med
    0.0  0.0  0.9    % 12 Heel Lat
];

for w = 1:length(trial_tags)
    tag = trial_tags{w};
    fprintf('   [Stage 2] Partitioning 12 boxes: %s ... ', tag);
    
    max_txt_path = fullfile(out_paths.stage1_level, sprintf('map_level_max_%s.txt', tag));
    if ~exist(max_txt_path, 'file')
        fprintf('SKIPPED (map_level_max tidak ditemukan)\n');
        continue;
    end
    map_level_max = load(max_txt_path);
    [n_len, n_wid] = size(map_level_max);
    
    % Try loading manual landmark files if provided
    anatomy_p = [];
    xy_cop_i100 = [];
    
    if ~isempty(aux_data_dir)
        cand_anatomy = fullfile(aux_data_dir, sprintf('anatomy_p_%s.txt', tag));
        if exist(cand_anatomy, 'file'), anatomy_p = load(cand_anatomy); end
        
        cand_cop = fullfile(aux_data_dir, sprintf('xy_cop_i100_3_%s.txt', tag));
        if exist(cand_cop, 'file'), xy_cop_i100 = load(cand_cop); end
    end
    
    % --- 1. Robust Automated Anatomical Landmark Discovery ---
    if isempty(anatomy_p) || size(anatomy_p, 1) < 4
        [rows, cols] = find(map_level_max > 0);
        if isempty(rows)
            rows = [round(n_len*0.1); round(n_len*0.9)];
            cols = [round(n_wid*0.2); round(n_wid*0.8)];
        end
        
        y_min = min(rows); y_max = max(rows);
        foot_h = max(10, y_max - y_min + 1);
        
        % Zone 1: Heel Region (0% to 25% foot length from bottom)
        heel_mask = (rows >= y_min) & (rows <= y_min + 0.25 * foot_h);
        if any(heel_mask)
            h_rows = rows(heel_mask);
            h_cols = cols(heel_mask);
            h_weights = zeros(size(h_rows));
            for k = 1:length(h_rows)
                h_weights(k) = map_level_max(h_rows(k), h_cols(k));
            end
            sum_hw = sum(h_weights);
            if sum_hw > 0
                x_heel_c = sum(h_cols .* h_weights) / sum_hw;
                y_heel_c = sum(h_rows .* h_weights) / sum_hw;
            else
                x_heel_c = mean(h_cols); y_heel_c = mean(h_rows);
            end
            x_lat_real = max(1, min(h_cols) - 1);       % Lateral is on Left (smaller X)
            x_med_real = min(n_wid, max(h_cols) + 1);   % Medial is on Right (larger X)
        else
            x_heel_c = mean(cols); y_heel_c = y_min + 0.1 * foot_h;
            x_lat_real = max(1, min(cols)); x_med_real = min(n_wid, max(cols));
        end
        y_heel_base = max(1, y_min - 1);
        
        % Zone 2: Metatarsal / Forefoot Region (55% to 75% foot length)
        mt_mask = (rows >= y_min + 0.55 * foot_h) & (rows <= y_min + 0.78 * foot_h);
        if any(mt_mask)
            mt_rows = rows(mt_mask);
            mt_cols = cols(mt_mask);
            mt_weights = zeros(size(mt_rows));
            for k = 1:length(mt_rows)
                mt_weights(k) = map_level_max(mt_rows(k), mt_cols(k));
            end
            sum_mw = sum(mt_weights);
            if sum_mw > 0
                x_mt_c = sum(mt_cols .* mt_weights) / sum_mw;
                y_mt_c = sum(mt_rows .* mt_weights) / sum_mw;
            else
                x_mt_c = mean(mt_cols); y_mt_c = mean(mt_rows);
            end
            x_lat_for = max(1, min(mt_cols) - 2);       % MT 4-5 (Lateral, Left)
            x_med_for = min(n_wid, max(mt_cols) + 2);   % MT 1 (Medial, Right)
        else
            x_mt_c = mean(cols); y_mt_c = y_min + 0.65 * foot_h;
            x_lat_for = max(1, min(cols) - 1); x_med_for = min(n_wid, max(cols) + 1);
        end
        
        % Zone 3: Toe Apex Region (78% to 100% foot length)
        toe_mask = (rows >= y_min + 0.78 * foot_h);
        if any(toe_mask)
            t_rows = rows(toe_mask);
            t_cols = cols(toe_mask);
            t_weights = zeros(size(t_rows));
            for k = 1:length(t_rows)
                t_weights(k) = map_level_max(t_rows(k), t_cols(k));
            end
            sum_tw = sum(t_weights);
            if sum_tw > 0
                x_toe_c = sum(t_cols .* t_weights) / sum_tw;
            else
                x_toe_c = mean(t_cols);
            end
        else
            x_toe_c = x_mt_c;
        end
        y_toe_top = min(n_len, y_max + 1);
        
        % Standard Definition of anatomy_p:
        % Row 1: Medial Line  -> [x_med_real, x_med_for, y_med_real, y_med_for]
        % Row 2: Lateral Line -> [x_lat_real, x_lat_for, y_lat_real, y_lat_for]
        % Row 3: Foot Axis    -> [x_heel,     x_toe,     y_heel,     y_toe]
        % Row 4: MT Landmark  -> [x_mt,       y_mt,      ArchIndex,  ArchIndex]
        anatomy_p = [
            x_med_real, x_med_for, y_heel_base, y_mt_c;
            x_lat_real, x_lat_for, y_heel_base, y_mt_c;
            x_heel_c,   x_toe_c,   y_heel_base, y_toe_top;
            x_mt_c,     y_mt_c,    0.23,        0.23
        ];
    end
    
    % --- 2. Extract Real COP Trajectory from 3D Roll-Off ---
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
    
    % --- 3. Geometric Longitudinal Foot Partitioning ---
    xy_lat_for  = [anatomy_p(2,2); anatomy_p(2,4)];
    xy_lat_real = [anatomy_p(2,1); anatomy_p(2,3)];
    xy_med_for  = [anatomy_p(1,2); anatomy_p(1,4)];
    xy_med_real = [anatomy_p(1,1); anatomy_p(1,3)];
    xy_toe      = [anatomy_p(3,2); anatomy_p(3,4)];
    xy_mt       = [anatomy_p(4,1); anatomy_p(4,2)];
    xy_heel     = [anatomy_p(3,1); anatomy_p(3,3)];
    
    x_a = [xy_med_real(1), xy_med_for(1)];
    y_a = [xy_med_real(2), xy_med_for(2)];
    x_b = [xy_lat_real(1), xy_lat_for(1)];
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
    
    % Metatarsal transversal division (Level 4 to Level 5)
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
    
    % Toe transversal division (Level 5 to Level 2)
    x_bb_toe = [x_vc_a(2), x_vc_b(2)]; y_bb_toe = [y_vc_a(2), y_vc_b(2)];
    [x_dd_toe, y_dd_toe] = func_perpendical_point_to_line(x_aa, y_aa, x_bb_toe, y_bb_toe, x_cc, y_cc);
    x_ct_d = x_dd_toe; y_ct_d = y_dd_toe;
    
    % --- 4. Construct 12 Boxes ---
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
    
    % --- 5. Render & Save Plot (Matching Sisipan 1 Style) ---
    fig = figure('Visible', 'off');
    surf(map_level_max); hold on;
    
    % Real COP Trajectory (Red line with white highlight)
    x_copi = xy_cop_i100(:, 1); y_copi = xy_cop_i100(:, 2);
    plot3(x_copi, y_copi, x_copi.*0 + level_1, 'w-', 'linewidth', 3);
    plot3(x_copi, y_copi, x_copi.*0 + level_1, 'r.-', 'linewidth', 1.5);
    
    % Draw 12 Box Polygons
    box_level_1 = [box(1, 1:2:8), box(1, 1)]*0 + level_1;
    for i = 1:size(box, 1)
        plot3([box(i, 1:2:8), box(i, 1)], [box(i, 2:2:8), box(i, 2)], box_level_1, 'y-', 'linewidth', 1.2);
        
        center_x = (box(i, 1) + box(i, 5)) / 2;
        center_y = (box(i, 2) + box(i, 6)) / 2;
        text(center_x, center_y, level_1, num2str(i), ...
            'BackgroundColor', box_color(i, :), 'fontsize', 8.5, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', 'Color', [0, 0, 0]);
    end
    
    view(0, 90); grid on; axis equal;
    xlim([-5, n_wid + 5]); ylim([-2, n_len + 5]);
    title(sprintf('%s [%d] %d %d %d', strrep(tag, '_', '\_'), w, ratio_c(1), ratio_c(2), ratio_c(3)));
    saveas(fig, fullfile(out_paths.stage2_xy, sprintf('xy_box12_%s', tag)), 'jpg');
    close(fig);
    
    success_tags{end+1} = tag; %#ok<AGROW>
    fprintf('OK\n');
end

end
