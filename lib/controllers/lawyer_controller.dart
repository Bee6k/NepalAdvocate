import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/lawyer_service.dart';

final lawyerServiceProvider = Provider<LawyerService>((ref) => LawyerService());

final lawyersProvider = FutureProvider.family<List<UserModel>, LawyerFilters>((ref, filters) async {
  final service = ref.read(lawyerServiceProvider);
  return await service.getLawyers(
    search: filters.search,
    specialization: filters.specialization,
    minRating: filters.minRating,
    page: filters.page,
    limit: filters.limit,
  );
});

class LawyerFilters {
  final String? search;
  final String? specialization;
  final double? minRating;
  final int page;
  final int limit;

  LawyerFilters({
    this.search,
    this.specialization,
    this.minRating,
    this.page = 1,
    this.limit = 20,
  });

  LawyerFilters copyWith({
    String? search,
    String? specialization,
    double? minRating,
    int? page,
    int? limit,
  }) {
    return LawyerFilters(
      search: search ?? this.search,
      specialization: specialization ?? this.specialization,
      minRating: minRating ?? this.minRating,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

