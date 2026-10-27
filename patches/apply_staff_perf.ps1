# Staff performance module: staff registration, staff tracker page, admin Staff Performance dashboard, larger flyer.
#   powershell -ExecutionPolicy Bypass -File apply_staff_perf.ps1 -Target ..\dist\assets\app.js
# Safe to run again: the injected code sits between /*MKS-BEGIN*/ and /*MKS-END*/ and is replaced; text patches skip if already applied.
param([Parameter(Mandatory = $true)][string]$Target, [string]$DumpJson = "")
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $here 'staff_perf'
$enc = [Text.Encoding]::GetEncoding(28591)
$d = $enc.GetString([IO.File]::ReadAllBytes($Target))
$plist = @()

function ReadSrc($f) { [IO.File]::ReadAllText((Join-Path $src $f), [Text.Encoding]::UTF8) }
function AddP([string]$name, [string]$old, [string]$new, [string]$marker) { $script:plist += ,@($name, $old, $new, $marker) }
function Patch([string]$name, [string]$old, [string]$new, [string]$marker, [int]$count = 1) {
  if ($script:d.Contains($marker)) { "  skip (already applied): $name"; return }
  $n = ([regex]::Matches($script:d, [regex]::Escape($old))).Count
  if ($n -ne $count) { throw "$name : expected $count match(es), found $n" }
  $script:d = $script:d.Replace($old, $new)
  "  applied: $name"
}

# ---- 1. the module code ----
$sqlText = [IO.File]::ReadAllText((Join-Path (Split-Path -Parent $here) 'supabase\staff_performance.sql'), [Text.Encoding]::UTF8)
if ($sqlText -match '[^\x00-\x7F]') { throw 'staff_performance.sql must be plain ASCII' }
$sqlJs = ($sqlText | ConvertTo-Json -Compress)
$admin = (ReadSrc 'staff_admin.js').Replace('__MKS_SQL__', $sqlJs)
$code = '/*MKS-BEGIN*/' + (ReadSrc 'staff_core.js') + "`n" + (ReadSrc 'staff_hub.js') + "`n" + $admin + "`n" + '/*MKS-END*/'
if ($code -match '[^\x00-\x7F]') { throw 'module code must be plain ASCII (use \u escapes)' }
$anchor = 'import{Fragment as D,jsx as e,jsxs as t}from"react/jsx-runtime";'
if (-not $d.Contains($anchor)) { throw 'jsx anchor missing' }
$b = $d.IndexOf('/*MKS-BEGIN*/')
if ($b -ge 0) {
  $en = $d.IndexOf('/*MKS-END*/', $b) + '/*MKS-END*/'.Length
  $d = $d.Substring(0, $b) + $code + $d.Substring($en)
  "  replaced module code"
} else {
  $d = $d.Replace($anchor, $anchor + $code)
  "  added module code"
}

