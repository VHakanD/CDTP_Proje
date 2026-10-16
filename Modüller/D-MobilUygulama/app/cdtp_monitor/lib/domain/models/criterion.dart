enum CriterionResult { pass, fail, info }

enum Verdict {
  pass('GEÇTİ'),
  fail('KALDI');

  const Verdict(this.label);
  final String label;
}

/// Sonuç ekranındaki tek ölçüt satırı (wireframe 06).
class Criterion {
  const Criterion({
    required this.name,
    required this.measured,
    required this.target,
    required this.result,
    this.reason,
  });

  final String name;
  final String measured;
  final String target;
  final CriterionResult result;
  final String? reason;

  Map<String, dynamic> toJson() => {
        'name': name,
        'measured': measured,
        'target': target,
        'result': result.name,
        if (reason != null) 'reason': reason,
      };

  factory Criterion.fromJson(Map<String, dynamic> j) => Criterion(
        name: j['name'] as String,
        measured: j['measured'] as String,
        target: j['target'] as String,
        result: CriterionResult.values.byName(j['result'] as String),
        reason: j['reason'] as String?,
      );
}
