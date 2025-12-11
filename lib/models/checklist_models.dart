class ChecklistItem {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final String? actionRoute;
  final String? actionLabel;

  ChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    this.actionRoute,
    this.actionLabel,
  });
}

class ChecklistProgress {
  final String type; // 'prospect' or 'member'
  final List<ChecklistItem> items;
  final int completedCount;
  final int totalCount;
  final double progressPercentage;

  ChecklistProgress({
    required this.type,
    required this.items,
    required this.completedCount,
    required this.totalCount,
    required this.progressPercentage,
  });

  factory ChecklistProgress.fromJson(Map<String, dynamic> json, String type) {
    final items = (json['items'] as List?)
            ?.map((item) => ChecklistItem(
                  id: item['id'],
                  title: item['title'],
                  description: item['description'],
                  completed: item['completed'] ?? false,
                  actionRoute: item['actionRoute'],
                  actionLabel: item['actionLabel'],
                ))
            .toList() ??
        [];

    final completed = items.where((item) => item.completed).length;
    final total = items.length;
    final percentage = total > 0 ? (completed / total) * 100 : 0.0;

    return ChecklistProgress(
      type: type,
      items: items,
      completedCount: completed,
      totalCount: total,
      progressPercentage: percentage,
    );
  }
}

class RequiredReadingProgress {
  final int totalRequired;
  final int completed;
  final List<RequiredArticle> articles;

  RequiredReadingProgress({
    required this.totalRequired,
    required this.completed,
    required this.articles,
  });

  bool get isComplete => totalRequired > 0 && completed == totalRequired;

  factory RequiredReadingProgress.fromJson(Map<String, dynamic> json) {
    return RequiredReadingProgress(
      totalRequired: json['totalRequired'] ?? 0,
      completed: json['completed'] ?? 0,
      articles: (json['articles'] as List?)
              ?.map((a) => RequiredArticle.fromJson(a))
              .toList() ??
          [],
    );
  }
}

class RequiredArticle {
  final int id;
  final String slug;
  final String title;
  final String category;
  final bool completed;

  RequiredArticle({
    required this.id,
    required this.slug,
    required this.title,
    required this.category,
    required this.completed,
  });

  factory RequiredArticle.fromJson(Map<String, dynamic> json) {
    return RequiredArticle(
      id: json['id'],
      slug: json['slug'],
      title: json['title'],
      category: json['category'],
      completed: json['completed'] ?? false,
    );
  }
}
