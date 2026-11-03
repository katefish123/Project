# FPGA 黑色角标透视校正工程 · 教师审核包

**审核版本：C V4S，最近一次实际烧录并由用户确认能显示校正页的版本。**

| 项目 | 固定内容 |
|---|---|
| 来源 | [PythonProject_update](https://github.com/katefish123/PythonProject_update)，`c-pipeline-next` |
| 生产源码提交 | `a8c42b8` |
| 器件/工具 | PG2L100H，-6，FBG676；PDS 2022.2-SP6.4 |
| 输入 | 1920×1080 RGB888，完整源图写入 DDR |
| 检测 | 四个固定 ROI 内的黑色像素质心，顺序 TL/TR/BR/BL |
| 输出 | 有效 765×1080；存储 768×1080；1080p HDMI 居中显示 |
| 已烧录码流 SHA256 | `3e3475d30e6fa2488a57a084aa236353077b91d80969b7d1c412c89c064d1b50` |
| 整理日期 | 2026-10-18 |

本包只围绕上述已烧录版本整理。135 个设计文件和 1 个约束均按原字节复制，已核对原 V4S 实现回执的 136 个 SHA256；路径重新分类，并提供相对路径工程入口。原始发布和本机原工程保留。

## 老师从哪里开始看

可先双击 [README.html](README.html) 查看无需联网的审核导览，再打开以下说明。

1. [项目说明与数据通路](docs/01_PROJECT_OVERVIEW.md)：目标、配置、模块关系与完成边界。
2. [源码导读](docs/02_SOURCE_GUIDE.md)：按功能分类的全部源文件及优先阅读路径。
3. [构建与仿真](docs/03_BUILD_AND_TEST.md)：打开 PDS、重新构建、运行仿真。
4. [验证与上板结果](docs/04_VALIDATION.md)：区分原仿真、原物理时序、本次实板观察及缺失项。
5. [硬件接线与操作](docs/05_HARDWARE.md)：按键、LED、固定检测区与故障排查。
6. [版本来源与使用说明](docs/06_PROVENANCE.md)：团队来源、厂商 IP、校验方式。

## 目录

```text
rtl/          按功能分类的 Verilog 源码
ip/           原 DDR3 IP 与 PLL 文件
constraints/  板卡引脚和时序约束
project/      PDS 工程入口、构建脚本和源码哈希清单
bitstream/    本次实际下载的 V4S .sbit 与校验值
sim/          原 V4S 整机 testbench、两种尺寸三幅图向量、B 参考模型
evidence/     原时序/仿真回执及本次下载日志、用户观察记录
docs/         审核说明、源码索引、复现方法与硬件操作
scripts/      文件校验、工程构建、仿真及显式 CRAM 下载入口
build/        本机验证/后续运行输出，不属于原实现证据
```

## 当前结论

- 原 V4S 的完整 60 图数字仿真及已约束物理时序通过，证据在 `evidence/`。
- 本次 Program 成功，芯片配置完成，CRC 错误位为 0。用户反馈“有矫正页了”，并对短时更新检查回复“可以了我觉得”。
- 曾出现 `DDR ALIGN ERROR`、LED6 不亮；重新上电并重烧同一码流后恢复。根因未确认，原故障截图保留。
- V4S 原发布缺少配套 `.smsk`，本次完整回读 Verify 未完成。临时 CRAM 下载断电后失效，未写启动 Flash。
- 实际相机帧率、长期稳定性、温升、自由旋转、镜头标定及精确几何未验收。HDMI 扫描频率与仿真的新图速率不能直接当作板上实测结果。

## 首先校验文件

在本包根目录打开 PowerShell，运行：

```powershell
.\scripts\Test-Package.ps1
```

查看源码可直接从 `rtl/top/video_correct_ddr_top.v` 开始。PDS 原生工程位于 `project/V4S_Review.pds`；也可通过 `scripts/Build-Project.ps1 -Stage Import` 重新生成工程。操作步骤及工具路径参数见构建说明。
