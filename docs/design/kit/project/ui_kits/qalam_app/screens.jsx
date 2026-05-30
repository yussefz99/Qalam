/* global React, LETTERS, LETTER_ORDER */
/* global Star, Button, Chip, Card, ProgressBar, Eyebrow, Icon */
/* global Mascot, LessonCard, JourneyNode, TracingCanvas */
const { useState, useEffect } = React;

// ============================================================================
// HOME
// ============================================================================
function HomeScreen({ child, progress, letter, nextUp, onStart, onJourney, onReset }) {
  const lessonNumber = letter.idx + 1;            // Lesson 1 = Alif, etc.
  const masteredCount = Object.keys(progress.letterStars || {}).length;
  const weeklyStars = Math.min(progress.totalStars, 12);   // simple "this week" stat

  return (
    <div style={{ padding: '24px 56px 24px 56px', display: 'flex', flexDirection: 'column', gap: 20, height: '100%', boxSizing: 'border-box' }}>
      <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
        <div>
          <Eyebrow>Sunday · Today's Lesson</Eyebrow>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 40, color: 'var(--fg)', lineHeight: 1.05, marginTop: 4 }}>
            Welcome back, {child.name.split(' ')[0]}.
          </div>
          <div style={{ fontFamily: 'var(--font-body)', fontSize: 18, color: 'var(--fg-muted)', marginTop: 4 }}>
            Qalam has a new letter ready for you.
          </div>
        </div>
        <Mascot state="idle" size={140} />
      </div>

      {/* Today's lesson hero */}
      <button
        onClick={onStart}
        style={{
          background: '#fff', borderRadius: 28, padding: 22,
          boxShadow: 'var(--shadow-md)', border: 'none', cursor: 'pointer',
          display: 'flex', gap: 20, alignItems: 'center', width: '100%', textAlign: 'left',
          transition: 'transform var(--dur-fast) var(--ease-out-quart), box-shadow var(--dur-fast) var(--ease-out-quart)',
        }}
        onMouseDown={e => { e.currentTarget.style.transform = 'translateY(2px)'; e.currentTarget.style.boxShadow = 'var(--shadow-sm)'; }}
        onMouseUp={e => { e.currentTarget.style.transform = ''; e.currentTarget.style.boxShadow = 'var(--shadow-md)'; }}
        onMouseLeave={e => { e.currentTarget.style.transform = ''; e.currentTarget.style.boxShadow = 'var(--shadow-md)'; }}
      >
        <div style={{
          width: 120, height: 120, borderRadius: 24, background: 'var(--soft-aqua)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
        }}>
          <div dir="rtl" style={{ fontFamily: 'var(--font-arabic-display)', fontWeight: 600, fontSize: 80, color: 'var(--deep-ink)', lineHeight: 1 }}>{letter.glyph}</div>
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 4 }}>
          <Eyebrow>Letters &amp; Writing · Lesson {lessonNumber}</Eyebrow>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 32, color: 'var(--fg)', lineHeight: 1.1 }}>The letter {letter.name}</div>
          <div style={{ fontFamily: 'var(--font-body)', fontSize: 16, color: 'var(--fg-muted)' }}>
            8 minutes · stroke order, then trace, then sound
          </div>
        </div>
        <div style={{
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
          padding: '0 8px 0 20px', borderLeft: '1px solid var(--border-soft)',
        }}>
          <div style={{
            width: 76, height: 76, borderRadius: '50%',
            background: 'var(--ink-teal)', color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 5px 0 var(--deep-ink)',
          }}>{React.cloneElement(Icon.play, { width: 34, height: 34 })}</div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 13, color: 'var(--deep-ink)', letterSpacing: '0.05em', textTransform: 'uppercase' }}>Tap to start</div>
        </div>
      </button>

      <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: 20, flex: 1, minHeight: 0 }}>
        <Card style={{ padding: 20 }}>
          <Eyebrow>Up Next</Eyebrow>
          <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 12 }}>
            {nextUp.length === 0 && (
              <div style={{ fontFamily: 'var(--font-body)', fontSize: 16, color: 'var(--fg-muted)', padding: '24px 8px' }}>
                You've reached the last letter — well done! Tap "Restart" below to begin again.
              </div>
            )}
            {nextUp.map((l, i) => (
              <UpcomingRow key={l.key} glyph={l.glyph} title={`The letter ${l.name}`}
                eyebrow={`Letters & Writing · Lesson ${letter.idx + 2 + i}`} meta="8 min" />
            ))}
          </div>
        </Card>

        <Card aqua style={{ display: 'flex', flexDirection: 'column', gap: 10, padding: 20 }}>
          <Eyebrow>Level 2 · Letters &amp; Writing</Eyebrow>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 10 }}>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 40, color: 'var(--deep-ink)', lineHeight: 1 }}>{masteredCount}</div>
            <div style={{ fontFamily: 'var(--font-body)', fontSize: 15, color: 'var(--fg-muted)', whiteSpace: 'nowrap' }}>of {LETTER_ORDER.length} letters</div>
          </div>
          <ProgressBar pct={(masteredCount / LETTER_ORDER.length) * 100} />
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 2 }}>
            <Star size={20} />
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 18, color: 'var(--fg)', whiteSpace: 'nowrap' }}>
              <span style={{ color: 'var(--gold-ink)' }}>{weeklyStars}</span> stars this week
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <button className="qbtn ghost small" onClick={onJourney}>See journey {Icon.arrow}</button>
            {onReset && (
              <button className="qbtn ghost small" onClick={onReset} style={{ minWidth: 0, padding: '0 16px' }}>
                {Icon.refresh} Restart
              </button>
            )}
          </div>
        </Card>
      </div>
    </div>
  );
}

