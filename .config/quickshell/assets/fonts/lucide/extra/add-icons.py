# Adds the SVG icons in this folder to ../lucide.ttf, for icons Lucide does not have.
# The SVGs must be on Lucide's grid (24x24, stroke 2, round caps and joins), as Tabler's are.
# Rerun after replacing lucide.ttf with a new Lucide release; it overwrites the glyphs it added before.
# Needs fonttools and picosvg (pip install fonttools picosvg, in a virtualenv).
import os
import pathlib

from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.svgLib.path import SVGPath
from fontTools.ttLib import TTFont
from picosvg.svg import SVG

# Supplementary Private Use Area, clear of the BMP range Lucide assigns its own codepoints in
CODEPOINTS = {"hdr": 0xF0000}

here = pathlib.Path(__file__).parent
font_path = here.parent / "lucide.ttf"
font = TTFont(font_path)
units = font["head"].unitsPerEm
order = font.getGlyphOrder()

for name, codepoint in CODEPOINTS.items():
    # Lucide's font maps the 24-unit viewBox onto the em, y flipped, baseline at the bottom
    filled = SVG.parse(str(here / f"{name}.svg")).topicosvg()
    pen = TTGlyphPen(None)
    to_font = TransformPen(Cu2QuPen(pen, max_err=1, reverse_direction=True), (units / 24, 0, 0, -units / 24, 0, units))
    SVGPath.fromstring(filled.tostring(), transform=(1, 0, 0, 1, 0, 0)).draw(to_font)

    glyph_name = f"extra-{name}"
    font["glyf"][glyph_name] = pen.glyph()
    font["hmtx"][glyph_name] = (units, 0)
    if glyph_name not in order:
        order.append(glyph_name)
    for table in font["cmap"].tables:
        if table.format == 12 or (table.format in (4, 0) and codepoint <= 0xFFFF):
            table.cmap[codepoint] = glyph_name

font.setGlyphOrder(order)
# A running shell reads the font file mapped in memory: writing it in place crashes FreeType there,
# a new file moved over it leaves the old one intact for whoever still has it open
temp_path = font_path.with_suffix(".ttf.tmp")
font.save(temp_path)
os.replace(temp_path, font_path)
print(f"added {', '.join(CODEPOINTS)} to {font_path.name}")
