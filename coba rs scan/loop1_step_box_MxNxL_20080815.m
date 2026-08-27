clc; close all; clearvars;

% =========================================================================
% 1. KONFIGURASI DIREKTORI & OPSI TRANSFORMASI
% =========================================================================
fopen_file = 'G:\coba rs scan\rawdata_rs\R\'; % Folder utama rawdata
save_file  = 'G:\coba rs scan\result\';     % Folder penyimpanan hasil

flipud_y = 'n'; % 'y' untuk membalik vertikal, 'n' jika tidak
fliplr_y = 'y'; % 'y' untuk membalik horizontal, 'n' jika tidak

% =========================================================================
% 2. GENERATE DAFTAR FOLDER SAMPLES (R_t000 - R_t078)
% =========================================================================
% Jika semua folder dari 000 sampai 078 ada:
range_folder = 0:78; 

% Catatan: Jika ada nomor yang loncat/kosong, Anda bisa menyesuaikan angkanya, contoh:
% range_folder = [0:9, 10:17, 19:46, 50:78];

no_man = {};
for k = range_folder
    no_man{end+1} = sprintf('R_t%03d', k);
end

% Membuat daftar nama percobaan per sampel (1 sampai 5 step)
no_man_step = {};
for i = 1:length(no_man)
    for j = 1:5
        no_man_step{end+1} = sprintf('%s_%d', no_man{i}, j); %#ok<SAGROW>
    end
end

fprintf('Total sampel yang akan diproses: %d percobaan.\n\n', length(no_man_step));

