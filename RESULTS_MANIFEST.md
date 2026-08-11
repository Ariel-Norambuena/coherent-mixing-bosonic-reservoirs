# Results manifest

SHA-256 lineage frozen after the successful `run_all('verify')` execution and
final LaTeX compilation on 2026-08-11. Paths are relative to the project root.

## Configurations and entry point

| Artifact | Purpose | SHA-256 |
|---|---|---|
| `run_all.m` | compact reproduction and verification entry point | `8f466ccf5328088068f70e702aad43f6ef6c47f1ecf7ba378699e052248be08e` |
| `figure3/configs/narma_revision_protocol_20260807.json` | disjoint development, selection, and locked banks | `7bd8e7f4719457accf4197dbe73cb3095bb4f7be8935dbc1a0eed737c64e3175` |
| `figure3/configs/narma_locked_config_20260810.json` | frozen physical architecture and primary endpoint | `68eec107bb9bf7092b5954991020244521346c85a256d44deb4890394b25f41d` |
| `figure3/configs/narma_locked_comparison_config_20260810.json` | physical and classical budget curves | `aee5d4687004f806762a648cd8c90f583d70bf4c327d68856613ad051a6672ba` |
| `figure3/configs/additional_benchmark_protocol_20260811.json` | preregistered minimal and phase-task selection/test banks | `ac1f6eed686e4c48a863b2f13a0d9e35078f3f7cdb802a5f0504b828098ba869` |
| `figure3/configs/minimal_architecture_locked_config_20260811.json` | frozen one-copy deterministic architecture | `74a9ddf95b1e55f14ff6d6b5658083335c3160a4f9789597116d4b427c11e631` |
| `figure3/configs/phase_channel_locked_config_20260811.json` | frozen coherent phase-channel benchmark | `14a59690c6d3905d24daa7b69543ebc3a918246f7e413113336a604998c5627e` |

## Numerical tables

