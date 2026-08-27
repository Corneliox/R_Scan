function [out_paths, processed_subjects] = main_rscan_pipeline(varargin)
% MAIN_RSCAN_PIPELINE - Unified Master Pipeline for RSscan Plantar Pressure & Gait Analysis
%
% USAGE:
%   main_rscan_pipeline()                             % Runs with default auto-detected paths
%   main_rscan_pipeline('raw_dir', 'path/to/rawdata') % Custom input directory
%   main_rscan_pipeline('output_dir', 'path/to/out')  % Custom base output directory
%   main_rscan_pipeline('subject', {'R_t000', ...})   % Specific subject(s)
%   main_rscan_pipeline('stages', [1:6])              % Specific stage(s)
%   main_rscan_pipeline('bodyweight', 75)             % Bodyweight in kg
%
% PIPELINE STAGES:
%   Stage 1: 3D Spatio-Temporal Matrix & COP Extraction (map_level, map_level_max)
%   Stage 2: 12-Box Geometric Foot Partitioning (xy_box12)
%   Stage 3: 12-Box Regional Force, Area, and Pressure with 101-point Stance Interpolation
%   Stage 4: Contact Timing, Peak Events, and %BW Normalization
%   Stage 5: Multi-Trial Subject Aggregation (N-Trial Mean & Standard Deviation)
%   Stage 6: Cohort Group Analysis by Arch Index & SPSS Matrix Export

clc;
fprintf('=========================================================================\n');
fprintf('   RSSCAN FOOTSCAN PLANTAR PRESSURE & GAIT ANALYSIS PIPELINE             \n');
fprintf('   Unified Modular Processing System                                     \n');
fprintf('=========================================================================\n\n');

% Add src/ directory and subfolders to MATLAB search path
root_dir = fileparts(mfilename('fullpath'));
src_dir  = fullfile(root_dir, 'src');
if exist(src_dir, 'dir')
    addpath(src_dir);
end

% --- 1. Parse Input Parameters ---
p = inputParser;
addParameter(p, 'raw_dir', '', @ischar);
addParameter(p, 'output_dir', '', @ischar);
addParameter(p, 'subject', {}, @(x) iscell(x) || ischar(x));
addParameter(p, 'stages', 1:6, @isnumeric);
addParameter(p, 'bodyweight', 70, @isnumeric);
addParameter(p, 'ratio_c', [30, 20, 20], @isnumeric);
parse(p, varargin{:});

raw_input_dir   = p.Results.raw_dir;
base_output_dir = p.Results.output_dir;
subject_filter  = p.Results.subject;
run_stages      = p.Results.stages;
bodyweight_kg   = p.Results.bodyweight;
ratio_c         = p.Results.ratio_c;

if ischar(subject_filter) && ~isempty(subject_filter)
    subject_filter = {subject_filter};
end

% --- 2. Auto-Detect Raw Data Directory ---
if isempty(raw_input_dir)
    candidate_raw_dirs = {
        fullfile(root_dir, 'rawdata_rs'), ...
        fullfile(root_dir, '20260824_rscop_box_pressure', 'rawdata_rs'), ...
        fullfile(root_dir, 'coba rs scan', 'rawdata_rs')
    };
    for k = 1:length(candidate_raw_dirs)
        if exist(candidate_raw_dirs{k}, 'dir')
            raw_input_dir = candidate_raw_dirs{k};
            break;
        end
    end
end

if isempty(raw_input_dir) || ~exist(raw_input_dir, 'dir')
    error('Directory rawdata_rs tidak ditemukan! Tentukan dengan parameter: main_rscan_pipeline(''raw_dir'', ''path'')');
end

fprintf('1. Direktori Input  : %s\n', raw_input_dir);

% --- 3. Scan Available Subjects & Trials (Dynamic N-Trial Detection) ---
subjects_info = scan_subject_trials(raw_input_dir, subject_filter);

