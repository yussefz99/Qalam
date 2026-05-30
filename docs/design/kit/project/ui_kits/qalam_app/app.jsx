/* global React, ReactDOM, LETTERS, LETTER_ORDER */
/* global AppBar, NavRail, HomeScreen, DemoScreen, TraceScreen, CompleteScreen, JourneyScreen, ParentScreen */
const { useState, useEffect, useCallback } = React;

const CHILD = { name: 'Layla', grade: 3, avatar: 'L' };

// Persisted progress
const STORAGE_KEY = 'qalam.progress.v1';
const defaultProgress = {
  currentIdx: 3,              // index into LETTER_ORDER (Thaa today)
  totalStars: 39,
  letterStars: {              // key → stars (0-3) for completed letters
    alif: 3, baa: 3, taa: 3,
  },
};
function loadProgress() {
  try { const raw = localStorage.getItem(STORAGE_KEY); if (raw) return { ...defaultProgress, ...JSON.parse(raw) }; }
  catch {}
  return defaultProgress;
}
function saveProgress(p) {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(p)); } catch {}
}

function App() {
  const [screen, setScreen] = useState('home');
  const [progress, setProgress] = useState(loadProgress);

  useEffect(() => { saveProgress(progress); }, [progress]);

  // Auto-scale stage to viewport
  useEffect(() => {
    const fit = () => {
      const stage = document.querySelector('.stage');
      if (!stage) return;
      const sx = window.innerWidth / 1280;
      const sy = window.innerHeight / 900;
      stage.style.transform = `scale(${Math.min(sx, sy, 1)})`;
    };
    fit();
    window.addEventListener('resize', fit);
    return () => window.removeEventListener('resize', fit);
  }, []);

  // Current letter — what "today's lesson" points at
  const currentKey = LETTER_ORDER[progress.currentIdx] || LETTER_ORDER[0];
  const currentLetter = { key: currentKey, ...LETTERS[currentKey], idx: progress.currentIdx };

  // Next up after current
  const nextUp = (() => {
    const i = progress.currentIdx;
    return [LETTER_ORDER[i + 1], LETTER_ORDER[i + 2]]
      .filter(Boolean)
      .map(k => ({ key: k, ...LETTERS[k] }));
  })();

  // Mark a letter complete: bumps currentIdx, awards stars, persists.
  const completeLetter = useCallback((earnedStars = 3) => {
    setProgress(p => ({
      ...p,
      currentIdx: Math.min(p.currentIdx + 1, LETTER_ORDER.length - 1),
      totalStars: p.totalStars + earnedStars,
      letterStars: { ...p.letterStars, [currentKey]: earnedStars },
    }));
  }, [currentKey]);

  // Reset (for the prototype "Restart progress" affordance)
  const resetProgress = useCallback(() => {
    setProgress({ currentIdx: 0, totalStars: 0, letterStars: {} });
    setScreen('home');
  }, []);

  // Flow: home → demo → trace → complete → home
  const flow = {
    home:     () => setScreen('demo'),
    demo:     () => setScreen('trace'),
    trace:    () => setScreen('complete'),
    complete: () => { completeLetter(3); setScreen('home'); },
  };

  const inLesson = ['demo','trace'].includes(screen);
  const navActive =
      screen === 'parent'  ? 'parent'
    : screen === 'journey' ? 'journey'
    : 'home';

  return (
    <div className="stage">
      <AppBar
        child={CHILD}
        stars={progress.totalStars}
        onClose={inLesson ? () => setScreen('home') : null}
      />
      <NavRail active={navActive} onChange={setScreen} />
      <div style={{ position: 'absolute', top: 84, left: 100, right: 0, bottom: 0, overflow: 'hidden' }}>
        {screen === 'home'     && <HomeScreen     child={CHILD} progress={progress} letter={currentLetter} nextUp={nextUp} onStart={flow.home} onJourney={() => setScreen('journey')} onReset={resetProgress} />}
        {screen === 'demo'     && <DemoScreen     letter={currentLetter} onTry={flow.demo} onBack={() => setScreen('home')} />}
        {screen === 'trace'    && <TraceScreen    letter={currentLetter} onComplete={flow.trace} />}
        {screen === 'complete' && <CompleteScreen letter={currentLetter} totalStars={progress.totalStars + 3} onHome={flow.complete} onJourney={() => { completeLetter(3); setScreen('journey'); }} />}
        {screen === 'journey'  && <JourneyScreen  progress={progress} onPickCurrent={() => setScreen('home')} />}
        {screen === 'parent'   && <ParentScreen   progress={progress} />}
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
