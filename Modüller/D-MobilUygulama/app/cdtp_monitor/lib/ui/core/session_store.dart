import 'package:flutter/foundation.dart';

import '../../domain/models/motion.dart';
import '../../domain/models/scene_setup.dart';
import '../../domain/models/test_task.dart';

/// Kamera görüntü oranı (genişlik / yükseklik, dik ekranda).
enum FrameRatio {
  square('1:1', 1),
  classic('4:3', 3 / 4),
  tall('9:16', 9 / 16);

  const FrameRatio(this.label, this.aspect);
  final String label;
  final double aspect;
}

/// Ekranlar arasında taşınan test hazırlığı: görev, beklenen yön, sahne, oran.
class SessionStore extends ChangeNotifier {
  TaskKind? task;
  Heading? expected;
  SceneSetup scene = const SceneSetup();
  FrameRatio ratio = FrameRatio.square;
  String? lastReportId;

  void selectTask(TaskKind t) {
    task = t;
    if (t != TaskKind.guidance) expected = null;
    notifyListeners();
  }

  void selectExpected(Heading h) {
    expected = h;
    notifyListeners();
  }

  void updateScene(SceneSetup s) {
    scene = s;
    notifyListeners();
  }

  void resetScene() => updateScene(SceneSetup(sensorAspect: scene.sensorAspect));

  void setRatio(FrameRatio r) {
    ratio = r;
    notifyListeners();
  }

  bool get taskReady => task != null && (task != TaskKind.guidance || expected != null);

  /// Sahne hazırlamada eksik adımlar (wireframe 04).
  List<String> missingSteps({required bool robotVisible}) => [
        if (!scene.phoneFixed) 'Telefonu sabitleyin',
        if (task?.needsScale == true && !scene.hasScale) 'P1 ve P2 ile ölçek alın',
        if (!robotVisible) 'Robot kadraja girmeli',
        if (task?.needsTargetZone == true && scene.targetZone == null) 'Hedef bölgeyi çizin',
      ];
}
