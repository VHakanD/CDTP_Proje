import 'data/repositories/robot_repository.dart';
import 'data/services/tracker/sim_tracker.dart';
import 'domain/models/motion.dart';
import 'domain/models/scene_setup.dart';
import 'domain/models/test_task.dart';
import 'ui/core/session_store.dart';

/// Yalnız web önizlemesi (Docker) için: adres çubuğundan hazırlık.
///
///   http://localhost:8080/?demo=B#/camera
///
/// - `demo=A|B|C|E`  → simülatöre bağlan, görevi seç (B için yön İLERİ),
///                     simülatör sahnesini (ölçek + hedef bölge) uygula.
/// - `ws=ws://...`   → farklı simülatör adresi (varsayılan ws://localhost:8765/ws).
/// - `ratio=1:1|4:3|9:16`
abstract final class DevPreset {
  static Future<void> apply(Uri url, RobotRepository robot, SessionStore session) async {
    final q = url.queryParameters;
    final demo = q['demo'];
    if (demo == null) return;

    final task = TaskKind.values.where((t) => t.module == demo.toUpperCase()).firstOrNull;
    if (task != null) {
      session.selectTask(task);
      if (task == TaskKind.guidance) session.selectExpected(Heading.forward);
    }
    session.updateScene(SceneSetup(
      p1: SimTracker.markerP1,
      p2: SimTracker.markerP2,
      targetZone: SimTracker.targetZone,
      start: SimTracker.origin,
      phoneFixed: true,
    ));
    final ratio = FrameRatio.values.where((r) => r.label == q['ratio']).firstOrNull;
    if (ratio != null) session.setRatio(ratio);

    // Oturum hazır olduktan sonra bağlan (kamera ekranı sahneyi baştan okusun).
    final ws = Uri.tryParse(q['ws'] ?? 'ws://localhost:8765/ws');
    if (ws != null) await robot.connect(ws);
  }
}
