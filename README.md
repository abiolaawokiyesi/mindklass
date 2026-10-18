# MindKlass — deployment repository

Current release: **2026.10.18.4** (adds `patch_rejection_expiry.py` and `patch_life_y1_v2.py`; `dist/` was patched directly with the equivalent PowerShell, confirm with `python3 build.py 2026.10.14.2` when Python is available)

---

## The situation this repo exists to handle

There is no readable source code for the production MindKlass app. The live
site runs from `assets/app.js`, a ~5 MB minified bundle with no sourcemap.
Every feature added since late July is a targeted edit to that compiled file.

Editing minified code by hand is unmaintainable, so instead each change is
written as a **patch script**: a small Python program that finds a specific
piece of code and replaces it, with commentary explaining what and why. The
scripts are the readable record of changes the bundle itself cannot show you.

If `MindKlass.jsx` (roughly 12,000–16,000 lines, around July 2026) is ever
found, these scripts document precisely what must be reapplied to it.

---

## Layout

```
build.py                        rebuilds the release from baseline + patches
deploy/app.baseline-2026.07.26.js   the untouched July 26 production bundle
patches/                        one script per feature, applied in order
static/                         everything not generated (html, images, slides)
tools/generate-voice.py         run on your PC to produce narration MP3s
dist/                           build output — this is what gets uploaded
```

`deploy/app.baseline-2026.07.26.js` is the **canonical starting point**. It is
the most complete artefact in existence: 87 courses including JAMB/UTME,
General Courses, IGCSE and Life Skills, plus TTS, the blog CMS, the jobs
board, course visibility and multi-currency. Never replace it with a
development build — one such rebuild silently dropped 59 courses and four
database tables.

---

## Rebuilding

```bash
python3 build.py 2026.08.09.16
```

Copies the baseline, applies every patch in order, syncs the version, and
writes `dist/`. Zip the **contents** of `dist/` and upload to `public_html`.

Verified: this reproduces the shipped bundle byte-for-byte.

**Patch order matters.** Later patches locate code earlier ones inserted.
Do not reorder them.

---

## The patches

| Script | What it does |
|---|---|
| `patch_voice.py` | Narration player: pre-generated MP3 when available, browser speech otherwise. Female voice only, working pause/resume. Replaces the old dual-gender toggle. |
| `patch_features.py` | Share button carrying the sharer's referral code; live course search; "Not approved" clears 30 minutes after the decision, applied at all four lookup points. |
| `inject_sat_batch1.py` | SAT units 1–7: Getting Started, Reading & Writing. |
| `inject_sat_batch2.py` | SAT units 8–13: the full Math section. |
| `patch_routing.py` | 29 real URLs (`/dashboard`, `/my-courses`, `/teacher-courses`…), working back/forward, `?c=` course deep links, `?ref=` preserved across navigation. |
| `patch_offline.py` | Progress mirrored to localStorage per user; writes made offline queued and flushed on reconnect; last unit bookmarked so "Continue learning" resumes exactly there. |
| `patch_carousel.py` | Slide carousel replaces the live-session countdown; Teacher's Course opened to guests. |
| `patch_aliases.py` | Short course URLs — `/lifeskills` and `/sat` open the course directly with the catalogue pre-filtered. Add new ones by editing the `ALIASES` dict. |
| `inject_vibe_intro.py` | Introduction to Vibe Coding — 15 units, General Courses. |
| `inject_vibe_advanced.py` | Advanced Vibe Coding — 20 units, General Courses. |
| `patch_esl0510_week1.py` | New teacher course 0510SE, Cambridge IGCSE English as a Second Language 5-week online course (Weeks 1 to 3: 20 units, 101-question assessment; sections can carry a figure, see apply_esl0510_week1.ps1). Add Weeks 2 to 5 in `patches/esl0510_content/`. Runs after the Life Skills patch. |
| `patch_life_y1_v2.py` | One-Year Life Skills Academy (LIFE-Y1) rebuilt: 51 units on one learning loop, 153 scenario quick checks, 4 rubric-based capstones, project-course UI (no exam chips or Term Assessment card). Content authored in `patches/lifey1_content/`, built by `build_course.ps1`. Runs last. |
| `patch_rejection_expiry.py` | Rejected approval requests (teacher training, student course, exam) vanish 30 minutes after the decision, in student and admin views, with a 30 s timer. Runs last. |

Every script asserts on its anchors and aborts rather than corrupting the
bundle if the code it expects has moved.

---

## The version rule

Three places must hold the **same** string:

1. `Sg="…"` — hardcoded inside `app.js`
2. `version.json`
3. `?v=…` on the script tag in `index.html` and `careers/index.html`

The app fetches `version.json` and compares it against the constant. If they
differ it shows "A new version of MindKlass is available." **on every load,
and refreshing cannot clear it** — reloading does not change a constant
compiled into the file. This caused a permanently stuck banner in July.

`build.py` sets all three together. Never edit one by hand.

---

## Voice narration

Lessons currently fall back to the phone's built-in voice, which sounds
robotic on budget Android devices. To fix that:

```bash
pip install edge-tts
python tools/generate-voice.py
```

Upload the resulting `voice/` folder to `public_html/voice/`. The app then
prefers the MP3 and marks it "HD"; anything without a file keeps the
fallback, so this can be rolled out lesson by lesson with no flag day.

Segment IDs must match what the app uses. **Hover any Listen button and the
tooltip shows that button's exact ID** — collect the ones you want narrated
and put them in the `SEGMENTS` list.

Neither Bark nor a live TTS service will work here: Bark is a ~5 GB PyTorch
model, and both need a server. Pre-generating is what fits cPanel hosting.

---

## Testing

Changes are validated before release by:

- **esbuild parse** of the whole patched bundle (catches syntax damage)
- **jsdom render** with React actually mounting and Supabase stubbed
- **Behavioural suites** run against code extracted verbatim from the shipped
  bundle: 27 routing/offline checks, 14 share/search/expiry checks, 14
  carousel checks, 8 voice checks

Run each boot test in its own process — multiple jsdom instances in one
process leak into each other and produce false failures.

---

## Outstanding

**Blocked on you**
- 200 SAT questions per focal point — until these arrive `passMark` and
  `totalQuestions` stay null and the final exam stays locked
- `voice/` MP3s (see above)
- Nav bar reorder — requested, sequence never supplied
- Canonical domain: standardised on `www.mindklass.com`; say if you want the
  bare domain instead and both the tags and a redirect need changing

**Not started**
- Admin view of all users' course-attempt progress
- SAT batches 3 and 4 (strategy, Desmos, practice tests, study plans, test day)
- Firebase push — `FCM_ENABLED` is false with placeholder config; two backend
  endpoints unbuilt
- Paystack reconciliation webhook — fees are currently marked paid
  optimistically on the client, with no server-side confirmation

---

## Notes worth keeping

- A white screen after deploy is more often a caching or partial-upload
  problem than a code bug. `index.html` carries a boot placeholder that shows
  a diagnostic message after 12 seconds instead of failing silently.
- `.htaccess` must not cache `app.js` aggressively — the filename never
  changes, so cache-busting depends entirely on the `?v=` query string.
- Courses must go in the `gg` catalogue (student-facing), not `mm` (teacher).
- Supabase columns are snake_case; the admin UI uses camelCase. Not the same.
- Turn on "Show Hidden Files" in cPanel File Manager or you will not see
  `.htaccess` after upload and will think it failed.
