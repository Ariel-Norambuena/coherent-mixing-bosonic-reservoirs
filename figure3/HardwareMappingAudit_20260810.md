# Hybrid SiN/TFLN hardware mapping audit

This is an engineering translation of normalized parameters, not a fabricated-device claim. It assumes a loaded linewidth of 8 MHz and critical external coupling at 1550 nm.

- Symbol time: `1.641 ns`; waveform update: `29.84 ps`.
- Average/peak sample rates per detector: `3.656/4.189 GS/s`.
- Coupling: `43.33 MHz`; detuning-modulation scale: `60 MHz`.
- Ideal on-chip drive estimate: `0.2237 nW/ring`, `8.052 nW` total.
- The power estimate excludes coupling loss, modulator insertion loss, local-oscillator power, I/Q hybrids, RF drivers, ADCs, thermal stabilization, and laser wall-plug efficiency; it must not be quoted as total system energy.
- A monolithic passive SiN network alone does not implement the required fast local detuning terms. The mapping therefore requires hybrid electro-optic control or an equivalent measured transfer matrix.
- The 55 mask values are waveform updates inside each symbol; only six of those integration times are digitized as virtual samples. The modulator therefore requires about 33.5 GHz update bandwidth while each electrical I/Q output requires at most 4.19 GS/s.
- The locked coupling gain is observed with simultaneous quadrature features. A direct implementation therefore needs 36 optical I/Q hybrids, 144 photodiodes, and 72 differential ADC channels. Intensity-only readout uses 36 detectors but does not inherit the locked coupling gain.
- The trained readout has 338 weights excluding bias. Explicit PCA costs 11232/3744 MACs per symbol for the original/minimal architectures; algebraic fusion with the linear readout reduces these counts to 5616/1872. These counts exclude standardization, buffering, acquisition, and energy.
