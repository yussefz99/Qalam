/* =========================================================================
   Qalam — Baa (ب) Letter Unit · prototype logic
   - one persistent room (tutor left, activity right, R->L ribbon on top)
   - reuses the existing trace / stroke-animation / celebration look
   - new surfaces: unit shell, meet, in-context forms, words, listen & write
   ========================================================================= */

/* ---- mascot poses (verbatim from repo assets/mascot/*.svg) ---- */
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
  check:`<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M4 12.5l5 5 11-11"/></svg>`,
  map:`<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 4L3 6v14l6-2 6 2 6-2V4l-6 2-6-2z"/><path d="M9 4v14M15 6v14"/></svg>`
};

/* ---- baa stroke geometry (canvas viewBox 0 0 600 400) ---- */
const BAA_PATH = "M150 152 Q300 350 460 158";

/* ============================ STATE ============================ */
const TOTAL = 6;
let cur = 0, sub = null, scale = 1;
const visited = new Set([0]);

const $ = (id)=>document.getElementById(id);
const mascotBox=$('mascotBox'), speech=$('speech'), soundBox=$('soundBox'),
      eyebrow=$('eyebrow'), headline=$('headline'), scene=$('scene'), actions=$('actions'),
      ribbon=$('ribbon');

function setTutor(pose, html, tone){
  mascotBox.innerHTML = M[pose] || M.idle;
  speech.className = 'speech' + (tone ? ' '+tone : '');
  const label = tone==='coral' ? 'Qalam says' : tone==='leaf' ? 'Qalam says' : '';
  speech.innerHTML = (label?`<span class="tone">${label}</span>`:'') + html;
}
function showSound(on){ soundBox.classList.toggle('hidden', !on); }

/* action row builder: items = [{label, kind, icon, on, disabled, id}] */
function setActions(items){
  actions.innerHTML='';
  items.forEach(it=>{
    if(it.spacer){ const s=document.createElement('div'); s.className='spacer'; actions.appendChild(s); return; }
    if(it.hint){ const h=document.createElement('div'); h.className='hint'; h.innerHTML=`<span class="pen"></span>${it.hint}`; actions.appendChild(h); return; }
    const b=document.createElement('button');
    b.className='btn '+(it.kind||'primary');
    if(it.id) b.id=it.id;
    if(it.disabled) b.disabled=true;
    b.innerHTML=(it.icon||'')+`<span>${it.label}</span>`+(it.iconAfter||'');
    if(it.on) b.addEventListener('click',it.on);
    actions.appendChild(b);
  });
}

/* ============================ RIBBON ============================ */
function buildRibbon(){
  ribbon.innerHTML='';
  for(let i=0;i<TOTAL;i++){
    const d=document.createElement('div');
    d.className='dot'+(i<cur?' done':'')+(i===cur?' active':'');
    d.title='Section '+(i+1);
    d.addEventListener('click',()=>go(i));
    ribbon.appendChild(d);
  }
}

/* ============================ DRAWING SURFACE ============================ *
 * Builds a .writebox with optional guide + a freehand <canvas> in deep-ink.
 * config: { guide:'path'|'glyph'|'baseline'|'none', glyph, demo, corner,
 *           reps, repLabel, firstFix, onComplete(ctrl) }
 * returns the writebox element (with ._ctrl)                               */
