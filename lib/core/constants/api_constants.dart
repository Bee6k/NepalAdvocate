class ApiConstants {
  // Base URLs - Production (Render)
  static const String baseUrl = 'https://backend-vts8.onrender.com/api';
  
  // WebSocket URL for Socket.IO (HTTPS for production)
  static const String wsUrl = 'https://backend-vts8.onrender.com';
  
  // For local development, uncomment these and comment the above:
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  // static const String wsUrl = 'http://10.0.2.2:3000'; // Android emulator
  // For physical device: 'http://192.168.x.x:3000/api'

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/profile';

  // Appointment endpoints
  static const String appointments = '/appointments';
  static const String myAppointments = '/appointments/mine';
  static const String consultationHistory = '/appointments/history';

  // Chat endpoints
  static const String conversations = '/chat/conversations';
  static const String messages = '/chat/conversations';
  static const String findConversation = '/chat/conversation/find';

  // Document endpoints
  static const String documents = '/documents';
  static const String uploadDocument = '/documents/upload';
  static const String myDocuments = '/documents/mine';
  static const String sharedDocuments = '/documents/shared';

  // Lawyer endpoints
  static const String lawyers = '/lawyers';
  static const String myClients = '/lawyers/my-clients';

  // Template endpoints
  static const String templates = '/templates';

  // Notification endpoints
  static const String notifications = '/notifications';

  // Admin endpoints
  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
  static const String adminVerifyLawyer = '/admin/lawyers';

  // Verification endpoints
  static const String submitVerificationRequest = '/verification/request';
  static const String getVerificationStatus = '/verification/request/status';
  static const String getVerificationRequests = '/admin/verification/requests';

  // Profile endpoints
  static const String uploadProfilePicture = '/profile/picture';
  static const String deleteProfilePicture = '/profile/picture';

  // Review endpoints
  static const String reviews = '/reviews';
  static const String lawyerReviews = '/reviews/lawyer';
  static const String myReviews = '/reviews/mine';
}

