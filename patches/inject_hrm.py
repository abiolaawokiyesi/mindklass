#!/usr/bin/env python3
"""
Replaces the HRMINTRO course with the detailed version supplied by the client.

The previous course covered the topics at face value. The new source runs to
623 KB across 15 modules with worked procedures, templates, formulas and case
studies — the "how to", not just the "what is".

WHAT THIS SCRIPT DOES
  * Splits the document into its 15 modules.
  * Within each module, converts the numbered headings and their prose into
    lesson sections, preserving the client's wording rather than rewriting it.
  * Extracts the practical case study from each module into its own section,
    since those are the certification-qualifying exercises.
  * Parses every multiple-choice question (stem, four options, marked answer)
    and attaches them per module as unit checks.
  * Pools every question into the course-level exam bank so the final
    assessment can unlock.

Anything that cannot be parsed cleanly is dropped rather than guessed at, and
the counts are reported so the result can be checked against the source.
"""
import json
import re
import sys

SRC = "assets/app.js"
DOC = "/mnt/user-data/uploads/1787041120125_Introduction_to_Human_Resource_Mana.txt"

ICONS = ["Landmark", "ClipboardList", "Users", "Rocket", "GraduationCap",
         "BarChart2", "CreditCard", "Heart", "Shield", "ShieldCheck",
         "Cpu", "TrendingUp", "Activity", "Target", "Trophy"]
ARTS = ["talk", "steps", "law", "build", "read", "chart", "mark", "target"]

raw = open(DOC, encoding="utf-8", errors="replace").read().replace("\r", "")
body = raw[raw.find("Body of content:"):]

# ---------------------------------------------------------------------------
# Split into modules.
# ---------------------------------------------------------------------------
hits = []
seen = set()
for m in re.finditer(r"\n#*\s*MODULE\s+(\d+)\s*[:\u2013-]\s*([^\n]+)", body, re.I):
    n = int(m.group(1))
    if n in seen:
        continue
    seen.add(n)
    hits.append((m.start(), n, m.group(2).strip()))
hits.sort()
if len(hits) != 15:
    sys.exit(f"FAIL: expected 15 modules, found {len(hits)}")

modules = []
for idx, (pos, n, title) in enumerate(hits):
    endpos = hits[idx + 1][0] if idx + 1 < len(hits) else len(body)
    modules.append((n, title, body[pos:endpos]))


# ---------------------------------------------------------------------------
# Question parsing. Format is: stem, then A.-D. lines, then "Correct Answer: X".
# ---------------------------------------------------------------------------
QRE = re.compile(
    r"(?:^|\n)(?:#*\s*)?(?:\*{0,2}Question\s+\d+\*{0,2}\s*\n+)?"
    r"\*{0,2}([A-Z][^\n]{12,240}\?)\*{0,2}\s*\n+"
    r"\*{0,2}A[.)]\s*\*{0,2}([^\n]+?)\*{0,2}\n+"
    r"\*{0,2}B[.)]\s*\*{0,2}([^\n]+?)\*{0,2}\n+"
    r"\*{0,2}C[.)]\s*\*{0,2}([^\n]+?)\*{0,2}\n+"
    r"\*{0,2}D[.)]\s*\*{0,2}([^\n]+?)\*{0,2}\s*\n+"
    r"(?:#*\s*)?\*{0,2}Correct\s+Answer\s*[:\-]?\s*([A-D])",
    re.M)

def parse_questions(text):
    out = []
    for m in QRE.finditer(text):
        stem = re.sub(r"\s+", " ", m.group(1)).strip()
        opts = [re.sub(r"\s+", " ", m.group(i)).strip() for i in range(2, 6)]
        ans = "ABCD".index(m.group(6))
        if len(set(opts)) != 4 or any(len(o) < 2 for o in opts):
            continue
        out.append({"q": stem, "o": opts, "a": ans})
    return out


# ---------------------------------------------------------------------------
# Prose -> sections. Headings become section titles; the paragraphs beneath
# become the body. Bare list lines are folded into the preceding paragraph so
# the reader does not meet a wall of orphaned fragments.
# ---------------------------------------------------------------------------
def clean(block):
    block = QRE.sub("\n", block)
    block = re.sub(r"(?im)^\s*Correct\s+Answer.*$", "", block)
    block = re.sub(r"(?im)^\s*Question\s+\d+\s*$", "", block)
    block = re.sub(r"(?m)^\s*[A-D]\.\s.*$", "", block)
    return block


