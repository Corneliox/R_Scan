function interactive_box_curator(tag, out_paths, ratio_c)
% INTERACTIVE_BOX_CURATOR - Interactive Visual Studio for 12-Box Geometric Curation
%
% Allows researchers to visually inspect, fine-tune, and drag landmark handles
% and division levels to produce perfectly tailored 12-box anatomical regions.
%
% Inputs:
%   tag       - Trial tag string, e.g. 'R_t000_1', 'L_kanan_kiri_1'
%   out_paths - Output path structure from resolve_output_dir
%   ratio_c   - Metatarsal partition ratio (default: [30, 20, 20])

if nargin < 3 || isempty(ratio_c)
    ratio_c = [30, 20, 20];
end

max_txt_path = fullfile(out_paths.stage1_level, sprintf('map_level_max_%s.txt', tag));
if ~exist(max_txt_path, 'file')
    errordlg(sprintf('Trial map_level_max not found for %s. Please run Stage 1 first.', tag), 'Curator Error');
    return;
end
map_level_max = load(max_txt_path);
[n_len, n_wid] = size(map_level_max);

% Determine foot laterality (Priority 1: side_*.txt from Excel, Priority 2: Prefix, Priority 3: Morphology)
is_foot_right = false;
side_file = fullfile(out_paths.stage1_level, sprintf('side_%s.txt', tag));
if exist(side_file, 'file')
    fid_s = fopen(side_file, 'r');
    if fid_s ~= -1
        s_val = strtrim(fgetl(fid_s));
        fclose(fid_s);
        if strcmpi(s_val, 'R')
            is_foot_right = true;
        elseif strcmpi(s_val, 'L')
            is_foot_right = false;
        end
    end
elseif startsWith(tag, 'R_', 'IgnoreCase', true)
    is_foot_right = true;
elseif startsWith(tag, 'L_', 'IgnoreCase', true)
    is_foot_right = false;
elseif contains(tag, '_R_', 'IgnoreCase', true) || endsWith(tag, '_R', 'IgnoreCase', true)
    is_foot_right = true;
elseif contains(tag, '_L_', 'IgnoreCase', true) || endsWith(tag, '_L', 'IgnoreCase', true)
    is_foot_right = false;
else
    forefoot_rows = max(1, round(n_len * 0.50)):n_len;
    forefoot_patch = map_level_max(forefoot_rows, :);
    [~, max_lin_idx] = max(forefoot_patch(:));
    [~, peak_col] = ind2sub(size(forefoot_patch), max_lin_idx);
    is_foot_right = (peak_col < n_wid / 2);
end

% Try loading existing anatomy_p or generate default
anatomy_file = fullfile(out_paths.stage2_xy, sprintf('anatomy_p_%s.txt', tag));
if ~exist(anatomy_file, 'file')
    anatomy_file = fullfile(out_paths.root, sprintf('anatomy_p_%s.txt', tag));
end

if exist(anatomy_file, 'file')
    anatomy_p = load(anatomy_file);
else
    anatomy_p = compute_auto_anatomy(map_level_max, is_foot_right);
end

% Load real COP trajectory
xy_cop_i100 = [];
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
if isempty(xy_cop_i100)
    xy_cop_i100 = [
        linspace(anatomy_p(3, 1), anatomy_p(3, 2), 101)', ...
        linspace(anatomy_p(3, 3), anatomy_p(3, 4), 101)'
    ];
end

