# Coherent mixing in bosonic reservoirs

MATLAB source code for the figures and numerical analyses accompanying
"Coherent mixing and nonlinear temporal processing in driven-dissipative
bosonic reservoirs."

This is a code-only repository. Generated figures, numerical tables, MAT
caches, and manuscript files are intentionally excluded. Running the scripts
creates those artifacts locally.

## Requirements

- MATLAB R2025b (tested)
- Parallel Computing Toolbox is optional and used only when the environment
  variable `KERR_FIG2_PARALLEL=1` is set for the synchronization map
- Sufficient disk space for the full NARMA10 and Mackey-Glass caches

Run all commands from the repository root.

## Fast verification

The NARMA10 smoke test exercises simulation, feature construction, train-only
preprocessing, validation-selected ridge regression, and file export:

```powershell
matlab -batch "KERR_NARMA_SMOKE=true; KERR_NARMA_OUTPUT_TAG='Smoke'; KERR_NARMA_SKIP_PHYSICAL_ABLATIONS=true; run('figure3/Fig3_KerrReservoir_NARMA10_Reproducible.m')"
```

Smoke and quick modes verify the pipeline only; their numerical values are not
paper results.

## Figures 1 and 2

```powershell
matlab -batch "run('figure1/Fig1_KerrResponse_Bistability.m')"
matlab -batch "run('figure2/Fig2_Kerr4_TwoTone_SyncMap.m')"
```

Figure 2 computes its synchronization map when no local MAT cache is present.
The full grid is substantially slower than Figure 1.

## NARMA10 pipeline

The main simulator contains the physical model, deterministic seed schedules,
feature blocks, PCA, tapped readouts, ridge selection, and smoke/quick modes.

```powershell
matlab -batch "run('figure3/Fig3_KerrReservoir_NARMA10_Reproducible.m')"
matlab -batch "run('figure3/run_full_K_sweep_20260706.m')"
matlab -batch "run('figure3/run_full_J_sweep_20260720.m')"
matlab -batch "run('figure3/run_full_J_high_extension_20260720.m')"
```

After the coupling sweep, run four independently reseeded confirmations:

```powershell
matlab -batch "KERR_NARMA_SEED_OFFSET=1; run('figure3/run_targeted_J_seed_20260720.m')"
```

Repeat with offsets 2, 3, and 4, then consolidate the final coupling figure:

```powershell
matlab -batch "run('figure3/analyze_J_sweep_multiseed_20260720.m')"
```

The selection-realization feature ablations and their consolidation are:

```powershell
matlab -batch "run('figure3/run_full_feature_ablation_J00_20260722.m')"
matlab -batch "run('figure3/run_full_feature_ablation_J08_20260722.m')"
matlab -batch "run('figure3/analyze_feature_ablation_Jpair_20260722.m')"
```

For the compact quadrature and intensity confirmations, run the following for
offsets 1 through 4 and then consolidate:

```powershell
matlab -batch "KERR_NARMA_SEED_OFFSET=1; run('figure3/run_targeted_compact_features_seed_20260806.m')"
matlab -batch "run('figure3/analyze_compact_features_multiseed_20260806.m')"
```

The matched 350-state echo-state network and comparison figure are generated
with:

```powershell
matlab -batch "run('figure3/Fig3_ESN_Baseline_NARMA10_20260806.m')"
matlab -batch "run('figure3/analyze_ESN_baseline_20260806.m')"
```

Once the main and K-sweep summary MAT files exist, the final diagnostic panels
can be rebuilt without rerunning the physical simulations:

```powershell
matlab -batch "run('figure3/plot_final_narma_from_cache_20260807.m')"
```

## Mackey-Glass and robustness

Create the paired horizon-48 raw-feature caches:

```powershell
matlab -batch "KERR_MG_HORIZON=48; KERR_MG_CACHE_ONLY=true; KERR_MG_J=0; KERR_MG_LAUNCHER_TAG='MGH48RawJ0_20260806'; run('figure3/run_mackey_glass_horizon12_20260806.m')"
matlab -batch "KERR_MG_HORIZON=48; KERR_MG_CACHE_ONLY=true; KERR_MG_J=0.8; KERR_MG_LAUNCHER_TAG='MGH48RawJ08_20260806'; run('figure3/run_mackey_glass_horizon12_20260806.m')"
```

Then generate the capacity-controlled benchmark and hardware-oriented
robustness figure:

```powershell
matlab -batch "run('figure3/analyze_mackey_glass_capacity_20260806.m')"
matlab -batch "run('figure3/analyze_hardware_robustness_20260806.m')"
```

## Reproducibility conventions

Physical parameters are fixed within each comparison. Dataset, mask, and
disorder seeds are paired across the physical cases being compared. PCA and
standardization are fitted on training data only, ridge penalties are selected
on validation data, and the test split is evaluated after selection. Analysis
scripts assert that required artifacts exist and reject non-finite values.

The code writes all generated artifacts next to the script that creates them.
The `.gitignore` keeps those outputs out of version control.
