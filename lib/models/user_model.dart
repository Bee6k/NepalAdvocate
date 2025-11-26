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
    try {
      // Ensure all required fields are strings
      final id = (json['id'] ?? json['_id'] ?? '').toString();
      final email = (json['email'] ?? '').toString();
      final role = (json['role'] ?? '').toString();
      final firstName = (json['firstName'] ?? '').toString();
      final lastName = (json['lastName'] ?? '').toString();
      final phone = json['phone']?.toString();
      final profilePicture = json['profilePicture']?.toString();
      
      // Safely parse lawyer profile
      LawyerProfileModel? lawyerProfile;
      if (json['lawyerProfile'] != null) {
        try {
          final profileJson = json['lawyerProfile'];
          if (profileJson is Map<String, dynamic>) {
            lawyerProfile = LawyerProfileModel.fromJson(profileJson);
          }
        } catch (e) {
          print('Error parsing lawyer profile: $e');
          lawyerProfile = null;
        }
      }
      
      return UserModel(
        id: id,
        email: email,
        role: role,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        profilePicture: profilePicture,
        lawyerProfile: lawyerProfile,
      );
    } catch (e, stackTrace) {
      print('Error in UserModel.fromJson: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
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
    // Safely parse specialization - handle both List and other types
    List<String> specializationList = [];
    if (json['specialization'] != null) {
      final specialization = json['specialization'];
      if (specialization is List) {
        try {
          specializationList = specialization
              .map((item) => item?.toString() ?? '')
              .where((item) => item.isNotEmpty)
              .toList()
              .cast<String>();
        } catch (e) {
          print('Error parsing specialization list: $e');
          specializationList = [];
        }
      } else if (specialization is String) {
        specializationList = [specialization];
      } else if (specialization is Map) {
        // If it's a Map, extract values
        try {
          specializationList = specialization.values
              .map((item) => item?.toString() ?? '')
              .where((item) => item.isNotEmpty)
              .toList()
              .cast<String>();
        } catch (e) {
          print('Error parsing specialization map: $e');
          specializationList = [];
        }
      }
    }

    // Safely parse numeric fields
    int experience = 0;
    if (json['experience'] != null) {
      if (json['experience'] is int) {
        experience = json['experience'];
      } else if (json['experience'] is String) {
        experience = int.tryParse(json['experience']) ?? 0;
      } else if (json['experience'] is double) {
        experience = json['experience'].toInt();
      }
    }

    double hourlyRate = 0.0;
    if (json['hourlyRate'] != null) {
      if (json['hourlyRate'] is double) {
        hourlyRate = json['hourlyRate'];
      } else if (json['hourlyRate'] is int) {
        hourlyRate = json['hourlyRate'].toDouble();
      } else if (json['hourlyRate'] is String) {
        hourlyRate = double.tryParse(json['hourlyRate']) ?? 0.0;
      }
    }

    double rating = 0.0;
    if (json['rating'] != null) {
      if (json['rating'] is double) {
        rating = json['rating'];
      } else if (json['rating'] is int) {
        rating = json['rating'].toDouble();
      } else if (json['rating'] is String) {
        rating = double.tryParse(json['rating']) ?? 0.0;
      }
    }

    int totalReviews = 0;
    if (json['totalReviews'] != null) {
      if (json['totalReviews'] is int) {
        totalReviews = json['totalReviews'];
      } else if (json['totalReviews'] is String) {
        totalReviews = int.tryParse(json['totalReviews']) ?? 0;
      } else if (json['totalReviews'] is double) {
        totalReviews = json['totalReviews'].toInt();
      }
    }

    return LawyerProfileModel(
      barLicenseNumber: json['barLicenseNumber']?.toString(),
      specialization: specializationList,
      experience: experience,
      hourlyRate: hourlyRate,
      bio: json['bio']?.toString(),
      rating: rating,
      totalReviews: totalReviews,
      isVerified: json['isVerified'] == true || json['isVerified'] == 'true',
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

