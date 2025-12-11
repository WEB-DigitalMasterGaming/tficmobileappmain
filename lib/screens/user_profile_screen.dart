import 'package:flutter/material.dart';
import 'package:tficmobileapp/services/api_service.dart';
import 'package:tficmobileapp/config/theme.dart';
import 'package:intl/intl.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _userData;
  List<dynamic> _pointsHistory = [];
  bool _isLoading = true;
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userData = await ApiService.getUserProfile();
      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPointsHistory() async {
    if (_isLoadingHistory || _pointsHistory.isNotEmpty) return;
    
    setState(() => _isLoadingHistory = true);

    try {
      final history = await ApiService.getPointsHistory();
      
      if (mounted) {
        setState(() {
          _pointsHistory = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading points history: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              color: accentBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 20),
                    _buildPointsCard(),
                    const SizedBox(height: 20),
                    _buildStatsGrid(),
                    const SizedBox(height: 20),
                    _buildUserInfoSection(),
                    const SizedBox(height: 20),
                    _buildPositionsSection(),
                    const SizedBox(height: 20),
                    _buildPointsHistorySection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final username = _userData?['username'] ?? 'Unknown';
    final gameUserName = _userData?['gameUserName'];
    final email = _userData?['email'];
    final discordUsername = _userData?['discordUsername'];
    final steamId = _userData?['steamId'];
    final avatarUrl = _userData?['avatarUrl'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: avatarUrl != null && avatarUrl.toString().isNotEmpty
                  ? CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(
                        avatarUrl.toString().startsWith('http')
                            ? avatarUrl
                            : '${ApiService.baseUrl}$avatarUrl',
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentBlue, accentBlue.withOpacity(0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          username.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            // Username
            Text(
              username,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (gameUserName != null) ...[
              const SizedBox(height: 4),
              Text(
                '🎮 $gameUserName',
                style: const TextStyle(color: textSecondary, fontSize: 14),
              ),
            ],
            const SizedBox(height: 12),
            // Quick info chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (email != null) _buildInfoChip(Icons.email, email),
                if (discordUsername != null) _buildInfoChip(Icons.discord, discordUsername),
                if (steamId != null) _buildInfoChip(Icons.videogame_asset, 'Steam: $steamId'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgPrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textMuted.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textMuted),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
    final orgPoints = _userData?['orgPoints'] ?? 0;
    final eventsAttended = _userData?['eventsAttended'] ?? 0;

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentBlue.withOpacity(0.1),
              accentBlue.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accentBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.star, color: accentBlue, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Org Points',
                        style: TextStyle(color: textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    orgPoints.toString(),
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: textMuted.withOpacity(0.3),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: warningColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.event_available, color: warningColor, size: 18),
                      ),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          'Events Attended',
                          style: TextStyle(color: textMuted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      eventsAttended.toString(),
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildStatsGrid() {
    final roles = _userData?['roles'] as List? ?? [];
    final departments = _userData?['departments'] as List? ?? [];
    final positions = _userData?['positions'] as List? ?? [];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1,
      children: [
        _buildStatCard(
          icon: Icons.security,
          label: 'Roles',
          value: roles.length.toString(),
          color: accentBlue,
        ),
        _buildStatCard(
          icon: Icons.business,
          label: 'Departments',
          value: departments.length.toString(),
          color: successColor,
        ),
        _buildStatCard(
          icon: Icons.work,
          label: 'Positions',
          value: positions.length.toString(),
          color: warningColor,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: textMuted, fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    final roles = _userData?['roles'] as List? ?? [];
    final departments = _userData?['departments'] as List? ?? [];
    final createdAt = _userData?['createdAt'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: accentBlue, size: 20),
                SizedBox(width: 8),
                Text(
                  'User Information',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (roles.isNotEmpty) ...[
              _buildInfoRow('Roles', roles.join(', ')),
              const SizedBox(height: 12),
            ],
            if (departments.isNotEmpty) ...[
              _buildInfoRow('Departments', departments.join(', ')),
              const SizedBox(height: 12),
            ],
            if (createdAt != null) ...[
              _buildInfoRow(
                'Member Since',
                DateFormat('MMM d, yyyy').format(DateTime.parse(createdAt)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(color: textMuted, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionsSection() {
    final positions = _userData?['positions'] as List? ?? [];

    if (positions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.work, color: accentBlue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Positions',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...positions.map((position) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: accentBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      position is Map ? (position['title'] ?? position.toString()) : position.toString(),
                      style: const TextStyle(color: textSecondary, fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsHistorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: accentBlue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Points History',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _loadPointsHistory,
                  child: Text(
                    _isLoadingHistory ? 'Loading...' : 'Load History',
                    style: const TextStyle(color: accentBlue, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingHistory)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_pointsHistory.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(Icons.history, size: 48, color: textMuted),
                      SizedBox(height: 8),
                      Text(
                        'No points history available',
                        style: TextStyle(color: textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _pointsHistory.map((transaction) {
                  // Backend returns camelCase: amount, reason, createdAt
                  final points = transaction['amount'] ?? 0;
                  final isPositive = points > 0;
                  final createdAt = transaction['createdAt'];
                  final dateStr = createdAt != null 
                    ? DateFormat('MMM d, yyyy').format(DateTime.parse(createdAt))
                    : 'Unknown date';
                  
                  return ListTile(
                    leading: Icon(
                      isPositive ? Icons.add_circle : Icons.remove_circle,
                      color: isPositive ? successColor : dangerColor,
                    ),
                    title: Text(
                      transaction['reason'] ?? 'Points transaction',
                      style: const TextStyle(color: textPrimary, fontSize: 14),
                    ),
                    subtitle: Text(
                      dateStr,
                      style: const TextStyle(color: textMuted, fontSize: 12),
                    ),
                    trailing: Text(
                      '${isPositive ? '+' : ''}$points',
                      style: TextStyle(
                        color: isPositive ? successColor : dangerColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
