import 'package:cdtp_robot_app/app/app.dart';
import 'package:cdtp_robot_app/features/reports/application/report_providers.dart';
import 'package:cdtp_robot_app/features/reports/domain/report_store.dart';
import 'package:cdtp_robot_app/features/settings/application/settings_controller.dart';
import 'package:cdtp_robot_app/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ana menu modulleri gorunur ve sekmeler degisir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          reportStoreProvider.overrideWithValue(InMemoryReportStore()),
        ],
        child: const CdtpApp(),
      ),
    );
    await tester.pump();

    for (final label in ['Panel', 'Test', 'Kayıtlar', 'Bağlantı', 'Ayarlar']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('Robota bağlı değil'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_circle_outline));
    await tester.pump();
    expect(find.text('Statik Denge'), findsOneWidget);
    expect(find.text('Bütünleşik Görev'), findsWidgets);
  });

  test('ayarlar JSON a yazilip geri okunur', () {
    const s = AppSettings(
      transport: TransportKind.ble,
      wsHost: '10.0.0.5',
      wsPort: 81,
      thresholds: EvaluationThresholds(distanceMinM: 0.7),
    );
    final back = AppSettings.fromJson(s.toJson());
    expect(back.transport, TransportKind.ble);
    expect(back.wsHost, '10.0.0.5');
    expect(back.wsPort, 81);
    expect(back.thresholds.distanceMinM, 0.7);
    expect(back.wsUri.toString(), 'ws://10.0.0.5:81/ws');
  });
}
