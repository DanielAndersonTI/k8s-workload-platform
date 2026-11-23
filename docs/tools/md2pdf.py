"""Gera docs/relatorio-final.pdf a partir de docs/relatorio-final.md.

Requer reportlab. Uso: python docs/tools/md2pdf.py
"""
import re
import sys
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.platypus import (Image, KeepTogether, Paragraph, SimpleDocTemplate,
                                Spacer, Table, TableStyle)
from reportlab.pdfgen import canvas as pdfcanvas

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

BASE = Path(__file__).resolve().parents[1]
SRC = BASE / "relatorio-final.md"
OUT = str(BASE / "relatorio-final.pdf")

styles = getSampleStyleSheet()
body = ParagraphStyle("body", parent=styles["BodyText"], fontName="Times-Roman",
                      fontSize=11, leading=16, alignment=TA_JUSTIFY, spaceAfter=8)
h1 = ParagraphStyle("h1", parent=styles["Heading1"], fontName="Times-Bold",
                    fontSize=15, leading=19, spaceBefore=14, spaceAfter=8)
h2 = ParagraphStyle("h2", parent=styles["Heading2"], fontName="Times-Bold",
                    fontSize=12.5, leading=16, spaceBefore=10, spaceAfter=6)
title = ParagraphStyle("title", parent=styles["Title"], fontName="Times-Bold",
                       fontSize=18, leading=22, spaceAfter=12)
cell = ParagraphStyle("cell", fontName="Times-Roman", fontSize=8.0, leading=10.2,
                      splitLongWords=1)
cellh = ParagraphStyle("cellh", fontName="Times-Bold", fontSize=8.0, leading=10.2,
                       splitLongWords=1)
ref = ParagraphStyle("ref", parent=body, fontSize=10, leading=14, spaceAfter=6,
                     alignment=TA_LEFT)
caption = ParagraphStyle("caption", parent=body, fontName="Times-Italic",
                         fontSize=9.5, leading=12, alignment=TA_CENTER,
                         spaceBefore=2, spaceAfter=10)
code = ParagraphStyle("code", parent=body, fontName="Courier", fontSize=8.2,
                      leading=11.0, alignment=TA_LEFT, spaceBefore=0,
                      spaceAfter=0)


def inline(t):
    t = t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    t = re.sub(r"`([^`]+)`", r'<font face="Courier">\1</font>', t)
    t = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", t)
    t = re.sub(r"\*([^*]+)\*", r"<i>\1</i>", t)
    return t


def _segments(s):
    """Divide a célula em tokens, dizendo a fonte de cada um."""
    parts = s.replace("**", "").replace("*", "").split("`")
    for idx, part in enumerate(parts):
        font = "Courier" if idx % 2 else "Times-Roman"
        for word in part.split():
            yield word, font


def _measure(cell, size):
    """Menor largura aceitável (maior token) e largura natural da célula."""
    minw = 0.0
    total = 0.0
    first = True
    for word, font in _segments(cell):
        w = pdfmetrics.stringWidth(word, font, size)
        minw = max(minw, w)
        if not first:
            total += pdfmetrics.stringWidth(" ", font, size)
        total += w
        first = False
    return minw, total


def _allocate(minw, natural, avail):
    """Reparte a largura disponível respeitando as quebras mínimas."""
    if sum(natural) <= avail:
        extra = (avail - sum(natural)) / len(natural)
        widths = [n + extra for n in natural]
    else:
        widths = [avail * n / sum(natural) for n in natural]
    widths = [max(w, m) for w, m in zip(widths, minw)]
    for _ in range(60):
        total = sum(widths)
        if abs(total - avail) < 0.01:
            break
        if total > avail:
            slack = [max(0.0, w - m) for w, m in zip(widths, minw)]
            s = sum(slack)
            if s < 0.01:
                break
            excess = total - avail
            widths = [w - excess * sl / s for w, sl in zip(widths, slack)]
            widths = [max(w, m) for w, m in zip(widths, minw)]
        else:
            grow = avail - total
            ds = sum(natural) or 1.0
            widths = [w + grow * n / ds for w, n in zip(widths, natural)]
    # última renormalização para fechar a largura exata da página
    scale = avail / sum(widths)
    return [w * scale for w in widths]


