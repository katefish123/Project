# 源码目录与逐文件索引

主工程共 135 个设计文件、1 个约束，全部与原 V4S 物理实现回执逐文件 SHA256 相符；仅调整存放位置。

| 分类 | 文件数 | 内容 |
|---|---:|---|
| `constraints/board_ddr.fdc` | 1 | 板级引脚与时序约束 |
| `ip/clock` | 2 | Pango PLL 原文件 |
| `ip/ddr3` | 74 | Pango DDR3 IP 原文件 |
| `rtl/algorithm` | 8 | B 原始数学/插值/除法模块 |
| `rtl/cache` | 2 | 四邻域 tile/cache |
| `rtl/capture` | 7 | 相机帧采集、连续源银行管理 |
| `rtl/cdc` | 5 | 复位同步、异步 FIFO、跨时钟桥 |
| `rtl/control` | 4 | 处理调度及兼容模块 |
| `rtl/display` | 8 | 1080p 时序、结果显示、预览与状态 |
| `rtl/geometry` | 5 | 四黑标检测、角点元数据与几何入口 |
| `rtl/hdmi` | 5 | HDMI 收发器 I²C 初始化与 VS 恢复 |
| `rtl/memory` | 9 | DDR 命令、仲裁、写回及自检 |
| `rtl/top` | 6 | 板级顶层、系统控制边界 |

## 优先阅读的活动路径

1. `rtl/top/video_correct_ddr_top.v`：芯片引脚、时钟/复位、HDMI、DDR IP 与核心连接。
2. `rtl/top/video_correct_ddr_continuous_core.v`：采集/处理/显示协调，帧号及拒绝计数。
3. `rtl/capture/continuous_source_path.v`：双源银行、采集 packet 与几何元数据汇合。
4. `rtl/geometry/marker_detector.v`：固定 ROI 内黑像素质心。
5. `rtl/control/c_stream_burst_correction_path.v` 与 `rtl/control/frame_processor_stream.v`：像素处理调度。
6. `rtl/algorithm/homography_solver.v`、`perspective_coord.v`、`bilinear_interp.v`：B 数学算法。
7. `rtl/memory/ddr_word_engine_result_burst.v` 与 `rtl/display/ddr_result_display_block64.v`：原生 DDR 接口及完整结果显示。

原编译清单也保留早期兼容模块，它们属于固定源码闭包；主活动路径从上述顶层向下查看，不能把所有文件都视为同时活动或本轮新增。

## 全部构建输入

