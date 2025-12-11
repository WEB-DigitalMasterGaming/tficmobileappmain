import 'package:flutter/material.dart';
import 'package:tficmobileapp/models/medical_ticket.dart';
import 'package:tficmobileapp/services/api_service.dart';
import 'package:tficmobileapp/config/theme.dart';
import 'package:tficmobileapp/screens/create_ticket_screen.dart';
import 'package:tficmobileapp/screens/ticket_detail_screen.dart';

class MedicalSosScreen extends StatefulWidget {
  const MedicalSosScreen({super.key});

  @override
  State<MedicalSosScreen> createState() => _MedicalSosScreenState();
}

class _MedicalSosScreenState extends State<MedicalSosScreen> with SingleTickerProviderStateMixin {
  MedicalTicket? _myActiveTicket;
  List<MedicalTicket> _availableTickets = [];
  List<Map<String, dynamic>> _allTicketsHistory = [];
  Map<String, dynamic>? _reports;
  bool _isLoading = true;
  bool _isLoadingAdmin = false;
  bool _canManageTickets = false;
  bool _canAccessMedicalReports = false;
  TabController? _tabController;
  int _tabCount = 1; // Default: My Ticket only

  @override
  void initState() {
    super.initState();
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
      // Load user profile to check permissions
      final userProfile = await ApiService.getUserProfile();
      
      if (userProfile != null) {
        // Check if user is Admin or CMO
        final isAdmin = userProfile['role'] == 'Admin';
        final primaryPos = userProfile['primaryPosition'];
        final isCMO = (primaryPos is Map && primaryPos['title']?.toString().toUpperCase() == 'CMO');
        
        // Check position-based permissions
        final primaryPosition = userProfile['primaryPosition'];
        final secondaryPosition = userProfile['secondaryPosition'];
        final tertiaryPosition = userProfile['tertiaryPosition'];
        final positions = [
          primaryPosition is Map ? primaryPosition : null,
          secondaryPosition is Map ? secondaryPosition : null,
          tertiaryPosition is Map ? tertiaryPosition : null,
        ];
        final canManageMedical = isAdmin || isCMO || positions.any((pos) => pos != null && pos['canManageMedicalTickets'] == true);
        
        // Check flags
        final flags = userProfile['flags'] as List<dynamic>? ?? [];
        final canAccessReports = isAdmin || flags.any((f) => f is Map && f['flag'] == 'AccessMedicalReports');
        
        _canManageTickets = canManageMedical;
        _canAccessMedicalReports = canAccessReports;
        
        // Determine tab count based on permissions
        // Admins always have full access
        if (isAdmin || canManageMedical) {
          // Full access: My Ticket + Available + Admin + Reports
          _tabCount = 4;
        } else if (canAccessReports) {
          // Reports only: My Ticket + Reports
          _tabCount = 2;
        } else {
          // No special permissions: My Ticket only
          _tabCount = 1;
        }
        
        // Initialize tab controller
        if (_tabController == null || _tabController!.length != _tabCount) {
          _tabController?.dispose();
          _tabController = TabController(length: _tabCount, vsync: this);
        }
      }
      
      // Load user's active ticket
      final myTicketData = await ApiService.getMyActiveTicket();
      if (myTicketData != null) {
        _myActiveTicket = MedicalTicket.fromJson(myTicketData);
      }

      // Load available tickets only if user has permission
      if (_canManageTickets) {
        try {
          final availableData = await ApiService.getAvailableTickets();
          _availableTickets = availableData.map((t) => MedicalTicket.fromJson(t)).toList();
        } catch (e) {
          debugPrint('Error loading available tickets: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading medical tickets: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAllTicketsHistory() async {
    if (!mounted) return;
    setState(() => _isLoadingAdmin = true);
    
    try {
      final history = await ApiService.getAllTicketHistory();
      if (mounted) {
        setState(() {
          _allTicketsHistory = history;
          _isLoadingAdmin = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading all tickets history: $e');
      if (mounted) {
        setState(() => _isLoadingAdmin = false);
      }
    }
  }

  Future<void> _loadReports() async {
    if (_reports != null) return; // Already loaded
    
    try {
      // Load last 30 days of reports
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));
      final reportsData = await ApiService.getTicketReports(
        startDate: startDate,
        endDate: endDate,
      );
      
      if (mounted) {
        setState(() {
          _reports = reportsData;
        });
      }
    } catch (e) {
      debugPrint('Error loading reports: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        title: const Text('🚑 Medical SOS', style: TextStyle(color: textPrimary)),
        backgroundColor: bgPrimary,
        iconTheme: const IconThemeData(color: accentBlue),
        actions: [
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
        bottom: _tabController != null && _tabCount > 1
            ? TabBar(
                controller: _tabController,
                indicatorColor: accentBlue,
                labelColor: accentBlue,
                unselectedLabelColor: textMuted,
                isScrollable: true,
                tabs: _buildTabs(),
                onTap: (index) {
                  // Load data for tab on first access
                  if (_canManageTickets) {
                    if (index == 2) _loadAllTicketsHistory();  // Admin tab
                    if (index == 3) _loadReports();  // Reports tab
                  } else if (_canAccessMedicalReports && index == 1) {
                    _loadReports();  // Reports tab (for non-medics with report access)
                  }
                },
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentBlue))
          : _tabController != null && _tabCount > 1
              ? TabBarView(
                  controller: _tabController,
                  children: _buildTabViews(),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF00BFFF),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: _buildMyTicketSection(),
                  ),
                ),
    );
  }

  // Build tabs based on permissions
  List<Widget> _buildTabs() {
    final tabs = <Widget>[
      const Tab(text: 'My Ticket', icon: Icon(Icons.person, size: 18)),
    ];
    
    if (_canManageTickets) {
      tabs.addAll([
        const Tab(text: 'Available', icon: Icon(Icons.medical_services, size: 18)),
        const Tab(text: 'Admin', icon: Icon(Icons.admin_panel_settings, size: 18)),
        const Tab(text: 'Reports', icon: Icon(Icons.analytics, size: 18)),
      ]);
    } else if (_canAccessMedicalReports) {
      tabs.add(const Tab(text: 'Reports', icon: Icon(Icons.analytics, size: 18)));
    }
    
    return tabs;
  }

  // Build tab views based on permissions
  List<Widget> _buildTabViews() {
    final views = <Widget>[
      _buildMyTicketTab(),
    ];
    
    if (_canManageTickets) {
      views.addAll([
        _buildAvailableTicketsTab(),
        _buildAdminTab(),
        _buildReportsTab(),
      ]);
    } else if (_canAccessMedicalReports) {
      views.add(_buildReportsTab());
    }
    
    return views;
  }

  Widget _buildMyTicketTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF00BFFF),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: _buildMyTicketSection(),
      ),
    );
  }

  Widget _buildAvailableTicketsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF00BFFF),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: _buildAvailableTicketsSection(),
      ),
    );
  }

  Widget _buildMyTicketSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_canManageTickets)
          const Text(
            'My Active Ticket',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (!_canManageTickets) const SizedBox(height: 12),
        
        if (_myActiveTicket == null)
          _buildCreateTicketCard()
        else
          _buildTicketCard(_myActiveTicket!, isMyTicket: true),
      ],
    );
  }

  Widget _buildCreateTicketCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentBlue, width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.medical_services, color: accentBlue, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No Active Ticket',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Need medical assistance? Create a ticket to get help from our medics.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateTicketScreen()),
              );
              if (result == true) {
                _loadData();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create SOS Ticket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTicketsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_availableTickets.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: const [
                Icon(Icons.check_circle_outline, color: accentBlue, size: 48),
                SizedBox(height: 12),
                Text(
                  '✅ No pending tickets',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'All medical requests have been handled',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgCardHover,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: accentBlue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_availableTickets.length} ticket(s) awaiting response',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ..._availableTickets.map((ticket) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTicketCard(ticket, isMyTicket: false),
                  )),
            ],
          ),
      ],
    );
  }

  Widget _buildTicketCard(MedicalTicket ticket, {required bool isMyTicket}) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailScreen(ticketId: ticket.id),
          ),
        );
        if (result == true) {
          _loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ticket.getStatusColor().withOpacity(0.5), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ticket.getStatusColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ticket.getStatusColor(), width: 1),
                  ),
                  child: Text(
                    ticket.getStatusDisplay(),
                    style: TextStyle(
                      color: ticket.getStatusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTime(ticket.createdAt),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, 'Player', ticket.inGameUsername),
            _buildInfoRow(Icons.public, 'System', ticket.currentSystem),
            _buildInfoRow(Icons.location_on, 'Location', ticket.currentLocation),
            if (ticket.deathTimerRemaining != null)
              _buildInfoRow(Icons.timer, 'Timer', '${ticket.deathTimerRemaining} minutes'),
            if (ticket.assignedMedicUsername != null)
              _buildInfoRow(Icons.medical_services, 'Medic', ticket.assignedMedicUsername!),
            if (ticket.notes != null && ticket.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Notes: ${ticket.notes}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accentBlue),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildAdminTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _allTicketsHistory = []);
        await _loadAllTicketsHistory();
      },
      color: const Color(0xFF00BFFF),
      child: _isLoadingAdmin
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(color: accentBlue),
                  SizedBox(height: 16),
                  Text(
                    'Loading all tickets history...',
                    style: TextStyle(color: textMuted),
                  ),
                ],
              ),
            )
          : _allTicketsHistory.isEmpty
          ? const Center(
              child: Text(
                'No ticket history found',
                style: TextStyle(color: textMuted),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _allTicketsHistory.length,
              itemBuilder: (context, index) {
                final ticket = _allTicketsHistory[index];
                return _buildAdminTicketCard(ticket);
              },
            ),
    );
  }

  Widget _buildAdminTicketCard(Map<String, dynamic> ticketData) {
    final status = ticketData['status'] ?? 'Unknown';
    final statusColor = _getStatusColor(status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailScreen(
                ticketId: ticketData['id'],
                ticketData: ticketData, // Pass the full ticket data
              ),
            ),
          );
          if (result == true) {
            setState(() => _allTicketsHistory = []);
            _loadAllTicketsHistory();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ID: ${ticketData['id']}',
                    style: const TextStyle(color: textMuted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ticketData['username'] ?? 'Unknown',
                      style: const TextStyle(color: textPrimary, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.public, size: 14, color: textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${ticketData['currentSystem']} - ${ticketData['currentLocation']}',
                      style: const TextStyle(color: textSecondary, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (ticketData['assignedMedicUsername'] != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.medical_services, size: 14, color: successColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Medic: ${ticketData['assignedMedicUsername']}',
                        style: const TextStyle(color: successColor, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 12, color: textMuted),
                  const SizedBox(width: 4),
                  Text(
                    ticketData['createdAt'] != null
                        ? _formatTime(DateTime.parse(ticketData['createdAt']))
                        : 'Unknown',
                    style: const TextStyle(color: textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _reports = null);
        await _loadReports();
      },
      color: const Color(0xFF00BFFF),
      child: _reports == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(color: accentBlue),
                  SizedBox(height: 16),
                  Text(
                    'Loading reports...',
                    style: TextStyle(color: textMuted),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  const Text(
                    'Last 30 Days Overview',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _buildStatCard(
                        'Total Tickets',
                        _reports?['totalTickets']?.toString() ?? '0',
                        Icons.local_hospital,
                        accentBlue,
                      ),
                      _buildStatCard(
                        'Completed',
                        _reports?['completedTickets']?.toString() ?? '0',
                        Icons.check_circle,
                        successColor,
                      ),
                      _buildStatCard(
                        'Pending',
                        _reports?['pendingTickets']?.toString() ?? '0',
                        Icons.pending,
                        warningColor,
                      ),
                      _buildStatCard(
                        'Avg Time',
                        _reports?['averageResolutionTime'] != null
                            ? '${_reports!['averageResolutionTime']}m'
                            : 'N/A',
                        Icons.timer,
                        textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Top Medics
                  if (_reports?['topMedics'] != null) ...[
                    const Text(
                      'Top Medics',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(_reports!['medicPerformance'] as List? ?? []).map((medic) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: successColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.medical_services,
                                  color: successColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  medic['medicName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accentBlue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${medic['ticketsCompleted']} tickets',
                                  style: const TextStyle(
                                    color: accentBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: textMuted, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return warningColor;
      case 'in progress':
      case 'inprogress':
        return accentBlue;
      case 'completed':
        return successColor;
      case 'cancelled':
        return dangerColor;
      default:
        return textMuted;
    }
  }
}
