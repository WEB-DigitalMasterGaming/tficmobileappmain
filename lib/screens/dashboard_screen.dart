import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:tficmobileapp/services/api_service.dart';
import 'package:tficmobileapp/utils/auth_storage.dart';
import 'package:tficmobileapp/config/theme.dart';
import 'package:tficmobileapp/widgets/dashboard_widgets.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> userEvents = [];
  bool isLoading = true;
  int upcomingEventsCount = 0;
  int activeMissionsCount = 0;
  int availableTicketsCount = 0;
  
  // Permission flags
  bool _canManageMedicalTickets = false;
  bool _canAccessMedicalReports = false;
  bool _isOrgMember = false;
  bool _canAccessMissions = false;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    // Fetch user and events in parallel
    final results = await Future.wait([
      ApiService.getUserProfile(),
      ApiService.getMyRsvpEvents(),
    ]);
    
    final user = results[0] as Map<String, dynamic>?;
    final events = results[1] as List<Map<String, dynamic>>;

    events.sort((a, b) => DateTime.parse(a['start']).compareTo(DateTime.parse(b['start'])));

    // Check permissions
    bool canManageMedical = false;
    bool canAccessReports = false;
    bool isOrgMember = false;
    bool canAccessMissions = false;
    int availableTickets = 0;
    int activeMissions = 0;

    if (user != null) {
      // Check if user is Admin or CMO
      final isAdmin = user['role'] == 'Admin';
      // Check if primaryPosition is a Map before accessing title
      final primaryPos = user['primaryPosition'];
      final isCMO = (primaryPos is Map && primaryPos['title']?.toString().toUpperCase() == 'CMO');
      
      // Check position-based permissions (handle both Map and null values)
      final positions = [
        user['primaryPosition'] is Map ? user['primaryPosition'] : null,
        user['secondaryPosition'] is Map ? user['secondaryPosition'] : null,
        user['tertiaryPosition'] is Map ? user['tertiaryPosition'] : null
      ];
      canManageMedical = isAdmin || isCMO || positions.any((pos) => pos != null && pos['canManageMedicalTickets'] == true);
      
      // Check flags (ensure each flag is a Map before accessing properties)
      final flags = user['flags'] as List<dynamic>? ?? [];
      canAccessReports = flags.any((f) => f is Map && f['flag'] == 'AccessMedicalReports');
      isOrgMember = flags.any((f) => f is Map && f['flag'] == 'OrgMember');
      final canAcceptMissions = flags.any((f) => f is Map && f['flag'] == 'CanAcceptMissions');
      
      // Check org points for Level 1+ (10+ points)
      final orgPoints = user['orgPoints'] ?? 0;
      final isLevel1OrHigher = orgPoints >= 10;
      
      // Can access missions if: Admin OR (OrgMember AND (Level1+ OR CanAcceptMissions flag))
      canAccessMissions = isAdmin || (isOrgMember && (isLevel1OrHigher || canAcceptMissions));
      
      // Fetch badge counts in parallel if user has permissions
      final badgeFutures = <Future<int>>[];
      if (canManageMedical || isAdmin || canAccessReports) {
        badgeFutures.add(ApiService.getAvailableTicketsCount());
      } else {
        badgeFutures.add(Future.value(0));
      }
      
      if (canAccessMissions) {
        badgeFutures.add(ApiService.getActiveMissionsCount());
      } else {
        badgeFutures.add(Future.value(0));
      }
      
      final badgeCounts = await Future.wait(badgeFutures);
      availableTickets = badgeCounts[0];
      activeMissions = badgeCounts[1];
    }

    if (!mounted) return; // Check if widget is still mounted before calling setState
    
    setState(() {
      userData = user;
      userEvents = events;
      upcomingEventsCount = events.length;
      _canManageMedicalTickets = canManageMedical;
      _canAccessMedicalReports = canAccessReports;
      _isOrgMember = isOrgMember;
      _canAccessMissions = canAccessMissions;
      availableTicketsCount = availableTickets;
      activeMissionsCount = activeMissions;
      isLoading = false;
    });
  }

  void logout() async {
    await AuthStorage.clearToken();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  void _showEventDetailsModal(Map<String, dynamic> event) async {
    final localStart = DateTime.parse(event['start']).toLocal();
    final formatted = DateFormat('M/d @ h:mm a').format(localStart);

    // Fetch full event details with image if not already loaded
    Map<String, dynamic> fullEvent = event;
    if (event['eventImageUrl'] == null && event['id'] != null) {
      final details = await ApiService.getEventById(event['id']);
      if (details != null) {
        fullEvent = details;
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(fullEvent['title'] ?? 'Event Details', style: const TextStyle(color: textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time: $formatted', style: const TextStyle(color: textSecondary)),
              const SizedBox(height: 8),
              Text('Your Role: ${fullEvent['role'] ?? 'Unknown'}', style: const TextStyle(color: accentBlue)),
              const SizedBox(height: 16),
              if (fullEvent['description'] != null && fullEvent['description'].toString().trim().isNotEmpty)
                Html(
                  data: fullEvent['description'],
                  style: {
                    '*': Style(color: textPrimary),
                    'strong': Style(color: accentBlue, fontWeight: FontWeight.bold),
                    'p': Style(color: textPrimary, margin: Margins.zero, padding: HtmlPaddings.zero),
                    'li': Style(color: textPrimary),
                    'div': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
                    'br': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
                  },
                  onLinkTap: (url, _, __) {
                    if (url != null) {
                      debugPrint('Link tapped: $url');
                    }
                  },
                ),
              if (fullEvent['eventImageUrl'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Builder(
                    builder: (context) {
                      final rawUrl = fullEvent['eventImageUrl'].toString();
                      debugPrint('📸 Raw eventImageUrl: ${rawUrl.substring(0, rawUrl.length > 100 ? 100 : rawUrl.length)}...');
                      
                      // Handle base64 data URLs
                      if (rawUrl.startsWith('data:image')) {
                        try {
                          final base64String = rawUrl.split(',').last;
                          final bytes = base64Decode(base64String);
                          return Image.memory(
                            bytes,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('❌ Image decode error: $error');
                              return const Icon(Icons.image_not_supported, color: Colors.grey);
                            },
                          );
                        } catch (e) {
                          debugPrint('❌ Base64 decode error: $e');
                          return const Icon(Icons.image_not_supported, color: Colors.grey);
                        }
                      }
                      
                      // Handle regular URLs
                      final imageUrl = rawUrl.startsWith('http')
                          ? rawUrl
                          : '${ApiService.baseUrl}$rawUrl';
                      debugPrint('📸 Event Image URL: $imageUrl');
                      return Image.network(
                        imageUrl,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('❌ Image load error: $error');
                          return const Icon(Icons.image_not_supported, color: Colors.grey);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          if (event['role'] != null)
            TextButton(
              onPressed: () async {
                final success = await ApiService.cancelRsvp(event['id']);
                if (!mounted) return;
                Navigator.of(context).pop();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('RSVP cancelled successfully')),
                  );
                  fetchUser();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to cancel RSVP')),
                  );
                }
              },
              child: const Text('Cancel RSVP', style: TextStyle(color: dangerColor)),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: accentBlue)),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Profile', style: TextStyle(color: textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (userData?['avatarUrl'] != null && userData!['avatarUrl'].toString().isNotEmpty)
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      userData!['avatarUrl'].toString().startsWith('http')
                        ? userData!['avatarUrl']
                        : '${ApiService.baseUrl}${userData!['avatarUrl']}',
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (userData?['gameUserName'] != null)
                _buildProfileRow('In-Game Name', userData!['gameUserName']),
              if (userData?['discordName'] != null)
                _buildProfileRow('Discord', userData!['discordName']),
              if (userData?['role'] != null)
                _buildProfileRow('Role', userData!['role']),
              if (userData?['primaryPositionTitle'] != null) ...[
                const Divider(color: Color(0xFF475569)),
                const Text('Positions', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildPositionChip('Primary', userData!['primaryPositionTitle']),
              ],
              if (userData?['secondaryPositionTitle'] != null)
                _buildPositionChip('Secondary', userData!['secondaryPositionTitle']),
              if (userData?['tertiaryPositionTitle'] != null)
                _buildPositionChip('Tertiary', userData!['tertiaryPositionTitle']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: accentBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(color: textMuted, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionChip(String type, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accentBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentBlue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 14, color: accentBlue),
          const SizedBox(width: 6),
          Text('$type: $title', style: const TextStyle(color: accentBlue, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (userData?['avatarUrl'] != null && userData!['avatarUrl'].toString().isNotEmpty)
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                  userData!['avatarUrl'].toString().startsWith('http')
                    ? userData!['avatarUrl']
                    : '${ApiService.baseUrl}${userData!['avatarUrl']}',
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData?['username'] ?? 'TFIC Dashboard',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (userData?['role'] != null)
                    Text(
                      userData!['role'],
                      style: const TextStyle(fontSize: 11, color: textMuted),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchUser,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: fetchUser,
            color: accentBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  _buildWelcomeCard(),
                  const SizedBox(height: 20),
                  
                  // Onboarding Checklist (if applicable)
                  if (_shouldShowChecklist()) ...[
                    _buildChecklistCard(),
                    const SizedBox(height: 20),
                  ],
                  
                  // Quick Stats
                  _buildQuickStats(),
                  const SizedBox(height: 24),
                  
                  // Quick Actions Grid
                  const SectionHeader(
                    title: 'Quick Access',
                    icon: Icons.dashboard,
                  ),
                  _buildQuickActionsGrid(),
                  const SizedBox(height: 24),
                  
                  // Upcoming Events Section
                  if (userEvents.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Upcoming Events',
                      icon: Icons.event,
                      trailing: TextButton(
                        onPressed: () async {
                          await Navigator.pushNamed(context, '/all-events');
                          fetchUser();
                        },
                        child: const Text('View All', style: TextStyle(color: accentBlue)),
                      ),
                    ),
                    _buildUpcomingEvents(),
                  ] else ...[
                    const SectionHeader(
                      title: 'Events',
                      icon: Icons.event,
                    ),
                    _buildNoEventsCard(),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  // Welcome Card with user info
  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.waving_hand, color: accentBlue, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back!',
                    style: TextStyle(color: textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userData?['username'] ?? 'Member',
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Quick Stats Row
  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            label: 'Events',
            value: upcomingEventsCount.toString(),
            icon: Icons.event,
            color: accentBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatsCard(
            label: 'Missions',
            value: activeMissionsCount.toString(),
            icon: Icons.flag,
            color: warningColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatsCard(
            label: 'Points',
            value: '0',
            icon: Icons.star,
            color: successColor,
          ),
        ),
      ],
    );
  }

  // Quick Actions Grid - with permission-based visibility
  Widget _buildQuickActionsGrid() {
    final List<Widget> actionCards = [];

    // Medical SOS - show badge only to authorized users
    actionCards.add(
      QuickActionCard(
        icon: Icons.medical_services,
        title: 'Medical SOS',
        subtitle: 'Emergency support',
        iconColor: dangerColor,
        badgeCount: (_canManageMedicalTickets || _canAccessMedicalReports || userData?['role'] == 'Admin') 
            ? availableTicketsCount 
            : null,
        onTap: () async {
          await Navigator.pushNamed(context, '/medical-sos');
          fetchUser();
        },
      ),
    );

    // Events - everyone can see
    actionCards.add(
      QuickActionCard(
        icon: Icons.event,
        title: 'Events',
        subtitle: 'View & RSVP',
        badgeCount: upcomingEventsCount,
        onTap: () async {
          await Navigator.pushNamed(context, '/all-events');
          fetchUser();
        },
      ),
    );

    // Missions - only show to authorized users (OrgMembers with Level 1+ or CanAcceptMissions flag)
    if (_canAccessMissions) {
      actionCards.add(
        QuickActionCard(
          icon: Icons.assignment,
          title: 'Missions',
          subtitle: 'Complete tasks',
          iconColor: warningColor,
          badgeCount: activeMissionsCount > 0 ? activeMissionsCount : null,
          onTap: () async {
            await Navigator.pushNamed(context, '/missions');
            fetchUser();
          },
        ),
      );
    }

    // Knowledge Base - everyone can see (content filtered by backend)
    actionCards.add(
      QuickActionCard(
        icon: Icons.library_books,
        title: 'Knowledge Base',
        subtitle: 'Learn & explore',
        iconColor: successColor,
        onTap: () => Navigator.pushNamed(context, '/knowledge-base'),
      ),
    );

    // Profile - everyone can see
    actionCards.add(
      QuickActionCard(
        icon: Icons.person,
        title: 'Profile',
        subtitle: 'View & edit',
        iconColor: accentBlue,
        onTap: () => Navigator.pushNamed(context, '/profile'),
      ),
    );

    // Feedback - everyone can see
    actionCards.add(
      QuickActionCard(
        icon: Icons.feedback,
        title: 'Feedback',
        subtitle: 'Submit & view',
        iconColor: const Color(0xFFFF9800),
        onTap: () => Navigator.pushNamed(context, '/feedback'),
      ),
    );

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: actionCards,
    );
  }

  // Upcoming Events List (First 3)
  Widget _buildUpcomingEvents() {
    return Column(
      children: userEvents.take(3).map((event) {
        final localStart = DateTime.parse(event['start']).toLocal();
        final formatted = DateFormat('M/d @ h:mm a').format(localStart);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showEventDetailsModal(event),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'] ?? 'Unnamed Event',
                    style: const TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: textMuted),
                      const SizedBox(height: 2),
                      Text(formatted, style: const TextStyle(color: textSecondary, fontSize: 13)),
                    ],
                  ),
                  if (event['role'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (event['roleIcon'] != null)
                          Image.network(
                            event['roleIcon'],
                            width: 16,
                            height: 16,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 16, color: accentBlue),
                          ),
                        const SizedBox(width: 4),
                        Text(
                          'Role: ${event['role']}',
                          style: const TextStyle(color: accentBlue, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // No Events Card
  Widget _buildNoEventsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: textMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No Upcoming Events',
              style: TextStyle(color: textMuted, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back later or browse all events',
              style: TextStyle(color: textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/all-events'),
              icon: const Icon(Icons.search),
              label: const Text('Browse Events'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Check if user should see checklist
  Future<bool> _shouldShowChecklistAsync() async {
    if (userData == null) return false;

    final role = userData!['role'];
    final flags = userData!['flags'] as List<dynamic>? ?? [];
    final isOrgMember = flags.any((f) => f is Map && f['flag'] == 'OrgMember');
    final isProspect = role == 'Prospect';

    // Don't show checklist for Admin or Leader
    if (role == 'Admin' || role == 'Leader') return false;

    // Don't show for non-prospects and non-members
    if (!isProspect && !isOrgMember) return false;

    // For prospects, check if they've completed all checklist items
    if (isProspect) {
      try {
        final progress = await ApiService.getOnboardingProgress(userData!);
        final items = progress['items'] as List<dynamic>? ?? [];
        final allComplete = items.every((item) => item['completed'] == true);
        return !allComplete; // Only show if not all complete
      } catch (e) {
        return true; // Show by default if we can't check
      }
    }

    // Show checklist for new members who haven't completed onboarding
    if (isOrgMember) {
      final hasProfile = userData!['gameUserName'] != null && userData!['discordName'] != null;
      final hasDepartment = userData!['primaryPosition'] != null || 
                           userData!['secondaryPosition'] != null || 
                           userData!['tertiaryPosition'] != null;
      final hasPoints = (userData!['orgPoints'] ?? 0) > 0;

      // Show if any of these are incomplete
      return !hasProfile || !hasDepartment || !hasPoints;
    }

    return false;
  }

  // Synchronous wrapper for build method
  bool _shouldShowChecklist() {
    if (userData == null) return false;

    final role = userData!['role'];
    final flags = userData!['flags'] as List<dynamic>? ?? [];
    final isOrgMember = flags.any((f) => f is Map && f['flag'] == 'OrgMember');
    final isProspect = role == 'Prospect';
    
    // Debug logging
    debugPrint('🔍 Checklist visibility check: role=$role, isOrgMember=$isOrgMember, isProspect=$isProspect');
    debugPrint('🔍 Flags: ${flags.where((f) => f is Map).map((f) => f['flag']).toList()}');

    // Don't show checklist for Admin, Leader, or established members
    if (role == 'Admin' || role == 'Leader') {
      debugPrint('🔍 Hiding checklist: User is $role');
      return false;
    }

    // Don't show for users who are neither prospects nor new members
    if (!isProspect && !isOrgMember) return false;

    // For prospects, show by default (actual check happens on click)
    if (isProspect) return true;

    // Show checklist for new members who haven't completed onboarding
    if (isOrgMember) {
      final hasProfile = userData!['gameUserName'] != null && userData!['discordName'] != null;
      final hasDepartment = userData!['primaryPosition'] != null || 
                           userData!['secondaryPosition'] != null || 
                           userData!['tertiaryPosition'] != null;
      final hasPoints = (userData!['orgPoints'] ?? 0) > 0;

      // Show if any of these are incomplete
      return !hasProfile || !hasDepartment || !hasPoints;
    }

    return false;
  }

  // Build checklist card
  Widget _buildChecklistCard() {
    final flags = userData!['flags'] as List<dynamic>? ?? [];
    final isOrgMember = flags.any((f) => f is Map && f['flag'] == 'OrgMember');
    final title = isOrgMember ? 'Getting Started' : 'Pre-Member Checklist';
    final subtitle = isOrgMember 
        ? 'Complete your TFIC onboarding'
        : 'Join TFIC as a full member';

    return Card(
      color: bgCard,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          await Navigator.pushNamed(context, '/onboarding-checklist');
          fetchUser(); // Refresh after returning
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.checklist, color: accentBlue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: textMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
