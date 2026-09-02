function rscan_curator_app(initial_out_dir)
% RSCAN_CURATOR_APP - Standalone Batch Inspection & Interactive 12-Box Curation Studio
%
% Rapidly inspect hundreds of processed trials one-by-one.
% Verified trials can be skipped with 1 click; inaccurate trials can be edited
% with live draggable handles and stored in RAM.
%
% Features:
% - Gallery Navigator: Previous / Next trial buttons & dropdown list
% - Propagate Baseline: Apply 1 curated trial to all other trials of the subject
% - In-Memory RAM Buffer: Changes are cached until committed
% - Top-Right 'Save & Repair All (Stage 3-6)' Button
% - Smart Close Hook with Save & Auto-Repair Dialog
%
% Launch from MATLAB:
% >> rscan_curator_app
% >> rscan_curator_app('path/to/output_folder')

root_dir = fileparts(mfilename('fullpath'));
src_dir  = fullfile(root_dir, 'src');
if exist(src_dir, 'dir')
    addpath(src_dir);
end

if nargin < 1 || isempty(initial_out_dir)
    initial_out_dir = fullfile(root_dir, 'output');
    if ~exist(initial_out_dir, 'dir')
        initial_out_dir = pwd;
    end
end

% --- App State Variables ---
app_state = struct();
app_state.out_dir = initial_out_dir;
app_state.out_paths = [];
app_state.trial_list = {};
app_state.current_idx = 1;
app_state.ram_buffer = containers.Map();
app_state.modified_tags = {};
app_state.active_handle_idx = -1;
app_state.handles_xy = zeros(6, 2);
app_state.ratio_c = [30, 20, 20];
app_state.is_foot_right = false;
app_state.map_level_max = [];
app_state.xy_cop_i100 = [];
app_state.current_box = [];

% Palette
c_bg       = [0.94, 0.94, 0.96];
c_panel    = [1.0, 1.0, 1.0];
c_repair   = [0.18, 0.65, 0.35];
c_curate   = [0.20, 0.45, 0.75];
font_main  = 'Segoe UI';

box_color = [
    0.6   0.6   1.0;
    0.0   0.7   0.0;
    1.0   0.5   0.0;
    1.0   1.0   0.0;
    1.0   0.0   0.0;
    1.0   0.0   1.0;
    0.5   0.5   0.5;
    0.0   0.9   0.9;
    0.5   0.0   0.0;
    0.0   1.0   0.0;
    0.7   0.0   0.7;
    0.0   0.0   0.9
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

fig_w = 1060; fig_h = 750;
screen_sz = get(0, 'ScreenSize');
fx = max(20, (screen_sz(3) - fig_w) / 2);
fy = max(20, (screen_sz(4) - fig_h) / 2);

hFig = figure('Name', 'RSscan Batch Curation Studio & Pipeline Repair', ...
              'NumberTitle', 'off', ...
              'Position', [fx, fy, fig_w, fig_h], ...
              'Color', c_bg, ...
              'MenuBar', 'none', ...
              'ToolBar', 'none', ...
              'CloseRequestFcn', @on_close_request, ...
              'WindowButtonDownFcn', @on_mouse_down, ...
              'WindowButtonMotionFcn', @on_mouse_move, ...
              'WindowButtonUpFcn', @on_mouse_up);

uicontrol(hFig, 'Style', 'text', 'String', 'RSscan Batch Inspection & 12-Box Curation Studio', ...
          'Units', 'pixels', 'Position', [20, 705, 550, 30], ...
          'FontName', font_main, 'FontSize', 14, 'FontWeight', 'bold', ...
          'BackgroundColor', c_bg, 'ForegroundColor', [0.15, 0.2, 0.3], ...
          'HorizontalAlignment', 'left');

hBtnTopRepair = uicontrol(hFig, 'Style', 'pushbutton', 'String', '💾  SAVE & REPAIR ALL (Stage 3-6)', ...
                          'Units', 'pixels', 'Position', [780, 700, 260, 36], ...
                          'FontName', font_main, 'FontSize', 10, 'FontWeight', 'bold', ...
                          'BackgroundColor', c_repair, 'ForegroundColor', [1, 1, 1], ...
                          'Callback', @(~, ~) save_and_repair_pipeline(true));

uipanel(hFig, 'Units', 'pixels', 'Position', [20, 640, 1020, 50], ...
        'BackgroundColor', c_panel, 'HighlightColor', [0.8, 0.8, 0.85]);

uicontrol(hFig, 'Style', 'text', 'String', 'Target Output Directory:', ...
          'Units', 'pixels', 'Position', [30, 652, 140, 22], ...
          'FontName', font_main, 'FontSize', 9, 'FontWeight', 'bold', ...
          'BackgroundColor', c_panel, 'HorizontalAlignment', 'left');

hEditOutPath = uicontrol(hFig, 'Style', 'edit', 'String', app_state.out_dir, ...
                         'Units', 'pixels', 'Position', [175, 652, 700, 24], ...
                         'FontName', font_main, 'FontSize', 9, 'BackgroundColor', [0.98, 0.98, 0.98], ...
                         'HorizontalAlignment', 'left');

uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Browse...', ...
          'Units', 'pixels', 'Position', [885, 652, 70, 24], ...
          'FontName', font_main, 'FontSize', 9, 'Callback', @on_browse_output);

uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Scan', ...
          'Units', 'pixels', 'Position', [960, 652, 65, 24], ...
          'FontName', font_main, 'FontSize', 9, 'FontWeight', 'bold', ...
          'Callback', @(~, ~) scan_output_directory());

hAx = axes('Parent', hFig, 'Units', 'pixels', 'Position', [40, 70, 620, 550]);

uipanel(hFig, 'Title', ' Curation & Navigation Controls ', ...
        'Units', 'pixels', 'Position', [680, 70, 360, 550], ...
        'FontName', font_main, 'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', c_panel, 'ForegroundColor', [0.2, 0.3, 0.4]);

hTxtNavStatus = uicontrol(hFig, 'Style', 'text', 'String', 'Trial: 0 of 0', ...
                          'Units', 'pixels', 'Position', [695, 575, 330, 24], ...
                          'FontName', font_main, 'FontSize', 11, 'FontWeight', 'bold', ...
                          'BackgroundColor', c_panel, 'ForegroundColor', [0.1, 0.3, 0.6], ...
                          'HorizontalAlignment', 'left');

hPopupTrials = uicontrol(hFig, 'Style', 'popupmenu', 'String', {'(No output trials found)'}, ...
                         'Units', 'pixels', 'Position', [695, 545, 330, 24], ...
                         'FontName', font_main, 'FontSize', 9, 'Callback', @on_popup_jump);

uicontrol(hFig, 'Style', 'pushbutton', 'String', '◀  Previous Trial', ...
          'Units', 'pixels', 'Position', [695, 505, 160, 32], ...
          'FontName', font_main, 'FontSize', 9.5, 'FontWeight', 'bold', ...
          'Callback', @(~, ~) navigate_trial(-1));

uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Next Trial  ▶', ...
          'Units', 'pixels', 'Position', [865, 505, 160, 32], ...
          'FontName', font_main, 'FontSize', 9.5, 'FontWeight', 'bold', ...
          'Callback', @(~, ~) navigate_trial(1));

hTxtModifiedBadge = uicontrol(hFig, 'Style', 'text', 'String', 'Status: Clean (Original)', ...
                              'Units', 'pixels', 'Position', [695, 475, 330, 20], ...
                              'FontName', font_main, 'FontSize', 8.5, 'FontWeight', 'bold', ...
                              'ForegroundColor', [0.3, 0.6, 0.3], 'BackgroundColor', c_panel, ...
                              'HorizontalAlignment', 'left');

uicontrol(hFig, 'Style', 'pushbutton', 'String', '🔗  Propagate This Geometry to All Trials of Subject', ...
          'Units', 'pixels', 'Position', [695, 430, 330, 34], ...
          'FontName', font_main, 'FontSize', 8.5, 'FontWeight', 'bold', ...
          'BackgroundColor', [0.35, 0.35, 0.65], 'ForegroundColor', [1, 1, 1], ...
          'Callback', @on_propagate_subject);

uicontrol(hFig, 'Style', 'text', 'String', 'Ratio MT Partition (Transversal %):', ...
          'Units', 'pixels', 'Position', [695, 395, 330, 18], ...
          'FontName', font_main, 'FontSize', 8.5, 'BackgroundColor', c_panel, ...
          'HorizontalAlignment', 'left');

hEditRatioApp = uicontrol(hFig, 'Style', 'edit', 'String', '30, 20, 20', ...
                          'Units', 'pixels', 'Position', [695, 370, 180, 24], ...
                          'FontName', font_main, 'FontSize', 9, 'Callback', @on_ratio_text_change);

uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Apply Ratio', ...
          'Units', 'pixels', 'Position', [885, 370, 140, 24], ...
          'FontName', font_main, 'FontSize', 8.5, 'Callback', @on_ratio_text_change);

hTxtCurHandle = uicontrol(hFig, 'Style', 'text', 'String', 'Active Handle: (None - Drag circles on foot)', ...
                          'Units', 'pixels', 'Position', [695, 330, 330, 30], ...
                          'FontName', font_main, 'FontSize', 8.5, 'ForegroundColor', [0.4, 0.4, 0.4], ...
                          'BackgroundColor', c_panel, 'HorizontalAlignment', 'left');

hTxtRamSummary = uicontrol(hFig, 'Style', 'text', 'String', 'Modified in RAM: 0 trials', ...
                           'Units', 'pixels', 'Position', [695, 290, 330, 20], ...
                           'FontName', font_main, 'FontSize', 8.5, 'FontWeight', 'bold', ...
                           'ForegroundColor', [0.7, 0.4, 0.1], 'BackgroundColor', c_panel, ...
                           'HorizontalAlignment', 'left');

uicontrol(hFig, 'Style', 'pushbutton', 'String', '↺  Reset Current Trial to Auto Baseline', ...
          'Units', 'pixels', 'Position', [695, 230, 330, 30], ...
          'FontName', font_main, 'FontSize', 9, ...
          'Callback', @on_reset_trial_auto);

