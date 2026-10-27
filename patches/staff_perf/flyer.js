function Id(props){
  var pz=f(!1),paused=pz[0],setPaused=pz[1];
  var reduce=!1;
  try{reduce=window.matchMedia&&window.matchMedia("(prefers-reduced-motion: reduce)").matches}catch(x){}
  var n=mkSlides.length,strip=mkSlides.concat(mkSlides),total=strip.length,auth=!!(props&&props.auth);
  /* Slide-by-slide carousel: each slide holds, then glides to the next. One slide shows on
     phones and tablets, two on wide screens. The strip is doubled so the loop is seamless. */
  var kf="",i,hold=.8;
  for(i=0;i<n;i++){
    var t0=i*100/n,t1=t0+100/n*hold,sh=(i*100/total).toFixed(4);
    kf+=t0.toFixed(3)+"%,"+t1.toFixed(3)+"%{transform:translateX(-"+sh+"%)}"}
  kf+="100%{transform:translateX(-"+(n*100/total).toFixed(4)+"%)}";
  var css=".mkfl{overflow:hidden;border-radius:18px;background:#0d1f4b;box-shadow:0 14px 40px rgba(0,0,0,.30);position:relative;line-height:0}"+
    ".mkfl-in{display:flex;width:"+(total*100)+"%;animation:mkflStep "+(n*6)+"s cubic-bezier(.65,0,.35,1) infinite}"+
    ".mkfl-in.mkfl-pause{animation-play-state:paused}"+
    ".mkfl-in.mkfl-still{animation:none}"+
    ".mkfl-in picture{flex:0 0 "+(100/total)+"%;display:block}"+
    ".mkfl-in img{width:100%;height:auto;display:block}"+
    "@media (min-width:900px){.mkfl-in{width:"+(total*50)+"%}}"+
    "@keyframes mkflStep{"+kf+"}";
  var wrap=auth?{position:"relative",left:"50%",transform:"translateX(-50%)",width:"min(1080px, calc(100vw - 24px))",margin:"0 0 18px"}
    :{width:"100%",maxWidth:1120,margin:"0 auto 16px"};
  return t("div",{className:"mkfl",onMouseEnter:function(){setPaused(!0)},onMouseLeave:function(){setPaused(!1)},onTouchStart:function(){setPaused(!0)},onTouchEnd:function(){setTimeout(function(){setPaused(!1)},1800)},style:wrap,"aria-roledescription":"carousel","aria-label":"MindKlass programmes",children:[
    e("style",{children:css}),
    e("div",{className:"mkfl-in"+(reduce?" mkfl-still":"")+(paused?" mkfl-pause":""),children:strip.map(function(sl,k){
      return t("picture",{children:[
        e("source",{media:"(max-width: 640px)",srcSet:sl.m}),
        e("img",{src:sl.s,alt:k<n?sl.a:"",loading:k<2?"eager":"lazy",decoding:"async","aria-hidden":k>=n?"true":void 0})]},k)})})]})}
