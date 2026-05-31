class LetterName {
  final String ar;
  final String display;

  const LetterName({required this.ar, required this.display});

  factory LetterName.fromJson(Map<String, dynamic> json) =>
      LetterName(ar: json['ar'] as String, display: json['display'] as String);
}

class LetterForms {
  final String isolated;
  final String initial;
  final String medial;
  final String final_; // 'final' is a reserved keyword

  const LetterForms({
    required this.isolated,
    required this.initial,
    required this.medial,
    required this.final_,
  });

  factory LetterForms.fromJson(Map<String, dynamic> json) => LetterForms(
        isolated: json['isolated'] as String,
        initial: json['initial'] as String,
        medial: json['medial'] as String,
        final_: json['final'] as String,
      );
}

class StrokeSpec {
  final int order;
  final String label;
  final List<List<double>> points; // normalized 0..1 coordinate pairs
  final String direction;

  const StrokeSpec({
    required this.order,
    required this.label,
    required this.points,
    required this.direction,
  });

  factory StrokeSpec.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>;
    final points = rawPoints.map((p) {
      final pair = p as List<dynamic>;
      return [(pair[0] as num).toDouble(), (pair[1] as num).toDouble()];
    }).toList();
    return StrokeSpec(
      order: json['order'] as int,
      label: json['label'] as String,
      points: points,
      direction: json['direction'] as String,
    );
  }
}

class CommonMistake {
  final String id;
  final String check; // maps to named predicates in geometric scorer (Phase 3)
  final String feedback; // child-friendly, warm, specific (the tutor's voice)

  const CommonMistake({
    required this.id,
    required this.check,
    required this.feedback,
  });

  factory CommonMistake.fromJson(Map<String, dynamic> json) => CommonMistake(
        id: json['id'] as String,
        check: json['check'] as String,
        feedback: json['feedback'] as String,
      );
}

class AudioRef {
  final String? letter; // asset path or null (Phase 7 fills)
  final List<String> examples;

  const AudioRef({this.letter, required this.examples});

  factory AudioRef.fromJson(Map<String, dynamic> json) {
    final raw = json['examples'] as List<dynamic>? ?? [];
    return AudioRef(
      letter: json['letter'] as String?,
      examples: raw.map((e) => e as String).toList(),
    );
  }
}

class Letter {
  final String id;
  final String char;
  final LetterName name;
  final int introOrder;
  final LetterForms forms;
  final List<StrokeSpec> referenceStrokes;
  final int cleanRepsToAdvance;
  final List<CommonMistake> commonMistakes;
  final String mistakesStatus; // "authored" | "placeholder"
  final bool signedOff;
  final AudioRef? audio;

  const Letter({
    required this.id,
    required this.char,
    required this.name,
    required this.introOrder,
    required this.forms,
    required this.referenceStrokes,
    required this.cleanRepsToAdvance,
    required this.commonMistakes,
    required this.mistakesStatus,
    required this.signedOff,
    this.audio,
  });

  factory Letter.fromJson(Map<String, dynamic> json) {
    final rawStrokes = json['referenceStrokes'] as List<dynamic>? ?? [];
    final rawMistakes = json['commonMistakes'] as List<dynamic>? ?? [];
    final audioJson = json['audio'] as Map<String, dynamic>?;
    return Letter(
      id: json['id'] as String,
      char: json['char'] as String,
      name: LetterName.fromJson(json['name'] as Map<String, dynamic>),
      introOrder: json['introOrder'] as int,
      forms: LetterForms.fromJson(json['forms'] as Map<String, dynamic>),
      referenceStrokes: rawStrokes
          .map((s) => StrokeSpec.fromJson(s as Map<String, dynamic>))
          .toList(),
      cleanRepsToAdvance: json['cleanRepsToAdvance'] as int,
      commonMistakes: rawMistakes
          .map((m) => CommonMistake.fromJson(m as Map<String, dynamic>))
          .toList(),
      mistakesStatus: json['mistakesStatus'] as String,
      signedOff: json['signedOff'] as bool,
      audio: audioJson != null ? AudioRef.fromJson(audioJson) : null,
    );
  }
}