function UpcomingRow({ glyph, title, eyebrow, meta }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
      <div dir="rtl" style={{ width: 56, height: 56, borderRadius: 16, background: 'var(--soft-aqua)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'var(--font-arabic-display)', fontWeight: 600, fontSize: 32, color: 'var(--deep-ink)', lineHeight: 1 }}>{glyph}</div>
      <div style={{ flex: 1 }}>
        <Eyebrow>{eyebrow}</Eyebrow>
        <div style={{ fontFamily: 'var(--font-display)', fontWeight: 500, fontSize: 18, color: 'var(--fg)' }}>{title}</div>
      </div>
      <div style={{ fontFamily: 'var(--font-body)', fontSize: 14, color: 'var(--fg-muted)' }}>{meta}</div>
    </div>
  );
}

// ============================================================================
// STROKE-ORDER DEMO
// ============================================================================
function DemoScreen({ letter, onTry, onBack }) {
  return (
    <div style={{ padding: 40, height: '100%', boxSizing: 'border-box', display: 'flex', flexDirection: 'column' }}>
      <Eyebrow>Watch · Stroke order</Eyebrow>
      <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 36, color: 'var(--fg)', marginTop: 6 }}>
        Watch me write <span style={{ color: 'var(--deep-ink)' }}>{letter.romanized}</span>.
      </div>

      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 40 }}>
        <Mascot state="write" size={200} />
        <TracingCanvas letterKey={letter.key} mode="demo" size={460} />
        <Card aqua style={{ width: 220 }}>
          <Eyebrow>Tip</Eyebrow>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 500, fontSize: 20, lineHeight: 1.35, color: 'var(--fg)', marginTop: 8 }}>
            Start at the <span style={{ color: 'var(--gold-ink)', fontWeight: 600 }}>gold dot{letter.starts.length > 1 ? 's' : ''}</span>. Follow the order shown.
          </div>
          <div style={{ fontFamily: 'var(--font-body)', fontSize: 14, color: 'var(--fg-muted)', marginTop: 10 }}>
            {letter.strokes.length} stroke{letter.strokes.length > 1 ? 's' : ''}
            {(letter.marks || []).length > 0 && <> · {letter.marks.length} dot{letter.marks.length > 1 ? 's' : ''}</>}
          </div>
          <button className="qbtn ghost small" style={{ width: '100%', marginTop: 14 }}>
            {Icon.volume} Hear the sound
          </button>
        </Card>
      </div>

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Button variant="ghost" onClick={onBack} icon={Icon.back}>Back</Button>
        <Button size="large" onClick={onTry} icon={Icon.arrow}>I'll try</Button>
      </div>
    </div>
  );
}

