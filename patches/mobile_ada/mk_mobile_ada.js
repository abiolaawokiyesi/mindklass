/*MK-MOBILE-BEGIN*/
/* Mobile shell (side drawer + floating bottom tabs), the Ada tutor view and the
   Student Subjects tiles. Everything here is plain functions that use the app's
   own React (f = useState, de = useEffect) and JSX runtime (e, t), so it can sit
   at module level and be called from the main component. */
function MkAdaIcon(p){var s=p.size||16;return e("svg",{width:s,height:s,viewBox:"0 0 24 24",fill:"none",stroke:p.color||"currentColor",strokeWidth:2,strokeLinecap:"round",strokeLinejoin:"round",style:p.style,children:[e("circle",{cx:12,cy:8,r:4},"a"),e("path",{d:"M4 21v-1a6 6 0 0 1 6-6h4a6 6 0 0 1 6 6v1"},"b"),e("path",{d:"M10 7.6h.01M14 7.6h.01"},"c")]})}
function MkMenuIcon(p){var s=p.size||18;return e("svg",{width:s,height:s,viewBox:"0 0 24 24",fill:"none",stroke:p.color||"currentColor",strokeWidth:2.2,strokeLinecap:"round",style:p.style,children:[e("path",{d:"M4 7h16"},"a"),e("path",{d:"M4 12h16"},"b"),e("path",{d:"M4 17h10"},"c")]})}
function mkWithAda(role,list){try{if(role==="parent"||!role)return list;if(list.some(function(i){return i.id==="ada"}))return list;var at=list.findIndex(function(i){return i.id==="learn"});var out=list.slice();out.splice(at>=0?at+1:Math.min(1,out.length),0,{id:"ada",I:MkAdaIcon,l:"Ask Ada"});return out}catch(x){return list}}
var MK_NAV_GROUPS=[["General",["home","courses","learn","general","jamb","training","ada"]],["Study",["assignments","quiz","gradebook","attendance","behavior","child","downloads","games","whiteboard","ipersonality"]],["Manage",["users","staffperf","staffhub","approvals","coursebuilder","exams","fees","push"]],["Connect",["community","messages","meetings","careers","blog","refer"]],["Account",["profile"]]];
var MK_TABS={student:["home","learn","ada","courses"],teacher:["home","courses","ada","learn"],admin:["home","users","approvals","learn"],parent:["home","child","gradebook","messages"],professional:["home","general","ada","quiz"]};
var MK_TAB_LABEL={home:"Home",courses:"Courses",learn:"Subjects",general:"General",ada:"Ada",users:"Users",approvals:"Approvals",child:"My Child",gradebook:"Report",messages:"Messages",quiz:"Tests"};
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
/*MK-MOBILE-END*/
