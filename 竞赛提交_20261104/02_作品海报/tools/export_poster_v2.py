from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CHROME = Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe")
HTML = ROOT / "poster_v2.html"
OUT = ROOT / "out_v2"
PNG = OUT / "png"
PDF = OUT / "作品海报_v2_学术.pdf"


def chrome(*args):
    subprocess.run([str(CHROME), "--headless=new", "--disable-gpu", *args], check=True)


def main():
    PNG.mkdir(parents=True, exist_ok=True)
    url = HTML.as_uri()
    for i in range(1, 5):
        chrome(
            "--hide-scrollbars",
            "--force-device-scale-factor=2",
            "--window-size=1920,1080",
            "--virtual-time-budget=6000",
            f"--screenshot={PNG / f'page{i}.png'}",
            f"{url}?page={i}",
        )
    chrome(
        "--no-pdf-header-footer",
        "--virtual-time-budget=8000",
        f"--print-to-pdf={PDF}",
        url,
    )
    print(f"PNG: {PNG}\\page1..4.png")
    print(f"PDF: {PDF}")


if __name__ == "__main__":
    main()
