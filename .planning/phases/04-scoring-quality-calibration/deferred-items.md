# Phase 04 — Deferred Items

Out-of-scope discoveries logged during execution (not fixed — outside the
current task's change surface).

| Discovered in | Item | Why deferred |
|---------------|------|--------------|
| Plan 04-04 | `mastery_celebration_golden_test.dart` golden snapshot fails (0.26%, ~1235px diff) | Pre-existing font-rendering golden drift (MEMORY: "golden tests font drift"). Not a regression — Plan 04-04 does not touch MasteryCelebration. Do NOT re-bake to "fix"; the diff is local headless-font rendering, not a real visual change. |
