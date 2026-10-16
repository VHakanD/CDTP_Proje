import 'package:cdtp_monitor/data/services/sim_glove_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('glove_uri_is_derived_from_robot_uri', () {
    expect(SimGloveService.gloveUriFor(Uri.parse('ws://localhost:8765/ws')).toString(), 'ws://localhost:8765/glove');
    expect(SimGloveService.gloveUriFor(Uri.parse('ws://10.0.2.2:8765/ws?x=1')).toString(), 'ws://10.0.2.2:8765/glove');
  });

  test('send_without_connection_is_noop', () {
    final g = SimGloveService()..send('forward');
    expect(g.lastCmd.value, isNull);
    expect(g.connected.value, isFalse);
  });
}
