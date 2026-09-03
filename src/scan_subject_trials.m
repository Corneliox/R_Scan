function [subjects_info] = scan_subject_trials(raw_base_dir, subject_filter)
% SCAN_SUBJECT_TRIALS - Dynamically scans and discovers all available subjects and trials
%
% Inputs:
%   raw_base_dir   - Path to rawdata containing 'L' and/or 'R' subdirectories, direct subject folders,
%                    or even a single subject directory directly.
%   subject_filter - Optional cell array of specific subject IDs (e.g. {'R_t000', 'L_t063', 't001'})
%                    If empty or omitted, all discovered subjects are processed.
%
% Output:
%   subjects_info  - Array of structures:
%                    .id          : Full ID string, e.g. 'R_t000', 'L_t000', 'R_subject1'
%                    .side        : 'R', 'L', or 'AUTO'
%                    .folder_t    : Folder name
%                    .folder_path : Full path to subject folder
%                    .trial_nums  : Vector of available trial numbers [1, 2, 3, ...]
%                    .trial_tags  : Cell array of trial identifiers, e.g. {'R_t000_1', 'L_t000_1'}

if nargin < 2
    subject_filter = {};
end
if ischar(subject_filter) && ~isempty(subject_filter)
    subject_filter = {subject_filter};
end

subjects_info = struct('id', {}, 'side', {}, 'folder_t', {}, 'folder_path', {}, 'trial_nums', {}, 'trial_tags', {});

if ~exist(raw_base_dir, 'dir')
    warning('Raw directory not found: %s', raw_base_dir);
    return;
end

% Check if raw_base_dir itself directly contains measurement files
direct_files = dir(fullfile(raw_base_dir, '*.xls*'));
is_direct_subject = false;
for k = 1:length(direct_files)
    fn = direct_files(k).name;
    if ~isempty(regexpi(fn, 'Roll\s*off|Centre\s*of\s*Force|Dynamic\s*Max|Foot\s*Dimensions|Impulse'))
        is_direct_subject = true;
        break;
    end
end

if is_direct_subject
    % raw_base_dir is itself the subject folder
    [~, folder_name] = fileparts(raw_base_dir);
    if isempty(folder_name), folder_name = 'Subject'; end
    subjects_info = process_single_folder(raw_base_dir, folder_name, 'AUTO', subject_filter, subjects_info);
    return;
end

% 1. Detect directory structure: Check whether 'L' or 'R' subdirectories exist
has_R = exist(fullfile(raw_base_dir, 'R'), 'dir') == 7;
has_L = exist(fullfile(raw_base_dir, 'L'), 'dir') == 7;

if has_R || has_L
    scan_configs = struct('side', {}, 'dir', {});
    if has_R
        scan_configs(end+1) = struct('side', 'R', 'dir', fullfile(raw_base_dir, 'R'));
    end
    if has_L
        scan_configs(end+1) = struct('side', 'L', 'dir', fullfile(raw_base_dir, 'L'));
    end
else
    % Flat directory structure: run scanning on raw_base_dir
    scan_configs = struct('side', 'AUTO', 'dir', raw_base_dir);
end

for c_idx = 1:length(scan_configs)
    current_side = scan_configs(c_idx).side;
    target_dir   = scan_configs(c_idx).dir;
    
    dir_entries = dir(target_dir);
    dir_folders = dir_entries([dir_entries.isdir] & ~ismember({dir_entries.name}, {'.', '..'}));
    
    for f = 1:length(dir_folders)
        folder_name = dir_folders(f).name;
        subj_folder_path = fullfile(target_dir, folder_name);
        
        % Early filter check to avoid disk I/O on unselected subjects
        if ~isempty(subject_filter)
            candidate_ids = {folder_name, sprintf('%s_%s', current_side, folder_name), sprintf('R_%s', folder_name), sprintf('L_%s', folder_name)};
            if isempty(intersect(candidate_ids, subject_filter))
                continue;
            end
        end
        
        % Check if folder has relevant measurement files
        folder_xls = dir(fullfile(subj_folder_path, '*.xls*'));
        if isempty(folder_xls)
            continue;
        end
        
        subjects_info = process_single_folder(subj_folder_path, folder_name, current_side, subject_filter, subjects_info);
    end
end

end

% =========================================================================
% HELPER FUNCTIONS
% =========================================================================

