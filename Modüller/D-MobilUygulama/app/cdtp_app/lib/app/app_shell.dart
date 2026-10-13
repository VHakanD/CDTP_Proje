import 'package:flutter/material.dart';

import '../features/connection/presentation/connection_badge.dart';
import '../features/connection/presentation/connection_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/reports/presentation/reports_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/tasks/presentation/task_select_page.dart';

/// Ana menu modulleri. Yeni modul eklemek icin buraya bir satir eklenir.
enum AppSection {
  dashboard('Panel', Icons.speed_outlined, Icons.speed),
  test('Test', Icons.play_circle_outline, Icons.play_circle),
  reports('Kayıtlar', Icons.fact_check_outlined, Icons.fact_check),
  connection('Bağlantı', Icons.wifi_tethering_outlined, Icons.wifi_tethering),
  settings('Ayarlar', Icons.settings_outlined, Icons.settings);

  const AppSection(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Uygulama iskeleti: dar ekranda alt menu, genis ekranda (tablet/web) yan menu.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppSection _section = AppSection.dashboard;

  void _go(AppSection s) => setState(() => _section = s);

  Widget _page(AppSection s) => switch (s) {
        AppSection.dashboard => DashboardPage(onOpenConnection: () => _go(AppSection.connection)),
        AppSection.test => const TaskSelectPage(),
        AppSection.reports => const ReportsPage(),
        AppSection.connection => const ConnectionPage(),
        AppSection.settings => const SettingsPage(),
      };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;

    // Sayfalarin durumu (kaydirma, form) sekme degisince kaybolmasin diye IndexedStack.
    final body = IndexedStack(
      index: _section.index,
      children: [
        for (final s in AppSection.values)
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: _page(s),
            ),
          ),
      ],
    );

    final appBar = AppBar(
      title: Text(_section.label),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(child: ConnectionBadge(onTap: () => _go(AppSection.connection))),
        ),
      ],
    );

    if (wide) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _section.index,
              onDestinationSelected: (i) => _go(AppSection.values[i]),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final s in AppSection.values)
                  NavigationRailDestination(
                    icon: Icon(s.icon),
                    selectedIcon: Icon(s.selectedIcon),
                    label: Text(s.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _section.index,
        onDestinationSelected: (i) => _go(AppSection.values[i]),
        destinations: [
          for (final s in AppSection.values)
            NavigationDestination(icon: Icon(s.icon), selectedIcon: Icon(s.selectedIcon), label: s.label),
        ],
      ),
    );
  }
}
