# 作品海报使用说明

面向队友与后续 AI。改文字、换图不需要构建工具；预览和导出只用本机 Chrome。

## 1. 这是什么

`poster.html` 是 4 页 16:9 的单文件海报，每页固定 1920×1080，HTML/CSS 加一小段原生 JS，图片全部相对路径引用，无外部依赖。默认主题 `hybrid`（深色页眉 + 浅色正文），可切 `blueprint`（全深色）和 `paper`（全浅色，隐藏装饰图）。

| 页 | 标题 | 这一页讲什么 |
| --- | --- | --- |
| P1 | 架构设计与性能 | Logos-2 系统框图；五时钟域、双 Bank、128×2 瓦片、240 位参数快照；0°/12°/45°/90° RTL 仿真缩略图与关键指标 |
| P2 | 作品亮点 | 18 mm 标定参数生成的畸变网格示意；单次重采样、分块缓存、帧同步锁参等五个设计选择；上位机界面复刻；UART 参数链 |
| P3 | 算法细节 | 逆仿射 + Brown 畸变；一次 2×2 采样；signed40/Q24 等定点格式；11 级坐标流水线 |
| P4 | 验证与效果 | 900 帧/30 s、+0.035 ns、资源与 1.449 px；四层证据链；实拍 A/B；开发板实物照占位；延迟/SFR/30 min 待实测 |

## 2. 三个文件入口

| 入口 | 作用 | 怎么用 |
| --- | --- | --- |
| `poster.html` | 唯一排版源：文字、样式、三套主题、单页导出逻辑都在这里 | 直接编辑，Chrome 打开预览 |
| `content.md` | 四页文案定稿与数据来源 | 先在这里定文字和数字，再同步到 HTML；HTML 不会自动读取它 |
| `assets/` | 图片资源：`figures/` 矢量图、`shots/` 位图、`gen/` AI 装饰图 | 见第 4 节；`shots` 优先同名替换 |

## 3. 改文字

1. 在 `poster.html` 搜索 `<section class="page" id="p1">` 到 `id="p4"`，每页一个 section。主标题是 `<h1>`，副标题 `.sub`，小节标题 `.sec`，正文在各卡片内。
2. 文案依据是 `content.md`；数字、限定词、图注必须两边一致。改数字前先核对 `../README.md` 的口径表和原始证据。
3. 保留 `.page` 的 1920×1080、主要网格布局和底部 `<script>`；脚本只处理 `?theme` 与 `?page`，删改会导致导出异常。
4. 图注里的“RTL 仿真”“界面示意”“非实拍”“待实测”是事实边界，不能删，也不能改成更强的表述。
5. 存 UTF-8；不要引入外网字体、CDN 或额外 JS。

## 4. 换图

### 4.1 同名替换（推荐）

`poster.html` 只认下表中的相对路径。换图时保持文件名、扩展名、大小写不变，覆盖前先备份；不要只改 HTML 不改图，或反之。

| 文件 | 当前尺寸 | 用在哪 | 替换要求 |
| --- | --- | --- | --- |
| `assets/shots/ab_raw.png`、`ab_corrected.png` | 1540×866 | P4 左 A/B 两联 | 同机位、同场景、同曝光，16:9；≥1540×866，建议 1920×1080；两张不得互换或单独改变裁切 |
| `assets/shots/angle_0.png` 等 4 张 | 640×360 | P1 四张缩略图 | 16:9；四张同视场，只改角度；≥640×360 |
| `assets/gen/*.png` | 1672×941 | 深色主题背景（P1–P4） | 16:9 横图，≥1920×1080（母版可用 3840×2160）；只做背景，见第 8 节 |
| `assets/figures/*.svg` | 矢量 | P1/P2/P3/P4 图卡 | 保持原文件名与 `viewBox`、白底；图内文字直接改 `<text>`，不要栅格化后放大 |

P1 缩略图按 180×101 裁切，P4 A/B 按容器 `object-fit: cover` 裁切；换图后必须导出检查主体是否被裁掉。照片不得拉伸变形。

P4 A/B 与 P1 缩略图在 CSS 中做了显示级降饱和（`saturate(.65)` / `saturate(.8)`），用于压掉室内灯下纸面的暖色偏；**原图文件未改**。要恢复原色，删除 `.shot img` 或 `.thumb img` 的 `filter` 即可。

### 4.2 两类自动生成的图

- `assets/figures/fig_grid_distortion.svg`：由 `tools/make_grid_figure.py` 读取 `A_lens_20261030/calibration/r50_18mm_hdmi_trial.json` 生成，位移放大 ×6。标定更新后重跑脚本，不要手改 SVG 里的曲线或系数。
- `assets/shots/*.png`：由 `tools/crop_shots.py` 从实板/验证目录裁切，需要 Pillow。源路径写死在脚本顶部，证据目录移动后先改常量。

## 5. 主题与导出

### 5.1 主题

