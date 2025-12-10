class KnowledgeArticle {
  final int id;
  final String title;
  final String slug;
  final String? summary;
  final String content;
  final String? htmlContent;
  final String category;
  final String? skillLevel;
  final List<String> tags;
  final String status;
  final bool isRequired;
  final String? author;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;

  KnowledgeArticle({
    required this.id,
    required this.title,
    required this.slug,
    this.summary,
    required this.content,
    this.htmlContent,
    required this.category,
    this.skillLevel,
    this.tags = const [],
    required this.status,
    this.isRequired = false,
    this.author,
    required this.createdAt,
    required this.updatedAt,
    this.viewCount = 0,
  });

  factory KnowledgeArticle.fromJson(Map<String, dynamic> json) {
    // Extract author username from author object or string
    String? authorName;
    if (json['author'] != null) {
      if (json['author'] is Map<String, dynamic>) {
        authorName = json['author']['username'] ?? json['author']['discordName'];
      } else if (json['author'] is String) {
        authorName = json['author'];
      }
    }
    
    return KnowledgeArticle(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      summary: json['summary'],
      content: json['content'] ?? '',
      htmlContent: json['htmlContent'],
      category: json['category'] ?? 'General',
      skillLevel: json['skillLevel'],
      tags: (json['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? [],
      status: json['status'] ?? 'Published',
      isRequired: json['isRequired'] ?? false,
      author: authorName,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      viewCount: json['viewCount'] ?? 0,
    );
  }
}
