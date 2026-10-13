#!/usr/bin/env python3
"""
Three features injected into the minified MindKlass bundle.

  1. Course search      — a search box above the category chips that filters
                          the catalogue by title, subject, group, code or
                          tagline as you type.
  2. Share with referral— a share icon on every course card. Uses the native
                          share sheet on mobile, clipboard on desktop. The
                          link always carries the sharer's referral code, so
                          any signup from it credits them.
  3. Rejection expiry   — a "Not approved" state stops showing 30 minutes
                          after the decision, so the card returns to a clean
                          "apply" state instead of displaying a stale refusal
                          indefinitely.
"""
import re
import sys

SRC = "assets/app.js"
WINDOW_MIN = 30

with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
    d = fh.read()

if "mkShareCourse" in d:
    sys.exit("FAIL: already patched")

# ===========================================================================
# 0. Shared helpers at module scope.
# ===========================================================================
anchor = 'import{Fragment as D,jsx as e,jsxs as t}from"react/jsx-runtime";'
helpers = r'''
var MK_REJECT_WINDOW_MS=%d*60*1000;
function mkRejectionExpired(app){
if(!app||app.status!=="rejected")return!1;
var ts=app.decidedTs||app.decided_at;if(!ts)return!1;
var when=new Date(ts).getTime();if(!when||isNaN(when))return!1;
return Date.now()-when>MK_REJECT_WINDOW_MS}
function mkLiveApp(app){return mkRejectionExpired(app)?null:app}
function mkShareCourse(base,refCode,courseKey,course){
var url=base+"/join?ref="+encodeURIComponent(refCode||"")+"&c="+encodeURIComponent(courseKey);
var title=(course&&(course.title||course.subject))||"a MindKlass course";
var text="I'm learning with MindKlass \u2014 "+title+". Join me:";
try{
if(navigator.share)return navigator.share({title:title,text:text,url:url}).catch(function(){});
}catch(x){}
try{navigator.clipboard.writeText(text+" "+url);alert("Share link copied \u2014 it carries your referral code, so you earn when someone joins through it.")}
catch(x){window.prompt("Copy this link:",url)}}
function mkCourseMatch(course,key,q){
if(!q)return!0;
var hay=[key,course.title,course.subject,course.group,course.cat,course.code,course.tagline,course.year,course.termLabel].filter(Boolean).join(" ").toLowerCase();
return q.toLowerCase().split(/\s+/).filter(Boolean).every(function(w){return hay.indexOf(w)>-1})}
''' % WINDOW_MIN
d = d.replace(anchor, anchor + helpers, 1)

# ===========================================================================
# 1. Search state — piggyback on the existing category-filter state.
# ===========================================================================
old = '[Ji,sc]=f("All")'
assert d.count(old) == 1, f"category state found {d.count(old)}x"
d = d.replace(old, '[Ji,sc]=f("All"),[mkQ,mkSetQ]=f("")', 1)

# ===========================================================================
# 2. Wire search into the catalogue filter.
#    Original: p = (all-categories ? n : n.filter(by category))
#    New:      also apply the text query.
# ===========================================================================
old_filter = 'let p=o||s||Ji==="All"?n:n.filter(([,d])=>(d.cat||d.subject)===Ji);'
assert d.count(old_filter) == 1, f"catalogue filter found {d.count(old_filter)}x"
new_filter = ('let p=(o||s||Ji==="All"?n:n.filter(([,d])=>(d.cat||d.subject)===Ji))'
              '.filter(([mk_k,mk_c])=>mkCourseMatch(mk_c,mk_k,mkQ));')
d = d.replace(old_filter, new_filter, 1)

# ===========================================================================
# 3. Render the search box immediately above the category chips.
# ===========================================================================
chips_anchor = '!o&&!s&&e("div",{style:{display:"flex",flexWrap:"wrap",gap:7,marginBottom:16},children:Yo.map(p=>{'
assert d.count(chips_anchor) == 1, f"chip row found {d.count(chips_anchor)}x"
search_box = ('t("div",{style:{position:"relative",marginBottom:12},children:['
              'e(Ru,{size:15,color:a.muted,style:{position:"absolute",left:12,top:"50%",transform:"translateY(-50%)",pointerEvents:"none"}}),'
              'e("input",{value:mkQ,onChange:mk_ev=>mkSetQ(mk_ev.target.value),'
              "placeholder:'Search courses \\u2014 try maths, SAT, leadership\\u2026',"
              'style:{width:"100%",boxSizing:"border-box",padding:"11px 38px 11px 36px",fontSize:13,fontWeight:600,'
              'borderRadius:10,border:`1.5px solid ${a.bd}`,background:a.card,color:a.txt,outline:"none",fontFamily:"inherit"}}),'
              'mkQ?e("button",{onClick:()=>mkSetQ(""),title:"Clear search",'
              'style:{position:"absolute",right:8,top:"50%",transform:"translateY(-50%)",border:"none",background:"transparent",'
              'cursor:"pointer",color:a.muted,padding:4,lineHeight:0},children:e(Pe,{size:15})}):null]}),')
