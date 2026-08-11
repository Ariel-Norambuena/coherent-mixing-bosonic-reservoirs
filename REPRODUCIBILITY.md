# Reproducibility

## Quick reproduction from archived results

From the project root, regenerate the final analysis tables and vector figures:

```powershell
matlab -batch "run_all('analysis')"
```

Run the same analyses plus compact row-count, finite-value, endpoint, and
figure-presence checks:

```powershell
matlab -batch "run_all('verify')"
```

Inside the complete archival workspace, rerun the MAT-dependent analyzers and
the no-leakage, alignment/split/metric, and cached/direct smoke tests with:

```powershell
matlab -batch "run_all('full_audit')"
```

`full_audit` requires regenerated trajectory summaries that are intentionally
excluded from the compact public repository.

The analysis command reads compact, versioned CSV/JSON artifacts and fixed
signal seeds. It does not rerun any 30-pair dynamical bank or overwrite large
trajectory results.

Compile the clean manuscript and Supplemental Material in the full workspace:

```powershell
latexmk -pdf -interaction=nonstopmode -halt-on-error Manuscript/Article_revision_20260811.tex
latexmk -pdf -interaction=nonstopmode -halt-on-error Manuscript/Supplement_revision_20260811.tex
```

## Frozen confirmatory protocol

The primary physical configuration is
`Figure 3/configs/narma_locked_config_20260810.json`, SHA-256
`68eec107bb9bf7092b5954991020244521346c85a256d44deb4890394b25f41d`.
The comparison configuration is
`Figure 3/configs/narma_locked_comparison_config_20260810.json`, SHA-256
`aee5d4687004f806762a648cd8c90f583d70bf4c327d68856613ad051a6672ba`.

Offsets 101--110 form the validation-only selection bank. Offsets 1001--1030
form the locked bank. Development offsets are disjoint. Do not tune any
physical, feature, or ridge choice against the locked outputs.

## Full experiment launchers

The long physical and baseline jobs are retained for audit and independent
re-execution:

```powershell
powershell -File "Figure 3/run_narma_locked_pairs_parallel_20260810.ps1"
powershell -File "Figure 3/run_narma_baseline_locked_parallel_20260810.ps1"
powershell -File "Figure 3/run_narma_mechanism_ablation_parallel_20260810.ps1"
powershell -File "Figure 3/run_narma_measurement_robustness_parallel_20260810.ps1"
powershell -File "Figure 3/run_minimal_architecture_stage_a_parallel_20260811.ps1"
powershell -File "Figure 3/run_minimal_architecture_copy_parallel_20260811.ps1"
powershell -File "Figure 3/run_minimal_architecture_locked_parallel_20260811.ps1"
powershell -File "Figure 3/run_phase_channel_selection_parallel_20260811.ps1"
powershell -File "Figure 3/run_phase_channel_locked_parallel_20260811.ps1"
```

These launchers are computationally expensive and collision guarded. Existing
paper-grade outputs should be archived before an independent rerun.

## Verification scope

The complete archival checks cover validation/test isolation, NARMA10 recurrence and
target alignment, causal split boundaries, independent metric calculations,
cached/direct feature equivalence, deterministic repeated execution, solver
convergence, exact Kerr-free contraction, finite result values, and figure
provenance through compact result tables.

The minimal architecture uses fresh NARMA10 offsets 3001--3030. The coherent
phase-channel task uses validation offsets 201--210 and locked offsets
4001--4030. Their frozen configuration hashes are listed in `README.md` and
`RESULTS_MANIFEST.md`.

See `RESULTS_MANIFEST.md` for the script, configuration, input, output, and
SHA-256 lineage of every submission-facing artifact.
