import 'package:flutter/material.dart';
import 'package:tficmobileapp/models/mission.dart';
import 'package:tficmobileapp/services/api_service.dart';
import 'package:tficmobileapp/config/theme.dart';
import 'package:intl/intl.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> with SingleTickerProviderStateMixin {
  List<Mission> _availableMissions = [];
  List<MissionAcceptance> _myMissions = [];
  bool _isLoading = true;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final availableData = await ApiService.getMissionBoard();
      final myData = await ApiService.getMyMissions();

      if (mounted) {
        setState(() {
          _availableMissions = availableData.map((m) => Mission.fromJson(m)).toList();
          _myMissions = myData.map((m) => MissionAcceptance.fromJson(m)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading missions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Missions'),
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
            Tab(text: 'Available', icon: Icon(Icons.flag, size: 20)),
            Tab(text: 'My Missions', icon: Icon(Icons.assignment_turned_in, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableTab(),
                _buildMyMissionsTab(),
              ],
            ),
    );
  }

  Widget _buildAvailableTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: accentBlue,
      child: _availableMissions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.flag_outlined, size: 64, color: textMuted),
                  SizedBox(height: 16),
                  Text(
                    'No missions available',
                    style: TextStyle(color: textSecondary, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availableMissions.length,
              itemBuilder: (context, index) {
                final mission = _availableMissions[index];
                return _buildMissionCard(mission);
              },
            ),
    );
  }

  Widget _buildMyMissionsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: accentBlue,
      child: _myMissions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.assignment_outlined, size: 64, color: textMuted),
                  SizedBox(height: 16),
                  Text(
                    'No active missions',
                    style: TextStyle(color: textSecondary, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Accept a mission from the Available tab',
                    style: TextStyle(color: textMuted, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myMissions.length,
              itemBuilder: (context, index) {
                final acceptance = _myMissions[index];
                return _buildMyMissionCard(acceptance);
              },
            ),
    );
  }

  Widget _buildMissionCard(Mission mission) {
    final hasTimeLimit = mission.completionTimeLimit != null;
    final hasReward = (mission.rewardPoints ?? 0) > 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showMissionDetails(mission),
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
                      color: warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.flag, color: warningColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.title,
                          style: const TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (mission.missionType != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            mission.missionType!,
                            style: TextStyle(color: warningColor.withOpacity(0.8), fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                mission.objective,
                style: const TextStyle(color: textSecondary, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (hasTimeLimit) ...[
                    Icon(Icons.timer, color: textMuted, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${mission.completionTimeLimit}h',
                      style: const TextStyle(color: textMuted, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (hasReward) ...[
                    const Icon(Icons.star, color: warningColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${mission.rewardPoints} pts',
                      style: const TextStyle(color: warningColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _acceptMission(mission),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Accept'),
                    style: TextButton.styleFrom(
                      foregroundColor: successColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyMissionCard(MissionAcceptance acceptance) {
    final statusColor = _getStatusColor(acceptance.status);
    final daysAgo = DateTime.now().difference(acceptance.createdAt).inDays;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showMyMissionDetails(acceptance),
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
                    child: Icon(Icons.assignment, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          acceptance.missionTitle,
                          style: const TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            acceptance.status,
                            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                acceptance.missionObjective,
                style: const TextStyle(color: textSecondary, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: textMuted, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    daysAgo == 0 ? 'Today' : '$daysAgo days ago',
                    style: const TextStyle(color: textMuted, fontSize: 12),
                  ),
                  if ((acceptance.rewardPoints ?? 0) > 0) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.star, color: warningColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${acceptance.rewardPoints} pts',
                      style: const TextStyle(color: warningColor, fontSize: 12),
                    ),
                  ],
                  const Spacer(),
                  if (acceptance.status.toLowerCase() == 'accepted') ...[
                    TextButton.icon(
                      onPressed: () => _completeMission(acceptance),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Complete', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: successColor,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
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
      case 'accepted':
        return accentBlue;
      case 'completed':
        return successColor;
      case 'abandoned':
        return dangerColor;
      default:
        return textMuted;
    }
  }

  void _showMissionDetails(Mission mission) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          mission.title,
          style: const TextStyle(color: textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mission.missionType != null) ...[
                _buildDetailRow(Icons.category, 'Type', mission.missionType!),
                const SizedBox(height: 8),
              ],
              _buildDetailRow(Icons.flag, 'Objective', mission.objective),
              if (mission.briefing != null) ...[
                const SizedBox(height: 12),
                const Text('Briefing:', style: TextStyle(color: textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  mission.briefing!,
                  style: const TextStyle(color: textSecondary, fontSize: 13),
                ),
              ],
              if (mission.completionTimeLimit != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(Icons.timer, 'Time Limit', '${mission.completionTimeLimit} hours'),
              ],
              if ((mission.rewardPoints ?? 0) > 0) ...[
                const SizedBox(height: 12),
                _buildDetailRow(Icons.star, 'Reward', '${mission.rewardPoints} points'),
              ],
              if (mission.createdBy != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(Icons.person, 'Created By', mission.createdBy!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _acceptMission(mission);
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Accept Mission'),
            style: ElevatedButton.styleFrom(
              backgroundColor: successColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showMyMissionDetails(MissionAcceptance acceptance) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          acceptance.missionTitle,
          style: const TextStyle(color: textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(Icons.info, 'Status', acceptance.status),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.flag, 'Objective', acceptance.missionObjective),
              if (acceptance.missionBriefing != null) ...[
                const SizedBox(height: 12),
                const Text('Briefing:', style: TextStyle(color: textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  acceptance.missionBriefing!,
                  style: const TextStyle(color: textSecondary, fontSize: 13),
                ),
              ],
              if (acceptance.notes != null) ...[
                const SizedBox(height: 12),
                const Text('Notes:', style: TextStyle(color: textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  acceptance.notes!,
                  style: const TextStyle(color: textSecondary, fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),
              _buildDetailRow(Icons.calendar_today, 'Accepted', DateFormat('MMM d, yyyy').format(acceptance.createdAt)),
            ],
          ),
        ),
        actions: [
          if (acceptance.status.toLowerCase() == 'accepted') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _abandonMission(acceptance);
              },
              child: const Text('Abandon', style: TextStyle(color: dangerColor)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _completeMission(acceptance);
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: successColor,
              ),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accentBlue, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: textMuted, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _acceptMission(Mission mission) async {
    final success = await ApiService.acceptMission(mission.id);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mission "${mission.title}" accepted!'),
          backgroundColor: successColor,
        ),
      );
      _loadData();
      _tabController?.animateTo(1); // Switch to My Missions tab
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to accept mission. You may not have permission.'),
          backgroundColor: dangerColor,
        ),
      );
    }
  }

  Future<void> _completeMission(MissionAcceptance acceptance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Complete Mission?', style: TextStyle(color: textPrimary)),
        content: Text(
          'Mark "${acceptance.missionTitle}" as complete? This will be reviewed by leadership.',
          style: const TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: successColor),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ApiService.completeMission(acceptance.id);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mission marked as complete!'),
          backgroundColor: successColor,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to complete mission'),
          backgroundColor: dangerColor,
        ),
      );
    }
  }

  Future<void> _abandonMission(MissionAcceptance acceptance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Abandon Mission?', style: TextStyle(color: textPrimary)),
        content: Text(
          'Are you sure you want to abandon "${acceptance.missionTitle}"?',
          style: const TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: dangerColor),
            child: const Text('Abandon'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ApiService.abandonMission(acceptance.id);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mission abandoned'),
          backgroundColor: warningColor,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to abandon mission'),
          backgroundColor: dangerColor,
        ),
      );
    }
  }
}
