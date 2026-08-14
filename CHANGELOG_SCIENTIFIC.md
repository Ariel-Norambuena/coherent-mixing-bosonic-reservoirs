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

## Coefficient-budget comparison

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

## 2026-08-11 final-referee extension

- Replaced the weak single-trajectory Mackey--Glass diagnostic with a synthetic
  coherent BPSK phase stream defined by a fixed complex five-tap channel,
  nonlinear phase rotation, additive circular Gaussian noise, and decision
  delay two.
- Prospectively froze a deterministic architecture reduction before fresh testing.
  Validation selected one 12-mode copy with global modulation at `J=0.65`.
  One, two, and three identical copies are redundant to numerical roundoff.
- On fresh NARMA10 offsets 3001--3030, hopping improves all 30 pairs; mean NRMSE
  changes from `0.331769` to `0.282166`.
- On fresh phase-channel offsets 4001--4030, the uncoupled bosonic map has lower
  soft NRMSE than NVAR2 in all 30 pairs, while hopping worsens all 30. Binary
  error is saturated, so no detection-advantage claim is made.
- The manuscript now begins from the driven Bose--Hubbard Hamiltonian and an
  explicit Lindblad equation with independent vacuum amplitude damping. It
  states that dephasing, thermal occupation, two-photon loss, and correlated
  baths are absent.
- Final compact reproduction, isolated Overleaf compilation, LaTeX audit, and
  page-by-page visual inspection pass.

## 2026-08-11 comparative-referee closure

- Replaced the occupation-based receiver conversion with channelwise centered
  quadrature variance propagated through standardization and PCA. The median
  retained-component counts at the normalization reference are `1.61165e-7`
  and `5.93421e-8` for `J=0/0.65`.
- Common scaling to `N_eff=1e4` would require `13.8988/37.7472 W/ring`, but a
  representative stoichiometric-SiN audit gives residual-Kerr ratios
  `1.40e4/3.55e3`. These are incompatibility diagnostics, not proposed powers.
- Added the reviewer-requested equal-frequency control. A deterministic
  nondegenerate spectrum is necessary even though random disorder is not.
- Added full-I/Q linear and NVAR2 baselines. Their mean locked NRMSE values are
  `0.089053` and `0.092861`, and both beat every phase-only method in 30/30
  realizations. The task is now framed as a synthetic phase-stream stress test.
- Separated the 338 trained readout weights from explicit PCA and fused-linear
  MAC counts; changed the comparison terminology to coefficient budget.
- Replaced "preregistered" by "prospectively frozen" and withdrew all
  low-power, direct coherent-equalizer, and fabrication-ready claims.

## 2026-08-13 editorial and figure-legibility pass

- Increased axis, tick, annotation, colorbar, and legend typography across all
  submission-facing figure generators.
- Moved legends away from data or into shared exterior positions so that they
  no longer obscure curves, paired realizations, or uncertainty intervals.
- Regenerated the nine affected PDF/PNG figure pairs from the unchanged compact
  numerical tables and refreshed their SHA-256 lineage in `RESULTS_MANIFEST.md`.
- Reframed NARMA10 as a structure-known diagnostic of fading memory and
  nonlinear mixing, rather than an application proxy or universal reservoir
  benchmark.

## 2026-08-13 v2.2.3 applied-frontier and reproducibility closure

- Extended the centered-signal receiver calculation from one representative
  trajectory to all ten prospectively defined selection offsets for both
  coupling conditions.
- Quantified the conservative residual-Kerr boundary and the four-to-five-order
  useful-signal/Kerr improvement required to reach the numerical precision
  target without crossing it.
- Corrected every public path in `REPRODUCIBILITY.md` from the archival
  `Figure 3/` name to the actual public `figure3/` directory and separated
  compact reproduction from full numerical regeneration.
- Strengthened the compact test with explicit identifier ordering and direct
  per-realization checks that both full-I/Q baselines beat every phase-only
  baseline in all 30 locked pairs.
- Lifted the Fig. 1 phase annotation and simplified the dense Fig. 6(d) labels.

## 2026-08-14 v2.2.4 mechanical submission closure

- Added a repository-level `.gitattributes` policy that fixes tracked text to
  LF and prevents platform-dependent CRLF conversion from invalidating the
  published SHA-256 manifest.
- Documented the byte-level hash convention and clean-checkout verification
  procedure in `REPRODUCIBILITY.md`.
- Closed manuscript wording and metadata items only; no architectures,
  simulations, numerical results, figures, or scientific claims were changed.
