// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod Notifier: session controller keyed by lessonId.
///
/// autoDispose — the session is torn down when the practice screen is popped,
/// preventing stale state if the child re-enters the same lesson.
/// family(String lessonId) — each lesson gets its own controller instance.

@ProviderFor(PracticeSessionController)
final practiceSessionControllerProvider = PracticeSessionControllerFamily._();

/// Riverpod Notifier: session controller keyed by lessonId.
///
/// autoDispose — the session is torn down when the practice screen is popped,
/// preventing stale state if the child re-enters the same lesson.
/// family(String lessonId) — each lesson gets its own controller instance.
final class PracticeSessionControllerProvider
    extends $NotifierProvider<PracticeSessionController, PracticeState> {
  /// Riverpod Notifier: session controller keyed by lessonId.
  ///
  /// autoDispose — the session is torn down when the practice screen is popped,
  /// preventing stale state if the child re-enters the same lesson.
  /// family(String lessonId) — each lesson gets its own controller instance.
  PracticeSessionControllerProvider._({
    required PracticeSessionControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'practiceSessionControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$practiceSessionControllerHash();

  @override
  String toString() {
    return r'practiceSessionControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PracticeSessionController create() => PracticeSessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PracticeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PracticeState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeSessionControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$practiceSessionControllerHash() =>
    r'3aff2089ffc4a61802963d4122f1ea42ab00dde8';

/// Riverpod Notifier: session controller keyed by lessonId.
///
/// autoDispose — the session is torn down when the practice screen is popped,
/// preventing stale state if the child re-enters the same lesson.
/// family(String lessonId) — each lesson gets its own controller instance.

final class PracticeSessionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          PracticeSessionController,
          PracticeState,
          PracticeState,
          PracticeState,
          String
        > {
  PracticeSessionControllerFamily._()
    : super(
        retry: null,
        name: r'practiceSessionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Riverpod Notifier: session controller keyed by lessonId.
  ///
  /// autoDispose — the session is torn down when the practice screen is popped,
  /// preventing stale state if the child re-enters the same lesson.
  /// family(String lessonId) — each lesson gets its own controller instance.

  PracticeSessionControllerProvider call(String lessonId) =>
      PracticeSessionControllerProvider._(argument: lessonId, from: this);

  @override
  String toString() => r'practiceSessionControllerProvider';
}

/// Riverpod Notifier: session controller keyed by lessonId.
///
/// autoDispose — the session is torn down when the practice screen is popped,
/// preventing stale state if the child re-enters the same lesson.
/// family(String lessonId) — each lesson gets its own controller instance.

abstract class _$PracticeSessionController extends $Notifier<PracticeState> {
  late final _$args = ref.$arg as String;
  String get lessonId => _$args;

  PracticeState build(String lessonId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PracticeState, PracticeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PracticeState, PracticeState>,
              PracticeState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