// ============================================================================
// TRACING (3 attempts)
// ============================================================================
function TraceScreen({ letter, onComplete }) {
  const [attempt, setAttempt] = useState(1);
  const [feedback, setFeedback] = useState(null);     // 'correct' | 'try'
  const totalAttempts = 3;

  const markAttempt = (good) => {
    setFeedback(good ? 'correct' : 'try');
    if (good) {
      if (attempt >= totalAttempts) {
        setTimeout(() => onComplete(), 700);
      } else {
        setTimeout(() => { setAttempt(a => a + 1); setFeedback(null); }, 700);
      }
    } else {
      setTimeout(() => setFeedback(null), 1200);
    }
  };

  return (
    <div style={{ padding: 40, height: '100%', boxSizing: 'border-box', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <Eyebrow>Your turn · Trace</Eyebrow>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 36, color: 'var(--fg)', marginTop: 6 }}>
            Now you trace {letter.romanized}.
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <span style={{ fontFamily: 'var(--font-body)', fontSize: 14, color: 'var(--fg-muted)', whiteSpace: 'nowrap' }}>Try {attempt} of {totalAttempts}</span>
          <div style={{ width: 200 }}><ProgressBar pct={(attempt / totalAttempts) * 100} /></div>
        </div>
      </div>

      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 40 }}>
        <Mascot state={feedback === 'try' ? 'try-again' : 'idle'} size={200} />
        <div className={feedback === 'try' ? 'wiggle' : ''} style={{ position: 'relative' }}>
          <TracingCanvas letterKey={letter.key} mode="trace" size={460} />
          {feedback && (
            <div style={{ position: 'absolute', left: '50%', top: -22, transform: 'translateX(-50%)' }} className="pop-in">
              {feedback === 'correct'
                ? <Chip kind="success" icon={<svg width="20" height="20" viewBox="0 0 32 32"><circle cx="16" cy="16" r="13" fill="#3FB984"/><path d="M9.5 16.5l4.5 4.5 8.5-9" fill="none" stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"/></svg>}>Nice line!</Chip>
                : <Chip kind="try">Let's try that again</Chip>}
            </div>
          )}
        </div>
        <Card aqua style={{ width: 220 }}>
          <Eyebrow>Listen</Eyebrow>
          <div dir="rtl" style={{ fontFamily: 'var(--font-arabic-display)', fontWeight: 600, fontSize: 100, color: 'var(--deep-ink)', textAlign: 'center', marginTop: 12, lineHeight: 1 }}>{letter.glyph}</div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 500, fontSize: 22, textAlign: 'center', color: 'var(--fg)', marginTop: 6 }}>{letter.romanized}</div>
          <button className="qbtn ghost small" style={{ width: '100%', marginTop: 14 }}>{Icon.volume} Play sound</button>
        </Card>
      </div>

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Button variant="ghost" onClick={() => markAttempt(false)}>Try again</Button>
        <Button size="large" onClick={() => markAttempt(true)} icon={Icon.arrow}>
          {attempt >= totalAttempts ? 'Finish' : 'Next try'}
        </Button>
      </div>
    </div>
  );
}

