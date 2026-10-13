#!/usr/bin/env python3
"""
Three changes.

1. URL SCHEME. Paths are renamed to the requested CamelCase form
   (/MyCourses, /GeneralCourses, /TeachersCourse ...). Matching stays
   case-insensitive so /mycourses and /MYCOURSES also work, and every
   previous lowercase slug is kept as a silent alias so links already
   shared in the wild do not break. The address bar always shows the
   canonical capitalised form.

2. CAROUSEL. The cross-fade is replaced with a continuous right-to-left
   scroll. The slide strip is duplicated and translated by exactly half
   its width, so the moment the first copy leaves the frame the second is
   in the identical position — the loop has no visible seam and no jump.

3. iPersonality is renamed 25Personalities throughout the interface, and
   its share links now point at /25Personalities.
"""
import re
import sys

SRC = "assets/app.js"

# view id -> (canonical display slug, [extra accepted spellings])
ROUTES = {
    "home":          ("Dashboard",       ["dashboard"]),
    "courses":       ("MyCourses",       ["my-courses", "mycourses"]),
    "learn":         ("Subjects",        ["subjects"]),
    "general":       ("GeneralCourses",  ["general-courses", "generalcourses"]),
    "jamb":          ("JAMB",            ["jamb"]),
    "training":      ("TeachersCourse",  ["teacher-courses", "teacherscourse", "teachers-course"]),
    "assignments":   ("Assignments",     ["assignments"]),
    "games":         ("GameHub",         ["games", "gamehub", "game-hub"]),
    "quiz":          ("Assessments",     ["assessments"]),
    "gradebook":     ("Grades",          ["grades"]),
    "community":     ("Community",       ["community"]),
    "messages":      ("Messages",        ["messages"]),
    "meetings":      ("VirtualClass",    ["virtual-class", "virtualclass"]),
    "whiteboard":    ("Whiteboard",      ["whiteboard"]),
    "downloads":     ("OfflineLibrary",  ["offline-library", "offlinelibrary"]),
    "refer":         ("Refer",           ["refer"]),
    "ipersonality":  ("25Personalities", ["ipersonality", "25personalities", "personality"]),
    "careers":       ("Careers",         ["careers"]),
    "blog":          ("Blog",            ["blog"]),
    "profile":       ("Profile",         ["profile"]),
    "attendance":    ("Attendance",      ["attendance"]),
    "behavior":      ("Behaviour",       ["behaviour", "behavior"]),
    "users":         ("Users",           ["users"]),
    "fees":          ("Fees",            ["fees"]),
    "approvals":     ("Approvals",       ["approvals"]),
    "exams":         ("Exams",           ["exams"]),
    "coursebuilder": ("CourseBuilder",   ["course-builder", "coursebuilder"]),
    "push":          ("Notifications",   ["notifications", "push"]),
    "child":         ("Child",           ["child"]),
}

with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
    d = fh.read()

if "MK_SLUGS" in d:
    sys.exit("FAIL: already patched")

# ---------------------------------------------------------------------------
# 1. Rebuild the route tables.
# ---------------------------------------------------------------------------
lookup = {}
for view, (canon, extras) in ROUTES.items():
    lookup[canon.lower()] = view
    for x in extras:
        lookup[x] = view
lookup_js = ",".join('"%s":"%s"' % (k, v) for k, v in lookup.items())
canon_js = ",".join('"%s":"%s"' % (v, c) for v, (c, _) in ROUTES.items())

old_tables = re.search(r'var MK_ROUTES=\{.*?\}\)\(\);', d, re.S)
if not old_tables:
    sys.exit("FAIL: route tables not found")
new_tables = ("var MK_ROUTES={" + lookup_js + "};"
              "var MK_SLUGS={" + canon_js + "};"
              "var MK_VIEW_TO_SLUG=MK_SLUGS;")
d = d[:old_tables.start()] + new_tables + d[old_tables.end():]

# ---------------------------------------------------------------------------
# 2. Continuous right-to-left scroll.
# ---------------------------------------------------------------------------
start = d.index("function Id(){")
i = d.index("{", start + len("function Id"))
depth = 0
j = i
instr = False
esc = False
quote = ""
while j < len(d):
    ch = d[j]
    if instr:
        if esc:
            esc = False
        elif ch == "\\":
            esc = True
        elif ch == quote:
            instr = False
    else:
        if ch in "\"'`":
            instr = True
            quote = ch
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                break
    j += 1
end = j + 1

carousel = (
'function Id(){'
'var pz=f(!1),paused=pz[0],setPaused=pz[1];'
'var reduce=!1;try{reduce=window.matchMedia&&window.matchMedia("(prefers-reduced-motion: reduce)").matches}catch(x){}'
# 10 seconds per slide, so a full cycle is slides x 10s.
'var dur=mkSlides.length*10;'
# The strip holds two identical copies. Translating by exactly -50% lands
# copy two precisely where copy one began, so the restart is invisible.
'var strip=mkSlides.concat(mkSlides);'
'return t("div",{'
'onMouseEnter:function(){setPaused(!0)},onMouseLeave:function(){setPaused(!1)},'
'style:{margin:"0 auto 16px",width:"100%",maxWidth:560,borderRadius:16,overflow:"hidden",'
'position:"relative",background:"#0d1f4b",boxShadow:"0 10px 30px rgba(0,0,0,.25)"},'
'children:['
'e("style",{children:"@keyframes mkScrollLeft{from{transform:translateX(0)}to{transform:translateX(-50%)}}"}),'
'e("div",{style:{display:"flex",width:"200%",'
'animation:reduce?"none":"mkScrollLeft "+dur+"s linear infinite",'
'animationPlayState:paused?"paused":"running"},'
'children:strip.map(function(sl,n){'
'return e("picture",{style:{width:(100/strip.length)+"%",flexShrink:0,display:"block"},children:['
'e("source",{media:"(max-width: 640px)",srcSet:sl.m}),'
'e("img",{src:sl.s,alt:n<mkSlides.length?sl.a:"",'
'loading:n===0?"eager":"lazy",decoding:"async","aria-hidden":n>=mkSlides.length?"true":void 0,'
'style:{width:"100%",height:"auto",objectFit:"cover",display:"block"}})]},n)})})'
']})}'
)
d = d[:start] + carousel + d[end:]

# ---------------------------------------------------------------------------
# 3. iPersonality -> 25Personalities in the interface and share links.
# ---------------------------------------------------------------------------
renames = [
    ('{id:"ipersonality",I:Va,l:"iPersonality"}', '{id:"ipersonality",I:Va,l:"25Personalities"}'),
    ('_a+"/ipersonality?ip="', '_a+"/25Personalities?ip="'),
    ('"iPersonality\\u2122 64"', '"25Personalities"'),
    ('MindKlass iPersonality\\u2122! ', 'MindKlass 25Personalities! '),
    ('MindKlass iPersonality\\u2122 64 \\xB7', 'MindKlass 25Personalities \\xB7'),
    ('" \\u2014 MindKlass iPersonality</title>', '" \\u2014 MindKlass 25Personalities</title>'),
    ('Someone shared their iPersonality\\u2122 result', 'Someone shared their 25Personalities result'),
]
applied = 0
for old, new in renames:
    if old in d:
        d = d.replace(old, new)
        applied += 1

with open(SRC, "w", encoding="utf-8", errors="surrogateescape") as fh:
    fh.write(d)

print(f"  routes           : {len(ROUTES)} views, {len(lookup)} accepted spellings")
print(f"  carousel         : continuous right-to-left, {len(ROUTES) and ''}seamless loop")
print(f"  renames applied  : {applied}/{len(renames)}")
