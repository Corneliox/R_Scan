function [success_tags] = stage3_compute_fap(trial_tags, out_paths)
% STAGE3_COMPUTE_FAP - Extracts Force, Area, and Pressure in 12 Boxes across 101 Stance Points
%
% Inputs:
%   trial_tags - Cell array of trial tags, e.g. {'R_t000_1', ...}
%   out_paths  - Structure of paths from resolve_output_dir

success_tags = {};
sensor_cell_area = 0.53 * 0.75; % cm^2 per cell

for w = 1:length(trial_tags)
    tag = trial_tags{w};
    fprintf('   [Stage 3] Calculating F, A, P (101 pts): %s ... ', tag);
    
    mat_path = fullfile(out_paths.stage1_level, sprintf('map_level_%s.mat', tag));
    box_path = fullfile(out_paths.stage2_xy, sprintf('xy_box12_%s.txt', tag));
    
    if ~exist(mat_path, 'file') || ~exist(box_path, 'file')
        fprintf('SKIPPED (File mat/box tidak lengkap)\n');
        continue;
    end
    
    loaded_mat = load(mat_path);
    matrix_level = loaded_mat.map_level;
    box = load(box_path);
    
    [n_rows, n_cols, n_frames] = size(matrix_level);
    
    % Prepare coordinate lookup table
    matrix_list = zeros(n_rows * n_cols, 2);
    for i = 1:n_rows
        for j = 1:n_cols
            matrix_list((i-1)*n_cols + j, :) = [j, i];
        end
    end
    
    num_boxes = size(box, 1);
    data_f = zeros(n_frames, num_boxes);
    data_p = zeros(n_frames, num_boxes);
    
    is_left = startsWith(tag, 'L', 'IgnoreCase', true);
    if is_left
        inval_dir = out_paths.stage3_inval_L;
        inxy_dir  = out_paths.stage3_inxy_L;
    else
        inval_dir = out_paths.stage3_inval_R;
        inxy_dir  = out_paths.stage3_inxy_R;
    end
    
    for b = 1:num_boxes
        a = box(b, 1:2); b_pt = box(b, 3:4); c = box(b, 5:6); d = box(b, 7:8);
        
        % Identify active cell coordinates inside this bounding box
        [aaaa, ~] = func_abcd_in(matrix_level(:, :, 1), matrix_list, a, b_pt, c, d);
        unit_count = size(aaaa, 1);
        
        value_inbox = zeros(n_frames, max(1, unit_count));
        
        if unit_count > 0
            for e = 1:n_frames
                mat_e = matrix_level(:, :, e);
                vals = zeros(1, unit_count);
                for pt_i = 1:unit_count
                    r = aaaa(pt_i, 2);
                    c_idx = aaaa(pt_i, 1);
                    if r >= 1 && r <= n_rows && c_idx >= 1 && c_idx <= n_cols
                        vals(pt_i) = mat_e(r, c_idx);
                    end
                end
                value_inbox(e, :) = vals;
                data_f(e, b) = sum(vals);
                data_p(e, b) = sum(vals) / (unit_count * sensor_cell_area);
            end
        end
        
        save(fullfile(inval_dir, sprintf('box12_value_inbox%d_%s.txt', b, tag)), 'value_inbox', '-ascii');
        save(fullfile(inxy_dir,  sprintf('box12_xy_inbox%d_%s.txt', b, tag)), 'aaaa', '-ascii');
    end
    
    data_f_sum = sum(data_f, 2);
    
    data_matrix = zeros(n_frames, 1);
    for e = 1:n_frames
        data_matrix(e) = sum(sum(matrix_level(:, :, e)));
    end
    
    % Save raw un-interpolated force & pressure
    save(fullfile(out_paths.stage3_matrix, sprintf('box12_data_f_%s.txt', tag)), 'data_f', '-ascii');
    save(fullfile(out_paths.stage3_matrix, sprintf('box12_data_p_%s.txt', tag)), 'data_p', '-ascii');
    save(fullfile(out_paths.stage3_matrix, sprintf('box12_data_matrix_%s.txt', tag)), 'data_matrix', '-ascii');
    save(fullfile(out_paths.stage3_matrix, sprintf('box12_data_f_sum_%s.txt', tag)), 'data_f_sum', '-ascii');
    
    % Interpolate to standard 101 points (0-100% stance phase)
    data_all = [data_f, data_p, data_matrix, data_f_sum];
    x_orig = linspace(0, 100, n_frames)';
    x_101  = linspace(0, 100, 101)';
    data_101_f12_p12_m1_s1 = interp1(x_orig, data_all, x_101, 'linear');
    
    save(fullfile(out_paths.stage3_fap, sprintf('box12_data_101_f12_p12_m1_s1_%s.txt', tag)), 'data_101_f12_p12_m1_s1', '-ascii');
    
    % Render & Save Plot
    fig = figure('Visible', 'off');
    subplot(2, 1, 1);
    plot(0:100, data_101_f12_p12_m1_s1(:, 1:12), 'linewidth', 1.5);
    ylabel('Force (N)'); grid on; title(sprintf('%s 12-Box Regional Force', strrep(tag, '_', '\_')));
    
    subplot(2, 1, 2);
    plot(0:100, data_101_f12_p12_m1_s1(:, 13:24), 'linewidth', 1.5);
    xlabel('% Stance Phase'); ylabel('Pressure (N/cm^2)'); grid on;
    saveas(fig, fullfile(out_paths.stage3_jpg, sprintf('box_value_%s', tag)), 'jpg');
    close(fig);
    
    success_tags{end+1} = tag; %#ok<AGROW>
    fprintf('OK\n');
end

end
