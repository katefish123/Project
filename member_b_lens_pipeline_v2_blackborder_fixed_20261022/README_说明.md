# 镜头畸变校正与自动去黑边

读取相机标定 JSON，按 k1/k2 二阶径向畸变与 p1/p2 切向畸变计算源坐标；可与显式 H 组合，一次重采样完成映射。默认裁剪有效区域并等比例放大以减少越界黑边。新的镜头入口不依赖四色或黑色角标。

适合研究真实相机内参、镜头畸变、定点坐标流水和有效视野裁剪。裁剪会损失部分视野；试标定参数来自佳能 R50 的 18mm、1920×1080 HDMI 场景，保留 deploy_to_fpga=false。自动识别无标记纸边和动态姿态控制层尚未实现。

## 原包与解压结构

- 原 ZIP：[同名压缩包](../member_b_lens_pipeline_v2_blackborder_fixed_20261022.zip)。
- 工程根目录：[`member_b_lens_pipeline_v2/`](member_b_lens_pipeline_v2/)，原 README：[打开](member_b_lens_pipeline_v2/README.md)。
- 已逐字节核对 186 个文件、7,786,167 字节，ZIP CRC 检查通过；原路径和文件内容均保留。
- [解压清单](EXTRACTION_MANIFEST.json) 列出每个原包文件的路径、大小和 SHA256，以及目录条目。

原包已有一层工程目录，因此外层同名目录用于隔离不同 ZIP；运行命令时进入上述工程根目录。

## 目录功能

| 目录 | 功能 |
| --- | --- |
| [`rtl/`](member_b_lens_pipeline_v2/rtl/) | Verilog 算法源文件。 |
| [`python/`](member_b_lens_pipeline_v2/python/) | Python 浮点/定点参考与命令行入口。 |
| [`sim/`](member_b_lens_pipeline_v2/sim/) | 自检查 testbench 与 tests.list 测试清单。 |
| [`scripts/`](member_b_lens_pipeline_v2/scripts/) | 测试、向量生成、演示和参数导出。 |
| [`examples/`](member_b_lens_pipeline_v2/examples/) | 示例图片、参数、阈值及 RTL 接线。 |
| [`vectors/`](member_b_lens_pipeline_v2/vectors/) | 输入数据、期望输出与数值测试向量。 |
| [`results/`](member_b_lens_pipeline_v2/results/) | 历史日志、CSV、图像与验证结果；并非本次重跑结果。 |
| [`docs/`](member_b_lens_pipeline_v2/docs/) | 算法、接口、集成和验证文档。 |
| [`calibration/`](member_b_lens_pipeline_v2/calibration/) | 相机试标定 JSON 与参数元数据。 |

## 主要文件

