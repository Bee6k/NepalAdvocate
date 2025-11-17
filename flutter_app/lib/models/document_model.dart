enum DocumentCategory {
  contract('contract'),
  legalDocument('legal_document'),
  evidence('evidence'),
  other('other');

  final String value;
  const DocumentCategory(this.value);

  static DocumentCategory fromString(String value) {
    return DocumentCategory.values.firstWhere(
      (cat) => cat.value == value,
      orElse: () => DocumentCategory.other,
    );
  }
}

class DocumentModel {
  final String id;
  final String ownerId;
  final String? appointmentId;
  final String fileName;
  final String originalName;
  final String filePath;
  final int fileSize;
  final String mimeType;
  final String? description;
  final DocumentCategory category;
  final bool isShared;
  final List<String> sharedWith;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentModel({
    required this.id,
    required this.ownerId,
    this.appointmentId,
    required this.fileName,
    required this.originalName,
    required this.filePath,
    required this.fileSize,
    required this.mimeType,
    this.description,
    this.category = DocumentCategory.other,
    this.isShared = false,
    this.sharedWith = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['_id'] ?? json['id'] ?? '',
      ownerId: json['owner'] is String
          ? json['owner']
          : json['owner']?['_id'] ?? json['owner']?['id'] ?? '',
      appointmentId: json['appointment']?.toString(),
      fileName: json['fileName'] ?? '',
      originalName: json['originalName'] ?? '',
      filePath: json['filePath'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      mimeType: json['mimeType'] ?? '',
      description: json['description'],
      category: DocumentCategory.fromString(json['category'] ?? 'other'),
      isShared: json['isShared'] ?? false,
      sharedWith: json['sharedWith'] != null
          ? List<String>.from(json['sharedWith'])
          : [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'description': description,
      'category': category.value,
    };
  }
}

