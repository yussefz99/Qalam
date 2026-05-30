/* global React, STAR, Eyebrow, QBtn, Mascot, Stars, Stage */

// =============================================================================
// HOME · Variant A — "Today, served"  (current direction, refined)
// Hero lesson card sits center-screen with mascot greeting; supporting cards beneath.
// =============================================================================
function HomeA() {
  return (
    <Stage>
      <div style={{ padding: '24px 56px', display: 'flex', flexDirection: 'column', gap: 20, height: '100%', boxSizing: 'border-box' }}>
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <div>
            <Eyebrow>Sunday · Today's Lesson</Eyebrow>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 40, color: 'var(--fg)', lineHeight: 1.05, marginTop: 4 }}>
              Welcome back, Layla.
            </div>
            <div style={{ fontFamily: 'var(--font-body)', fontSize: 18, color: 'var(--fg-muted)', marginTop: 4 }}>
              Qalam has a new lesson ready for you.
            </div>
          </div>
          <Mascot state="idle" size={140} />
        </div>

        {/* Hero card with "Tap to start" affordance */}
        <div style={{ background: '#fff', borderRadius: 28, padding: 22, boxShadow: 'var(--shadow-md)', display: 'flex', gap: 20, alignItems: 'center' }}>
          <div style={{ width: 120, height: 120, borderRadius: 24, background: 'var(--soft-aqua)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <div dir="rtl" style={{ fontFamily: 'var(--font-arabic-display)', fontWeight: 600, fontSize: 80, color: 'var(--deep-ink)', lineHeight: 1 }}>ب</div>
          </div>
          <div style={{ flex: 1 }}>
            <Eyebrow>Letters &amp; Writing · Lesson 4</Eyebrow>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 32, color: 'var(--fg)' }}>The letter Baa</div>
            <div style={{ fontFamily: 'var(--font-body)', fontSize: 16, color: 'var(--fg-muted)' }}>8 minutes · stroke order, tracing, and sounds</div>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, padding: '0 8px 0 20px', borderLeft: '1px solid var(--border-soft)' }}>
            <div style={{ width: 76, height: 76, borderRadius: '50%', background: 'var(--ink-teal)', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 5px 0 var(--deep-ink)' }}>
              <svg width="34" height="34" viewBox="0 0 24 24" fill="currentColor"><path d="M7 5v14l12-7Z"/></svg>
            </div>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 13, color: 'var(--deep-ink)', letterSpacing: '0.05em', textTransform: 'uppercase' }}>Tap to start</div>
          </div>
        </div>

        {/* Two supporting cards */}
        <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: 20, flex: 1, minHeight: 0 }}>
          <div style={{ background: '#fff', borderRadius: 24, padding: 20, boxShadow: 'var(--shadow-md)' }}>
            <Eyebrow>Up Next</Eyebrow>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginTop: 12 }}>
              {[['ت','Sentence: I see a house','Sentence Building · L 5','6 min'],
                ['ث','Sounds: tha vs taa','Pronunciation · L 6','4 min']].map(([g,t,e,m],i)=>(
                <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                  <div dir="rtl" style={{ width: 56, height: 56, borderRadius: 16, background: 'var(--soft-aqua)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'var(--font-arabic-display)', fontWeight: 600, fontSize: 32, color: 'var(--deep-ink)', lineHeight: 1 }}>{g}</div>
                  <div style={{ flex: 1 }}>
                    <Eyebrow>{e}</Eyebrow>
                    <div style={{ fontFamily: 'var(--font-display)', fontWeight: 500, fontSize: 18, color: 'var(--fg)' }}>{t}</div>
                  </div>
                  <div style={{ fontFamily: 'var(--font-body)', fontSize: 14, color: 'var(--fg-muted)' }}>{m}</div>
                </div>
              ))}
            </div>
          </div>
          <div style={{ background: 'var(--soft-aqua)', borderRadius: 24, padding: 20, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <Eyebrow>Level 2 · Letters &amp; Writing</Eyebrow>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 10 }}>
              <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 40, color: 'var(--deep-ink)', lineHeight: 1 }}>3</div>
              <div style={{ fontFamily: 'var(--font-body)', fontSize: 15, color: 'var(--fg-muted)' }}>of 12 letters</div>
            </div>
            <div style={{ height: 18, background: '#fff', borderRadius: 999, overflow: 'hidden' }}>
              <div style={{ height: '100%', width: '25%', background: 'var(--gold-ink)', borderRadius: 999 }} />
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 2 }}>
              {STAR(true, 20)}
              <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 18, color: 'var(--fg)' }}>
                <span style={{ color: 'var(--gold-ink)' }}>9</span> stars this week
              </div>
            </div>
          </div>
        </div>
      </div>
    </Stage>
  );
}

