# RSscan Plantar Pressure & Dynamic Gait Analysis Pipeline

A comprehensive MATLAB data processing pipeline for dynamic plantar pressure, ground reaction force (GRF), and center of pressure (COP) gait analysis based on **RSscan footscan®** pressure plate measurements.

---

## 📌 Overview

This repository provides an automated 6-stage biomechanical analysis pipeline that:
1. Parses raw RSscan spatio-temporal exports (`.xls` / `.xlsx` format).
2. Computes the longitudinal **geometric foot axis** and **Center of Pressure (COP)** trajectory.
3. Automatically partitions the plantar foot surface into **12 functional anatomical regions (boxes)**.
4. Normalizes contact timing into a standard **0–100% stance phase** (101 interpolated points).
5. Aggregates multi-trial measurements ($N$ walking steps per subject) into representative mean ± SD profiles.
6. Classifies subjects by **Arch Index (AI)** into clinical cohorts (*High Arch / Pes Cavus*, *Normal Arch*, *Flatfoot / Pes Planus*) for statistical evaluation (SPSS / ANOVA).

---

## 🦶 12 Anatomical Plantar Foot Regions

The pipeline geometrically divides each foot into 12 functional zones:

| Box Index | Anatomical Region | Clinical Abbreviation | Description |
| :---: | :--- | :--- | :--- |
| **Box 1** | Hallux (Big Toe) | Toe 1 | Medial distal toe |
| **Box 2** | Second Toe | Toe 2 | Second digital zone |
| **Box 3** | Third Toe | Toe 3 | Third digital zone |
| **Box 4** | Lesser Toes | Toe 4-5 | Fourth and fifth digital zones |
| **Box 5** | First Metatarsal Head | MT 1 | Medial forefoot |
| **Box 6** | Second Metatarsal Head | MT 2 | Central-medial forefoot |
| **Box 7** | Third Metatarsal Head | MT 3 | Central-lateral forefoot |
| **Box 8** | Fourth & Fifth Metatarsal Heads | MT 4-5 | Lateral forefoot |
| **Box 9** | Medial Midfoot | Mid Med | Medial longitudinal arch |
| **Box 10** | Lateral Midfoot | Mid Lat | Lateral longitudinal arch |
| **Box 11** | Medial Heel (Rearfoot) | Heel Med | Medial calcaneus |
| **Box 12** | Lateral Heel (Rearfoot) | Heel Lat | Lateral calcaneus |

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

### Stage Details

1. **Stage 1 (`stage1_extract_3d_cop.m`):**
   * Parses `Dynamic Roll off`, `Centre of Force line`, and `Dynamic Maximum Image`.
   * Standardizes orientation (horizontal flip for right foot) and extracts COP trajectory.
   * Outputs 3D spatio-temporal array (`map_level.mat`) and 2D peak pressure matrix (`map_level_max.txt`).

2. **Stage 2 (`stage2_segment_12boxes.m`):**
   * Uses helper functions `func_footaxis.m` and `func_perpendical_point_to_line.m`.
   * Computes the longitudinal axis of the foot and generates 4-point bounding polygons for all 12 regions (`xy_box12_*.txt`).

3. **Stage 3 (`stage3_compute_fap.m`):**
   * Uses `func_abcd_in.m` to map active sensors into their respective boxes across all frames.
   * Calculates regional force ($F$), contact area ($A$), and pressure ($P = F/A$).
   * Normalizes time to 0–100% stance phase (101 data points).

4. **Stage 4 (`stage4_temporal_events.m`):**
   * Detects temporal events: Initial Contact (*Start*), Roll-off (*End*), Time-to-Peak (*Max Index*), and Peak Value.
   * Normalizes force relative to subject body weight (%BW).

5. **Stage 5 (`stage5_subject_aggregation.m`):**
   * Dynamically averages all available trials ($N \ge 1$) per subject to compute ensemble mean and standard deviation.
   * Calculates Force-Time Integral (Impulse).

6. **Stage 6 (`stage6_group_analysis.m`):**
   * Groups subjects into Arch Index categories:
     - **High Arch (Pes Cavus):** $AI < 0.21$
     - **Normal Arch:** $0.21 \le AI \le 0.26$
     - **Flatfoot (Pes Planus):** $AI > 0.26$
   * Exports formatted ASCII datasets ready for statistical analysis in SPSS / ANOVA.

---

## 📂 Repository Structure

```text
├── main_rscan_pipeline.m                   # Unified Master Pipeline Entrypoint
├── src/                                    # Modular stage functions & geometry helpers
│   ├── resolve_output_dir.m                # Smart output directory resolution & fallback
│   ├── scan_subject_trials.m               # Dynamic N-trial detection per subject
│   ├── stage1_extract_3d_cop.m             # Stage 1: 3D matrix & COP extraction
│   ├── stage2_segment_12boxes.m            # Stage 2: 12-box foot partitioning
│   ├── stage3_compute_fap.m                # Stage 3: Force, Area, Pressure (101 pts)
│   ├── stage4_temporal_events.m            # Stage 4: Timing & %BW normalization
│   ├── stage5_subject_aggregation.m        # Stage 5: N-trial mean & standard deviation
│   ├── stage6_group_analysis.m             # Stage 6: Arch Index & SPSS matrix export
│   ├── func_footaxis.m                     # Foot axis helper
│   ├── func_abcd_in.m                      # Point-in-polygon helper
│   ├── func_perpendical_point_to_line.m    # Geometric perpendicular projection helper
│   └── func_box_link.m                     # Interactive box boundary linker
│
├── coba rs scan/                           # Legacy reference scripts (preserved)
├── 20260824_rscop_box_pressure/           # Legacy data & reference (preserved)
├── .gitignore                              # Git filter for large raw data (~3.85 GB)
└── README.md                               # Project documentation
```

---

## 🚀 Getting Started

### Prerequisites
* MATLAB R2018a or newer (compatible with legacy and modern releases).

### Quick Execution
Run the unified master pipeline directly from MATLAB in the root directory:

```matlab
% 1. Run full pipeline for all discovered subjects with default settings:
main_rscan_pipeline();

% 2. Run for specific subject(s) with custom output folder:
main_rscan_pipeline('subject', {'R_t000', 'L_t000'}, 'output_dir', 'D:\MyOutput');

% 3. Run specific stages (e.g. Stage 1 to 3 only):
main_rscan_pipeline('stages', 1:3);

% 4. Custom bodyweight normalization (e.g. 75 kg):
main_rscan_pipeline('bodyweight', 75);
```

### Smart Output Resolution & Fallback
The pipeline automatically formats the output folder as `<subject_name>_<YYYYMMDD>`.
- If the target folder is empty, output is saved directly in `<output_dir>/<subject_name>_<YYYYMMDD>`.
- If the folder contains previous results or general files, it automatically creates/routes to `<output_dir>/output/<subject_name>_<YYYYMMDD>`.
- Inside each subject folder, structured stage subfolders (`1_step_level` to `6_group`) are preserved.

---

## 📄 License & Notes
Developed for plantar pressure biomechanics research and gait analysis. All rights reserved.
