/// Şartname §5.2'deki dört test görevi (wireframe 03).
enum TaskKind {
  staticBalance('Statik Denge', 'A', '30 s dengede kalma', '30 s dolunca ya da denge bozulunca'),
  guidance('Robot Yönlendirmesi', 'B', 'doğru yön + 0,8–1,2 m', 'robot durunca'),
  charging('Şarj Etme', 'C', 'şarj başlangıcı ≤ 5 s içinde tespit', 'şarj başlayınca'),
  integrated('Bütünleşik Görev', 'E', 'ilaç kutusu düşmeden hedefe', 'şarj başlayınca');

  const TaskKind(this.label, this.module, this.goal, this.endRule);

  final String label;
  final String module;
  final String goal;
  final String endRule;

  /// Mesafe ölçümü (piksel→metre ölçeği) gerekir mi?
  bool get needsScale => this == guidance || this == integrated;

  /// Hedef / şarj bölgesi gerekir mi?
  bool get needsTargetZone => this == charging || this == integrated;
}
