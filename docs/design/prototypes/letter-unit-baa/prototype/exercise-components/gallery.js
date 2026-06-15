/* Qalam — Exercise gallery. Every question type is a CONFIG swapped into the
   same 5 components. Modality (hear/see/read) is a prompt-part variant. */
const scaffold = QC.ExerciseScaffold(document.getElementById('exHost'));
const pager=document.getElementById('pager'), controls=document.getElementById('controls'),
      tbdrow=document.getElementById('tbdrow'), inspector=document.getElementById('inspector'),
      compMap=document.getElementById('compMap'), cfgJson=document.getElementById('cfgJson'),
      cfgNote=document.getElementById('cfgNote');
document.getElementById('back').addEventListener('click',()=>history.length>1?history.back():null);
const GTBD='Which types &amp; how many per letter — <b>TBD</b>';
const say=l=>({type:'say',line:l}), aud=l=>({type:'audio',label:l}),
      img=(i,c)=>({type:'image',imageId:i,caption:c}), txt=(t,o)=>Object.assign({type:'text',text:t},o||{}),
      rule=(l,a)=>({type:'rule',label:l,labelAr:a});

const TYPES=[
{ key:'traceLetter', tab:'Trace', n:1, skill:'formation', pose:'idle',
  note:'A faint guide + the geometric stroke scorer — the only type on the trace canvas. Positional <b>form</b> is just <code>surface.guideForm</code>; no new screen per form.',
  tbd:['Clean reps to pass — <b>count TBD</b>'],
  variants:[
   {label:'Isolated',va:'ب',kick:'Q1 · traceLetter',prompt:[say('Start at the gold dot and sweep a <b>deep bowl</b>, then the dot below.'),aud('Hear “baa”')],
    surface:{mode:'trace',unit:'glyph',guideForm:'isolated',demo:true,corner:true},expected:{glyph:{char:'ب',form:'isolated'}},check:'glyph',
    feedback:{fix:'A little shallow — give the bowl a <b>deeper</b> curve. Try again, slower.',pass:'Beautiful — that’s baa. <span class="ar" dir="rtl">أحسنت!</span>'}},
   {label:'Initial',va:'بـ',kick:'Q1 · traceLetter',prompt:[say('Trace the <b>initial</b> baa — no tail, it reaches forward to join.'),rule('Initial form','أوّل')],
    surface:{mode:'trace',unit:'glyph',guideForm:'initial'},expected:{glyph:{char:'ب',form:'initial'}},check:'glyph + positionalForm',
    feedback:{fix:'No tail at the start — keep it small and flat. Try once more.',pass:'That’s the initial shape — ready to join.'}},
   {label:'Medial',va:'ـبـ',kick:'Q1 · traceLetter',prompt:[say('Trace the <b>medial</b> baa — a little tooth between two letters.'),rule('Medial form','وسط')],
    surface:{mode:'trace',unit:'glyph',guideForm:'medial'},expected:{glyph:{char:'ب',form:'medial'}},check:'glyph + positionalForm',
    feedback:{fix:'Smaller — a little tooth, no tail. Try again.',pass:'Perfect little tooth — the medial baa.'}}
  ]},

{ key:'writeLetter', tab:'Write letter', n:2, skill:'recall', pose:'think',
  note:'Merges write-from-sound, write-from-picture &amp; produce-form. Only the prompt PART changes (audio / image / rule) — the blank surface &amp; glyph validator stay identical.',
  tbd:['Which vocab &amp; pictures per letter — <b>TBD</b>'],
  variants:[
   {label:'Hear → letter',kick:'Q2 · writeLetter',prompt:[say('Listen, then write the letter the word <b>starts</b> with. No guide.'),aud('Play the word')],
    surface:{mode:'write',unit:'glyph',thinkText:'Let me see which letter you wrote <span class="thinking-dots"><i></i><i></i><i></i></span>'},expected:{glyph:{char:'ب'}},check:'glyph + positionalForm',
    feedback:{fix:'That’s <b>taa</b> — listen again: <span class="ar" dir="rtl">بطة</span>… <b>b, b</b>. Which letter makes that sound?',pass:'Yes — “baṭṭa” starts with <b>baa</b>, and there it is.'}},
   {label:'Picture → letter',kick:'Q2 · writeLetter',prompt:[say('Look at the picture. Write the letter the word <b>begins</b> with.'),img('duck (baṭṭa)','what does it start with?')],
    surface:{mode:'write',unit:'glyph'},expected:{glyph:{char:'ب'}},check:'glyph',
    feedback:{fix:'Make the <b>bowl deeper</b> with the dot below — that’s baa.',pass:'That’s it — “baṭṭa” (duck) starts with baa.'}},
   {label:'Write the form',va:'بـ',kick:'Q2 · writeLetter',prompt:[say('Write baa the way it looks at the <b>start</b> of a word.'),rule('Initial form','أوّل')],
    surface:{mode:'write',unit:'glyph'},expected:{glyph:{char:'ب',form:'initial'}},check:'glyph + positionalForm',
    feedback:{fix:'At the start, baa has <b>no tail</b> and reaches forward. Try again.',pass:'That’s the initial baa — from memory.'}}
  ]},

{ key:'writeWord', tab:'Write word', n:3, skill:'spelling', pose:'think',
  note:'Dictation (إملاء), copy (نسخ) &amp; picture→word are one type. Surface = write·word; validator = sequence (glyph scorer per letter, in order).',
  tbd:['Clean reps to pass — <b>count TBD</b>'],
  variants:[
   {label:'Hear it',va:'إملاء',kick:'Q3 · writeWord',prompt:[say('No dotted lines. Listen and write the <b>whole word</b> from memory.'),aud('Play “baab”')],
    surface:{mode:'write',unit:'word',thinkText:'Let me read what you wrote <span class="thinking-dots"><i></i><i></i><i></i></span>'},expected:{word:'باب'},check:'sequence',
    feedback:{fix:'Close — your first baa needs its dot. Listen again: <span class="ar" dir="rtl">باب</span>.',pass:'<span class="ar" dir="rtl">باب</span> — from memory, no guide. Real writing! <span class="ar" dir="rtl">أحسنت!</span>'}},
   {label:'Copy',va:'نسخ',kick:'Q3 · writeWord',prompt:[say('You saw the word for a moment — now write it from memory.'),txt('باب',{hidden:true,variant:'small'})],
    surface:{mode:'write',unit:'word'},expected:{word:'باب'},check:'sequence',
    feedback:{fix:'Almost — check the second baa’s dot. Try once more.',pass:'You remembered it — <span class="ar" dir="rtl">باب</span>. <span class="ar" dir="rtl">أحسنت!</span>'}},
   {label:'Picture',kick:'Q3 · writeWord',prompt:[say('Look at the picture and write the whole word for it.'),img('door (baab)')],
    surface:{mode:'write',unit:'word'},expected:{word:'باب'},check:'sequence',
    feedback:{fix:'That’s the right start — finish the whole word, <span class="ar" dir="rtl">باب</span>.',pass:'<span class="ar" dir="rtl">باب</span> — “door.” Beautiful.'}}
  ]},

{ key:'connectWord', tab:'Connect', n:4, skill:'spelling', pose:'write',
  note:'The joining skill. Loose letters shown as a text prompt; validator adds joinContinuity + positionalForm on top of sequence.',
  tbd:[],
  variants:[
   {label:'باب',kick:'Q4 · connectWord',prompt:[say('Here are the letters apart. Write them <b>joined</b> — keep your pen down across the word.'),txt('ب  ا  ب',{variant:'loose'})],
    surface:{mode:'write',unit:'word',ghost:true},expected:{word:'باب'},check:'sequence + joinContinuity',
    feedback:{fix:'Don’t lift between the letters — let baa <b>reach across</b> to join.',pass:'Joined in one go — <span class="ar" dir="rtl">باب</span>, “door.” <span class="ar" dir="rtl">أحسنت!</span>'}},
   {label:'كتاب',kick:'Q4 · connectWord',prompt:[say('Join these into one word — watch baa take its <b>final</b> shape at the end.'),txt('ك  ت  ا  ب',{variant:'loose'})],
    surface:{mode:'write',unit:'word',ghost:true},expected:{word:'كتاب'},check:'sequence + joinContinuity',
    feedback:{fix:'Keep the run connected — let baa’s tail return at the <b>end</b>.',pass:'<span class="ar" dir="rtl">كتاب</span> — “book,” joined. <span class="ar" dir="rtl">أحسنت!</span>'}}
  ]},

{ key:'transformWord', tab:'Transform', n:5, skill:'grammar', pose:'think',
  note:'NEW grammar type. A <code>rule</code> prompt-part (مثنى/جمع/عكس) + the base word; validator = sequence with a transformRule modifier. No new components.',
  tbd:['Grammar scope &amp; answer words per letter — <b>TBD</b>'],
  variants:[
   {label:'Dual',va:'مثنى',kick:'Q5 · transformWord',prompt:[say('One becomes two. Write the <b>dual</b> of <span class="ar" dir="rtl">باب</span>.'),rule('Dual','مثنى'),txt('باب',{variant:'small'})],
    surface:{mode:'write',unit:'word'},expected:{word:'بابان'},check:'sequence + transformRule',
    feedback:{fix:'Add the dual ending <span class="ar" dir="rtl">ـان</span>: <span class="ar" dir="rtl">بابان</span>.',pass:'<span class="ar" dir="rtl">بابان</span> — two doors. <span class="ar" dir="rtl">أحسنت!</span>'}},
   {label:'Plural',va:'جمع',kick:'Q5 · transformWord',prompt:[say('One becomes many. Write the <b>plural</b> of <span class="ar" dir="rtl">باب</span>.'),rule('Plural','جمع'),txt('باب',{variant:'small'})],
    surface:{mode:'write',unit:'word'},expected:{word:'أبواب'},check:'sequence + transformRule',
    feedback:{fix:'The plural of <span class="ar" dir="rtl">باب</span> is <span class="ar" dir="rtl">أبواب</span>.',pass:'<span class="ar" dir="rtl">أبواب</span> — many doors. <span class="ar" dir="rtl">أحسنت!</span>'}},
   {label:'Opposite',va:'عكس',kick:'Q5 · transformWord',prompt:[say('Write the <b>opposite</b> of <span class="ar" dir="rtl">كبير</span> — “big.”'),rule('Opposite','عكس'),txt('كبير',{variant:'small'})],
    surface:{mode:'write',unit:'word'},expected:{word:'صغير'},check:'sequence + transformRule',
    feedback:{fix:'The opposite of big is small — <span class="ar" dir="rtl">صغير</span>.',pass:'<span class="ar" dir="rtl">صغير</span> — “small.” <span class="ar" dir="rtl">أحسنت!</span>'}}
  ]},

{ key:'buildSentence', tab:'Sentence', n:6, skill:'syntax', pose:'think',
  note:'NEW — was missing entirely. Same engine: <code>write · sentence</code> surface (a long ruled line) + an <code>order</code> check. Fill-the-blank is the same surface with a gapped text prompt.',
  tbd:['Sentence set &amp; difficulty per level — <b>TBD</b>'],
  variants:[
   {label:'Hear it',kick:'Q6 · buildSentence',prompt:[say('Listen to the whole sentence, then write it — word by word, in order.'),aud('Play the sentence')],
    surface:{mode:'write',unit:'sentence',thinkText:'Let me read your sentence <span class="thinking-dots"><i></i><i></i><i></i></span>'},expected:{words:['البابُ','كبير']},check:'order + sequence',
    feedback:{fix:'Good start — keep the words in order: <span class="ar" dir="rtl">البابُ كبير</span>.',pass:'<span class="ar" dir="rtl">البابُ كبير</span> — “the door is big.” A whole sentence! <span class="ar" dir="rtl">أحسنت!</span>'}},
   {label:'Fill the blank',va:'فراغ',kick:'Q6 · buildSentence',prompt:[say('Read the sentence and write the <b>missing word</b>.'),txt('البابُ __blank__')],
    surface:{mode:'write',unit:'word'},expected:{word:'كبير'},check:'sequence',
    feedback:{fix:'A describing word fits here — try <span class="ar" dir="rtl">كبير</span> (“big”).',pass:'<span class="ar" dir="rtl">البابُ كبير</span> — you filled it in. <span class="ar" dir="rtl">أحسنت!</span>'}},
   {label:'Picture',kick:'Q6 · buildSentence',prompt:[say('Look at the picture and write a sentence that tells what you see.'),img('a big door')],
    surface:{mode:'write',unit:'sentence'},expected:{words:['البابُ','كبير']},check:'order + sequence',
    feedback:{fix:'Name it, then describe it: <span class="ar" dir="rtl">البابُ كبير</span>.',pass:'<span class="ar" dir="rtl">البابُ كبير</span> — you wrote a sentence. <span class="ar" dir="rtl">أحسنت!</span>'}}
  ]},

/* support */
{ key:'teachCard', tab:'Teach card', support:true, skill:'—', pose:'idle',
  note:'A support screen, not an assessed question. Just <code>PromptHeader</code> + a teach panel with <b>no WriteSurface and no FeedbackPanel</b>.',
  tbd:['Scope of <span class="ar" dir="rtl">ة / ى</span> &amp; which letters have which forms — <b>TBD</b>'],
  variants:[
   {label:'Meet baa',va:'ب',kick:'Support · teachCard',prompt:[say('This card just <b>teaches</b> — the sound and the four shapes. It feeds every question; nothing to write here.')],
    teach:true,supportCta:'Got it',check:'—',expected:{},role:'Teaches the sound, the four forms, and an example word. Feeds the question types.'}
  ]},

{ key:'letterMaze', tab:'Letter maze', support:true, skill:'—', pose:'idle',
  note:'Enrichment. The <b>same WriteSurface</b> in <code>trace</code> mode, but the validator runs relaxed (no-fail) — a fine-motor warm-up between graded reps.',
  tbd:['How a mastered letter resurfaces for review — <b>TBD</b>'],
  variants:[
   {label:'Trace the path',kick:'Support · letterMaze',prompt:[say('A fun warm-up — trace the winding baa path. No grading, just play.')],
    surface:{mode:'trace',unit:'glyph',guideGlyph:'ب',demo:false,firstFix:false},expected:{},check:'glyph · relaxed · no-fail',role:'A no-fail fine-motor warm-up between graded reps.',
    feedback:{pass:'You traced it smoothly — nice warm-up!'}}
  ]}
];

