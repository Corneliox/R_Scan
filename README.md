# RSscan Plantar Pressure & Dynamic Gait Analysis Studio

A comprehensive, modular MATLAB pipeline for dynamic plantar pressure, ground reaction force (GRF), and center of pressure (COP) gait analysis based on **RSscan footscan®** pressure plate measurements.

---

## ⚡ Quick Start: Interactive Desktop GUI (`rscan_gui`)

The primary and recommended interface for everyday analysis is the interactive desktop application **`rscan_gui`**. Open MATLAB and launch:

```matlab
% Launch the Interactive Studio GUI
rscan_gui
```

### Key GUI Features:
* **Interactive Directory Browsing:** Select **Raw Data Input** and **Output Directory** via native Windows folder dialogs.
* **Auto-Discovery & Trial Detection:** Automatically discovers all subjects, side laterality (`L`, `R`, or `AUTO`), and counts available trials.
* **Flexible Subject Selection:** Process all subjects with one click (*Select All*) or select specific subjects for targeted evaluation.
* **Stage-by-Stage Control:** Selectively execute any subset of Stages 1 to 6.
* **One-Click Execution:** Run the entire end-to-end pipeline with the **▶ RUN PIPELINE** button.
* **Explorer Integration:** Instantly open the generated results folder in Windows Explorer via **Open Output Folder**.

---

## 📌 Overview & 6-Stage Biomechanical Pipeline

This repository automates the end-to-end biomechanical processing of dynamic foot pressure measurements across 6 modular stages:

