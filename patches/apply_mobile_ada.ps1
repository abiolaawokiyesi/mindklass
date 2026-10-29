# Mobile shell + Ada tutor + first-visit fixes for MindKlass.
#
#   1. First visit / shared link fix: the visitor (guest) start-up used to force the
#      view to "home", throwing away the address the visitor came from, so a shared
#      course link or /Subjects opened the dashboard instead. It now honours the URL.
#   2. Mobile: the long scrolling bottom strip is replaced by a floating five-slot tab
#      bar (Home, Subjects, Ada, Courses, Menu) and a slide-in side drawer with grouped
#      links, theme switch, sign in/out, Ask Ada and Share.
#   3. "Ask Ada" view that embeds the Ada avatar service (see ..\ada) when
#      window.MK_ADA_URL is set (dist\ada-config.js), with honest states otherwise.
#   4. Student Subjects tiles on the dashboard and SS1/SS2/SS3 chips on the
#      Nigerian Curriculum catalogue.
#
# Usage (from the patches folder):  powershell -NoProfile -File .\apply_mobile_ada.ps1 -Target ..\dist\assets\app.js
# Safe to run twice: the module block is replaced, every other edit is skipped when present.
param([string]$Target = '..\dist\assets\app.js')
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$enc = [Text.Encoding]::GetEncoding(28591)
$path = (Resolve-Path (Join-Path $here $Target)).Path
$d = [IO.File]::ReadAllText($path, $enc)
$mod = [IO.File]::ReadAllText((Join-Path $here 'mobile_ada\mk_mobile_ada.js'), [Text.Encoding]::UTF8).TrimEnd()
if ($mod -match '[^\x00-\x7F]') { throw 'module has non-ascii characters' }

function Swap([string]$name, [string]$old, [string]$new) {
  if ($script:d.Contains($new)) { Write-Host "  skip (already applied): $name"; return }
  $n = ([regex]::Matches($script:d, [regex]::Escape($old))).Count
  if ($n -ne 1) { throw "anchor for '$name' found $n times" }
  $script:d = $script:d.Replace($old, $new)
  Write-Host "  applied: $name"
}

# --- module block (replace if present, else insert before the rejection-expiry helpers)
$b = $d.IndexOf('/*MK-MOBILE-BEGIN*/')
if ($b -ge 0) {
  $e2 = $d.IndexOf('/*MK-MOBILE-END*/') + '/*MK-MOBILE-END*/'.Length
  $d = $d.Substring(0, $b) + $mod + $d.Substring($e2)
  Write-Host '  replaced: module block'
} else {
  $anchor = 'var MK_REJECT_WINDOW_MS=30*60*1000;'
  if (([regex]::Matches($d, [regex]::Escape($anchor))).Count -ne 1) { throw 'module anchor missing' }
  $d = $d.Replace($anchor, $mod + "`n" + $anchor)
  Write-Host '  inserted: module block'
}

# --- routes: /Ada
Swap 'route table' '"staffperformance":"staffperf"};var MK_SLUGS=' '"staffperformance":"staffperf","ada":"ada","progress":"progress"};var MK_SLUGS='
Swap 'slug table' '"staffperf":"StaffPerformance"};var MK_VIEW_TO_SLUG' '"staffperf":"StaffPerformance","ada":"Ada","progress":"Progress"};var MK_VIEW_TO_SLUG'

# --- state
Swap 'state' '[mkQ,mkSetQ]=f(()=>mkSearchPrefill())' '[mkQ,mkSetQ]=f(()=>mkSearchPrefill()),[mkDrawer,mkSetDrawer]=f(!1),[mkLvl,mkSetLvl]=f("All")'

# --- 1. first visit keeps the address the visitor came from
Swap 'guest start view' 'try{oa()}catch{}B("dash"),ie("home")}' 'try{oa()}catch{}B("dash"),ie(mkInitialView("home"))}'

# --- nav list gets "Ask Ada"
Swap 'nav head' 'gd=({student:[{id:"home"' 'gd=mkWithAda(L,({student:[{id:"home"'
Swap 'nav tail' '[{id:"staffhub",I:Ge,l:"Staff Tracker"}]:[]),yd=i=>{' '[{id:"staffhub",I:Ge,l:"Staff Tracker"}]:[])),yd=i=>{'

# --- top bar hamburger
$ham = 'e("button",{onClick:()=>mkSetDrawer(!0),"aria-label":"Open menu",style:{background:"rgba(255,255,255,.1)",border:"none",borderRadius:8,width:32,height:32,display:"flex",alignItems:"center",justifyContent:"center",cursor:"pointer",flexShrink:0},children:e(MkMenuIcon,{size:18,color:"#fff"})}),'
Swap 'top bar' ',hu=()=>t("div",{style:{position:"sticky",top:0,zIndex:40,background:a.nav,padding:"10px 12px",display:"flex",alignItems:"center",gap:9},children:[e(Zo,{sm:!0}),' (',hu=()=>t("div",{style:{position:"sticky",top:0,zIndex:40,background:a.nav,padding:"10px 12px",display:"flex",alignItems:"center",gap:9},children:[' + $ham + 'e(Zo,{sm:!0}),')

