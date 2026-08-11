# Dynamic photon, residual Kerr, and thermal audit

Reviewer-triggered analysis using one archived-scale trajectory per condition.

- Loaded linewidth: `8 MHz`; external-coupling fraction: `0.5`.
- Detection efficiency: `0.50`; heterodyne factor: `1/2`.
- Integration aperture: `238.732 ps`; reference input: `0.224 nW/ring`.
- Target used only for comparison with the robustness sweep: `1e+04` effective photons.
- Kerr model: n2=`2.3e-19 m^2/W`, n=`1.977`, Veff=`1000 um^3`, K/2pi=`0.437 Hz/photon`.
- Thermo-optic coefficient: `2.45e-05 K^-1`; |dnu/dT|=`2.4 GHz/K`; DeltaT for 0.1 linewidth=`0.334 mK`.

The centered dynamic variance, rather than total carrier occupancy, is the operational signal. At the median retained PCA component, the inferred power and Kerr ratios are listed in the CSV. A physical platform is self-consistent only if its measured K, absorption, and thermal resistance satisfy both |K| nbar/kappa << 1 and |dnu/dT| Rth Pabs/kappa << 1.
