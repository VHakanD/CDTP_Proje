import 'package:flutter/material.dart';

/// Iki sutunlu (anahtar / deger) okunabilir tablo. Detay sayfalarinda kullanilir.
class KeyValueTable extends StatelessWidget {
  const KeyValueTable({super.key, required this.rows, this.keyFlex = 4, this.valueFlex = 5});

  final List<(String, String)> rows;
  final int keyFlex;
  final int valueFlex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              border: i == rows.length - 1
                  ? null
                  : Border(bottom: BorderSide(color: theme.colorScheme.outline)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: keyFlex,
                  child: Text(
                    rows[i].$1,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: valueFlex,
                  child: SelectableText(
                    rows[i].$2,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