| 文件 | 功能 |
| --- | --- |
| [`rtl/b_rectifier.v`](member_b_lens_pipeline_v2/rtl/b_rectifier.v) | B 算法封装：检测、H 求解、pending/active 参数和帧边界切换。 |
| [`rtl/marker_detector.v`](member_b_lens_pipeline_v2/rtl/marker_detector.v) | 标记检测、像素计数与坐标累加，计算四个质心并拒绝无效帧；黑标版增加 ROI 区分。 |
| [`rtl/homography_solver.v`](member_b_lens_pipeline_v2/rtl/homography_solver.v) | 根据四个角点求单应矩阵 H，使用共享迭代除法器。 |
| [`rtl/perspective_coord.v`](member_b_lens_pipeline_v2/rtl/perspective_coord.v) | H 乘加及流水除法，将目的坐标转换为源图 UQ12.8 坐标。 |
| [`rtl/scaled_div_pipe.v`](member_b_lens_pipeline_v2/rtl/scaled_div_pipe.v) | 坐标计算使用的定点流水除法。 |
| [`rtl/signed_div_seq.v`](member_b_lens_pipeline_v2/rtl/signed_div_seq.v) | 参数求解使用的有符号迭代除法。 |
| [`rtl/unsigned_div_seq.v`](member_b_lens_pipeline_v2/rtl/unsigned_div_seq.v) | 质心等计算使用的无符号迭代除法。 |
| [`rtl/perspective_core.v`](member_b_lens_pipeline_v2/rtl/perspective_core.v) | 生成源图四邻域地址和插值权重，连接缓存响应与插值。 |
| [`rtl/bilinear_interp.v`](member_b_lens_pipeline_v2/rtl/bilinear_interp.v) | 按权重计算 RGB888 双线性插值；最近邻模式复用该通路。 |
| [`python/brect/golden.py`](member_b_lens_pipeline_v2/python/brect/golden.py) | 独立浮点参考：标记检测、H 求解与图像重采样。 |
| [`python/brect/fixed.py`](member_b_lens_pipeline_v2/python/brect/fixed.py) | 定点参考：H、坐标、缓存地址和插值数值。 |
| [`python/brect/cli.py`](member_b_lens_pipeline_v2/python/brect/cli.py) | 静态图片命令行演示及可选摄像头采集/显示入口。 |
| [`examples/b_rectifier_instance.v`](member_b_lens_pipeline_v2/examples/b_rectifier_instance.v) | B 模块实例化与 A/C 接口连接示例。 |
| [`scripts/run_checks.py`](member_b_lens_pipeline_v2/scripts/run_checks.py) | 运行 Python、RTL 检查并生成验证报告；会重建部分结果文件。 |
| [`scripts/generate_vectors.py`](member_b_lens_pipeline_v2/scripts/generate_vectors.py) | 生成仿真输入和参考向量。 |
| [`scripts/make_demo.py`](member_b_lens_pipeline_v2/scripts/make_demo.py) | 生成示例场景与浮点/定点对照图片。 |
| [`run_modelsim.do`](member_b_lens_pipeline_v2/run_modelsim.do) | ModelSim/Questa 编译与仿真脚本。 |
| [`run_checks.bat`](member_b_lens_pipeline_v2/run_checks.bat) | Windows 检查入口。 |
| [`results/verification.json`](member_b_lens_pipeline_v2/results/verification.json) | 包内历史验证结果、测试列表、限制和源码校验信息。 |
| [`docs/algorithm.md`](member_b_lens_pipeline_v2/docs/algorithm.md) | 坐标约定、H 推导、定点算法及采样规则。 |
| [`docs/interfaces.md`](member_b_lens_pipeline_v2/docs/interfaces.md) | A/B/C 请求、缓存响应、标签及帧边界接口合同。 |
| [`calibration/r50_18mm_hdmi_trial.json`](member_b_lens_pipeline_v2/calibration/r50_18mm_hdmi_trial.json) | 试标定内参、畸变参数和适用条件。 |
| [`python/brect/calibration.py`](member_b_lens_pipeline_v2/python/brect/calibration.py) | 读取、校验标定 JSON，形成硬件定点参数。 |
| [`python/brect/lens.py`](member_b_lens_pipeline_v2/python/brect/lens.py) | 浮点和精确定点镜头映射，以及与 H 的组合取样。 |
| [`python/brect/lens_cli.py`](member_b_lens_pipeline_v2/python/brect/lens_cli.py) | 镜头矫正图片入口，支持有效区裁剪和保留原视野。 |
| [`python/brect/viewport.py`](member_b_lens_pipeline_v2/python/brect/viewport.py) | 规划有效区域、裁剪缩放及安全采样范围。 |
| [`rtl/lens_distort_coord.v`](member_b_lens_pipeline_v2/rtl/lens_distort_coord.v) | 二阶径向/切向坐标流水，10 个寄存级，可每拍接收一个请求。 |
| [`examples/lens_pipeline_instance.v`](member_b_lens_pipeline_v2/examples/lens_pipeline_instance.v) | 启用镜头校正的新 RTL 实例。 |
| [`examples/lens_autocrop_instance.v`](member_b_lens_pipeline_v2/examples/lens_autocrop_instance.v) | 绑定标定参数和有效 H 的去黑边实例。 |
| [`examples/r50_18mm_viewport.vh`](member_b_lens_pipeline_v2/examples/r50_18mm_viewport.vh) | 去黑边实例使用的尺寸、定点内参和 H 常量。 |
| [`scripts/export_calibration.py`](member_b_lens_pipeline_v2/scripts/export_calibration.py) | 标定 JSON 导出为硬件常量和元数据。 |
| [`scripts/export_lens_viewport.py`](member_b_lens_pipeline_v2/scripts/export_lens_viewport.py) | 导出去黑边视野的配置及硬件头文件。 |
| [`docs/black_border_handling.md`](member_b_lens_pipeline_v2/docs/black_border_handling.md) | 去黑边方法、视野损失及适用边界。 |
| [`docs/integration_lens_v2.md`](member_b_lens_pipeline_v2/docs/integration_lens_v2.md) | 镜头通路接线、H 方向及缓存集成方式。 |
| [`docs/validation_lens_v2.md`](member_b_lens_pipeline_v2/docs/validation_lens_v2.md) | 镜头及去黑边验证范围、数值对照和剩余工作。 |

## 包内已有的验证记录

2026-10-22，原 Python 10 项、镜头 Python 8 项、去黑边 Python 7 项、Icarus RTL 11 项；包内状态为 pass。这些是原包保存的记录，本次仅检查解压完整性、文件一致性和说明链接，没有重新运行算法、仿真、PDS 或上板。原报告见 [`results/verification.json`](member_b_lens_pipeline_v2/results/verification.json)。

这些包的算法仿真记录不能替代 PDS 综合/布局布线、资源及时序、DDR/HDMI 联调、板上帧率或整机验收。