d = d.replace(chips_anchor, search_box + chips_anchor, 1)

# ===========================================================================
# 4. Empty state should acknowledge the search, not claim "coming soon".
# ===========================================================================
old_empty = 'children:[s?"JAMB (UTME)":o?"General Courses":Ji," \\u2014 coming soon"]})'
assert d.count(old_empty) == 1, f"empty heading found {d.count(old_empty)}x"
d = d.replace(old_empty,
              'children:mkQ?["No course matches \\u201c",mkQ,"\\u201d"]:[s?"JAMB (UTME)":o?"General Courses":Ji," \\u2014 coming soon"]})',
              1)
old_empty_sub = 'children:"Courses in this category are being prepared. Check back soon."})'
assert d.count(old_empty_sub) == 1
d = d.replace(old_empty_sub,
              'children:mkQ?"Try a shorter word, or clear the search to see everything.":"Courses in this category are being prepared. Check back soon."})',
              1)

# ===========================================================================
# 5. Rejection expiry — applied at the three lookup points so every surface
#    (catalogue card, course page, status pill) agrees.
# ===========================================================================
finders = [
    ('Ss=(i,o)=>ga.find(s=>s.kind===i&&s.course===o&&s.userId===y?.id)',
     'Ss=(i,o)=>mkLiveApp(ga.find(s=>s.kind===i&&s.course===o&&s.userId===y?.id))'),
    ('Eo=i=>Gt.find(o=>o.course===i&&o.userId===y?.id)',
     'Eo=i=>mkLiveApp(Gt.find(o=>o.course===i&&o.userId===y?.id))'),
    ('vs=i=>Ct.find(o=>o.journey===i&&o.userId===y?.id)',
     'vs=i=>mkLiveApp(Ct.find(o=>o.journey===i&&o.userId===y?.id))'),
    ('vi=i=>Rr.find(o=>o.journey===i&&o.userId===y?.id)',
     'vi=i=>mkLiveApp(Rr.find(o=>o.journey===i&&o.userId===y?.id))'),
]
for old_f, new_f in finders:
    assert d.count(old_f) == 1, f"finder {old_f[:14]} found {d.count(old_f)}x"
    d = d.replace(old_f, new_f, 1)

# The mapper formats decided_at for display only; keep the raw value too.
old_map = 'decidedAt:i.decided_at?new Date(i.decided_at).toLocaleString():void 0'
# Two mappers: one for course_access_apps, one for exam_apps. Both need it.
assert d.count(old_map) == 2, f"mapper found {d.count(old_map)}x"
d = d.replace(old_map, old_map + ',decidedTs:i.decided_at||null')

# ===========================================================================
# 6. Share icon on every catalogue card.
# ===========================================================================
card_props = ('let N=vs(m),u=Ea(m),E=vi(m),W=jo(m).length,T=vl.has(m);return t("div",'
              '{style:{...k,display:"flex",flexDirection:"column",gap:10,'
              'borderTop:`4px solid ${u?"#059669":"#1842a8"}`,opacity:i&&T?.62:1},children:[')
assert d.count(card_props) == 1, f"card props found {d.count(card_props)}x"

# position:relative on the card so the icon can sit in its corner, then the
# share button as the card's first child.
new_props = ('let N=vs(m),u=Ea(m),E=vi(m),W=jo(m).length,T=vl.has(m);return t("div",'
             '{style:{...k,position:"relative",display:"flex",flexDirection:"column",gap:10,'
             'borderTop:`4px solid ${u?"#059669":"#1842a8"}`,opacity:i&&T?.62:1},children:['
             'e("button",{onClick:mk_ev=>{mk_ev.stopPropagation();mkShareCourse(_a,md,m,x)},'
             'title:"Share this course \u2014 your referral code travels with the link",'
             'style:{position:"absolute",top:8,right:8,zIndex:2,width:29,height:29,borderRadius:"50%",'
             'border:`1px solid ${a.bd}`,background:a.card,color:"#1842a8",cursor:"pointer",'
             'display:"flex",alignItems:"center",justifyContent:"center",padding:0},'
             'children:e(Ne,{size:14})}),')
d = d.replace(card_props, new_props, 1)

with open(SRC, "w", encoding="utf-8", errors="surrogateescape") as fh:
    fh.write(d)
print("patched (share button needs structural verification — see next step)")