// =============================================================================
// HOME · Variant B — "The Journey speaks"
// Journey path is the centerpiece; today's node pulses; mascot stands near it with
// a speech bubble. The lesson chip floats above the path. Single, large CTA.
// =============================================================================
function HomeB() {
  // 8 letters along a winding path.
  const path = [
    { x: 90,  y: 60,  state: 'complete', g: 'ا' },
    { x: 195, y: 130, state: 'complete', g: 'ب' },
    { x: 305, y: 60,  state: 'complete', g: 'ت' },
    { x: 420, y: 130, state: 'current',  g: 'ث' },
    { x: 530, y: 60,  state: 'locked',   g: 'ج' },
    { x: 640, y: 130, state: 'locked',   g: 'ح' },
    { x: 750, y: 60,  state: 'future',   g: 'خ' },
    { x: 860, y: 130, state: 'future',   g: 'د' },
  ];
  return (
    <Stage>
      <div style={{ padding: '36px 56px', height: '100%', boxSizing: 'border-box', display: 'flex', flexDirection: 'column' }}>
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <div>
            <Eyebrow>Sunday · Your Journey</Eyebrow>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 44, color: 'var(--fg)', lineHeight: 1.05, marginTop: 6 }}>
              You're up to <span style={{ color: 'var(--deep-ink)' }}>thaa</span> today.
            </div>
            <div style={{ fontFamily: 'var(--font-body)', fontSize: 18, color: 'var(--fg-muted)', marginTop: 6 }}>3 letters mastered · 9 stars this week</div>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6, alignItems: 'flex-end' }}>
            <Stars filled={9} total={9} size={22} gap={3} />
          </div>
        </div>

        {/* Path + nodes */}
        <div style={{ marginTop: 28, position: 'relative', flex: 1 }}>
          <svg viewBox="0 0 980 220" width="100%" preserveAspectRatio="xMidYMid meet" style={{ position: 'absolute', top: 30, left: 0, height: 260 }}>
            <path d="M 130 100 Q 192 160 247 100 T 365 100 T 482 100 T 600 100 T 717 100 T 835 100 T 900 100"
                  fill="none" stroke="#E8DFC9" strokeWidth="14" strokeLinecap="round" strokeDasharray="2 22"/>
            <path d="M 130 100 Q 192 160 247 100 T 365 100 Q 420 160 482 100"
                  fill="none" stroke="#F2A60C" strokeWidth="10" strokeLinecap="round"/>
          </svg>

          {path.map((n, i) => {
            const isCurrent = n.state === 'current';
            const bg = n.state === 'complete' ? 'var(--leaf)'
                     : isCurrent ? 'var(--ink-teal)'
                     : n.state === 'locked' ? '#DAD3C2'
                     : '#fff';
            const fg = n.state === 'future' ? 'var(--slate)' : '#fff';
            const shadow = n.state === 'complete' ? '0 6px 0 #2A8A60'
                         : isCurrent ? '0 6px 0 var(--deep-ink)'
                         : n.state === 'locked' ? '0 4px 0 #B8AE99'
                         : 'none';
            return (
              <div key={i} style={{
                position: 'absolute', left: n.x + 40, top: n.y + 30,
                width: isCurrent ? 108 : 88, height: isCurrent ? 108 : 88,
                borderRadius: '50%', background: bg, color: fg,
                boxShadow: shadow,
                border: n.state === 'future' ? '2px dashed var(--aqua-edge)' : 'none',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'var(--font-arabic-display)', fontWeight: 600, fontSize: isCurrent ? 56 : 44, direction: 'rtl', lineHeight: 1,
              }}>{n.g}</div>
            );
          })}

          {/* Mascot near "today" node, with speech bubble */}
          <div style={{ position: 'absolute', left: 380, top: 290, display: 'flex', alignItems: 'flex-end', gap: 16 }}>
            <Mascot state="write" size={200} />
            <div style={{ position: 'relative', background: '#fff', boxShadow: 'var(--shadow-md)', borderRadius: 24, padding: '20px 26px', maxWidth: 480 }}>
              <Eyebrow>Letters &amp; Writing · L 4</Eyebrow>
              <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 30, color: 'var(--fg)', lineHeight: 1.1, marginTop: 4 }}>Today let's learn <span dir="rtl" style={{ fontFamily: 'var(--font-arabic-display)', color: 'var(--deep-ink)' }}>ثَ</span> — thaa.</div>
              <div style={{ fontFamily: 'var(--font-body)', fontSize: 16, color: 'var(--fg-muted)', marginTop: 4 }}>8 minutes. Stroke order, then trace, then sounds.</div>
              <span style={{ position: 'absolute', left: -16, bottom: 32, width: 0, height: 0,
                borderTop: '14px solid transparent', borderBottom: '14px solid transparent', borderRight: '18px solid #fff' }} />
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 8 }}>
          <QBtn variant="ghost">Replay yesterday</QBtn>
          <QBtn size="xl">Start Lesson</QBtn>
        </div>
      </div>
    </Stage>
  );
}

