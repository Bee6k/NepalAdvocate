import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

class AppointmentController extends StateNotifier<AsyncValue<List<AppointmentModel>>> {
  final AppointmentService _appointmentService;

  AppointmentController(this._appointmentService) : super(const AsyncValue.loading()) {
    loadAppointments();
  }

  Future<void> loadAppointments({String? status}) async {
    state = const AsyncValue.loading();
    try {
      final appointments = await _appointmentService.getMyAppointments(status: status);
      state = AsyncValue.data(appointments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<AppointmentModel?> createAppointment({
    required String lawyerId,
    required DateTime proposedDate,
    required String proposedTime,
    required String reason,
    String? notes,
  }) async {
    try {
      final appointment = await _appointmentService.createAppointment(
        lawyerId: lawyerId,
        proposedDate: proposedDate,
        proposedTime: proposedTime,
        reason: reason,
        notes: notes,
      );
      await loadAppointments();
      return appointment;
    } catch (e) {
      rethrow;
    }
  }

  Future<AppointmentModel?> proposeTime({
    required String appointmentId,
    required DateTime proposedDate,
    required String proposedTime,
  }) async {
    try {
      final appointment = await _appointmentService.proposeTime(
        appointmentId: appointmentId,
        proposedDate: proposedDate,
        proposedTime: proposedTime,
      );
      await loadAppointments();
      return appointment;
    } catch (e) {
      rethrow;
    }
  }

  Future<AppointmentModel?> acceptAppointment(String appointmentId) async {
    try {
      final appointment = await _appointmentService.acceptAppointment(appointmentId);
      await loadAppointments();
      return appointment;
    } catch (e) {
      rethrow;
    }
  }

  Future<AppointmentModel?> rejectAppointment(String appointmentId, {String? rejectionReason}) async {
    try {
      final appointment = await _appointmentService.rejectAppointment(appointmentId, rejectionReason: rejectionReason);
      await loadAppointments();
      return appointment;
    } catch (e) {
      rethrow;
    }
  }

  Future<AppointmentModel?> cancelAppointment(String appointmentId) async {
    try {
      final appointment = await _appointmentService.cancelAppointment(appointmentId);
      await loadAppointments();
      return appointment;
    } catch (e) {
      rethrow;
    }
  }

  Future<AppointmentModel?> confirmAppointment(String appointmentId) async {
    try {
      final appointment = await _appointmentService.confirmAppointment(appointmentId);
      await loadAppointments();
      return appointment;
    } catch (e) {
      rethrow;
    }
  }

  Future<AppointmentModel?> completeAppointment(String appointmentId) async {
    try {
      final appointment = await _appointmentService.completeAppointment(appointmentId);
      await loadAppointments();
      return appointment;
    } catch (e) {
      rethrow;
    }
  }
}

final consultationHistoryProvider = FutureProvider<List<AppointmentModel>>((ref) async {
  final appointmentService = ref.read(appointmentServiceProvider);
  return await appointmentService.getConsultationHistory();
});

final appointmentServiceProvider = Provider<AppointmentService>((ref) => AppointmentService());

final appointmentControllerProvider =
    StateNotifierProvider<AppointmentController, AsyncValue<List<AppointmentModel>>>((ref) {
  return AppointmentController(ref.read(appointmentServiceProvider));
});

