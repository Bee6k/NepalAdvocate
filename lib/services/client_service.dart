import '../core/utils/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class ClientWithStats {
  final UserModel client;
  final int totalAppointments;
  final int pendingAppointments;
  final int confirmedAppointments;
  final int completedAppointments;
  final DateTime lastAppointmentDate;

  ClientWithStats({
    required this.client,
    required this.totalAppointments,
    required this.pendingAppointments,
    required this.confirmedAppointments,
    required this.completedAppointments,
    required this.lastAppointmentDate,
  });

  factory ClientWithStats.fromJson(Map<String, dynamic> json) {
    return ClientWithStats(
      client: UserModel.fromJson(json['client']),
      totalAppointments: json['totalAppointments'] ?? 0,
      pendingAppointments: json['pendingAppointments'] ?? 0,
      confirmedAppointments: json['confirmedAppointments'] ?? 0,
      completedAppointments: json['completedAppointments'] ?? 0,
      lastAppointmentDate: DateTime.parse(json['lastAppointmentDate']),
    );
  }
}

class ClientService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ClientWithStats>> getMyClients() async {
    try {
      final response = await _apiClient.get(ApiConstants.myClients);

      if (response.data['success'] == true) {
        final clients = response.data['data']['clients'] as List;
        return clients.map((json) => ClientWithStats.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}

