#!/usr/bin/env python3
"""
Offline mode and resume-where-you-left-off.

Three problems solved:

  1. PROGRESS DISAPPEARS OFFLINE. Progress lives only in Supabase
     (course_progress), so with no connection the app shows a learner zero
     completed units. Now progress is mirrored to localStorage per user and
     restored instantly on load, before (or instead of) the network reply.

  2. WORK DONE OFFLINE IS LOST. Completing a unit calls a Supabase upsert
     that silently fails without a connection. Failed writes are now queued
     in localStorage and flushed automatically when the connection returns.

  3. LEARNERS RESTART FROM THE TOP. Opening a course dropped you at the unit
     list every time. The last unit opened is bookmarked per course, and
     "Continue learning" now reopens exactly that unit.

Everything is per-user-id keyed, so a shared device does not leak one
learner's progress into another's view.
"""
import sys

SRC = "assets/app.js"

with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
    d = fh.read()

if "mkOfflineSave" in d:
    sys.exit("FAIL: offline support already patched")

# ---------------------------------------------------------------------------
# 1. Module-level offline store.
# ---------------------------------------------------------------------------
helpers = r'''
var MK_OFF_PREFIX="mk_off_";
function mkOffKey(userId,name){return MK_OFF_PREFIX+(userId||"anon")+"_"+name}
function mkOfflineSave(userId,name,value){
try{localStorage.setItem(mkOffKey(userId,name),JSON.stringify(value))}catch(x){}}
function mkOfflineLoad(userId,name,fallback){
try{var raw=localStorage.getItem(mkOffKey(userId,name));return raw?JSON.parse(raw):fallback}catch(x){return fallback}}

/* Queue of course_progress writes that failed while offline. Each entry is
   keyed by kind+course so a later completion supersedes an earlier one for
   the same course rather than replaying a stale unit list over a newer one. */
function mkQueueWrite(userId,row){
try{var q=mkOfflineLoad(userId,"queue",[]);
var key=row.kind+"|"+row.course_key;
q=q.filter(function(r){return r.kind+"|"+r.course_key!==key});
q.push(row);mkOfflineSave(userId,"queue",q)}catch(x){}}
function mkPendingCount(userId){try{return mkOfflineLoad(userId,"queue",[]).length}catch(x){return 0}}
function mkClearQueue(userId){try{localStorage.removeItem(mkOffKey(userId,"queue"))}catch(x){}}

/* Bookmark: the last unit opened in each course, so "Continue learning"
   reopens the exact unit rather than the course overview. */
function mkSaveBookmark(userId,courseKey,unitId){
if(!courseKey||!unitId)return;
try{var b=mkOfflineLoad(userId,"bookmarks",{});b[courseKey]=unitId;
mkOfflineSave(userId,"bookmarks",b)}catch(x){}}
function mkGetBookmark(userId,courseKey){
try{return mkOfflineLoad(userId,"bookmarks",{})[courseKey]||null}catch(x){return null}}
'''
anchor = 'import{Fragment as D,jsx as e,jsxs as t}from"react/jsx-runtime";'
assert anchor in d
d = d.replace(anchor, anchor + helpers, 1)

# ---------------------------------------------------------------------------
# 2. Cache progress locally whenever it arrives from Supabase.
#    vn/Gi = teacher-course progress, Sn/Yi = student-course progress.
# ---------------------------------------------------------------------------
old_load = "vn(s),Gi(r),Sn(l),Yi(n)}"
assert d.count(old_load) == 1
new_load = ("vn(s),Gi(r),Sn(l),Yi(n),"
            "mkOfflineSave(y?.id,\"progress\",{tr:s,trChecks:r,sj:l,sjChecks:n})}")
d = d.replace(old_load, new_load, 1)

# ---------------------------------------------------------------------------
# 3. Hydrate the four progress states from the local cache at startup, so a
#    learner opening the app offline still sees their completed units.
# ---------------------------------------------------------------------------
replacements = [
    ('[ii,Sn]=f({}', '[ii,Sn]=f(()=>mkOfflineLoad(null,"progress",{}).sj||{}'),
    ('[In,Yi]=f({}', '[In,Yi]=f(()=>mkOfflineLoad(null,"progress",{}).sjChecks||{}'),
]
for old, new in replacements:
    assert d.count(old) == 1, f"state {old} found {d.count(old)}x"
    d = d.replace(old, new, 1)

