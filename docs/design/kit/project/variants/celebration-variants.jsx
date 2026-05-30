/* global React, STAR, Eyebrow, QBtn, Mascot, Stars, Stage */

// =============================================================================
// CELEBRATION · Variant A — "Big mascot, gold stars"  (current direction)
// =============================================================================
function CelebrationA() {
  const pieces = Array.from({ length: 24 }).map((_, i) => ({
    x: 40 + (i / 24) * 1100 + (Math.sin(i) * 40),
    y: 720 + (i % 4) * 12,
    rot: (i * 47) % 360,
    size: 12 + (i % 5) * 4,
    teal: i % 3 === 0,
  }));
  return (
    <Stage showClose stars={42}>
      <div style={{ padding: 56, height: '100%', boxSizing: 'border-box', display: 'flex', flexDirection: 'column', position: 'relative' }}>
        {pieces.map((p, i) => (
          <div key={i} style={{
            position: 'absolute', left: p.x, top: p.y,
            width: p.size, height: p.size,
            background: p.teal ? 'var(--ink-teal)' : 'var(--gold-ink)',
            borderRadius: i % 2 === 0 ? '50%' : 4,
            transform: `rotate(${p.rot}deg)`,
            opacity: 0.85,
          }}/>
        ))}

        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', textAlign: 'center', gap: 24 }}>
          <Mascot state="cheer" size={260} />
          <div style={{ width: 'max-content' }}>
            <Eyebrow>Lesson Complete</Eyebrow>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 64, color: 'var(--deep-ink)', lineHeight: 1.05, marginTop: 4, whiteSpace: 'nowrap' }}>You did it!</div>
          </div>
          <Stars filled={3} total={5} size={72} gap={18} />
          <span style={{
            display: 'inline-flex', alignItems: 'center', gap: 8,
            background: 'var(--gold-tint)', color: '#8C5C04',
            height: 56, padding: '0 22px', borderRadius: 999,
            fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 22,
          }}>{STAR(true, 28)}<span style={{ whiteSpace: 'nowrap' }}>+3 stars · Total 42</span></span>
          <div style={{ fontFamily: 'var(--font-body)', fontSize: 20, color: 'var(--fg-muted)', maxWidth: 580, lineHeight: 1.5 }}>
            You traced <strong style={{ color: 'var(--fg)' }}>baa</strong> and built one sentence today. Tomorrow we'll meet <strong style={{ color: 'var(--fg)' }}>taa</strong>.
          </div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'center', gap: 16 }}>
          <QBtn variant="secondary">See journey</QBtn>
          <QBtn size="xl">Back home</QBtn>
        </div>
      </div>
    </Stage>
  );
}

// =============================================================================
// CELEBRATION · Variant B — "Mastered" stamp
// The letter you just mastered fills the screen, drawn in gold with a "MASTERED"
// ribbon stamp on top. Quieter, theatrical. Mascot small at side.
// =============================================================================
function CelebrationB() {
  return (
    <Stage showClose stars={42}>
      <div style={{ padding: 56, height: '100%', boxSizing: 'border-box', position: 'relative', overflow: 'hidden' }}>
        <Eyebrow>Mastered</Eyebrow>
        <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 32, color: 'var(--fg)', marginTop: 4 }}>
          You learned the letter baa.
        </div>

        {/* Center glyph — gold inked */}
        <div style={{
          position: 'absolute', left: 0, right: 0, top: 130, bottom: 140,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          {/* Soft halo */}
          <div style={{
            position: 'absolute', width: 520, height: 520, borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(242,166,12,0.18) 0%, rgba(242,166,12,0) 70%)',
          }}/>
          {/* Glyph */}
          <div dir="rtl" style={{
            fontFamily: 'var(--font-arabic-display)', fontWeight: 600,
            fontSize: 480, color: 'var(--gold-ink)', lineHeight: 1,
            textShadow: '0 3px 0 rgba(197,134,10,0.4), 0 14px 30px rgba(197,134,10,0.25)',
          }}>ب</div>

          {/* Diagonal "MASTERED" ribbon */}
          <div style={{
            position: 'absolute', top: 130, right: 70, transform: 'rotate(8deg)',
            background: 'var(--deep-ink)', color: '#fff',
            fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 36,
            letterSpacing: '0.06em', padding: '14px 48px',
            borderRadius: 14, boxShadow: '0 12px 30px rgba(14,91,95,0.4)',
            display: 'flex', alignItems: 'center', gap: 14,
          }}>
            {STAR(true, 34)} MASTERED
          </div>

          {/* Mascot bottom-left */}
          <div style={{ position: 'absolute', left: 40, bottom: -10 }}>
            <Mascot state="cheer" size={180} />
          </div>

          {/* Stars row top */}
          <div style={{ position: 'absolute', top: -10, left: '50%', transform: 'translateX(-50%)' }}>
            <Stars filled={3} total={3} size={64} gap={18} />
          </div>
        </div>

        {/* Bottom band */}
        <div style={{ position: 'absolute', left: 0, right: 0, bottom: 56, padding: '0 56px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div>
            <Eyebrow>Total</Eyebrow>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 32, color: 'var(--fg)' }}>
              <span style={{ color: 'var(--gold-ink)' }}>42</span> stars
              <span style={{ fontFamily: 'var(--font-body)', fontSize: 18, color: 'var(--fg-muted)', marginLeft: 14 }}>+3 today</span>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 16 }}>
            <QBtn variant="secondary">See journey</QBtn>
            <QBtn size="xl">Back home</QBtn>
          </div>
        </div>
      </div>
    </Stage>
  );
}

