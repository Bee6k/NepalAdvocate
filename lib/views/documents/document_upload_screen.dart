import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../services/document_service.dart';
import '../../widgets/common/app_button.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/document_model.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String? appointmentId;

  const DocumentUploadScreen({super.key, this.appointmentId});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _documentService = DocumentService();
  final _descriptionController = TextEditingController();
  File? _selectedFile;
  DocumentCategory _selectedCategory = DocumentCategory.other;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file to upload'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      await _documentService.uploadDocument(
        file: _selectedFile!,
        appointmentId: widget.appointmentId,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        onProgress: (sent, total) {
          setState(() {
            _uploadProgress = sent / total;
          });
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // File Selection
              InkWell(
                onTap: _isUploading ? null : _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingXL),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    border: Border.all(
                      color: _selectedFile != null
                          ? AppTheme.primaryColor
                          : AppTheme.cardColor,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.check_circle : Icons.upload_file,
                        size: 48,
                        color: _selectedFile != null
                            ? AppTheme.successColor
                            : AppTheme.primaryColor,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Text(
                        _selectedFile != null
                            ? _selectedFile!.path.split('/').last
                            : 'Tap to select file',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              // Category Selection
              Text(
                'Category',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: DocumentCategory.values.map((category) {
                  return ChoiceChip(
                    label: Text(category.value.replaceAll('_', ' ').toUpperCase()),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppConstants.spacingL),
              // Description
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Add a description for this document',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppConstants.spacingXL),
              // Upload Progress
              if (_isUploading) ...[
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingM),
              ],
              // Upload Button
              AppButton(
                text: 'Upload Document',
                onPressed: _isUploading ? null : _uploadDocument,
                isLoading: _isUploading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