# ---- 2. registration ----
AddP 'user object carries the staff request' 'function Di(h,b){let a=b?.details||{};return{id:h.id,' 'function Di(h,b){let a=b?.details||{};return{id:h.id,staffReq:h.user_metadata&&h.user_metadata.staff_position?{position:h.user_metadata.staff_position,manager:h.user_metadata.staff_manager||""}:null,' 'staffReq:h.user_metadata'
AddP 'role option' 'e("option",{value:"professional",children:"Other Professional"})' 'e("option",{value:"professional",children:"Other Professional"}),e("option",{value:"staff",children:"MindKlass Staff / Associate"})' 'MindKlass Staff / Associate'
AddP 'role grid columns' 'gridTemplateColumns:U.role==="student"||U.role==="professional"?Oe<480?"1fr":"1fr 1fr":"1fr"' 'gridTemplateColumns:U.role==="student"||U.role==="professional"||U.role==="staff"?Oe<480?"1fr":"1fr 1fr":"1fr"' 'U.role==="professional"||U.role==="staff"?Oe<480'
$staffFields = 'U.role==="staff"&&t("div",{style:{marginBottom:9},children:[e("label",{style:s,children:"Your position"}),t("select",{style:o,value:U.staffPos||"",onChange:r=>Be(l=>({...l,staffPos:r.target.value})),children:[e("option",{value:"",children:"- Select your position -"}),MKS_POSITIONS.map(r=>e("option",{value:r,children:r},r))]})]}),U.role==="staff"&&U.staffPos==="Other (type your position)"&&t("div",{style:{marginBottom:9,gridColumn:"1 / -1"},children:[e("label",{style:s,children:"Type your position"}),e("input",{style:o,placeholder:"e.g. Research Associate",value:U.staffOther||"",onChange:r=>Be(l=>({...l,staffOther:r.target.value}))})]}),U.role==="staff"&&t("div",{style:{marginBottom:9,gridColumn:"1 / -1"},children:[e("label",{style:s,children:"Line manager (optional)"}),e("input",{style:o,placeholder:"Who do you report to?",value:U.staffMgr||"",onChange:r=>Be(l=>({...l,staffMgr:r.target.value}))})]}),U.role==="staff"&&e("p",{style:{fontSize:11,color:a.muted,margin:"0 0 9px",gridColumn:"1 / -1",lineHeight:1.5},children:"Staff accounts are checked and approved by the administrator before the staff tracker opens."}),'
$placeOld = '(U.role==="teacher"||U.role==="professional")&&t("div",{style:{marginBottom:9},children:[e("label",{style:s,children:"Place of Work"})'
AddP 'staff fields' $placeOld ($staffFields + $placeOld) 'children:"Your position"'
AddP 'position check' 'if(U.role==="professional"&&!U.profession){ve("Please choose your profession.");return}' 'if(U.role==="professional"&&!U.profession){ve("Please choose your profession.");return}if(U.role==="staff"&&!(U.staffPos==="Other (type your position)"?(U.staffOther||"").trim():(U.staffPos||""))){ve("Please choose or type your position at MindKlass.");return}' 'Please choose or type your position'
AddP 'sign-up metadata' 'role:U.role,ref_used:s,country:U.country,currency:r,phone:U.phone.trim(),profession:U.role==="professional"?U.profession:"",school:U.role==="student"?(U.school||"").trim():"",workplace:U.role==="teacher"||U.role==="professional"?(U.workplace||"").trim():""}' 'role:U.role==="staff"?"professional":U.role,ref_used:s,country:U.country,currency:r,phone:U.phone.trim(),profession:U.role==="professional"?U.profession:U.role==="staff"?"MindKlass Staff":"",school:U.role==="student"?(U.school||"").trim():"",workplace:U.role==="teacher"||U.role==="professional"?(U.workplace||"").trim():U.role==="staff"?"MindKlass":"",staff_position:U.role==="staff"?(U.staffPos==="Other (type your position)"?(U.staffOther||"").trim():(U.staffPos||"")):"",staff_manager:U.role==="staff"?(U.staffMgr||"").trim():""}' 'staff_position:U.role==="staff"'
AddP 'profile update' 'profession:U.role==="professional"?U.profession:null,details:{school:U.role==="student"?(U.school||"").trim():null,workplace:U.role==="teacher"||U.role==="professional"?(U.workplace||"").trim():null,phone:U.phone.trim()||null}' 'profession:U.role==="professional"?U.profession:U.role==="staff"?"MindKlass Staff":null,details:{school:U.role==="student"?(U.school||"").trim():null,workplace:U.role==="teacher"||U.role==="professional"?(U.workplace||"").trim():U.role==="staff"?"MindKlass":null,phone:U.phone.trim()||null}' 'U.role==="staff"?"MindKlass":null'

