#!/usr/bin/env python3
"""
build.py — reproduce the MindKlass release from the baseline bundle.

    python3 build.py 2026.08.09.16

Copies the July 26 baseline into a working tree, applies every patch in
order, syncs the version in all three places that must agree, and writes
dist/ ready to upload.

Patch order matters. Later patches locate code that earlier ones inserted
(routing extends the effect the offline flush also hooks; the carousel
replaces a component the earlier patches leave alone). Do not reorder.
"""
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
BASELINE = os.path.join(ROOT, "deploy", "app.baseline-2026.07.26.js")
STATIC = os.path.join(ROOT, "static")
DIST = os.path.join(ROOT, "dist")

PATCHES = [
    "patch_voice.py",       # MP3-first narration player, female voice, pause
    "patch_features.py",    # share w/ referral, course search, 30-min rejection expiry
    "inject_sat_batch1.py", # SAT units 1-7  (Getting Started + Reading & Writing)
    "inject_sat_batch2.py", # SAT units 8-13 (Math)
    "patch_routing.py",     # real URLs, back/forward, ?c= deep links
    "patch_offline.py",     # progress cache, write queue, resume bookmarks
    "patch_carousel.py",    # slide carousel replaces countdown; guest nav
    "patch_aliases.py",     # short course URLs: /lifeskills, /sat
    "inject_vibe_intro.py",    # Introduction to Vibe Coding (15 units)
    "inject_vibe_advanced.py", # Advanced Vibe Coding (20 units)
    "patch_routes_v2.py",      # CamelCase URL scheme + scrolling carousel + rename
    "patch_25personalities.py",# 120-question 25Personalities assessment
    "patch_tts_icon.py",       # icon-only read-aloud, visible on course pages
    "inject_hrm.py",           # detailed HR course rebuilt from client document
    "patch_rejection_expiry.py",  # rejected requests vanish after 30 min, admin lists too
    "patch_life_y1_v2.py",        # One-Year Life Skills Academy redesign (content + project-course UI)
    "patch_esl0510_week1.py",     # teacher course 0510SE: IGCSE ESL 5-week course, Week 1
]


def sync_version(dist, version):
    """The three version markers MUST match exactly.

    The bundle holds a hardcoded constant; version.json is fetched at runtime
    and compared against it. If they differ, the "new version available"
    banner shows on EVERY load and refreshing cannot clear it, because
    reloading does not change a constant compiled into the file.
    """
    app = os.path.join(dist, "assets", "app.js")
    with open(app, encoding="utf-8", errors="surrogateescape") as fh:
        d = fh.read()
    d, n = re.subn(r'Sg="20\d\d\.\d\d\.\d\d(?:\.\d+)?"', f'Sg="{version}"', d)
    if n != 1:
        sys.exit(f"FAIL: version constant matched {n} times, expected 1")
    with open(app, "w", encoding="utf-8", errors="surrogateescape") as fh:
        fh.write(d)

    for page in ("index.html", os.path.join("careers", "index.html")):
        p = os.path.join(dist, page)
        with open(p, encoding="utf-8") as fh:
            h = fh.read()
        with open(p, "w", encoding="utf-8") as fh:
            fh.write(re.sub(r"app\.js\?v=[0-9.]+", f"app.js?v={version}", h))

    with open(os.path.join(dist, "version.json"), "w") as fh:
        fh.write('{"version":"%s"}\n' % version)
    print(f"  version synced in bundle + 2 pages + version.json -> {version}")


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: python3 build.py <version>   e.g. 2026.08.09.11")
    version = sys.argv[1]

    if os.path.isdir(DIST):
        shutil.rmtree(DIST)
    shutil.copytree(STATIC, DIST)
    os.makedirs(os.path.join(DIST, "assets"), exist_ok=True)
    shutil.copy(BASELINE, os.path.join(DIST, "assets", "app.js"))
    print(f"baseline copied ({os.path.getsize(BASELINE):,} bytes)\n")

    for name in PATCHES:
        print(f"applying {name}")
        # patch_25personalities.py reads mk25data.json from its working dir
        src_data = os.path.join(ROOT, "patches", "mk25data.json")
        if os.path.exists(src_data):
            shutil.copy(src_data, os.path.join(DIST, "mk25data.json"))
        r = subprocess.run([sys.executable, os.path.join(ROOT, "patches", name)],
                           cwd=DIST, capture_output=True, text=True)
        if r.returncode != 0:
            sys.exit(f"FAIL in {name}:\n{r.stdout}{r.stderr}")
        print(r.stdout.rstrip() + "\n")

    tmp = os.path.join(DIST, "mk25data.json")
    if os.path.exists(tmp):
        os.remove(tmp)
    sync_version(DIST, version)
    size = os.path.getsize(os.path.join(DIST, "assets", "app.js"))
    print(f"\ndist/ ready. app.js is {size:,} bytes.")
    print("Zip the CONTENTS of dist/ and upload to public_html.")


if __name__ == "__main__":
    main()
