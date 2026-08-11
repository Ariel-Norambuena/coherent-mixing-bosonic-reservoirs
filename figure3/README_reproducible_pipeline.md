# Fig. 3 reproducible NARMA10 pipeline

## Final PRApplied revision workflow (2026-08-10)

The submission-facing result is no longer the legacy single-run Fig. 3 below.
It uses a validation-only two-stage selection, frozen JSON configurations, a
30-pair locked physical test, equal-coefficient classical comparisons,
mechanism and capacity diagnostics, and NARMA10 measurement perturbations.
Earlier sections are retained as development provenance and must not be used
for confirmatory claims.

From the project root, regenerate all compact analyses and final figures:

```powershell
matlab -batch "run_all('analysis')"
```

Run the complete compact reproduction plus table and figure integrity checks:

```powershell
matlab -batch "run_all('verify')"
```

The verified frozen physical point is `K=0`, `J=0.65`, input gain `1.25`, 55
integration steps per symbol, six virtual samples, 26 training-fitted PCs, 13
causal delay blocks, and 339 trained coefficients including bias. Its config
is `configs/narma_locked_config_20260810.json`, SHA-256
`68eec107bb9bf7092b5954991020244521346c85a256d44deb4890394b25f41d`.

The locked quadrature result contains 30 paired offsets: mean test NRMSE is
`0.311757` at `J=0` and `0.278719` at `J=0.65`; all 30 pairs improve. The
paired mean reduction is `0.033039`, with percentile-bootstrap 95% interval
`[0.029688, 0.036143]`. Compact intensity readout reverses the intervention,
so the manuscript claim is explicitly observable dependent.

At 351 trained coefficients, the mean locked baselines are `0.384590` for
input delays, `0.120733` for quadratic NVAR, `0.815663` for cubic NVAR under
the frozen short-delay budget, and `0.259619` for the tapped ESN. These values
exclude a claim of general superiority over classical reservoirs.

Mechanism ablations show that detuning modulation is essential within the
tested encoding family, whereas static disorder, heterogeneous `G`, and a
nonzero commutator are not required. Untapped processing-capacity diagnostics
associate coupling with an increase in linear memory from about `6.8` to
`10.6--10.7`; quadratic and cross-product capacities do not increase.

Measurement perturbations are reported under two distinct protocols. Zero-shot
tests freeze the clean PCA and readout. Recalibrated tests refit PCA, scaling,
ridge, and readout on perturbed training/validation data for every perturbation
family. The final robustness table contains 2,900 seed-level rows and 98
groups. The defensible claim is calibration-conditioned robustness, not passive
fabrication tolerance.

The final `run_all('verify')` execution passed on 2026-08-10. It regenerated
all submission-facing compact artifacts and validated row counts, finite
values, locked endpoints, and figure presence. In the complete archival
workspace, `run_all('full_audit')` additionally runs the MAT-dependent
no-leakage, independent alignment/split/metric, and cached/direct-equivalence
smoke tests; those tests also passed before the release was frozen.

Main script:

```powershell
matlab -batch "run('Figure 3/Fig3_KerrReservoir_NARMA10_Reproducible.m')"
```

Smoke test, for syntax and end-to-end checks only:

```powershell
matlab -batch "KERR_NARMA_SMOKE=true; run('Figure 3/Fig3_KerrReservoir_NARMA10_Reproducible.m')"
```

Quick test with the small K sweep:

```powershell
matlab -batch "KERR_NARMA_QUICK=true; KERR_NARMA_RUN_KSWEEP=true; run('Figure 3/Fig3_KerrReservoir_NARMA10_Reproducible.m')"
```

Quick test with a custom K list:

```powershell
matlab -batch "KERR_NARMA_QUICK=true; KERR_NARMA_RUN_KSWEEP=true; KERR_NARMA_SKIP_PHYSICAL_ABLATIONS=true; KERR_NARMA_KLIST=[0 -0.02 -0.05 -0.10 -0.20 -0.35 -0.50 -0.80 -1.10 -1.40 -1.70]; KERR_NARMA_OUTPUT_TAG='FullKListPilot_YYYYMMDD'; run('Figure 3/Fig3_KerrReservoir_NARMA10_Reproducible.m')"
```

Quick test with feature-block ablations:

```powershell
matlab -batch "KERR_NARMA_QUICK=true; KERR_NARMA_RUN_FEATURE_ABLATIONS=true; run('Figure 3/Fig3_KerrReservoir_NARMA10_Reproducible.m')"
```