// =============================================================================
// HOME · Variant C — "One letter, big"
// Minimalist single-card: full-bleed lesson with the Arabic glyph as a watermark.
// Up-next collapsed to a small footer strip.
// =============================================================================
function HomeC() {
  return (
    <Stage>
      <div style={{ padding: '24px 48px 24px 48px', height: '100%', boxSizing: 'border-box', display: 'flex', flexDirection: 'column', gap: 16 }}>
        <div>
          <Eyebrow>Sunday · Today</Eyebrow>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 32, color: 'var(--fg)' }}>One lesson for Layla.</div>
        </div>

        {/* Hero full-bleed card */}
        <div style={{
          position: 'relative', flex: 1, borderRadius: 36, overflow: 'hidden',
          background: 'linear-gradient(180deg, #fff 0%, var(--soft-aqua) 100%)',
          boxShadow: 'var(--shadow-md)', padding: '40px 56px',
          display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
        }}>
          {/* Watermark glyph */}
          <div dir="rtl" style={{
            position: 'absolute', right: -40, bottom: -120,
            fontFamily: 'var(--font-arabic-display)', fontWeight: 600, fontSize: 720,
            color: 'var(--teal-wash)', opacity: 0.45, lineHeight: 1, pointerEvents: 'none',
          }}>ب</div>

          <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', gap: 12 }}>
            <Eyebrow>Letters &amp; Writing · Lesson 4</Eyebrow>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 84, color: 'var(--deep-ink)', lineHeight: 1, letterSpacing: '-0.01em' }}>The letter Baa</div>
            <div style={{ fontFamily: 'var(--font-body)', fontSize: 22, color: 'var(--fg-muted)', maxWidth: 540, lineHeight: 1.4 }}>
              You'll watch Qalam write it, trace it three times, and learn its sound.
            </div>
            <div style={{ display: 'flex', gap: 12, marginTop: 8 }}>
              {['8 min','Stroke order','Tracing','Sounds'].map((t,i)=>(
                <span key={i} style={{
                  background: 'rgba(255,255,255,0.7)', backdropFilter: 'blur(4px)',
                  border: '1px solid var(--border-soft)',
                  padding: '8px 16px', borderRadius: 999,
                  fontFamily: 'var(--font-body)', fontWeight: 600, fontSize: 14, color: 'var(--deep-ink)',
                }}>{t}</span>
              ))}
            </div>
          </div>

          <div style={{ position: 'relative', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
            <Mascot state="idle" size={180} />
            <QBtn size="xl" style={{ minWidth: 320 }}>Start Lesson</QBtn>
          </div>
        </div>

        {/* Footer strip */}
        <div style={{ background: '#fff', borderRadius: 20, padding: '14px 22px', boxShadow: 'var(--shadow-sm)', display: 'flex', alignItems: 'center', gap: 24 }}>
          <Eyebrow>Up Next</Eyebrow>
          <div style={{ flex: 1, display: 'flex', gap: 18 }}>
            <span style={{ fontFamily: 'var(--font-display)', fontSize: 16, color: 'var(--fg-muted)' }}><span dir="rtl" style={{ fontFamily: 'var(--font-arabic-display)', color: 'var(--deep-ink)', fontWeight: 600, marginRight: 6 }}>ت</span> Sentence: I see a house · 6 min</span>
            <span style={{ fontFamily: 'var(--font-display)', fontSize: 16, color: 'var(--fg-muted)' }}><span dir="rtl" style={{ fontFamily: 'var(--font-arabic-display)', color: 'var(--deep-ink)', fontWeight: 600, marginRight: 6 }}>ث</span> Sounds: tha vs taa · 4 min</span>
          </div>
          <span style={{ fontFamily: 'var(--font-body)', fontSize: 14, color: 'var(--fg-muted)' }}>3 lessons · 9 stars this week</span>
        </div>
      </div>
    </Stage>
  );
}

Object.assign(window, { HomeA, HomeB, HomeC });
