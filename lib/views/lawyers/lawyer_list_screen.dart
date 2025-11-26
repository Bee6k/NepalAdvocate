import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/verified_avatar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../appointments/appointment_booking_screen.dart';
import '../../models/user_model.dart';
import '../../controllers/lawyer_controller.dart';

class LawyerListScreen extends ConsumerStatefulWidget {
  const LawyerListScreen({super.key});

  @override
  ConsumerState<LawyerListScreen> createState() => _LawyerListScreenState();
}

class _LawyerListScreenState extends ConsumerState<LawyerListScreen> {
  final _searchController = TextEditingController();
  LawyerFilters _filters = LawyerFilters();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _filters = _filters.copyWith(
          search: _searchController.text.isEmpty ? null : _searchController.text,
        );
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _filters = _filters.copyWith(search: value.isEmpty ? null : value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lawyersAsync = ref.watch(lawyersProvider(_filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Lawyer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search lawyers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () {
                          // TODO: Show filter dialog
                        },
                      ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: lawyersAsync.when(
              data: (lawyers) {
                if (lawyers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No lawyers found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(lawyersProvider(_filters));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM,
                    ),
                    itemCount: lawyers.length,
                    itemBuilder: (context, index) {
                      final lawyer = lawyers[index];
                      final profile = lawyer.lawyerProfile;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                        child: AppCard(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AppointmentBookingScreen(lawyer: lawyer),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  VerifiedAvatar(
                                    imageUrl: lawyer.profilePicture,
                                    name: lawyer.fullName,
                                    radius: 30,
                                    isVerified: profile?.isVerified ?? false,
                                  ),
                                  const SizedBox(width: AppConstants.spacingM),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lawyer.fullName,
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 4),
                                        if (profile != null && profile.specialization.isNotEmpty)
                                          Text(
                                            profile.specialization.join(', '),
                                            style: Theme.of(context).textTheme.bodySmall,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        else if (profile == null)
                                          Text(
                                            'Profile pending',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.textSecondary,
                                                ),
                                          ),
                                        if (profile?.isVerified == true)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.verified,
                                                  size: 16,
                                                  color: AppTheme.successColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Verified',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: AppTheme.successColor,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppConstants.spacingM),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (profile != null)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 20,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          profile.rating > 0
                                              ? '${profile.rating.toStringAsFixed(1)} (${profile.totalReviews})'
                                              : 'No ratings',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      'New Lawyer',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                  if (profile != null && profile.hourlyRate > 0)
                                    Text(
                                      'Rs. ${profile.hourlyRate.toStringAsFixed(0)}/hr',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: AppTheme.primaryColor,
                                          ),
                                    )
                                  else if (profile == null)
                                    Text(
                                      'Rate TBD',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                ],
                              ),
                              if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
                                const SizedBox(height: AppConstants.spacingS),
                                Text(
                                  profile.bio!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: AppConstants.spacingM),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AppointmentBookingScreen(lawyer: lawyer),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                  ),
                                  child: const Text('Book Appointment'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading lawyers',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(lawyersProvider(_filters));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

