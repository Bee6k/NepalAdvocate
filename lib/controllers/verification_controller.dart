import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/verification_service.dart';

final verificationServiceProvider = Provider<VerificationService>((ref) {
  return VerificationService();
});

final verificationStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(verificationServiceProvider);
  return await service.getVerificationStatus();
});

