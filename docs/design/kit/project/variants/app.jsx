/* global React, ReactDOM, DesignCanvas, DCSection, DCArtboard */
/* global HomeA, HomeB, HomeC, CelebrationA, CelebrationB, CelebrationC */

function App() {
  return (
    <DesignCanvas>
      <DCSection id="home" title="Home / Today's Lesson" subtitle="Three takes on the first screen the child sees each session.">
        <DCArtboard id="home-a" label="A · Today, served" width={1280} height={900}><HomeA /></DCArtboard>
        <DCArtboard id="home-b" label="B · The Journey speaks" width={1280} height={900}><HomeB /></DCArtboard>
        <DCArtboard id="home-c" label="C · One letter, big" width={1280} height={900}><HomeC /></DCArtboard>
      </DCSection>

      <DCSection id="celebration" title="Lesson Complete" subtitle="The reward moment — what happens after a successful lesson.">
        <DCArtboard id="cele-a" label="A · Big mascot, gold stars" width={1280} height={900}><CelebrationA /></DCArtboard>
        <DCArtboard id="cele-b" label="B · Mastered stamp" width={1280} height={900}><CelebrationB /></DCArtboard>
        <DCArtboard id="cele-c" label="C · Journey forward" width={1280} height={900}><CelebrationC /></DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
