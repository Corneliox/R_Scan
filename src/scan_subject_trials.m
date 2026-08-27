function [subjects_info] = scan_subject_trials(raw_base_dir, subject_filter)
% SCAN_SUBJECT_TRIALS - Dynamically scans and discovers all available subjects and trials
%
% Inputs:
%   raw_base_dir   - Path to rawdata_rs containing 'L' and/or 'R' subdirectories
%   subject_filter - Optional cell array of specific subject IDs (e.g. {'R_t000', 'L_t063'})
%                    If empty or omitted, all discovered subjects are processed.
%
% Output:
%   subjects_info  - Array of structures:
%                    .id          : Full ID string, e.g. 'R_t000'
%                    .side        : 'R' or 'L'
%                    .folder_t    : 't000'
%                    .folder_path : Full path to subject folder
%                    .trial_nums  : Vector of available trial numbers [1, 2, 3, ...]
%                    .trial_tags  : Cell array of trial identifiers, e.g. {'R_t000_1', 'R_t000_2'}

if nargin < 2
    subject_filter = {};
end

subjects_info = struct('id', {}, 'side', {}, 'folder_t', {}, 'folder_path', {}, 'trial_nums', {}, 'trial_tags', {});

if ~exist(raw_base_dir, 'dir')
    warning('Raw directory not found: %s', raw_base_dir);
    return;
end

sides = {'R', 'L'};
sub_count = 0;

for s = 1:length(sides)
    current_side = sides{s};
    side_dir = fullfile(raw_base_dir, current_side);
    
    if ~exist(side_dir, 'dir')
        % Try case where raw_base_dir itself contains 't0xx' directly
        side_dir = raw_base_dir;
        current_side = '';
    end
    
    dir_entries = dir(side_dir);
    dir_folders = dir_entries([dir_entries.isdir] & ~ismember({dir_entries.name}, {'.', '..'}));
    
    for f = 1:length(dir_folders)
        folder_name = dir_folders(f).name;
        
        % Filter only subject folders starting with 't' or numeric
        if ~startsWith(folder_name, 't', 'IgnoreCase', true) && isempty(regexp(folder_name, '^\d+', 'once'))
            continue;
        end
        
        if ~isempty(current_side)
            full_subject_id = sprintf('%s_%s', current_side, folder_name);
        else
            full_subject_id = folder_name;
        end
        
        % Check if filtered
        if ~isempty(subject_filter) && ~ismember(full_subject_id, subject_filter) && ~ismember(folder_name, subject_filter)
            continue;
        end
        
        subj_folder_path = fullfile(side_dir, folder_name);
        
        % Discover all trials by checking files inside subj_folder_path
        trial_files = dir(fullfile(subj_folder_path, '*.xls*'));
        found_trials = [];
        
        for k = 1:length(trial_files)
            fname = trial_files(k).name;
            % Match patterns like:
            % '_1 Centre of Force line.xls' -> trial 1
            % 'Centre of Force line_1.xls'  -> trial 1
            tokens = regexp(fname, '^_(\d+)\s+', 'tokens');
            if isempty(tokens)
                tokens = regexp(fname, '_(\d+)\.(xls|xlsx)$', 'tokens');
            end
            if isempty(tokens)
                tokens = regexp(fname, 'trial\D*(\d+)', 'tokens', 'ignorecase');
            end
            
            if ~isempty(tokens)
                num = str2double(tokens{1}{1});
                if ~isnan(num)
                    found_trials(end+1) = num; %#ok<AGROW>
                end
            end
        end
        
        found_trials = unique(found_trials);
        
        % If no pattern matched, fallback to checking 1..20
        if isempty(found_trials)
            for test_trial = 1:20
                test_file1 = fullfile(subj_folder_path, sprintf('_%d Dynamic Roll off.xls', test_trial));
                test_file2 = fullfile(subj_folder_path, sprintf('Dynamic Roll off_%d.xls', test_trial));
                if exist(test_file1, 'file') || exist(test_file2, 'file')
                    found_trials(end+1) = test_trial; %#ok<AGROW>
                end
            end
        end
        
        if ~isempty(found_trials)
            sub_count = sub_count + 1;
            subjects_info(sub_count).id          = full_subject_id;
            subjects_info(sub_count).side        = current_side;
            subjects_info(sub_count).folder_t    = folder_name;
            subjects_info(sub_count).folder_path = subj_folder_path;
            subjects_info(sub_count).trial_nums  = sort(found_trials);
            
            tags = {};
            for t_idx = 1:length(found_trials)
                tags{end+1} = sprintf('%s_%d', full_subject_id, found_trials(t_idx)); %#ok<AGROW>
            end
            subjects_info(sub_count).trial_tags = tags;
        end
    end
end

end
