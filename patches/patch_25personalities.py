#!/usr/bin/env python3
"""
Installs the 25Personalities assessment component (MK25) and points the
view at it, replacing the 28-question iPersonality quiz.

Scoring:
  Each answer adds weighted deltas to up to four of twenty dimensions.
  Raw sums are normalised to 0-100 against the maximum obtainable spread
  for that dimension, so a dimension measured by six questions and one
  measured by twelve are directly comparable.

Type matching:
  Each of the 25 types carries a signature of the dimensions that must run
  high or low. A type's fit is the mean signed agreement between the
  person's normalised score and that signature. The top three become
  primary, secondary and supporting — deliberately not a single label.

Confidence:
  Reported per result from two signals: how completely the questions were
  answered, and how far apart the six consistency pairs sit. Wide
  disagreement lowers confidence rather than being averaged into false
  certainty.
"""
import json
import sys

SRC = "assets/app.js"

with open("mk25data.json", encoding="utf-8") as fh:
    DATA = fh.read()

with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
    d = fh.read()

if "function MK25(" in d:
    sys.exit("FAIL: already patched")

COMPONENT = (
'var MK25D=' + DATA + ';'
# --- scoring -----------------------------------------------------------------
'function mk25Score(ans){'
'var N=MK25D.dims.length,sum=new Array(N).fill(0),max=new Array(N).fill(0);'
'MK25D.qs.forEach(function(q,qi){'
# The maximum this question could contribute to each dimension, used for
# normalisation so dimensions measured by more questions are not inflated.
'var best=new Array(N).fill(0);'
'q.o.forEach(function(o){for(var k in o[1]){var v=Math.abs(o[1][k]);if(v>best[k])best[k]=v}});'
'for(var k2=0;k2<N;k2++)max[k2]+=best[k2];'
'var a=ans[qi];if(a===void 0)return;'
'var m=q.o[a][1];for(var k3 in m)sum[k3]+=m[k3]});'
'return sum.map(function(v,i){'
'if(!max[i])return 50;'
'return Math.max(0,Math.min(100,Math.round(50+v/max[i]*50)))})}'

'function mk25Types(scores){'
'return MK25D.types.map(function(t,i){'
'var n=0,tot=0;'
'for(var k in t.sig){var want=t.sig[k],got=(scores[k]-50)/50;'
'tot+=want>0?Math.min(got/want,1.4):Math.min(got/want,1.4);n++}'
'return{i:i,t:t,fit:n?tot/n:0}})'
'.sort(function(a,b){return b.fit-a.fit})}'

'function mk25Confidence(ans,scores){'
'var answered=Object.keys(ans).length,cov=answered/MK25D.qs.length;'
'var conflict=0;'
'MK25D.pairs.forEach(function(p){'
'var a=ans[p[0]],b=ans[p[1]];if(a===void 0||b===void 0)return;'
'if(Math.abs(a-b)<=1)conflict++});'
'var spread=scores.filter(function(s){return s<35||s>65}).length/scores.length;'
'var lvl=cov<.85?"Low":(conflict>=3||spread<.15)?"Moderate":"High";'
'return{level:lvl,cov:Math.round(cov*100),conflict:conflict}}'

# --- component ---------------------------------------------------------------
'function MK25(props){'
'var T=props.T,card=props.card,bP=props.bP,bO=props.bO,isMobile=props.isMobile;'
'var st=f("intro"),stage=st[0],setStage=st[1];'
'var pg=f(0),page=pg[0],setPage=pg[1];'
'var an=f({}),ans=an[0],setAns=an[1];'
'var PER=6,total=MK25D.qs.length,pages=Math.ceil(total/PER);'
'var answered=Object.keys(ans).length;'
'var result=null;'
'if(stage==="result"){'
'var sc=mk25Score(ans),tp=mk25Types(sc),cf=mk25Confidence(ans,sc);'
'result={scores:sc,types:tp,conf:cf}}'
'function pick(qi,oi){var n=Object.assign({},ans);n[qi]=oi;setAns(n)}'
'var H=function(txt,sub){return t("div",{style:{marginBottom:14},children:['
'e("h2",{style:{fontSize:17,fontWeight:900,fontFamily:"Outfit,sans-serif",color:T.head,margin:"0 0 4px"},children:txt}),'
'sub?e("p",{style:{fontSize:12.5,color:T.muted,margin:0,lineHeight:1.6},children:sub}):null]})};'

# ---- intro
'if(stage==="intro")return t("div",{children:['
'e("div",{style:{background:"linear-gradient(135deg,#0d1f4b,#1842a8)",borderRadius:18,padding:isMobile?18:26,marginBottom:16,color:"#fff"},children:'
't("div",{children:['
'e("div",{style:{fontSize:10,letterSpacing:2,textTransform:"uppercase",opacity:.65,marginBottom:6},children:"MindKlass"}),'
'e("h1",{style:{fontSize:isMobile?26:34,fontWeight:900,fontFamily:"Outfit,sans-serif",margin:"0 0 8px"},children:"25Personalities"}),'
'e("p",{style:{fontSize:14,opacity:.92,margin:0,maxWidth:600,lineHeight:1.65},children:"A 120-question profile across twenty dimensions \\u2014 temperament, thinking, emotion, motivation, values, identity, relationships, influence, culture, environment and life history. You receive three ranked patterns rather than a single label, because people are not one thing."})]})}),'
't("div",{style:Object.assign({},card,{marginBottom:14}),children:['
'H("Before you begin"),'
'e("ul",{style:{margin:0,paddingLeft:18,fontSize:13,color:T.txt,lineHeight:1.85},children:['
'e("li",{children:"Answer as you actually are most often \\u2014 not as you would like to be."}),'
'e("li",{children:"When two answers feel equally true, choose the one true in more situations."}),'
'e("li",{children:"Do not answer according to what sounds impressive. It only distorts your own result."}),'
'e("li",{children:"Takes roughly 15\\u201320 minutes. You can stop and continue on this page."})].map(function(x,i){return e("li",{children:x.props.children},i)})}),'
'e("p",{style:{fontSize:12,color:T.muted,marginTop:12,marginBottom:0,lineHeight:1.6},children:"This is an educational self-reflection tool. It is not a clinical or diagnostic assessment, it does not measure ability, and it cannot identify anyone with certainty. Results describe tendencies and probabilities \\u2014 treat them as a mirror, not a verdict."})]}),'
't("button",{onClick:function(){setStage("quiz")},style:Object.assign({},bP,{padding:"13px 26px",fontSize:14,display:"inline-flex",alignItems:"center",gap:7}),children:["Begin the assessment"]})]});'

# ---- questions
'if(stage==="quiz"){'
'var from=page*PER,slice=MK25D.qs.slice(from,from+PER);'
'var pageDone=slice.every(function(q,i){return ans[from+i]!==void 0});'
'return t("div",{children:['
't("div",{style:Object.assign({},card,{marginBottom:14}),children:['
't("div",{style:{display:"flex",justifyContent:"space-between",fontSize:11.5,fontWeight:800,color:T.muted,marginBottom:7},children:['
'e("span",{children:"Section "+(page+1)+" of "+pages}),'
'e("span",{children:answered+" of "+total+" answered"})]}),'
'e("div",{style:{height:7,borderRadius:99,background:T.alt,overflow:"hidden"},children:'
'e("div",{style:{width:(answered/total*100)+"%",height:"100%",background:"#1842a8",transition:"width .3s"}})})]}),'
'slice.map(function(q,i){var qi=from+i;return t("div",{style:Object.assign({},card,{marginBottom:12}),children:['
'e("div",{style:{fontSize:10,fontWeight:800,color:T.muted,marginBottom:5},children:"QUESTION "+(qi+1)}),'
'e("p",{style:{fontSize:14,fontWeight:700,color:T.head,margin:"0 0 11px",lineHeight:1.5},children:q.q}),'
'e("div",{style:{display:"flex",flexDirection:"column",gap:7},children:q.o.map(function(o,oi){'
'var on=ans[qi]===oi;'
'return e("button",{onClick:function(){pick(qi,oi)},style:{textAlign:"left",padding:"10px 13px",borderRadius:10,cursor:"pointer",'
'fontSize:13,lineHeight:1.45,fontFamily:"inherit",fontWeight:on?800:600,'
'border:on?"2px solid #1842a8":"1.5px solid "+T.bd,'
'background:on?T.pale:T.card,color:on?"#1842a8":T.txt},children:o[0]},oi)})})]},qi)}),'
't("div",{style:{display:"flex",gap:9,flexWrap:"wrap",marginTop:4},children:['
'page>0?e("button",{onClick:function(){setPage(page-1);window.scrollTo(0,0)},style:Object.assign({},bO,{padding:"11px 20px",fontSize:13}),children:"Back"}):null,'
'page<pages-1?e("button",{onClick:function(){setPage(page+1);window.scrollTo(0,0)},'
'style:Object.assign({},pageDone?bP:bO,{padding:"11px 22px",fontSize:13,opacity:pageDone?1:.55}),'
'children:pageDone?"Next section":"Answer all six to continue"}):'
'e("button",{onClick:function(){if(answered<total*.85){alert("Please answer at least 85% of the questions \\u2014 below that the result is not reliable enough to report.");return}setStage("result");window.scrollTo(0,0)},'
'style:Object.assign({},bP,{padding:"12px 24px",fontSize:13.5}),children:"See my profile"})]})]})}'

# ---- result
'var top3=result.types.slice(0,3),conf=result.conf;'
'var confColour=conf.level==="High"?"#059669":conf.level==="Moderate"?"#d97706":"#dc2626";'
'return t("div",{children:['
'e("div",{style:{background:"linear-gradient(135deg,#0d1f4b,#1842a8)",borderRadius:18,padding:isMobile?18:26,marginBottom:14,color:"#fff"},children:'
't("div",{children:['
'e("div",{style:{fontSize:10,letterSpacing:2,textTransform:"uppercase",opacity:.65,marginBottom:6},children:"Your primary pattern"}),'
'e("h1",{style:{fontSize:isMobile?24:31,fontWeight:900,fontFamily:"Outfit,sans-serif",margin:"0 0 10px"},children:top3[0].t.n}),'
't("p",{style:{fontSize:13.5,opacity:.92,margin:0,lineHeight:1.6},children:["Secondary: ",top3[1].t.n," \\u00b7 Supporting: ",top3[2].t.n]})]})}),'

't("div",{style:Object.assign({},card,{marginBottom:12,borderLeft:"4px solid "+confColour}),children:['
'e("div",{style:{fontSize:11,fontWeight:900,color:confColour,textTransform:"uppercase",letterSpacing:.5,marginBottom:4},children:conf.level+" confidence"}),'
'e("p",{style:{fontSize:12.5,color:T.txt,margin:0,lineHeight:1.6},children:'
'conf.level==="High"?"Your answers were consistent across questions measuring the same underlying tendencies, so these patterns are well supported by what you reported.":'
'conf.level==="Moderate"?"Some answers pointed in different directions on questions measuring the same tendency. That usually means your behaviour is genuinely context-dependent \\u2014 real, but it makes a single label less meaningful.":'
'"You left a number of questions unanswered, or your answers varied widely. Treat this profile as a rough sketch rather than a reading."}),'
'e("p",{style:{fontSize:11.5,color:T.muted,margin:"7px 0 0"},children:conf.cov+"% of questions answered \\u00b7 "+conf.conflict+" of "+MK25D.pairs.length+" consistency checks showed tension"})]}),'

'top3.map(function(r,i){return t("div",{style:Object.assign({},card,{marginBottom:12}),children:['
'e("div",{style:{fontSize:10,fontWeight:800,color:T.muted,textTransform:"uppercase",letterSpacing:.5,marginBottom:3},children:i===0?"Primary":i===1?"Secondary":"Supporting"}),'
'e("h3",{style:{fontSize:16,fontWeight:900,fontFamily:"Outfit,sans-serif",color:T.head,margin:"0 0 10px"},children:r.t.n}),'
'e("div",{style:{fontSize:11,fontWeight:800,color:"#059669",marginBottom:4},children:"STRENGTHS"}),'
'e("p",{style:{fontSize:13,color:T.txt,margin:"0 0 10px",lineHeight:1.6},children:r.t.s.join(" \\u00b7 ")}),'
'e("div",{style:{fontSize:11,fontWeight:800,color:"#d97706",marginBottom:4},children:"POTENTIAL VULNERABILITIES"}),'
'e("p",{style:{fontSize:13,color:T.txt,margin:"0 0 10px",lineHeight:1.6},children:r.t.w.join(" \\u00b7 ")}),'
'e("div",{style:{fontSize:11,fontWeight:800,color:"#1842a8",marginBottom:4},children:"ENVIRONMENTS THAT MAY SUIT YOU"}),'
'e("p",{style:{fontSize:13,color:T.txt,margin:"0 0 10px",lineHeight:1.6},children:r.t.c.join(" \\u00b7 ")}),'
'e("div",{style:{fontSize:11,fontWeight:800,color:"#7c3aed",marginBottom:4},children:"RELATIONSHIP ENVIRONMENT"}),'
'e("p",{style:{fontSize:13,color:T.txt,margin:0,lineHeight:1.6},children:r.t.r})]},i)}),'

't("div",{style:Object.assign({},card,{marginBottom:12}),children:['
'H("Your twenty dimensions","Each is measured by many questions. Scores near the middle mean the tendency is balanced or context-dependent, which is a real finding rather than a missing one."),'
'e("div",{style:{display:"flex",flexDirection:"column",gap:9},children:MK25D.dims.map(function(dm,i){'
'var v=result.scores[i];'
'return t("div",{children:['
't("div",{style:{display:"flex",justifyContent:"space-between",fontSize:11.5,fontWeight:700,color:T.txt,marginBottom:3},children:['
'e("span",{children:dm[0]}),e("span",{style:{color:T.muted},children:v})]}),'
'e("div",{style:{height:6,borderRadius:99,background:T.alt,overflow:"hidden"},children:'
'e("div",{style:{width:v+"%",height:"100%",background:v>65?"#1842a8":v<35?"#7c3aed":"#94a3b8"}})}),'
'e("div",{style:{display:"flex",justifyContent:"space-between",fontSize:10,color:T.muted,marginTop:2},children:'
'[e("span",{children:dm[1]},0),e("span",{children:dm[2]},1)]})]},i)})})]}),'

't("div",{style:Object.assign({},card,{marginBottom:12}),children:['
'H("How to read this"),'
'e("p",{style:{fontSize:13,color:T.txt,margin:"0 0 8px",lineHeight:1.65},children:"Four different things get confused when people read results like this, so separate them deliberately: who you tend to be, who you are becoming, what your circumstances are currently forcing you to be, and who you would like to be. They are rarely the same, and this assessment mostly measures the first."}),'
'e("p",{style:{fontSize:13,color:T.txt,margin:"0 0 8px",lineHeight:1.65},children:"Career suggestions are environments worth exploring, not predictions. They should be tested against your actual skills, education, interests and the opportunities genuinely available to you."}),'
'e("p",{style:{fontSize:12.5,color:T.muted,margin:0,lineHeight:1.6},children:"Personality shifts over time and behaves differently across contexts. If this result surprises you, that is worth thinking about \\u2014 but it is not evidence about you that outweighs your own experience of yourself."})]}),'

't("div",{style:{display:"flex",gap:9,flexWrap:"wrap"},children:['
'e("button",{onClick:function(){setAns({});setPage(0);setStage("intro");window.scrollTo(0,0)},'
'style:Object.assign({},bO,{padding:"11px 20px",fontSize:13}),children:"Take it again"}),'
'e("button",{onClick:function(){try{navigator.clipboard.writeText("My 25Personalities profile on MindKlass: "+top3[0].t.n+" (primary), "+top3[1].t.n+" (secondary). Find yours: https://www.mindklass.com/25Personalities");alert("Copied \\u2014 your result summary is on the clipboard.")}catch(x){}},'
'style:Object.assign({},bP,{padding:"11px 20px",fontSize:13}),children:"Share my result"})]})]})}'
)

anchor = 'import{Fragment as D,jsx as e,jsxs as t}from"react/jsx-runtime";'
if anchor not in d:
    sys.exit("FAIL: jsx anchor missing")
d = d.replace(anchor, anchor + COMPONENT, 1)

# Point the view at the new component.
old_view = 'if(G==="ipersonality")return J({children:e(pg,{T:a,isMobile:X,card:k,bP:C,bO:R})});'
if d.count(old_view) != 1:
    sys.exit(f"FAIL: ipersonality view found {d.count(old_view)}x")
d = d.replace(old_view,
              'if(G==="ipersonality")return J({children:e(MK25,{T:a,isMobile:X,card:k,bP:C,bO:R})});', 1)

with open(SRC, "w", encoding="utf-8", errors="surrogateescape") as fh:
    fh.write(d)

payload = json.loads(DATA)
print(f"  questions   : {len(payload['qs'])}")
print(f"  dimensions  : {len(payload['dims'])}")
print(f"  types       : {len(payload['types'])}")
print(f"  component   : {len(COMPONENT):,} chars")
