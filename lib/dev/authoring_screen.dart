// AuthoringScreen — the dev-only stroke authoring tool (D-02, plan 02.1-04).
//
// A dev seam where the owner (with his mother) traces a letter's strokes over a
// FAINT Noto Naskh glyph backdrop, tags each stroke (order/label/type/direction),
// and exports a normalized `referenceStrokes` JSON fragment to paste into
// assets/curriculum/letters.json. It reuses the Phase-1 Listener + smoothed
// CustomPainter capture (practice_screen.dart) so the authored data lives in the
// exact coordinate space and shape the scorer/animation consume — authored-path
// == scoring-path == animation-path by construction (S1-04).
//
// SECURITY (T-02.1-06 / T-01-05): captured points live IN MEMORY ONLY. They are
// never persisted, never `print`/`debugPrint`-logged, and are discarded on Clear
// and on dispose. The exported fragment is curriculum REFERENCE data (not child
// data), safe to copy out by hand.
//
// REACHABILITY (T-02.1-07): this is a DEBUG SEAM reachable only via the dev route
// /dev/authoring (see lib/router/app_router.dart). It is NOT surfaced in the
// child-facing navigation.

import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/colors.dart';
import '../theme/dimens.dart';
import '../theme/text_styles.dart';
import 'authoring_export.dart';

const List<String> _types = <String>['line', 'curve', 'dot'];
const List<String> _directions = <String>[
  'topToBottom',
  'bottomToTop',
  'leftToRight',
  'rightToLeft',
  'tap',
];

/// One traced + tagged stroke held in memory while authoring.
class _AuthoredStroke {
  _AuthoredStroke({
    required this.order,
    required this.label,
    required this.type,
    required this.direction,
    required this.points,
  });

  int order;
  String label;
  String type;
  String direction;
  final List<Offset> points; // raw local pixel coordinates (in-memory only)
}

class AuthoringScreen extends ConsumerStatefulWidget {
  const AuthoringScreen({super.key});

  /// Test seams.
  static const Key canvasKey = Key('authoring-canvas');
  static const Key exportButtonKey = Key('authoring-export-button');
  static const Key exportFieldKey = Key('authoring-export-field');

  @override
  ConsumerState<AuthoringScreen> createState() => _AuthoringScreenState();
}

class _AuthoringScreenState extends ConsumerState<AuthoringScreen> {
  /// The faint glyph being traced over (defaults to alif).
  String _glyph = 'ا';

  /// Completed + tagged strokes, plus the in-progress raw point list.
  final List<_AuthoredStroke> _strokes = <_AuthoredStroke>[];
  List<Offset>? _active;

  /// The most recent exported fragment (shown in a selectable field).
  String _exported = '[]';

  List<List<Offset>> get _allInk => <List<Offset>>[
        for (final s in _strokes) s.points,
        ?_active,
      ];

  void _startStroke(Offset p) => setState(() => _active = <Offset>[p]);

  void _extendStroke(Offset p) {
    final active = _active;
    if (active == null) return;
    setState(() => active.add(p));
  }

  void _endStroke() {
    final active = _active;
    if (active == null || active.isEmpty) {
      _active = null;
      return;
    }
    setState(() {
      final isDot = active.length == 1;
      _strokes.add(_AuthoredStroke(
        order: _strokes.length + 1,
        label: 'stroke_${_strokes.length + 1}',
        // A single-point tap defaults to a dot; a swipe defaults to a line.
        type: isDot ? 'dot' : 'line',
        // Default the direction from the captured endpoints so the export
        // passes the validator's DIRECTION check without manual tagging; the
        // owner can still override via the dropdown.
        direction: isDot ? 'tap' : _inferDirection(active),
        points: active,
      ));
      _active = null;
    });
  }

  /// Infers a default direction from a multi-point stroke's endpoints: the
  /// dominant axis (greater absolute delta) decides horizontal vs vertical, the
  /// sign decides the orientation. Matches the validator's first→last contract.
  String _inferDirection(List<Offset> pts) {
    final dx = pts.last.dx - pts.first.dx;
    final dy = pts.last.dy - pts.first.dy;
    if (dx.abs() >= dy.abs()) {
      return dx >= 0 ? 'leftToRight' : 'rightToLeft';
    }
    return dy >= 0 ? 'topToBottom' : 'bottomToTop';
  }

  void _clearAll() => setState(() {
        _strokes.clear();
        _active = null;
        _exported = '[]';
      });

