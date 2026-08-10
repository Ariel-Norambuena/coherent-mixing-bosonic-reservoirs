# Concrete platform mapping

## Recommended implementation

The most direct implementation is a low-power, coherently coupled silicon-nitride
microring array with electro-optic input modulation and intensity detection at
drop ports. The simulated `K=0` operating point should be interpreted as the
linear-response limit of each resonator, not as the absence of material Kerr
susceptibility. Square-law photodetection supplies the measured intensity
features.

The mapping uses a physical loaded linewidth of
`kappa_phys/(2*pi) = 8 MHz`. This value is experimentally grounded: wafer-scale
SiN microrings have reported loaded linewidths near 8 MHz and intrinsic
linewidths near 6.5 MHz. Hybrid lithium-niobate-on-SiN devices provide an
electro-optic route to detuning and amplitude modulation, and coupled microring
dimers have been demonstrated on that platform.

If a dimensionless frequency `p` is mapped to angular frequency
`p*Omega_0`, then

`Omega_0/(2*pi) = [kappa_phys/(2*pi)]/0.12 = 66.67 MHz`.

| Quantity | Simulation | SiN example | Implementation |
|---|---:|---:|---|
| Modes | 12 | 12 microrings | Evanescently coupled ring array |
| Loaded loss `kappa/(2*pi)` | 0.120 | 8 MHz | Set by intrinsic and bus/drop coupling |
| Coherent hopping `J/(2*pi)` | 0.800 | 53.3 MHz | Ring-ring directional couplers |
| Detuning span | about `+/-1.05` | about `+/-70 MHz` | Electro-optic resonance tuning |
| Input-symbol duration | 0.6875 | 1.64 ns | About 609 Msymbol/s |
| Mask-update interval | 0.0125 | 29.8 ps | About 33.5 GHz update rate |
| Virtual samples | 10 per symbol | about 150 ps spacing | Multi-GHz photodetection/ADC |
| Observable | `n_i=|beta_i|^2` | Drop-port optical power | Square-law photodiodes |
| Read channels | 12 nominal | 6 remains effective in the tested ablation | Six or more drop-port channels per copy |
| Ensemble copies | 3 nominal | Spatial, wavelength, or repeated calibration realizations | One copy remains useful; three reduce variability |
| Kerr operation | `K=0` | Low-power linear regime | Avoid nonlinear frequency pulling |

## Evidence boundary

- This is a parameter translation, not an experimental demonstration.
- Coupler layout must reproduce the weighted first-, second-, and third-neighbor
  graph or an equivalent measured transfer matrix.
- The mask-update rate is the tightest hardware requirement. A recent linear
  microring reservoir simulation used 40 ps mask intervals and a 25 GHz signal
  bandwidth, close to the 29.8 ps scale above.
- The physical disorder test in the present simulations includes detuning SD
  `0.05` in model-frequency units (`0.42*kappa`), 10% mask and drive mismatch, and 4% hopping
  mismatch. Individual disordered copies still reached Mackey-Glass h=48 NRMSE
  between 0.0865 and 0.0945 under the 339-coefficient readout budget.

## Primary sources

- J. Liu et al., high-yield SiN resonators with a most-probable intrinsic
  linewidth of 6.5 MHz and measured loaded linewidths around 8 MHz:
  https://doi.org/10.1038/s41467-021-21973-z
- M. Churaev et al., heterogeneous lithium-niobate-on-SiN integration,
  electro-optic electrodes, and coupled microring dimers:
  https://doi.org/10.1038/s41467-023-39047-7
- A. Mataji-Kojouri et al., a linear microring reservoir using photodetection,
  40 ps mask intervals, and NARMA10/Mackey-Glass benchmarks:
  https://doi.org/10.1038/s41598-026-39410-w