if isempty(subjects_info)
    warning('Tidak ada subjek atau data trial yang ditemukan di: %s', raw_input_dir);
    out_paths = []; processed_subjects = [];
    return;
end

fprintf('2. Subjek Terdeteksi: %d subjek ditemukan:\n', length(subjects_info));
total_trials = 0;
for s = 1:min(5, length(subjects_info))
    fprintf('   - %s (%d trials: %s)\n', subjects_info(s).id, length(subjects_info(s).trial_nums), num2str(subjects_info(s).trial_nums));
end
if length(subjects_info) > 5
    fprintf('   - ... dan %d subjek lainnya.\n', length(subjects_info) - 5);
end
for s = 1:length(subjects_info)
    total_trials = total_trials + length(subjects_info(s).trial_nums);
end
fprintf('   Total percobaan: %d trials.\n\n', total_trials);

% --- 4. Resolve Output Directory (Smart Fallback & Naming) ---
if isempty(base_output_dir)
    base_output_dir = fullfile(root_dir, 'output');
end

if length(subjects_info) == 1
    batch_subject_name = subjects_info(1).id;
else
    batch_subject_name = 'RSscan_Batch';
end
exec_date = datestr(now, 'yyyymmdd');

out_paths = resolve_output_dir(base_output_dir, batch_subject_name, exec_date);
fprintf('3. Direktori Output : %s\n', out_paths.root);
fprintf('=========================================================================\n\n');

% Gather all trial tags
all_trial_tags = {};
for s = 1:length(subjects_info)
    all_trial_tags = [all_trial_tags, subjects_info(s).trial_tags]; %#ok<AGROW>
end

% --- 5. Sequential Execution of Stages ---

% Stage 1
if ismember(1, run_stages)
    fprintf('--- TAHAP 1: Ekstraksi Matriks Spatio-Temporal 3D & COP ---\n');
    for s = 1:length(subjects_info)
        stage1_extract_3d_cop(subjects_info(s), out_paths);
    end
    fprintf('Tahap 1 selesai.\n\n');
end

% Stage 2
if ismember(2, run_stages)
    fprintf('--- TAHAP 2: Segmentasi Geometri 12 Area Anatomis Telapak Kaki ---\n');
    stage2_segment_12boxes(all_trial_tags, out_paths, raw_input_dir, ratio_c);
    fprintf('Tahap 2 selesai.\n\n');
end

% Stage 3
if ismember(3, run_stages)
    fprintf('--- TAHAP 3: Ekstraksi Gaya, Luas & Tekanan (Interpolasi 101 Titik) ---\n');
    stage3_compute_fap(all_trial_tags, out_paths);
    fprintf('Tahap 3 selesai.\n\n');
end

% Stage 4
if ismember(4, run_stages)
    fprintf('--- TAHAP 4: Analisis Timing Kontak & Normalisasi %%BW ---\n');
    stage4_temporal_events(all_trial_tags, out_paths, bodyweight_kg);
    fprintf('Tahap 4 selesai.\n\n');
end

% Stage 5
if ismember(5, run_stages)
    fprintf('--- TAHAP 5: Rata-rata Multi-Trial per Subjek (Mean & SD) ---\n');
    processed_subjects = stage5_subject_aggregation(subjects_info, out_paths, bodyweight_kg);
    fprintf('Tahap 5 selesai.\n\n');
else
    processed_subjects = {subjects_info.id};
end

% Stage 6
if ismember(6, run_stages)
    fprintf('--- TAHAP 6: Analisis Komparasi Grup & Ekspor Matriks SPSS ---\n');
    stage6_group_analysis(processed_subjects, out_paths);
    fprintf('Tahap 6 selesai.\n\n');
end

fprintf('=========================================================================\n');
fprintf('   EKSEKUSI PIPELINE SUKSES SELURUHNYA!                                  \n');
fprintf('   Hasil lengkap tersimpan di: %s\n', out_paths.root);
fprintf('=========================================================================\n');

end
