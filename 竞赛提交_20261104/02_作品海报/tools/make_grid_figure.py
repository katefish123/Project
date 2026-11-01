"""Generate a two-panel lens-distortion grid figure from the real calibration.

Input : A_lens_20261030/calibration/r50_18mm_hdmi_trial.json
Output: assets/figures/fig_grid_distortion.svg

The displacement is amplified (default x6) so the curvature is visible at
poster scale. The caption inside the SVG states this explicitly.
"""
from pathlib import Path
import json

ROOT = Path(r"C:\D\FPGA\竞赛提交_20261104\02_作品海报")
CAL = Path(r"C:\D\FPGA\A_lens_20261030\calibration\r50_18mm_hdmi_trial.json")
OUT = ROOT / "assets" / "figures" / "fig_grid_distortion.svg"

AMP = 6.0
W, H = 1400, 650
PANEL_W, PANEL_H = 660, 540
PANELS = [(10, 30), (730, 30)]
CX, CY = PANEL_W / 2, PANEL_H / 2
SCALE = 500.0
NAVY = "#0f2740"
TEAL = "#0e8fa8"
LINE = "#dbe6ee"

data = json.loads(CAL.read_text(encoding="utf-8"))


def find_intrinsics(node):
    if isinstance(node, dict):
        if all(k in node for k in ("fx", "fy", "cx", "cy", "k1", "k2", "p1", "p2")):
            return node
        for value in node.values():
            found = find_intrinsics(value)
            if found:
                return found
    elif isinstance(node, list):
        for value in node:
            found = find_intrinsics(value)
            if found:
                return found
    return None


cal = find_intrinsics(data)
if not cal:
    raise SystemExit("calibration intrinsics not found")
fx = cal["fx"]; fy = cal["fy"]; cx = cal["cx"]; cy = cal["cy"]
k1 = cal["k1"]; k2 = cal["k2"]; p1 = cal["p1"]; p2 = cal["p2"]


def distort(X, Y):
    r2 = X * X + Y * Y
    rad = 1.0 + k1 * r2 + k2 * r2 * r2
    Xd = X * rad + 2.0 * p1 * X * Y + p2 * (r2 + 2.0 * X * X)
    Yd = Y * rad + p1 * (r2 + 2.0 * Y * Y) + 2.0 * p2 * X * Y
    return Xd, Yd


def frac(v):
    return f"{v:.2f}".rstrip("0").rstrip(".")


def panel_svg(ox, oy, observed):
    out = []
    clip_id = f"clip{'A' if observed else 'B'}"
    out.append(f'<clipPath id="{clip_id}"><rect x="{ox}" y="{oy}" width="{PANEL_W}" height="{PANEL_H}" rx="10"/></clipPath>')
    out.append(f'<rect x="{ox}" y="{oy}" width="{PANEL_W}" height="{PANEL_H}" rx="10" fill="#ffffff" stroke="{LINE}"/>')

    xs = [(-0.64 + i * 0.04) for i in range(33)]
    ys = [(-0.48 + i * 0.04) for i in range(25)]
    samples = 48

    def pt(X, Y):
        if observed:
            Xd, Yd = distort(X, Y)
            X = X + AMP * (Xd - X)
            Y = Y + AMP * (Yd - Y)
        return ox + CX + X * SCALE, oy + CY - Y * SCALE

    out.append(f'<g clip-path="url(#{clip_id})">')
    for x in xs:
        pts = []
        for i in range(samples + 1):
            y = -0.48 + 0.96 * i / samples
            px, py = pt(x, y)
            pts.append(f"{px:.1f},{py:.1f}")
        strong = abs((x * 100) % 16) < 0.01
        width = 1.15 if strong else 0.7
        op = 0.62 if strong else 0.34
        out.append(f'<polyline points="{" ".join(pts)}" fill="none" stroke="{NAVY}" stroke-width="{width}" opacity="{op}"/>')
    for y in ys:
        pts = []
        for i in range(samples + 1):
            x = -0.64 + 1.28 * i / samples
            px, py = pt(x, y)
            pts.append(f"{px:.1f},{py:.1f}")
        strong = abs((y * 100) % 16) < 0.01
        width = 1.15 if strong else 0.7
        op = 0.62 if strong else 0.34
        out.append(f'<polyline points="{" ".join(pts)}" fill="none" stroke="{NAVY}" stroke-width="{width}" opacity="{op}"/>')

    # optical centre
    cxp, cyp = pt(0.0, 0.0)
    out.append(f'<circle cx="{cxp:.1f}" cy="{cyp:.1f}" r="4.2" fill="{TEAL}"/>')
    out.append(f'<circle cx="{cxp:.1f}" cy="{cyp:.1f}" r="9" fill="none" stroke="{TEAL}" stroke-width="1.2" opacity="0.55"/>')
    out.append("</g>")

    # corner ticks
    out.append(f'<path d="M{ox+14},{oy+28} V{oy+14} H{ox+28}" fill="none" stroke="{TEAL}" stroke-width="2"/>')
    out.append(f'<path d="M{ox+PANEL_W-28},{oy+14} H{ox+PANEL_W-14} V{oy+28}" fill="none" stroke="{TEAL}" stroke-width="2"/>')
    return "\n".join(out)


svg = []
svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" font-family="Microsoft YaHei, Noto Sans SC, sans-serif">')
svg.append(f'<rect width="{W}" height="{H}" fill="#ffffff"/>')
svg.append(panel_svg(*PANELS[0], observed=True))
svg.append(panel_svg(*PANELS[1], observed=False))

# labels
svg.append(f'<text x="10" y="602" fill="{NAVY}" font-size="24" font-weight="700">原始观测网格</text>')
svg.append(f'<text x="10" y="632" fill="#5b7186" font-size="17">按实测 k1/k2/p1/p2 计算 · 位移放大 ×{AMP:g} 便于观察</text>')
svg.append(f'<text x="730" y="602" fill="{NAVY}" font-size="24" font-weight="700">去畸变后的理想网格</text>')
svg.append(f'<text x="730" y="632" fill="#5b7186" font-size="17">同一条逆映射链路的输出目标 · 直线保持平直</text>')

# coefficient strip
svg.append(f'<text x="10" y="18" fill="{TEAL}" font-size="15" letter-spacing="1">SCHEMATIC · NOT A CAPTURE</text>')
svg.append(f'<text x="1390" y="18" fill="#7d94a6" font-size="14" text-anchor="end">k1 {k1:.6f}　k2 {k2:.6f}　p1 {p1:.6f}　p2 {p2:.6f}</text>')
svg.append("</svg>")

OUT.write_text("\n".join(svg), encoding="utf-8")
print(f"wrote {OUT} ({OUT.stat().st_size/1024:.1f} KB)")