% Colors
box_color = [
    0.6   0.6   1.0;   % 1 Toe 1
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

% --- Initialize Interactive Handles State ---
% Handle 1: Medial Forefoot (MT 1) -> [anatomy_p(1, 2), anatomy_p(1, 4)]
% Handle 2: Lateral Forefoot (MT 4-5) -> [anatomy_p(2, 2), anatomy_p(2, 4)]
% Handle 3: Medial Heel -> [anatomy_p(1, 1), anatomy_p(1, 3)]
% Handle 4: Lateral Heel -> [anatomy_p(2, 1), anatomy_p(2, 3)]
% Handle 5: Toe Apex -> [anatomy_p(3, 2), anatomy_p(3, 4)]
% Handle 6: Heel Base -> [anatomy_p(3, 1), anatomy_p(3, 3)]

handles_xy = [
    anatomy_p(1, 2), anatomy_p(1, 4); ... % 1: Medial Forefoot
    anatomy_p(2, 2), anatomy_p(2, 4); ... % 2: Lateral Forefoot
    anatomy_p(1, 1), anatomy_p(1, 3); ... % 3: Medial Heel
    anatomy_p(2, 1), anatomy_p(2, 3); ... % 4: Lateral Heel
    anatomy_p(3, 2), anatomy_p(3, 4); ... % 5: Toe Apex
    anatomy_p(3, 1), anatomy_p(3, 3)      % 6: Heel Base
];

handle_names = {
    'Medial Forefoot (MT1)';
    'Lateral Forefoot (MT4-5)';
    'Medial Heel';
    'Lateral Heel';
    'Toe Apex (Hallux)';
    'Heel Base'
};

selected_handle_idx = -1;
current_box = [];

% Create Window
fig_w = 920; fig_h = 720;
screen_sz = get(0, 'ScreenSize');
fx = max(30, (screen_sz(3) - fig_w) / 2);
fy = max(30, (screen_sz(4) - fig_h) / 2);

hCurFig = figure('Name', sprintf('12-Box Interactive Curator Studio - %s', tag), ...
                 'NumberTitle', 'off', ...
                 'Position', [fx, fy, fig_w, fig_h], ...
                 'Color', [0.94, 0.94, 0.96], ...
                 'MenuBar', 'none', ...
                 'ToolBar', 'none', ...
                 'WindowButtonDownFcn', @on_mouse_down, ...
                 'WindowButtonMotionFcn', @on_mouse_move, ...
                 'WindowButtonUpFcn', @on_mouse_up);

% Plot Axes
hAx = axes('Parent', hCurFig, 'Units', 'pixels', 'Position', [50, 60, 580, 620]);

% Right Side Control Panel
uipanel(hCurFig, 'Title', ' Interactive Control & Curation ', ...
        'Units', 'pixels', 'Position', [650, 60, 250, 620], ...
        'FontName', 'Segoe UI', 'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', [1, 1, 1], 'ForegroundColor', [0.2, 0.3, 0.4]);

uicontrol(hCurFig, 'Style', 'text', 'String', sprintf('Trial: %s', tag), ...
          'Units', 'pixels', 'Position', [660, 625, 230, 25], ...
          'FontName', 'Segoe UI', 'FontSize', 10, 'FontWeight', 'bold', ...
          'BackgroundColor', [1, 1, 1], 'HorizontalAlignment', 'left');

side_str = 'Left Foot';
if is_foot_right, side_str = 'Right Foot'; end
uicontrol(hCurFig, 'Style', 'text', 'String', sprintf('Orientation: %s', side_str), ...
          'Units', 'pixels', 'Position', [660, 600, 230, 20], ...
          'FontName', 'Segoe UI', 'FontSize', 9, 'ForegroundColor', [0.1, 0.5, 0.2], ...
          'BackgroundColor', [1, 1, 1], 'HorizontalAlignment', 'left');

% Instruction text
inst_str = sprintf(['INSTRUCTIONS:\n', ...
                    '• Click and DRAG any CIRCLE handle on the footprint to adjust.\n', ...
                    '• 12-Boxes update in real-time!\n', ...
                    '• Handles:\n', ...
                    '  🔴 Cyan Circle : Medial/Lateral Forefoot\n', ...
                    '  🟡 Yellow Circle: Medial/Lateral Heel\n', ...
                    '  🟢 Green Circle : Toe Apex / Heel Base']);
uicontrol(hCurFig, 'Style', 'text', 'String', inst_str, ...
          'Units', 'pixels', 'Position', [660, 440, 230, 150], ...
          'FontName', 'Segoe UI', 'FontSize', 8.5, 'BackgroundColor', [0.96, 0.97, 0.99], ...
          'ForegroundColor', [0.2, 0.2, 0.3], 'HorizontalAlignment', 'left');

% Ratio MT input
uicontrol(hCurFig, 'Style', 'text', 'String', 'Ratio MT Partition:', ...
          'Units', 'pixels', 'Position', [660, 400, 230, 20], ...
          'FontName', 'Segoe UI', 'FontSize', 9, 'BackgroundColor', [1, 1, 1], ...
          'HorizontalAlignment', 'left');
hEditRatioCur = uicontrol(hCurFig, 'Style', 'edit', 'String', sprintf('%d, %d, %d', ratio_c(1), ratio_c(2), ratio_c(3)), ...
                          'Units', 'pixels', 'Position', [660, 375, 230, 24], ...
                          'FontName', 'Segoe UI', 'FontSize', 9, 'Callback', @on_ratio_change);

% Active handle info
hTxtHandleInfo = uicontrol(hCurFig, 'Style', 'text', 'String', 'Active Handle: (None)', ...
                           'Units', 'pixels', 'Position', [660, 320, 230, 40], ...
                           'FontName', 'Segoe UI', 'FontSize', 8.5, 'ForegroundColor', [0.5, 0.2, 0.2], ...
                           'BackgroundColor', [1, 1, 1], 'HorizontalAlignment', 'left');

% Reset Auto button
uicontrol(hCurFig, 'Style', 'pushbutton', 'String', '↺  Reset to Auto Baseline', ...
          'Units', 'pixels', 'Position', [660, 180, 230, 32], ...
          'FontName', 'Segoe UI', 'FontSize', 9, ...
          'Callback', @on_reset_auto);

% Save & Apply button
uicontrol(hCurFig, 'Style', 'pushbutton', 'String', '💾  SAVE & APPLY CURATION', ...
          'Units', 'pixels', 'Position', [660, 120, 230, 45], ...
          'FontName', 'Segoe UI', 'FontSize', 10, 'FontWeight', 'bold', ...
          'BackgroundColor', [0.18, 0.65, 0.35], 'ForegroundColor', [1, 1, 1], ...
          'Callback', @on_save_curation);

% Redraw initial
redraw_plot();

% =========================================================================
% INTERACTIVE CALLBACKS
% =========================================================================

    function on_mouse_down(~, ~)
        cp = get(hAx, 'CurrentPoint');
        mx = cp(1, 1); my = cp(1, 2);
        
        % Check distance to each handle
        dists = sqrt((handles_xy(:, 1) - mx).^2 + (handles_xy(:, 2) - my).^2);
        [min_d, idx] = min(dists);
        
        if min_d <= 3.5
            selected_handle_idx = idx;
            set(hTxtHandleInfo, 'String', sprintf('Active Handle:\n[#%d] %s', idx, handle_names{idx}), ...
                'ForegroundColor', [0.1, 0.4, 0.8]);
        else
            selected_handle_idx = -1;
            set(hTxtHandleInfo, 'String', 'Active Handle: (None)', 'ForegroundColor', [0.5, 0.5, 0.5]);
        end
    end

    function on_mouse_move(~, ~)
        if selected_handle_idx > 0
            cp = get(hAx, 'CurrentPoint');
            mx = cp(1, 1); my = cp(1, 2);
            
            % Update handle position
            handles_xy(selected_handle_idx, 1) = max(-10, min(n_wid + 10, mx));
            handles_xy(selected_handle_idx, 2) = max(-5, min(n_len + 10, my));
            
            redraw_plot();
        end
    end

    function on_mouse_up(~, ~)
        selected_handle_idx = -1;
    end

    function on_ratio_change(~, ~)
        r_str = get(hEditRatioCur, 'String');
        r_vals = str2num(r_str); %#ok<ST2NM>
        if ~isempty(r_vals) && length(r_vals) == 3
            ratio_c = r_vals;
            redraw_plot();
        else
            set(hEditRatioCur, 'String', sprintf('%d, %d, %d', ratio_c(1), ratio_c(2), ratio_c(3)));
        end
    end

    function on_reset_auto(~, ~)
        auto_p = compute_auto_anatomy(map_level_max, is_foot_right);
        handles_xy = [
            auto_p(1, 2), auto_p(1, 4); ...
            auto_p(2, 2), auto_p(2, 4); ...
            auto_p(1, 1), auto_p(1, 3); ...
            auto_p(2, 1), auto_p(2, 3); ...
            auto_p(3, 2), auto_p(3, 4); ...
            auto_p(3, 1), auto_p(3, 3)
        ];
        redraw_plot();
    end

    function on_save_curation(~, ~)
        % Build curated anatomy_p
        cur_anatomy = [
            handles_xy(3, 1), handles_xy(1, 1), handles_xy(3, 2), handles_xy(1, 2); ... % Medial Line
            handles_xy(4, 1), handles_xy(2, 1), handles_xy(4, 2), handles_xy(2, 2); ... % Lateral Line
            handles_xy(6, 1), handles_xy(5, 1), handles_xy(6, 2), handles_xy(5, 2); ... % Foot Axis
            (handles_xy(1, 1)+handles_xy(2, 1))/2, (handles_xy(1, 2)+handles_xy(2, 2))/2, 0.23, 0.23
        ];
        
        % Save anatomy_p
        save(fullfile(out_paths.stage2_xy, sprintf('anatomy_p_%s.txt', tag)), 'cur_anatomy', '-ascii');
        save(fullfile(out_paths.root, sprintf('anatomy_p_%s.txt', tag)), 'cur_anatomy', '-ascii');
        
        % Save xy_box12
        if ~isempty(current_box)
            save(fullfile(out_paths.stage2_xy, sprintf('xy_box12_%s.txt', tag)), 'current_box', '-ascii');
        end
        
        % Save JPG plot
        fig_save = figure('Visible', 'off');
        surf(map_level_max); hold on;
        x_copi = xy_cop_i100(:, 1); y_copi = xy_cop_i100(:, 2);
        cop_zi = x_copi(:, 1).*0 + 90;
        plot3(x_copi, y_copi, cop_zi, 'w', 'linewidth', 3); hold on; grid on;
        plot3(x_copi, y_copi, cop_zi, 'r.-', 'linewidth', 1); hold on; grid on;
        
        box_level_1 = [current_box(1, 1:2:8), current_box(1, 1)]*0 + 90;
        for i = 1:size(current_box, 1)
            plot3([current_box(i, 1:2:8), current_box(i, 1)], [current_box(i, 2:2:8), current_box(i, 2)], box_level_1, 'c-', 'linewidth', 2); hold on;
            plot3([current_box(i, 1:2:8), current_box(i, 1)], [current_box(i, 2:2:8), current_box(i, 2)], box_level_1, 'k-', 'linewidth', 1); hold on;
            
            center_x = (current_box(i, 1) + current_box(i, 3)) / 2;
            center_y = (current_box(i, 4) + current_box(i, 6)) / 2;
            text(center_x, center_y, 90, text_list(i, 1:2), 'BackgroundColor', box_color(i, :), 'fontsize', 8, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
        end
        
        x_text = -10; y_text = 30; y_space = -2;
        for i = 1:12
            text(x_text, y_text + i*y_space, text_list(i, :), 'BackgroundColor', box_color(i, :), 'fontsize', 8.5, 'FontWeight', 'bold');
        end
        
        view(0, 90); grid on; axis equal;
        xlim([-14, n_wid + 4]); ylim([-2, n_len + 3]);
        title(sprintf('%s [Curated] %d %d %d', strrep(tag, '_', '\_'), ratio_c(1), ratio_c(2), ratio_c(3)));
        saveas(fig_save, fullfile(out_paths.stage2_xy, sprintf('xy_box12_%s', tag)), 'jpg');
        close(fig_save);
        
        msgbox(sprintf('Curation saved successfully for %s!\nUpdated baseline will be used for Stages 3–6.', tag), 'Curation Saved', 'help');
    end

    function redraw_plot()
        cla(hAx);
        axes(hAx);
        surf(map_level_max); hold on;
        
        % Plot COP
        x_copi = xy_cop_i100(:, 1); y_copi = xy_cop_i100(:, 2);
        cop_zi = x_copi(:, 1).*0 + 90;
        plot3(x_copi, y_copi, cop_zi, 'w', 'linewidth', 3); hold on; grid on;
        plot3(x_copi, y_copi, cop_zi, 'r.-', 'linewidth', 1); hold on; grid on;
        
        % Compute geometry from current handles
        cur_p = [
            handles_xy(3, 1), handles_xy(1, 1), handles_xy(3, 2), handles_xy(1, 2); ...
            handles_xy(4, 1), handles_xy(2, 1), handles_xy(4, 2), handles_xy(2, 2); ...
            handles_xy(6, 1), handles_xy(5, 1), handles_xy(6, 2), handles_xy(5, 2); ...
            (handles_xy(1, 1)+handles_xy(2, 1))/2, (handles_xy(1, 2)+handles_xy(2, 2))/2, 0.23, 0.23
        ];
        
        box = compute_boxes_from_anatomy(cur_p, ratio_c);
        current_box = box;
        
        % Draw 12 boxes
        box_level_1 = [box(1, 1:2:8), box(1, 1)]*0 + 90;
        for i = 1:size(box, 1)
            plot3([box(i, 1:2:8), box(i, 1)], [box(i, 2:2:8), box(i, 2)], box_level_1, 'c-', 'linewidth', 2); hold on;
            plot3([box(i, 1:2:8), box(i, 1)], [box(i, 2:2:8), box(i, 2)], box_level_1, 'k-', 'linewidth', 1); hold on;
            
            center_x = (box(i, 1) + box(i, 3)) / 2;
            center_y = (box(i, 4) + box(i, 6)) / 2;
            text(center_x, center_y, 90, text_list(i, 1:2), ...
                'BackgroundColor', box_color(i, :), 'fontsize', 8, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
        end
        
        % Draw Draggable Control Handles
        % Forefoot handles (Cyan)
        plot3(handles_xy(1:2, 1), handles_xy(1:2, 2), [95, 95], 'co', 'MarkerSize', 11, 'LineWidth', 2.5, 'MarkerFaceColor', [0, 0.9, 0.9]);
        % Heel handles (Yellow)
        plot3(handles_xy(3:4, 1), handles_xy(3:4, 2), [95, 95], 'yo', 'MarkerSize', 11, 'LineWidth', 2.5, 'MarkerFaceColor', [1, 1, 0]);
        % Apex & Base handles (Green)
        plot3(handles_xy(5:6, 1), handles_xy(5:6, 2), [95, 95], 'go', 'MarkerSize', 11, 'LineWidth', 2.5, 'MarkerFaceColor', [0, 1, 0]);
        
        % Draw connecting axis lines
        plot3([handles_xy(3, 1), handles_xy(1, 1)], [handles_xy(3, 2), handles_xy(1, 2)], [92, 92], 'y--', 'LineWidth', 1.2); % Medial Line
        plot3([handles_xy(4, 1), handles_xy(2, 1)], [handles_xy(4, 2), handles_xy(2, 2)], [92, 92], 'y--', 'LineWidth', 1.2); % Lateral Line
        plot3([handles_xy(6, 1), handles_xy(5, 1)], [handles_xy(6, 2), handles_xy(5, 2)], [92, 92], 'k-', 'LineWidth', 1.8);  % Longitudinal Axis
        
        % Left legend
        x_text = -10; y_text = 30; y_space = -2;
        for i = 1:12
            text(x_text, y_text + i*y_space, text_list(i, :), 'BackgroundColor', box_color(i, :), 'fontsize', 8.5, 'FontWeight', 'bold');
        end
        
        view(0, 90); grid on; axis equal;
        xlim([-14, n_wid + 4]); ylim([-2, n_len + 3]);
        title(hAx, sprintf('%s (Click and Drag Circles to Curate)', strrep(tag, '_', '\_')), 'FontWeight', 'bold');
        drawnow;
    end

end

% =========================================================================
% GEOMETRIC COMPUTATION HELPERS
% =========================================================================

function [anatomy_p] = compute_auto_anatomy(map_level_max, is_foot_right)
    [n_len, n_wid] = size(map_level_max);
    rows_active = find(any(map_level_max > 0, 2));
    cols_active = find(any(map_level_max > 0, 1));
    
    if isempty(rows_active)
        rows_active = (round(n_len*0.1):round(n_len*0.9))';
        cols_active = (round(n_wid*0.2):round(n_wid*0.8))';
    end
    
    y_min = min(rows_active);
    y_max = max(rows_active);
    total_h = max(10, y_max - y_min + 1);
    
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
    
    % Heel zone (0% to 22%)
    heel_rows = y_min:min(y_max, round(y_min + 0.22 * total_h));
    y_heel_base = y_min;
    
    % Metatarsal zone: Base of toes / Distal MT line at 76% to 80%
    mt_rows = max(y_min, round(y_min + 0.55 * total_h)):min(y_max, round(y_min + 0.78 * total_h));
    y_mt_distal = round(y_min + 0.78 * total_h);
    
    if is_foot_right
        x_med_real = min(c_min_per_r(heel_rows));
        x_lat_real = max(c_max_per_r(heel_rows));
        x_med_for  = min(c_min_per_r(mt_rows));
        x_lat_for  = max(c_max_per_r(mt_rows));
    else
        x_med_real = max(c_max_per_r(heel_rows));
        x_lat_real = min(c_min_per_r(heel_rows));
        x_med_for  = max(c_max_per_r(mt_rows));
        x_lat_for  = min(c_min_per_r(mt_rows));
    end
    
    x_heel_c = (x_med_real + x_lat_real) / 2;
    x_mt_c   = (x_med_for  + x_lat_for)  / 2;
    
    % Toe apex zone
    toe_rows = max(y_min, round(y_min + 0.78 * total_h)):y_max;
    t_weights = map_level_max(toe_rows, :);
    [t_r, t_c] = find(t_weights > 0);
    if ~isempty(t_c)
        t_w = zeros(size(t_c));
        for k = 1:length(t_c), t_w(k) = t_weights(t_r(k), t_c(k)); end
        if sum(t_w) > 0, x_toe_c = sum(t_c .* t_w) / sum(t_w); else, x_toe_c = mean(t_c); end
    else
        x_toe_c = x_mt_c;
    end
    y_toe_top = y_max;
    
    anatomy_p = [
        x_med_real, x_med_for, y_heel_base + 1, y_mt_distal;
        x_lat_real, x_lat_for, y_heel_base + 1, y_mt_distal;
        x_heel_c,   x_toe_c,   y_heel_base,     y_toe_top;
        x_mt_c,     y_mt_distal, 0.23,          0.23
    ];
end

function [box] = compute_boxes_from_anatomy(anatomy_p, ratio_c)
    ratio_cc = [ratio_c(1), ratio_c(1)+ratio_c(2), ratio_c(1)+ratio_c(2)+ratio_c(3)];
    
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
    
    x_bb_toe = [x_vc_a(2), x_vc_b(2)]; y_bb_toe = [y_vc_a(2), y_vc_b(2)];
    [x_dd_toe, y_dd_toe] = func_perpendical_point_to_line(x_aa, y_aa, x_bb_toe, y_bb_toe, x_cc, y_cc);
    x_ct_d = x_dd_toe; y_ct_d = y_dd_toe;
    
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
end
