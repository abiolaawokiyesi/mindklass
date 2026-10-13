#!/usr/bin/env python3
"""
Short course URLs.

    https://mindklass.com/lifeskills   -> the One-Year Life Skills Academy
    https://mindklass.com/sat          -> the Digital SAT course

These are aliases, not new views. Each resolves to a course key, which the
existing share-link machinery already knows how to handle: it picks the
catalogue tab the course lives in and pre-filters the list down to it.

The search box is pre-filled with a readable phrase ("Life Skills") rather
than the internal code ("LIFE-Y1"), because the visitor can see that box.

One wrinkle worth knowing about: the router pushes a tidy path whenever the
view changes, and that effect fires on first render too — which would
immediately rewrite /lifeskills to /subjects and throw away the pretty URL
the visitor arrived on. The push is therefore suppressed for exactly the
view the alias resolves to, and only while the alias path is still showing.
Navigating anywhere else pushes normally.
"""
import sys

SRC = "assets/app.js"

# path segment -> (course key, human search phrase)
ALIASES = {
    "lifeskills": ("LIFE-Y1", "Life Skills"),
    "life-skills": ("LIFE-Y1", "Life Skills"),
    "sat": ("SAT-Y1", "SAT"),
}

with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
    d = fh.read()

if "MK_PATH_COURSES" in d:
    sys.exit("FAIL: course aliases already patched")

entries = ",".join('"%s":{c:"%s",q:"%s"}' % (p, c, q) for p, (c, q) in ALIASES.items())

# ---------------------------------------------------------------------------
# 1. Alias table + lookup, inserted just before the existing share-link helper
#    so it is defined before anything references it.
# ---------------------------------------------------------------------------
anchor = 'function mkSharedCourse(){'
if d.count(anchor) != 1:
    sys.exit(f"FAIL: mkSharedCourse found {d.count(anchor)}x")

helpers = (
'var MK_PATH_COURSES={' + entries + '};'
'function mkPathCourse(){try{'
'var p=(window.location.pathname||"/").replace(/^\\/+|\\/+$/g,"").toLowerCase();'
'return MK_PATH_COURSES[p]||null}catch(x){return null}}'
'function mkSearchPrefill(){var a=mkPathCourse();if(a)return a.q;try{'
'return new URLSearchParams(window.location.search).get("c")||""}catch(x){return""}}'
)
d = d.replace(anchor, helpers + anchor, 1)

# ---------------------------------------------------------------------------
# 2. An alias counts as a shared course, so view resolution just works.
# ---------------------------------------------------------------------------
old = ('function mkSharedCourse(){try{return new URLSearchParams(window.location.search)'
       '.get("c")||""}catch(x){return""}}')
if d.count(old) != 1:
    sys.exit(f"FAIL: mkSharedCourse body found {d.count(old)}x")
new = ('function mkSharedCourse(){var a=mkPathCourse();if(a)return a.c;'
       'try{return new URLSearchParams(window.location.search).get("c")||""}catch(x){return""}}')
d = d.replace(old, new, 1)

# ---------------------------------------------------------------------------
# 3. Pre-fill the search box with the readable phrase.
# ---------------------------------------------------------------------------
old_q = '[mkQ,mkSetQ]=f(()=>mkSharedCourse())'
if d.count(old_q) != 1:
    sys.exit(f"FAIL: search state found {d.count(old_q)}x")
d = d.replace(old_q, '[mkQ,mkSetQ]=f(()=>mkSearchPrefill())', 1)

# ---------------------------------------------------------------------------
# 4. Keep the alias in the address bar until the visitor navigates away.
# ---------------------------------------------------------------------------
old_push = 'function mkPushView(view){try{'
if d.count(old_push) != 1:
    sys.exit(f"FAIL: mkPushView found {d.count(old_push)}x")
new_push = ('function mkPushView(view){try{'
            'var al=mkPathCourse();if(al&&view===mkViewForSharedCourse())return;')
d = d.replace(old_push, new_push, 1)

with open(SRC, "w", encoding="utf-8", errors="surrogateescape") as fh:
    fh.write(d)

for p, (c, q) in ALIASES.items():
    print(f"  /{p:<12} -> {c:<8} (search pre-filled \"{q}\")")