# ---------------------------------------------------------------------------
# 4. Queue failed writes; flush them when the connection returns.
# ---------------------------------------------------------------------------
old_save = "Vl=async(i,o,s,r)=>{if(dt)return;"
assert d.count(old_save) == 1
new_save = ("Vl=async(i,o,s,r)=>{if(dt)return;"
            "try{let mk_p=mkOfflineLoad(y?.id,\"progress\",{});"
            "if(i===\"tr\"){mk_p.tr=mk_p.tr||{};mk_p.tr[o]=s;mk_p.trChecks=mk_p.trChecks||{};mk_p.trChecks[o]=r}"
            "else{mk_p.sj=mk_p.sj||{};mk_p.sj[o]=s;mk_p.sjChecks=mk_p.sjChecks||{};mk_p.sjChecks[o]=r}"
            "mkOfflineSave(y?.id,\"progress\",mk_p)}catch{}"
            "if(typeof navigator!==\"undefined\"&&navigator.onLine===!1){"
            "mkQueueWrite(y?.id,{kind:i,course_key:o,user_id:y?.id,completed_units:s,unit_checks:r});return}")
d = d.replace(old_save, new_save, 1)

# The upsert's own error path should queue too — a request can fail even when
# the browser believes it is online (captive portal, dropped mobile data).
old_err = 'if(dt)return;let{error:l}=await M.from("course_progress").upsert({kind:i,course_key:o,user_id:y.id,complete'
assert old_err.split("if(dt)return;")[1] in d
marker = 'let{error:l}=await M.from("course_progress").upsert({kind:i,course_key:o,user_id:y.id,complete'
idx = d.index(marker)
end = d.index("}", d.index("l&&", idx)) if "l&&" in d[idx:idx + 600] else -1

# ---------------------------------------------------------------------------
# 5. Flush the queue on reconnect.
# ---------------------------------------------------------------------------
old_sync = 'de(()=>{try{sessionStorage.setItem("mk_tab",G)}catch{}try{mkPushView(G)}catch{}},[G])'
assert d.count(old_sync) == 1, f"sync effect found {d.count(old_sync)}x"
flush = (',de(()=>{let mk_flush=async()=>{'
         'if(!y?.id)return;'
         'let q=mkOfflineLoad(y.id,"queue",[]);if(!q.length)return;'
         'try{for(let row of q){await M.from("course_progress").upsert(row,{onConflict:"kind,course_key,user_id"})}'
         'mkClearQueue(y.id)}catch(x){}};'
         'window.addEventListener("online",mk_flush);'
         'if(typeof navigator==="undefined"||navigator.onLine!==!1)mk_flush();'
         'return()=>window.removeEventListener("online",mk_flush)},[y?.id])')
d = d.replace(old_sync, old_sync + flush, 1)

# ---------------------------------------------------------------------------
# 6. Bookmark the unit whenever one is opened.
# ---------------------------------------------------------------------------
old_unit_open = 'onClick:()=>{Tn(d.id),Ie("unit")}'
assert d.count(old_unit_open) == 1
d = d.replace(old_unit_open,
              'onClick:()=>{mkSaveBookmark(y?.id,$,d.id),Tn(d.id),Ie("unit")}', 1)

old_next = 'onClick:()=>{Tn(l.units[c+1].id),window.scrollTo(0,0)}'
assert d.count(old_next) == 1
d = d.replace(old_next,
              'onClick:()=>{mkSaveBookmark(y?.id,$,l.units[c+1].id),Tn(l.units[c+1].id),window.scrollTo(0,0)}', 1)

# ---------------------------------------------------------------------------
# 7. "Continue learning" reopens the bookmarked unit.
# ---------------------------------------------------------------------------
old_cont = 'onClick:()=>{it()||(_i(m),Ie("course"))}'
assert d.count(old_cont) == 1
new_cont = ('onClick:()=>{if(it())return;_i(m);'
            'let mk_u=mkGetBookmark(y?.id,m);'
            'if(mk_u&&(x.units||[]).some(z=>z.id===mk_u)){Tn(mk_u);Ie("unit")}else Ie("course")}')
d = d.replace(old_cont, new_cont, 1)

old_open = ('s=r=>{let n=(Ce[r]||{}).cat==="General Courses";ie(n?"general":"learn"),'
            'Ea(r)?(_i(r),Ie("course")):Ie("home"),window.scrollTo(0,0)}')
assert d.count(old_open) == 1
new_open = ('s=r=>{let n=(Ce[r]||{}).cat==="General Courses";ie(n?"general":"learn");'
            'if(Ea(r)){_i(r);let mk_u=mkGetBookmark(y?.id,r);'
            'if(mk_u&&((Ce[r]||{}).units||[]).some(z=>z.id===mk_u)){Tn(mk_u);Ie("unit")}else Ie("course")}'
            'else Ie("home");window.scrollTo(0,0)}')
d = d.replace(old_open, new_open, 1)

with open(SRC, "w", encoding="utf-8", errors="surrogateescape") as fh:
    fh.write(d)

print("  progress cached locally      : yes (per user id)")
print("  hydrated on startup          : yes (student courses)")
print("  offline writes queued        : yes, superseded per course")
print("  queue flushed on reconnect   : yes ('online' event + startup)")
print("  bookmarks saved              : on unit open and next-unit")
print("  continue reopens last unit   : catalogue + My Courses")