# ---- 3. staff state, navigation, pages, routes ----
$hook = 'var mkSS=f(null),mkStf=mkSS[0],setMkStf=mkSS[1],mkSR=f(0),mkTick=mkSR[0],setMkTick=mkSR[1];de(()=>{if(!y||!y.id||String(y.role||"").startsWith("visitor")){setMkStf(null);return}let live=!0;mksApi.loadMember(y.id).then(r=>{if(!live)return;if(r.error){setMkStf(null);return}if(r.data){setMkStf(r.data);return}if(y.staffReq&&y.staffReq.position){mksApi.requestStaff(y.id,y.staffReq.position,y.staffReq.manager).then(r2=>{if(live&&r2.data)setMkStf(Object.assign({status:"pending"},r2.data))})}else setMkStf(null)}).catch(()=>{});return()=>{live=!1}},[y&&y.id,mkTick]);'
AddP 'staff membership state' 'let ot=y?.role?.startsWith("visitor");' ($hook + 'let ot=y?.role?.startsWith("visitor");') 'mkStf=mkSS[0]'
AddP 'staff nav item' '.concat(dt?[{id:"training",I:we,l:"Teacher''s Course"}]:[]),yd=i=>{' '.concat(dt?[{id:"training",I:we,l:"Teacher''s Course"}]:[]).concat((mkStf||(y&&y.staffReq))&&!dt&&L!=="admin"?[{id:"staffhub",I:Ge,l:"Staff Tracker"}]:[]),yd=i=>{' 'id:"staffhub",I:Ge'
AddP 'admin nav item' '{id:"users",I:Ue,l:"Users"},{id:"approvals",I:Ei,l:"Course Approvals"}' '{id:"users",I:Ue,l:"Users"},{id:"staffperf",I:pt,l:"Staff Performance"},{id:"approvals",I:Ei,l:"Course Approvals"}' 'id:"staffperf",I:pt'
$viewOld = 'if(G==="ipersonality")return J({children:e(MK25,{T:a,isMobile:X,card:k,bP:C,bO:R})});'
$viewNew = 'if(G==="staffhub")return J({children:e(MkStaffHub,{T:a,isMobile:X,card:k,bP:C,bO:R,user:y,staff:mkStf,onStaff:()=>setMkTick(n=>n+1)})});if(G==="staffperf"&&L==="admin")return J({children:e(MkStaffAdmin,{T:a,isMobile:X,card:k,bP:C,bO:R,user:y})});'
AddP 'staff pages' $viewOld ($viewNew + $viewOld) 'G==="staffhub")return J'
AddP 'route slugs' '"push":"push","child":"child"};var MK_SLUGS=' '"push":"push","child":"child","stafftracker":"staffhub","staff":"staffhub","staffperformance":"staffperf"};var MK_SLUGS=' '"stafftracker":"staffhub"'
AddP 'page slugs' '"push":"Notifications","child":"Child"};var MK_VIEW_TO_SLUG' '"push":"Notifications","child":"Child","staffhub":"StaffTracker","staffperf":"StaffPerformance"};var MK_VIEW_TO_SLUG' '"staffhub":"StaffTracker"'

# ---- 4. the flyer ----
$flyer = ReadSrc 'flyer.js'
if ($flyer -match '[^\x00-\x7F]') { throw 'flyer.js must be plain ASCII' }
$fs = $d.IndexOf('function Id(')
$fe = $d.IndexOf('function Rg(h){')
if ($fs -lt 0 -or $fe -lt $fs) { throw 'flyer function not found' }
$d = $d.Substring(0, $fs) + $flyer.TrimEnd() + $d.Substring($fe)
"  flyer function replaced"
AddP 'flyer on sign-in page' 'e(Id,{}),t("div",{className:"mk-auth-card"' 'e(Id,{auth:!0}),t("div",{className:"mk-auth-card"' 'e(Id,{auth:!0})'

# ---- apply the recorded text patches ----
foreach ($p in $plist) { Patch $p[0] $p[1] $p[2] $p[3] }
if ($DumpJson) { $o = $plist | ForEach-Object { [ordered]@{ name = $_[0]; old = $_[1]; new = $_[2]; marker = $_[3] } }; [IO.File]::WriteAllText($DumpJson, ($o | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false))) }
[IO.File]::WriteAllBytes($Target, $enc.GetBytes($d))
"patched: $Target"