function makeWrite(config){
  const c = Object.assign({guide:'none', demo:false, corner:false, reps:1, firstFix:false}, config);
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
    box.innerHTML += `<svg class="demopath${sub==='watch'?' show':''}" viewBox="0 0 600 400" preserveAspectRatio="xMidYMid meet">
      <path class="dline" pathLength="1" stroke-dasharray="1" stroke-dashoffset="1" d="${BAA_PATH}">
        <animate attributeName="stroke-dashoffset" from="1" to="0" dur="1.5s" begin="indefinite" fill="freeze"></animate>
      </path>
      <circle class="nuqta" cx="300" cy="300" r="13" fill="#0E5B5F" opacity="0">
        <animate attributeName="opacity" from="0" to="1" begin="indefinite" dur=".35s" fill="freeze"></animate>
      </circle>
      <circle class="dnib" r="13" fill="#F2A60C"><animateMotion path="${BAA_PATH}" dur="1.5s" begin="indefinite" fill="freeze"></animateMotion></circle>
      <circle class="dnib-i" r="6" fill="#fff"><animateMotion path="${BAA_PATH}" dur="1.5s" begin="indefinite" fill="freeze"></animateMotion></circle>
    </svg>`;
  }

  const canvas=document.createElement('canvas'); box.appendChild(canvas);

  if(c.guide==='baseline' && c.noGuideBadge!==false){
    const b=document.createElement('div'); b.className='noguide'; b.textContent='No guide · from memory'; box.appendChild(b);
  }
  if(c.corner){
    const cb=document.createElement('button'); cb.className='cornerbtn';
    cb.innerHTML=`<span class="d"></span>Watch Me`; box.appendChild(cb);
    cb.addEventListener('click',()=>ctrl.replayDemo(true));
  }
  const clr=document.createElement('button'); clr.className='clearbtn';
  clr.innerHTML=IC.trash+'Clear'; box.appendChild(clr);

  let repline=null;
  if(c.reps>1 || c.repLabel){
    repline=document.createElement('div'); repline.className='repline';
    let pips=''; for(let i=0;i<c.reps;i++) pips+='<i class="pip"></i>';
    repline.innerHTML=`<span>${c.repLabel||'Clean reps'}</span><span class="pips">${pips}</span>`;
    box.appendChild(repline);
  }

  /* ----- canvas drawing ----- */
  const ctx2=canvas.getContext('2d');
  let drawing=false, last=null, drawn=0, attempts=0, repsDone=0, evaluating=false;
  function size(){
    const r=box.getBoundingClientRect();
    canvas.width=Math.round(r.width/scale); canvas.height=Math.round(r.height/scale);
    ctx2.lineCap='round'; ctx2.lineJoin='round'; ctx2.strokeStyle='#0E5B5F'; ctx2.lineWidth=12;
  }
  function pt(e){ const r=canvas.getBoundingClientRect(); return {x:(e.clientX-r.left)/scale, y:(e.clientY-r.top)/scale}; }
  function down(e){ if(evaluating) return; drawing=true; last=pt(e); try{canvas.setPointerCapture(e.pointerId);}catch(_){} }
  function move(e){ if(!drawing) return; const p=pt(e); ctx2.beginPath(); ctx2.moveTo(last.x,last.y); ctx2.lineTo(p.x,p.y); ctx2.stroke();
    drawn+=Math.hypot(p.x-last.x,p.y-last.y); last=p; }
  function up(){ if(!drawing) return; drawing=false; if(drawn>45 && !evaluating) evaluate(); }
  canvas.addEventListener('pointerdown',down);
  canvas.addEventListener('pointermove',move);
  canvas.addEventListener('pointerup',up);
  canvas.addEventListener('pointerleave',up);

  function clear(){ ctx2.clearRect(0,0,canvas.width,canvas.height); drawn=0; }
  clr.addEventListener('click',()=>{ if(evaluating)return; clear(); });

  function fillPip(){ if(repline){ const p=repline.querySelectorAll('.pip')[repsDone-1]; if(p)p.classList.add('done'); } }

  function evaluate(force){
    evaluating=true;
    if(c.firstFix && attempts===0 && !force){
      attempts++;
      setTutor('think', c.thinkText||'Let me look at your baa <span class="thinking-dots"><i></i><i></i><i></i></span>');
      setTimeout(()=>{
        setTutor('tryAgain', c.fixText, 'coral');
        setTimeout(()=>{ clear(); evaluating=false; }, 350);
      }, 750);
      return;
    }
    setTutor('think', c.thinkText||'Let me look <span class="thinking-dots"><i></i><i></i><i></i></span>');
    setTimeout(()=>{
      attempts++; repsDone++; fillPip();
      const done = repsDone>=c.reps;
      setTutor('cheer', done ? (c.praiseDone||c.praiseText) : c.praiseText, 'leaf');
      if(done){ evaluating=false; ctrl.complete=true; if(c.onComplete) c.onComplete(ctrl); }
      else { setTimeout(()=>{ clear(); evaluating=false; }, 900); }
    }, 750);
  }
  function markCorrect(){ if(evaluating||ctrl.complete) return; evaluate(true); }

  function replayDemo(reveal){
    const dp=box.querySelector('.demopath'); if(!dp) return;
    if(reveal) dp.classList.add('show');
    dp.classList.add('playing');
    dp.querySelectorAll('animate, animateMotion').forEach(a=>{ try{a.beginElement();}catch(e){} });
    const nuqta=dp.querySelector('.nuqta animate');
    setTimeout(()=>{ try{nuqta&&nuqta.beginElement();}catch(e){} }, 1500);
    setTimeout(()=>dp.classList.remove('playing'), 1750);
    if(reveal) setTimeout(()=>dp.classList.remove('show'), 2200);
  }

  const ctrl={ clear, markCorrect, replayDemo, size, complete:false, get attempts(){return attempts;} };
  box._ctrl=ctrl;
  requestAnimationFrame(()=>{ size(); if(c.demo && sub==='watch') replayDemo(false); });
  return box;
}

