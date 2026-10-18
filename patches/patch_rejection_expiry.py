#!/usr/bin/env python3
"""
Rejected course-approval requests disappear 30 minutes after the decision.

patch_features.py already hides a rejection from the *student's own* lookups
(catalogue card, course page, status pill) once it is older than 30 minutes,
but only when something re-renders. It left two gaps:

  1. The admin lists read the raw state arrays, so rejected requests stayed in
     the admin approval screens forever.
  2. Nothing re-rendered at the 30-minute mark, so a rejection stayed on screen
     until the user navigated or reloaded.

This patch fixes both for every kind of approval request:
  - teacher training applications   (course_access_apps, kind "teacher")
  - student course applications     (course_access_apps, kind "student")
  - term-assessment / exam requests (exam_apps, all kinds)

  A. mkPrune() drops expired rejections from a list. It is applied when each
     list is loaded, so every surface (student and admin) agrees.
  B. A 30-second timer prunes the three lists already in memory, so a rejection
     vanishes on screen when its 30 minutes are up. mkPrune returns the same
     array when nothing expired, so React does not re-render needlessly.

The rows stay in the database as an audit trail; only the UI hides them.
Must run after patch_features.py, which defines mkRejectionExpired/mkLiveApp
and adds decidedTs to the mappers.
"""
import sys

SRC = "assets/app.js"

with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
    d = fh.read()

if "function mkPrune(" in d:
    sys.exit("FAIL: already patched")


def swap(old, new):
    global d
    n = d.count(old)
    assert n == 1, f"anchor found {n}x: {old[:60]}"
    d = d.replace(old, new, 1)


# A. helper, next to the existing expiry helpers
swap('function mkLiveApp(app){return mkRejectionExpired(app)?null:app}',
     'function mkLiveApp(app){return mkRejectionExpired(app)?null:app}\n'
     'function mkPrune(a){var r=a.filter(function(x){return!mkRejectionExpired(x)});return r.length===a.length?a:r}')

# A. apply when loading
swap('qr(s.filter(r=>r.kind==="teacher").map(Gl)),Tr(s.filter(r=>r.kind==="student").map(Gl))',
     'qr(mkPrune(s.filter(r=>r.kind==="teacher").map(Gl))),Tr(mkPrune(s.filter(r=>r.kind==="student").map(Gl)))')
swap('Sr((i||[]).map(lh))', 'Sr(mkPrune((i||[]).map(lh)))')

# B. timer, as the first effect after the component's first state hooks
swap('[Me,Ye]=f(!1);de(()=>{try{let ae=new URLSearchParams',
     '[Me,Ye]=f(!1);de(()=>{var mkT=setInterval(function(){qr(mkPrune);Tr(mkPrune);Sr(mkPrune)},3e4);return()=>clearInterval(mkT)},[]);'
     'de(()=>{try{let ae=new URLSearchParams')

with open(SRC, "w", encoding="utf-8", errors="surrogateescape") as fh:
    fh.write(d)
print("  rejected requests now expire after 30 min (student + admin lists, live timer)")
