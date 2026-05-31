// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'curriculum_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(curriculumRepository)
final curriculumRepositoryProvider = CurriculumRepositoryProvider._();

final class CurriculumRepositoryProvider
    extends
        $FunctionalProvider<
          CurriculumRepository,
          CurriculumRepository,
          CurriculumRepository
        >
    with $Provider<CurriculumRepository> {
  CurriculumRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'curriculumRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$curriculumRepositoryHash();

  @$internal
  @override
  $ProviderElement<CurriculumRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CurriculumRepository create(Ref ref) {
    return curriculumRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CurriculumRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CurriculumRepository>(value),
    );
  }
}

String _$curriculumRepositoryHash() =>
    r'd5eb7c332e936b70f8e87ff1fe8796bc934ed552';
