# Real-Time Lens Distortion Correction on Logos-2 FPGA

基于紫光同创 Logos-2（PG2L100H）的 1080p30 实时镜头畸变矫正与角度控制系统。

A fully hardware video pipeline that captures HDMI 1080p60, stores frames in external DDR3, performs merged inverse-affine + Brown lens mapping, resamples once, and outputs 1080p30 over HDMI. Rotation / scale parameters can be updated from a host over UART and are committed at frame boundaries.

## 目录

- [系统概览](#系统概览)
- [关键特性](#关键特性)
- [架构](#架构)
- [指标](#指标)
- [仓库结构](#仓库结构)
- [构建](#构建)
- [验证](#验证)
- [当前状态](#当前状态)
- [许可](#许可)

## 系统概览

```
Canon R50 (1080p60 HDMI)
        │
   MS7200 HDMI RX ── I²C 配置
        │  148.5 MHz
   双 Bank 整帧采集 ──► DDR3 (x32, 125 MHz UI)
        │                     ▲
        │                     │ 源行 / 结果帧
        ▼                     │
   坐标变换 (逆仿射 + Brown) ──┘
        │
   四邻域分块缓存 (128×2 瓦片, 128 行)
        │
   单次双线性 / 最近邻插值
        │
   结果写回 DDR ──► 显示预取 ──► VTC 1080p30 ──► MS7210 HDMI TX
```

上位机通过 UART 115200 8N1 下发六项 signed40/Q24 逆仿射系数，参数在下一幅新校正帧首拍锁存。

## 关键特性

- **合并逆映射**：镜头畸变与旋转/缩放共用一条坐标链路，每个输出像素只做一次插值。
- **分块缓存**：128×2 像素瓦片、128 行双 Bank 缓存，旋转时按 128×128 分块遍历。
- **连续写回**：每笔 64 像素突发，兼顾 DDR 行内效率与真实地址写回。
- **帧边界参数快照**：240 位整组参数跨时钟传递，切换角度不撕裂。
- **双 Bank 采集**：采集与处理使用不同源 Bank，帧代数防止跨帧误用。
- **可恢复 DDR**：统一仲裁、单笔事务看门狗、自检与恢复流程。
- **双模式插值**：双线性 / 最近邻可切换，支持原图旁路对照。

## 架构

![System architecture](docs/figures/fig1_system_arch.svg)

| 图 | 内容 |
| --- | --- |
| `fig1_system_arch.svg` | 系统总体架构 |
| `fig2_frame_pipeline.svg` | 帧级并行与乒乓缓存 |
| `fig3_lens_math.svg` | 逆映射、Brown 畸变与仿射合并 |
| `fig4_ddr_layout.svg` | DDR3 地址划分与瓦片缓存 |
| `fig5_uart_protocol.svg` | UART 参数帧与事务顺序 |
| `fig6_clock_domains.svg` | 五个时钟域与跨域方式 |

> 将 `竞赛提交_20261104/01_技术报告/figures/` 下的 6 个 SVG 复制到本仓库 `docs/figures/` 即可正常显示。

## 指标

| 项目 | 数值 |
| --- | --- |
| 输入 | 1920×1080 RGB888，60 Hz，148.5 MHz 像素时钟 |
| 输出 | 1920×1080，30 Hz，74.25 MHz 像素时钟 |
| 新校正帧率 | 30 帧/秒（实板 30 s / 900 帧） |
| 处理时钟 | 92.8125 MHz |
| DDR | 外挂 DDR3，x32，UI 125 MHz |
| 畸变模型 | Brown k1/k2/p1/p2（k3 = 0） |
| 定点格式 | 仿射 Q24、畸变 Q26、内参 Q16、权重 UQ0.8 |
| 流水线 | 坐标 11 级，插值 3 级 |
| 资源 | LUT 59%，FF 45%，DRM 62%，APM 28% |
| 物理时序 | 最小裕量 +0.035 ns |
| 平台 | MES2L676-100HP / PG2L100H-6IFBG676 |

## 仓库结构

```
.
├─ rtl/                 # 顶层、采集、缓存、坐标、插值、显示、UART
├─ constr/              # 引脚与时序约束
├─ sim/                 # ModelSim testbench
├─ project/             # PDS 工程
├─ docs/                # 设计说明与图片
│  └─ figures/
└─ tools/               # 标定、回归、构建与审查脚本
```

核心源码：

| 文件 | 作用 |
| --- | --- |
| `video_correct_ddr_top.v` | 板级顶层 |
| `continuous_capture_rx.v` | 双 Bank 整帧采集 |
| `lens_affine_instance.v` | 目标→理想源坐标 + 镜头映射 + 重采样 |
| `lens_distort_coord.v` | Brown 畸变 11 级定点流水 |
| `ddr_quad_tile_cache.v` | 128 行四邻域瓦片缓存 |
| `ddr_word_engine_result_burst.v` | DDR 字/突发适配 |
| `ddr_result_writer_burst64.v` | 64 像素连续写回 |
| `lens_uart_control.v` | 参数帧解析、CRC16、停等事务 |
| `lens_parameter_mailbox.v` | 240 位跨时钟参数邮箱 |
| `video_timing_vtc.v` | 1080p30 扫描时序 |

## 构建

环境：

- PDS 2022.2-SP6.4，综合引擎 Pango ADS
- 器件 PG2L100H-6IFBG676
- 仿真 ModelSim SE-64 2020.4

步骤：

1. 用 PDS 打开 `project/` 下的工程；
2. 确认源码列表包含 `rtl/` 下全部 `.v` 与 DDR PHY 的 `.vp`，不加入 testbench；
3. 综合 → 布局布线 → 时序审查，确认 Setup/Hold/Recovery/Removal/Minimum Pulse Width 全部非负；
4. 生成 `.sbit` 与配套 `.smsk`，经 JTAG 下载并回读校验；
5. 相机 HDMI 接入 MS7200，输出接 MS7210 / 采集卡，上电后先显示彩条，首帧完成后切换真实画面。

> 不要用"综合成功"或"已生成码流"代替时序审查与实板验收。

## 验证

| 层级 | 内容 | 结果 |
| --- | --- | --- |
| 数值模型 | Python 定点/浮点参考 | 逐像素期望值 |
| RTL 仿真 | 五类 1080p 全视频回归 | 通过，最大帧间隔 33,333,300 ns |
| 综合网表 | 实际综合后镜头单元整数对照 | 4,075 组输入通过 |
| 实板 | 30 s 连续录像与逐帧统计 | 900 张新校正帧，0 拒绝 |

五类回归：0° 双线性、90° 双线性、逐帧 0°/90° 切换、原图旁路、12° 最近邻。

## 当前状态

- 固定镜头矫正 + 固定视口：已完成实板 30 fps 验收。
- 上位机角度/缩放：功能回归与数值对照通过；板级时序仍在收敛，尚未作为发布码流。
- 场景自适应透视（自动棋盘）：离线全链路 30 fps 通过，最终物理时序未完成。
- 真实光学指标（SFR/MTF50）、端到端延迟、长时间稳定性：待测。

## 许可

许可方式待定【待确认】。如使用第三方 IP 或参考例程，请在仓库中保留其原始许可与出处。