Tagged feature-ablation smoke test verified on 2026-07-11:

```powershell
matlab -batch "KERR_NARMA_QUICK=true; KERR_NARMA_RUN_FEATURE_ABLATIONS=true; KERR_NARMA_OUTPUT_TAG='FeatureAblationSmoke_20260711'; run('Figure 3/Fig3_KerrReservoir_NARMA10_Reproducible.m')"
```

The test completed all five feature modes at both `K=-1.62` and `K=0`, wrote a
10-row compact CSV, and produced finite trajectories and metrics. See
`Fig3_FeatureAblationSmoke_20260711_analysis.md`. These reduced-run values are a
pipeline check only and must not be quoted as paper-grade results.

Recommended paper-grade feature-ablation command:

```powershell
matlab -batch "KERR_NARMA_RUN_FEATURE_ABLATIONS=true; KERR_NARMA_SKIP_PHYSICAL_ABLATIONS=true; KERR_NARMA_OUTPUT_TAG='FeatureAblationsFull_YYYYMMDD'; run('Figure 3/Fig3_KerrReservoir_NARMA10_Reproducible.m')"
```

`KERR_NARMA_SKIP_PHYSICAL_ABLATIONS=true` avoids the separate `K=0` and `J=0`
diagnostic pass; it does not remove the `K=0` cases from the feature-ablation
workflow.

For paper-grade runs, keep `cfg.quickTest = false` and use the default full-size configuration. The script fits PCA and ridge readouts independently for each physical case in the K sweep and physical ablations. By default it does not save large raw feature matrices.

Paper-grade independent K sweep launcher:

```powershell
matlab -batch "run('Figure 3/run_full_K_sweep_20260706.m')"
```

Sweep and feature-ablation runs export compact CSV summaries in addition to `.mat`, `.pdf`, and `.png` outputs.

Reference nonlinear-run numbers from the existing ensemble-masked run:

- full reservoir NRMSE: 0.3222
- true test R2: 0.8962
- no taps NRMSE: 0.7218
- input-only tapped baseline NRMSE: 0.5285
- K=0 diagnostic NRMSE: 0.2978
- J=0 diagnostic NRMSE: 0.3545

Paper-grade independent K sweep completed on 2026-07-06:

- CSV: `Fig3_KerrReservoir_NARMA10_Reproducible_KSweepFull_20260706_KSweep_summary.csv`
- MAT: `Fig3_KerrReservoir_NARMA10_Reproducible_KSweepFull_20260706_summary.mat`
- figure: `Fig3_KerrReservoir_NARMA10_Reproducible_KSweepFull_20260706_KSweep.pdf`
- best tested point: K=0, test NRMSE 0.3014, true test R2 0.9092, validation NRMSE 0.3146
- closest weak-K point: K=-0.02, test NRMSE 0.3079, true test R2 0.9052

This sweep does not support the claim that stronger Kerr dynamics improves NARMA10 in the tested grid. The current manuscript claim should remain task-dependent: Kerr provides synchronization landscapes and amplitude-dependent frequency pulling, while this temporal-regression benchmark favors the Kerr-free or very-weak-K regime.

## Coherent-coupling sweep and multi-seed confirmation

The full two-regime coupling sweep completed on 2026-07-20:

```powershell
matlab -batch "run('Figure 3/run_full_J_sweep_20260720.m')"
```

It tests `J=[0,0.10,0.20,0.34,0.50,0.65]` at `K=0` and `K=-1.62`.
The targeted Kerr-free extension is:

```powershell
matlab -batch "run('Figure 3/run_full_J_high_extension_20260720.m')"
```

It adds `J=[0.80,0.95,1.10]` at `K=0`. The selection realization has an
interior minimum at `K=0, J=0.80`: test NRMSE `0.24695`, compared with
`0.32018` at `J=0`. At `K=-1.62`, the sampled minimum is `J=0.50` with test
NRMSE `0.30145`, compared with `0.35384` at `J=0`.

After selecting `J=0.80`, fixed-parameter paired confirmations use:

```powershell
matlab -batch "KERR_NARMA_SEED_OFFSET=1; run('Figure 3/run_targeted_J_seed_20260720.m')"
```

Repeat with offsets `2`, `3`, and `4`. The offset changes the dataset base
seed, mask, base-reservoir disorder, and copy disorder; both `J` values share
those seeds within a pair. The stable-dataset generator may increment the base
dataset seed when a NARMA trajectory fails its finite-value check, so analyses
must read the effective `datasetSeed` stored in each MAT file. The effective
dataset seeds here are `132`, `1143`, `2150`, `3159`, and `4168`.

