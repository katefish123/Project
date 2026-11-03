# FPGA 1080p30 完整 PDS 工程与烧录文件

这是当前源码对应的完整工程包，包含已经完成的布局布线现场和生成文件。没有增加功能、提高性能指标或修改 RTL、引脚、时钟约束。

**当前状态：烧录文件已生成；时序尚未闭合，未做上板验证。** 最终报告共 104 行时序汇总，其中 10 行违例，最差裕量 -1.272 ns。该包可用于继续工程和受控上板验证，不能据此声称硬件已稳定运行或时序合格。

## 使用入口

- 已生成文件：`firmware/video_correct_ddr_top.sbit`。
- 读回校验掩码：`firmware/video_correct_ddr_top.smsk`，它不是第二个烧录文件。
- 完整 PDS 工程：`native_project/FPGA_Nov01.pds`。解压整个目录后在 PDS 中打开，保留目录结构。
- 重新完整编译：Windows 下运行 `rebuild_windows.cmd`，输出到 `rebuild_output/`。需要 PDS 2022.2-SP6.4 及有效编译许可；安装位置不同时设置 `PDS_HOME`。
- 检查编译入口而不启动编译：`rebuild_windows.cmd --check-only`。
- 核对文件：运行 `verify_files.ps1`，或查看 `MANIFEST_SHA256.json`。

## 固定的硬件目标

Logos2 / PG2L100H / FBG676 / 速度等级 -6；顶层 `video_correct_ddr_top`。沿用现有 MES2L676-100HP 板卡的 144 个 IO 绑定，DDR、HDMI、UART 引脚未变。

使用原有 JTAG 下载线和 PDS 配套配置工具，识别到匹配器件后加载上述 `.sbit`。本次没有连接下载器、写入 FPGA 或擦写 Flash。Flash 固化仍需按实际板卡的 Flash 型号和启动配置选择下载工具设置，包内不含已执行的 Flash 固化结果。

## 编译来源与检查

- 构建：`native_fp_only_20261102_095930`，2026-11-02 15:07 生成码流。
- 151 个源码文件已逐文件核对，与构建输入和目前正在运行的 hfix 作业相同。
- PDS 工程引用的 178 个文件均已收齐，包括综合/映射/布线/时序/码流数据库。
- 144 个 IO 的封装位置与电气属性核对通过；原时钟周期保持不变。
- 详细状态：`evidence/verification.json`；完整报告：`native_project/report_timing/video_correct_ddr_top.rtr`。
- `.sbit` SHA256：`96316cc8db02e948712fe3a5ba64c2d19a94542f3bd2a4e1a275d2f16e6d3f9b`。
- `.smsk` SHA256：`06e6320230d3c23392ed83cfa9afc00695aec6c95c8416fd8fec7eaa20306481`。

这个包保留实际生成结果；正在运行的 `native_fp_only_hfix_20261102_155038` 是另一份布线现场，其最终结果尚未混入本包。