| 值 | 效果 |
| --- | --- |
| `blueprint` | 深色底；各页 `--head-img` 以低透明度整页氛围图显示 |
| `paper` | 浅色底；不显示装饰图 |
| `hybrid` | 深色页眉 + 浅色正文，默认；装饰图不显示 |

预览（cmd）：

```bat
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" "file:///C:/D/FPGA/竞赛提交_20261104/02_作品海报/poster.html?theme=paper"
```

不要传未知主题值；只认 `blueprint`、`paper`、`hybrid`。

### 5.2 导出单页 PNG

先建输出目录：

```bat
if not exist "C:\D\FPGA\竞赛提交_20261104\02_作品海报\out\png\hybrid" mkdir "C:\D\FPGA\竞赛提交_20261104\02_作品海报\out\png\hybrid"
```

导出第 1 页：

```bat
"C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 --window-size=1920,1080 --virtual-time-budget=4000 --screenshot="C:\D\FPGA\竞赛提交_20261104\02_作品海报\out\png\hybrid\page1.png" "file:///C:/D/FPGA/竞赛提交_20261104/02_作品海报/poster.html?theme=hybrid&page=1"
```

- `page=1..4` 必填；脚本会删掉其余页并把 body 边距归零，截图才是纯 1920×1080。
- `--force-device-scale-factor=2` 输出 3840×2160；要 1× 就改成 1。
- 图片未加载完时，把 `--virtual-time-budget` 加到 8000。

一次导出某主题的 4 页（PowerShell）：

```powershell
$root = "C:\D\FPGA\竞赛提交_20261104\02_作品海报"
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$theme = "hybrid"
New-Item -ItemType Directory -Force "$root\out\png\$theme" | Out-Null
1..4 | ForEach-Object {
  & $chrome --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 "--window-size=1920,1080" --virtual-time-budget=4000 "--screenshot=$root\out\png\$theme\page$_.png" "file:///C:/D/FPGA/竞赛提交_20261104/02_作品海报/poster.html?theme=$theme&page=$_"
}
```

把 `$theme` 换成 `blueprint` 或 `paper` 可导另外两套，共 12 张。

### 5.3 一键导出全部 PNG 与 PDF（推荐）

双击 `tools\export_poster.bat`，或运行：

```bat
python tools\export_poster.py
```

会生成 3 套主题 × 4 页 PNG（3840×2160）和 3 份 4 页 PDF：

- `out/png/blueprint/page1..4.png`、`out/作品海报_深空蓝图.pdf`
- `out/png/paper/page1..4.png`、`out/作品海报_白底学术.pdf`
- `out/png/hybrid/page1..4.png`、`out/作品海报_深顶白身.pdf`

手动导出单份 PDF：

```bat
"C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu --no-pdf-header-footer --virtual-time-budget=4000 --print-to-pdf="C:\D\FPGA\竞赛提交_20261104\02_作品海报\out\作品海报_深顶白身.pdf" "file:///C:/D/FPGA/%E7%AB%9E%E8%B5%9B%E6%8F%90%E4%BA%A4_20261104/02_%E4%BD%9C%E5%93%81%E6%B5%B7%E6%8A%A5/poster.html?theme=hybrid"
```

- 不要带 `page` 参数；CSS 的 `@page` 已是 1920×1080、无边距，默认输出 4 页。
- 若 PDF 多出空白页，检查 URL 是否误带 `page` 参数、是否改过 `@page`。

## 6. `data-slot="board-photo"` 实物照替换

位置在 P4 右下，当前是 756×112 的虚线占位，`poster.html` 中搜索 `data-slot="board-photo"`。

拍摄要求：

- 只拍横构图。推荐直接拍 3:1 左右的宽幅：开发板、相机/镜头、显示器排成一条水平线。
- 同框内容：板卡（丝印和接口可见）+ 相机与镜头 + 显示器（显示矫正后画面）。相机略高于桌面 30°–45°，避免屏幕反光和摩尔纹。
- 主体放中间，左右各留 5%–10% 空白；不要人物、学校标识、杂物、带 HUD 的调试画面。
- 最低分辨率：原图长边 ≥2400（建议 2400×1350 以上）；按 112 px 槽高裁成 ≥2100×340（3× 输出）；若把槽高改为 220 px，则裁成 ≥2100×660。

存为 `assets/shots/board_photo.jpg`（sRGB，质量 ≥90，无水印），然后把整段占位替换为：

```html
<div class="slot" data-slot="board-photo" style="padding:0;border-style:solid;overflow:hidden;flex:0 0 220px">
  <img src="assets/shots/board_photo.jpg" alt="开发板、相机与显示器实拍"
       style="width:100%;height:100%;object-fit:cover;object-position:50% 50%;display:block"/>
</div>
```

`flex:0 0 220px` 是推荐加高版；不想改布局就删掉这一项，按 112 px 裁 6.25:1 长条。替换后导出 P4，检查是否压到“待实测/应用”两行；若溢出，把 220 降到 180。

## 7. 事实口径（写文案前必读）

