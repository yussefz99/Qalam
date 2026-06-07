// Phase 4: ML Kit MlKitRecognizer will implement this interface.
// Phase 3 deliberately leaves this unimplemented (D-16) — zero network calls.
abstract interface class HandwritingRecognizer {
  Future<RecognitionResult> identify(List<List<double>> strokePoints);
}

class RecognitionResult {
  final String? topCandidate;
  final double confidence;
  const RecognitionResult({this.topCandidate, this.confidence = 0.0});
}
