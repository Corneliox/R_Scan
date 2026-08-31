function rscan_gui()
% RSCAN_GUI - Graphical User Interface for RSscan Plantar Pressure Pipeline
%
% Launch this function in MATLAB:
% >> rscan_gui

root_dir = fileparts(mfilename('fullpath'));
src_dir  = fullfile(root_dir, 'src');
if exist(src_dir, 'dir')
    addpath(src_dir);
end

% Create Main Figure Window
fig_width  = 780;
fig_height = 680;
screen_size = get(0, 'ScreenSize');
fig_x = max(50, (screen_size(3) - fig_width) / 2);
fig_y = max(50, (screen_size(4) - fig_height) / 2);

hFig = figure('Name', 'RSscan Plantar Pressure & Gait Analysis Studio', ...
              'NumberTitle', 'off', ...
              'Position', [fig_x, fig_y, fig_width, fig_height], ...
              'Color', [0.94, 0.94, 0.96], ...
              'MenuBar', 'none', ...
              'ToolBar', 'none', ...
              'Resize', 'on');

% --- Color Palette & Fonts ---
c_panel  = [1.0, 1.0, 1.0];
c_success= [0.18, 0.65, 0.35];
font_main = 'Segoe UI';

% Title Banner
uicontrol(hFig, 'Style', 'text', 'String', 'RSscan Plantar Pressure & Gait Analysis', ...
          'Units', 'pixels', 'Position', [20, 630, 740, 35], ...
          'FontName', font_main, 'FontSize', 15, 'FontWeight', 'bold', ...
          'BackgroundColor', [0.94, 0.94, 0.96], 'ForegroundColor', [0.15, 0.2, 0.3], ...
          'HorizontalAlignment', 'left');

% =========================================================================
% PANEL 1: DIRECTORY CONFIGURATION (I/O)
% =========================================================================
uipanel(hFig, 'Title', ' 1. Folder Configuration (Input & Output) ', ...
        'Units', 'pixels', 'Position', [20, 480, 740, 140], ...
        'FontName', font_main, 'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', c_panel, 'ForegroundColor', [0.2, 0.3, 0.4]);

% Default candidate raw dir
default_raw = fullfile(root_dir, '20260824_rscop_box_pressure', 'rawdata_rs');
if ~exist(default_raw, 'dir')
    default_raw = fullfile(root_dir, 'rawdata_rs');
end
default_out = fullfile(root_dir, 'output');

% Raw Input
uicontrol(hFig, 'Style', 'text', 'String', 'Input (Raw Data):', ...
          'Units', 'pixels', 'Position', [35, 565, 120, 20], ...
          'FontName', font_main, 'FontSize', 9, 'BackgroundColor', c_panel, ...
          'HorizontalAlignment', 'left');
hEditRaw = uicontrol(hFig, 'Style', 'edit', 'String', default_raw, ...
                     'Units', 'pixels', 'Position', [160, 565, 460, 24], ...
                     'FontName', font_main, 'FontSize', 9, 'BackgroundColor', [0.98, 0.98, 0.98], ...
                     'HorizontalAlignment', 'left');
uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Browse...', ...
          'Units', 'pixels', 'Position', [630, 565, 110, 24], ...
          'FontName', font_main, 'FontSize', 9, 'Callback', @browse_raw_callback);

% Output Folder
uicontrol(hFig, 'Style', 'text', 'String', 'Output (Results):', ...
          'Units', 'pixels', 'Position', [35, 520, 120, 20], ...
          'FontName', font_main, 'FontSize', 9, 'BackgroundColor', c_panel, ...
          'HorizontalAlignment', 'left');
hEditOut = uicontrol(hFig, 'Style', 'edit', 'String', default_out, ...
                     'Units', 'pixels', 'Position', [160, 520, 460, 24], ...
                     'FontName', font_main, 'FontSize', 9, 'BackgroundColor', [0.98, 0.98, 0.98], ...
                     'HorizontalAlignment', 'left');
uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Browse...', ...
          'Units', 'pixels', 'Position', [630, 520, 110, 24], ...
          'FontName', font_main, 'FontSize', 9, 'Callback', @browse_out_callback);

% Status info
hTxtDirStatus = uicontrol(hFig, 'Style', 'text', 'String', 'Status: Ready', ...
                          'Units', 'pixels', 'Position', [160, 490, 460, 18], ...
                          'FontName', font_main, 'FontSize', 8, 'ForegroundColor', [0.4, 0.4, 0.4], ...
                          'BackgroundColor', c_panel, 'HorizontalAlignment', 'left');