Reconstruct the compact tables, statistics, and manuscript figure with:

```powershell
matlab -batch "run('Figure 3/analyze_J_sweep_multiseed_20260720.m')"
```

Key outputs:

- `Fig3_JSweep_Combined_20260720.csv`
- `Fig3_JSweep_MultiSeed_20260720.csv`
- `Fig3_JSweep_MultiSeed_20260720_stats.csv`
- `Fig3_JSweep_MultiSeed_20260720_analysis.md`
- `Fig3_JSweep_MultiSeed_20260720.pdf` and `.png`

Across all five displayed pairs, test NRMSE is `0.3147 +/- 0.0090` at `J=0`
and `0.2573 +/- 0.0111` at `J=0.80` (mean +/- sample SD); all five improve.
For the four independent confirmation offsets only, the mean paired reduction
is `0.0534`, with 95% paired t interval `[0.0351,0.0717]` and two-sided
`p=0.0027`. Their mean input-only tapped baseline is `0.5450 +/- 0.0103`.

The defensible claim is specific: finite coherent coupling is a reproducible
resource for NARMA10 in this fixed architecture. The result does not establish
Kerr-enhanced temporal processing, quantum advantage, or a causal role for
synchronization cells. At `K=0`, nonlinear input-output processing can still
arise from the affine-bilinear input-state dynamics generated by
input-dependent detuning. The quadrature-only ablation below shows that
nonlinear measured observables are not required for the coupling gain.

## Kerr-free feature-block ablation

Paper-grade feature-block runs for the selection realization completed on
2026-07-22 at `K=0`, with paired `J=0` and `J=0.80` cases. The implementation
caches the complex trajectories and reconstructs each observable block from
the same states, so the comparison does not pay for or introduce a new
dynamical realization per block. Direct-versus-cached smoke checks gave zero
maximum absolute difference for all five blocks.

Reconstruct the paired table and figure with:

```powershell
matlab -batch "run('Figure 3/analyze_feature_ablation_Jpair_20260722.m')"
```

Key outputs:

- `Fig3_FeatureAblation_JPair_20260722.csv`
- `Fig3_FeatureAblation_JPair_20260722_analysis.md`
- `Fig3_FeatureAblation_JPair_20260722.pdf` and `.png`
- tagged full-run MAT/CSV outputs for `FeatureAblationK0J00Full_20260722` and
  `FeatureAblationK0J08Full_20260722`

Selection-realization test NRMSE values:

| Feature block | `J=0` | `J=0.80` | Absolute reduction |
|---|---:|---:|---:|
| Quadratures | 0.32899 | 0.25419 | 0.07480 |
| Number statistics | 0.32652 | 0.23189 | 0.09463 |
| Nonlinear number | 0.32551 | 0.24499 | 0.08052 |
| Phase/coherence | 0.31899 | 0.25150 | 0.06749 |
| All observables | 0.32018 | 0.24695 | 0.07323 |

All blocks improve with coupling. The quadrature-only result isolates the
affine-bilinear dynamical mechanism because it uses only `Re(beta_i)` and
`Im(beta_i)`. Compact number statistics are best on this realization and are
experimentally attractive, but that ranking is not yet a multi-seed result.
The launcher `run_targeted_compact_features_seed_20260722.m` is ready for
sequential paired confirmations. Attempts on 2026-07-23 were not started
because MATLAB could not communicate with required MathWorks services
(`5201`) even for a version-only command. Service access was restored by
2026-07-28/29, and the dedicated quick-mode smoke test completed with tag
`CompactFeaturesSmoke_20260728`. Its four CSV rows are finite, the MAT file
contains the expected 900-sample quick trajectory, and both compact blocks
improve with coupling:

- quadratures: test NRMSE `0.86592 -> 0.67987`;
- number statistics: test NRMSE `1.71230 -> 0.81993`.

These deliberately undersized quick-mode errors are pipeline checks only and
must not be quoted as scientific performance. They verify that the sequential
full-size launcher can be resumed without changing the manuscript claim.

The collision-safe launcher added on 2026-08-06 is:

```powershell
matlab -batch "KERR_NARMA_SEED_OFFSET=1; run('Figure 3/run_targeted_compact_features_seed_20260806.m')"
```

It refuses to run when its output tag already exists. Its dedicated quick-mode
smoke test completed without NaN/Inf values, and the first full-size independent
confirmation finished in approximately 9.6 minutes. At seed offset 1:

