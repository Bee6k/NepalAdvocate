import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';

class VerifiedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final bool isVerified;
  final Color? backgroundColor;
  final Color? textColor;

  const VerifiedAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20,
    this.isVerified = false,
    this.backgroundColor,
    this.textColor,
  });

  String? _getImageUrl() {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    
    // If it's a data URI (base64), return as is
    if (imageUrl!.startsWith('data:image')) {
      return imageUrl;
    }
    
    // If it's already a full URL, return as is
    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      return imageUrl;
    }
    
    // If it's a file path, construct the full URL
    final baseUrlWithoutApi = ApiConstants.baseUrl.replaceAll('/api', '');
    final normalizedPath = imageUrl!.replaceAll('\\', '/');
    
    // Remove leading slash if present to avoid double slashes
    final cleanPath = normalizedPath.startsWith('/') 
        ? normalizedPath.substring(1) 
        : normalizedPath;
    
    return '$baseUrlWithoutApi/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final finalImageUrl = _getImageUrl();
    
    if (!isVerified) {
      // Simple avatar without verification badge
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? AppTheme.primaryColor.withOpacity(0.1),
        backgroundImage: finalImageUrl != null
            ? (finalImageUrl.startsWith('data:image')
                ? MemoryImage(
                    base64Decode(finalImageUrl.split(',')[1]),
                  )
                : NetworkImage(finalImageUrl))
            : null,
        child: finalImageUrl == null
            ? Text(
                (name?.isNotEmpty ?? false) ? name![0].toUpperCase() : 'U',
                style: TextStyle(
                  color: textColor ?? AppTheme.primaryColor,
                  fontSize: radius * 0.7,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      );
    }

    // Verified avatar with badge
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Verification ring (like Facebook/Twitter) - outer ring
        Container(
          width: radius * 2 + 6,
          height: radius * 2 + 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.successColor,
                AppTheme.successColor.withOpacity(0.8),
                AppTheme.successColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.successColor.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        // Main avatar
        Positioned(
          left: 3,
          top: 3,
          child: CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor ?? AppTheme.primaryColor.withOpacity(0.1),
            backgroundImage: finalImageUrl != null
                ? (finalImageUrl.startsWith('data:image')
                    ? MemoryImage(
                        base64Decode(finalImageUrl.split(',')[1]),
                      )
                    : NetworkImage(finalImageUrl))
                : null,
            child: finalImageUrl == null
                ? Text(
                    (name?.isNotEmpty ?? false) ? name![0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: textColor ?? AppTheme.primaryColor,
                      fontSize: radius * 0.7,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        // Verification badge icon - beautiful and professional
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: radius * 0.65,
            height: radius * 0.65,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.successColor,
                    AppTheme.successColor.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.verified,
                size: radius * 0.45,
                color: AppTheme.backgroundColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

