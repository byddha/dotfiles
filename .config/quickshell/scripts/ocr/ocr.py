#!/usr/bin/env python3
"""
The text in an image, one line per row of text, with RapidOCR and the PP-OCRv6 medium models.

Usage: ocr.py IMAGE
       ocr.py --download    (only fetch the models; setup.sh runs this)
"""

import os
import sys

from rapidocr import RapidOCR
from rapidocr.utils.typings import LangDet, LangRec, ModelType, OCRVersion

MODELS = os.path.join(os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share"), "bidshell", "ocr", "models")


def rows(boxes, texts):
    """Joins the boxes that sit on one row, left to right: the models find a line number and
    the code next to it, or table cells, as separate boxes"""
    items = []
    for box, text in zip(boxes, texts):
        ys = [point[1] for point in box]
        items.append((min(point[0] for point in box), (min(ys) + max(ys)) / 2, max(ys) - min(ys), text))
    items.sort(key=lambda item: item[1])
    lines = []
    for x, middle, height, text in items:
        if lines and abs(middle - lines[-1]["middle"]) < lines[-1]["height"] / 2:
            lines[-1]["items"].append((x, text))
        else:
            lines.append({"middle": middle, "height": height, "items": [(x, text)]})
    return [" ".join(text for _, text in sorted(line["items"])) for line in lines]


def main():
    os.makedirs(MODELS, exist_ok=True)
    engine = RapidOCR(params={
        "Global.model_root_dir": MODELS,
        "Global.log_level": "error",
        # Screen text is upright, so the orientation model only costs time
        "Global.use_cls": False,
        "Det.ocr_version": OCRVersion.PPOCRV6,
        "Det.model_type": ModelType.MEDIUM,
        "Rec.ocr_version": OCRVersion.PPOCRV6,
        "Rec.model_type": ModelType.MEDIUM,
        # One model reads all its 50 languages; the language only selects that model
        "Det.lang_type": LangDet.EN,
        "Rec.lang_type": LangRec.EN,
    })
    if sys.argv[1] == "--download":
        return
    result = engine(sys.argv[1])
    if result.txts:
        print("\n".join(rows(result.boxes, result.txts)))


main()
