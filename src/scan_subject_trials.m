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
    
    % Check if this folder contains paired (bilateral Left & Right foot) measurements
    is_paired = check_if_paired_folder(subj_folder_path, file_names);
    
    if is_paired && strcmpi(default_side, 'AUTO')
        sides_to_add = {'L', 'R'};
    elseif strcmpi(default_side, 'R')
        sides_to_add = {'R'};
    elseif strcmpi(default_side, 'L')
        sides_to_add = {'L'};
    else
        % AUTO single side detection
        if startsWith(folder_name, 'R_', 'IgnoreCase', true)
            sides_to_add = {'R'};
        elseif startsWith(folder_name, 'L_', 'IgnoreCase', true)
            sides_to_add = {'L'};
        else
            sides_to_add = {'AUTO'};
        end
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

function is_paired = check_if_paired_folder(subj_folder_path, file_names)
    is_paired = false;
    
    % Find candidate files to inspect for paired indicators
    cand_pats = {'.*Centre\s*of\s*Force.*\.xls.*', '.*Foot\s*Dimensions.*\.xls.*', '.*Impulse.*\.xls.*', '.*Entire\s*Plate.*\.xls.*'};
    cand_files = {};
    for p = 1:length(cand_pats)
        m = ~cellfun(@isempty, regexpi(file_names, cand_pats{p}));
        cand_files = [cand_files, file_names(m)]; %#ok<AGROW>
    end
    cand_files = unique(cand_files);
    
    for c = 1:length(cand_files)
        fp = fullfile(subj_folder_path, cand_files{c});
        fid = fopen(fp, 'r');
        if fid == -1, continue; end
        
        has_left = false;
        has_right = false;
        line_count = 0;
        
        while ~feof(fid) && line_count < 2500
            tline = fgetl(fid);
            line_count = line_count + 1;
            if ~ischar(tline), continue; end
            
            if ~isempty(regexpi(tline, '(Left\s+foot\s+data|Left\s+Foot\s+Frame|Left\s+rectangle\s+position|pressure\s+frame\s+Left)'))
                has_left = true;
            end
            if ~isempty(regexpi(tline, '(Right\s+foot\s+data|Right\s+Foot\s+Frame|Right\s+rectangle\s+position|pressure\s+frame\s+Right)'))
                has_right = true;
            end
            if has_left && has_right
                is_paired = true;
                break;
            end
        end
        fclose(fid);
        
        if is_paired, return; end
    end
end
