import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../controllers/auth_controller.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/profile_picture_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class ClientProfileEditScreen extends ConsumerStatefulWidget {
  const ClientProfileEditScreen({super.key});

  @override
  ConsumerState<ClientProfileEditScreen> createState() => _ClientProfileEditScreenState();
}

class _ClientProfileEditScreenState extends ConsumerState<ClientProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = ref.read(authControllerProvider).user;
      if (user != null) {
        setState(() {
          _firstNameController.text = user.firstName;
          _lastNameController.text = user.lastName;
          _phoneController.text = user.phone ?? '';
          _emailController.text = user.email;
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
      await _authService.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
      );

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
    } on DioException catch (e) {
      String errorMessage = 'Error updating profile';
      if (e.response?.data != null && e.response!.data is Map<String, dynamic>) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
          ),
        );
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
                  isVerified: false,
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
                'Personal Information',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppConstants.spacingXL),
              
              // Email (read-only)
              AppTextField(
                label: 'Email',
                controller: _emailController,
                prefixIcon: Icons.email_outlined,
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // First Name
              AppTextField(
                label: 'First Name *',
                hint: 'Enter your first name',
                controller: _firstNameController,
                prefixIcon: Icons.person_outlined,
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // Last Name
              AppTextField(
                label: 'Last Name *',
                hint: 'Enter your last name',
                controller: _lastNameController,
                prefixIcon: Icons.person_outlined,
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // Phone
              AppTextField(
                label: 'Phone Number',
                hint: 'Enter your phone number (optional)',
                controller: _phoneController,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppConstants.spacingXL),
              
              // Save Button
              AppButton(
                text: 'Save Changes',
                onPressed: _saveProfile,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