// =============================================================================
// CELEBRATION · Variant C — "Journey forward"
// Shows the journey path, with the just-completed node leafing green and the
// mascot stamping a gold seal on top. The next node is highlighted.
// =============================================================================
function CelebrationC() {
  const nodes = [
    { g: 'ا', state: 'complete' },
    { g: 'ب', state: 'just',     stamp: true },
    { g: 'ت', state: 'next' },
    { g: 'ث', state: 'locked' },
    { g: 'ج', state: 'future' },
  ];
  return (
    <Stage showClose stars={42}>
      <div style={{ padding: 56, height: '100%', boxSizing: 'border-box', display: 'flex', flexDirection: 'column' }}>
        <Eyebrow>Lesson Complete</Eyebrow>
        <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 56, color: 'var(--deep-ink)', lineHeight: 1.05, marginTop: 4, whiteSpace: 'nowrap' }}>
          One step closer.
        </div>
        <div style={{ fontFamily: 'var(--font-body)', fontSize: 18, color: 'var(--fg-muted)', marginTop: 6 }}>
          You added <strong style={{ color: 'var(--gold-ink)' }}>baa</strong> to your journey.
        </div>

        {/* Path visualization */}
        <div style={{ flex: 1, position: 'relative', marginTop: 36 }}>
          <svg viewBox="0 0 1100 200" width="100%" style={{ height: 'auto', position: 'absolute', top: 60 }}>
            <line x1="80" y1="100" x2="1020" y2="100" stroke="#E8DFC9" strokeWidth="10" strokeDasharray="2 22" strokeLinecap="round"/>
            <line x1="80" y1="100" x2="450" y2="100" stroke="#3FB984" strokeWidth="8" strokeLinecap="round"/>
          </svg>

          <div style={{ position: 'absolute', top: 0, left: 0, right: 0, display: 'flex', justifyContent: 'space-around', alignItems: 'center', height: 220 }}>
            {nodes.map((n, i) => {
              const big = n.state === 'just' || n.state === 'next';
              const bg = n.state === 'complete' ? 'var(--leaf)'
                       : n.state === 'just'   ? 'var(--leaf)'
                       : n.state === 'next'   ? 'var(--ink-teal)'
                       : n.state === 'locked' ? '#DAD3C2'
                       : '#fff';
              const fg = n.state === 'future' ? 'var(--slate)' : '#fff';
              const shadow = n.state === 'complete' || n.state === 'just' ? '0 8px 0 #2A8A60'
                           : n.state === 'next' ? '0 8px 0 var(--deep-ink)'
                           : n.state === 'locked' ? '0 5px 0 #B8AE99'
                           : 'none';
              const size = big ? 132 : 96;
              return (
                <div key={i} style={{ position: 'relative' }}>
                  <div style={{
                    width: size, height: size, borderRadius: '50%',
                    background: bg, color: fg, boxShadow: shadow,
                    border: n.state === 'future' ? '2px dashed var(--aqua-edge)' : 'none',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontFamily: 'var(--font-arabic-display)', fontWeight: 600,
                    fontSize: big ? 68 : 44, direction: 'rtl', lineHeight: 1,
                  }}>{n.g}</div>
                  {n.stamp && (
                    <div style={{
                      position: 'absolute', top: -22, right: -22,
                      width: 76, height: 76, borderRadius: '50%',
                      background: 'var(--gold-ink)', color: '#fff',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      boxShadow: '0 6px 0 #B97D08', transform: 'rotate(-8deg)',
                    }}>{STAR(true, 56)}</div>
                  )}
                </div>
              );
            })}
          </div>

          {/* Mascot beneath the completed node */}
          <div style={{ position: 'absolute', left: '20%', top: 250, transform: 'translateX(-50%)' }}>
            <Mascot state="cheer" size={180} />
          </div>

          {/* Floating chip */}
          <div style={{
            position: 'absolute', left: '20%', top: 410, transform: 'translateX(-50%)',
            display: 'inline-flex', alignItems: 'center', gap: 8,
            background: 'var(--gold-tint)', color: '#8C5C04',
            height: 52, padding: '0 22px', borderRadius: 999,
            fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 20,
            boxShadow: 'var(--shadow-sm)',
          }}>{STAR(true, 26)}+3 stars</div>
        </div>

        {/* Bottom CTA + tomorrow tease */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 'auto' }}>
          <div>
            <Eyebrow>Tomorrow</Eyebrow>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 24, color: 'var(--fg)' }}>
              The letter taa — <span dir="rtl" style={{ fontFamily: 'var(--font-arabic-display)', color: 'var(--deep-ink)' }}>تَ</span>
            </div>
          </div>
          <QBtn size="xl">Back home</QBtn>
        </div>
      </div>
    </Stage>
  );
}

Object.assign(window, { CelebrationA, CelebrationB, CelebrationC });