| 包内文件 | 模块/类型 | 原工程相对路径 |
|---|---|---|
| [constraints/board_ddr.fdc](../constraints/board_ddr.fdc) | 约束 | `constr/board_ddr.fdc` |
| [ip/clock/config_pll_27m_10m/config_pll_27m_10m.v](../ip/clock/config_pll_27m_10m/config_pll_27m_10m.v) | config_pll_27m_10m | `vendor/c_current/01_design_code/ip/config_pll_27m_10m/config_pll_27m_10m.v` |
| [ip/clock/video_pll_27m_148m5/video_pll_27m_148m5.v](../ip/clock/video_pll_27m_148m5/video_pll_27m_148m5.v) | video_pll_27m_148m5 | `vendor/c_current/01_design_code/ip/video_pll_27m_148m5/video_pll_27m_148m5.v` |
| [ip/ddr3/ddr3_ip.v](../ip/ddr3/ddr3_ip.v) | ddr3_ip | `rtl/memory/ddr3_ip/ddr3_ip.v` |
| [ip/ddr3/ddr3_ip_ddrphy_top.v](../ip/ddr3/ddr3_ip_ddrphy_top.v) | ddr3_ip_ddrphy_top | `rtl/memory/ddr3_ip/ddr3_ip_ddrphy_top.v` |
| [ip/ddr3/rtl/ddrphy/ddr3_ip_slice_top_v1_10.v](../ip/ddr3/rtl/ddrphy/ddr3_ip_slice_top_v1_10.v) | ddr3_ip_slice_top_v1_10 | `rtl/memory/ddr3_ip/rtl/ddrphy/ddr3_ip_slice_top_v1_10.v` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_calib_mux_v1_0.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_calib_mux_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_calib_mux_v1_0.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_calib_top_v1_10.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_calib_top_v1_10.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_calib_top_v1_10.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_control_path_adj_v1_10.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_control_path_adj_v1_10.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_control_path_adj_v1_10.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_cpd_ctrl_v1_3.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_cpd_ctrl_v1_3.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_cpd_ctrl_v1_3.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_cpd_lock_v1_0.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_cpd_lock_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_cpd_lock_v1_0.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_data_slice_dqs_gate_cal_v1_10.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_data_slice_dqs_gate_cal_v1_10.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_data_slice_dqs_gate_cal_v1_10.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_data_slice_v1_10.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_data_slice_v1_10.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_data_slice_v1_10.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_data_slice_wrcal_v1_10.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_data_slice_wrcal_v1_10.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_data_slice_wrcal_v1_10.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_data_slice_wrlvl_v1_10.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_data_slice_wrlvl_v1_10.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_data_slice_wrlvl_v1_10.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_dfi_v1_3.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_dfi_v1_3.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_dfi_v1_3.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_dll_update_ctrl_v1_3.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_dll_update_ctrl_v1_3.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_dll_update_ctrl_v1_3.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_dqs_gate_coarse_cal_v1_0.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_dqs_gate_coarse_cal_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_dqs_gate_coarse_cal_v1_0.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_dqs_rddata_align_v1_10.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_dqs_rddata_align_v1_10.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_dqs_rddata_align_v1_10.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_dqsi_rdel_cal_v1_3.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_dqsi_rdel_cal_v1_3.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_dqsi_rdel_cal_v1_3.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_drift_ctrl_v1_0.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_drift_ctrl_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_drift_ctrl_v1_0.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_eyecal_v1_5.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_eyecal_v1_5.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_eyecal_v1_5.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_gate_update_ctrl_v1_3.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_gate_update_ctrl_v1_3.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_gate_update_ctrl_v1_3.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_gatecal_v1_10.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_gatecal_v1_10.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_gatecal_v1_10.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_gpll_phase_v1_0.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_gpll_phase_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_gpll_phase_v1_0.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_info_v1_0.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_info_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_info_v1_0.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_init_v1_0.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_init_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_init_v1_0.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_main_ctrl_v1_10.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_main_ctrl_v1_10.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_main_ctrl_v1_10.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_rdcal_v1_10.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_rdcal_v1_10.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_rdcal_v1_10.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_reset_ctrl_v1_3.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_reset_ctrl_v1_3.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_reset_ctrl_v1_3.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_rst_clk_phase_adj_v1_0.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_rst_clk_phase_adj_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_rst_clk_phase_adj_v1_0.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_rst_debounce_v1_0.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_rst_debounce_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_rst_debounce_v1_0.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_slice_rddata_align_v1_0.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_slice_rddata_align_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_slice_rddata_align_v1_0.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_training_ctrl_v1_0.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_training_ctrl_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_training_ctrl_v1_0.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_upcal_v1_0.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_upcal_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_upcal_v1_0.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_wdata_path_adj_v1_10.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_wdata_path_adj_v1_10.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_wdata_path_adj_v1_10.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_wrcal_v1_7.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_wrcal_v1_7.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_wrcal_v1_7.vp` |
| [ip/ddr3/rtl/ddrphy/ips2l_ddrphy_wrlvl_v1_0.vp](../ip/ddr3/rtl/ddrphy/ips2l_ddrphy_wrlvl_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ddrphy/ips2l_ddrphy_wrlvl_v1_0.vp` |
| [ip/ddr3/rtl/ips2l_rst_sync_v1_3.vp](../ip/ddr3/rtl/ips2l_rst_sync_v1_3.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/ips2l_rst_sync_v1_3.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/distributed_fifo/ips2l_distributed_fifo_v1_0.vp](../ip/ddr3/rtl/mcdq_ctrl/distributed_fifo/ips2l_distributed_fifo_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/distributed_fifo/ips2l_distributed_fifo_v1_0.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/distributed_fifo/rtl/ips2l_distributed_fifo_ctr_v1_0.vp](../ip/ddr3/rtl/mcdq_ctrl/distributed_fifo/rtl/ips2l_distributed_fifo_ctr_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/distributed_fifo/rtl/ips2l_distributed_fifo_ctr_v1_0.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/distributed_fifo/rtl/ips2l_distributed_fifo_v1_0_distributed_fifo_v1_0.vp](../ip/ddr3/rtl/mcdq_ctrl/distributed_fifo/rtl/ips2l_distributed_fifo_v1_0_distributed_fifo_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/distributed_fifo/rtl/ips2l_distributed_fifo_v1_0_distributed_fifo_v1_0.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/distributed_fifo/rtl/ips2l_distributed_sdpram_v1_0_distributed_fifo_v1_0.vp](../ip/ddr3/rtl/mcdq_ctrl/distributed_fifo/rtl/ips2l_distributed_sdpram_v1_0_distributed_fifo_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/distributed_fifo/rtl/ips2l_distributed_sdpram_v1_0_distributed_fifo_v1_0.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_apb_cross_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_apb_cross_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_apb_cross_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_calib_delay_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_calib_delay_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_calib_delay_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_cfg_apb_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_cfg_apb_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_cfg_apb_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dcd_bm_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dcd_bm_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_dcd_bm_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dcd_rowaddr_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dcd_rowaddr_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_dcd_rowaddr_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dcd_sm_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dcd_sm_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_dcd_sm_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dcd_top_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dcd_top_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_dcd_top_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dcp_back_ctrl_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dcp_back_ctrl_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_dcp_back_ctrl_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dcp_buf_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dcp_buf_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_dcp_buf_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dcp_out_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dcp_out_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_dcp_out_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dcp_top_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dcp_top_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_dcp_top_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dfi_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_dfi_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_dfi_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_lp_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_lp_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_lp_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_mrs_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_mrs_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_mrs_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_prefetch_fifo_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_prefetch_fifo_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_prefetch_fifo_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_rdatapath_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_rdatapath_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_rdatapath_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_reg_fifo2_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_reg_fifo2_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_reg_fifo2_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_ui_axi_v1_2a.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_ui_axi_v1_2a.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_ui_axi_v1_2a.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_wdatapath_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_wdatapath_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_wdatapath_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_wdp_align_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_wdp_align_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_wdp_align_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_wdp_dcp_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_wdp_dcp_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_wdp_dcp_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_wrapper_v1_2b.vp](../ip/ddr3/rtl/mcdq_ctrl/ips2l_mcdq_wrapper_v1_2b.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/ips2l_mcdq_wrapper_v1_2b.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_com_timing_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_com_timing_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_com_timing_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_tfaw_timing_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_tfaw_timing_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_tfaw_timing_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_tfaw_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_tfaw_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_tfaw_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_act2wr_pass_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_act2wr_pass_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_act2wr_pass_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_act_pass_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_act_pass_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_act_pass_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_pre_pass_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_pre_pass_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_pre_pass_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_rd_pass_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_rd_pass_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_rd_pass_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_ref_pass_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_ref_pass_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_ref_pass_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_wr_pass_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_wr_pass_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_timing_wr_pass_v1_2.vp` |
| [ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_trc_timing_v1_2.vp](../ip/ddr3/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_trc_timing_v1_2.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/mcdq_ctrl/syn_mod/ips2l_mcdq_trc_timing_v1_2.vp` |
| [ip/ddr3/rtl/pll/ips2l_ddrphy_gpll_v1_3.vp](../ip/ddr3/rtl/pll/ips2l_ddrphy_gpll_v1_3.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/pll/ips2l_ddrphy_gpll_v1_3.vp` |
| [ip/ddr3/rtl/pll/ips2l_ddrphy_ppll_v1_0.vp](../ip/ddr3/rtl/pll/ips2l_ddrphy_ppll_v1_0.vp) | 厂商保护源码 | `rtl/memory/ddr3_ip/rtl/pll/ips2l_ddrphy_ppll_v1_0.vp` |
| [rtl/algorithm/b_rectifier.v](../rtl/algorithm/b_rectifier.v) | b_rectifier | `vendor/b/rtl/b_rectifier.v` |
| [rtl/algorithm/bilinear_interp.v](../rtl/algorithm/bilinear_interp.v) | bilinear_interp | `vendor/b/rtl/bilinear_interp.v` |
| [rtl/algorithm/homography_solver.v](../rtl/algorithm/homography_solver.v) | homography_solver | `vendor/b/rtl/homography_solver.v` |
| [rtl/algorithm/perspective_coord.v](../rtl/algorithm/perspective_coord.v) | perspective_coord | `vendor/b/rtl/perspective_coord.v` |
| [rtl/algorithm/perspective_core.v](../rtl/algorithm/perspective_core.v) | perspective_core | `vendor/b/rtl/perspective_core.v` |
| [rtl/algorithm/scaled_div_pipe.v](../rtl/algorithm/scaled_div_pipe.v) | scaled_div_pipe | `vendor/b/rtl/scaled_div_pipe.v` |
| [rtl/algorithm/signed_div_seq.v](../rtl/algorithm/signed_div_seq.v) | signed_div_seq | `vendor/b/rtl/signed_div_seq.v` |
| [rtl/algorithm/unsigned_div_seq.v](../rtl/algorithm/unsigned_div_seq.v) | unsigned_div_seq | `vendor/b/rtl/unsigned_div_seq.v` |
| [rtl/cache/ddr_pixel_cache.v](../rtl/cache/ddr_pixel_cache.v) | ddr_pixel_cache | `rtl/memory/ddr_pixel_cache.v` |
| [rtl/cache/ddr_quad_tile_cache.v](../rtl/cache/ddr_quad_tile_cache.v) | ddr_quad_tile_cache | `rtl/stream/ddr_quad_tile_cache.v` |
| [rtl/capture/continuous_capture_manager.v](../rtl/capture/continuous_capture_manager.v) | continuous_capture_manager | `rtl/stream/continuous_capture_manager.v` |
| [rtl/capture/continuous_capture_rx.v](../rtl/capture/continuous_capture_rx.v) | continuous_capture_rx | `rtl/stream/continuous_capture_rx.v` |
| [rtl/capture/continuous_capture_writer.v](../rtl/capture/continuous_capture_writer.v) | continuous_capture_writer | `rtl/stream/continuous_capture_writer.v` |
| [rtl/capture/continuous_source_path.v](../rtl/capture/continuous_source_path.v) | continuous_source_path | `rtl/stream/continuous_source_path.v` |
| [rtl/capture/ddr_capture_writer.v](../rtl/capture/ddr_capture_writer.v) | ddr_capture_writer, ddr_capture_writer_banked | `rtl/memory/ddr_capture_writer.v` |
| [rtl/capture/ddr_snapshot_capture.v](../rtl/capture/ddr_snapshot_capture.v) | ddr_snapshot_capture | `rtl/video/ddr_snapshot_capture.v` |
| [rtl/capture/snapshot_capture.v](../rtl/capture/snapshot_capture.v) | snapshot_capture | `rtl/video/snapshot_capture.v` |
| [rtl/cdc/async_packet_fifo.v](../rtl/cdc/async_packet_fifo.v) | async_packet_fifo | `rtl/memory/async_packet_fifo.v` |
| [rtl/cdc/async_packet_stream.v](../rtl/cdc/async_packet_stream.v) | async_packet_stream | `rtl/stream/async_packet_stream.v` |
| [rtl/cdc/ddr_command_bridge.v](../rtl/cdc/ddr_command_bridge.v) | ddr_command_bridge | `rtl/memory/ddr_command_bridge.v` |
| [rtl/cdc/quad_packet_bridge.v](../rtl/cdc/quad_packet_bridge.v) | quad_packet_bridge | `rtl/stream/quad_packet_bridge.v` |
| [rtl/cdc/reset_sync.v](../rtl/cdc/reset_sync.v) | reset_sync | `rtl/common/reset_sync.v` |
| [rtl/control/c_stream_burst_correction_path.v](../rtl/control/c_stream_burst_correction_path.v) | c_stream_burst_correction_path | `rtl/stream/c_stream_burst_correction_path.v` |
| [rtl/control/c_stream_correction_path.v](../rtl/control/c_stream_correction_path.v) | c_stream_correction_path | `rtl/stream/c_stream_correction_path.v` |
| [rtl/control/frame_processor.v](../rtl/control/frame_processor.v) | frame_processor | `diagnostics/ddr_camera_hires_20261011/results/frame_processor.v` |
| [rtl/control/frame_processor_stream.v](../rtl/control/frame_processor_stream.v) | frame_processor_stream | `rtl/stream/frame_processor_stream.v` |
| [rtl/display/ddr_result_display.v](../rtl/display/ddr_result_display.v) | ddr_result_display | `diagnostics/ddr_camera_hires_prefetch_20261012/results/ddr_result_display.v` |
| [rtl/display/ddr_result_display_block64.v](../rtl/display/ddr_result_display_block64.v) | ddr_result_display_block64 | `rtl/stream/ddr_result_display_block64.v` |
| [rtl/display/frame_telemetry_overlay.v](../rtl/display/frame_telemetry_overlay.v) | frame_telemetry_overlay | `rtl/stream/frame_telemetry_overlay.v` |
| [rtl/display/result_display.v](../rtl/display/result_display.v) | result_display | `rtl/video/result_display.v` |
| [rtl/display/rx_preview.v](../rtl/display/rx_preview.v) | rx_preview | `rtl/video/rx_preview.v` |
| [rtl/display/rx_preview_stream.v](../rtl/display/rx_preview_stream.v) | rx_preview_stream | `rtl/stream/rx_preview_stream.v` |
| [rtl/display/status_overlay.v](../rtl/display/status_overlay.v) | status_overlay | `rtl/video/status_overlay.v` |
| [rtl/display/video_timing_vtc.v](../rtl/display/video_timing_vtc.v) | video_timing_vtc | `vendor/c_current/01_design_code/video_timing_vtc.v` |
| [rtl/geometry/c_corner_rectifier.v](../rtl/geometry/c_corner_rectifier.v) | c_corner_rectifier | `rtl/algo/c_corner_rectifier.v` |
| [rtl/geometry/capture_geometry.v](../rtl/geometry/capture_geometry.v) | capture_geometry | `rtl/algo/capture_geometry.v` |
| [rtl/geometry/continuous_capture_geometry.v](../rtl/geometry/continuous_capture_geometry.v) | continuous_capture_geometry | `rtl/stream/continuous_capture_geometry.v` |
| [rtl/geometry/geometry_frame_join.v](../rtl/geometry/geometry_frame_join.v) | geometry_frame_join | `rtl/algo/geometry_frame_join.v` |
| [rtl/geometry/marker_detector.v](../rtl/geometry/marker_detector.v) | marker_detector | `rtl/algo/marker_detector.v` |
| [rtl/hdmi/hdmi_config.v](../rtl/hdmi/hdmi_config.v) | hdmi_config | `rtl/hdmi/hdmi_config.v` |
| [rtl/hdmi/hdmi_vs_recover.v](../rtl/hdmi/hdmi_vs_recover.v) | hdmi_vs_recover | `vendor/c_current/01_design_code/hdmi_vs_recover.v` |
| [rtl/hdmi/iic_dri.v](../rtl/hdmi/iic_dri.v) | iic_dri | `rtl/hdmi/iic_dri.v` |
| [rtl/hdmi/ms7200_ctl.v](../rtl/hdmi/ms7200_ctl.v) | ms7200_ctl | `diagnostics/ddr_camera_reconnect_20261011/results/ms7200_ctl.v` |
| [rtl/hdmi/ms7210_ctl.v](../rtl/hdmi/ms7210_ctl.v) | ms7210_ctl | `rtl/hdmi/ms7210_ctl.v` |
| [rtl/memory/ddr_arbiter3.v](../rtl/memory/ddr_arbiter3.v) | ddr_arbiter3 | `rtl/memory/ddr_arbiter3.v` |
| [rtl/memory/ddr_arbiter3_fair.v](../rtl/memory/ddr_arbiter3_fair.v) | ddr_arbiter3_fair | `rtl/stream/ddr_arbiter3_fair.v` |
| [rtl/memory/ddr_arbiter3_turnaround.v](../rtl/memory/ddr_arbiter3_turnaround.v) | ddr_arbiter3_turnaround | `rtl/stream/ddr_arbiter3_turnaround.v` |
| [rtl/memory/ddr_result_writer.v](../rtl/memory/ddr_result_writer.v) | ddr_result_writer | `rtl/memory/ddr_result_writer.v` |
| [rtl/memory/ddr_result_writer_burst64.v](../rtl/memory/ddr_result_writer_burst64.v) | ddr_result_writer_burst64, burst64_async_fifo | `rtl/stream/ddr_result_writer_burst64.v` |
| [rtl/memory/ddr_result_writer_stream.v](../rtl/memory/ddr_result_writer_stream.v) | ddr_result_writer_stream, stream_writer_async_fifo | `rtl/stream/ddr_result_writer_stream.v` |
| [rtl/memory/ddr_self_test.v](../rtl/memory/ddr_self_test.v) | ddr_self_test | `rtl/memory/ddr_self_test.v` |
| [rtl/memory/ddr_word_engine.v](../rtl/memory/ddr_word_engine.v) | ddr_word_engine | `diagnostics/ddr_camera_hires_prefetch_20261012/results/ddr_word_engine.v` |
| [rtl/memory/ddr_word_engine_result_burst.v](../rtl/memory/ddr_word_engine_result_burst.v) | ddr_word_engine_result_burst | `rtl/stream/ddr_word_engine_result_burst.v` |
| [rtl/top/frame_session.v](../rtl/top/frame_session.v) | frame_session, frame_session_overlap | `rtl/top/frame_session.v` |
| [rtl/top/frame_session_overlap_stream.v](../rtl/top/frame_session_overlap_stream.v) | frame_session_overlap_stream | `rtl/top/frame_session_overlap_stream.v` |
| [rtl/top/video_correct_ddr_continuous_core.v](../rtl/top/video_correct_ddr_continuous_core.v) | video_correct_ddr_continuous_core | `rtl/top/video_correct_ddr_continuous_core.v` |
| [rtl/top/video_correct_ddr_core.v](../rtl/top/video_correct_ddr_core.v) | video_correct_ddr_core | `rtl/top/video_correct_ddr_core.v` |
| [rtl/top/video_correct_ddr_stream_core.v](../rtl/top/video_correct_ddr_stream_core.v) | video_correct_ddr_stream_core | `rtl/top/video_correct_ddr_stream_core.v` |
| [rtl/top/video_correct_ddr_top.v](../rtl/top/video_correct_ddr_top.v) | video_correct_ddr_top | `diagnostics/ddr_camera_hires_prefetch_20261012/results/video_correct_ddr_top.v` |