/* ============================ SECTIONS ============================ */
const SECTIONS = [meet, isolated, context, words, listenWrite, mastery];

/* baa's four contextual forms (ZWJ-joined) — powers the Meet morph (from Shape-Shifter) */
const ZWJ='\u200D';
const MFORMS=[
  {g:'ب',         l:'Isolated', ex:'On its own — the full bowl with its tail.',                 hint:null},
  {g:'ب'+ZWJ,     l:'Initial',  ex:'At the start — the tail goes; it reaches forward to join.', hint:'left'},
  {g:ZWJ+'ب'+ZWJ, l:'Medial',   ex:'In the middle — just a little tooth between letters.',       hint:'both'},
  {g:ZWJ+'ب',     l:'Final',    ex:'At the end — the tail comes back.',                          hint:'right'}
];
const ARROW_L=`<svg viewBox="0 0 34 20" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M32 10H4M11 4L4 10l7 6"/></svg>`;
const ARROW_R=`<svg viewBox="0 0 34 20" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M2 10h28M23 4l7 6-7 6"/></svg>`;
let meetIdx=0; const meetSeen=new Set();
function setMorph(i){
  meetIdx=i; meetSeen.add(i);
  const big=document.getElementById('mBig'); if(!big) return;
  big.classList.add('flip');
  setTimeout(()=>{ big.textContent=MFORMS[i].g; big.classList.remove('flip');
    const ex=document.getElementById('mEx'); if(ex) ex.textContent=MFORMS[i].ex; }, 150);
  document.querySelectorAll('.scrub-stop').forEach((s,j)=>{ s.classList.toggle('on',j===i); if(meetSeen.has(j)) s.classList.add('seen'); });
  applyMorphHints();
}
function applyMorphHints(){
  const h=MFORMS[meetIdx].hint, hl=document.getElementById('mHL'), hr=document.getElementById('mHR');
  if(hl) hl.classList.toggle('show', h==='left'||h==='both');
  if(hr) hr.classList.toggle('show', h==='right'||h==='both');
}

