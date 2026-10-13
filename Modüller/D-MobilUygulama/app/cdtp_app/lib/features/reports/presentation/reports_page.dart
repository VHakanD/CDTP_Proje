import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pending_block.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../tasks/domain/evaluation.dart';
import '../../tasks/domain/test_task.dart';
import '../../tasks/presentation/verdict_style.dart';
import '../application/report_providers.dart';
import '../domain/test_report.dart';
import 'report_detail_page.dart';

/// Kayitlar modulu: tum test raporlari, ozet ve butunluk durumu.
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  /// null = tum gorevler
  TestTask? _filter;

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(reportListProvider);
    final chain = ref.watch(chainVerificationProvider);
    final persistent = ref.watch(reportRepositoryProvider).isPersistent;

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(reportListProvider)
          ..invalidate(chainVerificationProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Özet',
            trailing: chain.when<Widget>(
              data: (v) => StatusChip(
                label: v.ok ? 'Bütünlük doğrulandı' : 'Zincir bozuk: #${v.brokenAtSeq}',
                color: v.ok ? AppColors.pass : AppColors.fail,
                dense: true,
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const StatusChip(label: 'Doğrulanamadı', color: AppColors.fail, dense: true),
            ),
            child: reports.when<Widget>(
              data: (list) => _SummaryTable(reports: list, persistent: persistent),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Kayıtlar okunamadı: $e'),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Tümü'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final t in TestTask.values)
                ChoiceChip(
                  label: Text('${t.module} · ${t.title}'),
                  selected: _filter == t,
                  onSelected: (_) => setState(() => _filter = t),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...reports.when<List<Widget>>(
            data: (list) {
              final filtered = _filter == null ? list : list.where((r) => r.task == _filter).toList();
              if (filtered.isEmpty) return [const PendingBlock(text: 'Kayıt yok')];
              return [
                for (final r in filtered)
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: _ReportRow(report: r)),
              ];
            },
            loading: () => const <Widget>[],
            error: (e, _) => const <Widget>[],
          ),
        ],
      ),
    );
  }
}

/// Gorev bazinda gecti / toplam tablosu.
class _SummaryTable extends StatelessWidget {
  const _SummaryTable({required this.reports, required this.persistent});

  final List<TestReport> reports;
  final bool persistent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    TableRow row(List<String> cells, {bool header = false}) => TableRow(
          children: [
            for (final c in cells)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text(
                  c,
                  style: header
                      ? muted?.copyWith(fontWeight: FontWeight.w700)
                      : theme.textTheme.bodyMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                ),
              ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          columnWidths: const {0: FlexColumnWidth(4)},
          border: TableBorder(horizontalInside: BorderSide(color: theme.colorScheme.outline)),
          children: [
            row(['Görev', 'Toplam', 'Geçti', 'Kaldı', 'Eksik'], header: true),
            for (final t in TestTask.values)
              row([
                '${t.module} · ${t.title}',
                reports.where((r) => r.task == t).length.toString(),
                reports.where((r) => r.task == t && r.verdict == Verdict.passed).length.toString(),
                reports.where((r) => r.task == t && r.verdict == Verdict.failed).length.toString(),
                reports.where((r) => r.task == t && r.verdict == Verdict.incomplete).length.toString(),
              ]),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          persistent
              ? 'Depolama: SQLite (telefonda kalıcı, değiştirilemez)'
              : 'Depolama: bellek (web önizleme, sayfa yenilenince silinir)',
          style: muted,
        ),
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report});

  final TestReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ReportDetailPage(report: report)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ModuleBadge(report.task.module, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.task.title, style: theme.textTheme.titleSmall),
                    Text(
                      '#${report.seq}  ·  ${Fmt.dateTime(report.startedAt)}  ·  '
                      '${Fmt.clock(Duration(milliseconds: report.durationMs))}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(label: report.verdict.label, color: verdictColor(report.verdict), dense: true),
            ],
          ),
        ),
      ),
    );
  }
}
