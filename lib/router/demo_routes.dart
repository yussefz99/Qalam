// The /demo route group (phase 02.1.1, DP-03/DP-04) — the navigable
// presentation walkthrough of the alif core loop.
//
// WHY THIS EXISTS: the 2026-06-02 course-staff presentation needs six
// screenshot-ready screens the presenter can tap through in narrative order,
// with NO dead ends. This file is the FIXED route map: the screen plans
// (03/04/05) replace each placeholder builder with their real widget WITHOUT
// touching the route table or each other's routers. The DemoStep chain encodes
// the FULL forward narrative — Home → Watch → Trace → Feedback·miss →
// Feedback·pass → Celebration → Home — so the clean-pass state is reachable by
// TAPPING `.next`, not only by deep link.
//
// Mocked-data demo only: no scorer, no capture, no persistence, no network
// (DP-01). The placeholder scaffolds use design-system tokens only (DP-02) so
// the group is presentation-calm even before the real screens land.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../demo/screens/demo_home_screen.dart';
import '../demo/screens/demo_trace_screen.dart';
import '../demo/screens/demo_watch_screen.dart';
import '../theme/colors.dart';
import '../theme/dimens.dart';
import '../theme/text_styles.dart';

/// The six ordered steps of the demo walkthrough (DP-04).
///
/// `feedbackMiss` is the HERO state (a specific named fix in the tutor's voice);
/// `feedbackPass` is the clean-pass praise that follows a successful retry.
enum DemoStep {
  home,
  watch,
  trace,
  feedbackMiss,
  feedbackPass,
  celebration;

  /// The `/demo/*` path this step resolves to.
  ///
  /// Feedback miss is the DEFAULT feedback step (`/demo/feedback`); the clean
  /// pass is a distinct sub-path so both states are independently routable.
  String get path {
    switch (this) {
      case DemoStep.home:
        return '/demo/home';
      case DemoStep.watch:
        return '/demo/watch';
      case DemoStep.trace:
        return '/demo/trace';
      case DemoStep.feedbackMiss:
        return '/demo/feedback';
      case DemoStep.feedbackPass:
        return '/demo/feedback/pass';
      case DemoStep.celebration:
        return '/demo/celebration';
    }
  }

  /// The next step in the narrative — the FULL forward walkthrough with NO dead
  /// ends. Critically, `feedbackMiss.next == feedbackPass` and
  /// `feedbackPass.next == celebration`, so the natural demo story (child
  /// traces, misses, retries, this time it's clean → praise → celebration) is
  /// tappable end-to-end. Celebration loops back to home.
  DemoStep get next {
    switch (this) {
      case DemoStep.home:
        return DemoStep.watch;
      case DemoStep.watch:
        return DemoStep.trace;
      case DemoStep.trace:
        return DemoStep.feedbackMiss;
      case DemoStep.feedbackMiss:
        return DemoStep.feedbackPass;
      case DemoStep.feedbackPass:
        return DemoStep.celebration;
      case DemoStep.celebration:
        return DemoStep.home;
    }
  }

  /// A short human label for the placeholder scaffold (and screenshots).
  String get label {
    switch (this) {
      case DemoStep.home:
        return 'Home';
      case DemoStep.watch:
        return 'Watch';
      case DemoStep.trace:
        return 'Trace';
      case DemoStep.feedbackMiss:
        return 'Feedback · Miss';
      case DemoStep.feedbackPass:
        return 'Feedback · Pass';
      case DemoStep.celebration:
        return 'Celebration';
    }
  }
}

/// The `/demo` route group, spread into the app router (D-08).
///
/// Each builder currently points at a calm [_DemoPlaceholder] so the walkthrough
/// is navigable end-to-end immediately. Plans 03/04/05 swap these builders for
/// the real widgets — the paths and ordering stay fixed.
List<RouteBase> demoRoutes() {
  return <RouteBase>[
    for (final DemoStep step in DemoStep.values)
      GoRoute(
        path: step.path,
        builder: (BuildContext context, GoRouterState state) =>
            _screenFor(step),
      ),
  ];
}

/// Resolves a [DemoStep] to its screen. Real screens land plan-by-plan (03/04/
/// 05) and replace their entry here; steps without a real screen yet fall back
/// to the calm [_DemoPlaceholder] so the walkthrough stays navigable end-to-end.
Widget _screenFor(DemoStep step) {
  switch (step) {
    case DemoStep.home:
      return const DemoHomeScreen();
    case DemoStep.watch:
      return const DemoWatchScreen();
    case DemoStep.trace:
      return const DemoTraceScreen();
    case DemoStep.feedbackMiss:
    case DemoStep.feedbackPass:
    case DemoStep.celebration:
      return _DemoPlaceholder(step: step);
  }
}

/// A calm parchment scaffold naming the step + a single tappable "next" CTA, so
/// the demo group is navigable before the real screens land. Tokens only
/// (DP-02): parchment background, ink-teal accent, no raw hex/magic numbers.
class _DemoPlaceholder extends StatelessWidget {
  const _DemoPlaceholder({required this.step});

  final DemoStep step;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QalamColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(QalamSpace.space8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  step.label,
                  style: QalamTextStyles.display,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: QalamSpace.space8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: QalamColors.primary,
                    minimumSize: const Size(QalamTargets.targetLarge,
                        QalamTargets.targetComfy),
                  ),
                  onPressed: () => context.go(step.next.path),
                  child: Text('Next', style: QalamTextStyles.button),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
