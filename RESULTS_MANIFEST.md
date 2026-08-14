# Results manifest

SHA-256 lineage frozen after the successful `run_all('verify')` execution and
final LaTeX compilation on 2026-08-13. On 2026-08-14, 36 CSV hashes were
normalized from working-tree CRLF bytes to the exact LF bytes stored in the
versioned release; numerical contents were unchanged. Paths are relative to
the project root.

## Configurations and entry point

| Artifact | Purpose | SHA-256 |
|---|---|---|
| `run_all.m` | compact reproduction and verification entry point | `4056e1ca531318f73ce7038640ee30e9007ba325fca858c86d202a6c93fc6b51` |
| `figure3/configs/narma_revision_protocol_20260807.json` | disjoint development, selection, and locked banks | `7bd8e7f4719457accf4197dbe73cb3095bb4f7be8935dbc1a0eed737c64e3175` |
| `figure3/configs/narma_locked_config_20260810.json` | frozen physical architecture and primary endpoint | `68eec107bb9bf7092b5954991020244521346c85a256d44deb4890394b25f41d` |
| `figure3/configs/narma_locked_comparison_config_20260810.json` | physical and classical budget curves | `aee5d4687004f806762a648cd8c90f583d70bf4c327d68856613ad051a6672ba` |
| `figure3/configs/additional_benchmark_protocol_20260811.json` | prospectively frozen minimal and phase-task selection/test banks | `ac1f6eed686e4c48a863b2f13a0d9e35078f3f7cdb802a5f0504b828098ba869` |
| `figure3/configs/minimal_architecture_locked_config_20260811.json` | frozen one-copy deterministic architecture | `74a9ddf95b1e55f14ff6d6b5658083335c3160a4f9789597116d4b427c11e631` |
| `figure3/configs/phase_channel_locked_config_20260811.json` | frozen coherent phase-channel benchmark | `14a59690c6d3905d24daa7b69543ebc3a918246f7e413113336a604998c5627e` |

## Numerical tables