/* ---- 1 · MEET THE LETTER (new surface) ---- */
function meet(){
  showSound(true);
  setTutor('think', 'This is <b>baa</b>. It makes the sound <b>“buh”</b> — like the start of <span class="ar" dir="rtl">باب</span>. Watch how it changes shape inside a word.');
  eyebrow.textContent='Meet the Letter';
  headline.innerHTML='This is <span class="ar" dir="rtl">ب</span> — baa.';
  scene.className='scene fade-in';
  meetIdx=0; meetSeen.clear(); meetSeen.add(0);
  scene.innerHTML=`
    <div class="meet">
      <div class="morphcard">
        <div class="joinhint left" id="mHL">${ARROW_L}<span>joins on</span></div>
        <div class="joinhint right" id="mHR"><span>joins on</span>${ARROW_R}</div>
        <button class="playbtn" id="meetPlay" style="position:absolute;top:18px;right:18px;width:auto;padding:0 18px;height:46px"><span>${IC.speaker}</span>Hear</button>
        <div class="bigmorph" id="mBig" dir="rtl">${MFORMS[0].g}</div>
        <div class="morph-explain" id="mEx">${MFORMS[0].ex}</div>
      </div>
      <div class="scrub"><div class="scrub-track" id="mTrack"></div></div>
    </div>`;
  const track=scene.querySelector('#mTrack');
  MFORMS.forEach((f,i)=>{ const s=document.createElement('div'); s.className='scrub-stop'+(i===0?' on seen':'');
    s.innerHTML=`<div class="sg" dir="rtl">${f.g}</div><div class="sl">${f.l}</div>`;
    s.addEventListener('click',()=>setMorph(i)); track.appendChild(s); });
  scene.querySelector('#meetPlay').addEventListener('click',e=>ping(e.currentTarget));
  applyMorphHints();
  setActions([{spacer:true},
    {label:'Start Writing', kind:'primary', iconAfter:IC.arrow, on:()=>go(1)}]);
}

/* ---- 2 · WATCH & TRACE — isolated (reuse trace + stroke animation) ---- */
function isolated(s){
  sub = s || 'watch';
  showSound(false);
  eyebrow.textContent = sub==='watch' ? 'Watch · Stroke Order' : 'Your Turn · Trace';
  headline.innerHTML = sub==='watch' ? 'Watch me write <span class="ar" dir="rtl">ب</span>.' : 'Now you trace <span class="ar" dir="rtl">ب</span>.';
  scene.className='scene fade-in';

  if(sub==='watch'){
    setTutor('write','Watch me. I start at the gold dot, sweep down into a smooth bowl, then drop the dot underneath.');
    const wrap=document.createElement('div'); wrap.style.cssText='flex:1;display:flex;gap:18px;min-height:0';
    const w=makeWrite({guide:'path', demo:true});
    const side=document.createElement('div'); side.className='sidecol';
    side.innerHTML=`<div class="tip-card"><div class="lbl">Tip</div><div class="txt">Start at the <b>gold dot</b>. Follow the curve down and to the left, then place the <b>dot below</b>.</div></div>`;
    wrap.appendChild(w); wrap.appendChild(side);
    scene.innerHTML=''; scene.appendChild(wrap);
    setActions([
      {label:'Watch again', kind:'quiet', icon:IC.replay, on:()=>w._ctrl.replayDemo(false)},
      {spacer:true},
      {label:"I'll Try", kind:'primary', iconAfter:IC.arrow, on:()=>isolated('trace')}]);
  } else {
    setTutor('idle','Take your time. Start at the gold dot and follow the bowl. Lift your pen when you reach the end.');
    const wrap=document.createElement('div'); wrap.style.cssText='flex:1;display:flex;gap:18px;min-height:0';
    const w=makeWrite({guide:'path', demo:true, corner:true, reps:2, repLabel:'Clean reps',
      fixText:'Your baa is a little shallow — start higher and give it a <b>deeper curve</b> at the bottom. Try again, slower this time.',
      praiseText:'Lovely — a nice deep bowl. Once more so it’s in your hand.',
      praiseDone:'Beautiful — smooth and deep, dot right below. <span class="ar" dir="rtl">أحسنت!</span>',
      firstFix:true,
      onComplete:()=>{ $('nextIso').disabled=false; }});
    const side=document.createElement('div'); side.className='sidecol';
    side.innerHTML=`<div class="listen-card"><div class="lbl">Listen</div><div class="big" dir="rtl">ب</div><div class="rom">baa</div>
      <button class="playbtn" id="traceListen"><span>${IC.speaker}</span>Play sound</button></div>`;
    wrap.appendChild(w); wrap.appendChild(side);
    scene.innerHTML=''; scene.appendChild(wrap);
    side.querySelector('#traceListen').addEventListener('click',e=>ping(e.currentTarget));
    setActions([
      {label:'Try again', kind:'quiet', on:()=>w._ctrl.clear()},
      {label:'Mark correct', kind:'ghost', icon:IC.check, on:()=>w._ctrl.markCorrect()},
      {spacer:true},
      {label:'Next', kind:'primary', id:'nextIso', disabled:true, iconAfter:IC.arrow, on:()=>go(2)}]);
  }
}

