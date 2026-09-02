function [success_tags] = stage1_extract_3d_cop(subject_info, out_paths)
% STAGE1_EXTRACT_3D_COP - Parses RSscan TSV/Excel exports into 3D Spatio-Temporal Matrix & COP
%
% Inputs:
%   subject_info - Structure containing subject folder & available trials from scan_subject_trials
%   out_paths    - Structure of destination paths from resolve_output_dir
%
% Output:
%   success_tags - Cell array of successfully processed trial tags (e.g. {'R_t000_1', 't001_1'})

success_tags = {};
subj_folder = subject_info.folder_path;
configured_side = upper(subject_info.side); % 'R', 'L', or 'AUTO'

% Get list of all files in subject directory for regex matching
dir_struct  = dir(subj_folder);
all_files   = {dir_struct(~[dir_struct.isdir]).name};
all_structs = dir_struct(~[dir_struct.isdir]);

for t_idx = 1:length(subject_info.trial_nums)
    trial_num = subject_info.trial_nums(t_idx);
    trial_tag = sprintf('%s_%d', subject_info.id, trial_num);
    
    fprintf('   [Stage 1] Processing trial: %s ... ', trial_tag);
    
    % --- 1. Regex File Matching (Flexible & Case-Insensitive) ---
    % Centre of Force
    pat_cop = {
        sprintf('^(_)?%d\\s*Centre\\s*of\\s*Force.*\\.(xls|xlsx)$', trial_num), ...
        sprintf('Centre\\s*of\\s*Force.*[\\s_]%d\\.(xls|xlsx)$', trial_num), ...
        sprintf('.*Centre\\s*of\\s*Force.*%d.*\\.(xls|xlsx)$', trial_num)
    };
    [cop_file, cop_size] = match_file(all_files, all_structs, pat_cop);
    
    % Dynamic Roll Off
    pat_roll = {
        sprintf('^(_)?%d\\s*Dynamic\\s*Roll\\s*off.*\\.(xls|xlsx)$', trial_num), ...
        sprintf('Dynamic\\s*Roll\\s*off.*[\\s_]%d\\.(xls|xlsx)$', trial_num), ...
        sprintf('.*Dynamic\\s*Roll\\s*off.*%d.*\\.(xls|xlsx)$', trial_num)
    };
    [roll_file, roll_size] = match_file(all_files, all_structs, pat_roll);
    
    % Dynamic Maximum Image
    pat_max = {
        sprintf('^(_)?%d\\s*Dynamic\\s*Maximum.*Image.*\\.(xls|xlsx)$', trial_num), ...
        sprintf('Dynamic\\s*Maximum.*Image.*[\\s_]%d\\.(xls|xlsx)$', trial_num), ...
        sprintf('.*Dynamic\\s*Maximum.*Image.*%d.*\\.(xls|xlsx)$', trial_num)
    };
    [max_file, max_size] = match_file(all_files, all_structs, pat_max);
    
    if isempty(cop_file) || isempty(roll_file)
        fprintf('SKIPPED (File COP atau Roll-off tidak ditemukan)\n');
        continue;
    end
    
    cop_path  = fullfile(subj_folder, cop_file);
    roll_path = fullfile(subj_folder, roll_file);
    max_path  = '';
    if ~isempty(max_file)
        max_path = fullfile(subj_folder, max_file);
    end
    
    % --- 2. Dynamic Parsing of Centre of Force (COP) & Laterality Auto-Discovery ---
    [cop_data, detected_side, grid_dims] = parse_cop_file(cop_path, configured_side);
    
    % Determine final is_right flag
    if strcmpi(configured_side, 'R')
        is_right = true;
    elseif strcmpi(configured_side, 'L')
        is_right = false;
    else
        % AUTO laterality from file contents
        is_right = strcmpi(detected_side, 'R');
    end
    
    % Calculate active frame count
    frame = 0;
    if ~isempty(cop_data) && size(cop_data, 2) >= 5
        yy_fz = cop_data(:, 5);
        no_yy_min = find(yy_fz > 0);
        if length(no_yy_min) > 1
            no_0 = diff(no_yy_min);
            no_00 = [1; no_0];
            no_11 = find(no_00 == 1);
            if length(no_00) ~= length(no_11)
                no_22 = find(no_00 > 1, 1);
                if ~isempty(no_22)
                    no_11 = 1:(no_22 - 1);
                end
            end
            yy_min = yy_fz(no_11);
            yy_max = yy_min(yy_min < 5000);
            frame = length(yy_max);
        end
    end
    
    % --- 3. Dynamic Parsing of Dynamic Roll Off ---
    [map_level, roll_frames] = parse_roll_off_file(roll_path, is_right, grid_dims, frame, configured_side);
    
    if isempty(map_level) || size(map_level, 3) == 0
        fprintf('SKIPPED (Tidak ada frame Roll-Off yang dapat dibaca)\n');
        continue;
    end
    
    if frame <= 0
        frame = size(map_level, 3);
    else
        frame = min(frame, size(map_level, 3));
        map_level = map_level(:, :, 1:frame);
    end
    
    % --- 4. Max Image Parsing & Automatic Fallback ---
    max_calculated = false;
    map_level_max = [];
    
    if ~isempty(max_path) && max_size >= 1000
        map_level_max = parse_max_image_file(max_path, is_right, size(map_level, 1), size(map_level, 2), configured_side);
    end
    
    % Fallback: Compute maximum directly from 3D Roll-Off matrix
    if isempty(map_level_max)
        map_level_max = max(map_level, [], 3);
        max_calculated = true;
    end
    
    % --- 5. Save Outputs ---
    save(fullfile(out_paths.stage1_level, sprintf('map_level_%s.mat', trial_tag)), 'map_level');
    save(fullfile(out_paths.stage1_level, sprintf('map_level_max_%s.txt', trial_tag)), 'map_level_max', '-ascii');
    
    % Visual Map Plot
    fig = figure('Visible', 'off');
    surf(map_level_max); hold on;
    axis equal; view(0, 90); colorbar;
    title(sprintf('%s [%d] Peak Pressure Map', strrep(trial_tag, '_', '\_'), t_idx));
    saveas(fig, fullfile(out_paths.stage1_level, sprintf('mn_%s', trial_tag)), 'jpg');
    close(fig);
    
    success_tags{end+1} = trial_tag; %#ok<AGROW>
    
    if max_calculated
        fprintf('OK (%d frames) [INFO: Max Image dihitung otomatis dari Roll Off 3D matrix]\n', frame);
    else
        fprintf('OK (%d frames)\n', frame);
    end
