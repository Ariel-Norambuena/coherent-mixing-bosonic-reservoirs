# Reproducibility

## Compact reproduction from archived results

From the repository root, regenerate the final analysis tables and vector
figures:

```powershell
matlab -batch "run_all('analysis')"
```

Run the same analyses plus compact row-count, finite-value, identifier-order,
paired-claim, endpoint, and figure-presence checks:

```powershell
matlab -batch "run_all('verify')"
```

These commands constitute the public compact path. They regenerate derived
analyses and figures from versioned CSV/JSON tables and fixed signal seeds;
they do not rerun the dynamical banks that produced the seed-level tables. On
the tested 12-core/24-thread workstation, `run_all('verify')` takes about one
minute and the compact repository occupies less than 50 MB before MATLAB
regenerates PDF/PNG figures.

The manuscript source is distributed separately from this code/data
repository. In the complete author workspace it can be compiled with:

```powershell
latexmk -pdf -interaction=nonstopmode -halt-on-error Manuscript/Article_submission_20260813.tex
latexmk -pdf -interaction=nonstopmode -halt-on-error Manuscript/Supplement_submission_20260813.tex
```

## Frozen confirmatory protocol

The primary physical configuration is
`figure3/configs/narma_locked_config_20260810.json`, SHA-256
`68eec107bb9bf7092b5954991020244521346c85a256d44deb4890394b25f41d`.
The comparison configuration is
`figure3/configs/narma_locked_comparison_config_20260810.json`, SHA-256
`aee5d4687004f806762a648cd8c90f583d70bf4c327d68856613ad051a6672ba`.

Offsets 101--110 form the validation-only selection bank. Offsets 1001--1030
form the locked bank. Development offsets are disjoint. No physical, feature,
or ridge choice is selected from locked outputs.

## Full numerical regeneration

The following launchers regenerate the submission-facing dynamical banks. Run
them from the repository root in a clean working copy; they are expensive and
collision guarded:

```powershell
powershell -File "figure3/run_narma_locked_pairs_parallel_20260810.ps1"
powershell -File "figure3/run_narma_baseline_locked_parallel_20260810.ps1"
powershell -File "figure3/run_narma_mechanism_ablation_parallel_20260810.ps1"
powershell -File "figure3/run_narma_measurement_robustness_parallel_20260810.ps1"
powershell -File "figure3/run_minimal_architecture_stage_a_parallel_20260811.ps1"
powershell -File "figure3/run_minimal_architecture_copy_parallel_20260811.ps1"
powershell -File "figure3/run_minimal_architecture_locked_parallel_20260811.ps1"
powershell -File "figure3/run_phase_channel_selection_parallel_20260811.ps1"
powershell -File "figure3/run_phase_channel_locked_parallel_20260811.ps1"
powershell -File "figure3/run_equal_frequency_control_parallel_20260812.ps1"
powershell -File "figure3/run_dynamic_feature_audit_multioffset_20260813.ps1"
```

After the trajectory summaries exist, rerun MAT-dependent analyzers and the
no-leakage, alignment/split/metric, and cached/direct tests with:

```powershell
matlab -batch "run_all('full_audit')"
```

The full path was tested on Windows 11 with MATLAB R2025b, 64 GB RAM, and 24
logical processors. The complete author workspace currently occupies about
7.4 GB, almost entirely trajectory MAT files. Individual banks were executed
as separate multi-process batches, so no single end-to-end wall time is
claimed; runtime depends strongly on worker count and storage throughput.
Existing paper-grade outputs should be archived before an independent rerun.

## Verification scope

The complete archival checks cover validation/test isolation, NARMA10
recurrence and target alignment, causal split boundaries, independent metric
calculations, cached/direct feature equivalence, deterministic repeated
execution, solver convergence, exact Kerr-free contraction, finite values,
identifier ordering, pairwise intervention directions, and figure provenance.

The minimal architecture uses fresh NARMA10 offsets 3001--3030. The coherent
phase-channel task uses validation offsets 201--210 and locked offsets
4001--4030. Their frozen configuration hashes are listed in `README.md` and
`RESULTS_MANIFEST.md`.

The public compact release includes the post-review equal-frequency, full-I/Q,
and multi-offset centered-feature photon/Kerr/thermal tables.
`run_all('analysis')` regenerates the revised receiver and task figures from
these tables. The launchers above regenerate MAT-dependent controls in the
archival workspace; `analyze_phase_channel_full_iq_20260812.m` independently
regenerates the digital full-I/Q table without rerunning the reservoir.

See `RESULTS_MANIFEST.md` for script, configuration, input, output, and SHA-256
lineage of each submission-facing artifact.