# --- bottom bar: swap the old scrolling strip for the new tab bar
$u0 = $d.IndexOf(',uu=()=>e("div",{style:{position:"fixed",bottom:0,left:0,right:0,zIndex:40')
$u1 = $d.IndexOf(',mu=()=>X?hu():cu()')
if ($u0 -ge 0 -and $u1 -gt $u0) {
  $d = $d.Substring(0, $u0) + ',uu=()=>e(MkBottomNav,{items:gd,active:G,go:yd,a,role:L,onMenu:()=>mkSetDrawer(!0),badge:pa})' + $d.Substring($u1)
  Write-Host '  applied: bottom tab bar'
} elseif ($d.Contains(',uu=()=>e(MkBottomNav,')) { Write-Host '  skip (already applied): bottom tab bar' } else { throw 'bottom bar anchors missing' }

# --- drawer
Swap 'drawer' 'X&&uu(),pu(),ns&&' 'X&&uu(),X&&e(MkDrawer,{open:mkDrawer,close:()=>mkSetDrawer(!1),items:gd,active:G,go:yd,a,role:L,user:y,guest:dt,dark:h,toggleTheme:g,onLogin:()=>Pa("in"),onLogout:Dl,badge:pa,logo:e(Zo,{sm:!0})}),pu(),ns&&'

# --- Ada view
Swap 'ada view' 'if(G==="learn"||G==="general"||G==="jamb"){let i=L==="admin",o=G==="general"' 'if(G==="ada")return J({children:e(MkAda,{a,k,X,role:L,guest:dt})});if(G==="learn"||G==="general"||G==="jamb"){let i=L==="admin",o=G==="general"'

# --- dashboard: Student Subjects tiles above Continue Learning
$grid = 't("div",{style:{display:"grid",gridTemplateColumns:"repeat(auto-fit,minmax(270px,1fr))",gap:12},children:[t("div",{style:k,children:[t("h3",{style:{fontSize:13,fontWeight:800,color:a.head,margin:"0 0 10px",display:"flex",alignItems:"center",gap:5},children:[e(fe,{size:13,color:"#1842a8"}),"Continue Learning"'
$tiles = 'e(MkSubjectTiles,{a,k,go:mk_c=>{yd("learn"),sc(mk_c)},ada:()=>yd("ada")}),'
Swap 'subject tiles' $grid ($tiles + $grid)

# --- Nigerian Curriculum: SS1 / SS2 / SS3 chips + filter
Swap 'level chips' '}),(()=>{let p=(o||s||Ji==="All"?n:n.filter(([,d])=>(d.cat||d.subject)===Ji)).filter(([mk_k,mk_c])=>mkCourseMatch(mk_c,mk_k,mkQ));' '}),Ji==="Nigerian Curriculum"&&!o&&!s&&e(MkLevelChips,{a,v:mkLvl,set:mkSetLvl}),(()=>{let p=(o||s||Ji==="All"?n:n.filter(([,d])=>(d.cat||d.subject)===Ji)).filter(([mk_k,mk_c])=>mkCourseMatch(mk_c,mk_k,mkQ)).filter(([,mk_d])=>Ji!=="Nigerian Curriculum"||mkLvl==="All"||String(mk_d.group||"").indexOf(mkLvl)===0);'


# --- progress dashboard route, alerts for applications and approvals ---
Swap 'seen state' '[mkDrawer,mkSetDrawer]=f(!1),[mkLvl,mkSetLvl]=f("All")' '[mkDrawer,mkSetDrawer]=f(!1),[mkLvl,mkSetLvl]=f("All"),[mkSeen,mkSetSeen]=f(()=>mkSeenLoad())'
Swap 'alert list' 'Ti=()=>Jn.filter(i=>i.audience==="all"||i.audience===L),ja=' 'Ti=()=>mkSynthAlerts({role:L,user:y,student:Ct,teacher:Gt,seen:mkSeen}).concat(Jn.filter(i=>i.audience==="all"||i.audience===L)),ja='
Swap 'mark alerts read' 'ud=async()=>{let i=Jn.filter(o=>!o.read)' 'ud=async()=>{mkSetSeen(mk_s=>{let mk_n=new Set(mk_s);Ti().forEach(mk_a=>mk_n.add(mk_a.id));try{localStorage.setItem("mk_seen_alerts",JSON.stringify([...mk_n].slice(-400)))}catch{}return mk_n});let i=Jn.filter(o=>!o.read)'
Swap 'application polling' 'de(()=>{try{sessionStorage.setItem("mk_tab",G)}catch{}try{mkPushView(G)}catch{}},[G]),' 'de(()=>{try{sessionStorage.setItem("mk_tab",G)}catch{}try{mkPushView(G)}catch{}},[G]),de(()=>{if(!y?.id||dt)return;let mk_t=()=>{if(document.visibilityState==="visible"&&navigator.onLine!==!1)nt()};let mk_iv=setInterval(mk_t,45e3);window.addEventListener("focus",mk_t);return()=>{clearInterval(mk_iv);window.removeEventListener("focus",mk_t)}},[y?.id]),'
Swap 'progress view' 'if(G==="ada")return J({children:e(MkAda,{a,k,X,role:L,guest:dt})});' 'if(G==="progress")return J({children:e(MkProgress,{a,k,X,role:L,user:y,guest:dt,Ce,Fe,mine:ii,checks:In,apps:Ct,tapps:Gt,exams:Ir,sb:M,go:mk_c=>{yd("learn"),mkSetQ(mk_c)},browse:()=>yd("learn"),ada:()=>yd("ada"),login:()=>Pa("in")})});if(G==="ada")return J({children:e(MkAda,{a,k,X,role:L,guest:dt})});'
[IO.File]::WriteAllText($path, $d, $enc)
Write-Host "patched: $path"