/* ---- 3 · IN-CONTEXT FORMS (new framing, reuse trace) ---- */
function context(){
  showSound(false);
  setTutor('write','At the <b>start</b> of a word baa drops its tail. In the <b>middle</b> it’s just a little tooth. At the <b>end</b>, the tail comes back. Trace each one.');
  eyebrow.textContent='Forms in Context';
  headline.innerHTML='Baa changes inside a word.';
  scene.className='scene fade-in';

  const steps=[
    {key:'initial', g:'بـ', l:'Initial'},
    {key:'medial',  g:'ـبـ',l:'Medial'},
    {key:'final',   g:'ـب', l:'Final'}
  ];
  const doneForms=new Set();
  let stage='forms'; // 'forms' -> 'word'

  const root=document.createElement('div'); root.style.cssText='flex:1;display:flex;flex-direction:column;min-height:0';
  const stepRow=document.createElement('div'); stepRow.className='formsteps';
  const area=document.createElement('div'); area.style.cssText='flex:1;display:flex;gap:18px;min-height:0';
  root.appendChild(stepRow); root.appendChild(area);
  scene.innerHTML=''; scene.appendChild(root);

  let active=0;
  function renderSteps(){
    stepRow.innerHTML='';
    steps.forEach((st,i)=>{
      const el=document.createElement('div');
      el.className='fstep'+(i===active&&stage==='forms'?' active':'')+(doneForms.has(st.key)?' done':'');
      el.innerHTML=`<div class="sg" dir="rtl">${st.g}</div><div class="sl">${doneForms.has(st.key)?'✓ '+st.l:st.l}</div>`;
      el.addEventListener('click',()=>{ if(stage==='forms'){ active=i; loadForm(); } });
      stepRow.appendChild(el);
    });
  }
  function loadForm(){
    renderSteps();
    const st=steps[active];
    setTutor('idle', `Trace the <b>${st.l.toLowerCase()}</b> baa — <span class="ar" dir="rtl">${st.g}</span>.`);
    const w=makeWrite({guide:'glyph', glyph:`<span dir="rtl">${st.g}</span>`, glyphSize:150, corner:false, reps:1,
      praiseText:'Nice — that’s the shape.', praiseDone:'Nice — that’s the shape.',
      onComplete:()=>{ doneForms.add(st.key); renderSteps();
        if(doneForms.size===steps.length){ toWord(); }
        else { // advance to next undone
          const nx=steps.findIndex(s=>!doneForms.has(s.key)); if(nx>=0){ active=nx; setTimeout(loadForm,500); } }
      }});
    const side=document.createElement('div'); side.className='sidecol';
    side.innerHTML=`<div class="listen-card"><div class="lbl">This form</div><div class="big" dir="rtl">${st.g}</div><div class="rom">${st.l}</div>
      <button class="playbtn"><span>${IC.speaker}</span>Hear it</button></div>`;
    area.innerHTML=''; area.appendChild(w); area.appendChild(side);
    side.querySelector('.playbtn').addEventListener('click',e=>ping(e.currentTarget));
    setActions([{hint:'Trace over the faint letter.'},{spacer:true},
      {label:'Next', kind:'primary', id:'nextCtx', disabled:true, iconAfter:IC.arrow, on:()=>go(3)}]);
  }
  function toWord(){
    stage='word'; renderSteps();
    setTutor('write','Now <b>join them</b>. Keep your pen down and write <span class="ar" dir="rtl">باب</span> — “door” — all in one go.');
    headline.innerHTML='Join them — write <span class="ar" dir="rtl">باب</span>.';
    const w=makeWrite({guide:'glyph', glyph:`<span dir="rtl">باب</span>`, glyphSize:140, corner:false, reps:1,
      fixText:'Don’t lift between the letters — let baa <b>reach across</b> to join. Try once more.',
      firstFix:true,
      praiseDone:'You joined it! That’s a whole word in your hand. <span class="ar" dir="rtl">أحسنت!</span>',
      onComplete:()=>{ $('nextCtx').disabled=false; }});
    const side=document.createElement('div'); side.className='sidecol';
    side.innerHTML=`<div class="listen-card"><div class="lbl">Listen</div><div class="big" dir="rtl" style="font-size:54px">باب</div><div class="rom">baab · door</div>
      <button class="playbtn"><span>${IC.speaker}</span>Play word</button></div>`;
    area.innerHTML=''; area.appendChild(w); area.appendChild(side);
    side.querySelector('.playbtn').addEventListener('click',e=>ping(e.currentTarget));
    setActions([{label:'Try again', kind:'quiet', on:()=>w._ctrl.clear()},{spacer:true},
      {label:'Next', kind:'primary', id:'nextCtx', disabled:true, iconAfter:IC.arrow, on:()=>go(3)}]);
  }
  renderSteps(); loadForm();
}

