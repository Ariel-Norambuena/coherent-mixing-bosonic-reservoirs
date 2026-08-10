# Scientific revision changelog

Disposition of `FEEDBACK_CODEX_PRAPPLIED.md` for the 2026-08-10 revision.
"Resolved by scope" means that the unsupported claim was removed or demoted,
as explicitly permitted by the referee report.

| Priority | Referee issue | Disposition | Primary evidence |
|---|---|---|---|
| P0 | Freeze the pre-review record | Complete | `review_baseline_20260807/BASELINE_AUDIT.md`, SHA-256 manifest |
| P0 | Validation-only selection | Complete | disjoint banks, stage-1 and stage-2 tables, no-leakage smoke test |
| P0 | At least 30 locked pairs | Complete | `NARMALockedPairs_Raw_20260810.csv`, all 30 quadrature pairs improve |
| P0 | Robust paired inference | Complete | bootstrap interval, sign-flip permutation, sign test, paired effect size |
| P0 | Equal trained-coefficient budgets | Complete | physical, input-delay, NVAR, and tapped-ESN error-budget curves |
| P0 | Strong temporal baselines | Complete | input delays, NVAR2, NVAR3, and validation-selected tapped ESN |
| P0 | Complete numerical protocol | Complete | frozen JSON, Supplemental Table I, `REPRODUCIBILITY.md` |
| P0 | Encoding and disorder ablations | Complete | nine equal-budget conditions over ten selection offsets |
| P1 | Exact Kerr-free contraction | Complete | analytic proof and independent exact-propagation verification |
| P1 | Noncommutativity mechanism | Complete, negative result | noncommutativity raises rank but is neither necessary nor predictive of error |
| P1 | Processing capacities | Complete | linear, quadratic, and cross-product capacities from untapped physical states |
| P1 | Mackey--Glass generalization | Resolved by scope | single-trajectory diagnostic moved to Supplemental Material; no general forecast claim |
| P1 | NARMA10 robustness | Complete | 2,900 rows, nine perturbation families, zero-shot and recalibrated protocols |
| P1 | Device-level mapping | Complete as illustrative mapping | bandwidth, power estimate, resonators, controls, detectors, ADCs, and MAC count |
| P2 | Synchronization scope | Complete | moved to Supplemental Material and separated from temporal-learning evidence |
| P2 | Mathematical notation | Complete | Hermitian hopping, rotating-frame detuning, locking absolute values, susceptibility definition |
| P2 | Remove unused fluctuation appendix | Complete | no incomplete Nambu/covariance appendix remains |
| P2 | Streamline article | Complete | 7 pages, 5 logical figures, 4 displayed equations, no forced page breaks |
| P2 | Increase figure typography | Complete | all final generators use publication-scale labels, ticks, and legends |
| P2 | Data and code statement | Complete | manuscript citation and public GitHub URL |

## Locked result

- Frozen architecture: `K=0`, `J=0.65`, input gain `1.25`, 55 integration
  steps, virtual nodes `[11 20 29 37 46 55]`, taps `[0:10 12 15]`, 26 PCs,
  and 339 coefficients including bias.
- Config SHA-256:
  `68eec107bb9bf7092b5954991020244521346c85a256d44deb4890394b25f41d`.
- Quadrature mean test NRMSE: `0.311757 +/- 0.014512` at `J=0` and
  `0.278719 +/- 0.018099` at `J=0.65`.
- Mean paired reduction: `0.033039`; 95% percentile-bootstrap interval
  `[0.029688, 0.036143]`; `30/30` pairs improve; paired `d_z=3.606`.
- Intensity mean test NRMSE: `0.314494` at `J=0` and `0.324800` at `J=0.65`;
  only `7/30` pairs improve. The intervention therefore reverses by observable.

## Fair comparison

At the requested 351-coefficient budget, mean locked test NRMSE is `0.384590`
for input delays, `0.120733` for NVAR2, `0.815663` for NVAR3, and `0.259619`
for the tapped ESN. The article states that the task-matched quadratic NVAR is
stronger and makes no algorithmic-superiority claim for the physical system.

## Mechanism and capacity

The uniform-encoding coupled condition has zero commutator norm and matches or
slightly improves the heterogeneous coupled conditions. Removing base or copy
disorder leaves performance essentially unchanged. Drive-only encoding is
substantially worse, identifying detuning modulation as essential within the
tested family. Heterogeneous encoding raises effective rank but does not lower
error. Coupling increases summed linear capacity from about `6.8` to
`10.6--10.7`; measured quadratic and cross-product capacities do not increase.

## Robustness and implementation

The robustness archive covers clean readout, detector SNR, photon-scaled noise,
quantization, channel reduction, failed modes, gain mismatch, correlated noise,
and sampling jitter. Every family is evaluated zero shot and after PCA/readout
recalibration. Recalibration preserves clean-like performance under moderate
quantization, channel removal, and failed modes, but the coupled advantage is
lost at 40 dB detector SNR. The claim is therefore calibration conditioned.

The illustrative hybrid SiN/TFLN mapping uses 36 resonators, 36 local detuning
controls, three shared input modulators, 1.641 ns symbols, a 33.5 GHz mask update
rate, and six digitized samples per symbol. Simultaneous quadrature readout uses
36 optical 90-degree hybrids, 144 photodiodes, and 72 differential ADC outputs.
The ideal on-chip drive estimate excludes coupling loss, local-oscillator power,
RF drivers, ADCs, stabilization, and wall-plug efficiency; the article says so.

## Final verification

- `matlab -batch "run_all('analysis')"`: PASS.
- `matlab -batch "run_all('verify')"`: compact table/figure integrity PASS.
- Complete MAT-dependent audit and smoke-test sequence: PASS.
- No-leakage smoke test: PASS; all selection-mode test metrics are `NaN`.
- NARMA alignment, split-boundary, and independent metric test: PASS.
- Cached/direct stage-2 equivalence test: PASS.
- Solver convergence: maximum NRMSE change `2.39e-10`, PASS.
- Seed determinism: exact repeated output, PASS.
- Kerr-free contraction: fitted exponent `-0.06=-kappa/2`, maximum relative
  error `3.242e-14`, PASS.
- Clean, marked, and Supplemental LaTeX builds: PASS with zero overfull boxes,
  undefined references/citations, or stuck/deferred floats.
- All pages of the final PDFs were rendered and visually inspected.