uicontrol(hFig, 'Style', 'pushbutton', 'String', '📁  Save Curations Only (No Pipeline Run)', ...
          'Units', 'pixels', 'Position', [695, 140, 330, 32], ...
          'FontName', font_main, 'FontSize', 9, ...
          'Callback', @(~, ~) save_and_repair_pipeline(false));

uicontrol(hFig, 'Style', 'pushbutton', 'String', '🚀  SAVE & REPAIR (Stage 3-6)', ...
          'Units', 'pixels', 'Position', [695, 85, 330, 48], ...
          'FontName', font_main, 'FontSize', 10.5, 'FontWeight', 'bold', ...
          'BackgroundColor', c_repair, 'ForegroundColor', [1, 1, 1], ...
          'Callback', @(~, ~) save_and_repair_pipeline(true));

hTxtBottomStatus = uicontrol(hFig, 'Style', 'text', 'String', 'Ready. Select output directory to begin batch curation.', ...
                             'Units', 'pixels', 'Position', [40, 20, 1000, 25], ...
                             'FontName', font_main, 'FontSize', 8.5, 'ForegroundColor', [0.4, 0.4, 0.4], ...
                             'BackgroundColor', c_bg, 'HorizontalAlignment', 'left');

scan_output_directory();

    function on_browse_output(~, ~)
        sel_d = uigetdir(get(hEditOutPath, 'String'), 'Select RSscan Output Base Folder');
        if ischar(sel_d) && ~isempty(sel_d)
            set(hEditOutPath, 'String', sel_d);
            app_state.out_dir = sel_d;
            scan_output_directory();
        end
    end

    function scan_output_directory()
        target_d = get(hEditOutPath, 'String');
        if ~exist(target_d, 'dir')
            set(hTxtBottomStatus, 'String', sprintf('Directory not found: %s', target_d), 'ForegroundColor', [0.8, 0.2, 0.2]);
            return;
        end
        
        app_state.out_paths = struct();
        app_state.out_paths.root          = target_d;
        app_state.out_paths.stage1_level  = fullfile(target_d, '1_step_level');
        app_state.out_paths.stage2_xy     = fullfile(target_d, '2_step_get_xy');
        app_state.out_paths.stage3_value  = fullfile(target_d, '3_step_value');
        app_state.out_paths.stage3_fap    = fullfile(target_d, '3_step_value', 'data_f_a_p');
        app_state.out_paths.stage3_inval_L= fullfile(target_d, '3_step_value', 'inbox_value_L');
        app_state.out_paths.stage3_inval_R= fullfile(target_d, '3_step_value', 'inbox_value_R');
        app_state.out_paths.stage3_inxy_L = fullfile(target_d, '3_step_value', 'inbox_xy_L');
        app_state.out_paths.stage3_inxy_R = fullfile(target_d, '3_step_value', 'inbox_xy_R');
        app_state.out_paths.stage3_matrix = fullfile(target_d, '3_step_value', 'p_f_matrix');
        app_state.out_paths.stage3_jpg    = fullfile(target_d, '3_step_value', 'jpg');
        app_state.out_paths.stage4_timing = fullfile(target_d, '4_step_start_end');
        app_state.out_paths.stage5_foot   = fullfile(target_d, '5_foot');
        app_state.out_paths.stage5_fap    = fullfile(target_d, '5_foot', 'force_area_pressure');
        app_state.out_paths.stage5_timing = fullfile(target_d, '5_foot', 'start_end');
        app_state.out_paths.stage6_group  = fullfile(target_d, '6_group');
        
        cand_dirs = {app_state.out_paths.stage1_level, target_d};
        max_files = [];
        for cd_i = 1:length(cand_dirs)
            if exist(cand_dirs{cd_i}, 'dir')
                found = dir(fullfile(cand_dirs{cd_i}, 'map_level_max_*.txt'));
                if ~isempty(found)
                    max_files = found;
                    app_state.out_paths.stage1_level = cand_dirs{cd_i};
                    break;
                end
            end
        end
        
        if isempty(max_files)
            sub_dirs = dir(target_d);
            sub_dirs = sub_dirs([sub_dirs.isdir] & ~ismember({sub_dirs.name}, {'.', '..'}));
            for sd_i = 1:length(sub_dirs)
                check_p = fullfile(target_d, sub_dirs(sd_i).name, '1_step_level');
                if exist(check_p, 'dir')
                    found = dir(fullfile(check_p, 'map_level_max_*.txt'));
                    if ~isempty(found)
                        target_d = fullfile(target_d, sub_dirs(sd_i).name);
                        set(hEditOutPath, 'String', target_d);
                        scan_output_directory();
                        return;
                    end
                end
            end
        end
        
        if isempty(max_files)
            set(hTxtBottomStatus, 'String', 'No processed trials (map_level_max_*.txt) found. Please run Stages 1 & 2 first in GUI.', ...
                'ForegroundColor', [0.8, 0.4, 0.1]);
            set(hPopupTrials, 'String', {'(No trials found)'}, 'Value', 1);
            set(hTxtNavStatus, 'String', 'Trial: 0 of 0');
            cla(hAx);
            return;
        end
        
        tags = cell(length(max_files), 1);
        for f = 1:length(max_files)
            fn = max_files(f).name;
            tag_name = regexprep(fn, '^map_level_max_', '');
            tag_name = regexprep(tag_name, '\.txt$', '');
            tags{f} = tag_name;
        end
        
        app_state.trial_list = tags;
        app_state.current_idx = 1;
        
        set(hPopupTrials, 'String', tags, 'Value', 1);
        set(hTxtBottomStatus, 'String', sprintf('Successfully loaded %d trial(s) for visual curation.', length(tags)), ...
            'ForegroundColor', [0.1, 0.6, 0.2]);
        
        load_trial_view(1);
    end

    function load_trial_view(trial_idx)
        if isempty(app_state.trial_list) || trial_idx < 1 || trial_idx > length(app_state.trial_list)
            return;
        end
        
        app_state.current_idx = trial_idx;
        tag = app_state.trial_list{trial_idx};
        
        set(hPopupTrials, 'Value', trial_idx);
        set(hTxtNavStatus, 'String', sprintf('Trial %d of %d:  %s', trial_idx, length(app_state.trial_list), tag));
        
        max_file = fullfile(app_state.out_paths.stage1_level, sprintf('map_level_max_%s.txt', tag));
        if ~exist(max_file, 'file')
            max_file = fullfile(app_state.out_paths.root, sprintf('map_level_max_%s.txt', tag));
        end
        if ~exist(max_file, 'file')
            return;
        end
        
        app_state.map_level_max = load(max_file);
        [n_len, n_wid] = size(app_state.map_level_max);
        
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
            forefoot_rows = max(1, round(n_len * 0.50)):n_len;
            forefoot_patch = app_state.map_level_max(forefoot_rows, :);
            [~, max_lin_idx] = max(forefoot_patch(:));
            [~, peak_col] = ind2sub(size(forefoot_patch), max_lin_idx);
            is_foot_right = (peak_col < n_wid / 2);
        end
        app_state.is_foot_right = is_foot_right;
        
        if app_state.ram_buffer.isKey(tag)
            cached = app_state.ram_buffer(tag);
            anatomy_p = cached.anatomy_p;
            app_state.ratio_c = cached.ratio_c;
            set(hTxtModifiedBadge, 'String', 'Status: ✍️ Modified in RAM (Unsaved)', 'ForegroundColor', [0.8, 0.4, 0.1]);
        else
            anatomy_file = fullfile(app_state.out_paths.stage2_xy, sprintf('anatomy_p_%s.txt', tag));
            if ~exist(anatomy_file, 'file')
                anatomy_file = fullfile(app_state.out_paths.root, sprintf('anatomy_p_%s.txt', tag));
            end
            
            if exist(anatomy_file, 'file')
                anatomy_p = load(anatomy_file);
                set(hTxtModifiedBadge, 'String', 'Status: 💾 Loaded from Saved Baseline', 'ForegroundColor', [0.2, 0.5, 0.8]);
            else
                anatomy_p = compute_auto_anatomy(app_state.map_level_max, is_foot_right);
                set(hTxtModifiedBadge, 'String', 'Status: 🤖 Auto-Generated Baseline', 'ForegroundColor', [0.3, 0.6, 0.3]);
            end
            app_state.ratio_c = [30, 20, 20];
        end
        
        app_state.xy_cop_i100 = [];
        mat_path = fullfile(app_state.out_paths.stage1_level, sprintf('map_level_%s.mat', tag));
        if exist(mat_path, 'file')
            ld = load(mat_path);
            map_3d = ld.map_level;
            n_f = size(map_3d, 3);
            raw_cop = zeros(n_f, 2);
            [gc, gr] = meshgrid(1:size(map_3d, 2), 1:size(map_3d, 1));
            for f_i = 1:n_f
                fm = map_3d(:, :, f_i);
                sf = sum(fm(:));
                if sf > 0
                    raw_cop(f_i, 1) = sum(sum(fm .* gc)) / sf;
                    raw_cop(f_i, 2) = sum(sum(fm .* gr)) / sf;
                end
            end
            vc = raw_cop(raw_cop(:, 1) > 0 & raw_cop(:, 2) > 0, :);
            if size(vc, 1) >= 5
                app_state.xy_cop_i100 = interp1(linspace(0, 100, size(vc, 1))', vc, linspace(0, 100, 101)', 'linear');
            end
        end
        if isempty(app_state.xy_cop_i100)
            app_state.xy_cop_i100 = [
                linspace(anatomy_p(3, 1), anatomy_p(3, 2), 101)', ...
                linspace(anatomy_p(3, 3), anatomy_p(3, 4), 101)'
            ];
        end
        
        app_state.handles_xy = [
            anatomy_p(1, 2), anatomy_p(1, 4); ...
            anatomy_p(2, 2), anatomy_p(2, 4); ...
            anatomy_p(1, 1), anatomy_p(1, 3); ...
            anatomy_p(2, 1), anatomy_p(2, 3); ...
            anatomy_p(3, 2), anatomy_p(3, 4); ...
            anatomy_p(3, 1), anatomy_p(3, 3)
        ];
        
        set(hEditRatioApp, 'String', sprintf('%d, %d, %d', app_state.ratio_c(1), app_state.ratio_c(2), app_state.ratio_c(3)));
        update_ram_summary_label();
        redraw_canvas();
    end

    function redraw_canvas()
        cla(hAx);
        axes(hAx);
        
        if isempty(app_state.map_level_max)
            return;
        end
        
        surf(app_state.map_level_max); hold on;
        
        x_copi = app_state.xy_cop_i100(:, 1); y_copi = app_state.xy_cop_i100(:, 2);
        cop_zi = x_copi(:, 1).*0 + 90;
        plot3(x_copi, y_copi, cop_zi, 'w', 'linewidth', 3); hold on; grid on;
        plot3(x_copi, y_copi, cop_zi, 'r.-', 'linewidth', 1); hold on; grid on;
        
        cur_p = [
            app_state.handles_xy(3, 1), app_state.handles_xy(1, 1), app_state.handles_xy(3, 2), app_state.handles_xy(1, 2); ...
            app_state.handles_xy(4, 1), app_state.handles_xy(2, 1), app_state.handles_xy(4, 2), app_state.handles_xy(2, 2); ...
            app_state.handles_xy(6, 1), app_state.handles_xy(5, 1), app_state.handles_xy(6, 2), app_state.handles_xy(5, 2); ...
            (app_state.handles_xy(1, 1)+app_state.handles_xy(2, 1))/2, (app_state.handles_xy(1, 2)+app_state.handles_xy(2, 2))/2, 0.23, 0.23
        ];
        
        box = compute_boxes_from_anatomy(cur_p, app_state.ratio_c);
        app_state.current_box = box;
        
        box_level_1 = [box(1, 1:2:8), box(1, 1)]*0 + 90;
        for b_i = 1:size(box, 1)
            plot3([box(b_i, 1:2:8), box(b_i, 1)], [box(b_i, 2:2:8), box(b_i, 2)], box_level_1, 'c-', 'linewidth', 2); hold on;
            plot3([box(b_i, 1:2:8), box(b_i, 1)], [box(b_i, 2:2:8), box(b_i, 2)], box_level_1, 'k-', 'linewidth', 1); hold on;
            
            center_x = (box(b_i, 1) + box(b_i, 3)) / 2;
            center_y = (box(b_i, 4) + box(b_i, 6)) / 2;
            text(center_x, center_y, 90, text_list(b_i, 1:2), ...
                'BackgroundColor', box_color(b_i, :), 'fontsize', 8, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
        end
        
        plot3(app_state.handles_xy(1:2, 1), app_state.handles_xy(1:2, 2), [95, 95], 'co', 'MarkerSize', 11, 'LineWidth', 2.5, 'MarkerFaceColor', [0, 0.9, 0.9]);
        plot3(app_state.handles_xy(3:4, 1), app_state.handles_xy(3:4, 2), [95, 95], 'yo', 'MarkerSize', 11, 'LineWidth', 2.5, 'MarkerFaceColor', [1, 1, 0]);
        plot3(app_state.handles_xy(5:6, 1), app_state.handles_xy(5:6, 2), [95, 95], 'go', 'MarkerSize', 11, 'LineWidth', 2.5, 'MarkerFaceColor', [0, 1, 0]);
        
        plot3([app_state.handles_xy(3, 1), app_state.handles_xy(1, 1)], [app_state.handles_xy(3, 2), app_state.handles_xy(1, 2)], [92, 92], 'y--', 'LineWidth', 1.2);
        plot3([app_state.handles_xy(4, 1), app_state.handles_xy(2, 1)], [app_state.handles_xy(4, 2), app_state.handles_xy(2, 2)], [92, 92], 'y--', 'LineWidth', 1.2);
        plot3([app_state.handles_xy(6, 1), app_state.handles_xy(5, 1)], [app_state.handles_xy(6, 2), app_state.handles_xy(5, 2)], [92, 92], 'k-', 'LineWidth', 1.8);
        
        x_text = -10; y_text = 30; y_space = -2;
        for i = 1:12
            text(x_text, y_text + i*y_space, text_list(i, :), 'BackgroundColor', box_color(i, :), 'fontsize', 8.5, 'FontWeight', 'bold');
        end
        
        [n_len, n_wid] = size(app_state.map_level_max);
        view(0, 90); grid on; axis equal;
        xlim([-14, n_wid + 4]); ylim([-2, n_len + 3]);
        
        tag = app_state.trial_list{app_state.current_idx};
        title(hAx, sprintf('%s (Drag Circles to Curate)', strrep(tag, '_', '\_')), 'FontWeight', 'bold');
        drawnow;
    end

    function on_mouse_down(~, ~)
        if isempty(app_state.map_level_max), return; end
        cp = get(hAx, 'CurrentPoint');
        mx = cp(1, 1); my = cp(1, 2);
        
        dists = sqrt((app_state.handles_xy(:, 1) - mx).^2 + (app_state.handles_xy(:, 2) - my).^2);
        [min_d, idx] = min(dists);
        
        if min_d <= 3.8
            app_state.active_handle_idx = idx;
            h_names = {'Medial Forefoot (MT1)', 'Lateral Forefoot (MT4-5)', 'Medial Heel', 'Lateral Heel', 'Toe Apex', 'Heel Base'};
            set(hTxtCurHandle, 'String', sprintf('Active Handle:\n[#%d] %s', idx, h_names{idx}), 'ForegroundColor', [0.1, 0.4, 0.8]);
        else
            app_state.active_handle_idx = -1;
            set(hTxtCurHandle, 'String', 'Active Handle: (None - Drag circles on foot)', 'ForegroundColor', [0.4, 0.4, 0.4]);
        end
    end

    function on_mouse_move(~, ~)
        if app_state.active_handle_idx > 0
            cp = get(hAx, 'CurrentPoint');
            mx = cp(1, 1); my = cp(1, 2);
            
            [n_len, n_wid] = size(app_state.map_level_max);
            app_state.handles_xy(app_state.active_handle_idx, 1) = max(-10, min(n_wid + 10, mx));
            app_state.handles_xy(app_state.active_handle_idx, 2) = max(-5, min(n_len + 10, my));
            
            cache_current_trial_to_ram();
            redraw_canvas();
        end
    end

    function on_mouse_up(~, ~)
        app_state.active_handle_idx = -1;
    end

    function cache_current_trial_to_ram()
        tag = app_state.trial_list{app_state.current_idx};
        
        cur_p = [
            app_state.handles_xy(3, 1), app_state.handles_xy(1, 1), app_state.handles_xy(3, 2), app_state.handles_xy(1, 2); ...
            app_state.handles_xy(4, 1), app_state.handles_xy(2, 1), app_state.handles_xy(4, 2), app_state.handles_xy(2, 2); ...
            app_state.handles_xy(6, 1), app_state.handles_xy(5, 1), app_state.handles_xy(6, 2), app_state.handles_xy(5, 2); ...
            (app_state.handles_xy(1, 1)+app_state.handles_xy(2, 1))/2, (app_state.handles_xy(1, 2)+app_state.handles_xy(2, 2))/2, 0.23, 0.23
        ];
        
        box = compute_boxes_from_anatomy(cur_p, app_state.ratio_c);
        
        cached_entry = struct();
        cached_entry.anatomy_p = cur_p;
        cached_entry.box = box;
        cached_entry.ratio_c = app_state.ratio_c;
        cached_entry.is_modified = true;
        
        app_state.ram_buffer(tag) = cached_entry;
        
        if ~ismember(tag, app_state.modified_tags)
            app_state.modified_tags{end+1} = tag;
        end
        
        set(hTxtModifiedBadge, 'String', 'Status: ✍️ Modified in RAM (Unsaved)', 'ForegroundColor', [0.8, 0.4, 0.1]);
        update_ram_summary_label();
    end

    function update_ram_summary_label()
        set(hTxtRamSummary, 'String', sprintf('Modified in RAM: %d trial(s)', length(app_state.modified_tags)));
    end

    function on_propagate_subject(~, ~)
        if isempty(app_state.trial_list), return; end
        curr_tag = app_state.trial_list{app_state.current_idx};
        
        sub_prefix = regexprep(curr_tag, '_\d+$', '');
        
        subj_matches = {};
        for k = 1:length(app_state.trial_list)
            t_name = app_state.trial_list{k};
            if startsWith(t_name, sub_prefix)
                subj_matches{end+1} = t_name; %#ok<AGROW>
            end
        end
        
        if length(subj_matches) <= 1
            msgbox(sprintf('Only 1 trial found for subject %s.', sub_prefix), 'Info', 'help');
            return;
        end
        
        cur_p = [
            app_state.handles_xy(3, 1), app_state.handles_xy(1, 1), app_state.handles_xy(3, 2), app_state.handles_xy(1, 2); ...
            app_state.handles_xy(4, 1), app_state.handles_xy(2, 1), app_state.handles_xy(4, 2), app_state.handles_xy(2, 2); ...
            app_state.handles_xy(6, 1), app_state.handles_xy(5, 1), app_state.handles_xy(6, 2), app_state.handles_xy(5, 2); ...
            (app_state.handles_xy(1, 1)+app_state.handles_xy(2, 1))/2, (app_state.handles_xy(1, 2)+app_state.handles_xy(2, 2))/2, 0.23, 0.23
        ];
        box = compute_boxes_from_anatomy(cur_p, app_state.ratio_c);
        
        for m_i = 1:length(subj_matches)
            m_tag = subj_matches{m_i};
            cached_entry = struct('anatomy_p', cur_p, 'box', box, 'ratio_c', app_state.ratio_c, 'is_modified', true);
            app_state.ram_buffer(m_tag) = cached_entry;
            if ~ismember(m_tag, app_state.modified_tags)
                app_state.modified_tags{end+1} = m_tag;
            end
        end
        
        update_ram_summary_label();
        msgbox(sprintf('Successfully applied this geometry baseline to all %d trials of %s in RAM!', ...
               length(subj_matches), sub_prefix), 'Propagation Complete', 'help');
    end

    function on_ratio_text_change(~, ~)
        r_str = get(hEditRatioApp, 'String');
        r_vals = str2num(r_str); %#ok<ST2NM>
        if ~isempty(r_vals) && length(r_vals) == 3
            app_state.ratio_c = r_vals;
            cache_current_trial_to_ram();
            redraw_canvas();
        else
            set(hEditRatioApp, 'String', sprintf('%d, %d, %d', app_state.ratio_c(1), app_state.ratio_c(2), app_state.ratio_c(3)));
        end
    end

    function on_reset_trial_auto(~, ~)
        auto_p = compute_auto_anatomy(app_state.map_level_max, app_state.is_foot_right);
        app_state.handles_xy = [
            auto_p(1, 2), auto_p(1, 4); ...
            auto_p(2, 2), auto_p(2, 4); ...
            auto_p(1, 1), auto_p(1, 3); ...
            auto_p(2, 1), auto_p(2, 3); ...
            auto_p(3, 2), auto_p(3, 4); ...
            auto_p(3, 1), auto_p(3, 3)
        ];
        app_state.ratio_c = [30, 20, 20];
        set(hEditRatioApp, 'String', '30, 20, 20');
        cache_current_trial_to_ram();
        redraw_canvas();
    end

    function navigate_trial(step)
        new_idx = app_state.current_idx + step;
        if new_idx >= 1 && new_idx <= length(app_state.trial_list)
            load_trial_view(new_idx);
        end
    end

    function on_popup_jump(~, ~)
        sel = get(hPopupTrials, 'Value');
        load_trial_view(sel);
    end

    function save_and_repair_pipeline(run_repair)
        if isempty(app_state.modified_tags)
            msgbox('No trials have been modified in RAM yet.', 'Info', 'help');
            return;
        end
        
        num_mod = length(app_state.modified_tags);
        set(hTxtBottomStatus, 'String', sprintf('Saving %d modified trial(s) to disk...', num_mod), 'ForegroundColor', [0.1, 0.3, 0.7]);
        drawnow;
        
        modified_subjects = {};
        for m = 1:num_mod
            m_tag = app_state.modified_tags{m};
            cached = app_state.ram_buffer(m_tag);
            
            cur_anatomy = cached.anatomy_p;
            save(fullfile(app_state.out_paths.stage2_xy, sprintf('anatomy_p_%s.txt', m_tag)), 'cur_anatomy', '-ascii');
            save(fullfile(app_state.out_paths.root, sprintf('anatomy_p_%s.txt', m_tag)), 'cur_anatomy', '-ascii');
            
            cur_box = cached.box;
            save(fullfile(app_state.out_paths.stage2_xy, sprintf('xy_box12_%s.txt', m_tag)), 'cur_box', '-ascii');
            
            max_p = fullfile(app_state.out_paths.stage1_level, sprintf('map_level_max_%s.txt', m_tag));
            if exist(max_p, 'file')
                ml_max = load(max_p);
                fig_s = figure('Visible', 'off');
                surf(ml_max); hold on;
                
                mat_f = fullfile(app_state.out_paths.stage1_level, sprintf('map_level_%s.mat', m_tag));
                if exist(mat_f, 'file')
                    ld_mat = load(mat_f); m3d = ld_mat.map_level;
                    [gc, gr] = meshgrid(1:size(m3d, 2), 1:size(m3d, 1));
                    raw_c = zeros(size(m3d, 3), 2);
                    for f_i = 1:size(m3d, 3)
                        fm = m3d(:, :, f_i); sf = sum(fm(:));
                        if sf > 0
                            raw_c(f_i, 1) = sum(sum(fm .* gc))/sf;
                            raw_c(f_i, 2) = sum(sum(fm .* gr))/sf;
                        end
                    end
                    vc = raw_c(raw_c(:, 1)>0 & raw_c(:, 2)>0, :);
                    if size(vc, 1)>=5
                        xy_c100 = interp1(linspace(0, 100, size(vc, 1))', vc, linspace(0, 100, 101)', 'linear');
                        plot3(xy_c100(:, 1), xy_c100(:, 2), xy_c100(:, 1)*0 + 90, 'w-', 'linewidth', 3);
                        plot3(xy_c100(:, 1), xy_c100(:, 2), xy_c100(:, 1)*0 + 90, 'r.-', 'linewidth', 1);
                    end
                end
                
                bl1 = [cur_box(1, 1:2:8), cur_box(1, 1)]*0 + 90;
                for b_i = 1:12
                    plot3([cur_box(b_i, 1:2:8), cur_box(b_i, 1)], [cur_box(b_i, 2:2:8), cur_box(b_i, 2)], bl1, 'c-', 'linewidth', 2); hold on;
                    plot3([cur_box(b_i, 1:2:8), cur_box(b_i, 1)], [cur_box(b_i, 2:2:8), cur_box(b_i, 2)], bl1, 'k-', 'linewidth', 1); hold on;
                    cx = (cur_box(b_i, 1) + cur_box(b_i, 3))/2;
                    cy = (cur_box(b_i, 4) + cur_box(b_i, 6))/2;
                    text(cx, cy, 90, text_list(b_i, 1:2), 'BackgroundColor', box_color(b_i, :), 'fontsize', 8, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
                end
                
                x_t = -10; y_t = 30; y_sp = -2;
                for i = 1:12
                    text(x_t, y_t + i*y_sp, text_list(i, :), 'BackgroundColor', box_color(i, :), 'fontsize', 8.5, 'FontWeight', 'bold');
                end
                view(0, 90); grid on; axis equal;
                xlim([-14, size(ml_max, 2)+4]); ylim([-2, size(ml_max, 1)+3]);
                title(sprintf('%s [Curated]', strrep(m_tag, '_', '\_')));
                saveas(fig_s, fullfile(app_state.out_paths.stage2_xy, sprintf('xy_box12_%s', m_tag)), 'jpg');
                close(fig_s);
            end
            
            s_prefix = regexprep(m_tag, '_\d+$', '');
            if ~ismember(s_prefix, modified_subjects)
                modified_subjects{end+1} = s_prefix; %#ok<AGROW>
            end
        end
        
        if ~run_repair
            app_state.modified_tags = {};
            update_ram_summary_label();
            set(hTxtModifiedBadge, 'String', 'Status: 💾 Saved to Disk', 'ForegroundColor', [0.2, 0.5, 0.8]);
            set(hTxtBottomStatus, 'String', sprintf('Saved %d curated trials to disk.', num_mod), 'ForegroundColor', [0.1, 0.6, 0.2]);
            msgbox(sprintf('Successfully saved %d curated trials to disk!', num_mod), 'Saved', 'help');
            return;
        end
        
        set(hTxtBottomStatus, 'String', '⚙️ Running Pipeline Repair (Stages 3 to 6)... Please wait.', 'ForegroundColor', [0.8, 0.4, 0.1]);
        drawnow;
        
        try
            stage3_compute_fap(app_state.modified_tags, app_state.out_paths);
            stage4_temporal_events(app_state.modified_tags, app_state.out_paths, 70);
            
            sub_info_repair = struct('id', {}, 'trial_tags', {});
            for s_i = 1:length(modified_subjects)
                sub_id = modified_subjects{s_i};
                s_tags = {};
                for t_i = 1:length(app_state.trial_list)
                    if startsWith(app_state.trial_list{t_i}, sub_id)
                        s_tags{end+1} = app_state.trial_list{t_i}; %#ok<AGROW>
                    end
                end
                sub_info_repair(s_i).id = sub_id;
                sub_info_repair(s_i).trial_tags = s_tags;
            end
            stage5_subject_aggregation(sub_info_repair, app_state.out_paths, 70);
            stage6_group_analysis(modified_subjects, app_state.out_paths);
            
            app_state.modified_tags = {};
            update_ram_summary_label();
            set(hTxtModifiedBadge, 'String', 'Status: ✅ Saved & Fully Repaired (Stages 3-6)', 'ForegroundColor', [0.1, 0.6, 0.2]);
            set(hTxtBottomStatus, 'String', sprintf('✅ Pipeline repair completed successfully for %d trial(s)!', num_mod), ...
                'ForegroundColor', [0.1, 0.6, 0.2]);
            
            msgbox(sprintf('Pipeline repair completed successfully!\n\n• %d trials updated\n• %d subjects re-aggregated (Mean & SD)\n• Stages 3–6 data and SPSS matrices synchronized.', ...
                   num_mod, length(modified_subjects)), 'Repair Complete', 'help');
        catch ME
            set(hTxtBottomStatus, 'String', sprintf('❌ Repair error: %s', ME.message), 'ForegroundColor', [0.8, 0.2, 0.2]);
            errordlg(['Error during pipeline repair: ', ME.message], 'Repair Error');
        end
    end

    function on_close_request(~, ~)
        if ~isempty(app_state.modified_tags)
            num_unsaved = length(app_state.modified_tags);
            choice = questdlg(sprintf('You have %d modified trial(s) in RAM that are unsaved.\n\nWhat would you like to do before closing?', num_unsaved), ...
                              'Unsaved Curation Changes', ...
                              'Save & Run Repair (Stage 3-6)', ...
                              'Save Only (No Repair)', ...
                              'Discard & Close', ...
                              'Save & Run Repair (Stage 3-6)');
            
            if strcmp(choice, 'Save & Run Repair (Stage 3-6)')
                save_and_repair_pipeline(true);
                delete(hFig);
            elseif strcmp(choice, 'Save Only (No Repair)')
                save_and_repair_pipeline(false);
                delete(hFig);
            elseif strcmp(choice, 'Discard & Close')
                delete(hFig);
            else
                return;
            end
        else
            delete(hFig);
        end
    end

end

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
    
    heel_rows = y_min:min(y_max, round(y_min + 0.22 * total_h));
    y_heel_base = y_min;
    
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
