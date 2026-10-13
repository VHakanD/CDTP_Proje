import '../../camera/domain/motion_sample.dart';

/// Uygulamadan secilebilen dort olcum gorevi (sartname 5.2 tablosu).
enum TestTask {
  staticBalance(
    module: 'A',
    title: 'Statik Denge',
    criterion: '30 s dengede kalma',
    rubric: 'Ö1-1',
  ),
  guidance(
    module: 'B',
    title: 'Robot Yönlendirmesi',
    criterion: 'Doğru yön, 0,8–1,2 m',
    rubric: 'Ö2',
  ),
  charging(
    module: 'C',
    title: 'Şarj Etme',
    criterion: 'Şarj başlangıcı 5 s içinde tespit',
    rubric: 'Ö3-3',
  ),
  integrated(
    module: 'E',
    title: 'Bütünleşik Görev',
    criterion: 'Kutu hedefe ulaşır, şarj başlar',
    rubric: 'Ö5',
  );

  const TestTask({
    required this.module,
    required this.title,
    required this.criterion,
    required this.rubric,
  });

  /// Sartnamedeki modul harfi.
  final String module;
  final String title;
  final String criterion;

  /// Ilgili puanlama tablosu satiri.
  final String rubric;
}

/// Gorev oncesi secilen parametreler.
class TaskParams {
  const TaskParams({this.expectedDirection});

  /// Yonlendirme gorevinde beklenen yon (eldivenle verilecek komut).
  final MotionDirection? expectedDirection;

  Map<String, Object?> toJson() => {
        if (expectedDirection != null) 'expected_direction': expectedDirection!.name,
      };

  factory TaskParams.fromJson(Map<String, Object?> j) => TaskParams(
        expectedDirection: MotionDirection.values.asNameMap()[j['expected_direction']],
      );
}
