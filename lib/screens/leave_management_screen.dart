import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/leave_request.dart';
import '../services/leave_service.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  final LeaveService _leaveService = LeaveService();
  List<LeaveRequest> _leaveRequests = [];
  bool _isLoading = true;
  String _filter = 'All'; // All, Pending, Approved, Rejected

  @override
  void initState() {
    super.initState();
    _loadLeaveRequests();
  }

  Future<void> _loadLeaveRequests() async {
    setState(() => _isLoading = true);
    final requests = await _leaveService.getAllLeaveRequests();
    setState(() {
      _leaveRequests = requests;
      _isLoading = false;
    });
  }

  List<LeaveRequest> get _filteredRequests {
    if (_filter == 'All') return _leaveRequests;
    return _leaveRequests.where((req) => req.status == _filter).toList();
  }

  Future<void> _approveLeave(String id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await _leaveService.approveLeaveRequest(
      id,
      comments: authProvider.currentUser!.name,
    );
    _loadLeaveRequests();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Leave request approved')));
    }
  }

  Future<void> _rejectLeave(String id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await _leaveService.rejectLeaveRequest(
      id,
      reason: authProvider.currentUser!.name,
    );
    _loadLeaveRequests();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Leave request rejected')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Requests')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Pending', 'Approved', 'Rejected'].map((
                  filter,
                ) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      onSelected: (selected) {
                        setState(() => _filter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                ? const Center(child: Text('No leave requests found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredRequests.length,
                    itemBuilder: (context, index) {
                      final request = _filteredRequests[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(request.status),
                            child: Icon(
                              _getStatusIcon(request.status),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            request.employeeName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${request.leaveType} - ${request.daysCount} day(s)',
                          ),
                          trailing: Chip(
                            label: Text(
                              request.status,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: _getStatusColor(
                              request.status,
                            ).withOpacity(0.2),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow(
                                    'Start Date',
                                    DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(request.startDate),
                                  ),
                                  _buildDetailRow(
                                    'End Date',
                                    DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(request.endDate),
                                  ),
                                  _buildDetailRow('Reason', request.reason),
                                  _buildDetailRow(
                                    'Request Date',
                                    DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(request.requestDate),
                                  ),
                                  if (request.approvedBy != null)
                                    _buildDetailRow(
                                      'Approved By',
                                      request.approvedBy!,
                                    ),
                                  if (request.status == 'Pending') ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _approveLeave(request.id),
                                            icon: const Icon(Icons.check),
                                            label: const Text('Approve'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _rejectLeave(request.id),
                                            icon: const Icon(Icons.close),
                                            label: const Text('Reject'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.pending;
      case 'Approved':
        return Icons.check_circle;
      case 'Rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
