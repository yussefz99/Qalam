// TeacherMarginPanel — RED stub (Plan 18-10 Task 1).
//
// Replaced by the real implementation in the GREEN commit.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/letter.dart';

class TeacherMarginPanel extends ConsumerWidget {
  const TeacherMarginPanel({super.key, required this.letter});

  final Letter letter;

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}