// ============================================================================
// LESSON COMPLETE — "Mastered stamp"
// ============================================================================
function CompleteScreen({ letter, totalStars, onHome, onJourney }) {
  return (
    <div style={{ padding: 56, height: '100%', boxSizing: 'border-box', position: 'relative', overflow: 'hidden' }}>
      <Eyebrow>Mastered</Eyebrow>
      <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 32, color: 'var(--fg)', marginTop: 4 }}>
        You learned the letter {letter.romanized}.
      </div>

      <div style={{
        position: 'absolute', left: 0, right: 0, top: 130, bottom: 140,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <div style={{
          position: 'absolute', width: 520, height: 520, borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(242,166,12,0.18) 0%, rgba(242,166,12,0) 70%)',
        }}/>
        <div dir="rtl" style={{
          fontFamily: 'var(--font-arabic-display)', fontWeight: 600,
          fontSize: 460, color: 'var(--gold-ink)', lineHeight: 1,
          textShadow: '0 3px 0 rgba(197,134,10,0.4), 0 14px 30px rgba(197,134,10,0.25)',
        }}>{letter.glyph}</div>

        <div style={{
          position: 'absolute', top: 110, right: 60, transform: 'rotate(8deg)',
          background: 'var(--deep-ink)', color: '#fff',
          fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 36,
          letterSpacing: '0.06em', padding: '14px 48px',
          borderRadius: 14, boxShadow: '0 12px 30px rgba(14,91,95,0.4)',
          display: 'flex', alignItems: 'center', gap: 14,
        }}>
          <Star size={34} /> MASTERED
        </div>

        <div style={{ position: 'absolute', left: 0, bottom: -10 }}>
          <Mascot state="cheer" size={200} />
        </div>

        <div style={{ position: 'absolute', top: -10, left: '50%', transform: 'translateX(-50%)', display: 'flex', gap: 18 }}>
          {Array.from({ length: 3 }).map((_, i) => <Star key={i} size={64} />)}
        </div>
      </div>

      <div style={{ position: 'absolute', left: 0, right: 0, bottom: 56, padding: '0 56px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <Eyebrow>Total</Eyebrow>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 32, color: 'var(--fg)' }}>
            <span style={{ color: 'var(--gold-ink)' }}>{totalStars}</span> stars
            <span style={{ fontFamily: 'var(--font-body)', fontSize: 18, color: 'var(--fg-muted)', marginLeft: 14 }}>+3 today</span>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 16 }}>
          <Button variant="secondary" onClick={onJourney}>See journey</Button>
          <Button size="large" onClick={onHome}>Back home</Button>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// JOURNEY MAP — all 28 letters
// ============================================================================
function JourneyScreen({ progress, onPickCurrent }) {
  const masteredCount = Object.keys(progress.letterStars || {}).length;
  return (
    <div style={{ padding: 40, height: '100%', boxSizing: 'border-box', display: 'flex', flexDirection: 'column' }}>
      <Eyebrow>Letters &amp; Writing</Eyebrow>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 16, marginTop: 4 }}>
        <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 36, color: 'var(--fg)' }}>Your journey</div>
        <div style={{ fontFamily: 'var(--font-body)', fontSize: 16, color: 'var(--fg-muted)' }}>{masteredCount} of {LETTER_ORDER.length} letters mastered</div>
      </div>

      <div style={{ marginTop: 14, width: 360 }}>
        <ProgressBar pct={(masteredCount / LETTER_ORDER.length) * 100} />
      </div>

      <div style={{
        marginTop: 22, flex: 1, overflowY: 'auto',
        display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)',
        gap: '20px 18px', alignContent: 'start', paddingRight: 8,
      }}>
        {LETTER_ORDER.map((key, i) => {
          const L = LETTERS[key];
          const state =
              progress.letterStars[key] ? 'complete'
            : i === progress.currentIdx  ? 'current'
            : i < progress.currentIdx    ? 'locked'
            : 'future';
          return (
            <button key={key}
              onClick={state === 'current' ? onPickCurrent : undefined}
              style={{ background: 'none', border: 'none', padding: 0, cursor: state === 'current' ? 'pointer' : 'default' }}>
              <JourneyNodeMini glyph={L.glyph} label={L.name} state={state} stars={progress.letterStars[key] || 0} />
            </button>
          );
        })}
      </div>
    </div>
  );
}

function JourneyNodeMini({ glyph, label, state, stars }) {
  const bg =
      state === 'complete' ? 'var(--leaf)'
    : state === 'current'  ? 'var(--ink-teal)'
    : state === 'locked'   ? '#DAD3C2'
    : '#fff';
  const fg = state === 'future' ? 'var(--slate)' : '#fff';
  const shadow =
      state === 'complete' ? '0 5px 0 #2A8A60'
    : state === 'current'  ? '0 5px 0 var(--deep-ink)'
    : state === 'locked'   ? '0 4px 0 #B8AE99'
    : 'none';
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
      <div style={{
        width: 76, height: 76, borderRadius: '50%',
        background: bg, color: fg, boxShadow: shadow,
        border: state === 'future' ? '2px dashed var(--aqua-edge)' : 'none',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'var(--font-arabic-display)', fontWeight: 600,
        fontSize: 36, direction: 'rtl', lineHeight: 1, position: 'relative',
      }}>
        {glyph}
        {state === 'complete' && stars > 0 && (
          <div style={{ position: 'absolute', top: -4, right: -4, display: 'flex', gap: 1 }}>
            {Array.from({ length: stars }).map((_, i) => <Star key={i} size={14} />)}
          </div>
        )}
      </div>
      <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 13, color: 'var(--fg)' }}>{label}</div>
    </div>
  );
}