end

end

% =========================================================================
% HELPER FUNCTIONS
% =========================================================================

function [matched_name, file_size] = match_file(file_list, struct_list, patterns)
    matched_name = '';
    file_size = 0;
    for p = 1:length(patterns)
        idx = find(~cellfun(@isempty, regexpi(file_list, patterns{p})), 1);
        if ~isempty(idx)
            matched_name = file_list{idx};
            file_size    = struct_list(idx).bytes;
            return;
        end
    end
end

function [cop_data, detected_side, grid_dims] = parse_cop_file(cop_path, configured_side)
    cop_data = [];
    detected_side = 'L'; % Default
    grid_dims = struct('width', 21, 'length', 39, 'bottom', 17, 'left', 15);
    
    fid = fopen(cop_path, 'r');
    if fid == -1, return; end
    
    lines = {};
    while ~feof(fid)
        tline = fgetl(fid);
        if ischar(tline)
            lines{end+1} = strtrim(tline); %#ok<AGROW>
        end
    end
    fclose(fid);
    
    if isempty(lines), return; end
    
    % Scan for foot data sections
    left_sec_idx  = find(~cellfun(@isempty, regexpi(lines, 'Left\s+foot\s+data')), 1);
    right_sec_idx = find(~cellfun(@isempty, regexpi(lines, 'Right\s+foot\s+data')), 1);
    
    % Decide target start line
    target_start = 1;
    if strcmpi(configured_side, 'R')
        if ~isempty(right_sec_idx)
            target_start = right_sec_idx;
            detected_side = 'R';
        end
    elseif strcmpi(configured_side, 'L')
        if ~isempty(left_sec_idx)
            target_start = left_sec_idx;
            detected_side = 'L';
        end
    else
        % AUTO mode: detect based on which section has active rectangle or non-zero data
        has_right_active = false;
        if ~isempty(right_sec_idx)
            for k = right_sec_idx:min(length(lines), right_sec_idx + 15)
                if ~isempty(regexpi(lines{k}, 'Rectangle\s+width')) && k < length(lines)
                    w = str2double(lines{k+1});
                    if ~isnan(w) && w > 0, has_right_active = true; end
                end
            end
        end
        if has_right_active
            target_start = right_sec_idx;
            detected_side = 'R';
        elseif ~isempty(left_sec_idx)
            target_start = left_sec_idx;
            detected_side = 'L';
        elseif ~isempty(right_sec_idx)
            target_start = right_sec_idx;
            detected_side = 'R';
        end
    end
    
    % Extract rectangle dimensions from target_start onwards
    for i = target_start:min(length(lines), target_start + 25)
        if ~isempty(regexpi(lines{i}, 'Rectangle\s+width')) && i < length(lines)
            w_val = str2double(lines{i+1});
            if ~isnan(w_val) && w_val > 0, grid_dims.width = w_val; end
        elseif ~isempty(regexpi(lines{i}, 'Rectangle\s+height')) && i < length(lines)
            h_val = str2double(lines{i+1});
            if ~isnan(h_val) && h_val > 0, grid_dims.length = h_val; end
        elseif ~isempty(regexpi(lines{i}, 'Rectangle\s+bottom')) && i < length(lines)
            b_val = str2double(lines{i+1});
            if ~isnan(b_val) && b_val > 0, grid_dims.bottom = b_val; end
        elseif ~isempty(regexpi(lines{i}, 'Rectangle\s+left')) && i < length(lines)
            l_val = str2double(lines{i+1});
            if ~isnan(l_val) && l_val > 0, grid_dims.left = l_val; end
        end
    end
    
    % Find table header "Frame" from target_start
    frame_header_idx = [];
    for k = target_start:length(lines)
        if ~isempty(regexpi(lines{k}, '^Frame\s+')) || ~isempty(regexpi(lines{k}, '^Frame\t'))
            frame_header_idx = k;
            break;
        end
    end
    
    if isempty(frame_header_idx)
        % Fallback: find any line containing 'Frame' and 'Force'
        for k = target_start:length(lines)
            if ~isempty(regexpi(lines{k}, 'Frame')) && ~isempty(regexpi(lines{k}, 'Force'))
                frame_header_idx = k;
                break;
            end
        end
    end
    
    if isempty(frame_header_idx)
        return;
    end
    
    % Read numeric rows
    rows = [];
    for k = (frame_header_idx + 1):length(lines)
        ln = lines{k};
        if isempty(ln), break; end
        % If hit another section header, stop
        if ~isempty(regexpi(ln, '(Left|Right)\s+foot\s+data')), break; end
        
        vals = str2num(ln); %#ok<ST2NM>
        if ~isempty(vals)
            rows = [rows; vals]; %#ok<AGROW>
        end
    end
    
    cop_data = rows;
