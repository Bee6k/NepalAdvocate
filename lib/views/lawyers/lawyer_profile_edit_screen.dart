import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../services/profile_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/profile_picture_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/lawyer_service.dart';
import '../../services/verification_service.dart';
import '../../core/utils/api_client.dart';
import '../../core/utils/number_formatter.dart';

class LawyerProfileEditScreen extends ConsumerStatefulWidget {
  const LawyerProfileEditScreen({super.key});

  @override
  ConsumerState<LawyerProfileEditScreen> createState() => _LawyerProfileEditScreenState();
}

class _LawyerProfileEditScreenState extends ConsumerState<LawyerProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _barLicenseController = TextEditingController();
  final _experienceController = TextEditingController();
  
  final LawyerService _lawyerService = LawyerService();
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  
  List<String> _selectedSpecializations = [];
  int? _experience;
  double? _hourlyRate;
  String? _barLicenseNumber;
  String? _bio;

  final List<String> _availableSpecializations = [
    'Criminal Law',
    'Civil Law',
    'Corporate Law',
    'Family Law',
    'Property Law',
    'Tax Law',
    'Immigration Law',
    'Labor Law',
    'Intellectual Property',
    'Constitutional Law',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _hourlyRateController.dispose();
    _barLicenseController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = ref.read(authControllerProvider).user;
      if (user?.lawyerProfile != null) {
        final profile = user!.lawyerProfile!;
        setState(() {
          _selectedSpecializations = List<String>.from(profile.specialization);
          _experience = profile.experience;
          _hourlyRate = profile.hourlyRate;
          _barLicenseNumber = profile.barLicenseNumber;
          _bio = profile.bio;
          
          _experienceController.text = profile.experience.toString();
          _hourlyRateController.text = profile.hourlyRate.toStringAsFixed(0);
          _barLicenseController.text = profile.barLicenseNumber ?? '';
          _bioController.text = profile.bio ?? '';
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(authControllerProvider).user;
      final hasExistingProfile = user?.lawyerProfile != null;
      final isVerified = user?.lawyerProfile?.isVerified ?? false;
      
      final updateData = <String, dynamic>{
        'specialization': _selectedSpecializations,
        'experience': _experience ?? 0,
        'bio': _bioController.text.trim(),
      };

      // Only include hourly rate if lawyer is verified or creating new profile
      if (isVerified || !hasExistingProfile) {
        updateData['hourlyRate'] = _hourlyRate ?? 0;
      }

      // Bar license number is required only when creating new profile
      if (!hasExistingProfile || _barLicenseController.text.trim().isNotEmpty) {
        updateData['barLicenseNumber'] = _barLicenseController.text.trim();
      }

      await _lawyerService.updateProfile(updateData);

      // Refresh user data
      await ref.read(authControllerProvider.notifier).refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Picture
              Center(
                child: ProfilePicturePicker(
                  currentImageUrl: ref.watch(authControllerProvider).user?.profilePicture,
                  name: ref.watch(authControllerProvider).user?.fullName,
                  isVerified: ref.watch(authControllerProvider).user?.lawyerProfile?.isVerified ?? false,
                  radius: 50,
                  onImageSelected: (File imageFile) async {
                    try {
                      final profileService = ProfileService();
                      final updatedUser = await profileService.uploadProfilePicture(imageFile);
                      await ref.read(authControllerProvider.notifier).refreshUser();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile picture updated successfully'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    }
                  },
                  onRemoveImage: ref.watch(authControllerProvider).user?.profilePicture != null &&
                          ref.watch(authControllerProvider).user!.profilePicture!.isNotEmpty
                      ? () async {
                          try {
                            final profileService = ProfileService();
                            await profileService.deleteProfilePicture();
                            await ref.read(authControllerProvider.notifier).refreshUser();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile picture removed successfully'),
                                  backgroundColor: AppTheme.successColor,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                            }
                          }
                        }
                      : null,
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              Text(
                'Lawyer Profile',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppConstants.spacingXL),
              
              // Bar License Number
              Builder(
                builder: (context) {
                  final user = ref.watch(authControllerProvider).user;
                  final isRequired = user?.lawyerProfile == null;
                  
                  return AppTextField(
                    label: isRequired ? 'Bar License Number *' : 'Bar License Number',
                    hint: 'Enter your bar license number',
                    controller: _barLicenseController,
                    prefixIcon: Icons.badge_outlined,
                    keyboardType: TextInputType.text,
                    validator: isRequired ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bar license number is required';
                      }
                      return null;
                    } : null,
                  );
                },
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // Specializations
              Text(
                'Specializations *',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppConstants.spacingS),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSpecializations.map((spec) {
                  final isSelected = _selectedSpecializations.contains(spec);
                  return FilterChip(
                    label: Text(spec),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSpecializations.add(spec);
                        } else {
                          _selectedSpecializations.remove(spec);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              if (_selectedSpecializations.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Please select at least one specialization',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.errorColor,
                        ),
                  ),
                ),
              const SizedBox(height: AppConstants.spacingM),
              
              // Experience
              AppTextField(
                label: 'Years of Experience *',
                hint: 'Enter years of experience',
                controller: _experienceController,
                prefixIcon: Icons.work_outline,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter years of experience';
                  }
                  final years = int.tryParse(value);
                  if (years == null || years < 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onChanged: (value) {
                  _experience = int.tryParse(value);
                },
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // Hourly Rate
              Builder(
                builder: (context) {
                  final user = ref.watch(authControllerProvider).user;
                  final isVerified = user?.lawyerProfile?.isVerified ?? false;
                  final hasExistingProfile = user?.lawyerProfile != null;
                  // Allow editing if creating new profile OR if verified
                  final canEditHourlyRate = !hasExistingProfile || isVerified;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        label: 'Hourly Rate (Rs.) *',
                        hint: 'Enter your consultation rate',
                        controller: _hourlyRateController,
                        prefixIcon: Icons.attach_money,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        readOnly: !canEditHourlyRate,
                        inputFormatters: canEditHourlyRate ? [
                          DecimalTextInputFormatter(),
                        ] : null,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your hourly rate';
                          }
                          final rate = double.tryParse(value);
                          if (rate == null || rate < 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                        onChanged: canEditHourlyRate ? (value) {
                          _hourlyRate = double.tryParse(value);
                        } : null,
                      ),
                      if (!canEditHourlyRate && hasExistingProfile)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppTheme.warningColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'You can only edit your hourly rate after your profile is verified by an admin.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.warningColor,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final verificationService = VerificationService();
                                await verificationService.submitVerificationRequest();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Verification request submitted successfully! An admin will review your profile.'),
                                      backgroundColor: AppTheme.successColor,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.verified_user),
                            label: const Text('Apply for Verification'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // Bio
              AppTextField(
                label: 'Bio',
                hint: 'Tell clients about yourself',
                controller: _bioController,
                prefixIcon: Icons.description_outlined,
                maxLines: 5,
                onChanged: (value) {
                  _bio = value;
                },
              ),
              const SizedBox(height: AppConstants.spacingXL),
              
              // Save Button
              AppButton(
                text: 'Save Profile',
                onPressed: _selectedSpecializations.isEmpty ? null : _saveProfile,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

