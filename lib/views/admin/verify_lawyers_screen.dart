import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/verified_avatar.dart';
import '../../widgets/common/app_text_field.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../services/lawyer_service.dart';
import '../../controllers/lawyer_controller.dart';
import '../../core/utils/number_formatter.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

class VerifyLawyersScreen extends ConsumerStatefulWidget {
  const VerifyLawyersScreen({super.key});

  @override
  ConsumerState<VerifyLawyersScreen> createState() => _VerifyLawyersScreenState();
}

class _VerifyLawyersScreenState extends ConsumerState<VerifyLawyersScreen> {
  final LawyerFilters _filters = LawyerFilters();
  bool _showOnlyUnverified = false;

  Future<void> _verifyLawyer(String lawyerId, double? hourlyRate) async {
    try {
      final adminService = ref.read(adminServiceProvider);
      await adminService.verifyLawyer(lawyerId, hourlyRate: hourlyRate);
      
      // Refresh the lawyer list
      ref.invalidate(lawyersProvider(_filters));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lawyer verified successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying lawyer: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lawyersAsync = ref.watch(lawyersProvider(_filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Lawyers'),
      ),
      body: Column(
        children: [
          // Filter toggle
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Show only unverified lawyers',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Switch(
                  value: _showOnlyUnverified,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyUnverified = value;
                    });
                    ref.invalidate(lawyersProvider(_filters));
                  },
                ),
              ],
            ),
          ),
          // Lawyers list
          Expanded(
            child: lawyersAsync.when(
              data: (lawyers) {
                // Filter lawyers based on verification status
                final filteredLawyers = _showOnlyUnverified
                    ? lawyers.where((lawyer) => 
                        lawyer.lawyerProfile == null || 
                        !lawyer.lawyerProfile!.isVerified)
                    .toList()
                    : lawyers;

                if (filteredLawyers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showOnlyUnverified 
                              ? Icons.verified_user 
                              : Icons.person_off,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showOnlyUnverified
                              ? 'All lawyers are verified'
                              : 'No lawyers found',
                          style: Theme.of(context).textTheme.titleLarge,
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
                    itemCount: filteredLawyers.length,
                    itemBuilder: (context, index) {
                      final lawyer = filteredLawyers[index];
                      final profile = lawyer.lawyerProfile;
                      final isVerified = profile?.isVerified ?? false;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  VerifiedAvatar(
                                    imageUrl: lawyer.profilePicture,
                                    name: lawyer.fullName,
                                    radius: 30,
                                    isVerified: false,
                                  ),
                                  const SizedBox(width: AppConstants.spacingM),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                lawyer.fullName,
                                                style: Theme.of(context).textTheme.titleLarge,
                                              ),
                                            ),
                                            if (isVerified)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.successColor.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.verified,
                                                      size: 16,
                                                      color: AppTheme.successColor,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Verified',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: AppTheme.successColor,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lawyer.email,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        if (profile != null) ...[
                                          const SizedBox(height: 4),
                                          if (profile.specialization.isNotEmpty)
                                            Text(
                                              profile.specialization.join(', '),
                                              style: Theme.of(context).textTheme.bodySmall,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          if (profile.barLicenseNumber != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'License: ${profile.barLicenseNumber}',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ] else ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Profile incomplete',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppTheme.warningColor,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (!isVerified && profile != null) ...[
                                const SizedBox(height: AppConstants.spacingM),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await showDialog<Map<String, dynamic>>(
                                        context: context,
                                        builder: (context) => _VerifyLawyerDialog(
                                          lawyerName: lawyer.fullName,
                                          currentHourlyRate: profile?.hourlyRate ?? 0,
                                        ),
                                      );
                                      if (result != null && result['confirmed'] == true) {
                                        final hourlyRate = result['hourlyRate'] as double?;
                                        await _verifyLawyer(lawyer.id, hourlyRate);
                                      }
                                    },
                                    icon: const Icon(Icons.verified_user),
                                    label: const Text('Verify Lawyer'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.successColor,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
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
                      'Error loading lawyers: ${error.toString()}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.errorColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(lawyersProvider(_filters)),
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

class _VerifyLawyerDialog extends StatefulWidget {
  final String lawyerName;
  final double currentHourlyRate;

  const _VerifyLawyerDialog({
    required this.lawyerName,
    required this.currentHourlyRate,
  });

  @override
  State<_VerifyLawyerDialog> createState() => _VerifyLawyerDialogState();
}

class _VerifyLawyerDialogState extends State<_VerifyLawyerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hourlyRateController = TextEditingController();
  bool _useCurrentRate = true;

  @override
  void initState() {
    super.initState();
    _hourlyRateController.text = widget.currentHourlyRate > 0
        ? widget.currentHourlyRate.toStringAsFixed(0)
        : '';
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify Lawyer'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to verify ${widget.lawyerName}?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _useCurrentRate,
                    onChanged: (value) {
                      setState(() {
                        _useCurrentRate = value ?? true;
                        if (_useCurrentRate && widget.currentHourlyRate > 0) {
                          _hourlyRateController.text =
                              widget.currentHourlyRate.toStringAsFixed(0);
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      widget.currentHourlyRate > 0
                          ? 'Use current hourly rate (Rs. ${widget.currentHourlyRate.toStringAsFixed(0)}/hr)'
                          : 'Set hourly rate',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              if (!_useCurrentRate || widget.currentHourlyRate == 0) ...[
                const SizedBox(height: 12),
                AppTextField(
                  controller: _hourlyRateController,
                  label: 'Hourly Rate (Rs.)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    DecimalTextInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter hourly rate';
                    }
                    final rate = double.tryParse(value);
                    if (rate == null || rate < 0) {
                      return 'Please enter a valid hourly rate';
                    }
                    return null;
                  },
                  prefixIcon: Icons.attach_money,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              double? hourlyRate;
              if (!_useCurrentRate || widget.currentHourlyRate == 0) {
                hourlyRate = double.tryParse(_hourlyRateController.text);
              } else {
                hourlyRate = widget.currentHourlyRate;
              }
              Navigator.pop(context, {
                'confirmed': true,
                'hourlyRate': hourlyRate,
              });
            }
          },
          child: const Text('Verify'),
        ),
      ],
    );
  }
}

