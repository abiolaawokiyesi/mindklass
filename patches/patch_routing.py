#!/usr/bin/env python3
"""
URL routing for MindKlass.

The app keeps its current view in a single state variable (G), persisted to
sessionStorage. This patch layers real URLs on top of that:

  * On load, the path decides the view (falling back to sessionStorage).
  * Changing view pushes a new history entry, so the address bar tracks it.
  * The browser Back and Forward buttons work.
  * A shared course link (?c=SAT-Y1) opens the right catalogue with that
    course already filtered in.

Note on slugs: the requested "/teacher's courses" cannot work as a URL —
apostrophes and spaces are not valid in a path. Used /teacher-courses.

/careers stays a real folder on the server (it has its own SEO head), so it
is served directly by Apache and then recognised by the router.
"""
import sys

SRC = "assets/app.js"

ROUTES = {
    "dashboard": "home",
    "my-courses": "courses",
    "subjects": "learn",
    "general-courses": "general",
    "jamb": "jamb",
    "teacher-courses": "training",
    "assignments": "assignments",
    "games": "games",
    "assessments": "quiz",
    "grades": "gradebook",
    "community": "community",
    "messages": "messages",
    "virtual-class": "meetings",
    "whiteboard": "whiteboard",
    "offline-library": "downloads",
    "refer": "refer",
    "ipersonality": "ipersonality",
    "careers": "careers",
    "blog": "blog",
    "profile": "profile",
    "attendance": "attendance",
    "behaviour": "behavior",
    "users": "users",
    "fees": "fees",
    "approvals": "approvals",
    "exams": "exams",
    "course-builder": "coursebuilder",
    "notifications": "push",
    "child": "child",
}

with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
    d = fh.read()

if "mkRouteFromPath" in d:
    sys.exit("FAIL: routing already patched")

# ---------------------------------------------------------------------------
# 1. Module-level route table and helpers.
# ---------------------------------------------------------------------------
slug_to_view = ",".join(f'"{k}":"{v}"' for k, v in ROUTES.items())

helpers = (
'\nvar MK_ROUTES={' + slug_to_view + '};'
'var MK_VIEW_TO_SLUG=(function(){var m={};for(var k in MK_ROUTES){if(!m[MK_ROUTES[k]])m[MK_ROUTES[k]]=k}return m})();'
# "/join" is the referral landing path; it must resolve to the dashboard
# rather than 404 into sessionStorage, while ?ref= is handled elsewhere.
'function mkRouteFromPath(){try{'
'var p=(window.location.pathname||"/").replace(/^\\/+|\\/+$/g,"").toLowerCase();'
'if(!p)return null;'
'if(p==="join")return "home";'
'return MK_ROUTES[p]||null}catch(x){return null}}'
'function mkSharedCourse(){try{return new URLSearchParams(window.location.search).get("c")||""}catch(x){return""}}'
# A shared course link should land on the catalogue that actually contains it.
'function mkViewForSharedCourse(){var c=mkSharedCourse();if(!c)return null;'
'try{var course=(typeof gg!=="undefined")&&gg[c];if(!course)return null;'
'return course.cat==="General Courses"?"general":(course.group==="JAMB (UTME)"||course.cat==="JAMB (UTME)")?"jamb":"learn"}catch(x){return null}}'
'function mkInitialView(fallback){return mkViewForSharedCourse()||mkRouteFromPath()||fallback}'
'function mkPushView(view){try{'
'var slug=MK_VIEW_TO_SLUG[view];if(!slug)return;'
'var target="/"+slug;'
# Preserve ?ref= so a referral survives navigation; drop ?c= once used.
'var ref=new URLSearchParams(window.location.search).get("ref");'
'if(ref)target+="?ref="+encodeURIComponent(ref);'
'if(window.location.pathname+window.location.search!==target)'
'window.history.pushState({mkView:view},"",target)}catch(x){}}\n'
)
anchor = 'import{Fragment as D,jsx as e,jsxs as t}from"react/jsx-runtime";'
assert anchor in d, "jsx import anchor missing"
d = d.replace(anchor, anchor + helpers, 1)

# ---------------------------------------------------------------------------
# 2. The initial view now comes from the URL first, sessionStorage second.
# ---------------------------------------------------------------------------
old_init = '[G,ie]=f(()=>{try{return sessionStorage.getItem("mk_tab")||"home"}catch{return"home"}})'
assert d.count(old_init) == 1, f"view state found {d.count(old_init)}x"
new_init = ('[G,ie]=f(()=>{try{return mkInitialView(sessionStorage.getItem("mk_tab")||"home")}'
            'catch{return mkInitialView("home")||"home"}})')
d = d.replace(old_init, new_init, 1)

# ---------------------------------------------------------------------------
# 3. A shared ?c=COURSE link pre-fills the catalogue search with that course.
# ---------------------------------------------------------------------------
old_q = '[mkQ,mkSetQ]=f("")'
assert d.count(old_q) == 1, f"search state found {d.count(old_q)}x"
d = d.replace(old_q, '[mkQ,mkSetQ]=f(()=>mkSharedCourse())', 1)

# ---------------------------------------------------------------------------
# 4. Keep the URL in step with the view, and make Back/Forward work.
#    Extends the existing sessionStorage sync effect rather than adding a
#    competing one, so the two can never disagree about the current view.
# ---------------------------------------------------------------------------
old_sync = 'de(()=>{try{sessionStorage.setItem("mk_tab",G)}catch{}},[G])'
assert d.count(old_sync) == 1, f"tab sync effect found {d.count(old_sync)}x"
new_sync = ('de(()=>{try{sessionStorage.setItem("mk_tab",G)}catch{}try{mkPushView(G)}catch{}},[G]),'
            'de(()=>{let mk_pop=()=>{let v=mkRouteFromPath();if(v)ie(v)};'
            'window.addEventListener("popstate",mk_pop);'
            'return()=>window.removeEventListener("popstate",mk_pop)},[])')
d = d.replace(old_sync, new_sync, 1)

with open(SRC, "w", encoding="utf-8", errors="surrogateescape") as fh:
    fh.write(d)

print(f"  routes registered : {len(ROUTES)}")
print(f"  initial view      : URL path -> shared course -> sessionStorage -> home")
print(f"  history           : pushState on view change, popstate handled")
print(f"  referral          : ?ref= preserved across navigation")