% =========================================================================
% 3. MAIN PROCESSING LOOP
% =========================================================================
for w = 1:length(no_man_step)
    close all;
    
    current_man_step = no_man_step{w};
    fprintf('[%d/%d] Processing: %s ... ', w, length(no_man_step), current_man_step);
    
    % Break string 'R_t063_1' -> side='R', folder_t='t063', step_num='1'
    parts = strsplit(current_man_step, '_'); 
    side     = parts{1}; % 'R' atau 'L'
    folder_t = parts{2}; % 't0xx'
    step_num = parts{3}; % '1' - '5'
    
    % Path lokasi folder target: G:\coba rs scan\rawdata_rs\R\t0xx\
    fopen_name = fullfile(fopen_file, side, folder_t);
    
    % --- Verifikasi Folder ---
    if ~exist(fopen_name, 'dir')
        fprintf('SKIPPED (Folder %s tidak ditemukan)\n', fopen_name);
        continue;
    end
    
    % --- Verifikasi & Pencarian File (.xls / .xlsx) ---
    cop_path  = fullfile(fopen_name, sprintf('Centre of Force line_%s.xls', step_num));
    roll_path = fullfile(fopen_name, sprintf('Dynamic Roll off_%s.xls', step_num));
    max_path  = fullfile(fopen_name, sprintf('Dynamic Maximum Image_%s.xls', step_num));
    
    % Fallback 1: Coba nama file standar (tanpa akhiran _step)
    if ~exist(cop_path, 'file')
        cop_path  = fullfile(fopen_name, 'Centre of Force line.xls');
        roll_path = fullfile(fopen_name, 'Dynamic Roll off.xls');
        max_path  = fullfile(fopen_name, 'Dynamic Maximum Image.xls');
    end
    
    % Fallback 2: Coba ekstensi .xlsx
    if ~exist(cop_path, 'file')
        cop_path  = fullfile(fopen_name, sprintf('Centre of Force line_%s.xlsx', step_num));
        roll_path = fullfile(fopen_name, sprintf('Dynamic Roll off_%s.xlsx', step_num));
        max_path  = fullfile(fopen_name, sprintf('Dynamic Maximum Image_%s.xlsx', step_num));
    end
    if ~exist(cop_path, 'file')
        cop_path  = fullfile(fopen_name, 'Centre of Force line.xlsx');
        roll_path = fullfile(fopen_name, 'Dynamic Roll off.xlsx');
        max_path  = fullfile(fopen_name, 'Dynamic Maximum Image.xlsx');
    end
    
    % Cek ulang keberadaan file
    if ~exist(cop_path, 'file') || ~exist(roll_path, 'file') || ~exist(max_path, 'file')
        fprintf('SKIPPED (File .xls/.xlsx tidak ditemukan)\n');
        continue;
    end
    
    % Buka File
    cop_line  = fopen(cop_path, 'r');
    roll      = fopen(roll_path, 'r');
    max_image = fopen(max_path, 'r');
    
    % --- Parse Centre of Force Line ---
    for i = 1:18, fgetl(cop_line); end
    yy = [];
    str = fgetl(cop_line);
    while ischar(str) && ~isempty(str)
        yy = [yy; str2num(str)]; %#ok<AGROW>
        str = fgetl(cop_line);
    end
    fclose(cop_line);
    
    if isempty(yy) || size(yy, 2) < 5
        fprintf('SKIPPED (Data COP kosong/tidak valid)\n');
        fclose(roll); fclose(max_image);
        continue;
    end
    yy_fz = yy(:, 5);

    % Determinasi Jumlah Frame
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
        fprintf('SKIPPED (Tidak ada frame valid)\n');
        fclose(roll); fclose(max_image);
        continue;
    end

    % --- Parse Max Image Header & Matrix ---
    for i = 1:3, fgetl(max_image); end
    str = fgetl(max_image);
    sample_rate = str2num(str(37:min(39, length(str)))); %#ok<NASGU>
    
    for i = 1:9, fgetl(max_image); end
    map_width = str2num(fgetl(max_image));
    
    fgetl(max_image); 
    map_length = str2num(fgetl(max_image));
    
    fgetl(max_image); 
    map_raw = zeros(map_length, map_width);
    for i = 1:map_length
        map_raw(i, :) = str2num(fgetl(max_image)); %#ok<AGROW>
    end
    fclose(max_image);

    % --- Parse Roll Off Data ---
    for i = 1:18, fgetl(roll); end
    
    map_level = zeros(map_length, map_width, frame);
    x_cop_raw = zeros(frame, 1);
    y_cop_raw = zeros(frame, 1);
    
    is_right_foot = strcmp(side, 'R');
    
    for i = 1:frame
        a = zeros(map_length, map_width);
        for j = 1:map_length
            str = fgetl(roll);
            if ~ischar(str), break; end
            a(j, :) = str2num(str);
        end
        
        % Transformasi Matriks
        if is_right_foot
            a = fliplr(a);
        end
        if strcmp(flipud_y, 'y')
            a = flipud(a);
        end
        if strcmp(fliplr_y, 'y')
            a = fliplr(a);
        end
        
        % Kalkulasi Center of Pressure (COP)
        sum_a = sum(a(:));
        if sum_a > 0
            cop_xi = sum((sum(a, 1)' .* (1:map_width)')) / sum(sum(a, 1));
            cop_yi = sum((sum(a, 2) .* (1:map_length)')) / sum(sum(a, 2));
        else
            cop_xi = 0;
            cop_yi = 0;
        end
        
        for k = 1:2
            fgetl(roll);
        end
        
        x_cop_raw(i, 1) = cop_xi;
        y_cop_raw(i, 1) = cop_yi;
        map_level(:, :, i) = a;
    end
    fclose(roll);

    % --- SAVE OUTPUT DATA ---
    map_level_max = max(map_level, [], 3);
    
    % Render Gambar Surf
    fig = figure('Visible', 'off');
    surf(map_level_max); 
    hold on; 
    axis equal; 
    view(0, 90); 
    colorbar;
    title(sprintf('%s [%d] region value', strrep(current_man_step, '_', '\_'), w));
    
    % Buat folder simpan jika belum ada
    if ~exist(save_file, 'dir')
        mkdir(save_file);
    end
    
    % Simpan ke .mat, .txt, dan .jpg
    save(fullfile(save_file, ['map_level_', current_man_step, '.mat']), 'map_level');
    save(fullfile(save_file, ['map_level_max_', current_man_step, '.txt']), 'map_level_max', '-ascii');
    saveas(fig, fullfile(save_file, ['mn_', current_man_step]), 'jpg');
    close(fig);
    
    fprintf('SUCCESS\n');
end

fprintf('\nProses selesai seluruhnya! Hasil disimpan di: %s\n', save_file);