/* global React */
const { useState, useEffect, useRef } = React;

// ============================================================================
// Atoms
// ============================================================================

function Star({ size = 32, filled = true, className = '' }) {
  return (
    <svg className={`qstar ${className}`} width={size} height={size} viewBox="0 0 48 48">
      <path
        d="M24 4.5l5.6 11.34 12.52 1.82-9.06 8.83 2.14 12.47L24 33.06l-11.2 5.9 2.14-12.47-9.06-8.83 12.52-1.82L24 4.5z"
        fill={filled ? '#F2A60C' : '#E8DFC9'}
        stroke={filled ? '#C5860A' : 'none'}
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
      {filled && (
        <path
          d="M24 9.6l4.1 8.3 9.16 1.34-6.63 6.46 1.56 9.13L24 30.5l-8.19 4.32 1.56-9.13-6.63-6.46 9.16-1.34L24 9.6z"
          fill="#FBC34A"
        />
      )}
    </svg>
  );
}

function Button({ children, variant = 'primary', size = 'md', icon, onClick, style }) {
  const cls = `qbtn${variant !== 'primary' ? ' ' + variant : ''}${size !== 'md' ? ' ' + size : ''}`;
  return (
    <button className={cls} onClick={onClick} style={style}>
      {icon}
      {children}
    </button>
  );
}

function Chip({ kind = 'info', icon, children }) {
  return <span className={`qchip ${kind}`}>{icon}{children}</span>;
}

function Card({ aqua, children, style, className = '' }) {
  return <div className={`qcard${aqua ? ' aqua' : ''} ${className}`} style={style}>{children}</div>;
}

function ProgressBar({ pct }) {
  return <div className="qprog"><div className="fill" style={{ width: `${pct}%` }} /></div>;
}

function Eyebrow({ children }) { return <div className="q-eyebrow">{children}</div>; }

// Outlined Lucide-style icons drawn inline for offline reliability
const Icon = {
  home:     <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 11 12 4l9 7v9a2 2 0 0 1-2 2h-4v-7H9v7H5a2 2 0 0 1-2-2v-9Z"/></svg>,
  map:      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="m3 6 6-2 6 2 6-2v14l-6 2-6-2-6 2V6Z"/><path d="M9 4v16M15 6v16"/></svg>,
  parent:   <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-7 8-7s8 3 8 7"/></svg>,
  settings: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 0 1-4 0v-.1A1.7 1.7 0 0 0 9 19.4a1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 0 1 0-4h.1A1.7 1.7 0 0 0 4.6 9a1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1A1.7 1.7 0 0 0 9 4.6a1.7 1.7 0 0 0 1-1.5V3a2 2 0 0 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9c.3.7.97 1.1 1.5 1H21a2 2 0 0 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1Z"/></svg>,
  close:    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M6 6 18 18M18 6 6 18"/></svg>,
  play:     <svg viewBox="0 0 24 24" fill="currentColor"><path d="M7 5v14l12-7Z"/></svg>,
  volume:   <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 10v4h4l5 4V6L8 10H4Z"/><path d="M17 8a5 5 0 0 1 0 8"/></svg>,
  back:     <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M15 18 9 12l6-6"/></svg>,
  arrow:    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14M13 6l6 6-6 6"/></svg>,
  pen:      <svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 2h8l2 6-6 14L6 8l2-6Z" opacity=".9"/><path d="M12 8v12" stroke="#F2A60C" strokeWidth="1.5" strokeLinecap="round"/></svg>,
  refresh:  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 12a9 9 0 0 1 15.5-6.3L21 8M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-15.5 6.3L3 16M3 21v-5h5"/></svg>,
};

// ============================================================================
// Mascot — uses the placeholder SVGs in assets/mascot/
// ============================================================================
function Mascot({ state = 'idle', size = 200, style }) {
  const resId = `mascot_${state.replace('-', '')}`;
  const src = (window.__resources && window.__resources[resId]) || `../../assets/mascot/qalam-${state}.svg`;
  return <img src={src} alt={`Qalam mascot, ${state}`} width={size} height={size * 1.4} style={style} />;
}

// ============================================================================
// AppBar
// ============================================================================
function AppBar({ child, stars, onClose }) {
  return (
    <div className="appbar">
      <div className="child">
        <div className="avatar">{child.avatar}</div>
        <div>
          <div className="name">{child.name}</div>
          <div className="grade">Grade {child.grade}</div>
        </div>
      </div>
      <div className="spacer" />
      <span className="star-chip"><Star size={26} />{stars}</span>
      <button className="iconbtn" aria-label="Settings">{Icon.settings}</button>
      {onClose && <button className="iconbtn" aria-label="Close" onClick={onClose}>{Icon.close}</button>}
    </div>
  );
}

