import 'package:flutter/material.dart';

import '../theme.dart';

/// Küçük gri bölüm etiketi (wireframe'deki "Şarj ve pil" gibi).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.mid)),
      );
}

/// İnce çerçeveli kutu; [dashed] uyarı / boş durum için.
class WfBox extends StatelessWidget {
  const WfBox({super.key, required this.child, this.dashed = false, this.padding = const EdgeInsets.all(10)});
  final Widget child;
  final bool dashed;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: dashed ? Colors.transparent : AppColors.surface,
          border: Border.all(color: dashed ? AppColors.warn : AppColors.line, width: dashed ? 1.2 : 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: child,
      );
}

class KvRow extends StatelessWidget {
  const KvRow(this.k, this.v, {super.key, this.bold = false});
  final String k;
  final String v;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text(k, style: const TextStyle(color: AppColors.mid))),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        ]),
      );
}

/// `[x] Robot bulundu` satırı.
class CheckLine extends StatelessWidget {
  const CheckLine(this.text, {super.key, required this.done});
  final String text;
  final bool done;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(done ? '[x] ' : '[ ] ', style: TextStyle(color: done ? AppColors.ink : AppColors.mid)),
          Expanded(child: Text(text, style: TextStyle(color: done ? AppColors.ink : AppColors.mid))),
        ]),
      );
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.solid = false, this.color});
  final String text;
  final bool solid;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: solid ? c : null,
        border: Border.all(color: solid ? c : AppColors.line),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: solid ? AppColors.bg : c, fontWeight: FontWeight.w700)),
    );
  }
}

/// Sayfa gövdesi: kaydırılabilir, kenar boşluklu sütun.
class WfPage extends StatelessWidget {
  const WfPage({super.key, required this.children, this.bottom});
  final List<Widget> children;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: children),
          ),
          if (bottom != null) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: bottom),
        ]),
      );
}
