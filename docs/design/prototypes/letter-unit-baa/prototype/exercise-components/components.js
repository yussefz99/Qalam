/* =========================================================================
   Qalam — Exercise Component System : the 5 reusable components
   Every question type is CONFIG fed into these. No per-type screens.
   Depends on window.Q (shared/core.js): M, STAR, IC, makeWrite, ping.
   ========================================================================= */
(function(){
const { STAR, IC } = window.Q;
const X_ICON=`<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6L6 18M6 6l12 12"/></svg>`;

/* form glyph helper — contextual forms of a base letter (baa shown) */
const FORMS={isolated:'ب', initial:'بـ', medial:'ـبـ', final:'ـب'};
function formGlyph(f){ return FORMS[f||'isolated']||'ب'; }

/* ---------- PromptHeader : renders an ordered list of PromptParts ---------- *
   parts: [{type:'say',line}, {type:'audio',label}, {type:'image',imageId,caption},
           {type:'text',text,gaps,variant}, {type:'rule',label,labelAr}]
   `say` is pulled out for the mascot; the rest render as the header row.        */
function PromptHeader(parts){
  parts = parts||[];
  let say='';
  const el=document.createElement('div'); el.className='prompt-header';
  const visuals=parts.filter(p=>{ if(p.type==='say'){ say=p.line; return false; } return true; });
  visuals.forEach(p=> el.appendChild(renderPart(p)) );
  if(!visuals.length) el.classList.add('empty');
  el.querySelectorAll('.pp-audio').forEach(b=>b.addEventListener('click',e=>Q.ping(e.currentTarget)));
  return { el, say, count:visuals.length };
}
function renderPart(p){
  const c=document.createElement('div'); c.className='ppart ppart-'+p.type;
  if(p.type==='audio'){
    c.innerHTML=`<button class="pp-audio"><span class="pp-ico">${IC.speaker}</span><span class="pp-lab">${p.label||'Play'}</span></button>`;
  } else if(p.type==='image'){
    c.innerHTML=`<div class="pp-img"><span>${p.imageId||'illustration'}</span></div>`+(p.caption?`<div class="pp-cap">${p.caption}</div>`:'');
  } else if(p.type==='text'){
    c.innerHTML=`<div class="pp-text ${p.variant||''}" dir="rtl">${renderText(p)}</div>`;
  } else if(p.type==='rule'){
    c.innerHTML=`<div class="pp-rule"><span class="pp-rule-ar" dir="rtl">${p.labelAr||''}</span><span class="pp-rule-en">${p.label||''}</span></div>`;
  }
  return c;
}
function renderText(p){
  let t=p.text||'';
  t=t.replace(/__blank__/g,'<span class="gap-word">▢</span>');
  t=t.replace(/_letter_/g,'<span class="gap-letter">◌</span>');
  if(p.hidden) t=`<span class="hidden-word">${t}</span>`;
  return t;
}

/* ---------- WriteSurface : the ONE canvas (trace|write × glyph|word|sentence) ----------
   surface: { mode:'trace'|'write', unit:'glyph'|'word'|'sentence',
              given?:{word|letters, blankIndex}, guideForm?, guideGlyph?,
              demo?, corner?, reps?, ghost?, firstFix? }
   feedback: { pass, fix }   hooks: { setTutor, onPass }                              */
function WriteSurface(surface, feedback, hooks){
  surface=surface||{}; feedback=feedback||{}; hooks=hooks||{};
  const mode=surface.mode||'write', unit=surface.unit||'glyph';
  let guide='baseline', glyph, glyphSize;
  if(mode==='trace'){
    if((surface.guideForm||'isolated')==='isolated' && unit==='glyph' && !surface.guideGlyph){ guide='path'; }
    else { guide='glyph'; glyph='<span dir="rtl">'+(surface.guideGlyph||formGlyph(surface.guideForm))+'</span>'; glyphSize=unit==='glyph'?150:130; }
  }
  const cfg={
    guide, glyph, glyphSize,
    demo: surface.demo!==undefined?surface.demo:(guide==='path'),
    corner: !!surface.corner,
    reps: surface.reps||1,
    repLabel: surface.repLabel,
    firstFix: surface.firstFix!==false,
    ghost: !!surface.ghost,
    fixText: feedback.fix,
    praiseText: feedback.pass,
    praiseDone: feedback.pass,
    thinkText: surface.thinkText,
    setTutor: hooks.setTutor||function(){},
    onComplete: ()=>hooks.onPass&&hooks.onPass()
  };
  const box=Q.makeWrite(cfg);
  if(unit==='word') box.classList.add('u-word');
  if(unit==='sentence') box.classList.add('u-sentence');

  // surface mode tag
  const tag=document.createElement('div'); tag.className='surface-tag';
  tag.innerHTML=`<span class="sd"></span>${mode==='trace'?'Trace · over the guide':'Write · '+unit+' · no guide'}`;
  box.appendChild(tag);

  // given ink (letters the child does NOT write — e.g. complete-the-word)
  if(surface.given){
    const o=document.createElement('div'); o.className='given-ink'; o.dir='rtl';
    const letters=surface.given.letters || (surface.given.word? surface.given.word.split(''):[]);
    letters.forEach((ch,i)=>{ const cell=document.createElement('span');
      if(i===surface.given.blankIndex){ cell.className='gv-blank'; } else { cell.className='gv-letter'; cell.textContent=ch; }
      o.appendChild(cell); });
    box.appendChild(o);
  }
  return { el:box, ctrl:box._ctrl };
}

/* ---------- FeedbackPanel : two states, shared by all types ---------- */
function FeedbackPanel(){
  const el=document.createElement('div'); el.className='feedback-panel';
  function show(state,data){
    data=data||{};
    if(state==='fix'){
      el.className='feedback-panel fix';
      el.innerHTML=`<div class="fb-ico">${X_ICON}</div><div class="fb-body"><div class="fb-tag">A specific fix</div><div class="fb-line">${data.line||''}</div></div>`;
    } else if(state==='pass'){
      el.className='feedback-panel pass';
      el.innerHTML=`<div class="fb-star">${STAR(44)}</div><div class="fb-body"><div class="fb-tag">Correct · one quiet star</div><div class="fb-line">${data.line||''}</div></div>`;
    } else {
      el.className='feedback-panel';
      el.innerHTML=`<div class="fb-hint"><span class="pen"></span>${data.hint||'Write on the surface — Qalam checks your strokes.'}</div>`;
    }
  }
  return { el, show };
}

/* ---------- ProgressRibbon : R→L position dots (position, not score) ---------- */
function ProgressRibbon(total,active){
  const el=document.createElement('div'); el.className='progress-ribbon';
  for(let i=0;i<total;i++){ const d=document.createElement('span'); d.className='pr-dot'+(i<active?' done':'')+(i===active?' active':''); el.appendChild(d); }
  return { el };
}

/* ---------- ExerciseScaffold : the page that hosts every exercise ----------
   Builds the RTL landscape shell and exposes load(config) + showState().      */
function ExerciseScaffold(host){
  host.classList.add('ex-scaffold');
  host.innerHTML=`
    <aside class="ex-tutor">
      <div class="ex-mascot" data-mascot></div>
      <div class="ex-tid"><div class="nm">Qalam</div><div class="role">Your Writing Tutor</div></div>
      <div class="ex-speech" data-speech></div>
      <div data-tutorslot></div>
    </aside>
    <main class="ex-main">
      <div class="ex-ribbonrow"><div class="ex-kick" data-kick></div><div data-ribbon></div></div>
      <div data-prompt></div>
      <div class="ex-surface" data-surface></div>
      <div class="ex-foot"><div data-feedback></div><div class="ex-cta" data-cta></div></div>
    </main>`;
  const mascotEl=host.querySelector('[data-mascot]'), speechEl=host.querySelector('[data-speech]'),
        kickEl=host.querySelector('[data-kick]'), ribbonSlot=host.querySelector('[data-ribbon]'),
        promptSlot=host.querySelector('[data-prompt]'), surfaceSlot=host.querySelector('[data-surface]'),
        footFb=host.querySelector('[data-feedback]'), ctaSlot=host.querySelector('[data-cta]'),
        tutorSlot=host.querySelector('[data-tutorslot]');

  let fb=FeedbackPanel(); footFb.appendChild(fb.el);
  let cur=null, ctrl=null;

  function setMascot(pose,html,tone){
    mascotEl.innerHTML=Q.M[pose]||Q.M.idle;
    speechEl.className='ex-speech'+(tone?(' '+tone):'');
    speechEl.innerHTML=(tone?'<span class="tone">Qalam says</span>':'')+html;
  }
  // wrapped tutor setter — also drives FeedbackPanel from validator tone
  function tutorAndFeedback(pose,html,tone){
    setMascot(pose,html,tone);
    if(tone==='coral'){ fb.show('fix',{line:html}); ctaFor('fix'); }
    else if(tone==='leaf'){ fb.show('pass',{line:html}); ctaFor('pass'); }
  }
  function ctaFor(state){
    ctaSlot.innerHTML='';
    if(state==='pass'){ addBtn('Next exercise','primary',IC.arrow,()=>cur&&cur.onNext&&cur.onNext()); }
    else if(state==='fix'){ addBtn('Clear','quiet',null,()=>ctrl&&ctrl.clear()); addBtn('Try again','primary',null,()=>{ ctrl&&ctrl.clear(); resetPrompt(); }); }
    else { addBtn('Clear','quiet',null,()=>ctrl&&ctrl.clear()); addBtn('Mark correct','primary',IC.check,()=>ctrl&&ctrl.markCorrect()); }
  }
  function addBtn(label,kind,icon,on){ const b=document.createElement('button'); b.className='exbtn '+kind;
    b.innerHTML=(icon||'')+`<span>${label}</span>`; b.addEventListener('click',on); ctaSlot.appendChild(b); }
  function resetPrompt(){ if(!cur)return; setMascot(cur.pose||'idle', cur._say||''); fb.show('prompt',{hint:cur.hint}); ctaFor('prompt'); }

  function load(config){
    cur=config; ctrl=null;
    kickEl.innerHTML=config.kick||'';
    // ProgressRibbon
    ribbonSlot.innerHTML=''; if(config.ribbon){ ribbonSlot.appendChild(ProgressRibbon(config.ribbon.total,config.ribbon.active).el); }
    // PromptHeader
    const ph=PromptHeader(config.prompt); cur._say=ph.say;
    promptSlot.innerHTML=''; promptSlot.appendChild(ph.el);
    // WriteSurface (or none, for teach card)
    surfaceSlot.innerHTML='';
    if(config.surface){
      const ws=WriteSurface(config.surface, config.feedback, { setTutor:tutorAndFeedback, onPass:()=>{} });
      surfaceSlot.appendChild(ws.el); ctrl=ws.ctrl;
    } else if(config.customSurface){
      surfaceSlot.appendChild(config.customSurface());
    }
    // tutor slot extra (e.g. support note / spec)
    tutorSlot.innerHTML=''; if(config.tutorExtra){ tutorSlot.appendChild(config.tutorExtra()); }
    // initial state
    setMascot(config.pose||'idle', ph.say||'');
    if(config.surface){ fb.show('prompt',{hint:config.hint}); ctaFor('prompt'); }
    else { fb.show('prompt',{hint:config.hint||'Nothing to write — this card teaches.'}); ctaSlot.innerHTML=''; if(config.supportCta){ addBtn(config.supportCta,'primary',null,()=>cur&&cur.onNext&&cur.onNext()); } }
  }
  // preview switch for the gallery (no drawing needed)
  function showState(state){
    if(!cur) return;
    if(state==='prompt') resetPrompt();
    else if(state==='fix') tutorAndFeedback('tryAgain', (cur.feedback&&cur.feedback.fix)||'Not quite — try again, slower.', 'coral');
    else if(state==='pass'){ tutorAndFeedback('cheer', (cur.feedback&&cur.feedback.pass)||'Beautiful!', 'leaf');
      const pip=surfaceSlot.querySelector('.pip:not(.done)'); if(pip) pip.classList.add('done'); }
  }
  return { load, showState, setMascot, get ctrl(){return ctrl;} };
}

window.QC = { ExerciseScaffold, PromptHeader, WriteSurface, FeedbackPanel, ProgressRibbon, formGlyph };
})();