下表只适用于 2026-10-29 固定镜头版；角度控制版是另一版本，不能混写。

| 项目 | 只能这样写 | 禁止 |
| --- | --- | --- |
| 实板帧率 | 30 s 输出 900 帧新校正帧，平均 30 帧/秒（2026-10-29 固定镜头版） | “60 帧矫正”、把 900 当 fps、说角度版也达到 |
| 时序裕量 | 最小裕量（minimum slack）+0.035 ns，仅限 2026-10-29 固定镜头版 | 外推到角度控制版或其他版本 |
| 角度控制版 | 离线回归通过、物理实现收敛中 | “已上板”“板级验收通过”“任意角度透视已上板” |
| 标定 | 18 mm 试标定；验证集重投影 RMS 1.449 px | 最终标定、MTF50 达标、任意镜头通用 |
| 端到端延迟 | 设计目标 ≤ 1 帧，未实测 | 具体 ms 数、“实测 1 帧” |
| 真实 SFR / MTF50 | 未实测；仅工具合成自测误差 ≤0.5% | 把合成自测当镜头实测、写具体 MTF50 数值 |
| 30 min 稳定性 | 未实测 | “已连续运行 30 min 无异常” |
| 身份信息 | 赛事名称可保留，其余身份信息一律不写 | 学校、学院、指导教师、校徽、任何单位标识 |

图注同样受约束：P1 四角度是 RTL 仿真；P2 面板是按 `lens_control_panel.py` 控件复刻的 HTML 示意；P4 A/B 是实板输出，但只覆盖固定镜头 + 固定视口裁剪，透视未校正。不要把“示意/仿真/待实测”改成“实拍/实测/已通过”。

## 8. AI 素材使用边界

`assets/gen/` 三张只作背景装饰，不能进证据位，不能当实物照、结果图或界面截图。当前仅在 `blueprint` 主题以整页低透明度氛围图显示；`hybrid` 页眉为纯色，`paper` 不显示。

| 文件 | 当前用途 | 约束 |
| --- | --- | --- |
| `blueprint_rays.png` | P2 深色背景（`#p2`） | 抽象光路，不是实测光路；构图靠右，左侧留给标题 |
| `lens_macro.png` | P3 深色背景（`#p3`） | 不是 18 mm 镜头实物；不得配“实拍镜头” |
| `chip_macro.png` | P1/P4 深色背景（`#p1`、`#p4`） | 图中是 QFP 类鸥翼脚，实板是 FBG676 BGA；绝不可标注为 PG2L100H 或开发板实拍 |

- 新增或替换时必须保留现有的压暗与径向/渐变遮罩，文字区留白；不能遮挡标题、正文、指标。
- 不得用 AI 生成棋盘格、矫正前后对比、SFR 曲线、延迟截图、上位机界面或任何“数据”。
- `paper` 主题隐藏装饰图是刻意设计；不要为了装饰图牺牲浅色主题的文字对比度。

## 9. 文件清单

| 路径 | 用途 |
| --- | --- |
| `poster.html` | 4 页海报源文件：布局、文字、主题、导出脚本 |
| `content.md` | 四页文案定稿与数据来源 |
| `README.md` | 本说明 |
| `缺图与生图提示词.md` | 待补素材清单、AI 素材用法、生图提示词 |
| `assets/figures/fig1_system_arch.svg` | P1 系统总体架构 |
| `assets/figures/fig2_frame_pipeline.svg` | P4 帧级并行流水 |
| `assets/figures/fig3_lens_math.svg` | P3 逆映射与一次重采样 |
| `assets/figures/fig4_ddr_layout.svg` | 备用：DDR 布局（当前海报未引用） |
| `assets/figures/fig5_uart_protocol.svg` | 备用：UART 协议（当前海报未引用） |
| `assets/figures/fig6_clock_domains.svg` | 备用：时钟域（当前海报未引用） |
| `assets/figures/fig_grid_distortion.svg` | P2 畸变网格示意（脚本生成，位移 ×6） |
| `assets/shots/ab_raw.png` | P4 原始输入 |
| `assets/shots/ab_corrected.png` | P4 实板矫正输出 |
| `assets/shots/angle_0.png` 等 4 张 | P1 RTL 仿真四角度缩略图（640×360） |
| `assets/gen/blueprint_rays.png` | P2 深色背景装饰 |
| `assets/gen/lens_macro.png` | P3 深色背景装饰 |
| `assets/gen/chip_macro.png` | P1/P4 深色背景装饰 |
| `tools/crop_shots.py` | 从证据图裁切 `assets/shots`（需 Pillow） |
| `tools/make_grid_figure.py` | 用 18 mm 标定 JSON 重新生成网格 SVG |
| `tools/export_poster.py` | 一键导出 3 主题 × 4 页 PNG 与 3 份 PDF |
| `tools/export_poster.bat` | 双击运行上面的 Python 脚本 |
| `out/` | 导出目录：`png/<theme>/page1..4.png`、`作品海报_*.pdf` |