| Artifact | Producer | SHA-256 |
|---|---|---|
| `figure3/NARMASelectionStage1_Summary_20260807.csv` | `analyze_narma_selection_stage1_20260807.m` | `e8af1b66b6f353c14ab50e02a47f6186dc2e06b197bf867aa294dda83e4f0e00` |
| `figure3/NARMASelectionStage2_Summary_20260810.csv` | `analyze_narma_selection_stage2_20260810.m` | `81c910d8d4396e4b1a609c8a867bdd083d9386b1d4054c98b7862f9a82adbd38` |
| `figure3/NARMALockedPairs_Raw_20260810.csv` | `analyze_narma_locked_pairs_20260810.m` | `92f59b7f818c893fe97b8a56c6a76ef4262d5afacd4a11932e776b67997bf65e` |
| `figure3/NARMALockedPairs_Statistics_20260810.csv` | `analyze_narma_locked_pairs_20260810.m` | `8d12a0c2b790fcb0fb1d8d38641be3b603a19b9eca37b018ea1e8897caa66315` |
| `figure3/NARMABaselineLocked_Raw_20260810.csv` | `analyze_narma_baseline_locked_20260810.m` | `a69802cd17ac68f87218402d1ae8d13b88eed49c56ddfabb0753f676578f6111` |
| `figure3/NARMABaselineLocked_Statistics_20260810.csv` | `analyze_narma_baseline_locked_20260810.m` | `03981cd06f69d5b92dbd03934683548745966c62d32e1427890a3f36d3b6aa99` |
| `figure3/NARMAFairComparison_PhysicalRaw_20260810.csv` | `analyze_narma_fair_comparison_20260810.m` | `d9dd7274f9859a57465d11c09bac9c4dc0e32fd19bcad900401606d3536b7dfb` |
| `figure3/NARMAFairComparison_PhysicalSummary_20260810.csv` | `analyze_narma_fair_comparison_20260810.m` | `1ec0a2ffd905a440b0b45cced8c9f5d4b57a1e6c4be30841fc824bad307bb5ac` |
| `figure3/NARMAMechanismAblation_Raw_20260810.csv` | `analyze_narma_mechanism_ablation_20260810.m` | `8270780ba8115b05a4f156d5490bf15862fc711fb410c0209e8aa543ba5bd060` |
| `figure3/NARMAMechanismAblation_Summary_20260810.csv` | `analyze_narma_mechanism_ablation_20260810.m` | `fa654c0f4549f56511432e42e2bb7c00092d90208797aa087bae3e7c8cef4df9` |
| `figure3/NARMAProcessingCapacity_Raw_20260810.csv` | `analyze_narma_processing_capacity_20260810.m` | `fde8a31f95db5d336dcc98a958e15f38db3ffc14d47961d6aa9d3b82165ab457` |
| `figure3/NARMAProcessingCapacity_Summary_20260810.csv` | `analyze_narma_processing_capacity_20260810.m` | `4bac8e14bb74942959f177aca6af112e98722fd0c06596b082cdff7dd42094a4` |
| `figure3/NARMAMeasurementRobustness_Raw_20260810.csv` | `analyze_narma_measurement_robustness_20260810.m` | `e196996b952e61248d36c962df11295cb6d43b9d0d2ff7dd94236d084a1d2c85` |
| `figure3/NARMAMeasurementRobustness_Summary_20260810.csv` | `analyze_narma_measurement_robustness_20260810.m` | `7c4db0f92ce2eadf4dc02cb78122c637d54e0d2296541fc62532430bea90de3e` |
| `figure3/NARMASolverConvergence_20260810.csv` | `analyze_narma_solver_convergence_20260810.m` | `be6e7f69cdd15456719e45192952cb2848edb287a6845ae22eceaf635c26c24b` |
| `figure3/NARMASeedDeterminism_20260810.csv` | `analyze_narma_determinism_20260810.m` | `8018480e1b8b5d5c1cafaaa62e5bf57123dade7c2a5c70bce0689b741f60a77c` |
| `figure3/K0ContractionSummary_20260810.csv` | `verify_k0_contraction_20260810.m` | `a03f5bcc4659eb6d1a03b965e4d3009225364603da05167bf775e4ffd929d2d0` |
| `figure3/HardwareMapping_HybridSiNTFLN_20260810.csv` | `generate_hardware_mapping_20260810.m` | `827dcd5eb6e0ab6799781258cc304910885b66977c2d0ba0c6271d993b3ce864` |
| `figure3/HardwareResourceBudget_20260810.csv` | `generate_hardware_mapping_20260810.m` | `21b1bc9d95110b27ed211ecd35ff166c7b0ad83b6ee1af97d74367098de8c0f9` |
| `figure3/MinimalArchitectureStageA_Summary_20260811.csv` | `analyze_minimal_architecture_stage_a_20260811.m` | `745c4e645652763f5e141f56547e1fa0c1711fb4dc2ba91ad2faf05965633e8e` |
| `figure3/MinimalArchitectureCopySelection_Raw_20260811.csv` | `analyze_minimal_architecture_copy_selection_20260811.m` | `26afaa5241f98f2846f1cdbc5739f142dcd2b396a1a5f4fc632617ad77356b72` |
| `figure3/MinimalArchitectureFreshNARMA_Raw_20260811.csv` | `analyze_minimal_architecture_locked_20260811.m` | `52f57ced7c49a3eef5728b26e35b8f41d0be8d39367c1a6751b9fa29f570905b` |
| `figure3/PhaseChannelSelectionSummary_20260811.csv` | `analyze_phase_channel_selection_20260811.m` | `aedc9bc8f066a979b954c9b2a46c8c40a3b3e783661470e9dce08fc35bbaf7ec` |
| `figure3/PhaseChannelLocked_Raw_20260811.csv` | `analyze_phase_channel_locked_20260811.m` | `ad5d9a37f50744116d7a2f4a0074a70fff11f62700324c51d116a624b8089cd1` |
| `figure3/PhaseChannelLocked_Summary_20260811.csv` | `analyze_phase_channel_locked_20260811.m` | `b62b511735b661fca76056165d1b8c8ea4736ef9af25d098dd640cc42615893e` |
| `figure3/PhotonPrecisionMapping_20260811.csv` | `analyze_photon_precision_mapping_20260811.m` | `8885651cecd61b93dfbc7cfb20fcb1dba89922f9428b9da11db9c36ac53ea64e` |
| `figure3/TaskSignalTracesExtended_20260811.csv` | `generate_signal_complexity_extended_20260811.m` | `a35e9365f8a9ed19cf7b6d5dcfb070b9c4be3378ac1c53bb8eabf7543b71ec29` |
| `figure3/TaskSignalSpectraExtended_20260811.csv` | `generate_signal_complexity_extended_20260811.m` | `6c76ec257e5ee7b6d17b745f169bb7aa0d847b39433fdb0f71ff5fd4a94ed61f` |
| `figure3/DynamicPhotonKerrThermalAudit_20260812.csv` | `analyze_dynamic_photon_kerr_thermal_20260812.m` | `cbb2b1e607c1c5cf874cbb6dea617fda0d9f0fdfe32b5612ec6f82b554a6bf8e` |
| `figure3/DynamicPhotonKerrMultiOffset_Raw_20260813.csv` | `analyze_dynamic_photon_kerr_multioffset_20260813.m` | `3182d602e957e02afdfee6eaeae0e9ca1b95c9b3c7705a7d2051c35a1586d663` |
| `figure3/DynamicPhotonKerrMultiOffset_Summary_20260813.csv` | `analyze_dynamic_photon_kerr_multioffset_20260813.m` | `d48f5510a87da06fa2945038d818017701f44cc205e9f1448c3925db8ff3adce` |
| `figure3/EqualFrequencyControl_Raw_20260812.csv` | `analyze_equal_frequency_control_20260812.m` | `0439b6f6fc1f9481f2f9ada3cfdceeb9dd98ad7c1e5100613fbbf64d3592a7f5` |
| `figure3/EqualFrequencyControl_Summary_20260812.csv` | `analyze_equal_frequency_control_20260812.m` | `f8213b0d1002a34f88ddebca53d5ecefe37e8feb6a49e906a5302ed59654980b` |
| `figure3/PhaseChannelFullIQ_Selection_20260812.csv` | `analyze_phase_channel_full_iq_20260812.m` | `a3ad86590c81f263d9083a6681f3a1a9497b299d8743c7eaa2cb356bf9870c7d` |
| `figure3/PhaseChannelFullIQ_Raw_20260812.csv` | `analyze_phase_channel_full_iq_20260812.m` | `eadfae1dba2798b87e5fc7bc2c017792b0dccbca9c04a0c0a10900a26d7eb803` |
| `figure3/PhaseChannelFullIQ_Summary_20260812.csv` | `analyze_phase_channel_full_iq_20260812.m` | `bc954aa5b57fefb0e6f17ba0e25b841516204c8d885048dbfb6e038a9efb9dba` |

