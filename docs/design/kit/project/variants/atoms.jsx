/* global React */
const { useState, useEffect } = React;

// =============================================================================
// Shared atoms (self-contained, no dependency on the main UI kit)
// =============================================================================

const STAR = (filled = true, size = 32) => (
  <svg width={size} height={size} viewBox="0 0 48 48" key={Math.random()}>
    <path
      d="M24 4.5l5.6 11.34 12.52 1.82-9.06 8.83 2.14 12.47L24 33.06l-11.2 5.9 2.14-12.47-9.06-8.83 12.52-1.82L24 4.5z"
      fill={filled ? '#F2A60C' : '#E8DFC9'}
      stroke={filled ? '#C5860A' : 'none'} strokeWidth="1.5" strokeLinejoin="round"
    />
    {filled && (
      <path d="M24 9.6l4.1 8.3 9.16 1.34-6.63 6.46 1.56 9.13L24 30.5l-8.19 4.32 1.56-9.13-6.63-6.46 9.16-1.34L24 9.6z" fill="#FBC34A"/>
    )}
  </svg>
);

const Eyebrow = ({ children }) => (
  <div style={{
    fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 13,
    letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--ink-teal)'
  }}>{children}</div>
);

const QBtn = ({ children, variant = 'primary', size = 'lg', style, icon }) => {
  const base = {
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 12,
    height: size === 'xl' ? 104 : size === 'lg' ? 80 : 64,
    padding: size === 'xl' ? '0 56px' : '0 36px',
    borderRadius: 999, border: 'none', cursor: 'pointer', whiteSpace: 'nowrap',
    fontFamily: 'var(--font-display)', fontWeight: 600,
    fontSize: size === 'xl' ? 30 : 24,
  };
  const variants = {
    primary:   { background: 'var(--ink-teal)', color: '#fff',         boxShadow: '0 5px 0 var(--deep-ink)' },
    secondary: { background: '#fff',            color: 'var(--deep-ink)', boxShadow: '0 5px 0 var(--aqua-edge)' },
    ghost:     { background: 'transparent',     color: 'var(--deep-ink)', border: '2px solid var(--aqua-edge)' },
  };
  return <button style={{ ...base, ...variants[variant], ...style }}>{icon}{children}</button>;
};

const Mascot = ({ state = 'idle', size = 200, style }) =>
  <img src={`../assets/mascot/qalam-${state}.svg`} width={size} height={size * 1.4} style={style} alt={`Qalam, ${state}`} />;

const Stars = ({ filled = 0, total = 3, size = 28, gap = 4 }) => (
  <div style={{ display: 'flex', gap }}>
    {Array.from({ length: total }).map((_, i) => STAR(i < filled, size))}
  </div>
);

// AppBar (compact)
function AppBar({ stars = 39, name = 'Layla', grade = 3, showClose = false }) {
  return (
    <div style={{
      height: 84, padding: '0 32px', display: 'flex', alignItems: 'center', gap: 16,
      background: 'var(--parchment)', borderBottom: '1px solid var(--border-soft)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
        <div style={{
          width: 56, height: 56, borderRadius: '50%', background: 'var(--teal-tint)',
          border: '2px solid var(--ink-teal)', display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 24, color: 'var(--deep-ink)',
        }}>{name[0]}</div>
        <div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 22, color: 'var(--fg)', lineHeight: 1.1 }}>{name}</div>
          <div style={{ fontFamily: 'var(--font-body)', fontSize: 14, color: 'var(--fg-muted)' }}>Grade {grade}</div>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <span style={{
        display: 'inline-flex', alignItems: 'center', gap: 8,
        background: 'var(--gold-tint)', color: '#8C5C04',
        height: 48, padding: '0 18px', borderRadius: 999,
        fontFamily: 'var(--font-display)', fontWeight: 600, fontSize: 22,
      }}>{STAR(true, 26)}{stars}</span>
      <button style={iconBtn}>{cog}</button>
      {showClose && <button style={iconBtn}>{xMark}</button>}
    </div>
  );
}
const iconBtn = {
  width: 56, height: 56, borderRadius: '50%', background: 'var(--soft-aqua)',
  border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
  color: 'var(--deep-ink)',
};
const cog = <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 0 1-4 0v-.1A1.7 1.7 0 0 0 9 19.4a1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 0 1 0-4h.1A1.7 1.7 0 0 0 4.6 9a1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1A1.7 1.7 0 0 0 9 4.6a1.7 1.7 0 0 0 1-1.5V3a2 2 0 0 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9c.3.7.97 1.1 1.5 1H21a2 2 0 0 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1Z"/></svg>;
const xMark = <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round"><path d="M6 6 18 18M18 6 6 18"/></svg>;

// Nav rail
function NavRail({ active = 'home' }) {
  const items = [['home','Home'],['journey','Journey'],['parent','Parent']];
  const icons = {
    home: <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 11 12 4l9 7v9a2 2 0 0 1-2 2h-4v-7H9v7H5a2 2 0 0 1-2-2v-9Z"/></svg>,
    journey: <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="m3 6 6-2 6 2 6-2v14l-6 2-6-2-6 2V6Z"/><path d="M9 4v16M15 6v16"/></svg>,
    parent: <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-7 8-7s8 3 8 7"/></svg>,
  };
  return (
    <div style={{
      position: 'absolute', top: 84, left: 0, bottom: 0, width: 100,
      background: 'var(--parchment)', borderRight: '1px solid var(--border-soft)',
      display: 'flex', flexDirection: 'column', alignItems: 'center', paddingTop: 24, gap: 18,
    }}>
      {items.map(([id, label]) => {
        const isActive = id === active;
        return (
          <div key={id} style={{
            width: 76, height: 76, borderRadius: 22,
            display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 4,
            background: isActive ? 'var(--teal-tint)' : 'transparent',
            color: isActive ? 'var(--deep-ink)' : 'var(--slate)',
            fontFamily: 'var(--font-display)', fontWeight: 500, fontSize: 13,
          }}>{icons[id]}<span>{label}</span></div>
        );
      })}
    </div>
  );
}

// Stage shell — 1280×900 tablet, with appbar + rail + content area
function Stage({ children, navActive = 'home', showClose = false, stars = 39 }) {
  return (
    <div style={{ width: 1280, height: 900, background: 'var(--parchment)', position: 'relative', overflow: 'hidden' }}>
      <AppBar stars={stars} showClose={showClose} />
      <NavRail active={navActive} />
      <div style={{ position: 'absolute', top: 84, left: 100, right: 0, bottom: 0, overflow: 'hidden' }}>
        {children}
      </div>
    </div>
  );
}

Object.assign(window, { STAR, Eyebrow, QBtn, Mascot, Stars, AppBar, NavRail, Stage });
