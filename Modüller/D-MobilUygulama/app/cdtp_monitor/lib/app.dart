import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'ui/core/theme.dart';
import 'ui/core/widgets/sim_glove_layer.dart';

class CdtpMonitorApp extends StatelessWidget {
  const CdtpMonitorApp({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'CDTP Robot İzleme',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        routerConfig: router,
        // Simülatöre bağlıyken klavye = sanal eldiven (gerçek robotta etkisiz).
        builder: (context, child) => SimGloveLayer(child: child ?? const SizedBox.shrink()),
      );
}
