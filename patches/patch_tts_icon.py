#!/usr/bin/env python3
"""
Text-to-speech: icon only, and visible wherever an approved learner lands.

TWO CHANGES

1. SIMPLIFIED CONTROL. The player is now a single round icon button:
   speaker to start, pause to pause, speaker again to resume. The label,
   the separate Stop button, the progress bar and the HD badge are gone.

2. VISIBILITY. The old button existed ONLY inside a unit page. An approved
   learner opening a course lands on the course overview (the unit list)
   and would never see it there — while an admin, who bypasses the
   approval gate entirely and browses differently, always did. That
   asymmetry is what made it look admin-only.

   The icon is now also rendered on the course overview header, reading
   the course title, tagline and what the course covers. So any approved
   learner meets it on the first screen of the course.

The component never returns null any more. If a browser genuinely cannot
speak, the icon still renders and explains itself on click, rather than
vanishing and looking like a missing feature.
"""
import re
import sys

SRC = "assets/app.js"

with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
    d = fh.read()

if "mkSpeakIcon" in d:
    sys.exit("FAIL: already patched")

# ---------------------------------------------------------------------------
# 1. Replace the MKV component body with the icon-only version.
# ---------------------------------------------------------------------------
start = d.index("function MKV(props){")
i = d.index("{", start + len("function MKV(props)"))
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

NEW = (
'function MKV(props){var mkSpeakIcon=1;'
'var id=props.id,text=props.text,size=props.size||34;'
'var st=f("idle"),mode=st[0],setMode=st[1];'
'var sg=f(null),seg=sg[0],setSeg=sg[1];'
'var audio=Re(null),chunks=Re([]),ci=Re(0),live=Re(!0);'
'var supported=typeof window<"u"&&typeof window.speechSynthesis<"u";'
'de(function(){live.current=!0;mkLoadVoiceManifest().then(function(m){'
'if(!live.current)return;setSeg((m.segments||[]).filter(function(s){return s.id===id})[0]||null)});'
'return function(){live.current=!1}},[id]);'
'function hardStop(){try{window.speechSynthesis.cancel()}catch(x){}'
'if(audio.current){try{audio.current.pause()}catch(x){}audio.current.currentTime=0}'
'ci.current=0;setMode("idle")}'
'de(function(){mkVoiceStoppers.add(hardStop);return function(){mkVoiceStoppers.delete(hardStop);hardStop()}},[]);'
'function speakFrom(i2){var v=mkFemaleVoice();'
'function nxt(){if(i2>=chunks.current.length){setMode("idle");ci.current=0;return}'
'ci.current=i2;var u=new SpeechSynthesisUtterance(chunks.current[i2]);'
'if(v)u.voice=v;u.rate=.95;u.pitch=1.05;u.volume=1;'
'u.onend=function(){i2++;nxt()};u.onerror=function(){setMode("idle")};'
'try{window.speechSynthesis.speak(u)}catch(x){setMode("idle")}}nxt()}'
'function play(){'
# Only one thing speaks at a time across the whole page.
'mkVoiceStoppers.forEach(function(s){if(s!==hardStop)try{s()}catch(x){}});'
'if(seg){if(!audio.current){var a=new Audio(seg.file);a.preload="none";'
'a.addEventListener("ended",function(){setMode("idle")});'
'a.addEventListener("error",function(){setMode("idle")});audio.current=a}'
'audio.current.play().then(function(){setMode("playing")}).catch(function(){setMode("idle")});return}'
'if(!supported){alert("Read-aloud is not available in this browser. Try Chrome, Edge or Safari.");return}'
'var raw=String(text||"").replace(/\\s+/g," ").trim();'
'if(!raw){alert("There is no text to read on this page yet.");return}'
'if(!chunks.current.length||ci.current===0)chunks.current=raw.match(/[^.!?]+[.!?]*/g)||[raw];'
'try{window.speechSynthesis.cancel()}catch(x){}'
'setMode("playing");speakFrom(ci.current||0)}'
'function pause(){if(seg&&audio.current){try{audio.current.pause()}catch(x){}setMode("paused");return}'
# speechSynthesis.pause() is unreliable on Android, so remember the sentence
# and cancel; resuming restarts from there rather than from the beginning.
'try{window.speechSynthesis.cancel()}catch(x){}setMode("paused")}'
'return e("button",{onClick:function(ev){ev.stopPropagation();mode==="playing"?pause():play()},'
'title:mode==="playing"?"Pause":mode==="paused"?"Resume reading":"Listen to this page",'
'"aria-label":mode==="playing"?"Pause reading":"Listen to this page",'
'style:{width:size,height:size,borderRadius:"50%",flexShrink:0,cursor:"pointer",padding:0,'
'display:"inline-flex",alignItems:"center",justifyContent:"center",'
'border:mode==="idle"?"1.5px solid #1842a8":"2px solid #1842a8",'
'background:mode==="idle"?"transparent":"#1842a8",'
'color:mode==="idle"?"#1842a8":"#fff",transition:"all .18s"},'
'children:mode==="playing"?e(Bu,{size:Math.round(size*.45)}):e(Gd,{size:Math.round(size*.45)})})}'
)
d = d[:start] + NEW + d[end:]

# The renderer no longer needs a label or button style.
old_qs = 'qs=(i,o,s="Listen")=>e(MKV,{id:i,text:o,label:s,btn:R},"spk_"+i)'
if d.count(old_qs) != 1:
    sys.exit(f"FAIL: qs renderer found {d.count(old_qs)}x")
d = d.replace(old_qs, 'qs=(i,o,s="Listen")=>e(MKV,{id:i,text:o},"spk_"+i)', 1)

# ---------------------------------------------------------------------------
# 2. Put the icon on the course overview page, where approved learners land.
# ---------------------------------------------------------------------------
anchor = 'if(Wt==="course"&&$){let l=Ce[$],n=jo($),c=Xl($),p=vi($);return Ea($)?J({children:t(D,{children:['
if d.count(anchor) != 1:
    sys.exit(f"FAIL: course overview anchor found {d.count(anchor)}x")
# Reads the course itself: title, tagline, and the unit titles with summaries.
listen = ('e("div",{style:{display:"flex",justifyContent:"flex-end",marginBottom:8},children:'
          'qs("course_"+$,(l.title||"")+". "+(l.tagline||"")+" This course has "+l.units.length+" units. "'
          '+l.units.map(function(u){return "Unit "+u.n+": "+u.title+". "+(u.summary||"")}).join(" "))}),')
d = d.replace(anchor, anchor + listen, 1)

with open(SRC, "w", encoding="utf-8", errors="surrogateescape") as fh:
    fh.write(d)

print("  player            : icon only (speaker / pause), no label, no stop, no bar")
print("  never returns null: unsupported browsers explain on click")
print("  course overview   : Listen icon added (reads title, tagline, unit list)")
print("  unit pages        : unchanged, now icon-only")
