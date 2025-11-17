class LegalTemplateModel {
  final String id;
  final String title;
  final String content;
  final String category;
  final String? description;
  final String? createdById;
  final bool isActive;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  LegalTemplateModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.description,
    this.createdById,
    this.isActive = true,
    this.usageCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LegalTemplateModel.fromJson(Map<String, dynamic> json) {
    return LegalTemplateModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? '',
      description: json['description'],
      createdById: json['createdBy'] is String
          ? json['createdBy']
          : json['createdBy']?['_id'] ?? json['createdBy']?['id'],
      isActive: json['isActive'] ?? true,
      usageCount: json['usageCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'description': description,
    };
  }
}

