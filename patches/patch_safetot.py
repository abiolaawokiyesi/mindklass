#!/usr/bin/env python3
"""
Teacher course: Safeguarding Training of Trainers and Capacity Building (SAFETOT), 22 units over 6 weeks.

Adds or replaces the entry "SAFETOT" in the TRAININGS base registry (teacher courses). Data comes
from patches/safetot_course.json, built by safetot_content/build_course.ps1. Needs the section
figure support added by patch_esl0510_week1 / apply_esl0510_week1.ps1 (section.img), so run it
after that patch. Windows equivalent: apply_safetot.ps1.
"""
import json
import os
import sys

SRC = "assets/app.js"
HERE = os.path.dirname(os.path.abspath(__file__))

with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
    d = fh.read()
with open(os.path.join(HERE, "safetot_course.json"), encoding="utf-8") as fh:
    course = fh.read()
json.loads(course)

key = '"SAFETOT":{'
if key in d:
    start = d.index(key) + len(key) - 1
    depth, in_str, esc, end = 0, False, False, -1
    for k in range(start, len(d)):
        c = d[k]
        if in_str:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
        elif c == '"':
            in_str = True
        elif c in "{[":
            depth += 1
        elif c in "}]":
            depth -= 1
            if depth == 0:
                end = k
                break
    assert end > 0, "end of SAFETOT not found"
    d = d[:start] + course + d[end + 1:]
else:
    anchor = ",mm={"
    assert d.count(anchor) == 1, f"anchor found {d.count(anchor)}x"
    d = d.replace(anchor, ',mm={"SAFETOT":' + course + ",", 1)

if 'd.img&&t("figure"' not in d:
    sys.exit("FAIL: figure support missing; run the ESL 0510 patch first")

with open(SRC, "w", encoding="utf-8", errors="surrogateescape") as fh:
    fh.write(d)
print(f"  teacher course SAFETOT added ({len(course):,} chars)")
