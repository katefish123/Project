# 黑色四角标记透视矫正

以 RGB 各通道阈值识别黑色像素，在四个互不重叠的 ROI 中分别统计质心；按左上、右上、右下、左下计算 H 并做逆映射取样。输出仍是 RGB888 彩色图像。

适合使用四个黑色角标的纸面透视矫正。ROI 内所有黑色像素都会参与统计，没有连通域或最大黑块筛选，正文、阴影等可能干扰质心。

## 原包与解压结构

- 原 ZIP：[同名压缩包](../member_b_perspective_black.zip)。
- 工程根目录：[`member_b_perspective_black/`](member_b_perspective_black/)，原 README：[打开](member_b_perspective_black/README.md)。
- 已逐字节核对 296 个文件、14,857,989 字节，ZIP CRC 检查通过；原路径和文件内容均保留。
- [解压清单](EXTRACTION_MANIFEST.json) 列出每个原包文件的路径、大小和 SHA256，以及目录条目。

原包已有一层工程目录，因此外层同名目录用于隔离不同 ZIP；运行命令时进入上述工程根目录。

## 目录功能

| 目录 | 功能 |
| --- | --- |
| [`rtl/`](member_b_perspective_black/rtl/) | Verilog 算法源文件。 |
| [`python/`](member_b_perspective_black/python/) | Python 浮点/定点参考与命令行入口。 |
| [`sim/`](member_b_perspective_black/sim/) | 自检查 testbench 与 tests.list 测试清单。 |
| [`scripts/`](member_b_perspective_black/scripts/) | 测试、向量生成、演示和参数导出。 |
| [`examples/`](member_b_perspective_black/examples/) | 示例图片、参数、阈值及 RTL 接线。 |
| [`vectors/`](member_b_perspective_black/vectors/) | 输入数据、期望输出与数值测试向量。 |
| [`results/`](member_b_perspective_black/results/) | 历史日志、CSV、图像与验证结果；并非本次重跑结果。 |
| [`docs/`](member_b_perspective_black/docs/) | 算法、接口、集成和验证文档。 |
| [`backups/`](member_b_perspective_black/backups/) | 历史版本与旧结果快照，应按其原日期理解。 |

## 主要文件

| 文件 | 功能 |
| --- | --- |
| [`rtl/b_rectifier.v`](member_b_perspective_black/rtl/b_rectifier.v) | B 算法封装：检测、H 求解、pending/active 参数和帧边界切换。 |
| [`rtl/marker_detector.v`](member_b_perspective_black/rtl/marker_detector.v) | 标记检测、像素计数与坐标累加，计算四个质心并拒绝无效帧；黑标版增加 ROI 区分。 |
| [`rtl/homography_solver.v`](member_b_perspective_black/rtl/homography_solver.v) | 根据四个角点求单应矩阵 H，使用共享迭代除法器。 |
| [`rtl/perspective_coord.v`](member_b_perspective_black/rtl/perspective_coord.v) | H 乘加及流水除法，将目的坐标转换为源图 UQ12.8 坐标。 |
| [`rtl/scaled_div_pipe.v`](member_b_perspective_black/rtl/scaled_div_pipe.v) | 坐标计算使用的定点流水除法。 |
| [`rtl/signed_div_seq.v`](member_b_perspective_black/rtl/signed_div_seq.v) | 参数求解使用的有符号迭代除法。 |
| [`rtl/unsigned_div_seq.v`](member_b_perspective_black/rtl/unsigned_div_seq.v) | 质心等计算使用的无符号迭代除法。 |
| [`rtl/perspective_core.v`](member_b_perspective_black/rtl/perspective_core.v) | 生成源图四邻域地址和插值权重，连接缓存响应与插值。 |
| [`rtl/bilinear_interp.v`](member_b_perspective_black/rtl/bilinear_interp.v) | 按权重计算 RGB888 双线性插值；最近邻模式复用该通路。 |
| [`python/brect/golden.py`](member_b_perspective_black/python/brect/golden.py) | 独立浮点参考：标记检测、H 求解与图像重采样。 |
| [`python/brect/fixed.py`](member_b_perspective_black/python/brect/fixed.py) | 定点参考：H、坐标、缓存地址和插值数值。 |
| [`python/brect/cli.py`](member_b_perspective_black/python/brect/cli.py) | 静态图片命令行演示及可选摄像头采集/显示入口。 |
| [`examples/b_rectifier_instance.v`](member_b_perspective_black/examples/b_rectifier_instance.v) | B 模块实例化与 A/C 接口连接示例。 |
| [`scripts/run_checks.py`](member_b_perspective_black/scripts/run_checks.py) | 运行 Python、RTL 检查并生成验证报告；会重建部分结果文件。 |
| [`scripts/generate_vectors.py`](member_b_perspective_black/scripts/generate_vectors.py) | 生成仿真输入和参考向量。 |
| [`scripts/make_demo.py`](member_b_perspective_black/scripts/make_demo.py) | 生成示例场景与浮点/定点对照图片。 |
| [`run_modelsim.do`](member_b_perspective_black/run_modelsim.do) | ModelSim/Questa 编译与仿真脚本。 |
| [`run_checks.bat`](member_b_perspective_black/run_checks.bat) | Windows 检查入口。 |
| [`results/verification.json`](member_b_perspective_black/results/verification.json) | 包内历史验证结果、测试列表、限制和源码校验信息。 |
| [`docs/algorithm.md`](member_b_perspective_black/docs/algorithm.md) | 坐标约定、H 推导、定点算法及采样规则。 |
| [`docs/interfaces.md`](member_b_perspective_black/docs/interfaces.md) | A/B/C 请求、缓存响应、标签及帧边界接口合同。 |

## 包内已有的验证记录

2026-10-11，17 项 Python 检查、9 项 Icarus RTL 自检查；包内状态为 pass。这些是原包保存的记录，本次仅检查解压完整性、文件一致性和说明链接，没有重新运行算法、仿真、PDS 或上板。原报告见 [`results/verification.json`](member_b_perspective_black/results/verification.json)。

这些包的算法仿真记录不能替代 PDS 综合/布局布线、资源及时序、DDR/HDMI 联调、板上帧率或整机验收。

原 README 中提到的同级 `member_b_perspective_original_2026-10-11.zip` 和 `source_backup_manifest.json` 不在此 ZIP 内；本次未补造这些文件。更详细的逐文件指南见 [`docs/file_guide.md`](member_b_perspective_black/docs/file_guide.md)。
