import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/verified_avatar.dart';

class ProfilePicturePicker extends StatelessWidget {
  final String? currentImageUrl;
  final String? name;
  final bool isVerified;
  final double radius;
  final Function(File) onImageSelected;
  final Function()? onRemoveImage;

  const ProfilePicturePicker({
    super.key,
    this.currentImageUrl,
    this.name,
    this.isVerified = false,
    this.radius = 50,
    required this.onImageSelected,
    this.onRemoveImage,
  });

  Future<bool> _requestPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        return false;
      }
      return status.isGranted;
    } else {
      // For gallery/photos
      if (Platform.isAndroid) {
        // Try photos permission first (Android 13+)
        try {
          final photosStatus = await Permission.photos.status;
          if (photosStatus.isDenied) {
            final result = await Permission.photos.request();
            if (result.isGranted) return true;
          } else if (photosStatus.isGranted) {
            return true;
          }
        } catch (e) {
          // Photos permission not available, fall through to storage
        }
        
        // Fallback to storage permission for older Android versions
        try {
          final storageStatus = await Permission.storage.status;
          if (storageStatus.isDenied) {
            final result = await Permission.storage.request();
            return result.isGranted;
          }
          return storageStatus.isGranted;
        } catch (e) {
          // If both fail, return false
          return false;
        }
      }
      // iOS handles permissions automatically through image_picker
      return true;
    }
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      // Request permission first
      final hasPermission = await _requestPermission(source);
      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                source == ImageSource.camera
                    ? 'Camera permission is required to take photos'
                    : 'Storage permission is required to select images',
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        onImageSelected(File(image.path));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.camera);
                },
              ),
              if (currentImageUrl != null && currentImageUrl!.isNotEmpty && onRemoveImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                  title: const Text('Remove Photo', style: TextStyle(color: AppTheme.errorColor)),
                  onTap: () {
                    Navigator.pop(context);
                    onRemoveImage!();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(context),
      child: VerifiedAvatar(
        imageUrl: currentImageUrl,
        name: name,
        radius: radius,
        isVerified: isVerified,
      ),
    );
  }
}

