# RSscan Plantar Pressure & Dynamic Gait Analysis Pipeline

A comprehensive MATLAB data processing pipeline for dynamic plantar pressure, ground reaction force (GRF), and center of pressure (COP) gait analysis based on **RSscan footscan®** pressure plate measurements.

---

## 📌 Overview

This repository provides an automated 6-stage biomechanical analysis pipeline that:
1. Parses raw RSscan spatio-temporal exports (.xls / .xlsx format).
2. Computes the longitudinal **geometric foot axis** and **Center of Pressure (COP)** trajectory.
3. Automatically partitions the plantar foot surface into **12 functional anatomical regions (boxes)**.
4. Normalizes contact timing into a standard **0–100% stance phase** (101 interpolated points).
5. Aggregates multi-trial measurements (5 walking steps per subject) into representative mean ± SD profiles.
6. Classifies subjects by **Arch Index (AI)** into clinical cohorts (*High Arch / Pes Cavus*, *Normal Arch*, *Flatfoot / Pes Planus*) for statistical evaluation (SPSS / ANOVA).

---

## 🦶 12 Anatomical Plantar Foot Regions

The pipeline geometrically divides each foot into 12 functional zones:

| Box Index | Anatomical Region | Clinical Abbreviation |
| :---: | :--- | :--- |
| **Box 1** | Hallux (Big Toe) | Toe 1 |
| **Box 2** | Second Toe | Toe 2 |
| **Box 3** | Third Toe | Toe 3 |
| **Box 4** | Lesser Toes | Toe 4-5 |
| **Box 5** | First Metatarsal Head | MT 1 |
| **Box 6** | Second Metatarsal Head | MT 2 |
| **Box 7** | Third Metatarsal Head | MT 3 |
| **Box 8** | Fourth & Fifth Metatarsal Heads | MT 4-5 |
| **Box 9** | Medial Midfoot | Mid Med |
| **Box 10** | Lateral Midfoot | Mid Lat |
| **Box 11** | Medial Heel (Rearfoot) | Heel Med |
| **Box 12** | Lateral Heel (Rearfoot) | Heel Lat |

---

## 🔄 6-Stage Pipeline Architecture

`
[ Raw RSscan Exports ]
         │
         ▼
[ loop1: 3D Pressure Matrix & COP Extraction ] ──► map_level_*.mat, map_level_max_*.txt
         │
         ▼
[ loop2: 12-Box Geometric Foot Partitioning ]  ──► xy_box12_*.txt, xy_box12_*.jpg
         │
         ▼
[ loop3: Regional Force, Area & Pressure (101 pts) ] ──► box12_data_101_*.txt
         │
         ▼
[ loop4: Stance Phase Timing & %BW Normalization ] ──► step_start_end_max_peak_*.txt
         │
         ▼
[ loop5: Multi-Step Subject Aggregation (5 Trials) ] ──► foot_fap_mean_*.txt, foot_fap_std_*.txt
         │
         ▼
[ loop6: Cohort Grouping by Arch Index (AI) ] ──► *_box12_group_semp_spss.txt (SPSS)
`

### Stage Details

1. **loop1_step_box_MxNxL_20080815.m (Stage 1):**
   * Parses Dynamic Roll off, Centre of Force line, and Dynamic Maximum Image.
   * Standardizes orientation (horizontal flip for right foot) and extracts COP trajectory.
   * Outputs 3D spatio-temporal array (map_level.mat) and 2D peak pressure matrix (map_level_max.txt).

2. **loop2_step_box12_get_xy_20080810.m (Stage 2):**
   * Uses helper functions unc_footaxis.m and unc_perpendical_point_to_line.m.
   * Computes the longitudinal axis of the foot and generates 4-point bounding polygons for all 12 regions (xy_box12_*.txt).

3. **loop3_step_box12_value_20080810.m (Stage 3):**
   * Uses unc_abcd_in.m to map active sensors into their respective boxes across all frames.
   * Calculates regional force ($), contact area ($), and pressure ( = F/A$).
   * Normalizes time to 0–100% stance phase (101 data points).

4. **loop4_step_start_end_20080815.m & loop4_step_pressure_area_20080826.m (Stage 4):**
   * Detects temporal events: Initial Contact (*Start*), Roll-off (*End*), Time-to-Peak (*Max Index*), and Peak Value.
   * Normalizes force relative to subject body weight (%BW).

5. **loop5_foot_froce_20080812.m & loop5_foot_pressure_area_20080826.m (Stage 5):**
   * Averages 5 repeated trials per subject to compute ensemble mean and standard deviation.
   * Calculates Force-Time Integral (Impulse).

6. **loop6_group_20080816.m & loop6_group_pressure_area_20080826.m (Stage 6):**
   * Groups subjects into Arch Index categories:
     - **High Arch (Pes Cavus):**  < 0.21$
     - **Normal Arch:** .21 \le AI \le 0.26$
     - **Flatfoot (Pes Planus):**  > 0.26$
   * Exports formatted ASCII datasets ready for statistical analysis in SPSS / ANOVA.

---

## 📂 Repository Structure

`
├── coba rs scan/                           # Sequential MATLAB processing scripts
│   ├── loop1_step_box_MxNxL_20080815.m
│   ├── loop2_step_box12_get_xy_20080810.m
│   ├── loop3_step_box12_value_20080810.m
│   ├── loop4_step_start_end_20080815.m
│   ├── loop4_step_pressure_area_20080826.m
│   ├── loop5_foot_froce_20080812.m
│   ├── loop5_foot_pressure_area_20080826.m
│   ├── loop6_group_20080816.m
│   └── loop6_group_pressure_area_20080826.m
│
├── 20260824_rscop_box_pressure/           # Geometric functions & shared results
│   ├── func_footaxis.m                     # Foot axis calculation
│   ├── func_abcd_in.m                      # Point-in-polygon cell assignment
│   ├── func_perpendical_point_to_line.m    # Geometric perpendicular projection
│   ├── func_box_link.m                     # Interactive box boundary linker
│   ├── rawdata_rs/                         # Raw RSscan tabular exports
│   └── result/                             # Hierarchical output folders
│       ├── 1_step_level/
│       ├── 2_step_get_xy/
│       ├── 3_step_value/
│       ├── 4_step_start_end/
│       ├── 5_foot/
│       └── 6_group/
│
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
├── .gitignore
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites
* MATLAB R2018a or newer (compatible with legacy and modern releases).

### Quick Execution
Run the unified master pipeline directly from MATLAB in the parent directory:

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
