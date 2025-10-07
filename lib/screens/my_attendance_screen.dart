import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/attendance.dart';
import '../services/attendance_service.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  List<Attendance> _attendanceRecords = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final records = await _attendanceService.getAttendanceByEmployee(
      authProvider.currentUser!.id,
    );
    final stats = await _attendanceService.getAttendanceStats(
      authProvider.currentUser!.id,
    );
    setState(() {
      _attendanceRecords = records;
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Section
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Attendance Rate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_stats['attendancePercentage'] ?? '0'}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Present',
                              _stats['presentDays']?.toString() ?? '0',
                              Icons.check_circle,
                            ),
                            _buildStatItem(
                              'Leave',
                              _stats['leaveDays']?.toString() ?? '0',
                              Icons.event_busy,
                            ),
                            _buildStatItem(
                              'Half Day',
                              _stats['halfDays']?.toString() ?? '0',
                              Icons.access_time,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Attendance Records
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Attendance History',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _attendanceRecords.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No attendance records')),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _attendanceRecords.length,
                          itemBuilder: (context, index) {
                            final record = _attendanceRecords[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(record.status),
                                  child: Icon(
                                    _getStatusIcon(record.status),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  DateFormat('EEEE, MMM dd, yyyy').format(record.date),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    if (record.checkIn != null && record.checkOut != null)
                                      Text(
                                        'Check In: ${DateFormat('hh:mm a').format(record.checkIn!)} | '
                                        'Check Out: ${DateFormat('hh:mm a').format(record.checkOut!)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    if (record.checkIn != null && record.checkOut != null)
                                      Text(
                                        'Working Hours: ${record.workingHours}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Chip(
                                  label: Text(
                                    record.status,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor:
                                      _getStatusColor(record.status).withOpacity(0.2),
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Absent':
        return Colors.red;
      case 'Leave':
        return Colors.orange;
      case 'Half Day':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Present':
        return Icons.check_circle;
      case 'Absent':
        return Icons.cancel;
      case 'Leave':
        return Icons.event_busy;
      case 'Half Day':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }
}