/* ---- 4 · WORDS (new surface) ---- */
const WORDS=[
  {ar:'باب', html:'<span class="baa">ب</span>ا<span class="baa">ب</span>', rom:'baab', en:'door', pic:'illustration: door'},
  {ar:'بطة', html:'<span class="baa">ب</span>طة', rom:'batta', en:'duck', pic:'illustration: duck'},
  {ar:'حليب', html:'حلي<span class="baa">ب</span>', rom:'haliib', en:'milk', pic:'illustration: milk'}
];
function words(){
  showSound(false);
  setTutor('idle','Here are three words that use <b>baa</b>. Tap a card to hear it, then trace the whole word.');
  eyebrow.textContent='Words with Baa';
  headline.innerHTML='Baa does real work.';
  scene.className='scene fade-in';
  const done=new Set();

  function grid(){
    setTutor('idle','Here are three words that use <b>baa</b>. Tap a card to hear it, then trace the whole word.');
    headline.innerHTML='Baa does real work.';
    const root=document.createElement('div'); root.className='words';
    root.innerHTML=`<div class="tbd"><span class="d"></span>Vocab words — to confirm with curriculum</div>`;
    const g=document.createElement('div'); g.className='wordgrid';
    WORDS.forEach((w,i)=>{
      const card=document.createElement('div'); card.className='wordcard';
      card.innerHTML=`<div class="pic"><span>${w.pic}</span></div>
        <div class="wd" dir="rtl">${w.html}</div>
        <div class="meta"><div><div class="rom">${w.rom}</div><div class="en">${w.en}</div></div>
        <button class="play" aria-label="Play">${IC.speaker}</button></div>
        <div class="trace-tag">${done.has(i)?IC.check+' Traced':IC.arrow+' Tap to trace'}</div>`;
      card.querySelector('.play').addEventListener('click',e=>{e.stopPropagation();ping(e.currentTarget);});
      card.addEventListener('click',()=>traceWord(i));
      g.appendChild(card);
    });
    root.appendChild(g);
    scene.className='scene fade-in'; scene.innerHTML=''; scene.appendChild(root);
    setActions([{hint:'Trace at least one word to go on.'},{spacer:true},
      {label:'Next', kind:'primary', disabled:done.size===0, iconAfter:IC.arrow, on:()=>go(4)}]);
  }
  function traceWord(i){
    const w=WORDS[i];
    setTutor('write',`Trace <span class="ar" dir="rtl">${w.ar}</span> — “${w.en}”. Watch the <b>baa</b> in teal.`);
    headline.innerHTML=`Trace <span class="ar" dir="rtl">${w.ar}</span>.`;
    const wrap=document.createElement('div'); wrap.style.cssText='flex:1;display:flex;gap:18px;min-height:0';
    const surf=makeWrite({guide:'glyph', glyph:`<span dir="rtl">${w.html}</span>`, glyphSize:130, reps:1,
      praiseDone:'Beautiful — you wrote a whole word. <span class="ar" dir="rtl">أحسنت!</span>',
      onComplete:()=>{ done.add(i); setTimeout(grid, 1100); }});
    const side=document.createElement('div'); side.className='sidecol';
    side.innerHTML=`<div class="listen-card"><div class="lbl">Listen</div><div class="big" dir="rtl" style="font-size:48px">${w.ar}</div><div class="rom">${w.rom} · ${w.en}</div>
      <button class="playbtn"><span>${IC.speaker}</span>Play word</button></div>
      <div class="pic" style="border-radius:18px;min-height:120px;background:repeating-linear-gradient(135deg,#EAF4F4,#EAF4F4 9px,#E2EFEF 9px,#E2EFEF 18px);border:1px solid #D6E8E8;display:flex;align-items:center;justify-content:center"><span style="font-family:'JetBrains Mono',monospace;font-size:11px;color:#5C6B70;background:rgba(255,255,255,.82);padding:4px 9px;border-radius:7px">${w.pic}</span></div>`;
    wrap.appendChild(surf); wrap.appendChild(side);
    scene.className='scene fade-in'; scene.innerHTML=''; scene.appendChild(wrap);
    side.querySelector('.playbtn').addEventListener('click',e=>ping(e.currentTarget));
    setActions([{label:'Back to words', kind:'quiet', on:grid},{label:'Clear', kind:'quiet', on:()=>surf._ctrl.clear()},{spacer:true},
      {label:'Next', kind:'primary', disabled:done.size===0, iconAfter:IC.arrow, on:()=>go(4)}]);
  }
  grid();
}

