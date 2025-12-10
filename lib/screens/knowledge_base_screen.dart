import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:tficmobileapp/models/knowledge_article.dart';
import 'package:tficmobileapp/services/api_service.dart';
import 'package:tficmobileapp/config/theme.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  List<KnowledgeArticle> _articles = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String? _selectedCategory;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final categoriesData = await ApiService.getKnowledgeCategories();
      final articlesData = await ApiService.getKnowledgeArticles(
        category: _selectedCategory,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );

      if (mounted) {
        setState(() {
          _categories = categoriesData;
          _articles = articlesData.map((a) => KnowledgeArticle.fromJson(a)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading knowledge base: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Knowledge Base'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          FutureBuilder<Map<String, dynamic>?>(
            future: ApiService.getUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data?['avatarUrl'] != null) {
                final avatarUrl = snapshot.data!['avatarUrl'].toString();
                if (avatarUrl.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(
                        avatarUrl.startsWith('http') ? avatarUrl : '${ApiService.baseUrl}$avatarUrl',
                      ),
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgCard,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search articles...',
                    hintStyle: TextStyle(color: textMuted.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.search, color: textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: textMuted),
                            onPressed: () {
                              _searchController.clear();
                              _loadData();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: bgPrimary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _loadData(),
                ),
                if (_categories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('All', null),
                        ..._categories.map((category) => _buildCategoryChip(category, category)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Articles List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _articles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.library_books, size: 64, color: textMuted),
                            SizedBox(height: 16),
                            Text(
                              'No articles found',
                              style: TextStyle(color: textSecondary, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: accentBlue,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _articles.length,
                          itemBuilder: (context, index) {
                            final article = _articles[index];
                            return _buildArticleCard(article);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? value) {
    final isSelected = _selectedCategory == value;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = value;
          });
          _loadData();
        },
        backgroundColor: bgPrimary,
        selectedColor: accentBlue.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? accentBlue : textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? accentBlue : textMuted.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildArticleCard(KnowledgeArticle article) {
    final categoryColor = _getCategoryColor(article.category);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showArticleDetails(article),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.article, color: categoryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          style: const TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                article.category,
                                style: TextStyle(color: categoryColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (article.skillLevel != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: textMuted.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  article.skillLevel!,
                                  style: const TextStyle(color: textMuted, fontSize: 10),
                                ),
                              ),
                            ],
                            if (article.isRequired) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Required',
                                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: textMuted),
                ],
              ),
              if (article.summary != null) ...[
                const SizedBox(height: 12),
                Text(
                  article.summary!,
                  style: const TextStyle(color: textSecondary, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (article.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: article.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(color: accentBlue, fontSize: 11),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'getting started':
        return successColor;
      case 'guides':
        return accentBlue;
      case 'tutorials':
        return warningColor;
      case 'reference':
        return const Color(0xFF8B5CF6);
      case 'faq':
        return const Color(0xFFEC4899);
      default:
        return textMuted;
    }
  }

  Future<void> _showArticleDetails(KnowledgeArticle article) async {
    // Fetch full article details
    final articleData = await ApiService.getKnowledgeArticleBySlug(article.slug);
    
    if (!mounted) return;
    
    if (articleData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load article'),
          backgroundColor: dangerColor,
        ),
      );
      return;
    }

    final fullArticle = KnowledgeArticle.fromJson(articleData);

    // Mark as read
    ApiService.markArticleAsRead(article.slug);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        fullArticle.title,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Meta info
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(fullArticle.category).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              fullArticle.category,
                              style: TextStyle(color: _getCategoryColor(fullArticle.category), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (fullArticle.skillLevel != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.signal_cellular_alt, size: 14, color: textMuted),
                            const SizedBox(width: 4),
                            Text(
                              fullArticle.skillLevel!,
                              style: const TextStyle(color: textMuted, fontSize: 12),
                            ),
                          ],
                          if (fullArticle.author != null) ...[
                            const Spacer(),
                            Icon(Icons.person, size: 14, color: textMuted),
                            const SizedBox(width: 4),
                            Text(
                              fullArticle.author!,
                              style: const TextStyle(color: textMuted, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: textMuted, height: 1),
                      const SizedBox(height: 20),
                      // Content - use htmlContent if available, otherwise content
                      Html(
                        data: fullArticle.htmlContent ?? fullArticle.content,
                        style: {
                          '*': Style(
                            color: textPrimary,
                            fontSize: FontSize(15),
                          ),
                          'h1': Style(
                            color: textPrimary,
                            fontSize: FontSize(22),
                            fontWeight: FontWeight.bold,
                            margin: Margins.only(top: 16, bottom: 8),
                          ),
                          'h2': Style(
                            color: textPrimary,
                            fontSize: FontSize(20),
                            fontWeight: FontWeight.bold,
                            margin: Margins.only(top: 14, bottom: 8),
                          ),
                          'h3': Style(
                            color: textPrimary,
                            fontSize: FontSize(18),
                            fontWeight: FontWeight.bold,
                            margin: Margins.only(top: 12, bottom: 6),
                          ),
                          'p': Style(
                            color: textSecondary,
                            margin: Margins.only(bottom: 12),
                            lineHeight: LineHeight(1.6),
                          ),
                          'a': Style(
                            color: accentBlue,
                            textDecoration: TextDecoration.underline,
                          ),
                          'code': Style(
                            backgroundColor: bgPrimary,
                            color: accentBlue,
                            padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
                            fontFamily: 'monospace',
                          ),
                          'pre': Style(
                            backgroundColor: bgPrimary,
                            padding: HtmlPaddings.all(12),
                            margin: Margins.symmetric(vertical: 8),
                            border: Border.all(color: textMuted.withOpacity(0.3)),
                          ),
                          'ul': Style(
                            color: textSecondary,
                            padding: HtmlPaddings.only(left: 20),
                            margin: Margins.only(bottom: 12),
                          ),
                          'ol': Style(
                            color: textSecondary,
                            padding: HtmlPaddings.only(left: 20),
                            margin: Margins.only(bottom: 12),
                          ),
                          'li': Style(
                            margin: Margins.only(bottom: 6),
                          ),
                          'blockquote': Style(
                            backgroundColor: accentBlue.withOpacity(0.1),
                            border: Border(left: BorderSide(color: accentBlue, width: 4)),
                            padding: HtmlPaddings.all(12),
                            margin: Margins.symmetric(vertical: 12),
                          ),
                        },
                      ),
                      const SizedBox(height: 20),
                      // Tags
                      if (fullArticle.tags.isNotEmpty) ...[
                        const Text(
                          'Tags',
                          style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: fullArticle.tags.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: accentBlue.withOpacity(0.3)),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(color: accentBlue, fontSize: 12),
                            ),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
