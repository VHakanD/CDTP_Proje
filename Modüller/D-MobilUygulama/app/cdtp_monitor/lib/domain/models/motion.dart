import 'dart:ui' show Offset;

/// Kameradan gelen tek takip örneği. [center] görüntüde 0..1 normalize konumdur.
class TrackSample {
  const TrackSample({required this.t, required this.center, required this.confidence});

  final Duration t;
  final Offset? center;
  final double confidence;
}

enum MotionState {
  moving('hareket ediyor'),
  turning('dönüyor'),
  staticBalance('statik denge'),
  recovering('toparlanma');

  const MotionState(this.label);
  final String label;
}

enum Heading {
  forward('İLERİ'),
  backward('GERİ'),
  left('SOL'),
  right('SAĞ'),
  stopped('DURUYOR');

  const Heading(this.label);
  final String label;

  /// Görev seçiminde kullanıcıya sunulan dört yön.
  static const choices = [forward, backward, right, left];
}

enum TrackQuality { visible, weak, lost }

/// HUD'un bir anda gösterdiği hareket özeti.
class MotionSnapshot {
  const MotionSnapshot({
    required this.state,
    required this.heading,
    required this.distanceM,
    required this.quality,
    required this.confidence,
    required this.center,
    required this.trail,
  });

  static const initial = MotionSnapshot(
    state: MotionState.staticBalance,
    heading: Heading.stopped,
    distanceM: null,
    quality: TrackQuality.lost,
    confidence: 0,
    center: null,
    trail: [],
  );

  final MotionState state;
  final Heading heading;

  /// Başlangıçtan bu yana kat edilen yol (m). Ölçek yoksa `null`.
  final double? distanceM;
  final TrackQuality quality;
  final double confidence;
  final Offset? center;
  final List<Offset> trail;
}