/* ---- 5 · LISTEN & WRITE (new surface — recall gate) ---- */
function listenWrite(){
  showSound(false);
  setTutor('think','No dotted lines this time. <b>Listen</b>, then write it yourself — this is how I know you really learned it.');
  eyebrow.textContent='Listen & Write';
  headline.innerHTML='Now write what you hear.';
  scene.className='scene fade-in';
  let mode='word'; const done=new Set();

  const root=document.createElement('div'); root.className='lw';
  const left=document.createElement('div'); left.className='lw-prompt';
  const right=document.createElement('div'); right.style.cssText='flex:1;display:flex;min-height:0';
  root.appendChild(left); root.appendChild(right);
  scene.innerHTML=''; scene.appendChild(root);

  function build(){
    const isWord = mode==='word';
    left.innerHTML=`
      <div class="lw-sub">
        <button class="b${isWord?' active':''}" data-m="word">Write the word</button>
        <button class="b${!isWord?' active':''}" data-m="letter">First letter</button>
      </div>
      <div class="lw-card">
        <div class="task">${isWord?'Listen, then write the whole word.':'Listen. Write the letter the word <b>starts</b> with.'}</div>
        <div class="sub">${isWord?'Dictation — from memory, no guide.':'Phonological awareness — hear → first letter.'}</div>
        <button class="bigplay">${IC.speaker}<span>${isWord?'Play “baab”':'Play “batta”'}</span></button>
      </div>`;
    left.querySelectorAll('.lw-sub .b').forEach(b=>b.addEventListener('click',()=>{ mode=b.dataset.m; build(); }));
    left.querySelector('.bigplay').addEventListener('click',e=>ping(e.currentTarget,true));

    const surf=makeWrite({guide:'baseline', reps:1,
      thinkText:'Let me read what you wrote <span class="thinking-dots"><i></i><i></i><i></i></span>',
      fixText: isWord
        ? 'Close! Your first <b>baa</b> needs its dot below. Listen once more — <span class="ar" dir="rtl">باب</span> — and write it again.'
        : 'That’s the right idea — make the <b>bowl</b> a little deeper. Listen again and try once more.',
      firstFix:true,
      praiseDone: isWord
        ? 'You wrote <span class="ar" dir="rtl">باب</span> from memory — no guide. That’s real writing. <span class="ar" dir="rtl">أحسنت!</span>'
        : 'Yes — “batta” starts with <b>baa</b>, and there it is.',
      onComplete:()=>{ done.add(mode); refreshNext(); }});
    right.innerHTML=''; right.appendChild(surf);
  }
  function refreshNext(){ const n=$('nextLW'); if(n) n.disabled=!done.has('word'); }
  build();
  setActions([{hint:'Write the word from memory to finish.'},{spacer:true},
    {label:'Finish lesson', kind:'primary', id:'nextLW', disabled:true, iconAfter:IC.arrow, on:()=>go(5)}]);
}

