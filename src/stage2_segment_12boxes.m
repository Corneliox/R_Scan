function [success_tags] = stage2_segment_12boxes(trial_tags, out_paths, aux_data_dir, ratio_c)
% STAGE2_SEGMENT_12BOXES - Computes 12 Functional Anatomical Regions on the Foot
%
% Inputs:
%   trial_tags   - Cell array of trial tags, e.g. {'R_t000_1', ...}
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
    0.6  0.6  1.0;   % 1 Toe 1
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
    
    % Try loading anatomy_p and xy_cop if available
    anatomy_p = [];
    xy_cop_i100 = [];
    
    cand_anatomy = {
        fullfile(aux_data_dir, sprintf('anatomy_p_%s.txt', tag)), ...
        fullfile(out_paths.root, sprintf('anatomy_p_%s.txt', tag)), ...
        fullfile(fileparts(out_paths.root), sprintf('anatomy_p_%s.txt', tag))
    };
    for k = 1:length(cand_anatomy)
        if exist(cand_anatomy{k}, 'file')
            anatomy_p = load(cand_anatomy{k}); break;
        end
    end
    
    cand_cop = {
        fullfile(aux_data_dir, sprintf('xy_cop_i100_3_%s.txt', tag)), ...
        fullfile(out_paths.root, sprintf('xy_cop_i100_3_%s.txt', tag)), ...
        fullfile(fileparts(out_paths.root), sprintf('xy_cop_i100_3_%s.txt', tag))
    };
    for k = 1:length(cand_cop)
        if exist(cand_cop{k}, 'file')
            xy_cop_i100 = load(cand_cop{k}); break;
        end
    end
    
    % If manual anatomy landmarks missing, auto-generate geometric landmarks from foot contour
    if isempty(anatomy_p) || size(anatomy_p, 1) < 4
        [rows, cols] = find(map_level_max > 0);
        if isempty(rows)
            [n_len, n_wid] = size(map_level_max);
            rows = [round(n_len*0.2); round(n_len*0.8)];
            cols = [round(n_wid*0.3); round(n_wid*0.7)];
        end
        min_y = min(rows); max_y = max(rows);
        min_x = min(cols); max_x = max(cols);
        mid_x = (min_x + max_x) / 2;
        
        % Generate standard anatomical template
        anatomy_p = [
            min_x, min_y + (max_y-min_y)*0.6, min_x + (max_x-min_x)*0.2, min_y + (max_y-min_y)*0.2;
            max_x, min_y + (max_y-min_y)*0.6, max_x - (max_x-min_x)*0.2, min_y + (max_y-min_y)*0.2;
            mid_x, max_y, mid_x, min_y;
            min_x, min_y + (max_y-min_y)*0.65, 0.23, 0.23
        ];
    end
    
    if isempty(xy_cop_i100)
        xy_cop_i100 = zeros(101, 2);
        xy_cop_i100(:, 1) = linspace(anatomy_p(3,1), anatomy_p(3,2), 101);
        xy_cop_i100(:, 2) = linspace(anatomy_p(3,3), anatomy_p(3,4), 101);
    end
    
    % Geometric computations
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
    
    x_ct_p = xy_toe(1);  y_ct_p = xy_toe(2);
    x_cd1_p= xy_mt(1);   y_cd1_p= xy_mt(2);
    x_ch_p = xy_heel(1); y_ch_p = xy_heel(2);
    
    x_cm = [(x_a(1)+x_b(1))/2, (x_a(2)+x_b(2))/2];
    y_cm = [(y_a(1)+y_b(1))/2, (y_a(2)+y_b(2))/2];
    
    ploy_a  = polyfit(x_a, y_a, 1);
    ploy_b  = polyfit(x_b, y_b, 1);
    ploy_cm = polyfit(x_cm, y_cm, 1);
    
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
        vc_a = function_vc_a \ constant_vc_a;
        
        function_vc_b = [-ploy_b(1), 1; -ploy_vc(1), 1];
        constant_vc_b = [ploy_b(2); ploy_vc(2)];
        vc_b = function_vc_b \ constant_vc_b;
        
        x_vc_a(i) = vc_a(1); y_vc_a(i) = vc_a(2);
        x_vc_b(i) = vc_b(1); y_vc_b(i) = vc_b(2);
    end
    
    % Metatarsal division
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
    
    % Toe division
    x_bb_toe = [x_vc_a(2), x_vc_b(2)]; y_bb_toe = [y_vc_a(2), y_vc_b(2)];
    [x_dd_toe, y_dd_toe] = func_perpendical_point_to_line(x_aa, y_aa, x_bb_toe, y_bb_toe, x_cc, y_cc);
    x_ct_d = x_dd_toe; y_ct_d = y_dd_toe;
    
    % Construct 12 Boxes
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
    save(fullfile(out_paths.stage2_xy, ['xy_box12_', tag, '.txt']), 'box', '-ascii');
    
    % Render & Save Plot
    fig = figure('Visible', 'off');
    surf(map_level_max); hold on;
    x_copi = xy_cop_i100(:, 1); y_copi = xy_cop_i100(:, 2);
    plot3(x_copi, y_copi, x_copi.*0 + level_1, 'r.-', 'linewidth', 1);
    
    box_level_1 = [box(1, 1:2:8), box(1, 1)]*0 + level_1;
    for i = 1:size(box, 1)
        plot3([box(i, 1:2:8), box(i, 1)], [box(i, 2:2:8), box(i, 2)], box_level_1, 'k-', 'linewidth', 1);
        text((box(i,1)+box(i,3))/2, (box(i,4)+box(i,6))/2, level_1, num2str(i), ...
            'BackgroundColor', box_color(i, :), 'fontsize', 8, 'HorizontalAlignment', 'center');
    end
    view(0, 90); grid on; axis equal;
    title(sprintf('%s 12 Anatomical Boxes', strrep(tag, '_', '\_')));
    saveas(fig, fullfile(out_paths.stage2_xy, ['xy_box12_', tag]), 'jpg');
    close(fig);
    
    success_tags{end+1} = tag; %#ok<AGROW>
    fprintf('OK\n');
end

end
