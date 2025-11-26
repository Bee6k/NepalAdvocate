import '../core/utils/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final ApiClient _apiClient = ApiClient();

  Future<AppointmentModel> createAppointment({
    required String lawyerId,
    required DateTime proposedDate,
    required String proposedTime,
    required String reason,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.appointments,
        data: {
          'lawyerId': lawyerId,
          'proposedDate': proposedDate.toIso8601String(),
          'proposedTime': proposedTime,
          'reason': reason,
          'notes': notes,
        },
      );

      if (response.data['success'] == true) {
        return AppointmentModel.fromJson(response.data['data']['appointment']);
      }
      throw Exception(response.data['message'] ?? 'Failed to create appointment');
    } catch (e) {
      rethrow;
    }
  }

  Future<AppointmentModel> proposeTime({
    required String appointmentId,
    required DateTime proposedDate,
    required String proposedTime,
  }) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.appointments}/$appointmentId/propose',
        data: {
          'proposedDate': proposedDate.toIso8601String(),
          'proposedTime': proposedTime,
        },
      );

      if (response.data['success'] == true) {
        return AppointmentModel.fromJson(response.data['data']['appointment']);
      }
      throw Exception(response.data['message'] ?? 'Failed to propose time');
    } catch (e) {
      rethrow;
    }
  }

  Future<AppointmentModel> acceptAppointment(String appointmentId) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.appointments}/$appointmentId/accept',
      );

      if (response.data['success'] == true) {
        return AppointmentModel.fromJson(response.data['data']['appointment']);
      }
      throw Exception(response.data['message'] ?? 'Failed to accept appointment');
    } catch (e) {
      rethrow;
    }
  }

  Future<AppointmentModel> rejectAppointment(String appointmentId, {String? rejectionReason}) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.appointments}/$appointmentId/reject',
        data: {
          if (rejectionReason != null) 'rejectionReason': rejectionReason,
        },
      );

      if (response.data['success'] == true) {
        return AppointmentModel.fromJson(response.data['data']['appointment']);
      }
      throw Exception(response.data['message'] ?? 'Failed to reject appointment');
    } catch (e) {
      rethrow;
    }
  }

  Future<AppointmentModel> confirmAppointment(String appointmentId) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.appointments}/$appointmentId/confirm',
      );

      if (response.data['success'] == true) {
        return AppointmentModel.fromJson(response.data['data']['appointment']);
      }
      throw Exception(response.data['message'] ?? 'Failed to confirm appointment');
    } catch (e) {
      rethrow;
    }
  }

  Future<AppointmentModel> completeAppointment(String appointmentId) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.appointments}/$appointmentId/complete',
      );

      if (response.data['success'] == true) {
        return AppointmentModel.fromJson(response.data['data']['appointment']);
      }
      throw Exception(response.data['message'] ?? 'Failed to complete consultation');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AppointmentModel>> getConsultationHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.consultationHistory,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success'] == true) {
        final appointments = response.data['data']['appointments'] as List;
        return appointments.map((json) => AppointmentModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AppointmentModel>> getMyAppointments({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.myAppointments,
        queryParameters: {
          if (status != null) 'status': status,
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success'] == true) {
        final appointments = response.data['data']['appointments'] as List;
        return appointments.map((json) => AppointmentModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<AppointmentModel> getAppointment(String appointmentId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.appointments}/$appointmentId');

      if (response.data['success'] == true) {
        return AppointmentModel.fromJson(response.data['data']['appointment']);
      }
      throw Exception(response.data['message'] ?? 'Appointment not found');
    } catch (e) {
      rethrow;
    }
  }
}