let cur=0, curV=0, inspOpen=false;

function teachSurface(){
  const t=document.createElement('div'); t.className='writebox';
  t.style.cssText='flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:18px;';
  const forms=[['ب','Isolated'],['بـ','Initial'],['ـبـ','Medial'],['ـب','Final']];
  t.innerHTML=`<div style="font-family:var(--font-arabic);font-weight:600;font-size:140px;color:var(--deep-ink);direction:rtl;line-height:1">بَ</div>
    <div style="display:flex;gap:14px">${forms.map(([g,l])=>`<div style="width:78px;height:78px;border-radius:16px;background:var(--soft-aqua);border:1px solid var(--aqua-edge);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px"><div style="font-family:var(--font-arabic);font-weight:500;font-size:30px;color:var(--deep-ink);direction:rtl;line-height:1">${g}</div><div style="font-family:var(--font-body);font-weight:700;font-size:9px;letter-spacing:.04em;text-transform:uppercase;color:var(--fg-muted)">${l}</div></div>`).join('')}</div>
    <button class="playbtn" style="width:auto;padding:0 20px;height:50px"><span>${Q.IC.speaker}</span>Hear “baa”</button>
    <div style="font-family:var(--font-body);font-weight:700;font-size:12.5px;color:var(--fg-muted)">No writing — this card sets up the sound &amp; shapes the questions test.</div>`;
  t.querySelector('.playbtn').addEventListener('click',e=>Q.ping(e.currentTarget));
  return t;
}

