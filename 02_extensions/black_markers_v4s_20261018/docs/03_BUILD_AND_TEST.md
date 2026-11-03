# 打开工程、构建与仿真

## 环境

- Windows；PDS 2022.2-SP6.4，器件 PG2L100H -6 FBG676 及厂商 IP 支持。
- ModelSim SE-64 2020.4 用于所附整机行为仿真。
- 可选 Python 3.12、NumPy 2.3.5、Pillow 12.3.0，用于核验数值向量。

Verilog、IP 和约束均在包内；不依赖原作者的 C:/D/FPGA、D:/FPGA 或 Git 工作区。原始证据中的绝对路径仅为历史记录。建议解压到英文路径，如 C:/FPGA_Review。

## PDS 入口

直接用 PDS 打开 project/V4S_Review.pds。此文件使用相对路径，包含 135 个设计文件和 1 个约束。需要在新的 build 目录生成可编辑工程副本时，在包根目录运行：

```powershell
.\scripts\Build-Project.ps1 -Stage Import
```

命令只复制并解析包内工程路径，显示生成的 .pds 位置，不连接板卡。

只做编译检查：

```powershell
.\scripts\Build-Project.ps1 -Stage Compile -PdsBin 'C:\pango\PDS_2022.2-SP6.4\bin'
```

完整重新综合、映射、布局布线、报告时序并生成新码流：

```powershell
.\scripts\Build-Project.ps1 -Stage Full
```

Full 在新运行目录生成平铺的 PDS Tcl，保持原 V4S 的 17 号布局/布线种子及多工艺角时序优化选项，不放宽约束。每次输出到新的 build/pds_阶段_时间/。工具可能在退出码为 0 时仍报错，脚本同时检查日志的错误和完成标志。

本次整理只验证工程导入、编译与行为回归，没有重新布局生成替代原版码流。重建得到的新文件应查看自己的最终时序报告，并重新板测；不能继承原发布通过结论，也不要求新码流字节与原发布相同。

## 仿真

缩小尺寸 6 图压力测试，包含坏角标拒绝后恢复：

```powershell
.\scripts\Run-Simulation.ps1 -Frames 6 -ModelSimBin 'C:\modeltech64_2020.4\win64'
```

原生尺寸短回归：

```powershell
.\scripts\Run-Simulation.ps1 -Native -Frames 3 -Stress 0
```

需要长回归时可将 Frames 改为 60。原 V4S 的 60 图历史资格记录保存在 evidence/simulation/original_qualification.json；它与本次整理后的回放结果分开记录。

testbench 保留原 V4S 应用层 DDR 模型与数值断言，将向量路径改为包内相对路径，并将处理时钟及毫秒分频对齐本版 57.115 MHz / 57115 周期配置。生产 RTL 未改。数字模型不包含真实 DRAM、训练、DQS、电气条件或镜头成像。脚本检查 test_passed 真值、成功标记和工具错误；输出保存在 build/sim_native值_frames数量_时间/。

数值向量核验，可选，需要 Python 依赖：

```powershell
python -m pip install -r .\sim\requirements.txt
python .\sim\verify_vectors.py --size all
```

fixture PNG 是合成输入和参考输出，不是本次相机成功出图的证据。

## 下载

实际烧录文件仅位于 bitstream/video_correct_ddr_top.sbit。显式执行以下命令才会连接下载器：

```powershell
.\scripts\Program-V4S.ps1 -PdsBin 'C:\pango\PDS_2022.2-SP6.4\bin'
```

校验、导入工程、编译和仿真不会操作硬件。本版缺配套 smsk，下载脚本明确记录 Verify 未执行，不假报回读成功。下载为临时 CRAM，未写 Flash；断电后需要重烧。
