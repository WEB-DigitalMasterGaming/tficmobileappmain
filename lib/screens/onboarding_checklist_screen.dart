import 'package:flutter/material.dart';
import 'package:tficmobileapp/services/api_service.dart';
import 'package:tficmobileapp/config/theme.dart';
import 'package:tficmobileapp/models/checklist_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingChecklistScreen extends StatefulWidget {
  const OnboardingChecklistScreen({super.key});

  @override
  State<OnboardingChecklistScreen> createState() => _OnboardingChecklistScreenState();
}

class _OnboardingChecklistScreenState extends State<OnboardingChecklistScreen> {
  ChecklistProgress? _checklistProgress;
  RequiredReadingProgress? _readingProgress;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    setState(() => _isLoading = true);

    try {
      // Get user profile
      final user = await ApiService.getUserProfile();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get checklist progress
      final progressData = await ApiService.getOnboardingProgress(user);
      final checklist = ChecklistProgress.fromJson(progressData, progressData['type']);

      // Get reading progress
      final flags = user['flags'] as List<dynamic>? ?? [];
      final hasOrgMember = flags.any((f) => f['flag'] == 'OrgMember');
      final isProspect = user['role'] == 'Prospect' || !hasOrgMember;
      String userType = isProspect ? 'Prospect' : (user['role'] == 'Leader' || user['role'] == 'Admin' ? 'Leader' : 'Member');
      final readingData = await ApiService.getRequiredReadingProgress(userType);
      final reading = RequiredReadingProgress.fromJson(readingData);

      setState(() {
        _userData = user;
        _checklistProgress = checklist;
        _readingProgress = reading;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading checklist: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleItem(ChecklistItem item) async {
    if (_userData == null) return;

    // Store progress locally
    final prefs = await SharedPreferences.getInstance();
    final userId = _userData!['id'];
    final key = 'checklist_${userId}_${item.id}';
    final newValue = !item.completed;
    await prefs.setBool(key, newValue);

    // Update UI
    setState(() {
      final index = _checklistProgress!.items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        final updatedItems = List<ChecklistItem>.from(_checklistProgress!.items);
        updatedItems[index] = ChecklistItem(
          id: item.id,
          title: item.title,
          description: item.description,
          completed: newValue,
          actionRoute: item.actionRoute,
          actionLabel: item.actionLabel,
        );

        final completed = updatedItems.where((i) => i.completed).length;
        final total = updatedItems.length;

        _checklistProgress = ChecklistProgress(
          type: _checklistProgress!.type,
          items: updatedItems,
          completedCount: completed,
          totalCount: total,
          progressPercentage: (completed / total) * 100,
        );
      }
    });

    // If prospect completes all items, call complete onboarding API
    if (_checklistProgress!.type == 'prospect' && 
        _checklistProgress!.completedCount == _checklistProgress!.totalCount) {
      final result = await ApiService.completeOnboarding();
      if (result['success'] == true) {
        _showSuccessDialog(result['message'] ?? 'Onboarding completed!');
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgCard,
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: successColor, size: 32),
            SizedBox(width: 12),
            Text('Success!', style: TextStyle(color: textPrimary)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: textSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to dashboard
            },
            child: const Text('OK', style: TextStyle(color: accentBlue)),
          ),
        ],
      ),
    );
  }

  void _handleAction(ChecklistItem item) async {
    if (item.actionRoute == null) return;

    // Handle external URLs
    if (item.actionRoute!.startsWith('http')) {
      // For Discord and RSI links, show a dialog with instructions
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: bgCard,
          title: Text(
            item.title,
            style: const TextStyle(color: textPrimary, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.description,
                style: const TextStyle(color: textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  item.actionRoute!,
                  style: const TextStyle(
                    color: accentBlue,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Copy this link and open it in your browser. After completing the action, return here and check the box.',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: accentBlue)),
            ),
          ],
        ),
      );
    } else if (item.actionRoute == '/code-of-conduct') {
      // Navigate to Code of Conduct and wait for acceptance
      final accepted = await Navigator.pushNamed(context, item.actionRoute!);
      if (accepted == true && mounted) {
        // Reload checklist to show updated progress
        _loadChecklist();
      }
    } else {
      // Navigate to internal route
      Navigator.pushNamed(context, item.actionRoute!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: bgCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Onboarding Checklist',
          style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentBlue))
          : _checklistProgress == null
              ? const Center(
                  child: Text(
                    'No checklist available',
                    style: TextStyle(color: textMuted),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChecklist,
                  color: accentBlue,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress card
                        _buildProgressCard(),
                        const SizedBox(height: 24),

                        // Checklist title
                        Text(
                          _checklistProgress!.type == 'prospect'
                              ? 'Pre-Member Checklist'
                              : 'Getting Started Checklist',
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _checklistProgress!.type == 'prospect'
                              ? 'Complete these steps to join TFIC as a full member'
                              : 'Get started with your TFIC journey',
                          style: const TextStyle(color: textMuted, fontSize: 14),
                        ),
                        const SizedBox(height: 16),

                        // Checklist items
                        ..._checklistProgress!.items.map((item) => _buildChecklistItem(item)).toList(),

                        // Required Reading Section (if applicable)
                        if (_readingProgress != null && _readingProgress!.totalRequired > 0) ...[
                          const SizedBox(height: 24),
                          _buildReadingProgressCard(),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _checklistProgress!;
    final percentage = progress.progressPercentage.toInt();

    return Card(
      color: bgCard,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Progress',
                  style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${progress.completedCount}/${progress.totalCount}',
                  style: const TextStyle(color: accentBlue, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.progressPercentage / 100,
                minHeight: 12,
                backgroundColor: bgCardHover,
                valueColor: const AlwaysStoppedAnimation<Color>(accentBlue),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage% Complete',
              style: const TextStyle(color: textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(ChecklistItem item) {
    return Card(
      color: bgCard,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _toggleItem(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.completed ? successColor : borderColor,
                    width: 2,
                  ),
                  color: item.completed ? successColor : Colors.transparent,
                ),
                child: item.completed
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: item.completed ? textMuted : textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: item.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(color: textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Action button
              if (item.actionRoute != null && !item.completed) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => _handleAction(item),
                  style: TextButton.styleFrom(
                    backgroundColor: accentBlue.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    item.actionLabel ?? 'Go',
                    style: const TextStyle(color: accentBlue, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingProgressCard() {
    final progress = _readingProgress!;

    return Card(
      color: bgCard,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.menu_book, color: accentBlue, size: 24),
                SizedBox(width: 12),
                Text(
                  'Required Reading',
                  style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.completed} of ${progress.totalRequired} articles read',
                  style: const TextStyle(color: textSecondary, fontSize: 14),
                ),
                Text(
                  progress.isComplete ? 'Complete ✓' : 'In Progress',
                  style: TextStyle(
                    color: progress.isComplete ? successColor : warningColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.totalRequired > 0 ? progress.completed / progress.totalRequired : 0,
                minHeight: 8,
                backgroundColor: bgCardHover,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress.isComplete ? successColor : accentBlue,
                ),
              ),
            ),
            if (progress.articles.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: borderColor),
              const SizedBox(height: 12),
              ...progress.articles.take(5).map((article) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      article.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: article.completed ? successColor : textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        article.title,
                        style: TextStyle(
                          color: article.completed ? textMuted : textSecondary,
                          fontSize: 13,
                          decoration: article.completed ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )).toList(),
              if (progress.articles.length > 5) ...[
                const SizedBox(height: 8),
                Text(
                  '+${progress.articles.length - 5} more articles',
                  style: const TextStyle(color: textMuted, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/knowledge-base'),
                style: TextButton.styleFrom(
                  backgroundColor: accentBlue.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'View All Required Reading',
                  style: TextStyle(color: accentBlue, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