def make_table(rows):
    ncol = max(len(r) for r in rows)
    avail = A4[0] - 5 * cm
    pad = 8.0

    def measures(size):
        minw = [0.0] * ncol
        natural = [0.0] * ncol
        for r in rows:
            cells = r + [""] * (ncol - len(r))
            for j, c in enumerate(cells):
                lo, hi = _measure(c, size)
                minw[j] = max(minw[j], lo)
                natural[j] = max(natural[j], hi)
        # o cabeçalho nunca deve quebrar: a largura da coluna cobre o rótulo
        header_cell = rows[0] + [""] * (ncol - len(rows[0]))
        for j in range(ncol):
            label = header_cell[j].replace("**", "").replace("*", "")
            head_natural = pdfmetrics.stringWidth(label, "Times-Bold", size) + 4
            minw[j] = max(minw[j], head_natural)
        return [m + pad for m in minw], [h + pad for h in natural]

    size = 8.0
    while True:
        minw, natural = measures(size)
        if sum(minw) <= avail or size <= 6.4:
            break
        size -= 0.5

    widths = _allocate(minw, natural, avail)
    body_cell = cell if size == 8.0 else ParagraphStyle(
        "cell%.1f" % size, parent=cell, fontSize=size, leading=size * 1.27)
    head_cell = cellh if size == 8.0 else ParagraphStyle(
        "cellh%.1f" % size, parent=cellh, fontSize=size, leading=size * 1.27)
    data = []
    for i, r in enumerate(rows):
        r = r + [""] * (ncol - len(r))
        data.append([Paragraph(inline(c), head_cell if i == 0 else body_cell)
                     for c in r])
    t = Table(data, colWidths=widths, repeatRows=1)
    t.setStyle(TableStyle([
        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#888888")),
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#eeeeee")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 3),
        ("RIGHTPADDING", (0, 0), (-1, -1), 3),
        ("TOPPADDING", (0, 0), (-1, -1), 2),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
    ]))
    return t


class NumberedCanvas(pdfcanvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved = []

    def showPage(self):
        self._saved.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        total = len(self._saved)
        for state in self._saved:
            self.__dict__.update(state)
            self.setFont("Times-Roman", 9)
            self.setFillColor(colors.HexColor("#555555"))
            self.drawCentredString(A4[0] / 2, 1.2 * cm, f"{self._pageNumber} de {total}")
            super().showPage()
        super().save()


lines = open(SRC, encoding="utf-8").read().splitlines()
flow = []
in_refs = False
in_code = False
i = 0
while i < len(lines):
    ln = lines[i].rstrip()
    if ln.startswith("```"):
        in_code = not in_code
        i += 1
        continue
    if in_code:
        flow.append(Paragraph(inline(ln) or "&nbsp;", code))
        i += 1
        continue
    if not ln.strip():
        i += 1
        continue
    m = re.fullmatch(r"!\[[^\]]*\]\(([^)]+)\)", ln.strip())
    if m:
        path = BASE / m.group(1)
        img = Image(path)
        maxw = A4[0] - 5 * cm
        ratio = img.imageHeight / img.imageWidth
        img.drawWidth = maxw
        img.drawHeight = maxw * ratio
        flow.append(Spacer(1, 4))
        flow.append(img)
        i += 1
        continue
    if ln.startswith("|"):
        rows = []
        while i < len(lines) and lines[i].startswith("|"):
            parts = [c.strip() for c in lines[i].strip().strip("|").split("|")]
            if not all(re.fullmatch(r":?-{2,}:?", c) for c in parts):
                rows.append(parts)
            i += 1
        table = make_table(rows)
        if len(rows) <= 8:
            flow.append(KeepTogether([Spacer(1, 4), table, Spacer(1, 8)]))
        else:
            flow.append(Spacer(1, 4))
            flow.append(table)
            flow.append(Spacer(1, 8))
        continue
    if ln.startswith("# "):
        flow.append(Paragraph(inline(ln[2:]), title))
    elif ln.startswith("## "):
        in_refs = ln[3:].strip().lower().startswith("refer")
        flow.append(Paragraph(inline(ln[3:]), h1))
    elif ln.startswith("### "):
        flow.append(Paragraph(inline(ln[4:]), h2))
    else:
        if re.fullmatch(r"\*Figura \d+.*\*", ln.strip()):
            flow.append(Paragraph(inline(ln.strip()), caption))
            i += 1
            continue
        buf = [ln]
        i += 1
        while i < len(lines) and lines[i].strip() and not lines[i].startswith(("#", "|", "![", "```")):
            buf.append(lines[i].rstrip())
            i += 1
        text = " ".join(x.strip() for x in buf)
        flow.append(Paragraph(inline(text), ref if in_refs else body))
        continue
    i += 1

doc = SimpleDocTemplate(OUT, pagesize=A4, leftMargin=2.5 * cm, rightMargin=2.5 * cm,
                        topMargin=2.2 * cm, bottomMargin=2.2 * cm,
                        title="Relatório de implantação: plataforma Kubernetes",
                        author="Daniel Anderson de Souza Silva")
doc.build(flow, canvasmaker=NumberedCanvas)
print(OUT)
