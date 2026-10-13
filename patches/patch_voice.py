#!/usr/bin/env python3
"""
Injects the MindKlass voice player into the minified production bundle.

Three edits, all surgical:
  1. Insert a self-contained MKV component + manifest loader after the imports.
  2. Replace the qs(...) Listen-button renderer so it uses MKV.
  3. Make As() (stop-all) also stop any playing MP3.

Everything else in the 5 MB bundle is left byte-for-byte untouched.
"""
import re
import sys

SRC = "assets/app.js"

# ---------------------------------------------------------------------------
# The component. Written in the same plain-JS style as the bundle so it can sit
# at module scope next to the minified code. It uses only module-level aliases:
#   f = useState, de = useEffect, Re = useRef
#   e = jsx, t = jsxs, D = Fragment
#   Gd = Volume2 icon, Bu = Pause icon
# ---------------------------------------------------------------------------
COMPONENT = r'''
var mkVoiceManifest=null,mkVoiceLoading=null,mkVoiceStoppers=new Set;
function mkLoadVoiceManifest(){
if(mkVoiceManifest)return Promise.resolve(mkVoiceManifest);
if(mkVoiceLoading)return mkVoiceLoading;
mkVoiceLoading=fetch("/voice/manifest.json",{cache:"no-store"}).then(function(r){return r.ok?r.json():null}).then(function(j){mkVoiceManifest=j&&j.segments?j:{segments:[]};return mkVoiceManifest}).catch(function(){mkVoiceManifest={segments:[]};return mkVoiceManifest});
return mkVoiceLoading}
function mkStopAllVoice(){mkVoiceStoppers.forEach(function(s){try{s()}catch(x){}})}
function mkFemaleVoice(){try{
var vs=window.speechSynthesis.getVoices()||[];if(!vs.length)return null;
var en=vs.filter(function(v){return /^en([-_]|$)/i.test(v.lang||"")});var pool=en.length?en:vs;
var fem=/(female|\bwoman\b|samantha|karen|victoria|zira|susan|linda|catherine|serena|tessa|fiona|moira|amelie|joana|aria|jenny|sonia|libby|emma|ava|natasha|clara|google uk english female|google us english)/i;
var male=/(\bmale\b|\bman\b|daniel|david|alex|fred|thomas|oliver|arthur|george|rishi|guy|ryan|eric|mark|google uk english male)/i;
function sc(v){var n=v.name||"",s=0;if(fem.test(n))s+=12;if(male.test(n))s-=10;if(/natural|neural/i.test(n))s+=6;if(/google/i.test(n))s+=4;if(/^en-GB/i.test(v.lang||""))s+=2;if(/^en-US/i.test(v.lang||""))s+=1;if(v.localService===!1)s+=1;return s}
return pool.slice().sort(function(a,b){return sc(b)-sc(a)})[0]||pool[0]}catch(x){return null}}
function MKV(props){
var id=props.id,text=props.text,label=props.label||"Listen",btn=props.btn||{};
var st=f("idle"),mode=st[0],setMode=st[1];
var pg=f(0),prog=pg[0],setProg=pg[1];
var sg=f(null),seg=sg[0],setSeg=sg[1];
var audio=Re(null),chunks=Re([]),ci=Re(0),live=Re(!0);
var supported=typeof window<"u"&&typeof window.speechSynthesis<"u";
de(function(){live.current=!0;mkLoadVoiceManifest().then(function(m){
if(!live.current)return;var hit=(m.segments||[]).filter(function(s){return s.id===id})[0]||null;setSeg(hit)});
return function(){live.current=!1}},[id]);
function hardStop(){
try{window.speechSynthesis.cancel()}catch(x){}
if(audio.current){try{audio.current.pause()}catch(x){}audio.current.currentTime=0}
ci.current=0;setProg(0);setMode("idle")}
de(function(){mkVoiceStoppers.add(hardStop);return function(){mkVoiceStoppers.delete(hardStop);hardStop()}},[]);
function ensureAudio(){
if(audio.current)return audio.current;
var a=new Audio(seg.file);a.preload="none";
a.addEventListener("timeupdate",function(){if(a.duration)setProg(a.currentTime/a.duration*100)});
a.addEventListener("ended",function(){setMode("idle");setProg(0)});
a.addEventListener("error",function(){setMode("idle")});
audio.current=a;return a}
function speakFrom(i){
var v=mkFemaleVoice();
function next(){
if(i>=chunks.current.length){setMode("idle");setProg(0);ci.current=0;return}
ci.current=i;setProg(i/chunks.current.length*100);
var u=new SpeechSynthesisUtterance(chunks.current[i]);
if(v)u.voice=v;u.rate=.95;u.pitch=1.05;u.volume=1;
u.onend=function(){i++;next()};
u.onerror=function(){setMode("idle")};
try{window.speechSynthesis.speak(u)}catch(x){setMode("idle")}}
next()}
function play(){
mkVoiceStoppers.forEach(function(s){if(s!==hardStop)try{s()}catch(x){}});
if(seg){var a=ensureAudio();a.play().then(function(){setMode("playing")}).catch(function(){setMode("idle")});return}
if(!supported){alert("Sorry \u2014 this browser doesn't support read-aloud. Try Chrome, Edge or Safari.");return}
var raw=String(text||"").replace(/\s+/g," ").trim();if(!raw)return;
if(!chunks.current.length||ci.current===0)chunks.current=raw.match(/[^.!?]+[.!?]*/g)||[raw];
try{window.speechSynthesis.cancel()}catch(x){}
setMode("playing");speakFrom(ci.current||0)}
function pause(){
if(seg&&audio.current){try{audio.current.pause()}catch(x){}setMode("paused");return}
try{window.speechSynthesis.cancel()}catch(x){}
setMode("paused")}
function toggle(){mode==="playing"?pause():play()}
if(!supported&&!seg)return null;
var bar=e("div",{onClick:function(ev){
if(!seg||!audio.current||!audio.current.duration)return;
var r=ev.currentTarget.getBoundingClientRect();
audio.current.currentTime=(ev.clientX-r.left)/r.width*audio.current.duration},
style:{flex:1,minWidth:70,height:6,borderRadius:4,background:"#dbe6ff",overflow:"hidden",cursor:seg?"pointer":"default"},
children:e("div",{style:{width:prog+"%",height:"100%",background:"#1842a8",transition:"width .15s linear"}})});
return t("span",{style:{display:"inline-flex",alignItems:"center",gap:8,flexWrap:"wrap",maxWidth:340},children:[
e("button",{onClick:toggle,title:seg?"Studio narration \u00b7 "+id:"Read aloud \u00b7 "+id,
style:Object.assign({},btn,{padding:"7px 13px",fontSize:12,display:"inline-flex",alignItems:"center",gap:6}),
children:mode==="playing"?t(D,{children:[e(Bu,{size:13}),"Pause"]}):t(D,{children:[e(Gd,{size:13}),mode==="paused"?"Resume":label]})}),
mode!=="idle"?e("button",{onClick:hardStop,title:"Stop",style:Object.assign({},btn,{padding:"7px 10px",fontSize:11}),children:"Stop"}):null,
mode!=="idle"?bar:null,
seg?e("span",{style:{fontSize:10,color:"#64748b",fontWeight:700,letterSpacing:.3},children:"HD"}):null]})}
'''