// ============================================================================
// PARENT AREA
// ============================================================================
function ParentScreen({ progress }) {
  const days = [3, 5, 2, 6, 4, 8, 0];
  const maxStar = Math.max(...days);
  const labels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  const completed = Object.keys(progress.letterStars || {})
    .map(k => ({ key: k, ...LETTERS[k], stars: progress.letterStars[k] }))
    .sort((a, b) => LETTER_ORDER.indexOf(a.key) - LETTER_ORDER.indexOf(b.key));

  return (
    <div style={{ padding: 40, height: '100%', boxSizing: 'border-box', display: 'flex', flexDirection: 'column', gap: 20 }}>
      <Eyebrow>Parent Area · Layla</Eyebrow>
      <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 36, color: 'var(--fg)' }}>This week with Qalam</div>

      <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: 20, flex: 1, minHeight: 0 }}>
        <Card>
          <Eyebrow>Stars per day</Eyebrow>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 14, height: 200, marginTop: 14 }}>
            {days.map((s, i) => (
              <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
                <div style={{ fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 14, color: s ? 'var(--gold-ink)' : 'var(--fg-muted)' }}>{s || '–'}</div>
                <div style={{
                  width: '100%', minHeight: 4,
                  height: `${(s / Math.max(maxStar,1)) * 160 + 4}px`,
                  background: s ? 'var(--gold-ink)' : 'var(--parchment-edge)',
                  borderRadius: 10,
                }} />
                <div style={{ fontFamily: 'var(--font-body)', fontSize: 13, color: 'var(--fg-muted)' }}>{labels[i]}</div>
              </div>
            ))}
          </div>

          <div style={{ marginTop: 18, padding: 16, background: 'var(--teal-tint)', borderRadius: 16, display: 'flex', gap: 14, alignItems: 'flex-start' }}>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 24, color: 'var(--deep-ink)', lineHeight: 1 }}>{Icon.pen}</div>
            <div style={{ fontFamily: 'var(--font-body)', fontSize: 15, color: 'var(--fg)', lineHeight: 1.5 }}>
              Layla has mastered <strong>{completed.length} letter{completed.length === 1 ? '' : 's'}</strong>. Stroke order is steady; keep practicing the harder letters together.
            </div>
          </div>
        </Card>

        <Card aqua style={{ display: 'flex', flexDirection: 'column' }}>
          <Eyebrow>Letters Mastered</Eyebrow>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 12, overflowY: 'auto', flex: 1 }}>
            {completed.length === 0 && (
              <div style={{ fontFamily: 'var(--font-body)', fontSize: 14, color: 'var(--fg-muted)' }}>No letters mastered yet. Layla will start with <strong style={{ color: 'var(--fg)' }}>alif</strong>.</div>
            )}
            {completed.map(l => (
              <div key={l.key} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '8px 12px', background: '#fff', borderRadius: 14 }}>
                <div dir="rtl" style={{ width: 36, height: 36, borderRadius: 12, background: 'var(--teal-tint)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'var(--font-arabic-display)', fontWeight: 600, fontSize: 22, color: 'var(--deep-ink)', lineHeight: 1 }}>{l.glyph}</div>
                <div style={{ flex: 1, fontFamily: 'var(--font-display)', fontWeight: 500, fontSize: 16, color: 'var(--fg)' }}>The letter {l.name}</div>
                <div style={{ display: 'flex', gap: 3 }}>
                  {Array.from({ length: 3 }).map((_, i) => <Star key={i} size={16} filled={i < l.stars} />)}
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}

Object.assign(window, {
  HomeScreen, DemoScreen, TraceScreen, CompleteScreen, JourneyScreen, ParentScreen,
});
