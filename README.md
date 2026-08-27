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
├── .gitignore
└── README.md
`

---

## 🚀 Getting Started

### Prerequisites
* MATLAB R2018a or newer (compatible with legacy and modern releases).

### Execution
Run the scripts sequentially in MATLAB:
`matlab
% Set MATLAB current folder to 'coba rs scan'
cd('coba rs scan');

% Run pipeline step by step:
run('loop1_step_box_MxNxL_20080815.m');
run('loop2_step_box12_get_xy_20080810.m');
run('loop3_step_box12_value_20080810.m');
run('loop4_step_pressure_area_20080826.m');
run('loop5_foot_pressure_area_20080826.m');
run('loop6_group_pressure_area_20080826.m');
`

---

## 📄 License & Notes
Developed for plantar pressure biomechanics research and gait analysis. All rights reserved.
