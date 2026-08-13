# Coherent mixing in bosonic reservoirs

MATLAB code, frozen configurations, compact seed-level tables, and final
figure generators for:

> **Coherent mixing and observable-dependent temporal processing in
> driven-dissipative bosonic reservoirs**

The central result concerns a Kerr-free, driven, lossy bosonic network with
input-dependent detuning. The state equation is affine-bilinear, equal-input
trajectories contract at the loss-controlled rate, and coherent hopping changes
which temporal histories are exposed by a specified observable. The original
30-pair NARMA10 bank and a fresh deterministic one-copy bank both show a hopping
gain in every realization. Compact intensity readout and coherent phase-channel
processing reverse the intervention. Full-I/Q digital baselines outperform all
phase-only models, so the second task is a synthetic phase-stream stress test,
not a competitive coherent equalizer. The repository therefore supports an
observable- and task-dependent claim, not a universal or quantum advantage.

## Quick reproduction

Requirements: MATLAB R2025b. The compact path uses the Statistics and Machine
Learning Toolbox for table/statistical utilities; Parallel Computing Toolbox is
needed only by the long multi-process launchers.

From the repository root:

```powershell
matlab -batch "run_all('analysis')"
matlab -batch "run_all('verify')"
```

`analysis` regenerates every final vector figure from compact tables or fixed
seeds. `verify` additionally checks table dimensions, finite values, identifier
order, frozen endpoints, and the 30-pair directions of the minimal NARMA10,
phase, and full-I/Q comparisons. Neither command needs the large temporary
state caches.

## Frozen protocol

- Physical config: `figure3/configs/narma_locked_config_20260810.json`
- SHA-256: `68eec107bb9bf7092b5954991020244521346c85a256d44deb4890394b25f41d`
- Comparison config: `figure3/configs/narma_locked_comparison_config_20260810.json`
- SHA-256: `aee5d4687004f806762a648cd8c90f583d70bf4c327d68856613ad051a6672ba`
- Selection offsets: 101--110
- Locked offsets: 1001--1030
- Primary readout: 26 PCs, 13 causal delay blocks, 339 coefficients including bias
- Minimal architecture: one deterministic 12-mode copy, global gain `1.00`,
  config SHA-256 `74a9ddf95b1e55f14ff6d6b5658083335c3160a4f9789597116d4b427c11e631`
- Phase-channel config SHA-256:
  `14a59690c6d3905d24daa7b69543ebc3a918246f7e413113336a604998c5627e`
- Deterministic spectrum control: ten paired validation offsets, with an
  equal-frequency condition that removes the hopping gain.
- Centered-signal receiver audit: no low-power or fabrication-ready operating
  point is claimed.

No physical, feature, or ridge choice is selected from the locked test bank.

## Repository contents

- `figure1/`, `figure2/`: legacy Kerr-response and synchronization generators
  retained as development provenance; they are not part of the current claim.
- `figure3/`: simulator, selection and locked launchers, classical baselines,
  ablations, capacities, perturbations, tests, compact tables, and final plots.
- `run_all.m`: compact reproduction, compact verification, and archival audit
  entry point.
- `RESULTS_MANIFEST.md`: script/table/figure lineage with SHA-256 hashes.
- `REPRODUCIBILITY.md`: compact and full execution commands.
- `ENVIRONMENT.md`: tested software environment.
- `CHANGELOG_SCIENTIFIC.md`: disposition of the simulated referee report.

## Full archival audit

After independently regenerating the trajectory summaries, run:

```powershell
matlab -batch "run_all('full_audit')"
```

This recomputes MAT-dependent statistics and executes the no-leakage,
NARMA-alignment/split/metric, and cached/direct-equivalence tests. The expensive
locked, baseline, mechanism, and robustness launchers are documented in
`REPRODUCIBILITY.md` and collision guarded.

## Data scope

Compact CSV tables contain every numerical value used in the article and all
seed-level endpoints needed for the published plots, including the fresh
minimal-architecture and synthetic phase-stream banks, equal-frequency
control, full-I/Q audit, and ten-offset centered-signal physical audit. Large complex-state
caches are excluded because the tracked launchers regenerate them
deterministically. The robustness claim is calibration conditioned; the
repository does not claim uncalibrated fabrication tolerance or a physically
self-consistent low-power scaling point.

## Citation and license

Use `CITATION.cff` to cite this software and the associated article. Code is
released under the MIT License. Numerical tables and figures may be reused with
attribution to the associated article and repository.
