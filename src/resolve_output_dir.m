function [out_paths] = resolve_output_dir(base_dir, subject_name, exec_date)
% RESOLVE_OUTPUT_DIR - Smart Output Directory Resolution with Fallback
%
% Determines the structured destination folder for RSscan processing:
% 1. Formats folder name as: <subject_name>_<YYYYMMDD>
% 2. Detects folder contents and handles fallbacks automatically:
%    - If target folder is empty -> uses <base_dir>/<folder_name>
%    - If target contains files & no output -> creates <base_dir>/output/<folder_name>
%    - If target already has previous analysis results -> moves to parent folder
%      and routes to parent/output/<folder_name>
% 3. Prepares standard stage subfolders (1_step_level to 6_group)

if nargin < 2 || isempty(subject_name)
    subject_name = 'RSscan_Batch';
end
if nargin < 3 || isempty(exec_date)
    exec_date = datestr(now, 'yyyymmdd');
end
if nargin < 1 || isempty(base_dir)
    % Default to root result folder
    root_script_dir = fileparts(fileparts(mfilename('fullpath')));
    base_dir = fullfile(root_script_dir, 'output');
end

target_folder_name = sprintf('%s_%s', subject_name, exec_date);

% Ensure base directory exists
if ~exist(base_dir, 'dir')
    mkdir(base_dir);
end

% Inspect contents of base_dir
dir_items = dir(base_dir);
% Filter out '.' and '..'
valid_items = dir_items(~ismember({dir_items.name}, {'.', '..'}));

[~, current_folder_name] = fileparts(base_dir);
is_already_in_output = strcmpi(current_folder_name, 'output');

% Check if base_dir already contains previous RSscan stage results directly
stage_indicators = {'1_step_level', '2_step_get_xy', '3_step_value', '4_step_start_end', '5_foot', '6_group'};
has_existing_stage_results = any(ismember({valid_items.name}, stage_indicators));

if isempty(valid_items)
    % Case 1: Folder is completely empty -> use directly
    final_subject_dir = fullfile(base_dir, target_folder_name);
elseif is_already_in_output
    % Case 2: Already inside an 'output' folder -> place target_folder_name here
    final_subject_dir = fullfile(base_dir, target_folder_name);
elseif has_existing_stage_results
    % Case 3: Folder already has previous analysis results directly inside it
    % Move 1 level up to parent and ensure output/<target_folder_name> is used
    parent_dir = fileparts(base_dir);
    parent_output_dir = fullfile(parent_dir, 'output');
    if ~exist(parent_output_dir, 'dir')
        mkdir(parent_output_dir);
    end
    final_subject_dir = fullfile(parent_output_dir, target_folder_name);
else
    % Case 4: Folder has files/data but no direct results or output folder
    output_subdir = fullfile(base_dir, 'output');
    if ~exist(output_subdir, 'dir')
        mkdir(output_subdir);
    end
    final_subject_dir = fullfile(output_subdir, target_folder_name);
end

% Build full subfolder hierarchy
out_paths = struct();
out_paths.root          = final_subject_dir;
out_paths.stage1_level  = fullfile(final_subject_dir, '1_step_level');
out_paths.stage2_xy     = fullfile(final_subject_dir, '2_step_get_xy');
out_paths.stage3_value  = fullfile(final_subject_dir, '3_step_value');
out_paths.stage3_fap    = fullfile(final_subject_dir, '3_step_value', 'data_f_a_p');
out_paths.stage3_inval_L= fullfile(final_subject_dir, '3_step_value', 'inbox_value_L');
out_paths.stage3_inval_R= fullfile(final_subject_dir, '3_step_value', 'inbox_value_R');
out_paths.stage3_inxy_L = fullfile(final_subject_dir, '3_step_value', 'inbox_xy_L');
out_paths.stage3_inxy_R = fullfile(final_subject_dir, '3_step_value', 'inbox_xy_R');
out_paths.stage3_matrix = fullfile(final_subject_dir, '3_step_value', 'p_f_matrix');
out_paths.stage3_jpg    = fullfile(final_subject_dir, '3_step_value', 'jpg');
out_paths.stage4_timing = fullfile(final_subject_dir, '4_step_start_end');
out_paths.stage5_foot   = fullfile(final_subject_dir, '5_foot');
out_paths.stage5_fap    = fullfile(final_subject_dir, '5_foot', 'force_area_pressure');
out_paths.stage5_timing = fullfile(final_subject_dir, '5_foot', 'start_end');
out_paths.stage6_group  = fullfile(final_subject_dir, '6_group');

% Create all destination directories
subfields = fieldnames(out_paths);
for k = 1:length(subfields)
    dir_path = out_paths.(subfields{k});
    if ~exist(dir_path, 'dir')
        mkdir(dir_path);
    end
end

end