| Artifact | Producer | SHA-256 |
|---|---|---|
| `figure3/NARMASelectionStage1_Summary_20260807.csv` | `analyze_narma_selection_stage1_20260807.m` | `204bb9b8469ca2e128de9892d74aa41721f694e86b99fb1eca7f6e2c4e7b72b7` |
| `figure3/NARMASelectionStage2_Summary_20260810.csv` | `analyze_narma_selection_stage2_20260810.m` | `06dd8c97d3178dd196dcb3111e4acdcfb4c96eb28edbbfa0bd44653bc3ecdc1c` |
| `figure3/NARMALockedPairs_Raw_20260810.csv` | `analyze_narma_locked_pairs_20260810.m` | `a40316d880b0b4ce3240eaac6fa10effff86ce6c0c50ab2643907c0703317ac2` |
| `figure3/NARMALockedPairs_Statistics_20260810.csv` | `analyze_narma_locked_pairs_20260810.m` | `79af69b55ca65cfed2f9a360a68cc4d6bc6a679fd12f2bc17af7d24ae8b090f9` |
| `figure3/NARMABaselineLocked_Raw_20260810.csv` | `analyze_narma_baseline_locked_20260810.m` | `55b27cc1e9e426791818823d5c13695dcedfd53949d5e1e8dbdf206d69f0fe11` |
| `figure3/NARMABaselineLocked_Statistics_20260810.csv` | `analyze_narma_baseline_locked_20260810.m` | `7df72d20d9286becf94b1956ae1f506773a80ef15e65344d20fc10befc70a2e1` |
| `figure3/NARMAFairComparison_PhysicalRaw_20260810.csv` | `analyze_narma_fair_comparison_20260810.m` | `b686cc7238321b12924e50d992efe92bee39965ad7892d7ef9b55ad0e089fc13` |
| `figure3/NARMAFairComparison_PhysicalSummary_20260810.csv` | `analyze_narma_fair_comparison_20260810.m` | `37f653fee332f4288d8552902df5edd3d0c72c6e9be96b670ca4c4dd6c60a666` |
| `figure3/NARMAMechanismAblation_Raw_20260810.csv` | `analyze_narma_mechanism_ablation_20260810.m` | `6a11d93fec099486c0e87f2d0534e97ac65dcd9f7d83c25e736ab6347212507a` |
| `figure3/NARMAMechanismAblation_Summary_20260810.csv` | `analyze_narma_mechanism_ablation_20260810.m` | `13500b0639957e37d9c2f09febb7ba3a522d274b025b82962a0cbf0388e0e2c3` |
| `figure3/NARMAProcessingCapacity_Raw_20260810.csv` | `analyze_narma_processing_capacity_20260810.m` | `f02c0d7d5abfc8fa74b78771fcba7835097261031bd778a5a17cc8ffb603e57e` |
| `figure3/NARMAProcessingCapacity_Summary_20260810.csv` | `analyze_narma_processing_capacity_20260810.m` | `84e6ffff5930a83a47a1dddd4c1d991d553822899c5a23c97fe30271f335338d` |
| `figure3/NARMAMeasurementRobustness_Raw_20260810.csv` | `analyze_narma_measurement_robustness_20260810.m` | `870cb1efef94d9cfd7e21f288630ee73b603584c6554dc8722846fc44252ee2e` |
| `figure3/NARMAMeasurementRobustness_Summary_20260810.csv` | `analyze_narma_measurement_robustness_20260810.m` | `9a9758b7c591d7431a733980bafdb9f9365a311d0f41c7840f3c68c43671d4ed` |
| `figure3/NARMASolverConvergence_20260810.csv` | `analyze_narma_solver_convergence_20260810.m` | `a5c518bd39d3d781efee8fe62a39e743be614c4313a50a4ea05951817bd66823` |
| `figure3/NARMASeedDeterminism_20260810.csv` | `analyze_narma_determinism_20260810.m` | `eb1366a2246e96af4166d954802b6fa3ff28f6ade148a0e20869dc778a1ef490` |
| `figure3/K0ContractionSummary_20260810.csv` | `verify_k0_contraction_20260810.m` | `26cf0458f0039eb8c0c73c51d70a77b3da7cad77e050efe2eaad3cc942c6e3de` |
| `figure3/HardwareMapping_HybridSiNTFLN_20260810.csv` | `generate_hardware_mapping_20260810.m` | `31bdf497b04f005c51783bbb5409c20c5f5023479ab953b6fe66f46f93eb2b70` |
| `figure3/HardwareResourceBudget_20260810.csv` | `generate_hardware_mapping_20260810.m` | `1b1c107701ff91660c3e86c8ecd39e4f69d44705975f1215021bd6c04c345443` |
| `figure3/MinimalArchitectureStageA_Summary_20260811.csv` | `analyze_minimal_architecture_stage_a_20260811.m` | `fadf19189bf8af649594067b20e1b9ba2b6591a99788381c15a384a329f0e444` |
| `figure3/MinimalArchitectureCopySelection_Raw_20260811.csv` | `analyze_minimal_architecture_copy_selection_20260811.m` | `55f3ac06533bac118b99be3f43c2245da25be38b3c55bddd36a41e4c92ef3ea0` |
| `figure3/MinimalArchitectureFreshNARMA_Raw_20260811.csv` | `analyze_minimal_architecture_locked_20260811.m` | `65f3f6969672a3aac58052e55c6be70d0ff8de52da2c6f975c4bb1c33fc4dc23` |
| `figure3/PhaseChannelSelectionSummary_20260811.csv` | `analyze_phase_channel_selection_20260811.m` | `dc6bafc018c1ecec7b5cf8c2e04c410c09ad9b9f42bbfb1f03bc712a2df22456` |
| `figure3/PhaseChannelLocked_Raw_20260811.csv` | `analyze_phase_channel_locked_20260811.m` | `1d0848de37ffa20e74143a8c35f6a89650d97413e9bce30c54c98456cfe985d2` |
| `figure3/PhaseChannelLocked_Summary_20260811.csv` | `analyze_phase_channel_locked_20260811.m` | `7e68ccb8f77c8e969699a20951f015207f8bc61b6843dda023244ab45bd81458` |
| `figure3/PhotonPrecisionMapping_20260811.csv` | `analyze_photon_precision_mapping_20260811.m` | `d9e445b036e6ead4169668c64082d4016512a7db70ef30067681686c38c50067` |
| `figure3/TaskSignalTracesExtended_20260811.csv` | `generate_signal_complexity_extended_20260811.m` | `174190cf9b94ae550a273b70478a220b1f2d56d62f49e491c891eef9b664744e` |
| `figure3/TaskSignalSpectraExtended_20260811.csv` | `generate_signal_complexity_extended_20260811.m` | `437499c38d2124cd57b65cdcd7658a57650ea8bc369712d51fe3ceeb391f3ab4` |