end

function [map_level, num_frames] = parse_roll_off_file(roll_path, is_right, grid_dims, expected_frames, configured_side)
    map_level = [];
    num_frames = 0;
    
    fid = fopen(roll_path, 'r');
    if fid == -1, return; end
    
    lines = {};
    while ~feof(fid)
        tline = fgetl(fid);
        if ischar(tline)
            lines{end+1} = strtrim(tline); %#ok<AGROW>
        end
    end
    fclose(fid);
    
    if isempty(lines), return; end
    
    % Check for section splits: 'Left foot data' / 'Right foot data'
    left_sec_idx  = find(~cellfun(@isempty, regexpi(lines, 'Left\s+foot\s+data')), 1);
    right_sec_idx = find(~cellfun(@isempty, regexpi(lines, 'Right\s+foot\s+data')), 1);
    
    % Check for frame tags like 'Left Foot Frame \d+' vs 'Right Foot Frame \d+'
    has_left_frame_tag  = any(~cellfun(@isempty, regexpi(lines, '^Left\s+Foot\s+Frame')));
    has_right_frame_tag = any(~cellfun(@isempty, regexpi(lines, '^Right\s+Foot\s+Frame')));
    
    is_paired_roll = (~isempty(left_sec_idx) && ~isempty(right_sec_idx)) || (has_left_frame_tag && has_right_frame_tag);
    
    start_line = 1;
    end_line   = length(lines);
    
    if is_paired_roll
        if strcmpi(configured_side, 'R')
            if ~isempty(right_sec_idx)
                start_line = right_sec_idx;
            end
        else
            if ~isempty(left_sec_idx)
                start_line = left_sec_idx;
                if ~isempty(right_sec_idx) && right_sec_idx > left_sec_idx
                    end_line = right_sec_idx - 1;
                end
            end
        end
    end
    
    subset_lines = lines(start_line:end_line);
    
    if is_paired_roll && has_right_frame_tag && strcmpi(configured_side, 'R')
        frame_header_indices = find(~cellfun(@isempty, regexpi(subset_lines, '^(Right\s+Foot\s+)?Frame\s+\d+')));
    elseif is_paired_roll && has_left_frame_tag && ~strcmpi(configured_side, 'R')
        frame_header_indices = find(~cellfun(@isempty, regexpi(subset_lines, '^(Left\s+Foot\s+)?Frame\s+\d+')));
    else
        frame_header_indices = find(~cellfun(@isempty, regexpi(subset_lines, '^Frame\s+\d+')));
    end
    
    if isempty(frame_header_indices)
        frame_header_indices = find(~cellfun(@isempty, regexpi(subset_lines, 'Frame\s+\d+')));
    end
    
    if isempty(frame_header_indices)
        return;
    end
    
    % Determine matrix length per frame
    if length(frame_header_indices) >= 2
        row_count = 0;
        for r = (frame_header_indices(1) + 1):(frame_header_indices(2) - 1)
            v = str2num(subset_lines{r}); %#ok<ST2NM>
            if ~isempty(v)
                row_count = row_count + 1;
            end
        end
        if row_count > 0
            map_len = row_count;
        else
            map_len = grid_dims.length;
        end
    else
        map_len = grid_dims.length;
    end
    
    num_total_frames = length(frame_header_indices);
    if expected_frames > 0
        num_to_read = min(num_total_frames, expected_frames);
    else
        num_to_read = num_total_frames;
    end
    
    first_f_start = frame_header_indices(1) + 1;
    first_row_v = str2num(subset_lines{first_f_start}); %#ok<ST2NM>
    if ~isempty(first_row_v)
        map_wid = length(first_row_v);
    else
        map_wid = grid_dims.width;
    end
    
    map_level = zeros(map_len, map_wid, num_to_read);
    
    for f_i = 1:num_to_read
        start_idx = frame_header_indices(f_i) + 1;
        a = zeros(map_len, map_wid);
        curr_row = 1;
        
        for l_idx = start_idx:length(subset_lines)
            if curr_row > map_len, break; end
            if ~isempty(regexpi(subset_lines{l_idx}, 'Frame\s+\d+')), break; end
            
            row_v = str2num(subset_lines{l_idx}); %#ok<ST2NM>
            if ~isempty(row_v)
                valid_w = min(map_wid, length(row_v));
                a(curr_row, 1:valid_w) = row_v(1:valid_w);
                curr_row = curr_row + 1;
            end
        end
        
        if is_right
            a = fliplr(a);
        end
        
        map_level(:, :, f_i) = a;
    end
    
    num_frames = size(map_level, 3);
