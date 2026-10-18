# Generates ..\life_y1_ui_patches.json : exact {old,new} string swaps applied to the bundle.
# Shared by patch_life_y1_v2.py (repo build) and apply_life_y1_v2.ps1 (Windows).
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$swaps = @()
function Add-Swap($name, $old, $new) { $script:swaps += [ordered]@{ name = $name; old = $old; new = $new } }

# 1. catalogue card chips
Add-Swap 'card chips' '{I:gt,l:`${x.totalQuestions} Q \xB7 ${x.examMins} min`},{I:je,l:`${x.passMark}% to pass`}].map((F,Q)=>' '...(x.assessmentType==="project"?[{I:_e,l:"Projects & activities"},{I:je,l:"Portfolio-graded"}]:[{I:gt,l:`${x.totalQuestions} Q \xB7 ${x.examMins} min`},{I:je,l:`${x.passMark}% to pass`}])].map((F,Q)=>'

# 2. course header chips
Add-Swap 'header chips' '{I:gt,l:`${l.totalQuestions} Q \xB7 ${l.examMins} min`},{I:je,l:`${l.passMark}% to pass`}].map((d,m)=>' '...(l.assessmentType==="project"?[{I:_e,l:"Projects & activities"},{I:je,l:"Portfolio-graded"}]:[{I:gt,l:`${l.totalQuestions} Q \xB7 ${l.examMins} min`},{I:je,l:`${l.passMark}% to pass`}])].map((d,m)=>'

# 3. header badge: no "IGCSE <code>" for project courses
Add-Swap 'header badge' 'children:l.cat==="General Courses"?l.termLabel:t(D,{children:["IGCSE ",l.code," \xB7 ",l.year," \xB7 ",l.termLabel]})' 'children:l.cat==="General Courses"||l.assessmentType==="project"?l.termLabel:t(D,{children:["IGCSE ",l.code," \xB7 ",l.year," \xB7 ",l.termLabel]})'

# 4. capstones and portfolio panel instead of the term-assessment card
$termOld = 't("div",{style:{...k,borderTop:"4px solid #d97706"},children:[t("h3",{style:{fontSize:16,fontWeight:900,fontFamily:"Outfit,sans-serif",color:a.head,margin:"0 0 6px",display:"flex",alignItems:"center",gap:7},children:[e(gt,{size:17,color:"#d97706"}),"Term Assessment"]}),'
$panel = 'l.assessmentType==="project"?t("div",{style:{...k,borderTop:"4px solid #7c3aed"},children:[t("h3",{style:{fontSize:16,fontWeight:900,fontFamily:"Outfit,sans-serif",color:a.head,margin:"0 0 6px",display:"flex",alignItems:"center",gap:7},children:[e(gt,{size:17,color:"#7c3aed"}),"Capstones and Portfolio"]}),e("p",{style:{fontSize:12.5,color:a.txt,lineHeight:1.7,margin:"0 0 14px"},children:"This course has no written exam. You are assessed on your participation, your portfolio and four capstone projects, each judged with a clear rubric."}),e("div",{style:{display:"flex",flexDirection:"column",gap:10},children:(l.capstones||[]).map((cp,ci)=>{let cu=l.units.find(z=>z.n===cp.week),cd=!!cu&&n.includes(cu.id);return t("div",{style:{border:`1px solid ${cd?"#a7f3d0":a.border}`,borderRadius:12,padding:"12px 14px",background:cd?"#f0fdf4":a.alt},children:[t("div",{style:{fontSize:10,fontWeight:800,color:a.muted,textTransform:"uppercase",letterSpacing:.5},children:["Week ",cp.week,cd?" \xB7 Completed":""]}),e("div",{style:{fontSize:14,fontWeight:800,color:a.head,margin:"2px 0 4px"},children:cp.title}),e("p",{style:{fontSize:12,color:a.txt,lineHeight:1.6,margin:"0 0 8px"},children:cp.desc}),e("div",{style:{display:"flex",flexWrap:"wrap",gap:5,marginBottom:8},children:(cp.rubric||[]).map((rb,ri)=>e("span",{style:{fontSize:10.5,fontWeight:700,color:"#7c3aed",background:a.pale,padding:"3px 9px",borderRadius:99},children:rb},ri))}),cu&&e("button",{onClick:()=>{mkSaveBookmark(y?.id,$,cu.id),Tn(cu.id),Ie("unit"),window.scrollTo(0,0)},style:{...R,padding:"7px 14px",fontSize:12},children:cd?"Review capstone":"Open capstone"})]},ci)})}),n.length>=l.units.length?e("div",{style:{marginTop:12,padding:"11px 14px",borderRadius:10,background:"#dcfce7",color:"#047857",fontSize:12.5,fontWeight:700},children:"You have completed every unit. Gather your portfolio and get ready to present at the Grand Summit."}):t("p",{style:{fontSize:11.5,color:a.muted,margin:"12px 0 0"},children:["Progress: ",n.length,"/",l.units.length," units complete."]})]}):'
Add-Swap 'capstone panel' $termOld ($panel + $termOld)

# 5. progress bar in the unit header
Add-Swap 'unit progress bar' 'qs("sjunit_"+n.id,Cd(n),"Listen")]}),n.sections.map(' 'qs("sjunit_"+n.id,Cd(n),"Listen"),e("div",{style:{flexBasis:"100%",height:6,background:a.alt,borderRadius:99,overflow:"hidden"},children:e("div",{style:{height:"100%",width:`${Math.round(n.n/l.units.length*100)}%`,background:"linear-gradient(90deg,#2158e8,#059669)",borderRadius:99}})})]}),n.sections.map('

# 6. quick-check wording for project courses
$chkOld = '"Answer all of these correctly to finish the unit. These are practice questions only ' + [string][char]92 + 'u2014 they do NOT count toward your term assessment score. They simply unlock the next steps."'
$chkNew = 'l.assessmentType==="project"?"Answer all of these to finish the unit. These are practice questions only, so there is no pressure: they simply check that the key ideas landed.":' + $chkOld
Add-Swap 'quick check wording' $chkOld $chkNew

$json = $swaps | ConvertTo-Json -Depth 5
$sb = New-Object Text.StringBuilder
foreach ($ch in $json.ToCharArray()) { if ([int]$ch -gt 126) { [void]$sb.Append(('\u{0:x4}' -f [int]$ch)) } else { [void]$sb.Append($ch) } }
[IO.File]::WriteAllText((Join-Path (Split-Path -Parent $here) 'life_y1_ui_patches.json'), $sb.ToString(), (New-Object Text.UTF8Encoding($false)))
"swaps: $($swaps.Count)"