% =========================================================================
% PANEL 2: SUBJECT SELECTION
% =========================================================================
uipanel(hFig, 'Title', ' 2. Subject Selection ', ...
        'Units', 'pixels', 'Position', [20, 250, 350, 215], ...
        'FontName', font_main, 'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', c_panel, 'ForegroundColor', [0.2, 0.3, 0.4]);

hListSubjects = uicontrol(hFig, 'Style', 'listbox', 'String', {'(Loading subjects...)'}, ...
                          'Units', 'pixels', 'Position', [35, 295, 320, 130], ...
                          'FontName', font_main, 'FontSize', 9, 'Max', 2, 'Min', 0);

uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Select All', ...
          'Units', 'pixels', 'Position', [35, 260, 95, 24], ...
          'FontName', font_main, 'FontSize', 8, 'Callback', @select_all_callback);
uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Clear', ...
          'Units', 'pixels', 'Position', [135, 260, 75, 24], ...
          'FontName', font_main, 'FontSize', 8, 'Callback', @clear_sub_callback);
uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Refresh List', ...
          'Units', 'pixels', 'Position', [215, 260, 140, 24], ...
          'FontName', font_main, 'FontSize', 8, 'Callback', @refresh_sub_callback);

% =========================================================================
% PANEL 3: STAGES & PARAMETERS
% =========================================================================
uipanel(hFig, 'Title', ' 3. Stages & Biomechanical Parameters ', ...
        'Units', 'pixels', 'Position', [390, 250, 370, 215], ...
        'FontName', font_main, 'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', c_panel, 'ForegroundColor', [0.2, 0.3, 0.4]);

hChk1 = uicontrol(hFig, 'Style', 'checkbox', 'String', 'Stage 1: 3D Array & COP Extraction', ...
                  'Units', 'pixels', 'Position', [405, 415, 330, 20], ...
                  'FontName', font_main, 'FontSize', 8.5, 'BackgroundColor', c_panel, 'Value', 1);
hChk2 = uicontrol(hFig, 'Style', 'checkbox', 'String', 'Stage 2: 12-Box Geometric Partitioning', ...
                  'Units', 'pixels', 'Position', [405, 390, 330, 20], ...
                  'FontName', font_main, 'FontSize', 8.5, 'BackgroundColor', c_panel, 'Value', 1);
hChk3 = uicontrol(hFig, 'Style', 'checkbox', 'String', 'Stage 3: Regional Force, Area & Pressure (101 pts)', ...
                  'Units', 'pixels', 'Position', [405, 365, 345, 20], ...
                  'FontName', font_main, 'FontSize', 8.5, 'BackgroundColor', c_panel, 'Value', 1);
hChk4 = uicontrol(hFig, 'Style', 'checkbox', 'String', 'Stage 4: Timing Events & %BW Normalization', ...
                  'Units', 'pixels', 'Position', [405, 340, 330, 20], ...
                  'FontName', font_main, 'FontSize', 8.5, 'BackgroundColor', c_panel, 'Value', 1);
hChk5 = uicontrol(hFig, 'Style', 'checkbox', 'String', 'Stage 5: N-Trial Subject Aggregation (Mean & SD)', ...
                  'Units', 'pixels', 'Position', [405, 315, 345, 20], ...
                  'FontName', font_main, 'FontSize', 8.5, 'BackgroundColor', c_panel, 'Value', 1);
hChk6 = uicontrol(hFig, 'Style', 'checkbox', 'String', 'Stage 6: Arch Index Cohort Grouping & SPSS Export', ...
                  'Units', 'pixels', 'Position', [405, 290, 345, 20], ...
                  'FontName', font_main, 'FontSize', 8.5, 'BackgroundColor', c_panel, 'Value', 1);

% Parameters
uicontrol(hFig, 'Style', 'text', 'String', 'Bodyweight (kg):', ...
          'Units', 'pixels', 'Position', [405, 260, 100, 20], ...
          'FontName', font_main, 'FontSize', 8.5, 'BackgroundColor', c_panel, ...
          'HorizontalAlignment', 'left');
