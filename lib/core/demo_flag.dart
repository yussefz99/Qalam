// The single shared DEMO compile-time flag.
//
// Pass `--dart-define=DEMO=true` to boot the app into the presentation demo
// walkthrough (phase 02.1.1) AND to reveal demo-only presenter chrome (e.g. the
// 17.2 "Teacher's Eye" diagnostic strip in the exercise scaffold). Real UAT /
// child-facing builds OMIT the flag, so all demo chrome disappears — leaving the
// production surfaces (like the warm Teacher's Margin) as the single margin note.
//
// Home for the flag so both the router and the exercise scaffold read ONE
// definition (no duplicate `bool.fromEnvironment('DEMO')` literals to drift).
library;

/// True only when built with `--dart-define=DEMO=true`. Off by default.
const bool kDemoMode = bool.fromEnvironment('DEMO');
