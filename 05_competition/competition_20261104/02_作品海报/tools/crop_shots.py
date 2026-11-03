"""Crop HUD-free poster shots from existing evidence images.

Read-only with respect to the source tree: writes only into
02_作品海报/assets/shots/. Uses Pillow (available in the bundled runtime).
"""
from pathlib import Path
from PIL import Image

ROOT = Path(r"C:\D\FPGA\竞赛提交_20261104\02_作品海报")
OUT = ROOT / "assets" / "shots"
OUT.mkdir(parents=True, exist_ok=True)

BOARD = Path(r"C:\D\FPGA\A_board_20261029\hardware_acceptance_20261029_225412")
VER = Path(r"C:\D\FPGA\A_lens_20261030\verification")

# The evidence frames carry a 375 px diagnostic HUD on the left.
# Crop the clean 16:9 window to the right of it.
CROP_16_9 = (380, 107, 1920, 973)  # 1540 x 866

SOURCES = {
    "ab_raw.png": BOARD / "frame_43s.png",
    "ab_corrected.png": BOARD / "frame_41s.png",
}

ANGLE_SOURCES = {
    "angle_0.png": VER / "video_20261030_143420_180676_4433aad4" / "primary" / "expected.png",
    "angle_12.png": VER / "video_20261030_135942_519642_30d8ed4b" / "primary" / "expected.png",
    "angle_45.png": VER / "video_20261030_131339_279281" / "expected.png",
    "angle_90.png": VER / "video_20261030_125726_048129" / "expected.png",
}


def save_crop(src: Path, dst: Path, box=None, size=None):
    if not src.exists():
        print(f"MISSING {src}")
        return
    im = Image.open(src).convert("RGB")
    if box:
        im = im.crop(box)
    if size:
        im = im.resize(size, Image.LANCZOS)
    im.save(dst, optimize=True)
    print(f"{dst.name:24s} {im.width}x{im.height}  {dst.stat().st_size/1024:.0f} KB")


for name, src in SOURCES.items():
    save_crop(src, OUT / name, CROP_16_9)

for name, src in ANGLE_SOURCES.items():
    save_crop(src, OUT / name, None, (640, 360))
