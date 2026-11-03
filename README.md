# main-B：B 成员算法工程

本分支的三个 ZIP 已分别解压到独立的同名目录。原压缩包和已有 `final/` 目录保留；不同版本的源码、演示和历史验证记录分别存放。

## 选择工程

| 功能 | 解压目录与说明 | 原压缩包 |
| --- | --- | --- |
| 四色标记透视矫正 | [member_b_perspective_final/](member_b_perspective_final/README_说明.md) | [ZIP](member_b_perspective_final.zip) |
| 黑色四角标记透视矫正 | [member_b_perspective_black/](member_b_perspective_black/README_说明.md) | [ZIP](member_b_perspective_black.zip) |
| 镜头畸变校正与自动去黑边 | [member_b_lens_pipeline_v2_blackborder_fixed_20261022/](member_b_lens_pipeline_v2_blackborder_fixed_20261022/README_说明.md) | [ZIP](member_b_lens_pipeline_v2_blackborder_fixed_20261022.zip) |

四色版以颜色区分四角；黑标版以四个 ROI 区分同色角标；镜头 V2 的新入口读取标定参数，不要求角标，并支持有效区裁剪去黑边。镜头校正与纸面透视校正是不同功能，镜头包尚未实现自动识别无标记纸边。

## 文件怎么读

每个解压目录的 `README_说明.md` 解释目录、主要 RTL/Python 文件、入口和包内已有验证范围；`EXTRACTION_MANIFEST.json` 列出原 ZIP 中全部文件的路径、字节数和 SHA256。进入解压目录内原有的工程根目录后再使用原运行说明。

各包通常包含 `rtl/` 算法硬件、`python/` 数值参考、`sim/` 仿真、`scripts/` 测试及演示脚本、`examples/` 图片和接线、`vectors/` 测试向量、`results/` 历史证据、`docs/` 接口和算法文档。`backups/` 是历史资料；`work/` 是编译缓存；`__MACOSX/` 是系统元数据。

已有 [`final/`](final/README.md) 作为分支原有文件集合保留；它与 `member_b_perspective_final.zip` 的解压目录分开存放，没有互相覆盖。

## 整理校验

原分支提交：`510c040f8da06e67f5b9b64f9c851dffeff3a8b0`。三个 ZIP 的 CRC 均通过，解压出的 999 个文件逐字节与原 ZIP 一致，所有原包内容均保留。原 ZIP 及分支原有文件未修改。

本次仅整理和阅读文件，没有运行包内程序或重新验证 FPGA 功能。各包的 pass 状态属于原包历史软件/RTL 仿真记录；PDS 时序、板上 DDR/HDMI、整机帧率及硬件验收应按相应实际证据判断。
