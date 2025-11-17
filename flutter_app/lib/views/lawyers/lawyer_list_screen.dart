import 'package:flutter/material.dart';
import '../../widgets/common/app_card.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class LawyerListScreen extends StatefulWidget {
  const LawyerListScreen({super.key});

  @override
  State<LawyerListScreen> createState() => _LawyerListScreenState();
}

class _LawyerListScreenState extends State<LawyerListScreen> {
  // This would normally fetch from API
  // For now, showing scaffold structure

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Lawyer'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        children: [
          // Search bar placeholder
          TextField(
            decoration: InputDecoration(
              hintText: 'Search lawyers...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  // Show filter dialog
                },
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          // Sample lawyer card - would be replaced with API data
          AppCard(
            onTap: () {
              // Navigate to lawyer detail
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryColor,
                      child: const Icon(Icons.person, size: 30),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lawyer Name',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Criminal Law, Civil Law',
                            style: Theme.of(context).textTheme.bodySmall,
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
                    Text(
                      'Rating: 4.5 ⭐',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Rs. 2000/hr',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingM),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to booking screen
                      // This would use actual lawyer data from API
                    },
                    child: const Text('Book Appointment'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

