class UserModel {
  final String id;
  final String email;
  final String role;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? profilePicture;
  final LawyerProfileModel? lawyerProfile;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.profilePicture,
    this.lawyerProfile,
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      profilePicture: json['profilePicture'],
      lawyerProfile: json['lawyerProfile'] != null
          ? LawyerProfileModel.fromJson(json['lawyerProfile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'profilePicture': profilePicture,
      'lawyerProfile': lawyerProfile?.toJson(),
    };
  }
}

class LawyerProfileModel {
  final String? barLicenseNumber;
  final List<String> specialization;
  final int experience;
  final double hourlyRate;
  final String? bio;
  final double rating;
  final int totalReviews;
  final bool isVerified;

  LawyerProfileModel({
    this.barLicenseNumber,
    required this.specialization,
    required this.experience,
    required this.hourlyRate,
    this.bio,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isVerified = false,
  });

  factory LawyerProfileModel.fromJson(Map<String, dynamic> json) {
    return LawyerProfileModel(
      barLicenseNumber: json['barLicenseNumber'],
      specialization: List<String>.from(json['specialization'] ?? []),
      experience: json['experience'] ?? 0,
      hourlyRate: (json['hourlyRate'] ?? 0).toDouble(),
      bio: json['bio'],
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barLicenseNumber': barLicenseNumber,
      'specialization': specialization,
      'experience': experience,
      'hourlyRate': hourlyRate,
      'bio': bio,
      'rating': rating,
      'totalReviews': totalReviews,
      'isVerified': isVerified,
    };
  }
}

enum UserRole {
  client('CLIENT'),
  lawyer('LAWYER'),
  admin('ADMIN');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.client,
    );
  }
}

