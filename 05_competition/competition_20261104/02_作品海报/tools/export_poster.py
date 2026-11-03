"""Export the 4-page poster to PNG (3 themes x 4 pages) and PDF (3 themes).

Usage (Windows):
    python tools/export_poster.py

Requires Google Chrome at the default path. All paths are resolved relative to
this file, so the folder can be moved as a whole.
"""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
CHROME = Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe")
HTML = ROOT / "poster.html"
OUT = ROOT / "out"

THEMES = {
    "blueprint": "深空蓝图",
    "paper": "白底学术",
    "hybrid": "深顶白身",
}
PAGES = (1, 2, 3, 4)

if not CHROME.exists():
    sys.exit(f"Chrome not found: {CHROME}")
if not HTML.exists():
    sys.exit(f"poster.html not found: {HTML}")

base = HTML.as_uri()
profile = Path(r"C:\Windows\TEMP\chrome_poster_profile")
profile.mkdir(parents=True, exist_ok=True)

def run(args):
    r = subprocess.run(args, capture_output=True, text=True, encoding="utf-8", errors="ignore")
    if r.returncode != 0:
        print("Chrome failed:", " ".join(str(a) for a in args[:3]))
        print((r.stderr or r.stdout)[-800:])
    return r.returncode == 0

ok = 0
for theme, cn in THEMES.items():
    png_dir = OUT / "png" / theme
    png_dir.mkdir(parents=True, exist_ok=True)
    for page in PAGES:
        target = png_dir / f"page{page}.png"
        args = [
            str(CHROME), "--headless=new", "--disable-gpu", "--hide-scrollbars",
            "--force-device-scale-factor=2", "--window-size=1920,1080",
            "--virtual-time-budget=5000", f"--user-data-dir={profile}",
            f"--screenshot={target}",
            f"{base}?theme={theme}&page={page}",
        ]
        if run(args) and target.exists() and target.stat().st_size > 10000:
            ok += 1
            print(f"PNG  {cn:8s} page{page}  {target.stat().st_size/1024:.0f} KB")
        else:
            print(f"FAIL PNG {theme} page{page}")

    pdf = OUT / f"作品海报_{cn}.pdf"
    args = [
        str(CHROME), "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
        "--virtual-time-budget=6000", f"--user-data-dir={profile}",
        f"--print-to-pdf={pdf}",
        f"{base}?theme={theme}",
    ]
    if run(args) and pdf.exists() and pdf.stat().st_size > 10000:
        print(f"PDF  {cn}  {pdf.stat().st_size/1024/1024:.2f} MB")
    else:
        print(f"FAIL PDF {theme}")

print(f"\nDone: {ok}/{len(THEMES)*len(PAGES)} PNG pages.")