end

function [map_level_max] = parse_max_image_file(max_path, is_right, fallback_len, fallback_wid, configured_side)
    map_level_max = [];
    fid = fopen(max_path, 'r');
    if fid == -1, return; end
    
    lines = {};
    while ~feof(fid)
        tline = fgetl(fid);
        if ischar(tline)
            lines{end+1} = strtrim(tline); %#ok<AGROW>
        end
    end
    fclose(fid);
    
    if isempty(lines), return; end
    
    left_sec_idx  = find(~cellfun(@isempty, regexpi(lines, '(pressure\s+frame\s+Left|Left\s+rectangle|Left\s+foot)')), 1);
    right_sec_idx = find(~cellfun(@isempty, regexpi(lines, '(pressure\s+frame\s+Right|Right\s+rectangle|Right\s+foot)')), 1);
    
    start_line = 1;
    end_line   = length(lines);
    if strcmpi(configured_side, 'R')
        if ~isempty(right_sec_idx)
            start_line = right_sec_idx;
        end
    else
        if ~isempty(left_sec_idx)
            start_line = left_sec_idx;
            if ~isempty(right_sec_idx) && right_sec_idx > left_sec_idx
                end_line = right_sec_idx - 1;
            end
        end
    end
    
    subset_lines = lines(start_line:end_line);
    
    matrix_rows = [];
    for k = 1:length(subset_lines)
        ln = subset_lines{k};
        vals = str2num(ln); %#ok<ST2NM>
        if length(vals) >= 8 || length(vals) == fallback_wid
            matrix_rows = [matrix_rows; vals]; %#ok<AGROW>
        end
    end
    
    if ~isempty(matrix_rows) && size(matrix_rows, 1) >= 10
        if is_right
            matrix_rows = fliplr(matrix_rows);
        end
        map_level_max = matrix_rows;
    end
end
