#!/usr/bin/env python3
"""
Two changes.

1. CAROUSEL replaces the "Join the live session" countdown banner.
   Four promotional slides cross-fade, one every 10 seconds, looping forever.
   The component keeps the same name (Id) as the banner it replaces, so both
   existing render sites — the sign-in screen and the guest home banner —
   pick it up with no further edits.

   Responsiveness is handled with a fixed 8:5 aspect ratio box rather than a
   fixed pixel height, so the slides scale cleanly from a 320px phone to a
   wide desktop with no letterboxing and no layout shift as images load.
   A <picture> element serves the 800px file to phones and the 1600px file
   to everything else, halving the download on mobile data.

2. GUEST ACCESS to the Teacher's Course catalogue. Guests already sign in as
   role "visitor-student", so they inherit the student navigation, which
   includes Subjects and General Courses. Teacher's Course sits only in the
   teacher navigation, so it is appended for guests here. Viewing is
   browsing only — the existing approval gate still stops a guest opening
   unit content, which is the correct behaviour.
"""
import re
import sys

SRC = "assets/app.js"
INTERVAL_MS = 10000
SLIDES = [
    ("slide-1", "Digital Skills and Internship led by experts — cybersecurity, digital marketing, web development, AI and more"),
    ("slide-2", "Life Skills for students to be future-ready today — leadership, collaboration, emotional intelligence and more"),
    ("slide-3", "Subject Mastery across the British and Nigerian curriculum — sciences, humanities, mathematics and languages"),
    ("slide-4", "Become a British curriculum-ready teacher — lesson planning, assessment, classroom management and more"),
]

with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
    d = fh.read()

if "mkSlides" in d:
    sys.exit("FAIL: carousel already patched")

# ---------------------------------------------------------------------------
# 1. Replace the countdown component with the carousel.
#    Located by its opening signature and closed by brace matching, so the
#    exact minified body does not need to be reproduced here.
# ---------------------------------------------------------------------------
start_sig = "function Id(){let h=new Date(Pi.target).getTime()"
start = d.find(start_sig)
if start < 0:
    sys.exit("FAIL: countdown component Id() not found")

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
removed = end - start

slides_js = ",".join(
    '{s:"/slides/%s.jpg",m:"/slides/%s-sm.jpg",a:"%s"}' % (n, n, alt.replace('"', '\\"'))
    for n, alt in SLIDES
)

carousel = (
'var mkSlides=[' + slides_js + '];'
'function Id(){'
'var st=f(0),idx=st[0],setIdx=st[1];'
'var pz=f(!1),paused=pz[0],setPaused=pz[1];'
# Respect the OS "reduce motion" setting: hold on the first slide rather than
# cross-fading, for users who get motion sickness or find it distracting.
'var reduce=!1;try{reduce=window.matchMedia&&window.matchMedia("(prefers-reduced-motion: reduce)").matches}catch(x){}'
'de(function(){if(paused||reduce)return;'
'var t=setInterval(function(){setIdx(function(v){return(v+1)%mkSlides.length})},' + str(INTERVAL_MS) + ');'
'return function(){clearInterval(t)}},[paused,reduce]);'
# Preload the next slide so the fade never reveals a half-loaded image.
'de(function(){try{var n=mkSlides[(idx+1)%mkSlides.length];var im=new Image;im.src=n.s}catch(x){}},[idx]);'
'return t("div",{'
'onMouseEnter:function(){setPaused(!0)},onMouseLeave:function(){setPaused(!1)},'
'style:{margin:"0 auto 16px",width:"100%",maxWidth:560,borderRadius:16,overflow:"hidden",'
'position:"relative",background:"#0d1f4b",boxShadow:"0 10px 30px rgba(0,0,0,.25)"},'
'children:['
# Aspect-ratio spacer: reserves the exact height before any image loads, so
# nothing jumps on slow connections. 62.5% == 1000/1600.
'e("div",{style:{width:"100%",paddingTop:"62.5%"}}),'
'mkSlides.map(function(sl,n){return e("picture",{style:{'
'position:"absolute",inset:0,opacity:n===idx?1:0,'
'transition:"opacity 1.1s ease-in-out",pointerEvents:"none"},children:['
'e("source",{media:"(max-width: 640px)",srcSet:sl.m}),'
'e("img",{src:sl.s,alt:sl.a,loading:n===0?"eager":"lazy",decoding:"async",'
'style:{width:"100%",height:"100%",objectFit:"cover",display:"block"}})]},n)}),'
# Dots double as manual controls, sized to stay tappable on a phone.
'e("div",{style:{position:"absolute",left:0,right:0,bottom:10,display:"flex",'
'justifyContent:"center",gap:7},children:mkSlides.map(function(sl,n){'
'return e("button",{onClick:function(){setIdx(n)},'
'"aria-label":"Show slide "+(n+1),'
'style:{width:n===idx?22:9,height:9,borderRadius:99,border:"none",padding:0,cursor:"pointer",'
'background:n===idx?"#fff":"rgba(255,255,255,.5)",transition:"width .3s,background .3s"}},n)})})'
']})}'
)

d = d[:start] + carousel + d[end:]

# ---------------------------------------------------------------------------
# 2. Give guests the Teacher's Course entry.
#    The nav array is built per role then filtered; the filter is the natural
#    place to also extend it, keeping one source of truth for guest nav rules.
# ---------------------------------------------------------------------------
old_filter = '.filter(i=>!(dt&&["profile","refer","downloads","gradebook","messages"].includes(i.id)))'
if d.count(old_filter) != 1:
    sys.exit(f"FAIL: guest nav filter found {d.count(old_filter)}x")
new_filter = (old_filter +
              '.concat(dt?[{id:"training",I:we,l:"Teacher\'s Course"}]:[])')
d = d.replace(old_filter, new_filter, 1)

with open(SRC, encoding="utf-8", errors="surrogateescape", mode="w") as fh:
    fh.write(d)

print(f"  countdown removed   : {removed:,} chars")
print(f"  carousel added      : {len(carousel):,} chars")
print(f"  slides              : {len(SLIDES)}, {INTERVAL_MS//1000}s each, looping")
print(f"  render sites reused : sign-in screen + guest home")
print(f"  guest nav           : Teacher's Course added")