// ============================================================================
// Nav Rail
// ============================================================================
function NavRail({ active, onChange }) {
  const items = [
    { id: 'home',   label: 'Home',   icon: Icon.home },
    { id: 'journey',label: 'Journey',icon: Icon.map },
    { id: 'parent', label: 'Parent', icon: Icon.parent },
  ];
  return (
    <div className="nav-rail">
      {items.map(it => (
        <button
          key={it.id}
          className={`nav-item${active === it.id ? ' active' : ''}`}
          onClick={() => onChange(it.id)}
        >
          {it.icon}
          <span>{it.label}</span>
        </button>
      ))}
    </div>
  );
}

// ============================================================================
// Lesson card
// ============================================================================
function LessonCard({ glyph, eyebrow, title, meta, stars = 0, onClick, hero = false }) {
  return (
    <div
      className="qcard"
      style={{
        display: 'flex', gap: 20, alignItems: 'center',
        padding: hero ? 32 : 20, cursor: 'pointer',
        background: hero ? '#fff' : '#fff',
      }}
      onClick={onClick}
    >
      <div style={{
        width: hero ? 140 : 84, height: hero ? 140 : 84,
        borderRadius: 24, background: 'var(--soft-aqua)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        <div dir="rtl" style={{
          fontFamily: 'var(--font-arabic-display)', fontWeight: 600,
          fontSize: hero ? 96 : 56, color: 'var(--deep-ink)', lineHeight: 1,
        }}>{glyph}</div>
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 6 }}>
        <Eyebrow>{eyebrow}</Eyebrow>
        <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: hero ? 36 : 24, color: 'var(--fg)', lineHeight: 1.15 }}>{title}</div>
        <div style={{ fontFamily: 'var(--font-body)', fontSize: hero ? 18 : 14, color: 'var(--fg-muted)' }}>{meta}</div>
      </div>
      <div style={{ display: 'flex', gap: 4 }}>
        {Array.from({ length: 3 }).map((_, i) => (
          <Star key={i} size={hero ? 32 : 22} filled={i < stars} />
        ))}
      </div>
    </div>
  );
}

// ============================================================================
// Journey node
// ============================================================================
function JourneyNode({ glyph, label, state }) {
  const cls = `journey-node ${state}`;
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
      <div className={cls} style={{
        width: 96, height: 96, borderRadius: '50%',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: 'var(--font-arabic-display)', fontWeight: 600,
        fontSize: 44, lineHeight: 1, direction: 'rtl',
        color: state === 'future' ? 'var(--slate)' : '#fff',
        background:
          state === 'complete' ? 'var(--leaf)' :
          state === 'current'  ? 'var(--ink-teal)' :
          state === 'locked'   ? '#DAD3C2' :
          '#fff',
        border: state === 'future' ? '2px dashed var(--aqua-edge)' : 'none',
        boxShadow:
          state === 'complete' ? '0 6px 0 0 #2A8A60' :
          state === 'current'  ? '0 6px 0 0 var(--deep-ink)' :
          state === 'locked'   ? '0 4px 0 0 #B8AE99' :
          'none',
        position: 'relative',
      }}>
        {state === 'locked'
          ? <span style={{ color: 'var(--slate)' }}>{glyph}</span>
          : <span>{glyph}</span>}
      </div>
      <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 16, color: 'var(--fg)' }}>{label}</div>
    </div>
  );
}

