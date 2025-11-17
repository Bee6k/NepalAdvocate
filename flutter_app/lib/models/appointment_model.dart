import 'user_model.dart';

enum AppointmentStatus {
  pending('PENDING'),
  proposed('PROPOSED'),
  confirmed('CONFIRMED'),
  cancelled('CANCELLED'),
  completed('COMPLETED');

  final String value;
  const AppointmentStatus(this.value);

  static AppointmentStatus fromString(String value) {
    return AppointmentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AppointmentStatus.pending,
    );
  }
}

class AppointmentModel {
  final String id;
  final String clientId;
  final String lawyerId;
  final UserModel? client;
  final UserModel? lawyer;
  final AppointmentStatus status;
  final DateTime proposedDate;
  final String proposedTime;
  final DateTime? confirmedDate;
  final String? confirmedTime;
  final String reason;
  final String? notes;
  final bool clientConfirmation;
  final bool lawyerConfirmation;
  final String? meetingLink;
  final String? conversationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppointmentModel({
    required this.id,
    required this.clientId,
    required this.lawyerId,
    this.client,
    this.lawyer,
    required this.status,
    required this.proposedDate,
    required this.proposedTime,
    this.confirmedDate,
    this.confirmedTime,
    required this.reason,
    this.notes,
    this.clientConfirmation = false,
    this.lawyerConfirmation = false,
    this.meetingLink,
    this.conversationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['_id'] ?? json['id'] ?? '',
      clientId: json['client'] is String
          ? json['client']
          : json['client']?['_id'] ?? json['client']?['id'] ?? '',
      lawyerId: json['lawyer'] is String
          ? json['lawyer']
          : json['lawyer']?['_id'] ?? json['lawyer']?['id'] ?? '',
      client: json['client'] is Map
          ? UserModel.fromJson(json['client'])
          : null,
      lawyer: json['lawyer'] is Map
          ? UserModel.fromJson(json['lawyer'])
          : null,
      status: AppointmentStatus.fromString(json['status'] ?? 'PENDING'),
      proposedDate: DateTime.parse(json['proposedDate']),
      proposedTime: json['proposedTime'] ?? '',
      confirmedDate: json['confirmedDate'] != null
          ? DateTime.parse(json['confirmedDate'])
          : null,
      confirmedTime: json['confirmedTime'],
      reason: json['reason'] ?? '',
      notes: json['notes'],
      clientConfirmation: json['clientConfirmation'] ?? false,
      lawyerConfirmation: json['lawyerConfirmation'] ?? false,
      meetingLink: json['meetingLink'],
      conversationId: json['conversationId']?.toString(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lawyerId': lawyerId,
      'proposedDate': proposedDate.toIso8601String(),
      'proposedTime': proposedTime,
      'reason': reason,
      'notes': notes,
    };
  }
}

