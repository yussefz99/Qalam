// ProgressRibbon — R→L position dots for the Letter-Unit exercise system
// (Plan 07-04). POSITION, NOT SCORE — COMPONENTS.md §5 / components.js
// ProgressRibbon / components.css `.progress-ribbon` + `.pr-dot`.
//
// ANTI-GAMIFICATION (CLAUDE.md Decided): there are NO numbers, NO streaks, NO
// running total, and the dots are NEVER gold (gold is reward-exclusive — the
// trace start-dot and the one mastery star only). Each dot is one of three
// states: done (filled teal), active (ringed teal, scaled up), or upcoming (a
// faint aqua-edge ring). It says "where you are in the section", nothing more.
//
// RTL: the dots run RIGHT-TO-LEFT (components.css `flex-direction:row-reverse`)
// so dot 0 sits on the right, matching the Arabic reading direction.

import 'package:flutter/material.dart';

import '../../../theme/qalam_tokens.dart';

/// A row of [total] position dots, with dots `0..active-1` DONE, dot [active]
/// ACTIVE, and the rest UPCOMING. Rendered right-to-left (RTL position).
class ProgressRibbon extends StatelessWidget {
  const ProgressRibbon({
    super.key,
    required this.total,
    required this.active,
  });

  /// How many positions (exercises) the current section has.
  final int total;

  /// The current position index (0-based). Dots before it are `done`, this dot
  /// is `active`, dots after it are `upcoming`.
  final int active;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    return Semantics(
      // Position information only — explicitly NOT a score (anti-gamification).
      label: 'Position ${active + 1} of $total',
      child: Row(
        // components.css `.progress-ribbon{flex-direction:row-reverse}` — R→L.
        textDirection: TextDirection.rtl,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 9), // .progress-ribbon gap:9
            _Dot(state: _stateFor(i)),
          ],
        ],
      ),
    );
  }

  _DotState _stateFor(int i) {
    if (i < active) return _DotState.done;
    if (i == active) return _DotState.active;
    return _DotState.upcoming;
  }
}

enum _DotState { done, active, upcoming }

/// One `.pr-dot`. 12×12 by default; the active dot scales to 1.3 with a soft
/// teal halo (components.css `.pr-dot.active{transform:scale(1.3);box-shadow:…}`).
class _Dot extends StatelessWidget {
  const _Dot({required this.state});

  final _DotState state;

  @override
  Widget build(BuildContext context) {
    const base = 12.0; // .pr-dot width/height:12px
    final bool active = state == _DotState.active;
    final double size = active ? base * 1.3 : base; // .active scale(1.3)

    final Color fill = switch (state) {
      _DotState.done => QalamTokens.inkTeal, // .done background:var(--ink-teal)
      _DotState.active => QalamTokens.tealTint, // .active background:teal-tint
      _DotState.upcoming => Colors.transparent, // upcoming: hollow
    };
    final Color border = switch (state) {
      _DotState.done => QalamTokens.inkTeal,
      _DotState.active => QalamTokens.inkTeal,
      _DotState.upcoming => QalamTokens.aquaEdge, // .pr-dot border:aqua-edge
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250), // .pr-dot transition .25s
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: border, width: 2), // .pr-dot border:2px
        boxShadow: active
            ? const [
                // .pr-dot.active box-shadow:0 0 0 4px rgba(22,138,143,.12)
                BoxShadow(
                  color: Color(0x1F168A8F),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
    );
  }
}
