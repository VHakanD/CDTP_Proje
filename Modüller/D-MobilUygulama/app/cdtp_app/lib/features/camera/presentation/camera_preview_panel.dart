import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/pending_block.dart';
import '../../../core/widgets/status_chip.dart';
import '../application/camera_session_controller.dart';

/// Test ekranindaki kamera onizleme alani.
/// Kayit sirasinda sol ustte "KAYIT" etiketi ve [overlay] (sayac) gosterilir.
class CameraPreviewPanel extends ConsumerWidget {
  const CameraPreviewPanel({super.key, this.overlay});

  final Widget? overlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cam = ref.watch(cameraSessionProvider);
    final controller = cam.controller;

    if (cam.status == CameraStatus.initializing || cam.status == CameraStatus.idle) {
      return const PendingBlock(text: 'Kamera açılıyor', height: 220);
    }
    if (controller == null || !controller.value.isInitialized) {
      return PendingBlock(
        text: 'Kamera kullanılamıyor${cam.message == null ? '' : '\n${cam.message}'}',
        height: 220,
      );
    }

    // CameraPreview kendi en-boy oranini cihaz yonune gore ayarlar.
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          CameraPreview(controller),
          if (cam.isRecording)
            const Positioned(
              left: 10,
              top: 10,
              child: StatusChip(label: 'KAYIT', color: AppColors.fail, dense: true),
            ),
          if (overlay != null) Positioned(right: 10, top: 10, child: overlay!),
        ],
      ),
    );
  }
}