function [subjects_info] = process_single_folder(subj_folder_path, folder_name, default_side, subject_filter, subjects_info)
    folder_files = dir(subj_folder_path);
    file_names   = {folder_files(~[folder_files.isdir]).name};
    found_trials = [];
    
    for k = 1:length(file_names)
        fname = file_names{k};
        
        tokens = regexp(fname, '^(_)?(\d+)\s+', 'tokens');
        if isempty(tokens)
            tokens = regexp(fname, '[_\s](\d+)\.(xls|xlsx)$', 'tokens');
        end
        if isempty(tokens)
            tokens = regexp(fname, 'trial\D*(\d+)', 'tokens', 'ignorecase');
        end
        if isempty(tokens)
            tokens = regexp(fname, '^(\d+)_', 'tokens');
        end
        
        if ~isempty(tokens)
            if iscell(tokens{1}) && length(tokens{1}) >= 2
                num = str2double(tokens{1}{2});
            else
                num = str2double(tokens{1}{1});
            end
            if ~isnan(num) && num > 0
                found_trials(end+1) = num; %#ok<AGROW>
            end
        end
    end
    
    found_trials = unique(found_trials);
    
    if isempty(found_trials)
        for test_trial = 1:20
            pat = sprintf('^(_)?%d\\s*Dynamic\\s*Roll.*\\.(xls|xlsx)$', test_trial);
            matched = ~cellfun(@isempty, regexpi(file_names, pat));
            if any(matched)
                found_trials(end+1) = test_trial; %#ok<AGROW>
            end
        end
    end
    
    if isempty(found_trials)
        return;
    end
    
    % Detect foot laterality directly from Excel file headers
    detected_sides = detect_sides_from_excel_files(subj_folder_path, file_names);
    
    if strcmpi(default_side, 'R')
        sides_to_add = {'R'};
    elseif strcmpi(default_side, 'L')
        sides_to_add = {'L'};
    elseif startsWith(folder_name, 'R_', 'IgnoreCase', true)
        sides_to_add = {'R'};
    elseif startsWith(folder_name, 'L_', 'IgnoreCase', true)
        sides_to_add = {'L'};
    elseif ~isempty(detected_sides)
        sides_to_add = detected_sides;
    else
        sides_to_add = {'AUTO'};
    end
    
    clean_folder_name = folder_name;
    if startsWith(clean_folder_name, 'R_', 'IgnoreCase', true) || startsWith(clean_folder_name, 'L_', 'IgnoreCase', true)
        clean_folder_name = clean_folder_name(3:end);
    end
    
    for s_i = 1:length(sides_to_add)
        side = sides_to_add{s_i};
        if strcmpi(side, 'AUTO')
            full_subject_id = folder_name;
        else
            full_subject_id = sprintf('%s_%s', side, clean_folder_name);
        end
        
        % Check filter
        if ~isempty(subject_filter)
            if ~ismember(full_subject_id, subject_filter) && ...
               ~ismember(folder_name, subject_filter) && ...
               ~ismember(strrep(full_subject_id, 'AUTO_', ''), subject_filter)
                continue;
            end
        end
        
        sub_count = length(subjects_info) + 1;
        subjects_info(sub_count).id          = full_subject_id;
        subjects_info(sub_count).side        = side;
        subjects_info(sub_count).folder_t    = folder_name;
        subjects_info(sub_count).folder_path = subj_folder_path;
        subjects_info(sub_count).trial_nums  = sort(found_trials);
        
        tags = cell(1, length(found_trials));
        for t_idx = 1:length(found_trials)
            tags{t_idx} = sprintf('%s_%d', full_subject_id, found_trials(t_idx));
        end
        subjects_info(sub_count).trial_tags = tags;
    end
end

function [detected_sides] = detect_sides_from_excel_files(subj_folder_path, file_names)
    detected_sides = {};
    
    cand_pats = {
        '.*Centre\s*of\s*Force.*\.xls.*', ...
        '.*Dynamic\s*Roll.*\.xls.*', ...
        '.*Foot\s*Dimensions.*\.xls.*', ...
        '.*Impulse.*\.xls.*', ...
        '.*Dynamic\s*Maximum.*\.xls.*'
    };
    cand_files = {};
    for p = 1:length(cand_pats)
        m = ~cellfun(@isempty, regexpi(file_names, cand_pats{p}));
        cand_files = [cand_files, file_names(m)]; %#ok<AGROW>
    end
    cand_files = unique(cand_files);
    
    has_left = false;
    has_right = false;
    
    for c = 1:length(cand_files)
        fp = fullfile(subj_folder_path, cand_files{c});
        fid = fopen(fp, 'r');
        if fid == -1, continue; end
        
        lines = {};
        while ~feof(fid) && length(lines) < 200
            tline = fgetl(fid);
            if ischar(tline)
                lines{end+1} = strtrim(tline); %#ok<AGROW>
            end
        end
        fclose(fid);
        
        if isempty(lines), continue; end
        
        % Check for Left foot data
        left_idx = find(~cellfun(@isempty, regexpi(lines, '(Left\s+foot\s+data|Left\s+rectangle\s+position|Left\s+Foot\s+Frame|pressure\s+frame\s+Left)')), 1);
        if ~isempty(left_idx)
            l_active = false;
            for k = left_idx:min(length(lines), left_idx + 15)
                if ~isempty(regexpi(lines{k}, 'Rectangle\s+width')) && k < length(lines)
                    w = str2double(lines{k+1});
                    if ~isnan(w) && w > 0, l_active = true; end
                end
            end
            if l_active || isempty(find(~cellfun(@isempty, regexpi(lines, 'Rectangle\s+width')), 1))
                has_left = true;
            end
        end
        
        % Check for Right foot data
        right_idx = find(~cellfun(@isempty, regexpi(lines, '(Right\s+foot\s+data|Right\s+rectangle\s+position|Right\s+Foot\s+Frame|pressure\s+frame\s+Right)')), 1);
        if ~isempty(right_idx)
            r_active = false;
            for k = right_idx:min(length(lines), right_idx + 15)
                if ~isempty(regexpi(lines{k}, 'Rectangle\s+width')) && k < length(lines)
                    w = str2double(lines{k+1});
                    if ~isnan(w) && w > 0, r_active = true; end
                end
            end
            if r_active || isempty(find(~cellfun(@isempty, regexpi(lines, 'Rectangle\s+width')), 1))
                has_right = true;
            end
        end
        
        if has_left && has_right, break; end
    end
    
    if has_left && has_right
        detected_sides = {'L', 'R'};
    elseif has_right
        detected_sides = {'R'};
    elseif has_left
        detected_sides = {'L'};
    end
end
