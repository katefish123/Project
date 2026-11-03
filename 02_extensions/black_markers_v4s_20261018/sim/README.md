# V4S 行为仿真与参考数据

testbench 来源为固定 V4S 对应源码，保留数值路径和断言，fixture 路径迁移到本目录；处理时钟和毫秒分频对齐 V4S 的 57.115 MHz / 57115 周期配置，日志频率标签同步修正。生产源码清单见 project/source_manifest.json。

fixtures/reduced：128×48 源图、32×48 存储结果（有效29×48），用于快速压力回归。
fixtures/fullhd：1920×1080 源图、768×1080 存储结果（有效765×1080），用于原生尺寸回归。

每种尺寸三幅不同内容/角点，sourceN.hex 为RGB888，expectedN.hex 为包含对齐黑边的逐像素预期。PNG 为合成检查图，不能作为实际板测成功证据。metadata.json 给出角点、ROI、H及生成来源；其中历史路径仅用于来源记录。

reference/brect 为与本版对应的 B 黑标定点参考；oracle.py 在不读取HDL请求或输出的条件下向量化生成预期，再抽样调用原B标量参考核验。
