function [success_tags] = stage1_extract_3d_cop(subject_info, out_paths)
% STAGE1_EXTRACT_3D_COP - Parses RSscan TSV exports into 3D Spatio-Temporal Matrix & COP
%
% Inputs:
%   subject_info - Structure containing subject folder & available trials from scan_subject_trials
%   out_paths    - Structure of destination paths from resolve_output_dir
%
% Output:
%   success_tags - Cell array of successfully processed trial tags (e.g. {'R_t000_1', ...})

success_tags = {};
subj_folder = subject_info.folder_path;
side        = subject_info.side;
is_right    = strcmpi(side, 'R');

for t_idx = 1:length(subject_info.trial_nums)
    trial_num = subject_info.trial_nums(t_idx);
    trial_tag = sprintf('%s_%d', subject_info.id, trial_num);
    
    fprintf('   [Stage 1] Processing trial: %s ... ', trial_tag);
    
    % Candidate filenames (support both standard and legacy prefixes)
    cop_candidates = {
        fullfile(subj_folder, sprintf('_%d Centre of Force line.xls', trial_num)), ...
        fullfile(subj_folder, sprintf('Centre of Force line_%d.xls', trial_num)), ...
        fullfile(subj_folder, sprintf('_%d Centre of Force line.xlsx', trial_num)), ...
        fullfile(subj_folder, sprintf('Centre of Force line_%d.xlsx', trial_num))
    };
    
    roll_candidates = {
        fullfile(subj_folder, sprintf('_%d Dynamic Roll off.xls', trial_num)), ...
        fullfile(subj_folder, sprintf('Dynamic Roll off_%d.xls', trial_num)), ...
        fullfile(subj_folder, sprintf('_%d Dynamic Roll off.xlsx', trial_num)), ...
        fullfile(subj_folder, sprintf('Dynamic Roll off_%d.xlsx', trial_num))
    };
    
    max_candidates = {
        fullfile(subj_folder, sprintf('_%d Dynamic Maximum  Image.xls', trial_num)), ...
        fullfile(subj_folder, sprintf('_%d Dynamic Maximum Image.xls', trial_num)), ...
        fullfile(subj_folder, sprintf('Dynamic Maximum  Image_%d.xls', trial_num)), ...
        fullfile(subj_folder, sprintf('Dynamic Maximum Image_%d.xls', trial_num)), ...
        fullfile(subj_folder, sprintf('_%d Dynamic Maximum Image.xlsx', trial_num))
    };
    
    cop_path = '';
    for k = 1:length(cop_candidates)
        if exist(cop_candidates{k}, 'file')
            cop_path = cop_candidates{k}; break;
        end
    end
    
    roll_path = '';
    for k = 1:length(roll_candidates)
        if exist(roll_candidates{k}, 'file')
            roll_path = roll_candidates{k}; break;
        end
    end
    
    max_path = '';
    for k = 1:length(max_candidates)
        if exist(max_candidates{k}, 'file')
            max_path = max_candidates{k}; break;
        end
    end
    
    if isempty(cop_path) || isempty(roll_path) || isempty(max_path)
        fprintf('SKIPPED (File .xls tidak lengkap)\n');
        continue;
    end
    
    % --- 1. Parse COP Line ---
    cop_fid = fopen(cop_path, 'r');
    if cop_fid == -1
        fprintf('SKIPPED (Gagal buka COP file)\n');
        continue;
    end
    for i = 1:18, fgetl(cop_fid); end
    yy = [];
    t_str = fgetl(cop_fid);
    while ischar(t_str) && ~isempty(t_str)
        row_vals = str2num(t_str); %#ok<ST2NM>
        if ~isempty(row_vals)
            yy = [yy; row_vals]; %#ok<AGROW>
        end
        t_str = fgetl(cop_fid);
    end
    fclose(cop_fid);
    
    if isempty(yy) || size(yy, 2) < 5
        fprintf('SKIPPED (Data COP kosong)\n');
        continue;
    end
    
    yy_fz = yy(:, 5);
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
    else
        frame = 0;
    end
    
    if frame <= 0
        fprintf('SKIPPED (Tidak ada frame aktif)\n');
        continue;
    end
    
    % --- 2. Parse Max Image Header ---
    max_fid = fopen(max_path, 'r');
    for i = 1:13, fgetl(max_fid); end
    map_width = str2num(fgetl(max_fid)); %#ok<ST2NM>
    fgetl(max_fid);
    map_length = str2num(fgetl(max_fid)); %#ok<ST2NM>
    fclose(max_fid);
    
    if isempty(map_width) || isempty(map_length)
        map_width = 32; map_length = 64; % Default sensor grid fallback
    end
    
    % --- 3. Parse Dynamic Roll Off ---
    roll_fid = fopen(roll_path, 'r');
    for i = 1:18, fgetl(roll_fid); end
    
    map_level = zeros(map_length, map_width, frame);
    x_cop_raw = zeros(frame, 1);
    y_cop_raw = zeros(frame, 1);
    
    for i = 1:frame
        a = zeros(map_length, map_width);
        for j = 1:map_length
            line_str = fgetl(roll_fid);
            if ~ischar(line_str), break; end
            vals = str2num(line_str); %#ok<ST2NM>
            if ~isempty(vals)
                a(j, 1:min(map_width, length(vals))) = vals(1:min(map_width, length(vals)));
            end
        end
        
        if is_right
            a = fliplr(a);
        end
        
        sum_a = sum(a(:));
        if sum_a > 0
            cop_xi = sum(sum(a, 1)' .* (1:map_width)') / sum_a;
            cop_yi = sum(sum(a, 2)  .* (1:map_length)') / sum_a;
        else
            cop_xi = 0; cop_yi = 0;
        end
        
        % Skip 2 delimiter lines in roll off
        for k = 1:2, fgetl(roll_fid); end
        
        x_cop_raw(i, 1) = cop_xi;
        y_cop_raw(i, 1) = cop_yi;
        map_level(:, :, i) = a;
    end
    fclose(roll_fid);
    
    map_level_max = max(map_level, [], 3);
    
    % --- 4. Save Outputs ---
    save(fullfile(out_paths.stage1_level, ['map_level_', trial_tag, '.mat']), 'map_level');
    save(fullfile(out_paths.stage1_level, ['map_level_max_', trial_tag, '.txt']), 'map_level_max', '-ascii');
    
    % Render & Save Visual Plot
    fig = figure('Visible', 'off');
    surf(map_level_max); hold on;
    axis equal; view(0, 90); colorbar;
    title(sprintf('%s [%d] Peak Pressure Map', strrep(trial_tag, '_', '\_'), t_idx));
    saveas(fig, fullfile(out_paths.stage1_level, ['mn_', trial_tag]), 'jpg');
    close(fig);
    
    success_tags{end+1} = trial_tag; %#ok<AGROW>
    fprintf('OK (%d frames)\n', frame);
end

end
