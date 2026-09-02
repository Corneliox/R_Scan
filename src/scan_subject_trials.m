function [subjects_info] = scan_subject_trials(raw_base_dir, subject_filter)
% SCAN_SUBJECT_TRIALS - Dynamically scans and discovers all available subjects and trials
%
% Inputs:
%   raw_base_dir   - Path to rawdata_rs containing 'L' and/or 'R' subdirectories, or direct subject folders
%   subject_filter - Optional cell array of specific subject IDs (e.g. {'R_t000', 'L_t063', 't001'})
%                    If empty or omitted, all discovered subjects are processed.
%
% Output:
%   subjects_info  - Array of structures:
%                    .id          : Full ID string, e.g. 'R_t000' or 't001'
%                    .side        : 'R', 'L', or 'AUTO'
%                    .folder_t    : Folder name, e.g. 't000' or 't001'
%                    .folder_path : Full path to subject folder
%                    .trial_nums  : Vector of available trial numbers [1, 2, 3, ...]
%                    .trial_tags  : Cell array of trial identifiers, e.g. {'R_t000_1', 't001_1'}

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
    % Flat directory structure: run scanning EXACTLY ONCE
    scan_configs = struct('side', 'AUTO', 'dir', raw_base_dir);
end

sub_count = 0;

for c_idx = 1:length(scan_configs)
    current_side = scan_configs(c_idx).side;
    target_dir   = scan_configs(c_idx).dir;
    
    dir_entries = dir(target_dir);
    dir_folders = dir_entries([dir_entries.isdir] & ~ismember({dir_entries.name}, {'.', '..'}));
    
    for f = 1:length(dir_folders)
        folder_name = dir_folders(f).name;
        
        % Filter only subject folders (starting with 't', 'R', 'L', or numeric)
        is_subj_name = startsWith(folder_name, 't', 'IgnoreCase', true) || ...
                       startsWith(folder_name, 'R_', 'IgnoreCase', true) || ...
                       startsWith(folder_name, 'L_', 'IgnoreCase', true) || ...
                       ~isempty(regexp(folder_name, '^\d+', 'once'));
        if ~is_subj_name
            continue;
        end
        
        % Determine Subject ID and Side
        effective_side = current_side;
        if strcmpi(current_side, 'AUTO')
            if startsWith(folder_name, 'R_', 'IgnoreCase', true)
                effective_side = 'R';
                full_subject_id = folder_name;
            elseif startsWith(folder_name, 'L_', 'IgnoreCase', true)
                effective_side = 'L';
                full_subject_id = folder_name;
            else
                effective_side = 'AUTO';
                full_subject_id = folder_name;
            end
        else
            full_subject_id = sprintf('%s_%s', current_side, folder_name);
        end
        
        % Apply subject filter if specified
        if ~isempty(subject_filter)
            if ~ismember(full_subject_id, subject_filter) && ...
               ~ismember(folder_name, subject_filter) && ...
               ~ismember(strrep(full_subject_id, 'AUTO_', ''), subject_filter)
                continue;
            end
        end
        
        subj_folder_path = fullfile(target_dir, folder_name);
        
        % Discover all trials using flexible regex matching across files in folder
        folder_files = dir(subj_folder_path);
        file_names   = {folder_files(~[folder_files.isdir]).name};
        found_trials = [];
        
        for k = 1:length(file_names)
            fname = file_names{k};
            
            % Match patterns like:
            % '_1 Centre of Force line.xls', '1 Centre of Force.xls', '_1 Dynamic Roll off.xls'
            % 'Centre of Force line_1.xls', 'Dynamic Maximum  Imagexx_2.xls'
            % 'trial_1.xls', 'trial1.xls'
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
        
        % Fallback scan for numbers 1 to 20 if no trials were extracted via regex
        if isempty(found_trials)
            for test_trial = 1:20
                pat = sprintf('^(_)?%d\\s*Dynamic\\s*Roll.*\\.(xls|xlsx)$', test_trial);
                matched = ~cellfun(@isempty, regexpi(file_names, pat));
                if any(matched)
                    found_trials(end+1) = test_trial; %#ok<AGROW>
                end
            end
        end
        
        if ~isempty(found_trials)
            sub_count = sub_count + 1;
            subjects_info(sub_count).id          = full_subject_id;
            subjects_info(sub_count).side        = effective_side;
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
end

end