| Feature block | `J=0` | `J=0.80` | Absolute reduction |
|---|---:|---:|---:|
| Quadratures | 0.319871 | 0.258394 | 0.061476 |
| Number statistics | 0.315050 | 0.242440 | 0.072610 |

Both blocks improve, and number statistics again outperform quadratures at the
coupled point. Offsets 2--4 were subsequently completed and consolidated as
described below. See `Fig3_CompactFeatures_Seed01_20260806_analysis.md`.

## Compact-feature multi-seed result (2026-08-06)

Offsets 1--4 completed with finite CSV/MAT outputs. Reconstruct the final table,
paired statistics, and three-panel figure with:

```powershell
matlab -batch "run('Figure 3/analyze_compact_features_multiseed_20260806.m')"
```

Confirmation means (mean +/- sample SD):

| Feature block | `J=0` | `J=0.80` | Mean paired reduction |
|---|---:|---:|---:|
| Quadratures | 0.32570 +/- 0.00867 | 0.26578 +/- 0.00593 | 0.05992 |
| Number statistics | 0.32263 +/- 0.01016 | 0.24677 +/- 0.00608 | 0.07585 |

The 95% paired intervals are `[0.05181,0.06803]` for quadratures and
`[0.06685,0.08486]` for number statistics. All four pairs improve. At `J=0.80`,
number statistics outperform quadratures in all four confirmations by 0.01901
NRMSE on average.

## Matched ESN baseline (2026-08-06)

`Fig3_ESN_Baseline_NARMA10_20260806.m` implements a sparse tanh ESN with 350
recurrent states. Hyperparameters are selected on offset zero and fixed for
offsets 1--4. The ESN mean test NRMSE is `0.29933 +/- 0.07653`. Paired 95%
intervals for bosonic minus ESN error include zero for quadratures and number
statistics, so the manuscript claims competitive performance and lower
observed variability, not classical superiority.

## Mackey-Glass and hardware robustness (2026-08-06)

`run_mackey_glass_horizon12_20260806.m` accepts `KERR_MG_HORIZON`. Direct
horizon-12 and horizon-48 runs with 350 PCs saturated for both physical cases;
these are retained as diagnostics and are not used for a coupling claim.
`analyze_mackey_glass_capacity_20260806.m` caps the tapped readout at 351
coefficients, selects 26 PCs/339 coefficients by validation, and evaluates test
once. Horizon-48 test NRMSE is `0.03871` at `J=0`, `0.06951` at `J=0.80`, and
`0.68768` for input-only linear delays. The reversal from NARMA10 is reported
explicitly: mixing is task-dependent.

`analyze_hardware_robustness_20260806.m` evaluates additive intensity noise,
3--12 bit quantization, random subsets of 3/6/9/12 measured modes, and subsets
of three independently disordered copies. At the coupled point, 10% readout
noise gives `0.23954 +/- 0.00351`, six-bit quantization gives `0.17532`, six
measured modes give `0.07283 +/- 0.01525`, and one disordered copy gives
`0.08950 +/- 0.00440`.

The concrete low-power SiN translation is documented in
`PLATFORM_MAPPING_20260806.md`. The compact public-archive candidate is under
`release_pra_20260806/`; its Data Availability Statement still requires a
public repository DOI before submission.

## Manuscript numerical audit

Before submission-facing edits, cross-check the headline manuscript values
against the compact result artifacts with:

```powershell
matlab -batch "run('Figure 3/verify_manuscript_numerics_20260804.m')"
```

The verifier reads the independent K sweep, combined J sweep, four-confirmation
statistics, feature-block ablation, and `Manuscript/Article.tex`. It checks the
reported rounded values, the all-pairs-improve flag, the paired interval and
`p` value, and the explicit selection-realization limitation. A successful run
writes `ManuscriptNumericsAudit_20260804.md` with status `PASS`. MATLAB Code
Analyzer reports zero issues for the verifier.

## Legacy memory-capacity diagnostic

The four-mode memory-capacity artifact was audited and exactly reproduced on
2026-07-13. Its correct generator is now restored at
`Fig3_KerrReservoir_MemoryCapacity.m`; the accidentally substituted NARMA10 file
is preserved as `Fig3_KerrReservoir_MemoryCapacity_misnamed_NARMA10_backup_20260713.m`.

The isolated verification run and regenerated outputs are under
`legacy_memory_repro_20260713/`. See `Fig3_MemoryCapacity_Audit_20260713.md` for
the parameter table and exact array comparisons.

