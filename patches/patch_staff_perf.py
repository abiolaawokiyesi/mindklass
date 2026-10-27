#!/usr/bin/env python3
"""
Staff performance module: staff registration, the staff daily/weekly/monthly/yearly tracker,
the administrator's Staff Performance dashboard, and a larger responsive flyer.

Windows equivalent: apply_staff_perf.ps1 (the two read the same files in patches/staff_perf/).
  staff_core.js, staff_hub.js, staff_admin.js  module code injected after the jsx-runtime import
  flyer.js                                     replaces function Id() (the animated flyer)
  text_patches.json                            exact-string edits to registration, navigation, pages, routes
  ../supabase/staff_performance.sql            tables and rules; also embedded in the admin page

Run the SQL once in Supabase (SQL editor) before the staff tables are used.
"""
import json
import os
import sys

SRC = "assets/app.js"
HERE = os.path.dirname(os.path.abspath(__file__))
SP = os.path.join(HERE, "staff_perf")


def rd(name):
    with open(os.path.join(SP, name), encoding="utf-8") as fh:
        return fh.read()


with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
    d = fh.read()

with open(os.path.join(HERE, "..", "supabase", "staff_performance.sql"), encoding="utf-8") as fh:
    sql = fh.read()

admin = rd("staff_admin.js").replace("__MKS_SQL__", json.dumps(sql))
code = "/*MKS-BEGIN*/" + rd("staff_core.js") + "\n" + rd("staff_hub.js") + "\n" + admin + "\n/*MKS-END*/"

anchor = 'import{Fragment as D,jsx as e,jsxs as t}from"react/jsx-runtime";'
if anchor not in d:
    sys.exit("FAIL: jsx anchor missing")
b = d.find("/*MKS-BEGIN*/")
if b >= 0:
    end = d.index("/*MKS-END*/", b) + len("/*MKS-END*/")
    d = d[:b] + code + d[end:]
    print("  replaced module code")
else:
    d = d.replace(anchor, anchor + code, 1)
    print("  added module code")

# the animated flyer
fs, fe = d.find("function Id("), d.find("function Rg(h){")
if fs < 0 or fe < fs:
    sys.exit("FAIL: flyer function not found")
d = d[:fs] + rd("flyer.js").rstrip() + d[fe:]

# exact-string edits
with open(os.path.join(SP, "text_patches.json"), encoding="utf-8") as fh:
    patches = json.load(fh)
for p in patches:
    if p["marker"] in d:
        print("  skip (already applied):", p["name"])
        continue
    n = d.count(p["old"])
    if n != 1:
        sys.exit(f"FAIL: {p['name']}: expected 1 match, found {n}")
    d = d.replace(p["old"], p["new"], 1)
    print("  applied:", p["name"])

with open(SRC, "w", encoding="utf-8", errors="surrogateescape") as fh:
    fh.write(d)
print("  staff performance module installed")
