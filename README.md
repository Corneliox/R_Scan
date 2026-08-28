# RSscan Plantar Pressure & Dynamic Gait Analysis Pipeline

A comprehensive MATLAB data processing pipeline for dynamic plantar pressure, ground reaction force (GRF), and center of pressure (COP) gait analysis based on **RSscan footscan®** pressure plate measurements.

---

## ⚡ Quick Start: Jalankan Aplikasi Utama (GUI)

Aplikasi utama yang paling direkomendasikan untuk digunakan sehari-hari adalah **`rscan_gui`**. Cukup buka MATLAB dan jalankan:

```matlab
% Buka GUI Studio Interaktif
rscan_gui
```

Dengan GUI ini, Anda dapat:
- Memilih folder **Input (Raw Data)** dan **Output** secara visual lewat tombol *Browse*.
- Memilih subjek tertentu atau seluruh subjek (*Select All*).
- Menjalankan seluruh tahapan (Tahap 1 s/d 6) hanya dengan satu klik tombol **▶ RUN PIPELINE**.
- Membuka folder hasil langsung di Windows Explorer setelah analisis selesai.

---

## 📌 Overview

Pipeline biomekanika terintegrasi ini mengotomatiskan 6 tahapan pemrosesan data:
1. **Tahap 1:** Membaca ekspor matriks spatio-temporal RSscan (`.xls` / `.xlsx`) dan mengekstrak lintasan COP.
2. **Tahap 2:** Menghitung sumbu geometris telapak kaki (*foot axis*) dan membagi telapak kaki menjadi **12 area anatomis (boxes)**.
3. **Tahap 3:** Mengekstrak nilai Gaya ($F$), Luas Kontak ($A$), dan Tekanan ($P = F/A$) pada 12 box dengan normalisasi **101 titik (0–100% stance phase)**.
4. **Tahap 4:** Mendeteksi parameter temporal kontak (*Start*, *End*, *Time-to-Peak*, *Peak Force*) dan normalisasi terhadap berat badan (%BW).
5. **Tahap 5:** Mengagregasi $N$ langkah uji coba per subjek menjadi kurva Rata-rata (*Mean*) dan Simpangan Baku (*SD*).
6. **Tahap 6:** Mengelompokkan subjek berdasarkan **Arch Index (AI)** (*High Arch*, *Normal Arch*, *Flatfoot*) dan mengekspor matriks tabel siap uji statistik (SPSS / ANOVA).

---

## 🦶 12 Area Anatomis Telapak Kaki (12 Boxes)

Telapak kaki dibagi secara otomatis ke dalam 12 zona fungsional:

| Box Index | Zona Anatomis | Singkatan | Deskripsi Klinis |
| :---: | :--- | :--- | :--- |
| **Box 1** | Hallux (Ibu Jari Kaki) | Toe 1 | Jari kaki medial / jempol |
| **Box 2** | Jari Kaki Kedua | Toe 2 | Jari telapak kedua |
| **Box 3** | Jari Kaki Ketiga | Toe 3 | Jari telapak ketiga |
| **Box 4** | Jari Kaki Keempat & Kelima | Toe 4-5 | Jari-jari kaki lateral |
| **Box 5** | Metatarsal Head 1 | MT 1 | Kepala metatarsal pertama (medial) |
| **Box 6** | Metatarsal Head 2 | MT 2 | Kepala metatarsal kedua (sentral-medial) |
| **Box 7** | Metatarsal Head 3 | MT 3 | Kepala metatarsal ketiga (sentral-lateral) |
| **Box 8** | Metatarsal Head 4 & 5 | MT 4-5 | Kepala metatarsal lateral |
| **Box 9** | Midfoot Medial | Mid Med | Lengkung telapak dalam (*Medial Longitudinal Arch*) |
| **Box 10** | Midfoot Lateral | Mid Lat | Lengkung telapak luar (*Lateral Longitudinal Arch*) |
| **Box 11** | Tumit Medial (Rearfoot) | Heel Med | Bagian dalam tumit (*Medial Calcaneus*) |
| **Box 12** | Tumit Lateral (Rearfoot) | Heel Lat | Bagian luar tumit (*Lateral Calcaneus*) |

---

## ⚙️ Parameter Biomekanika: Fungsi Ratio MT

### Apa itu Ratio MT?
**Ratio MT** (Metatarsal Partition Ratio, default: `30, 20, 20`) adalah parameter proporsi geometris yang digunakan pada **Tahap 2** untuk membagi garis transversal metatarsal (dari medial ke lateral) menjadi 4 zona metatarsal dan 4 zona jari kaki:

* **0% – 30% (Lebar 30%):** Area **Box 5 (MT 1)** dan **Box 1 (Toe 1 / Hallux)** pada sisi medial.
* **30% – 50% (Lebar 20%):** Area **Box 6 (MT 2)** dan **Box 2 (Toe 2)**.
* **50% – 70% (Lebar 20%):** Area **Box 7 (MT 3)** dan **Box 3 (Toe 3)**.
* **70% – 100% (Lebar 30%):** Area **Box 8 (MT 4-5)** dan **Box 4 (Toe 4-5)** pada sisi lateral.

