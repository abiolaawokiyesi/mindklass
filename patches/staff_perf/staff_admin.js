/* MindKlass staff performance module: the administrator's staff performance dashboard. */
var MKS_SQL=__MKS_SQL__;

function MkStaffAdmin(props){
  var T=props.T,isMobile=props.isMobile,card=props.card,bP=props.bP,bO=props.bO,admin=props.user;
  var inp=mksInput(T),lab=mksLabel(T);
  var a1=f("day"),view=a1[0],setView=a1[1];
  var a2=f(mksToday()),date=a2[0],setDate=a2[1];
  var a3=f([]),members=a3[0],setMembers=a3[1];
  var a4=f({}),names=a4[0],setNames=a4[1];
  var a5=f({}),sumsAll=a5[0],setSumsAll=a5[1];
  var a6=f({}),revsAll=a6[0],setRevsAll=a6[1];
  var a7=f(!0),loading=a7[0],setLoading=a7[1];
  var a8=f(null),problem=a8[0],setProblem=a8[1];
  var a9=f(0),tick=a9[0],setTick=a9[1];
  var a10=f(""),fPos=a10[0],setFPos=a10[1];
  var a11=f(""),q=a11[0],setQ=a11[1];
  var a12=f("score"),sortBy=a12[0],setSortBy=a12[1];
  var a13=f(null),sel=a13[0],setSel=a13[1];
  var a14=f([]),selTasks=a14[0],setSelTasks=a14[1];
  var a15=f({}),drafts=a15[0],setDrafts=a15[1];
  var a16=f(""),msg=a16[0],setMsg=a16[1];
  var a17=f(!1),showSql=a17[0],setShowSql=a17[1];
  var a18=f("day"),mTab=a18[0],setMTab=a18[1];
  var a19=f({pos:"",mgr:""}),edit=a19[0],setEdit=a19[1];
  var yr=date.slice(0,4);

  /* members + names */
  de(function(){
    var live=!0;setLoading(!0);
    mksApi.loadMembers().then(function(r){
      if(!live)return;
      if(r.error){setProblem(r.missing?"missing":(r.error.message||"error"));setMembers([]);setLoading(!1);return}
      setProblem(null);setMembers(r.data||[]);
      var ids=(r.data||[]).map(function(m){return m.user_id});
      if(!ids.length){setLoading(!1);return}
      M.from("profiles").select("id,name,nick,email").in("id",ids).then(function(p){
        if(!live)return;var m={};(p.data||[]).forEach(function(x){m[x.id]=x});setNames(m);setLoading(!1)})
    }).catch(function(x){if(live){setProblem(x&&x.message||"error");setLoading(!1)}});
    return function(){live=!1}},[tick]);

  /* summaries + reviews for the year */
  de(function(){
    var live=!0;
    mksApi.loadSummaryAll(yr+"-01-01",yr+"-12-31").then(function(r){if(live&&r.data)setSumsAll(r.data);if(live&&r.error&&r.missing)setProblem("missing")});
    mksApi.loadReviews(null,yr+"-01-01",yr+"-12-31").then(function(r){if(live&&r&&r.data)setRevsAll(r.data)});
    return function(){live=!1}},[yr,tick]);

  /* the selected staff member's tasks for the selected day */
  de(function(){
    if(!sel){setSelTasks([]);return}
    var live=!0;
    mksApi.tasksFor(sel,date).then(function(rows){if(live)setSelTasks(rows)});
    return function(){live=!1}},[sel,date,tick]);

  function nm(uid){var p=names[uid]||{};return p.name||p.nick||p.email||"Staff member"}
  var from,to;
  if(view==="day"){from=date;to=date}
  else if(view==="week"){from=mksMonday(date);to=mksAddDays(from,6)}
  else if(view==="month"){from=mksMonthStart(date);to=mksMonthEnd(date)}
  else{from=yr+"-01-01";to=yr+"-12-31"}
  var wk=mksMonday(date),wkEnd=mksAddDays(wk,6),mS=mksMonthStart(date),mE=mksMonthEnd(date);

  var approvedList=members.filter(function(m){return m.status==="approved"});
  var requests=members.filter(function(m){return m.status!=="approved"});
  var rows=approvedList.map(function(m){
    var s=sumsAll[m.user_id]||{},r=revsAll[m.user_id]||{};
    var ag=mksAgg(s,r,from,to),d=s[date]||null,rv=r[date]||{approval:"Pending",comment:""};
    return{m:m,uid:m.user_id,name:nm(m.user_id),pos:m.position||"",s:s,r:r,ag:ag,day:d,rv:rv,
      wk:mksAgg(s,r,wk,wkEnd),mo:mksAgg(s,r,mS,mE),yr:mksAgg(s,r,yr+"-01-01",yr+"-12-31"),
      score:view==="day"?(d?d.score:null):ag.avg}});
  var positions=[];rows.forEach(function(x){if(x.pos&&positions.indexOf(x.pos)<0)positions.push(x.pos)});
  var shown=rows.filter(function(x){return(!fPos||x.pos===fPos)&&(!q.trim()||(x.name+" "+x.pos).toLowerCase().indexOf(q.trim().toLowerCase())>-1)});
  shown.sort(function(a,b){
    if(sortBy==="name")return a.name.localeCompare(b.name);
    var av=a.score==null?-1:a.score,bv=b.score==null?-1:b.score;
    return sortBy==="low"?av-bv:bv-av});

  /* headline numbers for the chosen period */
  var sc=[],cleared=0,review=0,noPlan=0;
  shown.forEach(function(x){
    if(view==="day"){
      if(x.day&&x.day.planned>0){sc.push(x.day.score);var c=mksClear(x.day.score,x.rv.approval,x.day.planned);if(c.text==="CLEARED")cleared++;else review++}
      else noPlan++}
    else{
      if(x.ag.avg!=null){sc.push(x.ag.avg);cleared+=x.ag.cleared;if(x.ag.avg<MKS_TARGET)review++}else noPlan++}});
  var teamAvg=sc.length?Math.round(sc.reduce(function(p,c){return p+c},0)/sc.length*10)/10:null;

  function setReview(uid,d,approval,comment){
    var next=Object.assign({},revsAll);next[uid]=Object.assign({},next[uid]||{});next[uid][d]={approval:approval,comment:comment||""};setRevsAll(next);
    mksApi.saveReview(uid,d,approval,comment,admin&&admin.id).then(function(r){
      if(r.error)setMsg("Could not save the review: "+(r.error.message||"error"));else setMsg("Review saved")})}
  function setStatus(uid,status){
    var patch={status:status};if(status==="approved"){patch.approved_at=new Date().toISOString();patch.approved_by=admin&&admin.id}
    mksApi.updateMember(uid,patch).then(function(r){if(r.error)setMsg("Could not update: "+(r.error.message||"error"));else{setMsg("Updated");setTick(function(n){return n+1})}})}
  function saveProfile(uid){
    mksApi.updateMember(uid,{position:edit.pos,line_manager:edit.mgr}).then(function(r){if(r.error)setMsg("Could not save: "+(r.error.message||"error"));else{setMsg("Saved");setTick(function(n){return n+1})}})}
  function openStaff(x){setSel(x.uid);setMTab("day");setEdit({pos:x.pos,mgr:x.m.line_manager||""})}

  function exportCsv(){
    var head=view==="day"?["Staff","Position","Date","Daily score","Tasks completed","Tasks planned","Evidence","Blocked","Manager approval","Clearance","Manager comment","Week avg","Month avg","Year avg"]
      :["Staff","Position","Period","Average score","Days planned","Working days","On-target days","Cleared days","Tasks completed","Tasks planned","Evidence rate %","Blocked tasks","Rating"];
    var out=[head];
    shown.forEach(function(x){
      if(view==="day"){var d=x.day||{planned:0,completed:0,ev:0,bl:0,score:0},cl=mksClear(d.score,x.rv.approval,d.planned);
        out.push([x.name,x.pos,date,d.planned?d.score:"",d.completed,d.planned,d.ev,d.bl,x.rv.approval,cl.text,x.rv.comment,x.wk.avg==null?"":x.wk.avg,x.mo.avg==null?"":x.mo.avg,x.yr.avg==null?"":x.yr.avg])}
      else out.push([x.name,x.pos,from+" to "+to,x.ag.avg==null?"":x.ag.avg,x.ag.days,x.ag.workdays,x.ag.on,x.ag.cleared,x.ag.completed,x.ag.planned,x.ag.evRate,x.ag.bl,x.ag.avg==null?"No plan":mksBand(x.ag.avg,1).label])});
    mksCsv(out,"mindklass-staff-"+view+"-"+(view==="day"?date:view==="year"?yr:from)+".csv")}

  /* ---------- pieces ---------- */
  var heading=mkh("div",{style:{background:"linear-gradient(135deg,#0d1f4b,#1842a8)",borderRadius:18,padding:isMobile?16:22,marginBottom:14,color:"#fff"}},
    mkh("div",{style:{fontSize:10,letterSpacing:2,textTransform:"uppercase",opacity:.7,marginBottom:5}},"Administrator"),
    mkh("h1",{style:{fontSize:isMobile?22:28,fontWeight:900,fontFamily:"Outfit,sans-serif",margin:"0 0 6px"}},"Staff Performance"),
    mkh("p",{style:{fontSize:13,opacity:.9,margin:0,lineHeight:1.6,maxWidth:700}},"Daily scores, manager clearance and weekly, monthly and yearly performance for every approved team member."));

  var setupCard=problem==="missing"?mkh("div",{style:Object.assign({},card,{borderLeft:"5px solid #d97706",marginBottom:14})},
    mkh("h3",{style:{fontSize:15,fontWeight:900,color:T.head,fontFamily:"Outfit,sans-serif",margin:"0 0 6px"}},"One-time database setup needed"),
    mkh("p",{style:{fontSize:13,color:T.txt,margin:"0 0 8px",lineHeight:1.65}},"The staff tables are not in Supabase yet. Open your Supabase project, choose SQL Editor, paste the script and press Run. Then reload this page. The same script is in the project as ",mkh("code",{},MKS_SQL_FILE),"."),
    mkh("div",{style:{display:"flex",gap:8,flexWrap:"wrap",marginBottom:8}},
      mkh("button",{onClick:function(){try{navigator.clipboard.writeText(MKS_SQL);setMsg("SQL copied")}catch(x){setShowSql(!0)}},style:Object.assign({},bP,{padding:"9px 16px"})},"Copy the SQL"),
      mkh("button",{onClick:function(){setShowSql(!showSql)},style:Object.assign({},bO,{padding:"9px 16px"})},showSql?"Hide SQL":"Show SQL"),
      mkh("button",{onClick:function(){mksApi.reset();setProblem(null);setTick(function(n){return n+1})},style:Object.assign({},bO,{padding:"9px 16px"})},"I have run it, check again")),
    showSql?mkh("pre",{style:{background:T.alt,border:"1px solid "+T.border,borderRadius:10,padding:12,fontSize:11,color:T.txt,maxHeight:320,overflow:"auto",whiteSpace:"pre-wrap",margin:0}},MKS_SQL):null):null;
  var errCard=problem&&problem!=="missing"?mkh("div",{style:Object.assign({},card,{borderLeft:"5px solid #dc2626",marginBottom:14,fontSize:13,color:T.txt})},"Could not load staff data: "+problem):null;

  var requestsCard=requests.length?mkh("div",{style:Object.assign({},card,{marginBottom:14})},
    mkh("h3",{style:{fontSize:15,fontWeight:900,color:T.head,fontFamily:"Outfit,sans-serif",margin:"0 0 8px"}},"Staff registrations ("+requests.length+")"),
    requests.map(function(m,i){
      var col=m.status==="pending"?"#d97706":m.status==="rejected"?"#dc2626":"#64748b";
      return mkh("div",{key:m.user_id,style:{display:"flex",gap:10,alignItems:"center",flexWrap:"wrap",padding:"10px 0",borderTop:i?"1px solid "+T.border:"none"}},
        mkh("div",{style:{flex:"1 1 220px",minWidth:0}},
          mkh("div",{style:{fontSize:13.5,fontWeight:800,color:T.head}},nm(m.user_id)),
          mkh("div",{style:{fontSize:12,color:T.muted,overflowWrap:"anywhere"}},(names[m.user_id]&&names[m.user_id].email||"")+" \u00b7 "+(m.position||"-")+(m.line_manager?" \u00b7 reports to "+m.line_manager:""))),
        mksBadge(m.status,col),
        m.status!=="approved"?mkh("button",{onClick:function(){setStatus(m.user_id,"approved")},style:Object.assign({},bP,{padding:"7px 14px",fontSize:12})},"Approve"):null,
        m.status==="pending"?mkh("button",{onClick:function(){setStatus(m.user_id,"rejected")},style:Object.assign({},bO,{padding:"7px 14px",fontSize:12,color:"#dc2626",borderColor:"#dc2626"})},"Decline"):null)})):null;

  var viewBtns=mkh("div",{style:{display:"flex",gap:6,flexWrap:"wrap"}},[["day","Daily"],["week","Weekly"],["month","Monthly"],["year","Yearly"]].map(function(x){
    var on=view===x[0];return mkh("button",{key:x[0],onClick:function(){setView(x[0])},style:{padding:"8px 15px",borderRadius:99,border:on?"none":"1.5px solid "+T.border,background:on?"#1842a8":T.card,color:on?"#fff":T.txt,fontWeight:800,fontSize:12.5,cursor:"pointer",fontFamily:"inherit"}},x[1])}));
  function stepDate(n){if(view==="day")setDate(mksAddDays(date,n));else if(view==="week")setDate(mksAddDays(date,7*n));else if(view==="month")setDate(mksAddMonths(date,n));else setDate(mksAddMonths(date,12*n))}
  var periodLabel=view==="day"?mksNice(date):view==="week"?"Week of "+mksShort(from)+" \u2013 "+mksShort(to):view==="month"?MKS_MONTHS[+date.slice(5,7)-1]+" "+yr:"Year "+yr;
  var controls=mkh("div",{style:Object.assign({},card,{marginBottom:12,padding:isMobile?12:14})},
    mkh("div",{style:{display:"flex",gap:10,flexWrap:"wrap",alignItems:"center",marginBottom:10}},viewBtns,
      mkh("div",{style:{display:"flex",gap:6,alignItems:"center",flexWrap:"wrap"}},
        mkh("button",{onClick:function(){stepDate(-1)},style:Object.assign({},bO,{padding:"7px 12px"}),"aria-label":"Previous"},"\u2039"),
        mkh("input",{type:"date",value:date,onChange:function(ev){if(ev.target.value)setDate(ev.target.value)},style:Object.assign({},inp,{width:"auto"})}),
        mkh("button",{onClick:function(){stepDate(1)},style:Object.assign({},bO,{padding:"7px 12px"}),"aria-label":"Next"},"\u203a"),
        mkh("button",{onClick:function(){setDate(mksToday())},style:Object.assign({},bO,{padding:"7px 12px",fontSize:12})},"Today"))),
    mkh("div",{style:{display:"flex",gap:8,flexWrap:"wrap",alignItems:"center"}},
      mkh("div",{style:{fontSize:13.5,fontWeight:900,color:T.head,fontFamily:"Outfit,sans-serif",flex:"1 1 180px"}},periodLabel),
      mkh("input",{style:Object.assign({},inp,{width:isMobile?"100%":200}),placeholder:"Search name or position",value:q,onChange:function(ev){setQ(ev.target.value)}}),
      mkh("select",{style:Object.assign({},inp,{width:isMobile?"100%":210}),value:fPos,onChange:function(ev){setFPos(ev.target.value)}},mkh("option",{value:""},"All positions"),positions.map(function(p){return mkh("option",{key:p,value:p},p)})),
      mkh("select",{style:Object.assign({},inp,{width:isMobile?"100%":150}),value:sortBy,onChange:function(ev){setSortBy(ev.target.value)}},mkh("option",{value:"score"},"Highest score"),mkh("option",{value:"low"},"Lowest score"),mkh("option",{value:"name"},"Name A-Z")),
      mkh("button",{onClick:exportCsv,style:Object.assign({},bO,{padding:"8px 14px",fontSize:12})},"Export CSV")),
    msg?mkh("div",{style:{fontSize:11.5,color:T.muted,marginTop:8,fontWeight:700}},msg):null);

  var tiles=mkh("div",{style:{display:"grid",gridTemplateColumns:isMobile?"1fr 1fr":"repeat(5,1fr)",gap:10,marginBottom:12}},
    mksTile(T,"Approved staff",approvedList.length,null,requests.filter(function(m){return m.status==="pending"}).length+" waiting for approval"),
    mksTile(T,"Team average",teamAvg==null?"-":Math.round(teamAvg)+"%",teamAvg==null?null:mksBand(teamAvg,1).color,view==="day"?"submitted plans only":"average of staff averages"),
    mksTile(T,view==="day"?"Cleared today":"Cleared days",cleared,"#059669",view==="day"?"score "+MKS_TARGET+"%+ and approved":"approved on-target days"),
    mksTile(T,"Needs review",review,review?"#d97706":null,view==="day"?"below target or awaiting approval":"average below "+MKS_TARGET+"%"),
    mksTile(T,"No plan",noPlan,noPlan?"#dc2626":null,view==="day"?"nothing planned this day":"nothing planned in this period"));

  /* ---------- the staff table / cards ---------- */
  function scoreChip(v,planned){var b=mksBand(v||0,planned);return mkh("span",{style:{display:"inline-block",minWidth:52,textAlign:"center",fontWeight:900,fontSize:13,color:"#fff",background:b.color,borderRadius:8,padding:"4px 8px"}},planned===0||v==null?"-":Math.round(v)+"%")}
  function approvalSel(x){return mkh("select",{style:Object.assign({},inp,{padding:"6px 8px",fontSize:12,minWidth:120}),value:x.rv.approval,onChange:function(ev){setReview(x.uid,date,ev.target.value,(drafts[x.uid]!==void 0?drafts[x.uid]:x.rv.comment))},disabled:!x.day,"aria-label":"Manager approval"},MKS_APPROVALS.map(function(z){return mkh("option",{key:z,value:z},z)}))}
  function commentIn(x){var val=drafts[x.uid]!==void 0?drafts[x.uid]:x.rv.comment;return mkh("input",{style:Object.assign({},inp,{padding:"6px 8px",fontSize:12,minWidth:150}),placeholder:"Comment",value:val,disabled:!x.day,onChange:function(ev){var d=Object.assign({},drafts);d[x.uid]=ev.target.value;setDrafts(d)},onBlur:function(){if(drafts[x.uid]!==void 0&&drafts[x.uid]!==x.rv.comment)setReview(x.uid,date,x.rv.approval,drafts[x.uid])}})}

  var tableView;
  if(isMobile){
    tableView=mkh("div",{},shown.map(function(x){
      var d=x.day,cl=d?mksClear(d.score,x.rv.approval,d.planned):{text:"NO PLAN",color:"#94a3b8"};
      return mkh("div",{key:x.uid,style:Object.assign({},card,{marginBottom:10,padding:12})},
        mkh("div",{style:{display:"flex",justifyContent:"space-between",gap:8,alignItems:"flex-start",marginBottom:8}},
          mkh("div",{style:{minWidth:0}},mkh("div",{style:{fontSize:14,fontWeight:900,color:T.head}},x.name),mkh("div",{style:{fontSize:11.5,color:T.muted}},x.pos||"-")),
          view==="day"?scoreChip(d?d.score:null,d?d.planned:0):scoreChip(x.ag.avg,x.ag.days?1:0)),
        view==="day"?mkh("div",{},
          mkh("div",{style:{fontSize:12,color:T.txt,marginBottom:6}},(d?d.completed+"/"+d.planned+" tasks \u00b7 "+d.ev+" evidence \u00b7 "+d.bl+" blocked":"No plan for this day")),
          mkh("div",{style:{display:"flex",gap:6,alignItems:"center",flexWrap:"wrap",marginBottom:6}},mksBadge(cl.text,cl.color),approvalSel(x)),commentIn(x))
        :mkh("div",{style:{fontSize:12,color:T.txt}},x.ag.days+"/"+x.ag.workdays+" days \u00b7 "+x.ag.on+" on target \u00b7 "+x.ag.cleared+" cleared \u00b7 "+x.ag.completed+"/"+x.ag.planned+" tasks"),
        mkh("button",{onClick:function(){openStaff(x)},style:Object.assign({},bO,{padding:"7px 14px",fontSize:12,marginTop:8})},"View details"))}))}
  else{
    var th=function(h){return mkh("th",{key:h,style:{padding:"10px 12px",fontSize:10.5,textTransform:"uppercase",letterSpacing:.4,textAlign:"left",whiteSpace:"nowrap"}},h)};
    var heads=view==="day"?["Staff","Position","Score","Done / planned","Evidence","Blocked","Approval","Clearance","Comment","Week","Month","Year",""]:["Staff","Position","Avg score","Days planned","On target","Cleared","Tasks done","Evidence","Blocked","Rating",""];
    tableView=mkh("div",{style:{background:T.card,border:"1px solid "+T.border,borderRadius:14,boxShadow:T.shadow,overflow:"hidden"}},mkh("div",{style:{overflowX:"auto"}},
      mkh("table",{style:{width:"100%",borderCollapse:"collapse",fontSize:12.5,minWidth:view==="day"?1180:920}},
        mkh("thead",{},mkh("tr",{style:{background:T.alt,color:T.muted}},heads.map(th))),
        mkh("tbody",{},shown.map(function(x){
          var d=x.day,td=function(c,extra){return mkh("td",{style:Object.assign({padding:"9px 12px",color:T.txt,verticalAlign:"middle"},extra||{})},c)};
          var go=td(mkh("button",{onClick:function(){openStaff(x)},style:Object.assign({},bO,{padding:"5px 12px",fontSize:12})},"View"));
          if(view==="day"){var cl=d?mksClear(d.score,x.rv.approval,d.planned):{text:"NO PLAN",color:"#94a3b8"};
            return mkh("tr",{key:x.uid,style:{borderTop:"1px solid "+T.border}},
              td(mkh("b",{style:{color:T.head}},x.name)),td(x.pos||"-"),td(scoreChip(d?d.score:null,d?d.planned:0)),td(d?d.completed+" / "+d.planned:"-"),td(d?d.ev:"-"),td(d?(d.bl?mkh("b",{style:{color:"#dc2626"}},d.bl):0):"-"),
              td(approvalSel(x)),td(mksBadge(cl.text,cl.color)),td(commentIn(x)),
              td(x.wk.avg==null?"-":Math.round(x.wk.avg)+"%"),td(x.mo.avg==null?"-":Math.round(x.mo.avg)+"%"),td(x.yr.avg==null?"-":Math.round(x.yr.avg)+"%"),go)}
          var b=x.ag.avg==null?{label:"No plan",color:"#94a3b8"}:mksBand(x.ag.avg,1);
          return mkh("tr",{key:x.uid,style:{borderTop:"1px solid "+T.border}},
            td(mkh("b",{style:{color:T.head}},x.name)),td(x.pos||"-"),td(scoreChip(x.ag.avg,x.ag.days?1:0)),td(x.ag.days+" / "+x.ag.workdays),td(x.ag.on),td(x.ag.cleared),td(x.ag.completed+" / "+x.ag.planned),td(x.ag.evRate+"%"),td(x.ag.bl),td(mksBadge(b.label,b.color)),go)})))));
    if(!shown.length)tableView=null}

  var empty=!loading&&!problem&&!shown.length?mkh("div",{style:Object.assign({},card,{textAlign:"center",color:T.muted,fontSize:13})},approvedList.length?"No staff match your filters.":"No approved staff yet. Approved registrations will appear here."):null;

  /* ---------- one staff member (modal) ---------- */
  var modal=null;
  if(sel){
    var x=rows.filter(function(r){return r.uid===sel})[0]||(function(){var m=members.filter(function(z){return z.user_id===sel})[0]||{};return{uid:sel,name:nm(sel),pos:m.position||"",m:m,s:{},r:{},rv:{approval:"Pending",comment:""},wk:mksAgg({},{},wk,wkEnd),mo:mksAgg({},{},mS,mE),yr:mksAgg({},{},yr+"-01-01",yr+"-12-31")}})();
    var dd=mksDay(selTasks),cl2=mksClear(dd.score,x.rv.approval,dd.planned);
    var wBars=[0,1,2,3,4,5,6].map(function(n){var d=mksAddDays(wk,n),s=x.s[d];return{label:["Mon","Tue","Wed","Thu","Fri","Sat","Sun"][n],value:s&&s.planned>0?s.score:null}});
    var mBars=[0,1,2,3,4,5,6,7,8,9,10,11].map(function(n){var s0=yr+"-"+mksPad(n+1)+"-01",ag=mksAgg(x.s,x.r,s0,mksMonthEnd(s0));return{label:MKS_MONTHS[n].slice(0,3),value:ag.avg}});
    var mt=function(k,l){var on=mTab===k;return mkh("button",{key:k,onClick:function(){setMTab(k)},style:{padding:"8px 14px",borderRadius:99,border:on?"none":"1.5px solid "+T.border,background:on?"#1842a8":T.card,color:on?"#fff":T.txt,fontWeight:800,fontSize:12.5,cursor:"pointer",fontFamily:"inherit"}},l)};
    var dayBody=mkh("div",{},
      mkh("div",{style:{display:"grid",gridTemplateColumns:isMobile?"1fr 1fr":"repeat(4,1fr)",gap:10,marginBottom:12}},
        mksTile(T,"Score",dd.planned?Math.round(dd.score)+"%":"-",mksBand(dd.score,dd.planned).color,mksNice(date)),
        mksTile(T,"Tasks done",dd.completed+" / "+dd.planned),mksTile(T,"Evidence",dd.ev+" / "+dd.planned),mksTile(T,"Clearance",cl2.text,cl2.color)),
      mkh("div",{style:{display:"flex",gap:8,flexWrap:"wrap",alignItems:"flex-end",marginBottom:12}},
        mkh("div",{style:{flex:"0 0 150px"}},mkh("label",{style:lab},"Manager approval"),approvalSel(Object.assign({},x,{day:dd.planned?dd:null}))),
        mkh("div",{style:{flex:"1 1 240px"}},mkh("label",{style:lab},"Manager comment"),commentIn(Object.assign({},x,{day:dd.planned?dd:null})))),
      selTasks.filter(function(k){return String(k.title||"").trim()}).length===0?mkh("div",{style:{color:T.muted,fontSize:13,padding:"10px 0"}},"No tasks were planned on this day."):
      selTasks.filter(function(k){return String(k.title||"").trim()}).map(function(k,i){
        var qd=MKS_QUAD[k.quadrant]||MKS_QUAD.Q2,url=/^https?:\/\//i.test(String(k.evidence||"").trim());
        return mkh("div",{key:k.id,style:{border:"1px solid "+T.border,borderLeft:"5px solid "+qd.c,borderRadius:12,padding:11,marginBottom:8,background:T.alt}},
          mkh("div",{style:{display:"flex",justifyContent:"space-between",gap:8,flexWrap:"wrap",marginBottom:4}},
            mkh("b",{style:{color:T.head,fontSize:13.5}},(i+1)+". "+k.title),
            mkh("span",{style:{display:"flex",gap:6,alignItems:"center"}},mksBadge(k.quadrant+" \u00b7 "+qd.w,qd.c,!0),mksBadge(k.status,k.status==="Completed"?"#059669":k.status==="Blocked"?"#dc2626":"#64748b"),mkh("b",{style:{color:T.txt}},(+k.completion||0)+"%"))),
          k.expected?mkh("div",{style:{fontSize:12,color:T.muted}},"Expected: "+k.expected):null,
          k.evidence?mkh("div",{style:{fontSize:12,marginTop:3}},"Evidence: ",url?mkh("a",{href:String(k.evidence).trim(),target:"_blank",rel:"noopener noreferrer",style:{color:"#1842a8",fontWeight:700,overflowWrap:"anywhere"}},k.evidence):mkh("span",{style:{color:T.txt}},k.evidence)):mkh("div",{style:{fontSize:12,color:"#d97706",marginTop:3}},"No evidence attached"),
          k.blocker?mkh("div",{style:{fontSize:12,color:"#dc2626",marginTop:3}},"Blocker: "+k.blocker+(k.next_action?" \u2192 next: "+k.next_action:"")):null,
          k.notes?mkh("div",{style:{fontSize:12,color:T.muted,marginTop:3}},"Notes: "+k.notes):null)}));
    var trendBody=mkh("div",{},
      mkh("div",{style:{display:"grid",gridTemplateColumns:isMobile?"1fr 1fr":"repeat(4,1fr)",gap:10,marginBottom:12}},
        mksTile(T,"This week",x.wk.avg==null?"-":Math.round(x.wk.avg)+"%",x.wk.avg==null?null:mksBand(x.wk.avg,1).color,x.wk.days+" day(s) planned"),
        mksTile(T,"This month",x.mo.avg==null?"-":Math.round(x.mo.avg)+"%",x.mo.avg==null?null:mksBand(x.mo.avg,1).color,x.mo.cleared+" cleared day(s)"),
        mksTile(T,"This year",x.yr.avg==null?"-":Math.round(x.yr.avg)+"%",x.yr.avg==null?null:mksBand(x.yr.avg,1).color,x.yr.days+" day(s) planned"),
        mksTile(T,"Planning consistency",x.yr.consistency+"%","","of working days")),
      mkh("div",{style:{marginBottom:12}},mkh("div",{style:{fontSize:12,fontWeight:800,color:T.muted,marginBottom:4}},"Week of "+mksShort(wk)),mksBars(T,wBars,120)),
      mkh("div",{style:{marginBottom:12}},mkh("div",{style:{fontSize:12,fontWeight:800,color:T.muted,marginBottom:4}},MKS_MONTHS[+date.slice(5,7)-1]+" "+yr),mksHeat(T,date,x.s,function(d){setDate(d);setMTab("day")},date)),
      mkh("div",{},mkh("div",{style:{fontSize:12,fontWeight:800,color:T.muted,marginBottom:4}},"Year "+yr+" by month"),mksBars(T,mBars,130)));
    var profBody=mkh("div",{},
      mkh("div",{style:{display:"grid",gridTemplateColumns:isMobile?"1fr":"1fr 1fr",gap:10,marginBottom:10}},
        mkh("div",{},mkh("label",{style:lab},"Position"),mkh("select",{style:inp,value:MKS_POSITIONS.indexOf(edit.pos)>-1?edit.pos:"__x",onChange:function(ev){setEdit({pos:ev.target.value==="__x"?edit.pos:ev.target.value,mgr:edit.mgr})}},mkh("option",{value:"__x"},edit.pos&&MKS_POSITIONS.indexOf(edit.pos)<0?edit.pos:"- choose -"),MKS_POSITIONS.map(function(p){return mkh("option",{key:p,value:p},p)}))),
        mkh("div",{},mkh("label",{style:lab},"Line manager"),mkh("input",{style:inp,value:edit.mgr,onChange:function(ev){setEdit({pos:edit.pos,mgr:ev.target.value})}}))),
      mkh("div",{style:{display:"flex",gap:8,flexWrap:"wrap"}},
        mkh("button",{onClick:function(){saveProfile(x.uid)},style:Object.assign({},bP,{padding:"8px 16px",fontSize:12.5})},"Save details"),
        mkh("button",{onClick:function(){if(window.confirm("Pause this person's staff access?"))setStatus(x.uid,"inactive")},style:Object.assign({},bO,{padding:"8px 16px",fontSize:12.5,color:"#dc2626",borderColor:"#dc2626"})},"Pause access")));
    modal=mkh("div",{onClick:function(){setSel(null)},style:{position:"fixed",inset:0,background:"rgba(10,15,35,.6)",zIndex:9000,display:"flex",alignItems:"flex-start",justifyContent:"center",padding:isMobile?8:20,overflowY:"auto"}},
      mkh("div",{onClick:function(ev){ev.stopPropagation()},style:Object.assign({},card,{width:"100%",maxWidth:880,margin:"auto",padding:isMobile?14:20})},
        mkh("div",{style:{display:"flex",justifyContent:"space-between",gap:10,alignItems:"flex-start",marginBottom:12}},
          mkh("div",{style:{minWidth:0}},mkh("div",{style:{fontSize:18,fontWeight:900,color:T.head,fontFamily:"Outfit,sans-serif"}},x.name),mkh("div",{style:{fontSize:12.5,color:T.muted}},(x.pos||"-")+(x.m&&x.m.line_manager?" \u00b7 reports to "+x.m.line_manager:""))),
          mkh("button",{onClick:function(){setSel(null)},style:Object.assign({},bO,{padding:"6px 12px"}),"aria-label":"Close"},"Close")),
        mkh("div",{style:{display:"flex",gap:6,flexWrap:"wrap",marginBottom:12}},mt("day","Day: "+mksShort(date)),mt("trend","Trends"),mt("profile","Details")),
        mTab==="day"?dayBody:mTab==="trend"?trendBody:profBody))}

  return mkh("div",{style:{maxWidth:1280,margin:"0 auto",width:"100%"}},
    heading,setupCard,errCard,requestsCard,controls,tiles,
    loading?mkh("div",{style:Object.assign({},card,{textAlign:"center",color:T.muted})},"Loading staff\u2026"):null,
    tableView,empty,modal)}
