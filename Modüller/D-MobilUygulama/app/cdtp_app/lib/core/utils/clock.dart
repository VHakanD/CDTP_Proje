import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ekrandaki "x s once" gibi bilgileri tazelemek icin yarim saniyede bir tikleyen saat.
final clockProvider = StreamProvider<DateTime>(
  (ref) => Stream.periodic(const Duration(milliseconds: 500), (_) => DateTime.now()),
);
