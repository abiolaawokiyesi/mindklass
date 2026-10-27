/* MindKlass staff performance module: core helpers and data layer.
   Injected after the react/jsx-runtime import in dist/assets/app.js by apply_staff_perf.ps1
   (or patch_staff_perf.py). Uses the bundle's own aliases: e/t (jsx), f (useState),
   de (useEffect), Re (useRef), M (supabase client). ASCII only; symbols are \u escapes. */

var MKS_QUAD={
  Q1:{w:40,n:"Urgent + Important",use:"Critical deliverables, deadlines, emergencies",c:"#dc2626"},
  Q2:{w:30,n:"Important + Not Urgent",use:"Strategic work, planning, relationship building, prevention",c:"#2158e8"},
  Q3:{w:20,n:"Urgent + Not Important",use:"Interruptions, routine urgent requests",c:"#d97706"},
  Q4:{w:10,n:"Not Urgent + Not Important",use:"Low-value or admin activities; keep limited",c:"#64748b"}
};
var MKS_POSITIONS=["Project Management Associate","Business Development Associate","HR and Admin Associate","Program Management Associate","Finance Management Associate","Digital Marketing Associate","Creative Media Associate","Communications Associate","Partnerships Associate","Operations and Logistics Associate","Monitoring, Evaluation and Learning Associate","Education and Innovation Associate","Executive Assistant","Other (type your position)"];
var MKS_STATUSES=["Not Started","In Progress","Completed","Blocked"];
var MKS_APPROVALS=["Pending","Approved","Not Approved"];
var MKS_TARGET=80;
var MKS_MONTHS=["January","February","March","April","May","June","July","August","September","October","November","December"];
var MKS_SQL_FILE="supabase/staff_performance.sql";

function mksPad(n){return n<10?"0"+n:""+n}
function mksYmd(d){return d.getFullYear()+"-"+mksPad(d.getMonth()+1)+"-"+mksPad(d.getDate())}
function mksDate(s){var p=String(s).split("-");return new Date(+p[0],+p[1]-1,+p[2],12,0,0)}
function mksToday(){return mksYmd(new Date())}
function mksAddDays(s,n){var d=mksDate(s);d.setDate(d.getDate()+n);return mksYmd(d)}
function mksMonday(s){var d=mksDate(s),g=d.getDay();d.setDate(d.getDate()+(g===0?-6:1-g));return mksYmd(d)}
function mksMonthStart(s){return String(s).slice(0,7)+"-01"}
function mksMonthEnd(s){var d=mksDate(s);return mksYmd(new Date(d.getFullYear(),d.getMonth()+1,0,12))}
function mksYearStart(s){return String(s).slice(0,4)+"-01-01"}
function mksYearEnd(s){return String(s).slice(0,4)+"-12-31"}
function mksAddMonths(s,n){var d=mksDate(s);d.setDate(1);d.setMonth(d.getMonth()+n);return mksYmd(d)}
function mksNice(s){try{return mksDate(s).toLocaleDateString(undefined,{weekday:"short",day:"numeric",month:"short",year:"numeric"})}catch(x){return s}}
function mksShort(s){try{return mksDate(s).toLocaleDateString(undefined,{day:"numeric",month:"short"})}catch(x){return s}}
function mksWorkdays(from,to){
  var end=to>mksToday()?mksToday():to,n=0,c=from,g=0;
  while(c<=end&&g<400){var w=mksDate(c).getDay();if(w!==0&&w!==6)n++;c=mksAddDays(c,1);g++}
  return n}
