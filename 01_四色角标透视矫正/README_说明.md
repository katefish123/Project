# 四色标记透视矫正

检测红、绿、黄、蓝四种标记的质心，分别对应纸张左上、右上、右下、左下；由四点求逆透视矩阵 H，再从目的像素映射回源图取样。支持最近邻和双线性插值。

适合研究四色标记检测、四点单应变换和 A/B/C 算法接口。

## 工程入口与来源

- 工程根目录：当前 `01_四色角标透视矫正/`，可直接打开 [`README.md`](README.md)、[`rtl/`](rtl/) 和 [`python/`](python/)。
- 原 ZIP 已从当前分支删除；原包可在 [Git 历史](https://github.com/katefish123/PythonProject_update/blob/510c040f8da06e67f5b9b64f9c851dffeff3a8b0/member_b_perspective_final.zip) 中查看。
- 已解压的 517 个文件内容保留；本次去掉重复的外层工程目录。
- [文件清单](EXTRACTION_MANIFEST.json) 同时记录原 ZIP 路径、当前路径、字节数和 SHA256。

运行原说明中的命令时，进入当前目录即可。原文件内的历史绝对路径或外部备份引用仍按其原记录理解。

## 目录功能

| 目录 | 功能 |
| --- | --- |
| [`rtl/`](rtl/) | Verilog 算法源文件。 |
| [`python/`](python/) | Python 浮点/定点参考与命令行入口。 |
| [`sim/`](sim/) | 自检查 testbench 与 tests.list 测试清单。 |
| [`scripts/`](scripts/) | 测试、向量生成、演示和参数导出。 |
| [`examples/`](examples/) | 示例图片、参数、阈值及 RTL 接线。 |
| [`vectors/`](vectors/) | 输入数据、期望输出与数值测试向量。 |
| [`results/`](results/) | 历史日志、CSV、图像与验证结果；并非本次重跑结果。 |
| [`docs/`](docs/) | 算法、接口、集成和验证文档。 |
| [`backups/`](backups/) | 历史版本与旧结果快照，应按其原日期理解。 |
| [`work/`](work/) | 原 ModelSim 编译工作库和缓存，不是算法源文件。 |

## 主要文件

| 文件 | 功能 |
| --- | --- |
| [`rtl/b_rectifier.v`](rtl/b_rectifier.v) | B 算法封装：检测、H 求解、pending/active 参数和帧边界切换。 |
| [`rtl/marker_detector.v`](rtl/marker_detector.v) | 标记检测、像素计数与坐标累加，计算四个质心并拒绝无效帧；黑标版增加 ROI 区分。 |
| [`rtl/homography_solver.v`](rtl/homography_solver.v) | 根据四个角点求单应矩阵 H，使用共享迭代除法器。 |
| [`rtl/perspective_coord.v`](rtl/perspective_coord.v) | H 乘加及流水除法，将目的坐标转换为源图 UQ12.8 坐标。 |
| [`rtl/scaled_div_pipe.v`](rtl/scaled_div_pipe.v) | 坐标计算使用的定点流水除法。 |
| [`rtl/signed_div_seq.v`](rtl/signed_div_seq.v) | 参数求解使用的有符号迭代除法。 |
| [`rtl/unsigned_div_seq.v`](rtl/unsigned_div_seq.v) | 质心等计算使用的无符号迭代除法。 |
| [`rtl/perspective_core.v`](rtl/perspective_core.v) | 生成源图四邻域地址和插值权重，连接缓存响应与插值。 |
| [`rtl/bilinear_interp.v`](rtl/bilinear_interp.v) | 按权重计算 RGB888 双线性插值；最近邻模式复用该通路。 |
| [`python/brect/golden.py`](python/brect/golden.py) | 独立浮点参考：标记检测、H 求解与图像重采样。 |
| [`python/brect/fixed.py`](python/brect/fixed.py) | 定点参考：H、坐标、缓存地址和插值数值。 |
| [`python/brect/cli.py`](python/brect/cli.py) | 静态图片命令行演示及可选摄像头采集/显示入口。 |
| [`examples/b_rectifier_instance.v`](examples/b_rectifier_instance.v) | B 模块实例化与 A/C 接口连接示例。 |
| [`scripts/run_checks.py`](scripts/run_checks.py) | 运行 Python、RTL 检查并生成验证报告；会重建部分结果文件。 |
| [`scripts/generate_vectors.py`](scripts/generate_vectors.py) | 生成仿真输入和参考向量。 |
| [`scripts/make_demo.py`](scripts/make_demo.py) | 生成示例场景与浮点/定点对照图片。 |
| [`run_modelsim.do`](run_modelsim.do) | ModelSim/Questa 编译与仿真脚本。 |
| [`run_checks.bat`](run_checks.bat) | Windows 检查入口。 |
| [`results/verification.json`](results/verification.json) | 包内历史验证结果、测试列表、限制和源码校验信息。 |
| [`docs/algorithm.md`](docs/algorithm.md) | 坐标约定、H 推导、定点算法及采样规则。 |
| [`docs/interfaces.md`](docs/interfaces.md) | A/B/C 请求、缓存响应、标签及帧边界接口合同。 |

## 包内已有的验证记录

2026-10-06，10 项 Python 检查、8 项 Icarus RTL 自检查；包内状态为 pass。这些是原包保存的记录，本次仅检查解压完整性、文件一致性和说明链接，没有重新运行算法、仿真、PDS 或上板。原报告见 [`results/verification.json`](results/verification.json)。

这些包的算法仿真记录不能替代 PDS 综合/布局布线、资源及时序、DDR/HDMI 联调、板上帧率或整机验收。

原 ZIP 的 `__MACOSX/`、`._*` 和 `.DS_Store` 也已原样保留，它们是 macOS 元数据，不是 RTL 或算法入口。Git 不保存独立空目录，原目录条目记录在解压清单中。
