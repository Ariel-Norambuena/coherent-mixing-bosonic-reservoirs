# Numerical environment

The final revision was generated on:

- Microsoft Windows 11 Pro, build 26200.
- MATLAB R2025b, version 25.2.0.2998904.
- Parallel Computing Toolbox for the multi-process launchers.
- Statistics and Machine Learning Toolbox for PCA and statistical utilities.
- MiKTeX with REVTeX 4.2 for the manuscript.

The core reservoir integrator, feature construction, ridge solution, and
compact-table analyzers are MATLAB code. No Java runtime is required. The
paper-grade runs use fixed-step fourth-order Runge--Kutta integration and the
frozen JSON configurations under `Figure 3/configs/`.

The locked physical test and classical comparison were executed as separate
processes using the PowerShell launchers. Compact CSV, JSON, and PDF artifacts
are retained; temporary trajectory caches and large state arrays are not part
of the public archive.
