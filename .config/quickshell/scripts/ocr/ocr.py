#!/usr/bin/env python3
"""
The text in an image, with RapidOCR and the PP-OCRv6 small or medium models, reported as it goes so the
region selector can draw it: one JSON object per line on stdout.

  {"boxes": [[x, y, width, height], ...]}   the text lines found, in image pixels, reading order
  {"read": [i, ...]}                        these of them (indices into boxes) have been read
  {"text": "..."}                           the result, one line per row of text

Usage: ocr.py small|medium IMAGE
       ocr.py --download    (only fetch both models; setup.sh runs this)
"""

import json
import os
import sys

from rapidocr import RapidOCR
from rapidocr.main import RapidOCRError
from rapidocr.utils.process_img import map_boxes_to_original
from rapidocr.utils.typings import LangDet, LangRec, ModelType, OCRVersion

MODELS = os.path.join(os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share"), "bidshell", "ocr", "models")
# RapidOCR's own recognition batch
BATCH = 6


def emit(**message):
    print(json.dumps(message), flush=True)


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


def load(model_type):
    return RapidOCR(params={
        "Global.model_root_dir": MODELS,
        "Global.log_level": "error",
        # Screen text is upright, so the orientation model only costs time
        "Global.use_cls": False,
        "Det.ocr_version": OCRVersion.PPOCRV6,
        "Det.model_type": model_type,
        "Rec.ocr_version": OCRVersion.PPOCRV6,
        "Rec.model_type": model_type,
        # One model reads all its 50 languages; the language only selects that model
        "Det.lang_type": LangDet.EN,
        "Rec.lang_type": LangRec.EN,
    })


def main():
    os.makedirs(MODELS, exist_ok=True)
    if sys.argv[1] == "--download":
        load(ModelType.SMALL)
        load(ModelType.MEDIUM)
        return
    engine = load(ModelType.SMALL if sys.argv[1] == "small" else ModelType.MEDIUM)

    # RapidOCR's own steps (pinned to 3.9.2 by setup.sh), so the lines found can be shown before
    # they are read: detection takes well under a second, reading most of the time
    original = engine.load_img(sys.argv[2])
    image, record = engine.preprocess_img(original)
    try:
        crops, found = engine.detect_and_crop(image, record)
    except RapidOCRError:
        emit(boxes=[])
        emit(text="")
        return
    height, width = original.shape[:2]
    boxes = map_boxes_to_original(found.boxes, record, height, width)
    emit(boxes=[[float(box[:, 0].min()), float(box[:, 1].min()), float(box[:, 0].max() - box[:, 0].min()), float(box[:, 1].max() - box[:, 1].min())] for box in boxes])

    # By width, as RapidOCR batches them itself: a batch is padded to its widest line, so lines
    # taken in reading order would make it several times slower
    order = sorted(range(len(crops)), key=lambda i: crops[i].shape[1] / crops[i].shape[0])
    texts, scores = [""] * len(crops), [0.0] * len(crops)
    for start in range(0, len(order), BATCH):
        batch = order[start:start + BATCH]
        result = engine.recognize_txt([crops[i] for i in batch])
        for i, text, score in zip(batch, result.txts, result.scores):
            texts[i], scores[i] = text, score
        emit(read=batch)

    kept = [(box, text) for box, text, score in zip(boxes, texts, scores) if text.strip() and score >= engine.cfg.Global.text_score]
    emit(text="\n".join(rows([box for box, _ in kept], [text for _, text in kept])))


main()
