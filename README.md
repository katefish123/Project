# FPGA 视频处理工程

所有当前资料已集中到 **main**，按用途及阶段归档。2026-11-02 新增的两份交付分别保留为最终完整工程和黑色角标拓展功能，工程内部文件名、源码、约束、码流和相对目录均保留。

## 从这里开始

| 用途 | 入口 |
| --- | --- |
| 最终完整工程（1080p30） | [说明](01_final/FPGA_1080p30_20261102/README_先读我.md) · [PDS 工程](01_final/FPGA_1080p30_20261102/native_project/FPGA_Nov01.pds) |
| 最终工程烧录文件 | [sbit](01_final/FPGA_1080p30_20261102/firmware/video_correct_ddr_top.sbit) · [读回掩码 smsk](01_final/FPGA_1080p30_20261102/firmware/video_correct_ddr_top.smsk) |
| 黑色角标拓展 V4S | [教师审核说明](02_extensions/black_markers_v4s_20261018/README.md) · [PDS 工程](02_extensions/black_markers_v4s_20261018/project/V4S_Review.pds) |
| 历史集成工程、交接、增量与进度 | [历史目录](03_history/) |
| A/B/C 团队资料及 C 实验快照 | [团队目录](04_team/) |
| 时间线及原路径对照 | [时间线](05_docs/TIMELINE.md) · [整理规则](05_docs/ORGANIZATION.md) · [分支清单](05_docs/BRANCHES.md) |
| 用户原始完整工程压缩包 | [原 ZIP](06_archives/FPGA_1080p30_完整工程_含烧录文件_20261102.zip) |

## 获取完整文件

仓库含 Git LFS 大文件。请使用安装了 Git LFS 的 Git 客户端克隆，并执行：

```sh
git clone https://github.com/katefish123/Project.git
cd Project
git lfs pull
```

GitHub 网页显示的少数 LFS 文件可能只是指针；下载后应按包内 SHA256 清单校验。打开最终 PDS 工程时，保留整个 `FPGA_1080p30_20261102` 目录结构。旧目录中的“当前版本”“下一步”等说明属于当时记录，当前入口以本页为准。

本次只整理与校验文件，未重新编译 FPGA、运行包内脚本、烧录板卡或重新验证功能。
