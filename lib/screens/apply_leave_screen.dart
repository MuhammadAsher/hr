import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/leave_request.dart';
import '../services/leave_service.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final LeaveService _leaveService = LeaveService();
  
  String _selectedLeaveType = 'Annual Leave';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  List<LeaveRequest> _myLeaveRequests = [];

  final List<String> _leaveTypes = [
    'Annual Leave',
    'Sick Leave',
    'Casual Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Unpaid Leave',
  ];

  @override
  void initState() {
    super.initState();
    _loadMyLeaveRequests();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadMyLeaveRequests() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final requests = await _leaveService.getLeaveRequestsByEmployee(
      authProvider.currentUser!.id,
    );
    setState(() => _myLeaveRequests = requests);
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final request = LeaveRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        employeeId: authProvider.currentUser!.id,
        employeeName: authProvider.currentUser!.name,
        leaveType: _selectedLeaveType,
        startDate: _startDate,
        endDate: _endDate,
        reason: _reasonController.text,
        requestDate: DateTime.now(),
      );

      await _leaveService.createLeaveRequest(request);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request submitted successfully')),
        );
        _reasonController.clear();
        _loadMyLeaveRequests();
      }
    }
  }

  int get _daysCount {
    return _endDate.difference(_startDate).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Leave'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Leave Application Form
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'New Leave Request',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLeaveType,
                        decoration: const InputDecoration(
                          labelText: 'Leave Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _leaveTypes.map((type) {
                          return DropdownMenuItem(value: type, child: Text(type));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedLeaveType = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectStartDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectEndDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Total Days: $_daysCount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter reason' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitLeaveRequest,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Submit Request'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // My Leave Requests
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'My Leave Requests',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _myLeaveRequests.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No leave requests yet'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _myLeaveRequests.length,
                    itemBuilder: (context, index) {
                      final request = _myLeaveRequests[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(request.status),
                            child: Icon(
                              _getStatusIcon(request.status),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(request.leaveType),
                          subtitle: Text(
                            '${DateFormat('MMM dd').format(request.startDate)} - ${DateFormat('MMM dd, yyyy').format(request.endDate)} (${request.daysCount} days)',
                          ),
                          trailing: Chip(
                            label: Text(
                              request.status,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor:
                                _getStatusColor(request.status).withOpacity(0.2),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 16),
          ],
        ),
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