```text
[ Raw RSscan Exports (Dynamic Roll off, COP line, Dynamic Max Image) ]
                               │
                               ▼
     [ Stage 1: 3D Spatio-Temporal Matrix & COP Extraction ]
        └── Output: map_level_*.mat, map_level_max_*.txt, mn_*.jpg
                               │
                               ▼
     [ Stage 2: 12-Box Geometric Foot Surface Partitioning ]
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

### Detailed Stage Breakdown:

1. **Stage 1 (`stage1_extract_3d_cop.m`):**
   * **Dynamic File Discovery:** Case-insensitive regex matching for RSscan `.xls` / `.xlsx` exports.
   * **Streaming Parser:** Dynamically locates active foot sections and data headers (`Frame`).
   * **Orientation Standardization:** Automatically applies `fliplr` to mirror right feet onto a standardized anatomical coordinate system.
   * **Max Image Fallback:** Automatically calculates `map_level_max = max(map_level, [], 3)` if the export contains only a header without numeric grid values.

2. **Stage 2 (`stage2_segment_12boxes.m`):**
   * Computes the longitudinal **geometric foot axis** using `func_footaxis.m`.
   * Projects transversal partition lines via 2D vector geometry (`func_perpendical_point_to_line.m`).
   * Outputs 4-point bounding quad polygons for each of the 12 anatomical regions (`xy_box12_*.txt`).

3. **Stage 3 (`stage3_compute_fap.m`):**
   * Maps active sensor cells into their respective bounding boxes using matrix polygon inclusion (`func_abcd_in.m`).
   * Extracts regional Force ($F$), Area ($A$), and Pressure ($P = F/A$).
   * Normalizes time into a standardized **0–100% stance phase** (101 interpolated points).

4. **Stage 4 (`stage4_temporal_events.m`):**
   * Identifies temporal contact milestones: Initial Contact (*Start*), Toe-Off (*End*), Time-to-Peak (*Max Index*), and Peak Force value.
   * Normalizes regional forces relative to subject body weight (%BW).

5. **Stage 5 (`stage5_subject_aggregation.m`):**
   * Dynamically aggregates all available trials ($N \ge 1$) per subject into ensemble Mean $\pm$ Standard Deviation (SD) curves.
   * Computes Force-Time Integrals (Impulse).

6. **Stage 6 (`stage6_group_analysis.m`):**
   * Classifies subjects by **Arch Index (AI)** into clinical cohorts:
     - **High Arch (Pes Cavus):** $AI < 0.21$
     - **Normal Arch:** $0.21 \le AI \le 0.26$
     - **Flatfoot (Pes Planus):** $AI > 0.26$
   * Exports formatted ASCII dataset matrices ready for statistical evaluation in SPSS / ANOVA.

---

## 🦶 12 Anatomical Plantar Foot Regions

The plantar foot surface is divided into 12 functional zones:

| Box Index | Anatomical Region | Clinical Abbrev. | Description |
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

## ⚙️ Biomechanical Parameters

### 1. Ratio MT (Metatarsal Partition Ratio)
**Ratio MT** (default: `[30, 20, 20]`) specifies the transversal geometric partition of the forefoot from the **Medial** to **Lateral** boundary:

```
[ Medial Boundary ]                                              [ Lateral Boundary ]
├─────────────────────┬──────────────┬──────────────┬───────────────────────────────┤
│      0% - 30%       │  30% - 50%   │  50% - 70%   │          70% - 100%           │
│    (Width: 30%)     │ (Width: 20%) │ (Width: 20%) │         (Width: 30%)          │
├─────────────────────┼──────────────┼──────────────┼───────────────────────────────┤
│  Box 1 : Toe 1      │ Box 2 : Toe 2│ Box 3 : Toe 3│  Box 4 : Toe 4-5              │
│  Box 5 : MT 1       │ Box 6 : MT 2 │ Box 7 : MT 3 │  Box 8 : MT 4-5               │
└─────────────────────┴──────────────┴──────────────┴───────────────────────────────┘
```

* **Anatomical Alignment:** Accommodates the broader anatomical footprint of the first metatarsal head (MT1) and lateral column (MT4-5) compared to central metatarsals (MT2, MT3).
* **Automated Standardization:** Ensures consistent anatomical bounding across varied foot lengths and widths without manual re-drawing.
* **Customizability:** Adjustable via the GUI parameter field for specialized clinical populations (e.g., pediatric feet, diabetic neuropathy, *hallux valgus*).

### 2. Body Weight Normalization
Regional force profiles can be normalized to percentage of body weight (%BW) using the subject's weight in kilograms (default: 70 kg):
$$\%BW = \frac{F_{\text{measured}}\text{ (N)}}{\text{Body Weight (kg)} \times 9.80665\text{ m/s}^2} \times 100\%$$

---

## 📂 Repository Structure

```text
├── rscan_gui.m                             # 🚀 PRIMARY APPLICATION: Graphical User Interface Studio
├── main_rscan_pipeline.m                   # Batch Processing Engine (Master Orchestrator)
├── src/                                    # Modular stage functions & geometry algorithms
│   ├── resolve_output_dir.m                # Smart output directory resolution & fallback logic
│   ├── scan_subject_trials.m               # Dynamic trial scanner & flat-folder detector
│   ├── stage1_extract_3d_cop.m             # Stage 1: 3D spatio-temporal matrix & COP extraction
│   ├── stage2_segment_12boxes.m            # Stage 2: 12-box geometric surface partitioning
│   ├── stage3_compute_fap.m                # Stage 3: Regional Force, Area & Pressure (101 points)
│   ├── stage4_temporal_events.m            # Stage 4: Contact timing & %BW normalization
│   ├── stage5_subject_aggregation.m        # Stage 5: Multi-trial subject ensemble averaging
│   ├── stage6_group_analysis.m             # Stage 6: Arch Index classification & SPSS export
│   ├── func_footaxis.m                     # Geometric foot axis computation
│   ├── func_abcd_in.m                      # Robust matrix polygon cell inclusion
│   ├── func_perpendical_point_to_line.m    # 2D vector algebra perpendicular projection
│   └── func_box_link.m                     # Boundary vertex connection helper
│
├── coba rs scan/                           # Legacy reference scripts (preserved 100%)
├── 20260824_rscop_box_pressure/           # Legacy data & reference outputs (preserved 100%)
├── .gitignore                              # Git filter for raw data (~3.85 GB)
└── README.md                               # Project documentation
```

---

## 🚀 Execution Options

### Option 1: Desktop GUI (Recommended)
```matlab
rscan_gui
```

### Option 2: Script / Command-Line Interface (CLI)
```matlab
% 1. Run default batch pipeline on all auto-detected subjects:
main_rscan_pipeline();

% 2. Process specific subject(s) with custom output folder:
main_rscan_pipeline('subject', {'R_t000', 'L_t000'}, 'output_dir', 'D:\MyResults');

% 3. Execute specific stages only (e.g. Stages 1 through 3):
main_rscan_pipeline('stages', 1:3);

% 4. Custom body weight normalization (e.g. 75 kg):
main_rscan_pipeline('bodyweight', 75);
```

### 📁 Smart Output Resolution & Fallback
The pipeline automatically formats the output folder as `<subject_name>_<YYYYMMDD>`.
- If the target folder is empty, output is saved directly in `<output_dir>/<subject_name>_<YYYYMMDD>`.
- If the folder contains previous results, it automatically routes to `<output_dir>/output/<subject_name>_<YYYYMMDD>`.
- Inside each subject directory, structured stage subfolders (`1_step_level` to `6_group`) are maintained.

---

## 📄 License & Citation
Developed for plantar pressure biomechanics research and clinical gait analysis. All rights reserved.