def main():
    with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
        d = fh.read()
    original_len = len(d)

    # --- 1. insert the component just after the react/jsx-runtime import ------
    anchor = 'import{Fragment as D,jsx as e,jsxs as t}from"react/jsx-runtime";'
    if anchor not in d:
        sys.exit("FAIL: jsx-runtime import anchor not found")
    if "function MKV(" in d:
        sys.exit("FAIL: bundle already patched")
    d = d.replace(anchor, anchor + COMPONENT, 1)

    # --- 2. swap the Listen-button renderer ----------------------------------
    start_marker = 'qs=(i,o,s="Listen")=>'
    end_marker = ',"spk_"+i):null'
    s = d.index(start_marker)
    end = d.index(end_marker, s) + len(end_marker)
    replacement = 'qs=(i,o,s="Listen")=>e(MKV,{id:i,text:o,label:s,btn:R},"spk_"+i)'
    removed = end - s
    d = d[:s] + replacement + d[end:]

    # --- 3. make the global stop also stop MP3 playback ----------------------
    old_as = 'As=()=>{try{window.speechSynthesis.cancel()}catch{}oo(null)}'
    if d.count(old_as) != 1:
        sys.exit(f"FAIL: As() stop-all found {d.count(old_as)} times")
    d = d.replace(old_as,
                  'As=()=>{try{window.speechSynthesis.cancel()}catch{}try{mkStopAllVoice()}catch{}oo(null)}')

    with open(SRC, "w", encoding="utf-8", errors="surrogateescape") as fh:
        fh.write(d)

    print(f"  component inserted      : {len(COMPONENT)} chars")
    print(f"  qs() renderer replaced  : {removed} chars removed (incl. gender toggle)")
    print(f"  As() stop-all patched   : yes")
    print(f"  bundle {original_len} -> {len(d)} bytes")


if __name__ == "__main__":
    main()