Legacy result: `MC=3.7331` for a four-mode reservoir at `K=-0.8`; 95.7% of the
capacity comes from delays 1--10. This is reproducible but does not match the
current 12-mode NARMA10 protocol and must not be presented as evidence for the
`K=0` versus `K=-1.62` operating-point comparison.

## Lyapunov audit

The legacy four-mode Lyapunov scan was audited on 2026-07-20 before any full
run. Its two-trajectory estimator lets the perturbation decay throughout the
settling interval without renormalization. A single-point smoke test confirmed
complete numerical collapse: zero separation and `NaN` LLE. Renormalizing
during settling produced a finite short-window diagnostic (`-0.448649`) at the
same point.

Files:

- `LyapunovSinglePointAudit_20260720.m`
- `LyapunovSinglePointAudit_20260720.csv`
- `Fig4_Lyapunov_Audit_20260720.md`

Do not launch the legacy 25-by-25 scan as written. It also changes the random
input sequence at every memory-slice point and does not represent the current
12-mode NARMA10 protocol. The required replacement is a conditional Lyapunov
diagnostic along the actual masked input trajectory, with warmup
renormalization, common inputs across `K` cases, multiple seeds, and convergence
checks.

## PRApplied major-revision protocol (2026-08-07)

The pre-review protocol is frozen under `../review_baseline_20260807/`. Its
automatic audit is:

```powershell
matlab -batch "run('Figure 3/audit_pre_review_protocol_20260807.m')"
```

The audit confirms that the old bosonic readout used 4551 coefficients
including bias (`350 PCs x 13 delay blocks + 1`), whereas the 350-state ESN
used 351. The old ESN comparison is therefore development evidence and must
not be described as matched by trained readout capacity.

The replacement selection design is frozen in
`configs/narma_revision_protocol_20260807.json`. Validate its disjoint seed
banks and coefficient accounting with:

```powershell
matlab -batch "run('Figure 3/validate_revision_protocol_20260807.m')"
```

The configuration reserves historical offsets 0--4 for development, offsets
101--110 for validation-only selection, and offsets 1001--1030 for a future
30-pair locked test. The banks do not overlap. The primary quadrature endpoint
uses at most 351 readout coefficients: 26 PCs over 13 delay blocks produce 339
coefficients including bias.

Selection mode is enforced inside the main simulator by setting
`KERR_NARMA_PROTOCOL_MODE='selection'`. In this mode `idxTest` is never passed
to the readout, every test metric is `NaN`, and K/J selection uses validation
NRMSE. The end-to-end guard is:

```powershell
matlab -batch "addpath('Figure 3'); test_selection_no_leakage_20260807"
```

The independent target-alignment, split-boundary, and metric audit is:

```powershell
matlab -batch "run('Figure 3/test_narma_alignment_split_metrics_20260808.m')"
```

It reconstructs every NARMA10 update from the saved input and target, verifies
the disjoint train/validation/test target indices, proves all taps are causal,
and independently recomputes NRMSE, coefficient of determination, and squared
correlation. The first 15 validation and test samples intentionally use past
features from the immediately preceding split because the benchmark is a
continuous online stream; no future feature or target is used.

Run one full stage-1 selection realization with:

```powershell
matlab -batch "KERR_NARMA_SELECTION_INDEX=1; run('Figure 3/run_narma_selection_stage1_20260807.m')"
```

where the index is 1--10. The launcher has a collision guard and reads the
seed offset and candidate grid from the frozen JSON. After all ten complete,
aggregate only validation metrics with:

```powershell
matlab -batch "run('Figure 3/analyze_narma_selection_stage1_20260807.m')"
```

Audit the stability of the validation-only choice without using test data:

```powershell
matlab -batch "run('Figure 3/analyze_narma_selection_stability_20260809.m')"
```

The `K=0, J=0.65` choice survives all ten leave-one-seed-out analyses and is
selected in 99.87% of 10,000 seed-bootstrap resamples under the frozen
0.005-NRMSE tie rule. Relative to `J=0`, validation improves in 9/10 seeds.
These diagnostics support carrying this point into stage 2, but they are still
selection evidence and must not be reported as locked-test inference.

Generate and audit the cached stage-2 execution plan without running a
reservoir:

```powershell
matlab -batch "run('Figure 3/plan_narma_stage2_cached_grid_20260810.m')"
```