hEditBW = uicontrol(hFig, 'Style', 'edit', 'String', '70', ...
                    'Units', 'pixels', 'Position', [505, 260, 50, 22], ...
                    'FontName', font_main, 'FontSize', 8.5);

uicontrol(hFig, 'Style', 'text', 'String', 'Ratio MT:', ...
          'Units', 'pixels', 'Position', [570, 260, 60, 20], ...
          'FontName', font_main, 'FontSize', 8.5, 'BackgroundColor', c_panel, ...
          'HorizontalAlignment', 'left');
hEditRatio = uicontrol(hFig, 'Style', 'edit', 'String', '30, 20, 20', ...
                      'Units', 'pixels', 'Position', [630, 260, 110, 22], ...
                      'FontName', font_main, 'FontSize', 8.5);

% =========================================================================
% PANEL 4: EXECUTION & CONSOLE LOG
% =========================================================================
uipanel(hFig, 'Title', ' 4. Execution & Status Log ', ...
        'Units', 'pixels', 'Position', [20, 20, 740, 215], ...
        'FontName', font_main, 'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', c_panel, 'ForegroundColor', [0.2, 0.3, 0.4]);

hBtnRun = uicontrol(hFig, 'Style', 'pushbutton', 'String', '▶  RUN PIPELINE', ...
                    'Units', 'pixels', 'Position', [35, 175, 490, 32], ...
                    'FontName', font_main, 'FontSize', 11, 'FontWeight', 'bold', ...
                    'BackgroundColor', c_success, 'ForegroundColor', [1, 1, 1], ...
                    'Callback', @run_pipeline_callback);

hBtnOpenOut = uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Open Output Folder', ...
                        'Units', 'pixels', 'Position', [540, 175, 200, 32], ...
                        'FontName', font_main, 'FontSize', 9, ...
                        'Callback', @open_output_callback);

hLogBox = uicontrol(hFig, 'Style', 'edit', 'String', {'RSscan GUI Ready. Click "RUN PIPELINE" to start.'}, ...
                    'Units', 'pixels', 'Position', [35, 30, 705, 135], ...
                    'FontName', 'Consolas', 'FontSize', 8.5, 'Max', 2, 'Min', 0, ...
                    'BackgroundColor', [0.12, 0.14, 0.18], 'ForegroundColor', [0.85, 0.9, 0.95], ...
                    'HorizontalAlignment', 'left');

% Populate Subject List initially
discovered_subs = [];
refresh_subjects();