### Mengapa Ratio MT Penting?
1. **Proporsi Anatomis Manusia:** Kepala metatarsal pertama (MT1) dan metatarsal luar (MT4-5) secara anatomis lebih lebar daripada MT2 dan MT3.
2. **Standardisasi Otomatis:** Menjamin segmentasi 12 box konsisten pada seluruh subjek tanpa perlu menggambar poligon manual satu per satu pada ratusan data langkah.
3. **Kustomisasi Klinis:** Jika Anda menganalisis populasi khusus (misalnya kaki diabetes, anak-anak, atau kelainan *hallux valgus*), rasio ini dapat disesuaikan langsung melalui antarmuka GUI.

---

## 🔄 6-Stage Pipeline Architecture

```text
[ Raw RSscan Exports (Dynamic Roll off, COP line, Dynamic Max Image) ]
                               │
                               ▼
     [ Stage 1: 3D Spatio-Temporal Matrix & COP Extraction ]
        └── Output: map_level_*.mat, map_level_max_*.txt, mn_*.jpg
                               │
                               ▼
     [ Stage 2: 12-Box Geometric Foot Partitioning ]
        └── Output: xy_box12_*.txt, xy_box12_*.jpg
                               │
                               ▼
     [ Stage 3: Regional Force, Area & Pressure (101 pts) ]
        └── Output: box12_data_101_*.txt, inbox_value_*.txt, inbox_xy_*.txt
                               │
                               ▼
     [ Stage 4: Stance Phase Timing & %BW Normalization ]
        └── Output: step_start_end_max_peak_*.txt, data_pressure_*.txt, data_area_*.txt
                               │
                               ▼
     [ Stage 5: Multi-Trial Subject Aggregation (N Steps) ]
        └── Output: foot_fap_mean_*.txt, foot_fap_std_*.txt, foot_fap_*.jpg
                               │
                               ▼
     [ Stage 6: Cohort Grouping by Arch Index & SPSS Export ]
        └── Output: *_box12_group_semp_spss.txt, *_box_group.jpg
```

---

## 📂 Struktur Repositori

```text
├── rscan_gui.m                             # 🚀 APLIKASI UTAMA: Graphical User Interface Studio
├── main_rscan_pipeline.m                   # Engine Pemroses Utama (Master Orchestrator)
├── src/                                    # Modul & Fungsi Helper Terintegrasi
│   ├── resolve_output_dir.m                # Logika Cerdas Resolusi & Fallback Folder Output
│   ├── scan_subject_trials.m               # Detektor Dinamis Jumlah Percobaan (1..N Trials)
│   ├── stage1_extract_3d_cop.m             # Tahap 1: Ekstraksi Array 3D & COP
│   ├── stage2_segment_12boxes.m            # Tahap 2: Segmentasi 12 Box Telapak Kaki
│   ├── stage3_compute_fap.m                # Tahap 3: Perhitungan F, A, P (101 Titik)
│   ├── stage4_temporal_events.m            # Tahap 4: Timing Kontak & Normalisasi %BW
│   ├── stage5_subject_aggregation.m        # Tahap 5: Rata-rata Multi-Trial per Subjek
│   ├── stage6_group_analysis.m             # Tahap 6: Analisis Grup Arch Index & SPSS
│   ├── func_footaxis.m                     # Helper: Sumbu Geometris Telapak Kaki
│   ├── func_abcd_in.m                      # Helper: Deteksi Sensor dalam Poligon 4 Titik
│   ├── func_perpendical_point_to_line.m    # Helper: Aljabar Vektor Proyeksi Garis
│   └── func_box_link.m                     # Helper: Penghubung Titik Batas
│
├── coba rs scan/                           # Skrip Legacy Referensi (Dipertahankan 100%)
├── 20260824_rscop_box_pressure/           # Data & Hasil Legacy Referensi (Dipertahankan 100%)
├── .gitignore                              # Filter Git untuk Data Besar (~3.85 GB)
└── README.md                               # Dokumentasi Teknis Repositori
```

---

## 🚀 Cara Menjalankan

### Opsi 1: Menjalankan via GUI (Direkomendasikan)
```matlab
rscan_gui
```

### Opsi 2: Menjalankan via Skrip Command Window (CLI / Batch Script)
```matlab
% 1. Eksekusi default (semua subjek & semua tahap):
main_rscan_pipeline();

% 2. Eksekusi untuk subjek dan folder output khusus:
main_rscan_pipeline('subject', {'R_t000', 'L_t000'}, 'output_dir', 'D:\Hasil_RScan');

% 3. Eksekusi tahapan tertentu saja (misal tahap 1 sampai 3):
main_rscan_pipeline('stages', 1:3);

% 4. Normalisasi berat badan khusus (contoh: 75 kg):
main_rscan_pipeline('bodyweight', 75);
```

---

## 📄 Lisensi & Catatan
Dikembangkan untuk riset biomekanika tekanan plantar dan analisis gaya berjalan (*gait analysis*). Seluruh hak cipta dilindungi.
