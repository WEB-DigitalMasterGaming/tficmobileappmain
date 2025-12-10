import 'package:flutter/material.dart';
import 'package:tficmobileapp/models/feedback.dart' as model;
import 'package:tficmobileapp/services/api_service.dart';
import 'package:tficmobileapp/config/theme.dart';
import 'package:intl/intl.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> with SingleTickerProviderStateMixin {
  List<model.Feedback> _myFeedback = [];
  bool _isLoading = true;
  TabController? _tabController;

  // Form fields
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  String _selectedPageScope = 'General';
  String _selectedCategory = 'Feature Request';
  String _selectedPriority = 'Medium';

  final List<String> _pageScopes = [
    'General',
    'Dashboard',
    'Events',
    'Medical SOS',
    'Missions',
    'Profile',
    'Leadership',
    'Mobile App',
  ];

  final List<String> _categories = [
    'Feature Request',
    'Bug Report',
    'Improvement',
    'Question',
    'Other',
  ];

  final List<String> _priorities = [
    'Low',
    'Medium',
    'High',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFeedback();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedback() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getMyFeedback();
      if (mounted) {
        setState(() {
          _myFeedback = data.map((f) => model.Feedback.fromJson(f)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading feedback: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Feedback'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedback,
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
              return const SizedBox(width: 12);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentBlue,
          labelColor: accentBlue,
          unselectedLabelColor: textMuted,
          tabs: const [
            Tab(text: 'Submit', icon: Icon(Icons.add_comment, size: 20)),
            Tab(text: 'My Feedback', icon: Icon(Icons.history, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSubmitTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildSubmitTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
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
                            color: accentBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.feedback, color: accentBlue, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share Your Feedback',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Help us improve TFIC',
                                style: TextStyle(color: textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Page Scope Dropdown
                    const Text('Page / Area', style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedPageScope,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: bgPrimary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: textMuted.withOpacity(0.3)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      dropdownColor: bgCard,
                      style: const TextStyle(color: textPrimary),
                      items: _pageScopes.map((scope) {
                        return DropdownMenuItem(value: scope, child: Text(scope));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedPageScope = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Category Dropdown
                    const Text('Category', style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: bgPrimary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: textMuted.withOpacity(0.3)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      dropdownColor: bgCard,
                      style: const TextStyle(color: textPrimary),
                      items: _categories.map((category) {
                        return DropdownMenuItem(value: category, child: Text(category));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Priority Dropdown
                    const Text('Priority', style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: bgPrimary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: textMuted.withOpacity(0.3)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      dropdownColor: bgCard,
                      style: const TextStyle(color: textPrimary),
                      items: _priorities.map((priority) {
                        return DropdownMenuItem(value: priority, child: Text(priority));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedPriority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Message TextArea
                    const Text('Message', style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 6,
                      style: const TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: bgPrimary,
                        hintText: 'Describe your feedback in detail...',
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.6)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: textMuted.withOpacity(0.3)),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your feedback';
                        }
                        if (value.trim().length < 10) {
                          return 'Please provide more detail (at least 10 characters)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitFeedback,
                        icon: const Icon(Icons.send),
                        label: const Text('Submit Feedback'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadFeedback,
      color: accentBlue,
      child: _myFeedback.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history, size: 64, color: textMuted),
                  SizedBox(height: 16),
                  Text(
                    'No feedback submitted yet',
                    style: TextStyle(color: textSecondary, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Submit your first feedback from the Submit tab',
                    style: TextStyle(color: textMuted, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myFeedback.length,
              itemBuilder: (context, index) {
                final feedback = _myFeedback[index];
                return _buildFeedbackCard(feedback);
              },
            ),
    );
  }

  Widget _buildFeedbackCard(model.Feedback feedback) {
    final statusColor = _getStatusColor(feedback.status);
    final priorityColor = _getPriorityColor(feedback.priority);
    final hasResponses = feedback.responses.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showFeedbackDetails(feedback),
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.message, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                feedback.status,
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: priorityColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                feedback.priority,
                                style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feedback.category,
                          style: const TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (hasResponses)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: successColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: successColor, size: 16),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                feedback.message,
                style: const TextStyle(color: textPrimary, fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: textMuted),
                  const SizedBox(width: 4),
                  Text(
                    feedback.pageScope,
                    style: const TextStyle(color: textMuted, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 14, color: textMuted),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(feedback.createdAt),
                    style: const TextStyle(color: textMuted, fontSize: 12),
                  ),
                  const Spacer(),
                  if (hasResponses)
                    Text(
                      '${feedback.responses.length} response${feedback.responses.length > 1 ? 's' : ''}',
                      style: const TextStyle(color: successColor, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return accentBlue;
      case 'in progress':
        return warningColor;
      case 'resolved':
        return successColor;
      case 'closed':
        return textMuted;
      default:
        return textSecondary;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return warningColor;
      case 'low':
        return successColor;
      default:
        return textMuted;
    }
  }

  void _showFeedbackDetails(model.Feedback feedback) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                feedback.category,
                style: const TextStyle(color: textPrimary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(feedback.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                feedback.status,
                style: TextStyle(color: _getStatusColor(feedback.status), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: textMuted),
                  const SizedBox(width: 4),
                  Text(feedback.pageScope, style: const TextStyle(color: textSecondary, fontSize: 13)),
                  const SizedBox(width: 16),
                  Icon(Icons.priority_high, size: 16, color: _getPriorityColor(feedback.priority)),
                  const SizedBox(width: 4),
                  Text(feedback.priority, style: TextStyle(color: _getPriorityColor(feedback.priority), fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Your Message:', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(
                feedback.message,
                style: const TextStyle(color: textPrimary, fontSize: 14),
              ),
              if (feedback.responses.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Responses:', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ...feedback.responses.map((response) => Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: successColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.admin_panel_settings, size: 14, color: successColor),
                          const SizedBox(width: 4),
                          Text(
                            response.adminName,
                            style: const TextStyle(color: successColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('MMM d').format(response.respondedAt),
                            style: const TextStyle(color: textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        response.responseText,
                        style: const TextStyle(color: textPrimary, fontSize: 13),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ApiService.submitFeedback(
      pageScope: _selectedPageScope,
      category: _selectedCategory,
      message: _messageController.text.trim(),
      priority: _selectedPriority,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully!'),
          backgroundColor: successColor,
        ),
      );
      _messageController.clear();
      _loadFeedback();
      _tabController?.animateTo(1); // Switch to history tab
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit feedback'),
          backgroundColor: dangerColor,
        ),
      );
    }
  }
}