function mksUuid(){
  try{if(window.crypto&&window.crypto.randomUUID)return window.crypto.randomUUID()}catch(x){}
  return"xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g,function(c){var r=Math.random()*16|0;return(c==="x"?r:(r&3|8)).toString(16)})}

function mksNewTask(uid,date,pos){
  return{id:mksUuid(),user_id:uid,task_date:date,position:pos,title:"",quadrant:"Q2",expected:"",completion:0,evidence:"",status:"Not Started",blocker:"",next_action:"",notes:""}}

/* score of one day from its tasks: sum(weight x completion) / sum(weight) */
function mksDay(tasks){
  var pw=0,cw=0,np=0,nc=0,ev=0,bl=0;
  (tasks||[]).forEach(function(k){
    if(!String(k.title||"").trim())return;
    var q=MKS_QUAD[k.quadrant],w=q?q.w:0,c=Math.max(0,Math.min(100,Number(k.completion)||0));
    pw+=w;cw+=w*c/100;np++;if(c>=100)nc++;
    if(String(k.evidence||"").trim())ev++;
    if(k.status==="Blocked"||String(k.blocker||"").trim())bl++});
  return{planned:np,completed:nc,pw:pw,cw:cw,ev:ev,bl:bl,score:pw?Math.round(cw/pw*1000)/10:0}}
function mksFromRow(r){
  return{planned:+r.tasks_planned||0,completed:+r.tasks_completed||0,pw:+r.planned_weight||0,cw:+r.completed_weight||0,ev:+r.evidence_count||0,bl:+r.blocked_count||0,score:+r.score||0}}

function mksBand(score,planned){
  if(planned===0)return{label:"No plan",color:"#94a3b8"};
  if(score>=90)return{label:"Outstanding",color:"#059669"};
  if(score>=MKS_TARGET)return{label:"On target",color:"#16a34a"};
  if(score>=65)return{label:"Below target",color:"#d97706"};
  return{label:"Needs support",color:"#dc2626"}}
function mksClear(score,approval,planned){
  if(!planned)return{text:"NO PLAN",color:"#94a3b8"};
  if(approval==="Not Approved")return{text:"NOT CLEARED",color:"#dc2626"};
  if(score>=MKS_TARGET&&approval==="Approved")return{text:"CLEARED",color:"#059669"};
  if(score>=MKS_TARGET)return{text:"AWAITING MANAGER",color:"#d97706"};
  return{text:"NOT CLEARED",color:"#dc2626"}}

/* aggregate a date range. sums: {date: dayObj}; revs: {date: {approval}} (single staff) */
function mksAgg(sums,revs,from,to){
  var days=0,total=0,on=0,cl=0,np=0,nc=0,ev=0,bl=0,d=from,g=0;
  while(d<=to&&g<400){
    var s=sums[d];
    if(s&&s.planned>0){
      days++;total+=s.score;np+=s.planned;nc+=s.completed;ev+=s.ev;bl+=s.bl;
      if(s.score>=MKS_TARGET)on++;
      var rv=revs&&revs[d];if(s.score>=MKS_TARGET&&rv&&rv.approval==="Approved")cl++}
    d=mksAddDays(d,1);g++}
  var wd=mksWorkdays(from,to);
  return{days:days,avg:days?Math.round(total/days*10)/10:null,on:on,cleared:cl,planned:np,completed:nc,ev:ev,bl:bl,
    workdays:wd,consistency:wd?Math.min(100,Math.round(days/wd*100)):0,
    doneRate:np?Math.round(nc/np*100):0,evRate:np?Math.round(ev/np*100):0}}

/* ---------------- data layer: Supabase, with a device-only fallback ---------------- */
function mksMissing(err){
  if(!err)return false;
  var m=((err.message||"")+" "+(err.code||"")+" "+(err.details||"")).toLowerCase();
  return m.indexOf("does not exist")>-1||m.indexOf("schema cache")>-1||m.indexOf("42p01")>-1||m.indexOf("pgrst205")>-1||m.indexOf("could not find the table")>-1}
function mksLsGet(k,d){try{var v=localStorage.getItem(k);return v?JSON.parse(v):d}catch(x){return d}}
function mksLsSet(k,v){try{localStorage.setItem(k,JSON.stringify(v))}catch(x){}}
async function mksPaged(build){
  var out=[],from=0,step=1000,i;
  for(i=0;i<40;i++){
    var r=await build().range(from,from+step-1);
    if(r.error)return{error:r.error,data:out};
    out=out.concat(r.data||[]);
    if(!r.data||r.data.length<step)break;
    from+=step}
  return{data:out}}

var mksApi={
  mode:"db",
  probed:null,
  probe:function(){
    if(mksApi.probed)return mksApi.probed;
    mksApi.probed=M.from("staff_tasks").select("id").limit(1).then(function(r){
      if(r.error&&mksMissing(r.error))mksApi.mode="local";
      return mksApi.mode}).catch(function(){return mksApi.mode});
    return mksApi.probed},
  reset:function(){mksApi.probed=null;mksApi.mode="db"},

  /* staff membership */
  loadMember:async function(uid){
    var r=await M.from("staff_members").select("*").eq("user_id",uid).maybeSingle();
    if(r.error)return{error:r.error,missing:mksMissing(r.error)};
    return{data:r.data||null}},
  requestStaff:async function(uid,position,manager){
    var row={user_id:uid,position:position,line_manager:manager||"",status:"pending"};
    var r=await M.from("staff_members").upsert(row,{onConflict:"user_id",ignoreDuplicates:true}).select().maybeSingle();
    if(r.error)return{error:r.error,missing:mksMissing(r.error)};
    return{data:r.data||row}},
  loadMembers:async function(){
    var r=await mksPaged(function(){return M.from("staff_members").select("*").order("created_at",{ascending:true})});
    if(r.error)return{error:r.error,missing:mksMissing(r.error)};
    return{data:r.data}},
  updateMember:async function(uid,patch){
    var r=await M.from("staff_members").update(patch).eq("user_id",uid);
    return{error:r.error}},

  /* daily tasks */
  loadTasks:async function(uid,date){
    if(mksApi.mode==="local")return mksLsGet("mks:t:"+uid+":"+date,[]);
    var r=await M.from("staff_tasks").select("*").eq("user_id",uid).eq("task_date",date).order("position",{ascending:true});
    if(r.error){if(mksMissing(r.error)){mksApi.mode="local";return mksLsGet("mks:t:"+uid+":"+date,[])}throw r.error}
    mksLsSet("mks:t:"+uid+":"+date,r.data||[]);
    return r.data||[]},
  saveTask:async function(task,all){
    mksLsSet("mks:t:"+task.user_id+":"+task.task_date,all);
    if(mksApi.mode==="local")return{local:true};
    var row={id:task.id,user_id:task.user_id,task_date:task.task_date,position:task.position,title:task.title||"",quadrant:task.quadrant,expected:task.expected||"",
      completion:Math.max(0,Math.min(100,Math.round(Number(task.completion)||0))),evidence:task.evidence||"",status:task.status,blocker:task.blocker||"",next_action:task.next_action||"",notes:task.notes||"",updated_at:new Date().toISOString()};
    var r=await M.from("staff_tasks").upsert(row,{onConflict:"id"});
    if(r.error){if(mksMissing(r.error)){mksApi.mode="local";return{local:true}}throw r.error}
    return{}},
  deleteTask:async function(task,all){
    mksLsSet("mks:t:"+task.user_id+":"+task.task_date,all);
    if(mksApi.mode==="local")return{local:true};
    var r=await M.from("staff_tasks").delete().eq("id",task.id);
    if(r.error)throw r.error;
    return{}},

  /* daily summaries (one row per staff per day) */
  loadSummary:async function(uid,from,to){
    var out={};
    if(mksApi.mode==="local"){
      var i,k,pre="mks:t:"+uid+":";
      try{for(i=0;i<localStorage.length;i++){k=localStorage.key(i);
        if(k&&k.indexOf(pre)===0){var dt=k.slice(pre.length);if(dt>=from&&dt<=to){var s=mksDay(mksLsGet(k,[]));if(s.planned>0)out[dt]=s}}}}catch(x){}
      return out}
    var r=await mksPaged(function(){return M.from("staff_daily_summary").select("*").eq("user_id",uid).gte("task_date",from).lte("task_date",to).order("task_date",{ascending:true})});
    if(r.error){if(mksMissing(r.error)){mksApi.mode="local";return mksApi.loadSummary(uid,from,to)}throw r.error}
    r.data.forEach(function(x){out[x.task_date]=mksFromRow(x)});
    return out},
  loadSummaryAll:async function(from,to){
    var r=await mksPaged(function(){return M.from("staff_daily_summary").select("*").gte("task_date",from).lte("task_date",to).order("task_date",{ascending:true})});
    if(r.error)return{error:r.error,missing:mksMissing(r.error)};
    var by={};
    r.data.forEach(function(x){(by[x.user_id]||(by[x.user_id]={}))[x.task_date]=mksFromRow(x)});
    return{data:by}},

  /* manager reviews (daily clearance) */
  loadReviews:async function(uid,from,to){
    var out={};
    if(mksApi.mode==="local")return out;
    var r=await mksPaged(function(){var q=M.from("staff_day_reviews").select("*").gte("task_date",from).lte("task_date",to).order("task_date",{ascending:true});return uid?q.eq("user_id",uid):q});
    if(r.error)return uid?out:{error:r.error};
    if(uid){r.data.forEach(function(x){out[x.task_date]={approval:x.approval,comment:x.comment||""}});return out}
    var by={};
    r.data.forEach(function(x){(by[x.user_id]||(by[x.user_id]={}))[x.task_date]={approval:x.approval,comment:x.comment||""}});
    return{data:by}},
  saveReview:async function(uid,date,approval,comment,adminId){
    var r=await M.from("staff_day_reviews").upsert({user_id:uid,task_date:date,approval:approval,comment:comment||"",reviewed_by:adminId||null,reviewed_at:new Date().toISOString()},{onConflict:"user_id,task_date"});
    return{error:r.error}},

  /* weekly plan */
  loadPlan:async function(uid,week){
    var key="mks:w:"+uid+":"+week;
    if(mksApi.mode==="local")return mksLsGet(key,{objective:"",items:[]});
    var r=await M.from("staff_weekly_plans").select("*").eq("user_id",uid).eq("week_start",week).maybeSingle();
    if(r.error){if(mksMissing(r.error)){mksApi.mode="local";return mksLsGet(key,{objective:"",items:[]})}throw r.error}
    var p=r.data?{objective:r.data.objective||"",items:Array.isArray(r.data.items)?r.data.items:[]}:{objective:"",items:[]};
    mksLsSet(key,p);return p},
  savePlan:async function(uid,week,plan){
    mksLsSet("mks:w:"+uid+":"+week,plan);
    if(mksApi.mode==="local")return{local:true};
    var r=await M.from("staff_weekly_plans").upsert({user_id:uid,week_start:week,objective:plan.objective||"",items:plan.items||[],updated_at:new Date().toISOString()},{onConflict:"user_id,week_start"});
    if(r.error){if(mksMissing(r.error)){mksApi.mode="local";return{local:true}}throw r.error}
    return{}},

  /* admin: one staff member's tasks on a day */
  tasksFor:async function(uid,date){
    var r=await M.from("staff_tasks").select("*").eq("user_id",uid).eq("task_date",date).order("position",{ascending:true});
    return r.error?[]:(r.data||[])}
};

/* ---------------- small UI helpers ---------------- */
function mkh(tag,props){
  var ch=[],i,c;
  for(i=2;i<arguments.length;i++){c=arguments[i];if(Array.isArray(c))ch=ch.concat(c);else ch.push(c)}
  ch=ch.filter(function(x){return x!==null&&x!==void 0&&x!==!1});
  var p=Object.assign({},props||{});
  if(ch.length)p.children=ch.length===1?ch[0]:ch;
  return ch.length>1?t(tag,p):e(tag,p)}
function mksInput(T){
  return{width:"100%",padding:"9px 11px",borderRadius:9,border:"1.5px solid "+T.inpBdr,fontSize:13,background:T.inpBg,color:T.txt,fontFamily:"Nunito,sans-serif",outline:"none",boxSizing:"border-box"}}
function mksLabel(T){
  return{display:"block",fontSize:10,fontWeight:800,color:T.muted,marginBottom:4,textTransform:"uppercase",letterSpacing:.5}}
function mksBadge(text,color,solid){
  return mkh("span",{style:{display:"inline-block",fontSize:10.5,fontWeight:800,padding:"3px 9px",borderRadius:99,letterSpacing:.3,whiteSpace:"nowrap",
    background:solid?color:color+"22",color:solid?"#fff":color,border:solid?"none":"1px solid "+color+"55"}},text)}
function mksTile(T,label,value,color,sub){
  return mkh("div",{style:{background:T.card,border:"1px solid "+T.border,borderRadius:14,padding:"12px 14px",boxShadow:T.shadow,minWidth:0}},
    mkh("div",{style:{fontSize:10,fontWeight:800,color:T.muted,textTransform:"uppercase",letterSpacing:.5,marginBottom:5}},label),
    mkh("div",{style:{fontSize:(String(value).length<=6?22:String(value).length<=10?17:14),fontWeight:900,color:color||T.head,fontFamily:"Outfit,sans-serif",lineHeight:1.2,overflowWrap:"break-word"}},value),
    sub?mkh("div",{style:{fontSize:11,color:T.muted,marginTop:3}},sub):null)}
function mksRing(T,score,size,color){
  var r=size/2-9,c=2*Math.PI*r,off=c*(1-Math.max(0,Math.min(100,score))/100),h=size/2;
  return mkh("svg",{width:size,height:size,viewBox:"0 0 "+size+" "+size,style:{flexShrink:0}},
    mkh("circle",{cx:h,cy:h,r:r,fill:"none",stroke:T.alt,strokeWidth:10}),
    mkh("circle",{cx:h,cy:h,r:r,fill:"none",stroke:color,strokeWidth:10,strokeLinecap:"round",strokeDasharray:c,strokeDashoffset:off,transform:"rotate(-90 "+h+" "+h+")"}),
    mkh("text",{x:h,y:h+size/12,textAnchor:"middle",fontSize:size/4.2,fontWeight:900,fill:T.head,fontFamily:"Outfit,sans-serif"},Math.round(score)+"%"))}
function mksBars(T,data,h){
  var n=data.length,W=Math.max(480,n*56),H=h||150,bw=Math.min(30,W/n*.62),ty=H-(H-10)*MKS_TARGET/100;
  return mkh("svg",{viewBox:"0 0 "+W+" "+(H+26),style:{width:"100%",height:"auto",maxHeight:210,display:"block"},role:"img","aria-label":"Score chart"},
    mkh("line",{x1:0,x2:W,y1:ty,y2:ty,stroke:"#94a3b8",strokeDasharray:"4 4",strokeWidth:1}),
    mkh("text",{x:W-2,y:ty-3,textAnchor:"end",fontSize:9,fill:T.muted},"target "+MKS_TARGET+"%"),
    data.map(function(d,i){
      var x=i*(W/n)+(W/n-bw)/2,v=d.value==null?0:d.value,bh=d.value==null?0:Math.max(2,(H-10)*v/100);
      return mkh("g",{key:i},
        mkh("rect",{x:x,y:H-bh,width:bw,height:d.value==null?0:bh,rx:4,fill:d.value==null?T.alt:mksBand(v,1).color}),
        d.value!=null?mkh("text",{x:x+bw/2,y:H-bh-4,textAnchor:"middle",fontSize:10,fontWeight:700,fill:T.txt},Math.round(v)):null,
        mkh("text",{x:x+bw/2,y:H+15,textAnchor:"middle",fontSize:10,fill:T.muted},d.label))}))}
function mksHeat(T,anchor,sums,onPick,sel){
  var first=mksMonthStart(anchor),last=mksMonthEnd(anchor),lead=(mksDate(first).getDay()+6)%7,cells=[],i,d=first,names=["Mon","Tue","Wed","Thu","Fri","Sat","Sun"];
  for(i=0;i<lead;i++)cells.push(mkh("div",{key:"b"+i}));
  while(d<=last){
    (function(day){
      var s=sums[day],has=s&&s.planned>0,col=has?mksBand(s.score,1).color:T.alt,isSel=day===sel;
      cells.push(mkh("button",{key:day,onClick:function(){onPick(day)},title:mksNice(day)+(has?" \u00b7 "+Math.round(s.score)+"%":" \u00b7 no plan"),
        style:{aspectRatio:"1 / 1",minHeight:38,borderRadius:9,border:isSel?"2px solid "+T.head:"1px solid "+T.border,background:col,color:has?"#fff":T.muted,cursor:"pointer",fontFamily:"inherit",padding:2,display:"flex",flexDirection:"column",alignItems:"center",justifyContent:"center",lineHeight:1.1}},
        mkh("span",{style:{fontSize:11,fontWeight:800}},+day.slice(8)),
        has?mkh("span",{style:{fontSize:9.5,fontWeight:700,opacity:.95}},Math.round(s.score)):null))})(d);
    d=mksAddDays(d,1)}
  return mkh("div",{style:{maxWidth:460}},
    mkh("div",{style:{display:"grid",gridTemplateColumns:"repeat(7,1fr)",gap:5,marginBottom:5}},names.map(function(x){return mkh("div",{key:x,style:{fontSize:10,fontWeight:800,color:T.muted,textAlign:"center"}},x)})),
    mkh("div",{style:{display:"grid",gridTemplateColumns:"repeat(7,1fr)",gap:5}},cells))}
function mksCsv(rows,name){
  var csv=rows.map(function(r){return r.map(function(c){var s=String(c==null?"":c);return/[",\n]/.test(s)?'"'+s.replace(/"/g,'""')+'"':s}).join(",")}).join("\r\n");
  try{var b=new Blob(["\ufeff"+csv],{type:"text/csv;charset=utf-8"}),a=document.createElement("a");a.href=URL.createObjectURL(b);a.download=name;document.body.appendChild(a);a.click();setTimeout(function(){document.body.removeChild(a);URL.revokeObjectURL(a.href)},400)}catch(x){alert("Could not create the file.")}}
