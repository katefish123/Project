import re
import sys
from pathlib import Path

SRC = Path(sys.argv[1])
DST = Path(sys.argv[2])

text = SRC.read_text(encoding="utf-8")
lines = text.split("\n")


def esc(s: str) -> str:
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def inline(s: str) -> str:
    s = esc(s)
    s = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"`(.+?)`", r"<code>\1</code>", s)
    s = s.replace("【待确认】", '<span class="todo">【待确认】</span>')
    return s


out = []
i = 0
in_cover = True
first_break_done = False
out.append('<section class="cover">')

while i < len(lines):
    line = lines[i]
    stripped = line.strip()

    if stripped == "<!-- pagebreak -->":
        if in_cover:
            out.append("</section>")
            in_cover = False
            first_break_done = True
        out.append('<div class="pb"></div>')
        i += 1
        continue

    if not stripped:
        i += 1
        continue

    # fenced code
    if stripped.startswith("```"):
        i += 1
        buf = []
        while i < len(lines) and not lines[i].strip().startswith("```"):
            buf.append(lines[i])
            i += 1
        i += 1
        out.append("<pre><code>" + esc("\n".join(buf)) + "</code></pre>")
        continue

    # image
    m = re.match(r"!\[(.*?)\]\((.*?)\)", stripped)
    if m:
        out.append(
            '<figure><img src="%s" alt="%s"/><figcaption>%s</figcaption></figure>'
            % (m.group(2), esc(m.group(1)), inline(m.group(1)))
        )
        i += 1
        continue

    # headings
    if stripped.startswith("### "):
        out.append("<h3>" + inline(stripped[4:]) + "</h3>")
        i += 1
        continue
    if stripped.startswith("## "):
        out.append("<h2>" + inline(stripped[3:]) + "</h2>")
        i += 1
        continue
    if stripped.startswith("# "):
        out.append("<h1>" + inline(stripped[2:]) + "</h1>")
        i += 1
        continue

    # table
    if stripped.startswith("|") and i + 1 < len(lines) and re.match(r"^\|[\s:\-|]+\|$", lines[i + 1].strip()):
        header = [c.strip() for c in stripped.strip("|").split("|")]
        i += 2
        rows = []
        while i < len(lines) and lines[i].strip().startswith("|"):
            rows.append([c.strip() for c in lines[i].strip().strip("|").split("|")])
            i += 1
        html = ['<table><thead><tr>']
        html += ["<th>" + inline(c) + "</th>" for c in header]
        html.append("</tr></thead><tbody>")
        for r in rows:
            html.append("<tr>" + "".join("<td>" + inline(c) + "</td>" for c in r) + "</tr>")
        html.append("</tbody></table>")
        out.append("".join(html))
        continue

    # ordered list
    if re.match(r"^\d+\.\s", stripped):
        items = []
        while i < len(lines) and re.match(r"^\d+\.\s", lines[i].strip()):
            items.append("<li>" + inline(re.sub(r"^\d+\.\s+", "", lines[i].strip())) + "</li>")
            i += 1
        out.append("<ol>" + "".join(items) + "</ol>")
        continue

    # bullet list
    if stripped.startswith("- "):
        items = []
        while i < len(lines) and lines[i].strip().startswith("- "):
            items.append("<li>" + inline(lines[i].strip()[2:]) + "</li>")
            i += 1
        out.append("<ul>" + "".join(items) + "</ul>")
        continue

    # TOC appendix lines (no list marker, one per line)
    if stripped.startswith("附录 "):
        out.append('<p class="toc-line">' + inline(stripped) + "</p>")
        i += 1
        continue

    # paragraph (join consecutive non-special lines)
    para = [stripped]
    i += 1
    while i < len(lines):
        nxt = lines[i].strip()
        if (not nxt or nxt.startswith("#") or nxt.startswith("|") or nxt.startswith("- ")
                or nxt.startswith("```") or nxt.startswith("![") or nxt == "<!-- pagebreak -->"
                or re.match(r"^\d+\.\s", nxt)):
            break
        para.append(nxt)
        i += 1
    out.append("<p>" + inline(" ".join(para)) + "</p>")

if in_cover:
    out.append("</section>")

body = "\n".join(out)

HTML = """<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8"/>
<title>技术报告</title>
<style>
@page { size: A4; margin: 16mm 16mm 14mm 16mm; }
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; }
body {
  font-family: "Source Han Serif SC", "Noto Serif SC", "SimSun", serif;
  font-size: 10pt; line-height: 1.55; color: #1b2b3a;
}
h1, h2, h3, table, figcaption, .cover-meta { font-family: "Microsoft YaHei", "PingFang SC", sans-serif; }
h1 { font-size: 22pt; line-height: 1.3; color: #0b1f31; margin: 0 0 6mm 0; letter-spacing: .5px; }
h2 { font-size: 14pt; color: #0b1f31; margin: 6mm 0 2mm 0; padding-bottom: 1.4mm;
     border-bottom: 2px solid #0e8fa8; break-after: avoid; }
h3 { font-size: 11pt; color: #0e6f84; margin: 4mm 0 1.4mm 0; break-after: avoid; }
p { margin: 0 0 2.2mm 0; text-align: justify; orphans: 2; widows: 2; }
ul, ol { margin: 0 0 2.4mm 0; padding-left: 6mm; }
li { margin-bottom: .8mm; }
strong { color: #0b1f31; }
code { font-family: Consolas, "Cascadia Mono", monospace; font-size: 8.8pt;
       background: #eef4f7; padding: 0 .8mm; border-radius: 1mm; word-break: break-all; }
pre { background: #f4f8fa; border-left: 3px solid #0e8fa8; padding: 2.2mm 3mm;
      margin: 0 0 2.6mm 0; overflow: hidden; }
pre code { background: none; padding: 0; font-size: 8.8pt; line-height: 1.5; word-break: normal; }
table { width: 100%; border-collapse: collapse; margin: 1.4mm 0 3mm 0; font-size: 8.8pt;
        break-inside: auto; }
th { background: #eaf2f6; color: #0b1f31; font-weight: 600; text-align: left; }
th, td { border: 0.6pt solid #b9cbd7; padding: 1.1mm 1.8mm; vertical-align: top; }
tr { break-inside: avoid; }
tr:nth-child(even) td { background: #fbfdfe; }
figure { margin: 1.8mm 0 2.4mm 0; break-inside: avoid; text-align: center; }
figure img { width: 96%; height: auto; }
figcaption { font-size: 8.8pt; color: #5b7186; margin-top: 1.2mm; }
.todo { color: #b45309; font-weight: 600; }
.toc-line { margin: 0 0 .8mm 0; }
.pb { break-after: page; }

.cover { position: relative; min-height: 240mm; display: flex; flex-direction: column; justify-content: center; }
.cover h1 { font-size: 26pt; margin-bottom: 5mm; }
.cover p { font-size: 10.5pt; text-align: left; }
.cover strong { color: #0e6f84; }
.cover::after {
  content: "MES2L676-100HP　·　PG2L100H-6IFBG676　·　PDS 2022.2-SP6.4　·　ModelSim SE-64 2020.4";
  position: absolute; left: 0; right: 0; bottom: 0;
  padding-top: 4mm; border-top: .6pt solid #b9cbd7;
  font: 8.6pt "Microsoft YaHei", sans-serif; color: #5b7186; letter-spacing: .3mm;
}
</style>
</head>
<body>
__BODY__
</body>
</html>
"""

DST.write_text(HTML.replace("__BODY__", body), encoding="utf-8")
print("written", DST)
