# 备份与历史目录

完整修改前工程位于本目录上两级的`member_b_perspective_original_2026-10-11.zip`，包含原工程全部245个文件（10,427,777字节）。同级`source_backup_manifest.json`提供逐文件大小和SHA256及归档校验记录。原工程目录未修改。需要恢复完整工程时，应使用该ZIP解压到新目录。

本目录的两个子目录是历史或生成产物归档：

| 子目录 | 范围 |
| --- | --- |
| `2026-10-06_before_interface_v1_supplements/` | 原工程已有的局部备份：v1接口补充前README、部分文档/脚本、ModelSim入口、旧结果及安装清单；保持原内容 |
| `2026-10-11_before_black_detection/` | 本次从工作副本隔离的旧`results/`、ModelSim `work/`与`modelsim.ini`，保留四色版证据与编译数据库 |

历史目录中的README、颜色描述、通过次数和日志只属于当时版本；不能作为当前黑色检测版本的说明或结果。当前入口为根README、`docs/file_guide.md`和新`results/verification.json`。ModelSim`work/`可以从源码重建，其数据库不是源码也不是FPGA位流。
