/* MindKlass staff performance module: the staff member's daily/weekly/monthly/yearly tracker page. */

function MkStaffHub(props){
  var T=props.T,isMobile=props.isMobile,card=props.card,bP=props.bP,bO=props.bO,user=props.user,staff=props.staff,onStaff=props.onStaff;
  var uid=user&&user.id;
  var s1=f("today"),tab=s1[0],setTab=s1[1];
  var s2=f(mksToday()),date=s2[0],setDateRaw=s2[1];
  var s3=f([]),tasks=s3[0],setTasks=s3[1];
  var s4=f(!0),loading=s4[0],setLoading=s4[1];
  var s5=f("db"),mode=s5[0],setMode=s5[1];
  var s6=f(""),saveMsg=s6[0],setSaveMsg=s6[1];
  var s7=f({}),sums=s7[0],setSums=s7[1];
  var s8=f({}),revs=s8[0],setRevs=s8[1];
  var s9=f({objective:"",items:[]}),plan=s9[0],setPlan=s9[1];
  var s10=f(0),tick=s10[0],setTick=s10[1];
  var s11=f({}),open=s11[0],setOpen=s11[1];
  var s12=f(""),reqPos=s12[0],setReqPos=s12[1];
  var s13=f(""),reqOther=s13[0],setReqOther=s13[1];
  var s14=f(""),reqMgr=s14[0],setReqMgr=s14[1];
  var s15=f(!1),reqBusy=s15[0],setReqBusy=s15[1];
  var s16=f(""),reqErr=s16[0],setReqErr=s16[1];
  var tasksRef=Re(tasks);tasksRef.current=tasks;
  var planRef=Re(plan);planRef.current=plan;
  var timers=Re({});
  var planTimer=Re(null);

  var approved=!!(staff&&staff.status==="approved");
  var allowed=approved||mode==="local";
  var inp=mksInput(T),lab=mksLabel(T);

  de(function(){var live=!0;mksApi.probe().then(function(m){if(live)setMode(m)});return function(){live=!1}},[]);

  /* load the selected day */
  de(function(){
    if(!uid||!allowed)return;
    var live=!0;setLoading(!0);
    mksApi.loadTasks(uid,date).then(function(rows){if(!live)return;tasksRef.current=rows;setTasks(rows);setLoading(!1)})
      .catch(function(x){if(!live)return;setLoading(!1);setSaveMsg("Could not load: "+(x&&x.message||"error"))});
    return function(){live=!1}},[uid,date,allowed,mode]);

  /* load the year of summaries and manager reviews */
  var yr=date.slice(0,4);
  de(function(){
    if(!uid||!allowed)return;
    var live=!0;
    mksApi.loadSummary(uid,yr+"-01-01",yr+"-12-31").then(function(m){if(live)setSums(m)}).catch(function(){});
    mksApi.loadReviews(uid,yr+"-01-01",yr+"-12-31").then(function(m){if(live)setRevs(m||{})}).catch(function(){});
    return function(){live=!1}},[uid,allowed,yr,mode,tick]);

  /* weekly plan */
  var weekStart=mksMonday(date);
  de(function(){
    if(!uid||!allowed)return;
    var live=!0;
    mksApi.loadPlan(uid,weekStart).then(function(p){if(live){planRef.current=p;setPlan(p)}}).catch(function(){});
    return function(){live=!1}},[uid,allowed,weekStart,mode]);

  function flush(){
    Object.keys(timers.current).forEach(function(id){
      clearTimeout(timers.current[id]);delete timers.current[id];
      var cur=tasksRef.current.find(function(x){return x.id===id});
      if(cur)mksApi.saveTask(cur,tasksRef.current).catch(function(){})})}
  function setDate(d){flush();setDateRaw(d)}

  function persist(task){
    setSaveMsg("Saving\u2026");
    clearTimeout(timers.current[task.id]);
    timers.current[task.id]=setTimeout(function(){
      delete timers.current[task.id];
      var cur=tasksRef.current.find(function(x){return x.id===task.id});
      if(!cur)return;
      mksApi.saveTask(cur,tasksRef.current).then(function(r){
        setSaveMsg(r&&r.local?"Saved on this device only":"All changes saved");
        if(r&&r.local)setMode("local");
        setTick(function(n){return n+1})
      }).catch(function(x){setSaveMsg("Not saved: "+(x&&x.message||"check your connection")+" \u2014 will retry on your next change")})},700)}
  function upd(id,patch){
    var cur=tasksRef.current.find(function(k){return k.id===id});
    if(!cur)return;
    patch=Object.assign({},patch);
    if(patch.status==="Completed")patch.completion=100;
    if(patch.completion!==void 0){
      var c=Math.max(0,Math.min(100,Math.round(+patch.completion||0)));patch.completion=c;
      if(c>=100)patch.status="Completed";
      else if(c>0&&(cur.status==="Not Started"||cur.status==="Completed"))patch.status="In Progress";
      else if(c===0&&cur.status==="Completed")patch.status="Not Started"}
    var next=tasksRef.current.map(function(k){return k.id===id?Object.assign({},k,patch):k});
    tasksRef.current=next;setTasks(next);
    persist(next.find(function(k){return k.id===id}))}
  function addTask(prefill){
    if(tasksRef.current.length>=20){alert("You can plan up to 20 tasks in one day.");return}
    var mx=0;tasksRef.current.forEach(function(k){if(k.position>mx)mx=k.position});
    var nt=Object.assign(mksNewTask(uid,date,mx+1),prefill||{});
    var next=tasksRef.current.concat([nt]);tasksRef.current=next;setTasks(next);persist(nt)}
  function removeTask(k){
    if(!window.confirm("Remove this task from your plan?"))return;
    clearTimeout(timers.current[k.id]);delete timers.current[k.id];
    var next=tasksRef.current.filter(function(x){return x.id!==k.id});
    tasksRef.current=next;setTasks(next);
    mksApi.deleteTask(k,next).then(function(){setSaveMsg("All changes saved");setTick(function(n){return n+1})}).catch(function(x){setSaveMsg("Not removed: "+(x&&x.message||"error"))})}
  function carryOver(){
    (async function(){
      var i,d,rows,inc;
      for(i=1;i<=7;i++){
        d=mksAddDays(date,-i);rows=await mksApi.loadTasks(uid,d);
        inc=rows.filter(function(k){return String(k.title||"").trim()&&(+k.completion||0)<100});
        if(inc.length){inc.forEach(function(k){addTask({title:k.title,quadrant:k.quadrant,expected:k.expected,next_action:k.next_action,notes:"Carried over from "+mksShort(d)})});return}}
      alert("No unfinished tasks found in the last 7 days.")})()}

  /* weekly plan saving */
  function setPlanSaved(p){
    planRef.current=p;setPlan(p);
    clearTimeout(planTimer.current);
    planTimer.current=setTimeout(function(){
      mksApi.savePlan(uid,weekStart,planRef.current).then(function(r){setSaveMsg(r&&r.local?"Saved on this device only":"All changes saved")}).catch(function(x){setSaveMsg("Plan not saved: "+(x&&x.message||"error"))})},800)}
  function planItem(i,patch){
    var items=planRef.current.items.map(function(x,n){return n===i?Object.assign({},x,patch):x});
    setPlanSaved({objective:planRef.current.objective,items:items})}
  function sendToDay(item,day){
    var nt=Object.assign(mksNewTask(uid,day,1),{title:item.title||"",quadrant:item.priority||"Q2",expected:item.kpi||"",notes:"From weekly plan"});
    if(day===date){addTask({title:nt.title,quadrant:nt.quadrant,expected:nt.expected,notes:nt.notes});return}
    mksApi.loadTasks(uid,day).then(function(rows){
      var mx=0;rows.forEach(function(k){if(k.position>mx)mx=k.position});nt.position=mx+1;
      var all=rows.concat([nt]);
      return mksApi.saveTask(nt,all)}).then(function(){alert("Added to "+mksNice(day)+".");setTick(function(n){return n+1})}).catch(function(x){alert("Could not add: "+(x&&x.message||"error"))})}

  /* ---------- derived numbers ---------- */
  var cur=mksDay(tasks);
  var sumsNow=Object.assign({},sums);
  if(cur.planned>0)sumsNow[date]=cur;else delete sumsNow[date];
  var rev=revs[date]||{approval:"Pending",comment:""};
  var band=mksBand(cur.score,cur.planned),clr=mksClear(cur.score,rev.approval,cur.planned);

  /* ---------- gates ---------- */
  function shell(){
    var kids=Array.prototype.slice.call(arguments);
    return mkh("div",{style:{maxWidth:1100,margin:"0 auto",width:"100%"}},
      mkh("div",{style:{background:"linear-gradient(135deg,#0d1f4b,#1842a8)",borderRadius:18,padding:isMobile?16:22,marginBottom:14,color:"#fff"}},
        mkh("div",{style:{fontSize:10,letterSpacing:2,textTransform:"uppercase",opacity:.7,marginBottom:5}},"MindKlass team"),
        mkh("h1",{style:{fontSize:isMobile?22:28,fontWeight:900,fontFamily:"Outfit,sans-serif",margin:"0 0 6px"}},"My Daily Tracker"),
        mkh("p",{style:{fontSize:13,opacity:.9,margin:0,lineHeight:1.6,maxWidth:680}},"Plan your day, rank each task by priority, record evidence, and see your score for the day, week, month and year.")),
      kids)}

  if(!uid)return shell(mkh("div",{style:card},"Please sign in to use the staff tracker."));

  if(!allowed){
    if(!staff){
      var sendReq=function(){
        var pos=reqPos==="Other (type your position)"?reqOther.trim():reqPos;
        if(!pos){setReqErr("Please choose your position.");return}
        setReqErr("");setReqBusy(!0);
        mksApi.requestStaff(uid,pos,reqMgr.trim()).then(function(r){
          setReqBusy(!1);
          if(r.error){setReqErr(r.missing?"The staff database has not been set up yet. Please ask the administrator to run "+MKS_SQL_FILE+" in Supabase.":(r.error.message||"Could not send your request."));return}
          if(onStaff)onStaff()})};
      return shell(mkh("div",{style:Object.assign({},card,{maxWidth:640})},
        mkh("h2",{style:{fontSize:17,fontWeight:900,color:T.head,fontFamily:"Outfit,sans-serif",margin:"0 0 6px"}},"Request staff access"),
        mkh("p",{style:{fontSize:13,color:T.muted,margin:"0 0 14px",lineHeight:1.6}},"The tracker is for MindKlass team members. Tell us your position. An administrator will approve your request."),
        mkh("label",{style:lab},"Your position"),
        mkh("select",{style:Object.assign({},inp,{marginBottom:10}),value:reqPos,onChange:function(ev){setReqPos(ev.target.value)}},
          mkh("option",{value:""},"- Select your position -"),MKS_POSITIONS.map(function(p){return mkh("option",{key:p,value:p},p)})),
        reqPos==="Other (type your position)"?mkh("div",{style:{marginBottom:10}},mkh("label",{style:lab},"Type your position"),mkh("input",{style:inp,value:reqOther,onChange:function(ev){setReqOther(ev.target.value)}})):null,
        mkh("label",{style:lab},"Line manager (optional)"),
        mkh("input",{style:Object.assign({},inp,{marginBottom:12}),placeholder:"Who do you report to?",value:reqMgr,onChange:function(ev){setReqMgr(ev.target.value)}}),
        reqErr?mkh("div",{style:{background:"#fef2f2",border:"1px solid #fecaca",color:"#b91c1c",borderRadius:9,padding:"8px 11px",fontSize:12,marginBottom:10}},reqErr):null,
        mkh("button",{onClick:sendReq,disabled:reqBusy,style:Object.assign({},bP,{opacity:reqBusy?.6:1})},reqBusy?"Sending\u2026":"Send request")))}
    var msgs={pending:["Waiting for approval","Your staff request is with the administrator. You will see your tracker here as soon as it is approved.","#d97706"],
      rejected:["Request not approved","Your staff request was not approved. Please speak to the administrator.","#dc2626"],
      inactive:["Staff access paused","Your staff access is paused. Please speak to the administrator.","#64748b"]};
    var m=msgs[staff.status]||msgs.pending;
    return shell(mkh("div",{style:Object.assign({},card,{maxWidth:640,borderLeft:"5px solid "+m[2]})},
      mkh("h2",{style:{fontSize:17,fontWeight:900,color:T.head,fontFamily:"Outfit,sans-serif",margin:"0 0 6px"}},m[0]),
      mkh("p",{style:{fontSize:13,color:T.muted,margin:"0 0 8px",lineHeight:1.6}},m[1]),
      mkh("p",{style:{fontSize:12.5,color:T.txt,margin:0}},"Position: ",mkh("b",{},staff.position||"-"),staff.line_manager?" \u00b7 Line manager: "+staff.line_manager:"")))}

  /* ---------- shared pieces ---------- */
  var dateBar=mkh("div",{style:Object.assign({},card,{display:"flex",gap:8,flexWrap:"wrap",alignItems:"center",marginBottom:12,padding:isMobile?12:14})},
    mkh("button",{onClick:function(){setDate(mksAddDays(date,-1))},style:Object.assign({},bO,{padding:"8px 12px"}),"aria-label":"Previous day"},"\u2039"),
    mkh("input",{type:"date",value:date,onChange:function(ev){if(ev.target.value)setDate(ev.target.value)},style:Object.assign({},inp,{width:"auto",flex:"0 1 170px"})}),
    mkh("button",{onClick:function(){setDate(mksAddDays(date,1))},style:Object.assign({},bO,{padding:"8px 12px"}),"aria-label":"Next day"},"\u203a"),
    mkh("button",{onClick:function(){setDate(mksToday())},style:Object.assign({},bO,{padding:"8px 12px",fontSize:12})},"Today"),
    mkh("div",{style:{flex:1,minWidth:150,fontSize:12.5,color:T.txt,fontWeight:700}},mksNice(date)),
    mkh("div",{style:{fontSize:11.5,color:saveMsg.indexOf("Not")===0?"#dc2626":T.muted,fontWeight:700}},saveMsg));

  var profileBar=mkh("div",{style:{display:"flex",gap:8,flexWrap:"wrap",alignItems:"center",marginBottom:12}},
    mkh("span",{style:{fontSize:13,fontWeight:800,color:T.head}},user.name||user.nick||"Staff"),
    staff&&staff.position?mksBadge(staff.position,"#2158e8"):null,
    staff&&staff.line_manager?mkh("span",{style:{fontSize:12,color:T.muted}},"Line manager: "+staff.line_manager):null);

  var banner=mode==="local"?mkh("div",{style:{background:"#fffbeb",border:"1px solid #fde68a",color:"#92400e",borderRadius:12,padding:"10px 13px",fontSize:12.5,lineHeight:1.55,marginBottom:12}},
    mkh("b",{},"Saved on this device only. "),"The staff database has not been set up yet, so your administrator cannot see these entries. Ask them to run ",mkh("code",{},MKS_SQL_FILE)," in Supabase (SQL editor), then reload."):null;

  var tabs=[["today","Today"],["week","Weekly plan"],["month","Month"],["year","Year"],["guide","How it works"]];
  var tabBar=mkh("div",{style:{display:"flex",gap:6,overflowX:"auto",marginBottom:12,paddingBottom:2}},tabs.map(function(x){
    var on=tab===x[0];
    return mkh("button",{key:x[0],onClick:function(){setTab(x[0])},style:{padding:"9px 16px",borderRadius:99,border:on?"none":"1.5px solid "+T.border,background:on?"#1842a8":T.card,color:on?"#fff":T.txt,fontWeight:800,fontSize:13,cursor:"pointer",fontFamily:"inherit",whiteSpace:"nowrap"}},x[1])}));

  /* ---------- TODAY ---------- */
  function taskCard(k,i){
    var q=MKS_QUAD[k.quadrant]||MKS_QUAD.Q2,isOpen=!!open[k.id],c=Math.max(0,Math.min(100,+k.completion||0)),url=/^https?:\/\//i.test(String(k.evidence||"").trim());
    var two=isMobile?"1fr":"1fr 1fr 1fr";
    return mkh("div",{key:k.id,style:{background:T.card,border:"1px solid "+T.border,borderLeft:"5px solid "+q.c,borderRadius:14,padding:isMobile?12:14,marginBottom:10,boxShadow:T.shadow}},
      mkh("div",{style:{display:"grid",gridTemplateColumns:isMobile?"1fr":"1fr 190px 70px",gap:10,alignItems:"end",marginBottom:10}},
        mkh("div",{},mkh("label",{style:lab},"Task "+(i+1)+" \u00b7 task / deliverable"),
          mkh("input",{style:inp,placeholder:"What exactly will you deliver today?",value:k.title,onChange:function(ev){upd(k.id,{title:ev.target.value})}})),
        mkh("div",{},mkh("label",{style:lab},"Priority (Eisenhower)"),
          mkh("select",{style:inp,value:k.quadrant,onChange:function(ev){upd(k.id,{quadrant:ev.target.value})}},Object.keys(MKS_QUAD).map(function(z){return mkh("option",{key:z,value:z},z+" \u00b7 "+MKS_QUAD[z].n+" ("+MKS_QUAD[z].w+")")}))),
        mkh("div",{style:{textAlign:isMobile?"left":"center"}},mkh("label",{style:lab},"Weight"),mkBadgeW(q))),
      mkh("div",{style:{display:"grid",gridTemplateColumns:two,gap:10,marginBottom:10}},
        mkh("div",{},mkh("label",{style:lab},"Why / expected output"),mkh("input",{style:inp,placeholder:"What does 'done' look like?",value:k.expected,onChange:function(ev){upd(k.id,{expected:ev.target.value})}})),
        mkh("div",{},mkh("label",{style:lab},"Evidence / work link"),
          mkh("div",{style:{display:"flex",gap:6}},mkh("input",{style:inp,placeholder:"Paste a Drive, doc or photo link",value:k.evidence,onChange:function(ev){upd(k.id,{evidence:ev.target.value})}}),
            url?mkh("a",{href:String(k.evidence).trim(),target:"_blank",rel:"noopener noreferrer",style:{display:"flex",alignItems:"center",padding:"0 10px",borderRadius:9,background:T.pale,color:"#1842a8",fontWeight:800,fontSize:12,textDecoration:"none"}},"Open"):null)),
        mkh("div",{},mkh("label",{style:lab},"Status"),mkh("select",{style:inp,value:k.status,onChange:function(ev){upd(k.id,{status:ev.target.value})}},MKS_STATUSES.map(function(z){return mkh("option",{key:z,value:z},z)})))),
      mkh("div",{style:{display:"flex",alignItems:"center",gap:10,flexWrap:"wrap"}},
        mkh("label",{style:Object.assign({},lab,{marginBottom:0})},"Completion"),
        mkh("input",{type:"range",min:0,max:100,step:5,value:c,onChange:function(ev){upd(k.id,{completion:+ev.target.value})},style:{flex:"1 1 160px",minWidth:120,accentColor:q.c}}),
        mkh("input",{type:"number",min:0,max:100,value:c,onChange:function(ev){upd(k.id,{completion:ev.target.value===""?0:+ev.target.value})},style:Object.assign({},inp,{width:72,textAlign:"center"}),"aria-label":"Completion percent"}),
        mkh("span",{style:{fontSize:12,fontWeight:800,color:T.muted}},"%"),
        mkh("button",{onClick:function(){upd(k.id,{completion:100})},style:Object.assign({},bO,{padding:"6px 12px",fontSize:12})},"Done"),
        mkh("button",{onClick:function(){var o=Object.assign({},open);o[k.id]=!o[k.id];setOpen(o)},style:Object.assign({},bO,{padding:"6px 12px",fontSize:12})},isOpen?"Hide details":"Blocker & notes"),
        mkh("button",{onClick:function(){removeTask(k)},style:{background:"none",border:"none",color:"#dc2626",fontWeight:800,fontSize:12,cursor:"pointer",padding:"6px 4px"}},"Remove")),
      isOpen?mkh("div",{style:{display:"grid",gridTemplateColumns:two,gap:10,marginTop:10}},
        mkh("div",{},mkh("label",{style:lab},"Blocker / dependency"),mkh("input",{style:inp,placeholder:"What stopped you?",value:k.blocker,onChange:function(ev){upd(k.id,{blocker:ev.target.value})}})),
        mkh("div",{},mkh("label",{style:lab},"Next action"),mkh("input",{style:inp,placeholder:"What happens next, and when?",value:k.next_action,onChange:function(ev){upd(k.id,{next_action:ev.target.value})}})),
        mkh("div",{},mkh("label",{style:lab},"Staff notes"),mkh("input",{style:inp,value:k.notes,onChange:function(ev){upd(k.id,{notes:ev.target.value})}}))):null)}
  function mkBadgeW(q){return mksBadge(q.w,q.c,!0)}

  var todayView=mkh("div",{},
    mkh("div",{style:{display:"grid",gridTemplateColumns:isMobile?"1fr":"260px 1fr",gap:12,marginBottom:12}},
      mkh("div",{style:Object.assign({},card,{display:"flex",alignItems:"center",gap:14,padding:14})},
        mksRing(T,cur.score,112,band.color),
        mkh("div",{},mkh("div",{style:{fontSize:10,fontWeight:800,color:T.muted,textTransform:"uppercase",letterSpacing:.5}},"Daily performance score"),
          mkh("div",{style:{margin:"5px 0"}},mksBadge(cur.planned?band.label.toUpperCase():"NO PLAN YET",band.color,!0)),
          mkh("div",{style:{fontSize:11.5,color:T.muted}},"Target "+MKS_TARGET+"%"))),
      mkh("div",{style:{display:"grid",gridTemplateColumns:isMobile?"1fr 1fr":"repeat(4,1fr)",gap:10}},
        mksTile(T,"Planned weight",cur.pw,null,"completed "+(Math.round(cur.cw*10)/10)),
        mksTile(T,"Tasks done",cur.completed+" / "+cur.planned,null,cur.planned?Math.round(cur.completed/cur.planned*100)+"% finished":""),
        mksTile(T,"Evidence",cur.ev+" / "+cur.planned,cur.planned&&cur.ev<cur.planned?"#d97706":"#059669","links attached"),
        mksTile(T,"Blocked",cur.bl,cur.bl?"#dc2626":T.head,"tasks with a blocker"),
        mksTile(T,"Manager approval",rev.approval,rev.approval==="Approved"?"#059669":rev.approval==="Not Approved"?"#dc2626":"#d97706"),
        mksTile(T,"Clearance",clr.text,clr.color),
        mkh("div",{style:{gridColumn:isMobile?"1 / -1":"span 2",background:T.card,border:"1px solid "+T.border,borderRadius:14,padding:"12px 14px",boxShadow:T.shadow}},
          mkh("div",{style:{fontSize:10,fontWeight:800,color:T.muted,textTransform:"uppercase",letterSpacing:.5,marginBottom:5}},"Manager comment"),
          mkh("div",{style:{fontSize:13,color:rev.comment?T.txt:T.muted,lineHeight:1.5}},rev.comment||"No comment yet.")))),
    loading?mkh("div",{style:Object.assign({},card,{textAlign:"center",color:T.muted})},"Loading your plan\u2026"):
    mkh("div",{},
      tasks.length===0?mkh("div",{style:Object.assign({},card,{textAlign:"center",marginBottom:10})},
        mkh("p",{style:{fontSize:14,fontWeight:800,color:T.head,margin:"0 0 6px"}},"No tasks planned for this day yet"),
        mkh("p",{style:{fontSize:12.5,color:T.muted,margin:"0 0 12px",lineHeight:1.6}},"Break your weekly plan into three to six specific tasks. Pick a priority for each, then update completion before you finish for the day.")):null,
      tasks.map(taskCard),
      mkh("div",{style:{display:"flex",gap:8,flexWrap:"wrap",marginBottom:12}},
        mkh("button",{onClick:function(){addTask()},style:Object.assign({},bP,{padding:"10px 18px"})},"+ Add task"),
        mkh("button",{onClick:carryOver,style:Object.assign({},bO,{padding:"10px 16px"})},"Carry over unfinished tasks"))),
    mkh("div",{style:Object.assign({},card,{background:T.alt,fontSize:12,color:T.muted,lineHeight:1.65})},
      mkh("b",{style:{color:T.txt}},"Fair-use note. "),"The tracker supports accountability, not long hours. A score below "+MKS_TARGET+"% starts a conversation about priorities, blockers, workload and support. You are fully cleared for a day when your score is "+MKS_TARGET+"% or more and your line manager approves."));

  /* ---------- WEEK ---------- */
  var wEnd=mksAddDays(weekStart,6),wAgg=mksAgg(sumsNow,revs,weekStart,wEnd);
  var wBars=[0,1,2,3,4,5,6].map(function(n){var d=mksAddDays(weekStart,n),s=sumsNow[d];return{label:["Mon","Tue","Wed","Thu","Fri","Sat","Sun"][n],value:s&&s.planned>0?s.score:null}});
  var wTotal=0;plan.items.forEach(function(x){wTotal+=+x.weight||0});
  var weekDays=[0,1,2,3,4,5,6].map(function(n){return mksAddDays(weekStart,n)});
  var weekView=mkh("div",{},
    mkh("div",{style:Object.assign({},card,{marginBottom:12})},
      mkh("div",{style:{display:"flex",justifyContent:"space-between",alignItems:"center",gap:8,flexWrap:"wrap",marginBottom:8}},
        mkh("div",{style:{fontSize:14,fontWeight:900,color:T.head,fontFamily:"Outfit,sans-serif"}},"Week of "+mksShort(weekStart)+" \u2013 "+mksShort(wEnd)),
        mkh("div",{style:{display:"flex",gap:6}},
          mkh("button",{onClick:function(){setDate(mksAddDays(weekStart,-7))},style:Object.assign({},bO,{padding:"6px 12px"})},"\u2039 Previous"),
          mkh("button",{onClick:function(){setDate(mksAddDays(weekStart,7))},style:Object.assign({},bO,{padding:"6px 12px"})},"Next \u203a"))),
      mksBars(T,wBars,140),
      mkh("div",{style:{display:"grid",gridTemplateColumns:isMobile?"1fr 1fr":"repeat(5,1fr)",gap:10,marginTop:10}},
        mksTile(T,"Weekly score",wAgg.avg==null?"-":Math.round(wAgg.avg)+"%",wAgg.avg==null?null:mksBand(wAgg.avg,1).color,wAgg.days+" planned day(s)"),
        mksTile(T,"On-target days",wAgg.on,null,"\u2265 "+MKS_TARGET+"%"),
        mksTile(T,"Cleared days",wAgg.cleared,"#059669","manager approved"),
        mksTile(T,"Tasks done",wAgg.completed+" / "+wAgg.planned),
        mksTile(T,"Evidence rate",wAgg.evRate+"%"))),
    mkh("div",{style:Object.assign({},card,{marginBottom:12})},
      mkh("h3",{style:{fontSize:14,fontWeight:900,color:T.head,fontFamily:"Outfit,sans-serif",margin:"0 0 8px"}},"Weekly plan \u2192 daily execution"),
      mkh("label",{style:lab},"Weekly objective"),
      mkh("textarea",{style:Object.assign({},inp,{minHeight:64,resize:"vertical",marginBottom:12}),placeholder:"What must be true by the end of this week?",value:plan.objective,onChange:function(ev){setPlanSaved({objective:ev.target.value,items:planRef.current.items})}}),
      plan.items.map(function(it,i){
        var q=MKS_QUAD[it.priority]||MKS_QUAD.Q2,three=isMobile?"1fr":"1fr 1fr 1fr 1fr";
        return mkh("div",{key:i,style:{border:"1px solid "+T.border,borderLeft:"5px solid "+q.c,borderRadius:12,padding:12,marginBottom:10,background:T.alt}},
          mkh("div",{style:{display:"grid",gridTemplateColumns:isMobile?"1fr":"2fr 2fr 1fr 90px",gap:10,marginBottom:8}},
            mkh("div",{},mkh("label",{style:lab},"Weekly task / deliverable"),mkh("input",{style:inp,value:it.title||"",onChange:function(ev){planItem(i,{title:ev.target.value})}})),
            mkh("div",{},mkh("label",{style:lab},"Expected output / KPI"),mkh("input",{style:inp,value:it.kpi||"",onChange:function(ev){planItem(i,{kpi:ev.target.value})}})),
            mkh("div",{},mkh("label",{style:lab},"Priority"),mkh("select",{style:inp,value:it.priority||"Q2",onChange:function(ev){planItem(i,{priority:ev.target.value})}},Object.keys(MKS_QUAD).map(function(z){return mkh("option",{key:z,value:z},z)}))),
            mkh("div",{},mkh("label",{style:lab},"Weight %"),mkh("input",{style:inp,type:"number",min:0,max:100,value:it.weight==null?"":it.weight,onChange:function(ev){planItem(i,{weight:ev.target.value===""?"":+ev.target.value})}}))),
          mkh("div",{style:{display:"grid",gridTemplateColumns:three,gap:10,marginBottom:8}},
            mkh("div",{},mkh("label",{style:lab},"Owner"),mkh("input",{style:inp,value:it.owner||"",onChange:function(ev){planItem(i,{owner:ev.target.value})}})),
            mkh("div",{},mkh("label",{style:lab},"Due date"),mkh("input",{style:inp,type:"date",value:it.due||"",onChange:function(ev){planItem(i,{due:ev.target.value})}})),
            mkh("div",{},mkh("label",{style:lab},"Status"),mkh("select",{style:inp,value:it.status||"Not Started",onChange:function(ev){planItem(i,{status:ev.target.value})}},MKS_STATUSES.map(function(z){return mkh("option",{key:z,value:z},z)}))),
            mkh("div",{},mkh("label",{style:lab},"Notes / links"),mkh("input",{style:inp,value:it.notes||"",onChange:function(ev){planItem(i,{notes:ev.target.value})}}))),
          mkh("div",{style:{display:"flex",gap:8,flexWrap:"wrap",alignItems:"center"}},
            mkh("select",{style:Object.assign({},inp,{width:"auto"}),value:it._day||(weekDays.indexOf(date)>-1?date:weekDays[0]),onChange:function(ev){planItem(i,{_day:ev.target.value})},"aria-label":"Day to add to"},weekDays.map(function(d){return mkh("option",{key:d,value:d},mksNice(d))})),
            mkh("button",{onClick:function(){if(!String(it.title||"").trim()){alert("Give the task a name first.");return}sendToDay(it,it._day||(weekDays.indexOf(date)>-1?date:weekDays[0]))},style:Object.assign({},bO,{padding:"7px 13px",fontSize:12})},"Add to daily plan"),
            mkh("button",{onClick:function(){setPlanSaved({objective:planRef.current.objective,items:planRef.current.items.filter(function(x,n){return n!==i})})},style:{background:"none",border:"none",color:"#dc2626",fontWeight:800,fontSize:12,cursor:"pointer"}},"Remove")))}),
      mkh("div",{style:{display:"flex",gap:10,alignItems:"center",flexWrap:"wrap"}},
        mkh("button",{onClick:function(){if(planRef.current.items.length>=20){alert("Up to 20 weekly tasks.");return}setPlanSaved({objective:planRef.current.objective,items:planRef.current.items.concat([{title:"",kpi:"",priority:"Q2",weight:"",owner:"",due:"",status:"Not Started",notes:""}])})},style:Object.assign({},bP,{padding:"9px 16px"})},"+ Add weekly task"),
        mkh("span",{style:{fontSize:12,fontWeight:700,color:wTotal===100||!plan.items.length?T.muted:"#d97706"}},"Weights add up to "+wTotal+"%"+(wTotal===100?" \u2713":" (aim for 100%)")))));

  /* ---------- MONTH ---------- */
  var mStart=mksMonthStart(date),mEnd=mksMonthEnd(date),mAgg=mksAgg(sumsNow,revs,mStart,mEnd);
  var weeks=[],wd=mksMonday(mStart);
  while(wd<=mEnd){var a=wd<mStart?mStart:wd,b=mksAddDays(wd,6)>mEnd?mEnd:mksAddDays(wd,6);weeks.push({from:a,to:b,agg:mksAgg(sumsNow,revs,a,b)});wd=mksAddDays(wd,7)}
  var quad={Q1:0,Q2:0,Q3:0,Q4:0};
  var monthView=mkh("div",{},
    mkh("div",{style:Object.assign({},card,{marginBottom:12})},
      mkh("div",{style:{display:"flex",justifyContent:"space-between",alignItems:"center",gap:8,flexWrap:"wrap",marginBottom:10}},
        mkh("div",{style:{fontSize:15,fontWeight:900,color:T.head,fontFamily:"Outfit,sans-serif"}},MKS_MONTHS[+date.slice(5,7)-1]+" "+date.slice(0,4)),
        mkh("div",{style:{display:"flex",gap:6}},
          mkh("button",{onClick:function(){setDate(mksAddMonths(date,-1))},style:Object.assign({},bO,{padding:"6px 12px"})},"\u2039 Previous"),
          mkh("button",{onClick:function(){setDate(mksAddMonths(date,1))},style:Object.assign({},bO,{padding:"6px 12px"})},"Next \u203a"))),
      mksHeat(T,date,sumsNow,function(d){setDate(d);setTab("today")},date),
      mkh("div",{style:{display:"flex",gap:12,flexWrap:"wrap",marginTop:10,fontSize:11,color:T.muted}},
        [["#059669","90%+"],["#16a34a","80\u201389%"],["#d97706","65\u201379%"],["#dc2626","under 65%"]].map(function(x){return mkh("span",{key:x[1],style:{display:"inline-flex",alignItems:"center",gap:5}},mkh("i",{style:{width:11,height:11,borderRadius:3,background:x[0],display:"inline-block"}}),x[1])}),
        mkh("span",{},"Tap a day to open it"))),
    mkh("div",{style:{display:"grid",gridTemplateColumns:isMobile?"1fr 1fr":"repeat(4,1fr)",gap:10,marginBottom:12}},
      mksTile(T,"Monthly score",mAgg.avg==null?"-":Math.round(mAgg.avg)+"%",mAgg.avg==null?null:mksBand(mAgg.avg,1).color,"average of planned days"),
      mksTile(T,"Days planned",mAgg.days+" / "+mAgg.workdays,null,mAgg.consistency+"% planning consistency"),
      mksTile(T,"On-target days",mAgg.on,null,"\u2265 "+MKS_TARGET+"%"),
      mksTile(T,"Cleared days",mAgg.cleared,"#059669","manager approved"),
      mksTile(T,"Tasks done",mAgg.completed+" / "+mAgg.planned,null,mAgg.doneRate+"% finished"),
      mksTile(T,"Evidence rate",mAgg.evRate+"%",null,"tasks with a link"),
      mksTile(T,"Blocked tasks",mAgg.bl,mAgg.bl?"#dc2626":null),
      mksTile(T,"Rating",mAgg.avg==null?"No plan":mksBand(mAgg.avg,1).label,mAgg.avg==null?"#94a3b8":mksBand(mAgg.avg,1).color))
    ,mkh("div",{style:card},
      mkh("h3",{style:{fontSize:14,fontWeight:900,color:T.head,fontFamily:"Outfit,sans-serif",margin:"0 0 8px"}},"Week by week"),
      weeks.map(function(w,i){return mkh("div",{key:i,style:{display:"flex",justifyContent:"space-between",gap:8,padding:"8px 0",borderTop:i?"1px solid "+T.border:"none",fontSize:13,color:T.txt,flexWrap:"wrap"}},
        mkh("span",{style:{fontWeight:700}},mksShort(w.from)+" \u2013 "+mksShort(w.to)),
        mkh("span",{style:{color:T.muted}},w.agg.days+" day(s) \u00b7 "+w.agg.completed+"/"+w.agg.planned+" tasks"),
        mkh("span",{style:{fontWeight:800,color:w.agg.avg==null?T.muted:mksBand(w.agg.avg,1).color}},w.agg.avg==null?"-":Math.round(w.agg.avg)+"%"))})));

  /* ---------- YEAR ---------- */
  var yAgg=mksAgg(sumsNow,revs,yr+"-01-01",yr+"-12-31");
  var months=[0,1,2,3,4,5,6,7,8,9,10,11].map(function(n){var s=yr+"-"+mksPad(n+1)+"-01";return{n:n,from:s,to:mksMonthEnd(s),agg:mksAgg(sumsNow,revs,s,mksMonthEnd(s))}});
  var best=null;months.forEach(function(m){if(m.agg.avg!=null&&(!best||m.agg.avg>best.agg.avg))best=m});
  var yearView=mkh("div",{},
    mkh("div",{style:Object.assign({},card,{marginBottom:12})},
      mkh("div",{style:{display:"flex",justifyContent:"space-between",alignItems:"center",gap:8,flexWrap:"wrap",marginBottom:8}},
        mkh("div",{style:{fontSize:15,fontWeight:900,color:T.head,fontFamily:"Outfit,sans-serif"}},"Year "+yr),
        mkh("div",{style:{display:"flex",gap:6}},
          mkh("button",{onClick:function(){setDate(mksAddMonths(date,-12))},style:Object.assign({},bO,{padding:"6px 12px"})},"\u2039 "+(+yr-1)),
          mkh("button",{onClick:function(){setDate(mksAddMonths(date,12))},style:Object.assign({},bO,{padding:"6px 12px"})},(+yr+1)+" \u203a"))),
      mksBars(T,months.map(function(m){return{label:MKS_MONTHS[m.n].slice(0,3),value:m.agg.avg}}),160)),
    mkh("div",{style:{display:"grid",gridTemplateColumns:isMobile?"1fr 1fr":"repeat(4,1fr)",gap:10,marginBottom:12}},
      mksTile(T,"Yearly score",yAgg.avg==null?"-":Math.round(yAgg.avg)+"%",yAgg.avg==null?null:mksBand(yAgg.avg,1).color,"average of planned days"),
      mksTile(T,"Days planned",yAgg.days,null,yAgg.consistency+"% of working days"),
      mksTile(T,"On-target days",yAgg.on,null,"\u2265 "+MKS_TARGET+"%"),
      mksTile(T,"Cleared days",yAgg.cleared,"#059669"),
      mksTile(T,"Tasks done",yAgg.completed+" / "+yAgg.planned,null,yAgg.doneRate+"% finished"),
      mksTile(T,"Evidence rate",yAgg.evRate+"%"),
      mksTile(T,"Blocked tasks",yAgg.bl),
      mksTile(T,"Best month",best?MKS_MONTHS[best.n]:"-",best?"#059669":null,best?Math.round(best.agg.avg)+"%":""))
    ,mkh("div",{style:{background:T.card,border:"1px solid "+T.border,borderRadius:14,boxShadow:T.shadow,overflow:"hidden"}},
      mkh("div",{style:{overflowX:"auto"}},mkh("table",{style:{width:"100%",borderCollapse:"collapse",fontSize:12.5,minWidth:480}},
        mkh("thead",{},mkh("tr",{style:{background:T.alt,color:T.muted,textAlign:"left"}},["Month","Days planned","Avg score","On target","Cleared","Tasks done"].map(function(h){return mkh("th",{key:h,style:{padding:"9px 12px",fontSize:10.5,textTransform:"uppercase",letterSpacing:.4}},h)}))),
        mkh("tbody",{},months.map(function(m){return mkh("tr",{key:m.n,style:{borderTop:"1px solid "+T.border,color:T.txt}},
          mkh("td",{style:{padding:"9px 12px",fontWeight:700}},MKS_MONTHS[m.n]),
          mkh("td",{style:{padding:"9px 12px"}},m.agg.days+" / "+m.agg.workdays),
          mkh("td",{style:{padding:"9px 12px",fontWeight:800,color:m.agg.avg==null?T.muted:mksBand(m.agg.avg,1).color}},m.agg.avg==null?"-":Math.round(m.agg.avg)+"%"),
          mkh("td",{style:{padding:"9px 12px"}},m.agg.on),
          mkh("td",{style:{padding:"9px 12px"}},m.agg.cleared),
          mkh("td",{style:{padding:"9px 12px"}},m.agg.completed+" / "+m.agg.planned))}))))));

  /* ---------- GUIDE ---------- */
  var guideView=mkh("div",{},
    mkh("div",{style:Object.assign({},card,{marginBottom:12})},
      mkh("h3",{style:{fontSize:15,fontWeight:900,color:T.head,fontFamily:"Outfit,sans-serif",margin:"0 0 8px"}},"Your day in eight steps"),
      mkh("ol",{style:{margin:0,paddingLeft:20,fontSize:13,color:T.txt,lineHeight:1.85}},
        ["Start each morning: pick the date and break your weekly plan into specific, measurable tasks.","Give every task a priority from the Eisenhower table below. The weight is added for you.","Update completion for each task before you finish (0 to 100%).","Paste evidence: a Drive, document, email, photo or report link.","If a task is not finished, write the blocker and the next action.","Your line manager sets the day to Approved, Not Approved or Pending.","You are fully cleared only when your score is "+MKS_TARGET+"% or more and your manager approves.","Use the Weekly plan tab to plan the week, then add tasks to each day."].map(function(x,i){return mkh("li",{key:i},x)}))),
    mkh("div",{style:Object.assign({},card,{marginBottom:12})},
      mkh("h3",{style:{fontSize:15,fontWeight:900,color:T.head,fontFamily:"Outfit,sans-serif",margin:"0 0 8px"}},"Eisenhower priority and weights"),
      Object.keys(MKS_QUAD).map(function(z){var q=MKS_QUAD[z];return mkh("div",{key:z,style:{display:"flex",gap:10,alignItems:"flex-start",padding:"8px 0",borderTop:z==="Q1"?"none":"1px solid "+T.border}},
        mksBadge(z+" \u00b7 "+q.w,q.c,!0),mkh("div",{style:{fontSize:12.5,color:T.txt,lineHeight:1.5}},mkh("b",{},q.n),mkh("br",{}),mkh("span",{style:{color:T.muted}},q.use)))})),
    mkh("div",{style:Object.assign({},card,{marginBottom:12})},
      mkh("h3",{style:{fontSize:15,fontWeight:900,color:T.head,fontFamily:"Outfit,sans-serif",margin:"0 0 8px"}},"How the scores are worked out"),
      mkh("ul",{style:{margin:0,paddingLeft:20,fontSize:13,color:T.txt,lineHeight:1.85}},
        ["Daily score = the sum of (task weight x completion) divided by the sum of all planned task weights.","Weekly, monthly and yearly scores are the average of the daily scores on the days you planned.","On-target day: score "+MKS_TARGET+"% or more. Cleared day: on target and approved by your line manager.","Planning consistency: planned days compared with working days (Monday to Friday).","Ratings: 90%+ Outstanding, "+MKS_TARGET+"\u201389% On target, 65\u201379% Below target, under 65% Needs support."].map(function(x,i){return mkh("li",{key:i},x)}))),
    mkh("div",{style:Object.assign({},card,{background:T.alt,fontSize:12.5,color:T.muted,lineHeight:1.65})},"A score below "+MKS_TARGET+"% should trigger a review of priorities, blockers, workload and support needed. Manager approval is a separate control and is not used to punish staff for legitimate blockers."));

  var body=tab==="today"?todayView:tab==="week"?weekView:tab==="month"?monthView:tab==="year"?yearView:guideView;
  return shell(profileBar,banner,dateBar,tabBar,body)}