function buildPager(){
  pager.innerHTML='';
  TYPES.forEach((t,i)=>{
    if(t.support && (i===0||!TYPES[i-1].support)){ const dv=document.createElement('div'); dv.className='pdiv-lbl'; dv.textContent='Support'; pager.appendChild(dv); }
    const b=document.createElement('button'); b.className='pchip'+(i===cur?' on':'')+(t.support?' support':'');
    b.innerHTML=`<div class="pn">${t.support?'·':'Q'+t.n}</div><div class="pl">${t.tab}</div>`;
    b.addEventListener('click',()=>render(i,0)); pager.appendChild(b);
  });
}
function buildControls(t){
  controls.innerHTML='';
  if(t.variants.length>1){
    const lab=document.createElement('span'); lab.className='vlab'; lab.textContent='Prompt'; controls.appendChild(lab);
    t.variants.forEach((v,j)=>{ const b=document.createElement('button'); b.className='vchip'+(j===curV?' on':'');
      b.innerHTML=(v.va?`<span class="va" dir="rtl">${v.va}</span>`:'')+`<span>${v.label}</span>`;
      b.addEventListener('click',()=>render(cur,j)); controls.appendChild(b); });
  }
  if(!t.support){
    const sb=document.createElement('div'); sb.className='statebar';
    sb.innerHTML=`<button data-s="prompt" class="on">Prompt</button><button data-s="fix">Fix</button><button data-s="pass">Pass</button>`;
    sb.querySelectorAll('button').forEach(btn=>btn.addEventListener('click',()=>{ sb.querySelectorAll('button').forEach(x=>x.classList.toggle('on',x===btn)); scaffold.showState(btn.dataset.s); }));
    controls.appendChild(sb);
  }
}
function buildTbd(t){
  let html=`<span class="tbd"><span class="d"></span>${GTBD}</span>`;
  t.tbd.forEach(x=>html+=`<span class="tbd"><span class="d"></span>${x}</span>`);
  tbdrow.innerHTML=html;
}
function renderInspector(t,v){
  const usesSurface=!v.teach;
  const comps=[
    {n:'ExerciseScaffold',on:true,r:'page shell'},
    {n:'PromptHeader',on:true,r:(v.prompt.filter(p=>p.type!=='say').map(p=>p.type).join(' + ')||'say only')},
    {n:'WriteSurface',on:usesSurface,r:usesSurface?(v.surface.mode+' · '+v.surface.unit):'—'},
    {n:'FeedbackPanel',on:!v.teach,r:v.teach?'—':'pass / fix'},
    {n:'ProgressRibbon',on:true,r:'position'}
  ];
  compMap.innerHTML=comps.map(c=>`<div class="comp${c.on?' active':''}"><span class="cdot"></span><span class="cn">${c.n}</span><span class="cr">${c.r}</span></div>`).join('');
  const K=s=>`<span class="k">${s}</span>`, S=s=>`<span class="s">'${s}'</span>`;
  const pp=v.prompt.map(p=>p.type).join(', ');
  let lines=[];
  lines.push(`{`);
  lines.push(`  ${K('key')}: ${S(t.key)},`);
  lines.push(`  ${K('skill')}: ${S(t.skill)},`);
  lines.push(`  ${K('prompt')}: [ ${pp} ],`);
  if(v.teach){ lines.push(`  ${K('surface')}: <span class="c">null — teaches only</span>,`); }
  else { lines.push(`  ${K('surface')}: { ${K('mode')}:${S(v.surface.mode)}, ${K('unit')}:${S(v.surface.unit)}${v.surface.guideForm?', '+K('guideForm')+':'+S(v.surface.guideForm):''}${v.surface.given?', '+K('given')+':{…}':''} },`); }
  lines.push(`  ${K('expected')}: ${JSON.stringify(v.expected).replace(/"/g,'')},`);
  lines.push(`  ${K('check')}: ${S(v.check)}`);
  lines.push(`}`);
  cfgJson.innerHTML=lines.join('\n');
  cfgNote.innerHTML=t.note;
}

