class ApiConstants {
  // Base URLs - Update these for your environment
  static const String baseUrl = 'http://10.0.2.2:3000/api'; // Use 10.0.2.2 for Android emulator
  // For physical device, use your computer's IP: 'http://192.168.x.x:3000/api'
  
  static const String wsUrl = 'http://10.0.2.2:3000'; // WebSocket URL

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // Appointment endpoints
  static const String appointments = '/appointments';
  static const String myAppointments = '/appointments/mine';

  // Chat endpoints
  static const String conversations = '/chat/conversations';
  static const String messages = '/chat/conversations';

  // Document endpoints
  static const String documents = '/documents';
  static const String uploadDocument = '/documents/upload';
  static const String myDocuments = '/documents/mine';

  // Lawyer endpoints
  static const String lawyers = '/lawyers';

  // Template endpoints
  static const String templates = '/templates';

  // Notification endpoints
  static const String notifications = '/notifications';

  // Admin endpoints
  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
}

