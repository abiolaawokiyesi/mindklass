/*MK-MOBILE-BEGIN*/
/* Mobile shell (side drawer + floating bottom tabs), the Ada tutor view and the
   Student Subjects tiles. Everything here is plain functions that use the app's
   own React (f = useState, de = useEffect) and JSX runtime (e, t), so it can sit
   at module level and be called from the main component. */
function MkAdaIcon(p){var s=p.size||16;return e("svg",{width:s,height:s,viewBox:"0 0 24 24",fill:"none",stroke:p.color||"currentColor",strokeWidth:2,strokeLinecap:"round",strokeLinejoin:"round",style:p.style,children:[e("circle",{cx:12,cy:8,r:4},"a"),e("path",{d:"M4 21v-1a6 6 0 0 1 6-6h4a6 6 0 0 1 6 6v1"},"b"),e("path",{d:"M10 7.6h.01M14 7.6h.01"},"c")]})}
function MkMenuIcon(p){var s=p.size||18;return e("svg",{width:s,height:s,viewBox:"0 0 24 24",fill:"none",stroke:p.color||"currentColor",strokeWidth:2.2,strokeLinecap:"round",style:p.style,children:[e("path",{d:"M4 7h16"},"a"),e("path",{d:"M4 12h16"},"b"),e("path",{d:"M4 17h10"},"c")]})}
function mkWithAda(role,list){try{if(role==="parent"||!role)return list;var out=list.slice();if(!out.some(function(i){return i.id==="progress"})){var h=out.findIndex(function(i){return i.id==="home"});out.splice(h>=0?h+1:0,0,{id:"progress",I:pt,l:role==="admin"?"All Progress":"My Progress"})}if(!out.some(function(i){return i.id==="ada"})){var at=out.findIndex(function(i){return i.id==="learn"});out.splice(at>=0?at+1:Math.min(1,out.length),0,{id:"ada",I:MkAdaIcon,l:"Ask Ada"})}return out}catch(x){return list}}
var MK_NAV_GROUPS=[["General",["home","progress","courses","learn","general","jamb","training","ada"]],["Study",["assignments","quiz","gradebook","attendance","behavior","child","downloads","games","whiteboard","ipersonality"]],["Manage",["users","staffperf","staffhub","approvals","coursebuilder","exams","fees","push"]],["Connect",["community","messages","meetings","careers","blog","refer"]],["Account",["profile"]]];
var MK_TABS={student:["home","learn","ada","progress"],teacher:["home","courses","ada","learn"],admin:["home","users","progress","approvals"],parent:["home","child","gradebook","messages"],professional:["home","general","ada","quiz"]};
var MK_TAB_LABEL={home:"Home",progress:"Progress",courses:"Courses",learn:"Subjects",general:"General",ada:"Ada",users:"Users",approvals:"Approvals",child:"My Child",gradebook:"Report",messages:"Messages",quiz:"Tests"};
var MK_ROLE_LABEL={student:"Student",teacher:"Teacher",admin:"Administrator",parent:"Parent",professional:"Professional"};
function MkBottomNav(p){
  var a=p.a,ids=MK_TABS[p.role]||MK_TABS.student;
  var tabs=ids.map(function(id){return p.items.find(function(x){return x.id===id})}).filter(Boolean);
  var tabBtn=function(i){
    var on=p.active===i.id,isAda=i.id==="ada";
    return e("button",{onClick:function(){p.go(i.id)},"aria-label":i.l,"aria-current":on?"page":void 0,style:{display:"flex",alignItems:"center",justifyContent:"center",gap:7,height:44,minWidth:44,padding:on?"0 16px":"0 11px",borderRadius:16,border:"none",cursor:"pointer",background:on?"#1842a8":"transparent",color:on?"#fff":a.muted,fontFamily:"Nunito,sans-serif",fontWeight:800,fontSize:12,transition:"all .18s",flexShrink:0},children:[
      isAda&&!on?e("span",{style:{width:30,height:30,borderRadius:"50%",background:"linear-gradient(135deg,#059669,#2158e8)",display:"flex",alignItems:"center",justifyContent:"center"},children:e(i.I,{size:17,color:"#fff"})}):e(i.I,{size:20}),
      on&&e("span",{style:{whiteSpace:"nowrap"},children:MK_TAB_LABEL[i.id]||i.l})]},i.id)
  };
  var menu=e("button",{onClick:p.onMenu,"aria-label":"Open menu",style:{position:"relative",display:"flex",alignItems:"center",justifyContent:"center",height:44,minWidth:44,padding:"0 11px",borderRadius:16,border:"none",cursor:"pointer",background:"transparent",color:a.muted,flexShrink:0},children:[e(MkMenuIcon,{size:20}),p.badge>0&&e("span",{style:{position:"absolute",top:7,right:8,width:9,height:9,borderRadius:"50%",background:"#dc2626",border:"2px solid "+a.card}})]},"menu");
  return e("nav",{"aria-label":"Main",style:{position:"fixed",left:10,right:10,bottom:"calc(10px + env(safe-area-inset-bottom, 0px))",zIndex:40,background:a.card,borderRadius:24,padding:"7px 8px",display:"flex",alignItems:"center",justifyContent:"space-between",gap:2,boxShadow:"0 10px 30px rgba(6,13,30,.22), 0 0 0 1px "+a.border},children:tabs.map(tabBtn).concat([menu])});
}
function MkDrawer(p){
  var a=p.a;if(!p.open)return null;
  var groups=[],used={};
  MK_NAV_GROUPS.forEach(function(g){var its=p.items.filter(function(i){return g[1].indexOf(i.id)>=0});its.forEach(function(i){used[i.id]=1});if(its.length)groups.push([g[0],its])});
  var rest=p.items.filter(function(i){return!used[i.id]});if(rest.length)groups.push(["More",rest]);
  var nm=(p.user&&(p.user.name||p.user.nick))||"Guest";
  var ini=String(nm).trim().split(/\s+/).slice(0,2).map(function(w){return w.charAt(0).toUpperCase()}).join("")||"G";
  var sub=p.guest?"Visitor mode - log in to save your progress":(MK_ROLE_LABEL[p.role]||"Learner");
  var go=function(id){p.go(id);p.close()};
  var row=function(i){
    var on=p.active===i.id;
    return e("button",{onClick:function(){go(i.id)},style:{width:"100%",display:"flex",alignItems:"center",gap:12,padding:"11px 12px",borderRadius:14,border:"none",cursor:"pointer",textAlign:"left",background:on?a.pale:"transparent",color:on?"#1842a8":a.txt,fontFamily:"Nunito,sans-serif",fontSize:14,fontWeight:on?800:600,marginBottom:2},children:[
      e(i.I,{size:18,style:{flexShrink:0,color:on?"#1842a8":a.muted}}),
      e("span",{style:{flex:1},children:i.l}),
      i.id==="community"&&p.badge>0&&e("span",{style:{minWidth:18,height:18,borderRadius:99,background:"#dc2626",color:"#fff",fontSize:10,fontWeight:800,display:"flex",alignItems:"center",justifyContent:"center",padding:"0 5px"},children:p.badge>9?"9+":p.badge}),
      i.id==="ada"&&e("span",{style:{fontSize:9,fontWeight:800,color:"#059669",background:"rgba(5,150,105,.14)",padding:"2px 7px",borderRadius:99},children:"AI TUTOR"})]},i.id)
  };
  var share=function(){try{var u=location.origin;if(navigator.share)navigator.share({title:"MindKlass",text:"Learn with MindKlass",url:u}).catch(function(){});else if(navigator.clipboard)navigator.clipboard.writeText(u)}catch(x){}};
  return e("div",{style:{position:"fixed",inset:0,zIndex:9000,display:"flex"},role:"dialog","aria-modal":"true","aria-label":"Menu",children:[
    e("style",{children:"@keyframes mkSlideIn{from{transform:translateX(-100%)}to{transform:translateX(0)}}@keyframes mkFadeIn{from{opacity:0}to{opacity:1}}"}),
    e("div",{onClick:p.close,style:{position:"absolute",inset:0,background:"rgba(6,13,30,.55)",animation:"mkFadeIn .2s ease"}}),
    t("div",{style:{position:"relative",width:"min(86vw,340px)",height:"100%",background:a.card,display:"flex",flexDirection:"column",animation:"mkSlideIn .24s ease",boxShadow:"8px 0 40px rgba(0,0,0,.35)",borderRadius:"0 28px 28px 0",overflow:"hidden"},children:[
      t("div",{style:{background:"linear-gradient(160deg,#0d1f4b,#1842a8)",padding:"16px 18px 40px",borderRadius:"0 0 50% 50% / 0 0 30px 30px",flexShrink:0},children:[
        t("div",{style:{display:"flex",alignItems:"center",justifyContent:"space-between"},children:[p.logo,e("button",{onClick:p.close,"aria-label":"Close menu",style:{background:"rgba(255,255,255,.14)",border:"none",borderRadius:10,width:32,height:32,display:"flex",alignItems:"center",justifyContent:"center",cursor:"pointer"},children:e(Pe,{size:16,color:"#fff"})})]}),
        t("div",{style:{textAlign:"center",marginTop:14},children:[
          e("div",{style:{width:60,height:60,borderRadius:"50%",background:"#fff",color:"#1842a8",fontWeight:900,fontSize:21,fontFamily:"Outfit,sans-serif",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 8px",boxShadow:"0 4px 14px rgba(0,0,0,.25)"},children:ini}),
          e("div",{style:{color:"#fff",fontWeight:900,fontSize:16,fontFamily:"Outfit,sans-serif"},children:nm}),
          e("div",{style:{color:"rgba(255,255,255,.75)",fontSize:12,marginTop:2},children:sub})]})]}),
      t("div",{style:{flex:1,overflowY:"auto",padding:"8px 14px 10px",WebkitOverflowScrolling:"touch"},children:[
        groups.map(function(g){return t("div",{style:{marginTop:12},children:[e("div",{style:{fontSize:11,fontWeight:800,letterSpacing:.6,textTransform:"uppercase",color:a.muted,padding:"0 12px 6px"},children:g[0]}),g[1].map(row)]},g[0])}),
        e("div",{style:{height:1,background:a.border,margin:"12px 4px"}}),
        t("button",{onClick:p.toggleTheme,style:{width:"100%",display:"flex",alignItems:"center",gap:12,padding:"11px 12px",borderRadius:14,border:"none",cursor:"pointer",background:"transparent",color:a.txt,fontFamily:"Nunito,sans-serif",fontSize:14,fontWeight:600,textAlign:"left"},children:[p.dark?e(Os,{size:18,style:{color:a.muted}}):e(Fs,{size:18,style:{color:a.muted}}),p.dark?"Light mode":"Dark mode"]}),
        p.guest?t("button",{onClick:function(){p.close();p.onLogin()},style:{width:"100%",display:"flex",alignItems:"center",gap:12,padding:"11px 12px",borderRadius:14,border:"none",cursor:"pointer",background:"transparent",color:"#1842a8",fontFamily:"Nunito,sans-serif",fontSize:14,fontWeight:800,textAlign:"left"},children:[e(No,{size:18,style:{transform:"scaleX(-1)"}}),"Log in or create account"]}):t("button",{onClick:function(){p.close();p.onLogout()},style:{width:"100%",display:"flex",alignItems:"center",gap:12,padding:"11px 12px",borderRadius:14,border:"none",cursor:"pointer",background:"transparent",color:"#e11d48",fontFamily:"Nunito,sans-serif",fontSize:14,fontWeight:800,textAlign:"left"},children:[e(No,{size:18}),"Sign out"]})]}),
      t("div",{style:{display:"flex",gap:10,padding:"12px 14px calc(14px + env(safe-area-inset-bottom, 0px))",borderTop:"1px solid "+a.border,flexShrink:0},children:[
        e("button",{onClick:function(){go("ada")},style:{flex:1,border:"none",borderRadius:99,padding:"11px 10px",background:"#059669",color:"#fff",fontWeight:800,fontSize:13,cursor:"pointer",fontFamily:"Nunito,sans-serif"},children:"Ask Ada"}),
        e("button",{onClick:share,style:{flex:1,borderRadius:99,padding:"11px 10px",background:"transparent",border:"1.5px solid "+a.border,color:a.txt,fontWeight:700,fontSize:13,cursor:"pointer",fontFamily:"Nunito,sans-serif"},children:"Share app"})]})]})]});
}
function MkAda(p){
  var a=p.a,k=p.k,X=p.X;
  var url=String((typeof window!=="undefined"&&window.MK_ADA_URL)||"").replace(/\/+$/,"");
  var s1=f(url?"checking":"off"),state=s1[0],setState=s1[1];
  var s2=f(0),tick=s2[0],setTick=s2[1];
  var s3=f(null),info=s3[0],setInfo=s3[1];
  de(function(){
    if(!url)return;var dead=!1,c=new AbortController(),tm=setTimeout(function(){c.abort()},9000);
    setState("checking");
    fetch(url+"/api/health",{signal:c.signal,cache:"no-store"}).then(function(r){if(!r.ok)throw 0;return r.json()}).then(function(j){if(!dead){setInfo(j);setState("ready")}}).catch(function(){if(!dead)setState("down")}).then(function(){clearTimeout(tm)});
    return function(){dead=!0;clearTimeout(tm);try{c.abort()}catch(x){}}
  },[url,tick]);
  var head=t("div",{style:{background:"linear-gradient(135deg,#0d1f4b,#1842a8)",borderRadius:18,padding:X?"16px":"22px",marginBottom:14,color:"#fff",display:"flex",gap:12,alignItems:"center"},children:[
    e("div",{style:{width:46,height:46,borderRadius:"50%",background:"rgba(255,255,255,.16)",display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0},children:e(MkAdaIcon,{size:24,color:"#fff"})}),
    t("div",{children:[e("h1",{style:{fontSize:X?18:22,fontWeight:900,fontFamily:"Outfit,sans-serif",margin:0},children:"Ask Ada - your live tutor"}),e("p",{style:{fontSize:12.5,margin:"3px 0 0",color:"rgba(255,255,255,.82)",lineHeight:1.5},children:"Talk or type. Ada teaches your lessons out loud, answers questions and explains in your own language."})]})]});
  var card=function(title,body,extra){return t("div",{style:{...k,textAlign:"center",padding:"26px 18px"},children:[e("div",{style:{fontSize:15,fontWeight:900,color:a.head,fontFamily:"Outfit,sans-serif",marginBottom:6},children:title}),e("p",{style:{fontSize:12.5,color:a.muted,lineHeight:1.65,margin:"0 auto",maxWidth:520},children:body}),extra||null]})};
  var main;
  if(state==="off"){
    main=p.role==="admin"?card("Ada is not connected yet","Deploy the avatar service in the ada folder (see ada/FREE_SETUP.md), then put its address in ada-config.js (window.MK_ADA_URL) and reload. Students will see Ada here and in the bottom menu straight away."):card("Ada is coming soon","Your live tutor is being set up. Check back soon - in the meantime your lessons and subjects are ready for you.");
  }else if(state==="checking"){
    main=card("Waking Ada up...","This can take a few seconds the first time.");
  }else if(state==="down"){
    main=card("Ada is resting right now","We could not reach the tutor service. Check your connection and try again.",e("button",{onClick:function(){setTick(function(n){return n+1})},style:{marginTop:14,border:"none",borderRadius:10,padding:"10px 18px",background:"#1842a8",color:"#fff",fontWeight:800,fontSize:13,cursor:"pointer",fontFamily:"inherit"},children:"Try again"}));
  }else{
    var mode=info&&info.tutor&&info.tutor.mode;
    main=t("div",{children:[
      e("iframe",{title:"Ada, the MindKlass tutor",src:url+"/embed",allow:"microphone; autoplay; clipboard-write",style:{width:"100%",height:X?"calc(100vh - 250px)":"calc(100vh - 200px)",minHeight:480,border:"1px solid "+a.border,borderRadius:16,background:"#080b13",display:"block"}}),
      t("div",{style:{display:"flex",justifyContent:"space-between",gap:8,flexWrap:"wrap",fontSize:11,color:a.muted,marginTop:8},children:[e("span",{children:mode==="model"?"Ada is answering with the AI tutor.":"Ada is teaching from MindKlass lessons."}),e("a",{href:url+"/classroom",target:"_blank",rel:"noopener",style:{color:"#1842a8",fontWeight:800},children:"Open full screen"})]})]});
  }
  return t("div",{children:[head,main]});
}
function MkSubjectTiles(p){
  var a=p.a,k=p.k;
  var tiles=[["Nigerian Curriculum","SS1, SS2 and SS3 lesson notes","#1842a8","Nigerian Curriculum"],["Cambridge","IGCSE learning journeys","#7c3aed","Cambridge"],["JAMB (UTME)","UTME exam preparation","#059669","JAMB (UTME)"],["Soft Skills","Life and career skills","#d97706","Soft Skills"],["IB","IB programme","#db2777","IB"]];
  return t("div",{style:{...k,marginBottom:12},children:[
    t("div",{style:{display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:10},children:[e("h3",{style:{fontSize:13,fontWeight:800,color:a.head,margin:0},children:"Student Subjects"}),e("button",{onClick:function(){p.go("All")},style:{background:"none",border:"none",color:"#1842a8",fontWeight:800,fontSize:11,cursor:"pointer"},children:"See all"})]}),
    t("div",{style:{display:"flex",gap:10,overflowX:"auto",paddingBottom:4,WebkitOverflowScrolling:"touch"},children:[
      e("button",{onClick:p.ada,style:{minWidth:150,flexShrink:0,textAlign:"left",border:"none",cursor:"pointer",borderRadius:14,padding:"12px",background:"linear-gradient(135deg,#059669,#2158e8)",color:"#fff",fontFamily:"inherit"},children:t("div",{children:[e(MkAdaIcon,{size:20,color:"#fff"}),e("div",{style:{fontWeight:900,fontSize:13,marginTop:6},children:"Ask Ada"}),e("div",{style:{fontSize:10.5,opacity:.85,marginTop:2},children:"Your live tutor"})]})},"ada"),
      tiles.map(function(x){return e("button",{onClick:function(){p.go(x[3])},style:{minWidth:150,flexShrink:0,textAlign:"left",cursor:"pointer",borderRadius:14,padding:"12px",background:x[2]+"14",border:"1.5px solid "+x[2]+"33",color:a.head,fontFamily:"inherit"},children:t("div",{children:[e("div",{style:{fontWeight:900,fontSize:13,color:x[2]},children:x[0]}),e("div",{style:{fontSize:10.5,color:a.muted,marginTop:3,lineHeight:1.4},children:x[1]})]})},x[0])})]})]});
}
function MkLevelChips(p){
  var a=p.a,lv=["All","SS1","SS2","SS3"];
  return e("div",{style:{display:"flex",flexWrap:"wrap",gap:7,margin:"-6px 0 16px"},children:lv.map(function(x){var on=p.v===x;return e("button",{onClick:function(){p.set(x)},style:{fontSize:12,fontWeight:800,padding:"5px 14px",borderRadius:99,cursor:"pointer",border:on?"1.5px solid #059669":"1.5px solid "+a.bd,background:on?"#059669":a.card,color:on?"#fff":a.txt},children:x==="All"?"All classes":x},x)})});
}
/* ---- Alerts for course applications and approvals (no database change needed) ---- */
function mkSeenLoad(){try{return new Set(JSON.parse(localStorage.getItem("mk_seen_alerts")||"[]"))}catch(x){return new Set()}}
function mkSynthAlerts(o){
  var out=[];
  try{
    var me=o.user&&o.user.id,seen=o.seen||new Set(),now=Date.now(),lim=14*864e5;
    [o.student||[],o.teacher||[]].forEach(function(list){
      list.forEach(function(ap){
        var name=ap.title||ap.subject||"a course";
        if(o.role==="admin"){
          if(ap.status==="pending"){
            var id="app-"+ap.id+"-pending";
            out.push({id:id,title:"New course application",body:(ap.name||ap.nick||"A learner")+" applied for "+name+(ap.appliedAt?" ("+ap.appliedAt+")":"")+". Open Course Approvals to approve or decline.",type:"approval",audience:"admin",urgent:!0,date:ap.appliedAt||"",ts:Date.parse(ap.appliedAt)||0,read:seen.has(id)});
          }
        }else if(me&&ap.userId===me&&(ap.status==="approved"||ap.status==="rejected"||ap.status==="revoked")){
          var dts=ap.decidedTs?Date.parse(ap.decidedTs):0;
          if(dts&&now-dts>lim)return;
          var id2="app-"+ap.id+"-"+ap.status;
          var body=ap.status==="approved"?"Good news! Your application for "+name+" has been approved. Open Subjects or My Progress to start learning.":ap.status==="rejected"?"Your application for "+name+" was not approved this time. You can contact the administrator for help.":"Your access to "+name+" has been removed by the administrator.";
          out.push({id:id2,title:ap.status==="approved"?"Course approved":ap.status==="rejected"?"Application not approved":"Access removed",body:body,type:"approval",audience:o.role,urgent:ap.status==="approved",date:ap.decidedAt||"",ts:dts,read:seen.has(id2)});
        }
      });
    });
  }catch(x){}
  out.sort(function(a,b){return b.ts-a.ts});
  return out;
}
/* ---- Progress dashboard ---- */
function MkDonut(p){
  var r=54,c=2*Math.PI*r,off=0,tot=p.segs.reduce(function(s,x){return s+x.v},0);
  var kids=[e("circle",{cx:70,cy:70,r:r,fill:"none",stroke:p.track,strokeWidth:22},"track")];
  if(tot>0)p.segs.forEach(function(sg,i){
    if(sg.v<=0)return;
    var len=c*sg.v/tot;
    kids.push(e("circle",{cx:70,cy:70,r:r,fill:"none",stroke:sg.c,strokeWidth:22,strokeDasharray:len+" "+(c-len),strokeDashoffset:-off,transform:"rotate(-90 70 70)"},"s"+i));
    off+=len;
  });
  kids.push(e("text",{x:70,y:68,textAnchor:"middle",fontSize:24,fontWeight:900,fill:p.txt,fontFamily:"Outfit,sans-serif",children:p.center},"ct"));
  kids.push(e("text",{x:70,y:86,textAnchor:"middle",fontSize:10,fill:p.muted,children:p.sub},"sb"));
  return e("svg",{viewBox:"0 0 140 140",width:p.size||150,height:p.size||150,role:"img","aria-label":p.label||"Chart",children:kids});
}
function MkCal(p){
  var a=p.a,s=f(0),off=s[0],setOff=s[1];
  var base=new Date();base.setDate(1);base.setMonth(base.getMonth()+off);
  var y=base.getFullYear(),m=base.getMonth(),first=(new Date(y,m,1).getDay()+6)%7,days=new Date(y,m+1,0).getDate(),prev=new Date(y,m,0).getDate();
  var today=new Date(),tk=today.getFullYear()+"-"+String(today.getMonth()+1).padStart(2,"0")+"-"+String(today.getDate()).padStart(2,"0");
  var cells=[];
  for(var i=0;i<42;i++){
    var d=i-first+1,inM=d>=1&&d<=days,label=inM?d:(d<1?prev+d:d-days);
    var key=inM?y+"-"+String(m+1).padStart(2,"0")+"-"+String(d).padStart(2,"0"):"";
    var mk=inM&&p.marks[key]||"";
    var bg="transparent",col=inM?a.txt:a.muted;
    if(key===tk){bg="#1842a8";col="#fff"}else if(mk==="exam"){bg="#d97706";col="#fff"}else if(mk==="active"){bg="#059669";col="#fff"}
    cells.push(e("div",{style:{height:32,display:"flex",alignItems:"center",justifyContent:"center"},children:e("span",{style:{width:28,height:28,borderRadius:"50%",background:bg,color:col,fontSize:12,fontWeight:bg==="transparent"?500:800,opacity:inM?1:.4,display:"flex",alignItems:"center",justifyContent:"center"},children:label})},i));
  }
  var head=["Mon","Tue","Wed","Thu","Fri","Sat","Sun"].map(function(x){return e("div",{style:{textAlign:"center",fontSize:10,fontWeight:800,color:a.muted,padding:"4px 0"},children:x},x)});
  var nb=function(dir,txt){return e("button",{onClick:function(){setOff(off+dir)},"aria-label":dir<0?"Previous month":"Next month",style:{background:"none",border:"none",cursor:"pointer",color:a.muted,fontSize:18,padding:"0 8px"},children:txt})};
  return t("div",{children:[
    t("div",{style:{display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:6},children:[nb(-1,"\u2039"),e("div",{style:{fontWeight:800,color:a.head,fontSize:14},children:base.toLocaleString("en",{month:"long",year:"numeric"})}),nb(1,"\u203A")]}),
    e("div",{style:{display:"grid",gridTemplateColumns:"repeat(7,1fr)"},children:head.concat(cells)}),
    t("div",{style:{display:"flex",flexWrap:"wrap",gap:"4px 12px",marginTop:10,fontSize:11,color:a.muted},children:[
      t("span",{children:[e("i",{style:{display:"inline-block",width:9,height:9,borderRadius:"50%",background:"#1842a8",marginRight:5}}),"Today"]},"a"),
      t("span",{children:[e("i",{style:{display:"inline-block",width:9,height:9,borderRadius:"50%",background:"#059669",marginRight:5}}),"Learning activity"]},"b"),
      t("span",{children:[e("i",{style:{display:"inline-block",width:9,height:9,borderRadius:"50%",background:"#d97706",marginRight:5}}),"Assessment opens"]},"c")]})]});
}
function mkBar(a,pct,col){return e("div",{style:{height:7,background:a.border,borderRadius:99,overflow:"hidden"},children:e("div",{style:{height:"100%",width:Math.max(0,Math.min(100,pct))+"%",background:col||"#1842a8",borderRadius:99,transition:"width .4s"}})})}
function MkProgress(p){
  var a=p.a,k=p.k,X=p.X,admin=p.role==="admin",me=p.user&&p.user.id;
  var s1=f([]),rows=s1[0],setRows=s1[1],s2=f(!0),loading=s2[0],setLoading=s2[1],s3=f(""),qs=s3[0],setQs=s3[1],s4=f("all"),cf=s4[0],setCf=s4[1],s5=f(0),tick=s5[0],setTick=s5[1];
  de(function(){
    if(p.guest||!me){setLoading(!1);return}
    var dead=!1;setLoading(!0);
    (async function(){
      var q=p.sb.from("course_progress").select("*, profiles(nick,name)");if(!admin)q=q.eq("user_id",me);
      var r=await q;
      if(r.error){q=p.sb.from("course_progress").select("*");if(!admin)q=q.eq("user_id",me);r=await q}
      if(!dead){setRows(r.data||[]);setLoading(!1)}
    })().catch(function(){if(!dead)setLoading(!1)});
    return function(){dead=!0};
  },[me,admin,tick]);
  var cat=function(kind,key){return(kind==="tr"?p.Fe:p.Ce)[key]||null};
  var total=function(c){return c&&c.units?c.units.length:0};
  var titleOf=function(c,key){return c?(c.group?c.group+" - "+(c.termLabel||c.title):(c.title||c.subject||key)):key};
  var marks={};
  rows.forEach(function(r){if(r.updated_at){marks[String(r.updated_at).slice(0,10)]="active"}});
  Object.keys(p.exams||{}).forEach(function(kk){var v=p.exams[kk];if(v)marks[String(v).slice(0,10)]="exam"});
  var cardWrap=function(child,extra){return e("div",{style:Object.assign({},k,extra||{}),children:child})};
  var h3=function(txt){return e("h3",{style:{fontSize:14,fontWeight:800,color:a.head,margin:"0 0 12px",fontFamily:"Outfit,sans-serif"},children:txt})};
  var tile=function(v,l,col){return t("div",{style:Object.assign({},k,{padding:14,textAlign:"center"}),children:[e("div",{style:{fontSize:22,fontWeight:900,color:col,fontFamily:"Outfit,sans-serif"},children:v}),e("div",{style:{fontSize:11,color:a.muted,marginTop:2},children:l})]},l)};
  var status=function(done,tot){return tot>0&&done>=tot?"Completed":done>0?"In progress":"Not started"};
  var stCol={"Completed":"#059669","In progress":"#1842a8","Not started":"#94a3b8"};
  var head=t("div",{style:{background:"linear-gradient(135deg,#0d1f4b,#1842a8)",borderRadius:18,padding:X?"16px":"22px",marginBottom:14,color:"#fff"},children:[
    e("h1",{style:{fontSize:X?20:24,fontWeight:900,fontFamily:"Outfit,sans-serif",margin:0},children:admin?"Progress of all learners":"My Progress"}),
    e("p",{style:{fontSize:12.5,margin:"4px 0 0",color:"rgba(255,255,255,.82)",lineHeight:1.5},children:admin?"See how every learner is moving through their courses. Learners only see their own progress.":"See how far you have come in each course and what to do next."})]});
  if(p.guest||!me){
    return t("div",{children:[head,cardWrap(t("div",{style:{textAlign:"center",padding:"18px 8px"},children:[e("div",{style:{fontWeight:900,color:a.head,fontSize:15,marginBottom:6},children:"Log in to see your progress"}),e("p",{style:{fontSize:12.5,color:a.muted,margin:"0 auto 12px",maxWidth:420,lineHeight:1.6},children:"Your progress is saved to your account, so you can pick up where you stopped on any device."}),e("button",{onClick:p.login,style:{border:"none",borderRadius:10,padding:"10px 20px",background:"#1842a8",color:"#fff",fontWeight:800,cursor:"pointer",fontFamily:"inherit"},children:"Log in"})]}))]});
  }
  var layout=function(main,side){return e("div",{style:{display:"grid",gridTemplateColumns:X?"1fr":"minmax(0,1fr) 300px",gap:14,alignItems:"start"},children:[e("div",{children:main},"m"),e("div",{children:side},"s")]})};
  var calCard=cardWrap([h3("Calendar"),e(MkCal,{a:a,marks:marks})],{marginBottom:14});
  /* ------------- learner view ------------- */
  if(!admin){
    var mine={};
    var courses=[];
    (p.apps||[]).forEach(function(ap){
      if(ap.userId!==me||!(ap.status==="approved"||ap.status==="pending"))return;
      var c=p.Ce[ap.journey];if(!c)return;
      var done=(p.mine[ap.journey]||[]).length,tot=total(c);
      courses.push({key:ap.journey,title:titleOf(c,ap.journey),sub:c.cat||c.subject||"",done:Math.min(done,tot||done),tot:tot,pct:tot?Math.round(Math.min(done,tot)/tot*100):0,ap:ap.status});
    });
    var seenKeys={};courses.forEach(function(c){seenKeys[c.key]=1});
    rows.forEach(function(r){
      if(r.kind==="tr"||seenKeys[r.course_key])return;
      var c=p.Ce[r.course_key];if(!c)return;
      var done=(p.mine[r.course_key]||r.completed_units||[]).length,tot=total(c);
      courses.push({key:r.course_key,title:titleOf(c,r.course_key),sub:c.cat||c.subject||"",done:Math.min(done,tot||done),tot:tot,pct:tot?Math.round(Math.min(done,tot)/tot*100):0,ap:"approved"});
    });
    var active=courses.filter(function(c){return c.ap==="approved"}),pending=courses.filter(function(c){return c.ap==="pending"});
    var unitsDone=active.reduce(function(s,c){return s+c.done},0),unitsTot=active.reduce(function(s,c){return s+c.tot},0);
    var attempted=0;
    active.forEach(function(c){var ch=p.checks[c.key]||{},dn=p.mine[c.key]||[];Object.keys(ch).forEach(function(u){if(dn.indexOf(u)<0)attempted++})});
    var remaining=Math.max(0,unitsTot-unitsDone-attempted);
    var overall=unitsTot?Math.round(unitsDone/unitsTot*100):0;
    var cards=active.slice(0,2).concat(pending.slice(0,Math.max(0,2-active.length))).map(function(c,i){
      var col=["#1842a8","#7c3aed","#059669","#d97706"][i%4];
      return t("button",{onClick:function(){p.go(c.key)},style:Object.assign({},k,{textAlign:"left",cursor:"pointer",borderLeft:"4px solid "+col,display:"flex",flexDirection:"column",gap:6,fontFamily:"inherit"}),children:[
        e("div",{style:{fontWeight:800,color:a.head,fontSize:13.5,lineHeight:1.35},children:c.title}),
        e("div",{style:{fontSize:11,color:a.muted},children:c.sub}),
        c.ap==="pending"?e("div",{style:{fontSize:11,fontWeight:800,color:"#d97706"},children:"Waiting for approval"}):t("div",{children:[mkBar(a,c.pct,col),e("div",{style:{fontSize:11,fontWeight:800,color:col,marginTop:5},children:c.done+" of "+c.tot+" units \u00B7 "+c.pct+"%"})]})]},c.key);
    });
    var more=courses.length>cards.length?courses.length-cards.length:0;
    var courseRow=courses.length===0?cardWrap(t("div",{style:{textAlign:"center",padding:"14px 6px"},children:[e("div",{style:{fontWeight:900,color:a.head,fontSize:15,marginBottom:6},children:"You have not started a course yet"}),e("p",{style:{fontSize:12.5,color:a.muted,margin:"0 auto 12px",maxWidth:440,lineHeight:1.6},children:"Choose a subject, apply, and once the administrator approves you, your progress will appear here. You will get an alert when you are approved."}),e("button",{onClick:p.browse,style:{border:"none",borderRadius:10,padding:"10px 20px",background:"#1842a8",color:"#fff",fontWeight:800,cursor:"pointer",fontFamily:"inherit"},children:"Browse subjects"})]}),{marginBottom:14}):
      e("div",{style:{display:"grid",gridTemplateColumns:X?"1fr":"repeat(3,minmax(0,1fr))",gap:12,marginBottom:14},children:cards.concat(more>0?[t("button",{onClick:function(){document.getElementById("mk-prog-list")&&document.getElementById("mk-prog-list").scrollIntoView({behavior:"smooth"})},style:Object.assign({},k,{textAlign:"left",cursor:"pointer",fontFamily:"inherit"}),children:[e("div",{style:{fontWeight:900,fontSize:22,color:a.head},children:more+" more"}),e("div",{style:{fontSize:12,color:"#1842a8",fontWeight:800,marginTop:4},children:"Show all"})]},"more")]:[])});
    var promo=cardWrap(t("div",{style:{display:"flex",gap:14,alignItems:"center",flexWrap:"wrap"},children:[
      e("div",{style:{width:54,height:54,borderRadius:"50%",background:"rgba(217,119,6,.15)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:26,flexShrink:0},children:"\uD83D\uDCA1"}),
      t("div",{style:{flex:1,minWidth:200},children:[e("div",{style:{fontWeight:900,color:a.head,fontSize:15},children:"Take more courses to reach your goals"}),e("div",{style:{fontSize:12.5,color:a.muted,lineHeight:1.5,marginTop:2},children:"Our subjects help you build skills, prepare for exams and open new doors."})]}),
      e("button",{onClick:p.browse,style:{border:"none",borderRadius:99,padding:"10px 22px",background:"linear-gradient(135deg,#f5b301,#d97706)",color:"#fff",fontWeight:800,cursor:"pointer",fontFamily:"inherit"},children:"Browse"})]}),{marginBottom:14});
    var donutCard=cardWrap([h3("Unit status"),t("div",{style:{display:"flex",alignItems:"center",gap:16,flexWrap:"wrap",justifyContent:"center"},children:[
      e(MkDonut,{segs:[{v:unitsDone,c:"#059669"},{v:attempted,c:"#1842a8"},{v:remaining,c:"#cbd5e1"}],track:a.border,txt:a.head,muted:a.muted,center:overall+"%",sub:"complete",label:"Unit status"}),
      t("div",{style:{fontSize:12,color:a.txt,display:"flex",flexDirection:"column",gap:7},children:[
        t("span",{children:[e("i",{style:{display:"inline-block",width:10,height:10,borderRadius:"50%",background:"#059669",marginRight:7}}),"Completed ("+unitsDone+")"]},"a"),
        t("span",{children:[e("i",{style:{display:"inline-block",width:10,height:10,borderRadius:"50%",background:"#1842a8",marginRight:7}}),"Started, checks not passed ("+attempted+")"]},"b"),
        t("span",{children:[e("i",{style:{display:"inline-block",width:10,height:10,borderRadius:"50%",background:"#cbd5e1",marginRight:7}}),"Not started ("+remaining+")"]},"c")]})]})]);
    var barsCard=cardWrap([e("div",{id:"mk-prog-list"},"anchor"),h3("Learning progress"),active.length===0?e("div",{style:{fontSize:12.5,color:a.muted},children:"No approved courses yet."}):e("div",{style:{display:"flex",flexDirection:"column",gap:14},children:active.map(function(c){return e("button",{onClick:function(){p.go(c.key)},style:{background:"none",border:"none",textAlign:"left",cursor:"pointer",padding:0,fontFamily:"inherit"},children:t("div",{children:[t("div",{style:{display:"flex",justifyContent:"space-between",gap:8,fontSize:12,color:a.txt,marginBottom:5},children:[e("span",{style:{fontWeight:700},children:c.title}),e("span",{style:{fontWeight:900,color:"#1842a8"},children:c.pct+"%"})]}),mkBar(a,c.pct)]})},c.key)})})]);
    var tiles=e("div",{style:{display:"grid",gridTemplateColumns:"repeat(2,minmax(0,1fr))",gap:12,marginBottom:14},children:[tile(unitsDone+" / "+unitsTot,"Units completed","#059669"),tile(String(pending.length),"Awaiting approval","#d97706")]});
    var side=[calCard,cardWrap(t("div",{style:{textAlign:"center"},children:[e("div",{style:{fontWeight:900,color:a.head,fontSize:15},children:"Stuck on a topic?"}),e("p",{style:{fontSize:12.5,color:a.muted,lineHeight:1.55,margin:"6px 0 12px"},children:"Ask Ada, your live tutor, to explain it in your own language."}),e("button",{onClick:p.ada,style:{border:"none",borderRadius:99,padding:"10px 22px",background:"linear-gradient(135deg,#7c3aed,#1842a8)",color:"#fff",fontWeight:800,cursor:"pointer",fontFamily:"inherit"},children:"Ask Ada"})]}))];
    return t("div",{children:[head,loading?e("div",{style:{fontSize:12,color:a.muted,marginBottom:8},children:"Loading your progress..."}):null,layout([e("h2",{style:{fontSize:16,fontWeight:900,color:a.head,fontFamily:"Outfit,sans-serif",margin:"0 0 10px"},children:"Your Courses"},"h"),courseRow,promo,e("div",{style:{display:"grid",gridTemplateColumns:X?"1fr":"1fr 1fr",gap:12,marginBottom:14},children:[donutCard,barsCard]}),tiles],side)]});
  }
  /* ------------- administrator view ------------- */
  var map={};
  var add=function(kind,uid,name,key,done,last){
    var id=kind+"|"+uid+"|"+key;
    if(!map[id])map[id]={kind:kind,uid:uid,name:name||"Learner",key:key,done:0,last:""};
    if(done!=null)map[id].done=Math.max(map[id].done,done);
    if(last&&last>map[id].last)map[id].last=last;
    if(name&&map[id].name==="Learner")map[id].name=name;
  };
  rows.forEach(function(r){add(r.kind==="tr"?"tr":"sj",r.user_id,(r.profiles&&(r.profiles.name||r.profiles.nick))||"",r.course_key,(r.completed_units||[]).length,r.updated_at||"")});
  (p.apps||[]).forEach(function(ap){if(ap.status==="approved")add("sj",ap.userId,ap.name||ap.nick,ap.journey,null,"")});
  (p.tapps||[]).forEach(function(ap){if(ap.status==="approved")add("tr",ap.userId,ap.name||ap.nick,ap.course,null,"")});
  var list=Object.keys(map).map(function(id){
    var r=map[id],c=cat(r.kind,r.key),tot=total(c),done=tot?Math.min(r.done,tot):r.done;
    return {kind:r.kind,uid:r.uid,name:r.name,key:r.key,title:titleOf(c,r.key),done:done,tot:tot,pct:tot?Math.round(done/tot*100):0,last:r.last,st:status(done,tot)};
  });
  var courseKeys=[];list.forEach(function(r){if(courseKeys.indexOf(r.key)<0)courseKeys.push(r.key)});
  var shown=list.filter(function(r){return(cf==="all"||r.key===cf)&&(!qs||(r.name+" "+r.title).toLowerCase().indexOf(qs.toLowerCase())>=0)}).sort(function(x,y2){return(y2.last||"").localeCompare(x.last||"")||x.name.localeCompare(y2.name)});
  var learners={};list.forEach(function(r){learners[r.uid]=1});
  var cnt={"Completed":0,"In progress":0,"Not started":0};list.forEach(function(r){cnt[r.st]++});
  var avg=list.length?Math.round(list.reduce(function(s,r){return s+r.pct},0)/list.length):0;
  var pend=(p.apps||[]).concat(p.tapps||[]).filter(function(ap){return ap.status==="pending"}).length;
  var perCourse=courseKeys.map(function(key){var rs=list.filter(function(r){return r.key===key});return{key:key,title:rs[0].title,n:rs.length,avg:Math.round(rs.reduce(function(s,r){return s+r.pct},0)/rs.length)}}).sort(function(x,y2){return y2.n-x.n}).slice(0,8);
  var tilesA=e("div",{style:{display:"grid",gridTemplateColumns:X?"repeat(2,minmax(0,1fr))":"repeat(5,minmax(0,1fr))",gap:12,marginBottom:14},children:[tile(String(Object.keys(learners).length),"Learners tracked","#1842a8"),tile(String(list.length),"Course enrolments","#7c3aed"),tile(avg+"%","Average completion","#059669"),tile(String(cnt["Completed"]),"Courses completed","#059669"),tile(String(pend),"Applications waiting","#d97706")]});
  var donutA=cardWrap([h3("Enrolment status"),t("div",{style:{display:"flex",alignItems:"center",gap:16,flexWrap:"wrap",justifyContent:"center"},children:[
    e(MkDonut,{segs:[{v:cnt["Completed"],c:"#059669"},{v:cnt["In progress"],c:"#1842a8"},{v:cnt["Not started"],c:"#cbd5e1"}],track:a.border,txt:a.head,muted:a.muted,center:String(list.length),sub:"enrolments",label:"Enrolment status"}),
    t("div",{style:{fontSize:12,color:a.txt,display:"flex",flexDirection:"column",gap:7},children:["Completed","In progress","Not started"].map(function(nm){return t("span",{children:[e("i",{style:{display:"inline-block",width:10,height:10,borderRadius:"50%",background:nm==="Not started"?"#cbd5e1":stCol[nm],marginRight:7}}),nm+" ("+cnt[nm]+")"]},nm)})})]})]);
  var barsA=cardWrap([h3("Courses by average completion"),perCourse.length===0?e("div",{style:{fontSize:12.5,color:a.muted},children:"No learners are enrolled yet."}):e("div",{style:{display:"flex",flexDirection:"column",gap:12},children:perCourse.map(function(c){return t("div",{children:[t("div",{style:{display:"flex",justifyContent:"space-between",gap:8,fontSize:12,color:a.txt,marginBottom:4},children:[e("span",{style:{fontWeight:700},children:c.title+" ("+c.n+")"}),e("span",{style:{fontWeight:900,color:"#1842a8"},children:c.avg+"%"})]}),mkBar(a,c.avg)]},c.key)})})]);
  var sel={border:"1.5px solid "+a.bd,background:a.card,color:a.txt,borderRadius:10,padding:"9px 11px",fontSize:12.5,fontFamily:"inherit"};
  var table=cardWrap([t("div",{style:{display:"flex",gap:8,flexWrap:"wrap",alignItems:"center",justifyContent:"space-between",marginBottom:10},children:[h3("Everyone's progress"),t("div",{style:{display:"flex",gap:8,flexWrap:"wrap"},children:[
    e("input",{value:qs,onChange:function(ev){setQs(ev.target.value)},placeholder:"Search name or course",style:Object.assign({},sel,{minWidth:150})}),
    t("select",{value:cf,onChange:function(ev){setCf(ev.target.value)},style:sel,children:[e("option",{value:"all",children:"All courses"},"all")].concat(courseKeys.map(function(key){var r=list.find(function(x){return x.key===key});return e("option",{value:key,children:r?r.title:key},key)}))}),
    e("button",{onClick:function(){setTick(tick+1)},style:Object.assign({},sel,{cursor:"pointer",fontWeight:800}),children:"Refresh"})]})]}),
    shown.length===0?e("div",{style:{fontSize:12.5,color:a.muted,padding:"10px 0"},children:loading?"Loading...":"No matching learners yet. If you expected to see learners here, run supabase/progress_dashboard.sql once so administrators can read all progress."}):e("div",{style:{overflowX:"auto"},children:t("table",{style:{width:"100%",borderCollapse:"collapse",minWidth:560,fontSize:12.5},children:[
      e("thead",{children:e("tr",{children:["Learner","Course","Progress","Units","Last active"].map(function(h){return e("th",{style:{textAlign:"left",padding:"8px 10px",background:a.pale,color:a.head,fontWeight:800,borderBottom:"1px solid "+a.border},children:h},h)})})}),
      e("tbody",{children:shown.slice(0,200).map(function(r,i){return t("tr",{children:[
        e("td",{style:{padding:"8px 10px",borderTop:"1px solid "+a.border,fontWeight:700,color:a.head},children:r.name}),
        e("td",{style:{padding:"8px 10px",borderTop:"1px solid "+a.border,color:a.txt},children:r.title+(r.kind==="tr"?" (teacher)":"")}),
        e("td",{style:{padding:"8px 10px",borderTop:"1px solid "+a.border,minWidth:130},children:t("div",{children:[mkBar(a,r.pct,stCol[r.st]),e("div",{style:{fontSize:10.5,marginTop:3,color:stCol[r.st],fontWeight:800},children:r.pct+"% \u00B7 "+r.st})]})}),
        e("td",{style:{padding:"8px 10px",borderTop:"1px solid "+a.border,color:a.txt},children:r.done+" / "+r.tot}),
        e("td",{style:{padding:"8px 10px",borderTop:"1px solid "+a.border,color:a.muted},children:r.last?new Date(r.last).toLocaleDateString():"Not yet"})]},i)})})]})})]);
  return t("div",{children:[head,tilesA,layout([e("div",{style:{display:"grid",gridTemplateColumns:X?"1fr":"1fr 1fr",gap:12,marginBottom:14},children:[donutA,barsA]}),table],[calCard])]});
}
/*MK-MOBILE-END*/
