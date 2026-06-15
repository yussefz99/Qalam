/* =========================================================================
   Qalam — shared core for the Letter Unit direction prototypes
   exposes window.Q : mascot poses, brand star, icons, baa geometry,
   a reusable drawing/trace surface, and tablet-fit scaling.
   ========================================================================= */
(function(){
const M = {
  idle:`<svg viewBox="0 0 200 280"><ellipse cx="100" cy="265" rx="60" ry="8" fill="#0E5B5F" opacity="0.10"/><path d="M60 60 Q60 40 100 40 Q140 40 140 60 L140 210 Q140 230 100 230 Q60 230 60 210 Z" fill="#0E5B5F"/><path d="M60 110 Q100 116 140 110" fill="none" stroke="#0a4448" stroke-width="2" opacity="0.5"/><path d="M60 160 Q100 166 140 160" fill="none" stroke="#0a4448" stroke-width="2" opacity="0.5"/><path d="M72 60 Q70 130 76 200" stroke="#1a797d" stroke-width="6" stroke-linecap="round" fill="none" opacity="0.7"/><path d="M60 210 L100 270 L140 210 Z" fill="#168A8F"/><path d="M100 230 L100 270" stroke="#F2A60C" stroke-width="2" stroke-linecap="round"/><rect x="70" y="80" width="60" height="60" rx="14" fill="#FAF6EE"/><circle cx="86" cy="108" r="5" fill="#222A2E"/><circle cx="114" cy="108" r="5" fill="#222A2E"/><circle cx="84.5" cy="106" r="1.6" fill="#fff"/><circle cx="112.5" cy="106" r="1.6" fill="#fff"/><path d="M88 124 Q100 132 112 124" fill="none" stroke="#222A2E" stroke-width="2.5" stroke-linecap="round"/><circle cx="80" cy="120" r="2.5" fill="#FF8A6B" opacity="0.6"/><circle cx="120" cy="120" r="2.5" fill="#FF8A6B" opacity="0.6"/><path d="M58 150 Q42 160 44 178" stroke="#0E5B5F" stroke-width="10" stroke-linecap="round" fill="none"/><path d="M142 150 Q158 160 156 178" stroke="#0E5B5F" stroke-width="10" stroke-linecap="round" fill="none"/><circle cx="44" cy="178" r="8" fill="#0E5B5F"/><circle cx="156" cy="178" r="8" fill="#0E5B5F"/></svg>`,
  write:`<svg viewBox="0 0 200 280"><ellipse cx="100" cy="265" rx="60" ry="8" fill="#0E5B5F" opacity="0.10"/><path d="M60 60 Q60 40 100 40 Q140 40 140 60 L140 210 Q140 230 100 230 Q60 230 60 210 Z" fill="#0E5B5F"/><path d="M60 110 Q100 116 140 110" fill="none" stroke="#0a4448" stroke-width="2" opacity="0.5"/><path d="M60 160 Q100 166 140 160" fill="none" stroke="#0a4448" stroke-width="2" opacity="0.5"/><path d="M72 60 Q70 130 76 200" stroke="#1a797d" stroke-width="6" stroke-linecap="round" fill="none" opacity="0.7"/><path d="M60 210 L100 270 L140 210 Z" fill="#168A8F"/><path d="M100 230 L100 270" stroke="#F2A60C" stroke-width="2" stroke-linecap="round"/><rect x="70" y="80" width="60" height="60" rx="14" fill="#FAF6EE"/><ellipse cx="86" cy="108" rx="4" ry="6" fill="#222A2E"/><ellipse cx="114" cy="108" rx="4" ry="6" fill="#222A2E"/><circle cx="84.5" cy="105" r="1.6" fill="#fff"/><circle cx="112.5" cy="105" r="1.6" fill="#fff"/><path d="M92 126 Q100 124 108 126" fill="none" stroke="#222A2E" stroke-width="2.5" stroke-linecap="round"/><path d="M58 160 Q44 200 70 215" stroke="#0E5B5F" stroke-width="10" stroke-linecap="round" fill="none"/><circle cx="70" cy="215" r="8" fill="#0E5B5F"/><path d="M142 160 Q170 200 168 235" stroke="#0E5B5F" stroke-width="10" stroke-linecap="round" fill="none"/><circle cx="168" cy="235" r="8" fill="#0E5B5F"/><path d="M100 270 Q120 275 140 268" stroke="#F2A60C" stroke-width="3" stroke-linecap="round" fill="none" opacity="0.7"/></svg>`,
  think:`<svg viewBox="0 0 200 280"><ellipse cx="100" cy="265" rx="60" ry="8" fill="#0E5B5F" opacity="0.10"/><path d="M60 60 Q60 40 100 40 Q140 40 140 60 L140 210 Q140 230 100 230 Q60 230 60 210 Z" fill="#0E5B5F"/><path d="M60 110 Q100 116 140 110" fill="none" stroke="#0a4448" stroke-width="2" opacity="0.5"/><path d="M60 160 Q100 166 140 160" fill="none" stroke="#0a4448" stroke-width="2" opacity="0.5"/><path d="M72 60 Q70 130 76 200" stroke="#1a797d" stroke-width="6" stroke-linecap="round" fill="none" opacity="0.7"/><path d="M60 210 L100 270 L140 210 Z" fill="#168A8F"/><rect x="70" y="80" width="60" height="60" rx="14" fill="#FAF6EE"/><circle cx="86" cy="106" r="5" fill="#222A2E"/><circle cx="114" cy="106" r="5" fill="#222A2E"/><circle cx="86" cy="104" r="1.6" fill="#fff"/><circle cx="114" cy="104" r="1.6" fill="#fff"/><path d="M92 124 Q100 122 102 126" fill="none" stroke="#222A2E" stroke-width="2.5" stroke-linecap="round"/><path d="M142 150 Q160 145 135 138" stroke="#0E5B5F" stroke-width="10" stroke-linecap="round" fill="none"/><circle cx="135" cy="138" r="8" fill="#0E5B5F"/><path d="M58 150 Q42 160 44 178" stroke="#0E5B5F" stroke-width="10" stroke-linecap="round" fill="none"/><circle cx="44" cy="178" r="8" fill="#0E5B5F"/><circle cx="160" cy="60" r="3" fill="#168A8F" opacity="0.6"/><circle cx="172" cy="46" r="5" fill="#168A8F" opacity="0.8"/><circle cx="186" cy="28" r="7" fill="#168A8F"/></svg>`,
  tryAgain:`<svg viewBox="0 0 200 280"><ellipse cx="100" cy="265" rx="60" ry="8" fill="#0E5B5F" opacity="0.10"/><path d="M60 60 Q60 40 100 40 Q140 40 140 60 L140 210 Q140 230 100 230 Q60 230 60 210 Z" fill="#0E5B5F"/><path d="M60 110 Q100 116 140 110" fill="none" stroke="#0a4448" stroke-width="2" opacity="0.5"/><path d="M60 160 Q100 166 140 160" fill="none" stroke="#0a4448" stroke-width="2" opacity="0.5"/><path d="M72 60 Q70 130 76 200" stroke="#1a797d" stroke-width="6" stroke-linecap="round" fill="none" opacity="0.7"/><path d="M60 210 L100 270 L140 210 Z" fill="#168A8F"/><rect x="70" y="80" width="60" height="60" rx="14" fill="#FAF6EE"/><path d="M82 110 Q86 106 90 110" fill="none" stroke="#222A2E" stroke-width="3" stroke-linecap="round"/><path d="M110 110 Q114 106 118 110" fill="none" stroke="#222A2E" stroke-width="3" stroke-linecap="round"/><path d="M88 128 Q100 124 112 128" fill="none" stroke="#222A2E" stroke-width="2.5" stroke-linecap="round"/><circle cx="80" cy="124" r="3" fill="#FF8A6B" opacity="0.7"/><circle cx="120" cy="124" r="3" fill="#FF8A6B" opacity="0.7"/><path d="M58 150 Q42 145 38 165" stroke="#0E5B5F" stroke-width="10" stroke-linecap="round" fill="none"/><path d="M142 150 Q158 145 162 165" stroke="#0E5B5F" stroke-width="10" stroke-linecap="round" fill="none"/><circle cx="38" cy="165" r="8" fill="#0E5B5F"/><circle cx="162" cy="165" r="8" fill="#0E5B5F"/></svg>`,
  cheer:`<svg viewBox="0 0 200 280"><ellipse cx="100" cy="265" rx="60" ry="8" fill="#0E5B5F" opacity="0.10"/><g transform="rotate(-6 100 140)"><path d="M60 60 Q60 40 100 40 Q140 40 140 60 L140 210 Q140 230 100 230 Q60 230 60 210 Z" fill="#0E5B5F"/><path d="M60 110 Q100 116 140 110" fill="none" stroke="#0a4448" stroke-width="2" opacity="0.5"/><path d="M60 160 Q100 166 140 160" fill="none" stroke="#0a4448" stroke-width="2" opacity="0.5"/><path d="M72 60 Q70 130 76 200" stroke="#1a797d" stroke-width="6" stroke-linecap="round" fill="none" opacity="0.7"/><path d="M60 210 L100 270 L140 210 Z" fill="#168A8F"/><path d="M100 230 L100 270" stroke="#F2A60C" stroke-width="2" stroke-linecap="round"/><rect x="70" y="80" width="60" height="60" rx="14" fill="#FAF6EE"/><path d="M80 108 Q86 100 92 108" fill="none" stroke="#222A2E" stroke-width="3" stroke-linecap="round"/><path d="M108 108 Q114 100 120 108" fill="none" stroke="#222A2E" stroke-width="3" stroke-linecap="round"/><path d="M84 120 Q100 138 116 120" fill="none" stroke="#222A2E" stroke-width="3" stroke-linecap="round"/><circle cx="80" cy="124" r="3" fill="#FF8A6B" opacity="0.7"/><circle cx="120" cy="124" r="3" fill="#FF8A6B" opacity="0.7"/></g><path d="M58 100 Q42 70 48 50" stroke="#0E5B5F" stroke-width="10" stroke-linecap="round" fill="none"/><path d="M142 100 Q158 70 152 50" stroke="#0E5B5F" stroke-width="10" stroke-linecap="round" fill="none"/><circle cx="48" cy="50" r="8" fill="#0E5B5F"/><circle cx="152" cy="50" r="8" fill="#0E5B5F"/><circle cx="32" cy="40" r="4" fill="#F2A60C"/><circle cx="170" cy="34" r="5" fill="#F2A60C"/><circle cx="20" cy="120" r="3" fill="#F2A60C"/><circle cx="180" cy="130" r="3" fill="#F2A60C"/></svg>`
};
const STAR = (s)=>`<svg width="${s}" height="${s}" viewBox="0 0 48 48"><path d="M24 4.5l5.6 11.34 12.52 1.82-9.06 8.83 2.14 12.47L24 33.06l-11.2 5.9 2.14-12.47-9.06-8.83 12.52-1.82L24 4.5z" fill="#F2A60C" stroke="#C5860A" stroke-width="1.5" stroke-linejoin="round"/><path d="M24 9.6l4.1 8.3 9.16 1.34-6.63 6.46 1.56 9.13L24 30.5l-8.19 4.32 1.56-9.13-6.63-6.46 9.16-1.34L24 9.6z" fill="#FBC34A"/></svg>`;
const IC = {
  speaker:`<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 5L6 9H2v6h4l5 4V5z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/><path d="M19 5a9 9 0 0 1 0 14"/></svg>`,
  replay:`<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/></svg>`,
  arrow:`<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M13 6l6 6-6 6"/></svg>`,
  trash:`<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/></svg>`,
  check:`<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M4 12.5l5 5 11-11"/></svg>`
};
const BAA_PATH = "M150 152 Q300 350 460 158";

const Q = { M, STAR, IC, BAA_PATH, scale:1 };

/* tablet-fit scaling for a fixed stage (default 1280x800) */
Q.fit = function(stage, w, h){
  w=w||1280; h=h||800; const pad=44;
  Q.scale=Math.min((innerWidth-pad)/w,(innerHeight-pad)/h,1);
  stage.style.transform='scale('+Q.scale+')';
  document.querySelectorAll('.writebox').forEach(b=>{ if(b._ctrl) b._ctrl.size(); });
};
Q.ping = function(btn){ btn.classList.remove('ping'); void btn.offsetWidth; btn.classList.add('ping'); };

/* ---- reusable trace surface ----------------------------------------------
   config: { guide:'path'|'glyph'|'baseline'|'none', glyph, glyphSize,
             demo:bool, demoShow:bool, corner:bool, reps, repLabel,
             firstFix:bool, fixText, praiseText, praiseDone, thinkText,
             ghost:bool (show correct path over the child's ink on a miss),
             setTutor(pose,html,tone), onComplete(ctrl) }                    */
Q.makeWrite = function(config){
  const c = Object.assign({guide:'none', demo:false, corner:false, reps:1, firstFix:false, setTutor:function(){}}, config);
  const box=document.createElement('div'); box.className='writebox';

  if(c.guide==='path'){
    box.innerHTML += `<svg class="guidepath" viewBox="0 0 600 400" preserveAspectRatio="xMidYMid meet">
      <path class="gline" d="${BAA_PATH}"></path>
      <circle cx="300" cy="300" r="13" fill="none" stroke="#D6E8E8" stroke-width="3" stroke-dasharray="2 9"></circle>
      <circle class="startdot-o" cx="150" cy="152" r="14"></circle>
      <circle class="startdot-i" cx="150" cy="152" r="6.5"></circle>
      <text x="150" y="157" text-anchor="middle" font-family="Fredoka" font-weight="600" font-size="15" fill="#0E5B5F">1</text>
    </svg>`;
  } else if(c.guide==='glyph'){
    box.innerHTML += `<div class="guide-glyph" style="font-size:${c.glyphSize||150}px">${c.glyph||''}</div>`;
  } else if(c.guide==='baseline'){
    box.innerHTML += `<div class="ruled" style="top:62%"></div>`;
  }
  if(c.demo){
    box.innerHTML += `<svg class="demopath${c.demoShow?' show':''}" viewBox="0 0 600 400" preserveAspectRatio="xMidYMid meet">
      <path class="dline" pathLength="1" stroke-dasharray="1" stroke-dashoffset="1" d="${BAA_PATH}"><animate attributeName="stroke-dashoffset" from="1" to="0" dur="1.5s" begin="indefinite" fill="freeze"></animate></path>
      <circle class="nuqta" cx="300" cy="300" r="13" fill="#0E5B5F" opacity="0"><animate attributeName="opacity" from="0" to="1" begin="indefinite" dur=".35s" fill="freeze"></animate></circle>
      <circle class="dnib" r="13" fill="#F2A60C"><animateMotion path="${BAA_PATH}" dur="1.5s" begin="indefinite" fill="freeze"></animateMotion></circle>
      <circle class="dnib-i" r="6" fill="#fff"><animateMotion path="${BAA_PATH}" dur="1.5s" begin="indefinite" fill="freeze"></animateMotion></circle>
    </svg>`;
  }
  if(c.ghost){
    box.innerHTML += `<svg class="ghostpath" viewBox="0 0 600 400" preserveAspectRatio="xMidYMid meet" style="position:absolute;inset:0;width:100%;height:100%;pointer-events:none;opacity:0;transition:opacity .3s ease">
      <path d="${BAA_PATH}" fill="none" stroke="#3FB984" stroke-width="11" stroke-linecap="round" stroke-dasharray="3 14"></path></svg>`;
  }
  const canvas=document.createElement('canvas'); box.appendChild(canvas);
  if(c.guide==='baseline' && c.noGuideBadge!==false){ const b=document.createElement('div'); b.className='noguide'; b.textContent='No guide · from memory'; box.appendChild(b); }
  if(c.corner){ const cb=document.createElement('button'); cb.className='cornerbtn'; cb.innerHTML=`<span class="d"></span>Watch Me`; box.appendChild(cb); cb.addEventListener('click',()=>ctrl.replayDemo(true)); }
  const clr=document.createElement('button'); clr.className='clearbtn'; clr.innerHTML=IC.trash+'Clear'; box.appendChild(clr);

  let repline=null;
  if(c.reps>1 || c.repLabel){
    repline=document.createElement('div'); repline.className='repline';
    let pips=''; for(let i=0;i<c.reps;i++) pips+='<i class="pip"></i>';
    repline.innerHTML=`<span>${c.repLabel||'Clean reps'}</span><span class="pips">${pips}</span>`;
    box.appendChild(repline);
  }

  const ctx2=canvas.getContext('2d');
  let drawing=false,last=null,drawn=0,attempts=0,repsDone=0,evaluating=false;
  function size(){ const r=box.getBoundingClientRect(); canvas.width=Math.max(2,Math.round(r.width/Q.scale)); canvas.height=Math.max(2,Math.round(r.height/Q.scale));
    ctx2.lineCap='round'; ctx2.lineJoin='round'; ctx2.strokeStyle='#0E5B5F'; ctx2.lineWidth=12; }
  function pt(e){ const r=canvas.getBoundingClientRect(); return {x:(e.clientX-r.left)/Q.scale,y:(e.clientY-r.top)/Q.scale}; }
  function down(e){ if(evaluating) return; drawing=true; last=pt(e); try{canvas.setPointerCapture(e.pointerId);}catch(_){} }
  function move(e){ if(!drawing) return; const p=pt(e); ctx2.beginPath(); ctx2.moveTo(last.x,last.y); ctx2.lineTo(p.x,p.y); ctx2.stroke(); drawn+=Math.hypot(p.x-last.x,p.y-last.y); last=p; }
  function up(){ if(!drawing) return; drawing=false; if(drawn>45 && !evaluating) evaluate(); }
  canvas.addEventListener('pointerdown',down); canvas.addEventListener('pointermove',move);
  canvas.addEventListener('pointerup',up); canvas.addEventListener('pointerleave',up);
  function clear(){ ctx2.clearRect(0,0,canvas.width,canvas.height); drawn=0; const g=box.querySelector('.ghostpath'); if(g)g.style.opacity=0; }
  clr.addEventListener('click',()=>{ if(!evaluating) clear(); });
  function fillPip(){ if(repline){ const p=repline.querySelectorAll('.pip')[repsDone-1]; if(p)p.classList.add('done'); } }

  function evaluate(force){
    evaluating=true;
    if(c.firstFix && attempts===0 && !force){
      attempts++;
      c.setTutor('think', c.thinkText||'Let me look <span class="thinking-dots"><i></i><i></i><i></i></span>');
      const g=box.querySelector('.ghostpath');
      setTimeout(()=>{ c.setTutor('tryAgain', c.fixText, 'coral'); if(g)g.style.opacity=.9; setTimeout(()=>{ if(g)g.style.opacity=0; clear(); evaluating=false; }, c.ghost?1400:350); }, 750);
      return;
    }
    c.setTutor('think', c.thinkText||'Let me look <span class="thinking-dots"><i></i><i></i><i></i></span>');
    setTimeout(()=>{ attempts++; repsDone++; fillPip(); const done=repsDone>=c.reps;
      c.setTutor('cheer', done?(c.praiseDone||c.praiseText):c.praiseText, 'leaf');
      if(done){ evaluating=false; ctrl.complete=true; if(c.onComplete) c.onComplete(ctrl); }
      else setTimeout(()=>{ clear(); evaluating=false; }, 900);
    }, 750);
  }
  function markCorrect(){ if(!evaluating && !ctrl.complete) evaluate(true); }
  function replayDemo(reveal){ const dp=box.querySelector('.demopath'); if(!dp) return;
    if(reveal) dp.classList.add('show'); dp.classList.add('playing');
    dp.querySelectorAll('animate, animateMotion').forEach(a=>{ try{a.beginElement();}catch(e){} });
    const nq=dp.querySelector('.nuqta animate'); setTimeout(()=>{ try{nq&&nq.beginElement();}catch(e){} },1500);
    setTimeout(()=>dp.classList.remove('playing'),1750); if(reveal) setTimeout(()=>dp.classList.remove('show'),2200);
  }
  const ctrl={ clear, markCorrect, replayDemo, size, complete:false, el:box, get attempts(){return attempts;} };
  box._ctrl=ctrl;
  requestAnimationFrame(()=>{ size(); if(c.demo && c.demoShow) replayDemo(false); });
  return box;
};

window.Q = Q;
})();