The plan contains 120 unique trajectories and 480 validation-only readout
fits. Simulating each trajectory once at the union of the six- and ten-node
sampling indices reduces the simulation count by 75%. Each temporary complex
state cache is 145--169 MiB and must be processed in memory, one trajectory at
a time, rather than saved as a large result artifact. The two tap sets use 342
and 339 coefficients, both below the frozen 351-coefficient budget.

Do not execute the locked offsets until stage 2 is complete, the final
configuration has been written to a separate locked JSON, and its SHA-256 has
been recorded. The first locked execution is intentionally irreversible from
the standpoint of confirmatory inference.

## Final-referee physics revision (2026-08-11)

The final-referee revision is strictly Kerr-free and adds four deterministic
analysis/figure entry points:

```powershell
matlab -batch "run('Figure 3/generate_figure1_architecture_mechanism_20260811.m')"
matlab -batch "run('Figure 3/generate_figure2_selection_capacity_20260811.m')"
matlab -batch "run('Figure 3/generate_signal_complexity_20260811.m')"
matlab -batch "run('Figure 3/analyze_photon_precision_mapping_20260811.m')"
```

They generate the physical-mechanism diagram, the Kerr-free selection and
delay-resolved capacity figure, the original signal diagnostic, and the
coherent-receiver photon-precision mapping. The final two-task signal figure is
generated by `generate_signal_complexity_extended_20260811.m` and replaces the
single-trajectory Mackey--Glass diagnostic in the manuscript.

The photon mapping is an explicit implementation-level audit, not a low-power
claim. It assumes vacuum amplitude damping, a stated external-coupling fraction,
detector efficiency, integration time, and simultaneous-quadrature penalty. Its
result shows that the detector precision used in the stress tests requires a
high signal-photon budget under the illustrative optical translation.

## Minimal architecture and coherent phase channel (2026-08-11)

The additional benchmark was frozen before fresh-test evaluation in
`configs/additional_benchmark_protocol_20260811.json`, SHA-256
`ac1f6eed686e4c48a863b2f13a0d9e35078f3f7cdb802a5f0504b828098ba869`.
Run the validation-only architecture selection with:

```powershell
powershell -File "Figure 3/run_minimal_architecture_stage_a_parallel_20260811.ps1"
matlab -batch "run('Figure 3/analyze_minimal_architecture_stage_a_20260811.m')"
powershell -File "Figure 3/run_minimal_architecture_copy_parallel_20260811.ps1"
matlab -batch "run('Figure 3/analyze_minimal_architecture_copy_selection_20260811.m')"
```

Stage A contains 120 runs over ten selection offsets, four hopping values, and
three global gains. It selects `J=0.65`, gain `1.00`, uniform deterministic
parameters, and one 12-mode copy. Two and three identical deterministic copies
are redundant to numerical roundoff. The locked minimal configuration has
SHA-256
`74a9ddf95b1e55f14ff6d6b5658083335c3160a4f9789597116d4b427c11e631`.
The fresh NARMA10 bank is launched and aggregated with:

```powershell
powershell -File "Figure 3/run_minimal_architecture_locked_parallel_20260811.ps1"
matlab -batch "run('Figure 3/analyze_minimal_architecture_locked_20260811.m')"
```

All 30 offsets 3001--3030 improve with hopping. Mean NRMSE changes from
`0.331769` to `0.282166`; the paired reduction is `0.049604`, with bootstrap
95% interval `[0.047873,0.051384]`.

The coherent BPSK phase-channel task uses validation offsets 201--210 and
locked offsets 4001--4030. Its frozen configuration has SHA-256
`14a59690c6d3905d24daa7b69543ebc3a918246f7e413113336a604998c5627e`.
Run it with:

```powershell
powershell -File "Figure 3/run_phase_channel_selection_parallel_20260811.ps1"
matlab -batch "run('Figure 3/analyze_phase_channel_selection_20260811.m')"
powershell -File "Figure 3/run_phase_channel_locked_parallel_20260811.ps1"
matlab -batch "run('Figure 3/analyze_phase_channel_locked_20260811.m')"
```

On the fresh bank, the uncoupled bosonic map has lower soft NRMSE than NVAR2 in
all 30 pairs, while hopping worsens all 30 pairs. Bit-error rates are saturated,
so the result is not a detection-advantage claim. Regenerate the final compact
figures without MAT caches using:

```powershell
matlab -batch "run('Figure 3/generate_signal_complexity_extended_20260811.m')"
matlab -batch "run('Figure 3/generate_figure_minimal_phase_20260811.m')"
matlab -batch "run('Figure 3/plot_photon_precision_from_table_20260811.m')"
```
