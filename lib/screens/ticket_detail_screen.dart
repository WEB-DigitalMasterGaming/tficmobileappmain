import 'package:flutter/material.dart';
import 'package:tficmobileapp/models/medical_ticket.dart';
import 'package:tficmobileapp/models/ticket_message.dart';
import 'package:tficmobileapp/services/api_service.dart';
import 'dart:async';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;
  final Map<String, dynamic>? ticketData;

  const TicketDetailScreen({super.key, required this.ticketId, this.ticketData});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  MedicalTicket? _ticket;
  List<TicketMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;
  bool _isSending = false;
  int? _currentUserId;
  bool _canManageTickets = false;
  bool _canAccessMedicalReports = false;
  String? _userRole;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadTicketAndMessages();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh messages every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadMessages(silent: true);
      }
    });
  }

  Future<void> _loadTicketAndMessages() async {
    setState(() => _isLoading = true);

    try {
      // Get current user profile
      final profile = await ApiService.getUserProfile();
      if (profile != null) {
        _currentUserId = profile['id'];
        _userRole = profile['role'];
        
        // Check if user has permission to manage medical tickets or access reports
        final positions = profile['positions'] as List<dynamic>?;
        if (positions != null) {
          _canManageTickets = positions.any((pos) => pos['canManageMedicalTickets'] == true);
          _canAccessMedicalReports = positions.any((pos) => pos['canAccessMedicalReports'] == true);
        }
      }

      // Use ticket data if provided, otherwise try to load from lists
      if (widget.ticketData != null) {
        _ticket = MedicalTicket.fromJson(widget.ticketData!);
        debugPrint('🎫 Using provided ticket data: ${_ticket!.inGameUsername}');
      } else {
        // Fallback: Try to load from available tickets or user's ticket
        debugPrint('🎫 No ticket data provided, attempting to load from lists');
        try {
          final availableTickets = await ApiService.getAvailableTickets();
          _ticket = availableTickets
              .map((t) => MedicalTicket.fromJson(t))
              .firstWhere((t) => t.id == widget.ticketId, orElse: () {
            throw Exception('Ticket not found in available tickets');
          });
        } catch (e) {
          final myTicketData = await ApiService.getMyActiveTicket();
          if (myTicketData != null) {
            final myTicket = MedicalTicket.fromJson(myTicketData);
            if (myTicket.id == widget.ticketId) {
              _ticket = myTicket;
            }
          }
        }
      }

      // Load messages ONLY if user has permission to view them
      if (_ticket != null && _canViewMessages()) {
        await _loadMessages();
      } else {
        debugPrint('❌ Could not load ticket #${widget.ticketId}');
      }
    } catch (e) {
      debugPrint('❌ Error loading ticket: $e');
    }

    setState(() => _isLoading = false);
  }

  // Check if user can view messages/chat
  bool _canViewMessages() {
    if (_ticket == null) return false;
    
    final isAssignedMedic = _currentUserId == _ticket!.assignedMedicId;
    final isAdmin = _userRole == 'Admin';
    final isCMO = _userRole == 'CMO';
    
    return isAssignedMedic || isAdmin || isCMO || _canAccessMedicalReports;
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final messagesData = await ApiService.getTicketMessages(widget.ticketId);
      final newMessages = messagesData.map((m) => TicketMessage.fromJson(m)).toList();
      
      if (mounted) {
        setState(() {
          _messages = newMessages;
        });
        
        // Auto-scroll to bottom when new messages arrive
        if (_scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }

    if (!silent && mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    // Check if ticket has been claimed before allowing messages
    if (_ticket?.assignedMedicId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This ticket must be claimed by a medic before messages can be sent'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isSending = true);

    try {
      final success = await ApiService.sendTicketMessage(widget.ticketId, message);
      
      if (success) {
        _messageController.clear();
        await _loadMessages();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _claimTicket() async {
    final success = await ApiService.claimTicket(widget.ticketId);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ticket claimed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to claim ticket'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeTicket() async {
    final success = await ApiService.completeTicket(widget.ticketId);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ticket completed!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to complete ticket'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelTicket() async {
    final success = await ApiService.cancelTicket(widget.ticketId);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ticket cancelled'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to cancel ticket'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _ticket == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F1C),
        appBar: AppBar(
          title: const Text('Ticket Details', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF1A1A2E),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BFFF)),
        ),
      );
    }

    final isMyTicket = _currentUserId == _ticket!.userId;
    final isAssignedMedic = _currentUserId == _ticket!.assignedMedicId;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1C),
      appBar: AppBar(
        title: Text('Ticket #${_ticket!.id}', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A2E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Only medics can claim tickets
          if (_ticket!.status == 'Pending' && _canManageTickets && !isMyTicket)
            IconButton(
              icon: const Icon(Icons.medical_services),
              onPressed: _claimTicket,
              tooltip: 'Claim Ticket',
            ),
          // Only assigned medic can complete
          if (_ticket!.status == 'InProgress' && isAssignedMedic && _canManageTickets)
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: _completeTicket,
              tooltip: 'Complete Ticket',
            ),
          // Users can only cancel their own tickets
          if (isMyTicket && (_ticket!.status == 'Pending' || _ticket!.status == 'InProgress'))
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _cancelTicket,
              tooltip: 'Cancel Ticket',
            ),
        ],
      ),
      body: Column(
        children: [
          // Ticket Info Header
          _buildTicketHeader(),
          
          // Messages List - Only show if user has permission
          if (_canViewMessages())
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
            )
          else
            // Show message for users without permission
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 64, color: Colors.white24),
                      const SizedBox(height: 16),
                      Text(
                        'Chat Access Restricted',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Only assigned medics and authorized personnel can view the chat.',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Chat Monitoring Notice - Only show if user has chat access
          if (_canViewMessages())
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                border: Border(
                  top: BorderSide(color: Color(0xFF2A2A3E), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.white38),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This chat is monitored and may be reviewed by approved leadership and administrators.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Message Input - Only show if user has permission and ticket is active
          if (_canViewMessages() && 
              _ticket!.status != 'Completed' && 
              _ticket!.status != 'Cancelled' && 
              _ticket!.status != 'Archived')
            _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildTicketHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(
          bottom: BorderSide(color: _ticket!.getStatusColor().withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _ticket!.getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _ticket!.getStatusColor(), width: 1),
                ),
                child: Text(
                  _ticket!.getStatusDisplay(),
                  style: TextStyle(
                    color: _ticket!.getStatusColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.person, _ticket!.inGameUsername),
          _buildInfoRow(Icons.public, _ticket!.currentSystem),
          _buildInfoRow(Icons.location_on, _ticket!.currentLocation),
          if (_ticket!.deathTimerRemaining != null)
            _buildInfoRow(Icons.timer, '${_ticket!.deathTimerRemaining} minutes'),
          if (_ticket!.assignedMedicUsername != null)
            _buildInfoRow(Icons.medical_services, 'Medic: ${_ticket!.assignedMedicUsername}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF00BFFF)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(TicketMessage message) {
    final isMyMessage = message.userId == _currentUserId;
    final isSystemMessage = message.isSystemMessage;

    if (isSystemMessage) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A3E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message.message,
            style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.username,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMyMessage ? const Color(0xFF00BFFF) : const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatMessageTime(message.createdAt),
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(top: BorderSide(color: Color(0xFF2A2A3E))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF0F0F1C),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSending ? null : _sendMessage,
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF00BFFF),
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.send, color: Color(0xFF00BFFF)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF2A2A3E),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