## Figures

| Output | Generating analysis | Principal inputs | SHA-256 |
|---|---|---|---|
| `figure3/Figure1_ArchitectureMechanism_20260810.pdf` | `generate_figure1_architecture_mechanism_20260810.m` | locked config, contraction verification | `49e4a2af67a8173da2906286c2dd48f82b62703bed8054f1fb32cb688b16c84e` |
| `figure3/Figure2_SelectionCapacity_20260810.pdf` | `generate_figure2_selection_capacity_20260810.m` | stage-1, stage-2, capacity tables | `a5faf671efe1bfdd245c39ad9dc5093f47b97423a413ff73c9ae81647878e6a0` |
| `figure3/NARMALockedPairs_20260810.pdf` | `plot_narma_locked_pairs_from_tables_20260810.m` | 30-pair locked CSV files | `66a81f1ceb3a6bf99b7f0b63bf3930732ef8f33452949ca25115948c852a2ab6` |
| `figure3/NARMAMechanismAblation_20260810.pdf` | `plot_narma_mechanism_from_tables_20260810.m` | equal-budget ablation CSV files | `0197f59f698ebb01976676e59e238e4117452fa4d531aace03447aad484bf307` |
| `figure3/NARMAFairComparison_20260810.pdf` | `plot_narma_fair_comparison_from_tables_20260810.m` | physical and classical budget tables | `fd99c709029c19022043c2fe55d040a08f50db48109794f224b187e017cb9f98` |
| `figure3/NARMAMeasurementRobustness_20260810.pdf` | `plot_narma_robustness_from_tables_20260810.m` | 2,900-row perturbation table | `9e1b80168fc8a56a6c1f9d22ff1c2068656354718a92dce617d685c544d289ff` |
| `figure3/Figure1_PhysicalMechanism_20260811.pdf` | `generate_figure1_architecture_mechanism_20260811.m` | locked config and exact contraction | `e934a1d895915e725baaa5acc5846a92922447648512911255ac5fb6475fb19b` |
| `figure3/Figure2_KerrFreeSelectionMemory_20260811.pdf` | `generate_figure2_selection_capacity_20260811.m` | selection and lag-capacity tables | `cad1760132343802ffa6860d07736b9265f8aee4bef1dfd54c2d55c836e7c8ce` |
| `figure3/Figure3_TaskSignalComplexityExtended_20260811.pdf` | `generate_signal_complexity_extended_20260811.m` | fixed NARMA10 and phase-channel seeds | `b48ab263e81c3f5016c7ddf4f4793dbfde10a6f93704241e09ce0c5425324db8` |
| `figure3/Figure6_MinimalArchitectureTasks_20260811.pdf` | `generate_figure_minimal_phase_20260811.m` | minimal, equal-frequency, phase, and full-I/Q tables | `cc05043c55ef8ee68b2c9ee87160fc3cadf2bd918640ceeaa6195eab912b59a8` |
| `figure3/FigS_PhotonPrecision_20260811.pdf` | `plot_dynamic_photon_kerr_thermal_20260812.m` | ten-offset centered-signal photon/Kerr table | `d324c65fbda6d34a90611768e8e2aec00598983cd86774660cb32099b45015d7` |
| `figure3/PhaseChannelFullIQ_20260812.pdf` | `analyze_phase_channel_full_iq_20260812.m` | phase-task selection and locked offsets | `b8627a1bd0557b94b293bad56f51def201b2ec9f0b65bcaa945184f8b5ccc326` |

Large temporary complex-state caches are intentionally excluded. The complete
paper values are retained in the compact seed-level tables listed above.