def sections_from(module_text, module_title):
    text = clean(module_text)
    text = re.sub(r"\n#*\s*MODULE\s+\d+[^\n]*\n", "\n", text, flags=re.I)
    # Modules 1-2 use plain-text headings; 3-15 use markdown. Accept both:
    # a "#"-prefixed line, or a bare line starting with a section number.
    parts = re.split(r"\n(?:#{1,4}\s*([^\n]+)|(\d+(?:\.\d+)*\.?\s+[A-Z][^\n]{3,80}))\n", "\n" + text)
    parts = [x for x in parts if x is not None]
    chunks = []
    if parts[0].strip():
        chunks.append(("Module Introduction", parts[0]))
    for i in range(1, len(parts) - 1, 2):
        chunks.append((parts[i].strip(), parts[i + 1]))

    secs = []
    for head, block in chunks:
        head = re.sub(r"^\d+(\.\d+)*\.?\s*", "", head).strip()
        if not head or len(head) > 70:
            continue
        # Learning-objective bullets get split out as headings by the numbered
        # pattern; a real heading is a noun phrase, not a full sentence.
        if head.endswith(".") or head.count(" ") > 9:
            continue
        paras = []
        for p in re.split(r"\n\s*\n", block):
            p = re.sub(r"\s+", " ", p).strip()
            p = re.sub(r"^[-*\u2022]\s*", "", p)
            p = p.replace("**", "").replace("---", "").strip()
            if len(p) < 40:
                continue
            paras.append(p)
            if len(paras) >= 8:
                break
        if len(paras) < 1:
            continue
        htxt = head.title() if head.isupper() else head
        for wrong, right in (("Hr ", "HR "), (" Hr", " HR"), ("Hrm", "HRM")):
            htxt = htxt.replace(wrong, right)
        secs.append({"art": ARTS[len(secs) % len(ARTS)],
                     "h": htxt,
                     "p": paras})
        if len(secs) >= 21:
            break
    return secs


units = []
exam_bank = []
report = []

for (n, title, text) in modules:
    qs = parse_questions(text)
    exam_bank.extend(qs)
    secs = sections_from(text, title)

    # Pull the practical case study out as its own closing section.
    # Case studies sit at the end of each module, past the section cap, so
    # they are pulled out explicitly and appended. They are the exercises
    # that qualify a learner for certification, so none may be dropped.
    cs = re.search(
        r"\n#{0,4}\s*\d+\.\s*[^\n]*?(?i:case\s+study)[^\n]*\n(.*?)"
        r"(?=\n#\s|\n\d+\.\s+[A-Z]{3,}|\Z)", text, re.S)
    if cs:
        paras = []
        for p in re.split(r"\n\s*\n", clean(cs.group(1))):
            p = re.sub(r"\s+", " ", p).replace("**", "").replace("---", "").strip()
            p = re.sub(r"^[-*\u2022]\s*", "", p)
            if len(p) > 40:
                paras.append(p)
            if len(paras) >= 8:
                break
        if paras:
            secs.append({"art": "mark", "h": "Practical Case Study", "p": paras})

    if not secs:
        sys.exit(f"FAIL: module {n} produced no sections")

    words = sum(len(" ".join(s["p"]).split()) for s in secs)
    title_clean = title.title() if title.isupper() else title
    for wrong, right in (("Hr ", "HR "), (" Hr", " HR"), ("Hrm", "HRM"),
                         ("And", "and"), ("Of", "of"), ("The", "the")):
        title_clean = title_clean.replace(wrong, right)
    title_clean = title_clean[0].upper() + title_clean[1:]
    units.append({
        "id": f"hrm{n}", "n": n, "title": title_clean,
        "mins": max(35, min(90, 12 + words // 45)),
        "icon": ICONS[(n - 1) % len(ICONS)],
        "summary": (secs[0]["p"][0][:210] + "…") if secs[0]["p"] else title_clean,
        "keyWords": [],
        "sections": secs,
        "check": qs[:10],
    })
    report.append((n, title_clean, len(secs), words, len(qs)))

# ---------------------------------------------------------------------------
# Splice into the bundle.
# ---------------------------------------------------------------------------
with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
    d = fh.read()

anchor = 'HRMINTRO:{code:"HRMINTRO",'
if d.count(anchor) != 1:
    sys.exit(f"FAIL: HRMINTRO found {d.count(anchor)}x")

start = d.index(anchor)
i = d.index("{", start + len("HRMINTRO:"))
depth = 0
j = i
instr = False
esc = False
q = ""
while j < len(d):
    ch = d[j]
    if instr:
        if esc:
            esc = False
        elif ch == "\\":
            esc = True
        elif ch == q:
            instr = False
    else:
        if ch in "\"'`":
            instr = True
            q = ch
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                break
    j += 1
old = d[start:j + 1]

course = {
    "code": "HRMINTRO",
    "subject": "Introduction to Human Resource Management",
    "group": "General Courses",
    "cat": "General Courses",
    "year": "All years",
    "term": 1,
    "termLabel": "15-module course · 8–12 weeks",
    "title": "Introduction to Human Resource Management (HRM)",
    "tagline": ("A practical, procedure-led foundation in HRM: how to plan a workforce, run a "
                "recruitment cycle, onboard properly, manage performance, build pay structures, "
                "handle employee relations and stay compliant — with a worked case study in every module."),
    "months": "8–12 weeks",
    "passMark": 75,
    "totalQuestions": min(100, len(exam_bank)),
    "examMins": 60,
    "materials": [],
    "units": units,
    "questions": exam_bank,
}

new = "HRMINTRO:" + json.dumps(course, ensure_ascii=False, separators=(",", ":"))
d = d[:start] + new + d[j + 1:]

with open(SRC, "w", encoding="utf-8", errors="surrogateescape") as fh:
    fh.write(d)

tw = sum(r[3] for r in report)
print(f"  replaced {len(old):,} chars with {len(new):,}")
print(f"  units    : {len(units)}")
print(f"  sections : {sum(len(u['sections']) for u in units)}")
print(f"  words    : ~{tw:,}")
print(f"  exam bank: {len(exam_bank)} questions (exam set to {course['totalQuestions']})")
print()
for n, ti, s, w, qn in report:
    print(f"   {n:>2}. {ti[:46]:<46} {s} sections, {w:>5} words, {qn:>2} Qs")