  void _export() {
    final captured = _strokes
        .map((s) => CapturedStroke(
              order: s.order,
              label: s.label,
              type: s.type,
              direction: s.direction,
              points: s.points
                  .map((o) => <double>[o.dx, o.dy])
                  .toList(growable: false),
            ))
        .toList();
    setState(() => _exported = exportReferenceStrokesJson(captured));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QalamColors.bg,
      appBar: AppBar(
        backgroundColor: QalamColors.bg,
        title: Text('Authoring (D-02)', style: QalamTextStyles.heading),
        actions: <Widget>[
          TextButton(
            onPressed: _strokes.isNotEmpty || _active != null ? _clearAll : null,
            child: Text('Clear', style: QalamTextStyles.button),
          ),
          const SizedBox(width: QalamSpace.space4),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(QalamSpace.space4),
              child: Row(
                children: <Widget>[
                  Text('Glyph:', style: QalamTextStyles.label),
                  const SizedBox(width: QalamSpace.space3),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: _glyph,
                      textAlign: TextAlign.center,
                      onChanged: (v) =>
                          setState(() => _glyph = v.isEmpty ? ' ' : v),
                    ),
                  ),
                ],
              ),
            ),
            // The trace surface: faint glyph backdrop + live ink capture.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: QalamSpace.space4,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(QalamRadii.lg),
                  child: ColoredBox(
                    color: QalamColors.bg,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        // Faint glyph backdrop — ignore pointers so it never
                        // intercepts the trace.
                        IgnorePointer(
                          child: Center(
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Opacity(
                                opacity: 0.12,
                                child: Text(
                                  _glyph,
                                  style: const TextStyle(
                                    fontFamily: QalamFonts.arabic,
                                    fontSize: 240,
                                    color: QalamColors.fg,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        _CaptureSurface(
                          captureKey: AuthoringScreen.canvasKey,
                          ink: _allInk,
                          onStart: _startStroke,
                          onUpdate: _extendStroke,
                          onEnd: _endStroke,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Per-stroke tagging controls + export.
            _TagAndExportPanel(
              strokes: _strokes,
              exported: _exported,
              onChanged: () => setState(() {}),
              onExport: _export,
              onCopy: () => Clipboard.setData(ClipboardData(text: _exported)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Listener-based capture (reused from practice_screen): converts global →
/// local and samples points. Captures ALL pointers (finger-only authoring is
/// fine for an internal tool). Renders smoothed ink via [_InkPainter].
class _CaptureSurface extends StatelessWidget {
  const _CaptureSurface({
    required this.captureKey,
    required this.ink,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  final Key captureKey;
  final List<List<Offset>> ink;
  final ValueChanged<Offset> onStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;

  Offset _local(BuildContext context, Offset global) {
    final box = context.findRenderObject()! as RenderBox;
    return box.globalToLocal(global);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => onStart(_local(context, e.position)),
      onPointerMove: (e) => onUpdate(_local(context, e.position)),
      onPointerUp: (e) => onEnd(),
      onPointerCancel: (e) => onEnd(),
      child: CustomPaint(
        painter: _InkPainter(ink),
        child: SizedBox.expand(key: captureKey),
      ),
    );
  }
}

/// Smoothed-ink painter (mirrors practice_screen's _InkPainter).
class _InkPainter extends CustomPainter {
  _InkPainter(this.strokes);
  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = QalamColors.inkStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = QalamInk.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawPoints(PointMode.points, stroke, pen);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length - 1; i++) {
        final cur = stroke[i];
        final next = stroke[i + 1];
        final mid = Offset((cur.dx + next.dx) / 2, (cur.dy + next.dy) / 2);
        path.quadraticBezierTo(cur.dx, cur.dy, mid.dx, mid.dy);
      }
      path.lineTo(stroke.last.dx, stroke.last.dy);
      canvas.drawPath(path, pen);
    }
  }

  @override
  bool shouldRepaint(_InkPainter old) => old.strokes != strokes;
}

/// The tagging table (order/label/type/direction per stroke) + Export/Copy and
/// the selectable export field.
class _TagAndExportPanel extends StatelessWidget {
  const _TagAndExportPanel({
    required this.strokes,
    required this.exported,
    required this.onChanged,
    required this.onExport,
    required this.onCopy,
  });

  final List<_AuthoredStroke> strokes;
  final String exported;
  final VoidCallback onChanged;
  final VoidCallback onExport;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      padding: const EdgeInsets.all(QalamSpace.space4),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final s in strokes)
              Padding(
                padding: const EdgeInsets.only(bottom: QalamSpace.space2),
                child: Row(
                  children: <Widget>[
                    Text('#${s.order}', style: QalamTextStyles.label),
                    const SizedBox(width: QalamSpace.space3),
                    Expanded(
                      child: TextFormField(
                        initialValue: s.label,
                        decoration: const InputDecoration(labelText: 'label'),
                        onChanged: (v) {
                          s.label = v;
                          onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: QalamSpace.space3),
                    DropdownButton<String>(
                      value: s.type,
                      items: <DropdownMenuItem<String>>[
                        for (final t in _types)
                          DropdownMenuItem<String>(value: t, child: Text(t)),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          s.type = v;
                          onChanged();
                        }
                      },
                    ),
                    const SizedBox(width: QalamSpace.space3),
                    DropdownButton<String>(
                      value: s.direction,
                      items: <DropdownMenuItem<String>>[
                        for (final d in _directions)
                          DropdownMenuItem<String>(value: d, child: Text(d)),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          s.direction = v;
                          onChanged();
                        }
                      },
                    ),
                  ],
                ),
              ),
            Row(
              children: <Widget>[
                FilledButton(
                  key: AuthoringScreen.exportButtonKey,
                  onPressed: onExport,
                  child: const Text('Export'),
                ),
                const SizedBox(width: QalamSpace.space3),
                TextButton(onPressed: onCopy, child: const Text('Copy')),
              ],
            ),
            const SizedBox(height: QalamSpace.space3),
            SelectableText(
              exported,
              key: AuthoringScreen.exportFieldKey,
              style: QalamTextStyles.body.copyWith(fontFamily: QalamFonts.body),
            ),
          ],
        ),
      ),
    );
  }
}