/* ---- 6 · MASTERY (matched celebration · ONE quiet star, no totals) ---- */
function mastery(){
  showSound(false);
  setTutor('cheer','You can write <b>baa</b> on your own now — start, middle, and end. I’m proud of you. <span class="ar" dir="rtl">أحسنت.</span>','leaf');
  eyebrow.textContent='Mastered';
  headline.innerHTML='You learned the letter <span class="ar" dir="rtl">ب</span> — baa.';
  scene.className='scene fade-in';
  scene.innerHTML=`<div class="mastery">
      <div class="glow"></div>
      <div class="mastery-inner">
        <div class="star-big pop">${STAR(150)}</div>
        <div class="said">One quiet star — because you truly write <span class="ar" dir="rtl">باب</span> now.<br>A milestone, not a score.</div>
      </div>
    </div>`;
  // gentle gold sparks (reward moment — gold is allowed here)
  const inner=scene.querySelector('.mastery-inner');
  const angles=[[-150,-90],[150,-80],[-170,40],[170,50],[-60,-150],[70,-150]];
  angles.forEach((a,i)=>{ const s=document.createElement('div'); s.className='spark';
    s.style.left='50%'; s.style.top='34%'; s.style.setProperty('--to',`translate(${a[0]}px,${a[1]}px)`);
    inner.appendChild(s); setTimeout(()=>s.classList.add('go'), 280+i*70); });
  setActions([
    {label:'See journey', kind:'ghost', icon:IC.map, on:()=>{}},
    {spacer:true},
    {label:'Next letter', kind:'primary', iconAfter:IC.arrow, on:()=>go(0)}]);
}

/* ============================ NAV ============================ */
function go(n, s){
  cur=Math.max(0,Math.min(TOTAL-1,n)); sub=s||null; visited.add(cur);
  buildRibbon();
  scene.scrollTop=0;
  SECTIONS[cur](sub);
  $('backBtn').style.visibility = (cur===0 && !sub) ? 'hidden' : 'visible';
}
$('backBtn').addEventListener('click',()=>{
  if(cur===1 && sub==='trace'){ isolated('watch'); return; }
  if(cur>0) go(cur-1);
});
$('closeBtn').addEventListener('click',()=>{ if(confirm('Leave the lesson? Your place is saved.')) go(0); });
$('soundHear').addEventListener('click',e=>ping(e.currentTarget));

/* tiny audio-feedback affordance (visual ping; real audio is a placeholder) */
function ping(btn, big){
  btn.classList.remove('ping'); void btn.offsetWidth; btn.classList.add('ping');
}

/* ============================ FIT ============================ */
function fit(){
  const pad=44;
  scale=Math.min((innerWidth-pad)/1280,(innerHeight-pad)/800,1);
  document.querySelector('.stage').style.transform='scale('+scale+')';
  // keep any live canvas crisp after a resize
  document.querySelectorAll('.writebox').forEach(b=>{ if(b._ctrl) b._ctrl.size(); });
}
addEventListener('resize',fit);
fit(); go(0);