function render(i,v){
  cur=i; curV=v||0; const t=TYPES[i], variant=t.variants[curV];
  buildPager(); buildControls(t); buildTbd(t);
  const config={
    kick:variant.kick, pose:t.pose, prompt:variant.prompt,
    ribbon:{total:6,active:t.support?5:(t.n-1)},
    feedback:variant.feedback,
    onNext:()=>{ const next=(cur+1)%TYPES.length; render(next,0); }
  };
  if(variant.teach){ config.customSurface=teachSurface; config.supportCta=variant.supportCta;
    config.tutorExtra=()=>{ const d=document.createElement('div'); d.style.cssText='margin-top:auto;background:var(--gold-tint);border:1px solid #EBD49A;border-radius:14px;padding:11px 13px;font-family:var(--font-body);font-weight:700;font-size:11.5px;line-height:1.45;color:#9A6A2E'; d.innerHTML='Support screen · not an assessed question'; return d; }; }
  else if(variant.surface){ config.surface=variant.surface; }
  scaffold.load(config);
  renderInspector(t,variant);
}

document.getElementById('cfgToggle').addEventListener('click',e=>{
  inspOpen=!inspOpen; inspector.classList.toggle('open',inspOpen); e.currentTarget.classList.toggle('on',inspOpen);
});

const stage=document.querySelector('.stage');
function fit(){ Q.fit(stage,1280,800); }
addEventListener('resize',fit);
buildPager(); render(0,0); fit();
