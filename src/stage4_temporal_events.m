function [success_tags] = stage4_temporal_events(trial_tags, out_paths, bodyweight_kg)
% STAGE4_TEMPORAL_EVENTS - Computes Contact Timing, Peak Events, and %BW Normalization
%
% Inputs:
%   trial_tags    - Cell array of trial tags, e.g. {'R_t000_1', ...}
%   out_paths     - Structure of paths from resolve_output_dir
%   bodyweight_kg - Subject bodyweight in kg (default: 70 kg)

if nargin < 3 || isempty(bodyweight_kg)
    bodyweight_kg = 70; % Default bodyweight in kg
end
bodyweight_N = bodyweight_kg * 9.8;
sensor_cell_area = 0.53 * 0.75; % cm^2 per cell
success_tags = {};

for w = 1:length(trial_tags)
    tag = trial_tags{w};
    fprintf('   [Stage 4] Contact timing & %BW normalization: %s ... ', tag);
    
    fap_path = fullfile(out_paths.stage3_fap, sprintf('box12_data_101_f12_p12_m1_s1_%s.txt', tag));
    if ~exist(fap_path, 'file')
        fprintf('SKIPPED (Data 101 titik tidak ditemukan)\n');
        continue;
    end
    
    data_101 = load(fap_path);
    data_f_n = data_101(:, 1:12);
    data_f_bw = (data_f_n / bodyweight_N) * 100; % %BW
    
    start_end_max_peak = zeros(12, 4);
    data_area = zeros(101, 12);
    data_pressure = zeros(101, 12);
    
    is_left = startsWith(tag, 'L', 'IgnoreCase', true);
    if is_left
        inval_dir = out_paths.stage3_inval_L;
    else
        inval_dir = out_paths.stage3_inval_R;
    end
    
    for q = 1:12
        fz_cut = data_f_bw(:, q);
        
        if sum(fz_cut) == 0
            start_end_max_peak(q, :) = [0, 0, 0, 0];
        else
            max_f = max(fz_cut);
            noise_fz = max_f * 0.01;
            
            fz_signal_o = find(fz_cut > noise_fz);
            if isempty(fz_signal_o)
                x1 = 0; x2 = 0;
            else
                x1 = fz_signal_o(1);
                x2 = fz_signal_o(end);
            end
            
            [max_value, max_index] = max(fz_cut);
            start_end_max_peak(q, :) = [x1, x2, max_index, max_value];
        end
        
        % Compute dynamic contact area from inbox cell values (with cross-folder fallback)
        val_file = fullfile(inval_dir, sprintf('box12_value_inbox%d_%s.txt', q, tag));
        if ~exist(val_file, 'file')
            if is_left
                alt_file = fullfile(out_paths.stage3_inval_R, sprintf('box12_value_inbox%d_%s.txt', q, tag));
            else
                alt_file = fullfile(out_paths.stage3_inval_L, sprintf('box12_value_inbox%d_%s.txt', q, tag));
            end
            if exist(alt_file, 'file')
                val_file = alt_file;
            end
        end
        
        if exist(val_file, 'file')
            box_val = load(val_file);
            raw_area = sum(box_val > 0, 2) * sensor_cell_area;
            x_orig = linspace(0, 100, length(raw_area))';
            x_101  = linspace(0, 100, 101)';
            data_area(:, q) = interp1(x_orig, raw_area, x_101, 'linear');
        else
            data_area(:, q) = (data_f_n(:, q) > 0) * (5 * sensor_cell_area);
        end
        
        for j = 1:101
            if data_area(j, q) > 0
                data_pressure(j, q) = data_f_n(j, q) / data_area(j, q);
            else
                data_pressure(j, q) = 0;
            end
        end
    end
    
    % Save timing & continuous curves
    save(fullfile(out_paths.stage4_timing, sprintf('step_start_end_max_peak_%s.txt', tag)), 'start_end_max_peak', '-ascii');
    save(fullfile(out_paths.stage4_timing, sprintf('data_pressure_%s.txt', tag)), 'data_pressure', '-ascii');
    save(fullfile(out_paths.stage4_timing, sprintf('data_area_%s.txt', tag)), 'data_area', '-ascii');
    
    % Render & Save Plot
    fig = figure('Visible', 'off');
    subplot(3, 1, 1);
    plot(0:100, data_f_bw, 'linewidth', 1.5);
    ylabel('% Body Weight'); grid on; title(sprintf('%s Force, Area, Pressure', strrep(tag, '_', '\_')));
    
    subplot(3, 1, 2);
    plot(0:100, data_area, 'linewidth', 1.5);
    ylabel('Area (cm^2)'); grid on;
    
    subplot(3, 1, 3);
    plot(0:100, data_pressure, 'linewidth', 1.5);
    xlabel('% Stance Phase'); ylabel('Pressure (N/cm^2)'); grid on;
    
    saveas(fig, fullfile(out_paths.stage4_timing, sprintf('step_pressure_area_%s', tag)), 'jpg');
    close(fig);
    
    success_tags{end+1} = tag; %#ok<AGROW>
    fprintf('OK\n');
end

end
