#!/usr/bin/env python3
"""
Teacher course: Cambridge IGCSE English as a Second Language (0510), 5-week online course.

Adds a new entry "0510SE" to the TRAININGS base registry (the teacher certification
courses). Week 1 is built from the 2024 to 2026 syllabus (Speaking Endorsement):
Introductions, syllabus overview, subject content and details of the assessment.
Weeks 2 to 5 are added later by extending patches/esl0510_content and re-running
build_course.ps1.

The older course "0510" (8 units, written for the earlier tiered syllabus) is left in
place; retire it by deleting its entry once the new course has all five weeks.
Run after the other patches. The data is built into patches/esl0510se_course.json.
"""
import json
import os
import sys

SRC = "assets/app.js"
HERE = os.path.dirname(os.path.abspath(__file__))

with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
    d = fh.read()

with open(os.path.join(HERE, "esl0510se_course.json"), encoding="utf-8") as fh:
    course = fh.read()
json.loads(course)

key = '"0510SE":{'
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
    assert end > 0, "end of 0510SE not found"
    d = d[:start] + course + d[end + 1:]
else:
    anchor = ',mm={"0510":{code:"0510",cat:"Cambridge"'
    assert d.count(anchor) == 1, f"anchor found {d.count(anchor)}x"
    d = d.replace(anchor, ',mm={"0510SE":' + course + ',"0510":{code:"0510",cat:"Cambridge"', 1)

with open(SRC, "w", encoding="utf-8", errors="surrogateescape") as fh:
    fh.write(d)
print(f"  teacher course 0510SE added ({len(course):,} chars)")