// ============================================================================
// Stylus tracing canvas — supports all 28 letters via window.LETTERS data.
// Pass `letterKey="alif"` (etc) or fall back to legacy `glyph="alif"|"baa"`.
// ============================================================================
function TracingCanvas({ letterKey, glyph, mode = 'demo', size = 500, onDone }) {
  // Resolve from the 28-letter table when available; else fall back to legacy.
  const key = letterKey || glyph || 'alif';
  const fromTable = (typeof window !== 'undefined' && window.LETTERS && window.LETTERS[key]) || null;

  const legacy = {
    alif: { strokes: ['M 300 100 L 300 500'], starts: [{ x: 300, y: 100, n: 1 }], marks: [], glyph: 'ا' },
    baa:  { strokes: ['M 130 280 Q 300 480 470 280'], starts: [{ x: 130, y: 280, n: 1 }], marks: [{ x: 300, y: 530, kind: 'dot' }], glyph: 'ب' },
  };
  const d = fromTable || legacy[key] || legacy.alif;

  const strokeRefs = useRef([]);
  const [lengths, setLengths] = useState(() => d.strokes.map(() => 800));
  const [playKey, setPlayKey] = useState(0);
  const playing = mode === 'demo';

  useEffect(() => {
    const lens = d.strokes.map((_, i) => {
      const el = strokeRefs.current[i];
      return el ? Math.ceil(el.getTotalLength()) : 800;
    });
    setLengths(lens);
  }, [key]);

  // Stagger the stroke animations so they play in order.
  let delayCursor = 0.2;

  return (
    <div style={{
      width: size, height: size,
      borderRadius: 28, background: '#fff',
      boxShadow: 'var(--shadow-md)',
      position: 'relative',
    }}>
      <svg viewBox="0 0 600 600" width={size} height={size}>
        {/* Faint guide letter sitting underneath */}
        <text
          x="300" y="430" textAnchor="middle"
          fontFamily="Noto Naskh Arabic, serif" fontSize="540" fill="#EAF4F4"
          direction="rtl"
        >{d.glyph}</text>

        {/* Dotted guide paths (all strokes) */}
        {d.strokes.map((p, i) => (
          <path key={`g${i}`} d={p}
            stroke="#B7DEDF" strokeWidth="18" strokeLinecap="round"
            strokeDasharray="2 28" fill="none"
          />
        ))}

        {/* Inked stroke (animated when demo) */}
        {d.strokes.map((p, i) => {
          const dur = 1.4;
          const delay = delayCursor; delayCursor += dur + 0.15;
          const len = lengths[i] || 800;
          return (
            <path
              key={`s${i}-${playKey}`}
              ref={el => strokeRefs.current[i] = el}
              d={p}
              stroke="#0E5B5F" strokeWidth="22" strokeLinecap="round" fill="none"
              style={{
                strokeDasharray: len,
                strokeDashoffset: playing ? len : 0,
                animation: playing ? `draw ${dur}s var(--ease-in-out) ${delay}s forwards` : 'none',
              }}
            />
          );
        })}

        {/* Identifying marks (dots above/below) */}
        {d.marks && d.marks.map((m, i) => (
          <circle key={`m${i}`} cx={m.x} cy={m.y} r="10" fill="#0E5B5F" />
        ))}

        {/* Stroke-order start dots with numbers */}
        {d.starts.map((s, i) => (
          <g key={`n${i}`}>
            <circle cx={s.x} cy={s.y} r="22" fill="#F2A60C" stroke="#fff" strokeWidth="3" />
            <text x={s.x} y={s.y + 7} textAnchor="middle"
                  fontFamily="Fredoka, sans-serif" fontWeight="600" fontSize="22" fill="#fff">
              {s.n}
            </text>
          </g>
        ))}
      </svg>

      {/* Controls (overlay bottom-right) */}
      <div style={{ position: 'absolute', right: 16, bottom: 16, display: 'flex', gap: 10 }}>
        <button className="qbtn small ghost" onClick={() => setPlayKey(k => k + 1)}>
          {Icon.refresh} Replay
        </button>
      </div>
    </div>
  );
}

// ============================================================================
// Confetti — gold sparkles for celebration
// ============================================================================
function Confetti() {
  const pieces = Array.from({ length: 18 }).map((_, i) => ({
    x: 50 + Math.random() * 1100,
    delay: Math.random() * 0.6,
    rot: Math.random() * 360,
    size: 14 + Math.random() * 18,
  }));
  return (
    <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none', overflow: 'hidden' }}>
      {pieces.map((p, i) => (
        <div key={i} className="float-up" style={{
          position: 'absolute', left: p.x, top: 600,
          width: p.size, height: p.size,
          background: i % 3 === 0 ? 'var(--ink-teal)' : 'var(--gold-ink)',
          borderRadius: i % 2 === 0 ? '50%' : 4,
          transform: `rotate(${p.rot}deg)`,
          animationDelay: `${p.delay}s`,
        }} />
      ))}
    </div>
  );
}

Object.assign(window, {
  Star, Button, Chip, Card, ProgressBar, Eyebrow, Icon,
  Mascot, AppBar, NavRail, LessonCard, JourneyNode, TracingCanvas, Confetti,
});