## Figures

| Output | Generating analysis | Principal inputs | SHA-256 |
|---|---|---|---|
| `figure3/Figure1_ArchitectureMechanism_20260810.pdf` | `generate_figure1_architecture_mechanism_20260810.m` | locked config, contraction verification | `49e4a2af67a8173da2906286c2dd48f82b62703bed8054f1fb32cb688b16c84e` |
| `figure3/Figure2_SelectionCapacity_20260810.pdf` | `generate_figure2_selection_capacity_20260810.m` | stage-1, stage-2, capacity tables | `a5faf671efe1bfdd245c39ad9dc5093f47b97423a413ff73c9ae81647878e6a0` |
| `figure3/NARMALockedPairs_20260810.pdf` | `plot_narma_locked_pairs_from_tables_20260810.m` | 30-pair locked CSV files | `c154589bea692bf460fbaef5c8a565d7fd9430b80750615b1817d7644f8d01a0` |
| `figure3/NARMAMechanismAblation_20260810.pdf` | `plot_narma_mechanism_from_tables_20260810.m` | equal-budget ablation CSV files | `e3f57bcb42dde0ddf7f485492154c63490f384295a2bd2ca427a06fff0372082` |
| `figure3/NARMAFairComparison_20260810.pdf` | `plot_narma_fair_comparison_from_tables_20260810.m` | physical and classical budget tables | `c23a95a86d477dc2d2c14e346ec298098a08751ccaed4f0b40389e8eb97bb432` |
| `figure3/NARMAMeasurementRobustness_20260810.pdf` | `plot_narma_robustness_from_tables_20260810.m` | 2,900-row perturbation table | `583a1617fa53b0b087b33916b8831d1d4c52c89d34b6614a1394df588b3657f3` |
| `figure3/Figure1_PhysicalMechanism_20260811.pdf` | `generate_figure1_architecture_mechanism_20260811.m` | locked config and exact contraction | `8511bbf0945dd229f0547746eeb1864b19e826354d1eb251f0524df3a70f5d61` |
| `figure3/Figure2_KerrFreeSelectionMemory_20260811.pdf` | `generate_figure2_selection_capacity_20260811.m` | selection and lag-capacity tables | `9417953274072dcb81d517175c9c9adafc66f2841e5004ec881448006e7f69dc` |
| `figure3/Figure3_TaskSignalComplexityExtended_20260811.pdf` | `generate_signal_complexity_extended_20260811.m` | fixed NARMA10 and phase-channel seeds | `efb4c69f21d721ca7471fdbe50139631527d7524d3661d67c6506445f6889afb` |
| `figure3/Figure6_MinimalArchitectureTasks_20260811.pdf` | `generate_figure_minimal_phase_20260811.m` | seed-level minimal and phase tables | `643d30ab45d5e1abcb43b36efe1448d5eb6babe4eeea96a3273efe0727197beb` |
| `figure3/FigS_PhotonPrecision_20260811.pdf` | `plot_photon_precision_from_table_20260811.m` | photon-mapping table | `a410f48508b08dfea85b40ab5ee0e96eab2699dc426e6eb532b36fdb913feb64` |

Large temporary complex-state caches are intentionally excluded. The complete
paper values are retained in the compact seed-level tables listed above.

