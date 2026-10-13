/// Tek bir kriterin sonucu.
enum CriterionStatus {
  pass('Sağlandı'),
  fail('Sağlanmadı'),

  /// Kriteri olcecek veri yok (orn. kamera tespiti henuz yok, sensor bildirmiyor).
  missing('Veri yok');

  const CriterionStatus(this.label);
  final String label;
}

/// Kriterin verisinin nereden geldigi (raporda seffaflik icin).
enum DataSource {
  telemetry('Telemetri'),
  camera('Kamera'),
  timer('Süre'),
  link('Bağlantı');

  const DataSource(this.label);
  final String label;
}

/// Bir gorevin genel sonucu.
enum Verdict {
  passed('GEÇTİ'),
  failed('KALDI'),

  /// Zorunlu bir kriterin verisi yok; karar verilemedi (puanlamada KALDI sayilir).
  incomplete('EKSİK VERİ');

  const Verdict(this.label);
  final String label;
}

class CriterionResult {
  const CriterionResult({
    required this.id,
    required this.label,
    required this.expected,
    required this.measured,
    required this.status,
    required this.source,
    this.required = true,
  });

  final String id;
  final String label;
  final String expected;
  final String measured;
  final CriterionStatus status;
  final DataSource source;

  /// false ise sadece bilgi amaclidir, karari etkilemez.
  final bool required;

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'expected': expected,
        'measured': measured,
        'status': status.name,
        'source': source.name,
        'required': required,
      };

  factory CriterionResult.fromJson(Map<String, Object?> j) => CriterionResult(
        id: j['id']! as String,
        label: j['label']! as String,
        expected: j['expected']! as String,
        measured: j['measured']! as String,
        status: CriterionStatus.values.byName(j['status']! as String),
        source: DataSource.values.byName(j['source']! as String),
        required: j['required'] as bool? ?? true,
      );
}

class EvaluationResult {
  EvaluationResult(this.criteria, {Map<String, Object?>? metrics}) : metrics = metrics ?? {};

  final List<CriterionResult> criteria;

  /// Raporda gosterilen olculen degerler (sure, mesafe, yon ...).
  final Map<String, Object?> metrics;

  /// Karar kurali:
  ///  - Zorunlu kriterlerden biri saglanmadiysa -> KALDI
  ///  - Hicbiri saglanmamis degil ama biri olculemediyse -> EKSIK VERI
  ///  - Hepsi saglandiysa -> GECTI
  Verdict get verdict {
    final req = criteria.where((c) => c.required);
    if (req.any((c) => c.status == CriterionStatus.fail)) return Verdict.failed;
    if (req.any((c) => c.status == CriterionStatus.missing)) return Verdict.incomplete;
    return Verdict.passed;
  }
}