% =========================================================================
% CALLBACK FUNCTIONS
% =========================================================================

    function browse_raw_callback(~, ~)
        sel_dir = uigetdir(get(hEditRaw, 'String'), 'Select RSscan Raw Data Directory');
        if ischar(sel_dir) && ~isempty(sel_dir)
            set(hEditRaw, 'String', sel_dir);
            refresh_subjects();
        end
    end

    function browse_out_callback(~, ~)
        sel_dir = uigetdir(get(hEditOut, 'String'), 'Select Output Base Directory');
        if ischar(sel_dir) && ~isempty(sel_dir)
            set(hEditOut, 'String', sel_dir);
        end
    end

    function select_all_callback(~, ~)
        n = length(get(hListSubjects, 'String'));
        if n > 0
            set(hListSubjects, 'Value', 1:n);
        end
    end

    function clear_sub_callback(~, ~)
        set(hListSubjects, 'Value', []);
    end

    function refresh_sub_callback(~, ~)
        refresh_subjects();
    end

    function refresh_subjects()
        raw_p = get(hEditRaw, 'String');
        if ~exist(raw_p, 'dir')
            set(hListSubjects, 'String', {'(Directory not found)'}, 'Value', 1);
            set(hTxtDirStatus, 'String', 'Status: Raw directory not found', 'ForegroundColor', [0.8, 0.2, 0.2]);
            return;
        end
        
        try
            subs = scan_subject_trials(raw_p, {});
            discovered_subs = subs;
            if isempty(subs)
                set(hListSubjects, 'String', {'(No subjects found in folder)'}, 'Value', 1);
                set(hTxtDirStatus, 'String', 'Status: 0 subjects found', 'ForegroundColor', [0.8, 0.5, 0.1]);
            else
                list_str = cell(length(subs), 1);
                total_t = 0;
                for k = 1:length(subs)
                    list_str{k} = sprintf('%s  (%d trials: %s)', subs(k).id, length(subs(k).trial_nums), num2str(subs(k).trial_nums));
                    total_t = total_t + length(subs(k).trial_nums);
                end
                set(hListSubjects, 'String', list_str, 'Value', 1:length(subs));
                set(hTxtDirStatus, 'String', sprintf('Status: %d subjects detected (%d total trials)', length(subs), total_t), ...
                    'ForegroundColor', [0.1, 0.6, 0.2]);
            end
        catch ME
            set(hListSubjects, 'String', {['Error: ', ME.message]});
        end
    end

    function run_pipeline_callback(~, ~)
        raw_dir = get(hEditRaw, 'String');
        out_dir = get(hEditOut, 'String');
        
        % Stages
        stages = [];
        if get(hChk1, 'Value'), stages = [stages, 1]; end
        if get(hChk2, 'Value'), stages = [stages, 2]; end
        if get(hChk3, 'Value'), stages = [stages, 3]; end
        if get(hChk4, 'Value'), stages = [stages, 4]; end
        if get(hChk5, 'Value'), stages = [stages, 5]; end
        if get(hChk6, 'Value'), stages = [stages, 6]; end
        
        if isempty(stages)
            msgbox('Pilih minimal satu tahap untuk dijalankan.', 'Peringatan', 'warn');
            return;
        end
        
        % Subjects
        sel_idx = get(hListSubjects, 'Value');
        
        if isempty(sel_idx) || isempty(discovered_subs)
            msgbox('Pilih minimal satu subjek untuk diproses.', 'Peringatan', 'warn');
            return;
        end
        
        selected_sub_ids = {discovered_subs(sel_idx).id};
        
        % Parameters
        bw_val = str2double(get(hEditBW, 'String'));
        if isnan(bw_val) || bw_val <= 0, bw_val = 70; end
        
        ratio_str = get(hEditRatio, 'String');
        ratio_vals = str2num(ratio_str); %#ok<ST2NM>
        if isempty(ratio_vals) || length(ratio_vals) ~= 3, ratio_vals = [30, 20, 20]; end
        
        % Update Log
        log_msg = {
            sprintf('[%s] Memulai pipeline RSscan...', datestr(now, 'HH:MM:SS'));
            sprintf('Input  : %s', raw_dir);
            sprintf('Output : %s', out_dir);
            sprintf('Subjek : %d subjek dipilih', length(selected_sub_ids));
            sprintf('Stages : %s', num2str(stages));
            'Sedang memproses... Harap tunggu (lihat Command Window MATLAB untuk detail lengkap).'
        };
        set(hLogBox, 'String', log_msg(:));
        drawnow;
        
        set(hBtnRun, 'Enable', 'off', 'String', '⏳ PROCESSING...');
        
        try
            [final_out, ~] = main_rscan_pipeline('raw_dir', raw_dir, ...
                                                'output_dir', out_dir, ...
                                                'subject', selected_sub_ids, ...
                                                'stages', stages, ...
                                                'bodyweight', bw_val, ...
                                                'ratio_c', ratio_vals);
            
            complete_msg = {
                sprintf('[%s] ✅ EKSEKUSI PIPELINE SELESAI!', datestr(now, 'HH:MM:SS'));
                sprintf('Hasil tersimpan di: %s', final_out.root);
                'Seluruh tahap berhasil diproses tanpa error.'
            };
            set(hLogBox, 'String', [log_msg(:); complete_msg(:)]);
            msgbox(sprintf('Proses selesai!\nHasil tersimpan di:\n%s', final_out.root), 'Sukses', 'help');
        catch ME
            err_msg = {
                sprintf('[%s] ❌ ERROR: %s', datestr(now, 'HH:MM:SS'), ME.message);
                'Periksa detail error di Command Window.'
            };
            set(hLogBox, 'String', [log_msg(:); err_msg(:)]);
            errordlg(['Terjadi kesalahan: ', ME.message], 'Error Pipeline');
        end
        
        set(hBtnRun, 'Enable', 'on', 'String', '▶  RUN PIPELINE');
    end

    function open_output_callback(~, ~)
        out_dir = get(hEditOut, 'String');
        if exist(out_dir, 'dir')
            winopen(out_dir);
        else
            parent_out = fileparts(out_dir);
            if exist(parent_out, 'dir')
                winopen(parent_out);
            else
                msgbox('Folder output belum terbentuk.', 'Info', 'help');
            end
        end
    end

end
