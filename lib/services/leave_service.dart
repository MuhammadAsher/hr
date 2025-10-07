import '../models/leave_request.dart';

class LeaveService {
  final List<LeaveRequest> _leaveRequests = [
    LeaveRequest(
      id: '1',
      employeeId: '2',
      employeeName: 'Employee User',
      leaveType: 'Sick Leave',
      startDate: DateTime.now().add(const Duration(days: 5)),
      endDate: DateTime.now().add(const Duration(days: 7)),
      reason: 'Medical appointment',
      status: 'Pending',
      requestDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    LeaveRequest(
      id: '2',
      employeeId: '1',
      employeeName: 'John Doe',
      leaveType: 'Annual Leave',
      startDate: DateTime.now().add(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 15)),
      reason: 'Family vacation',
      status: 'Pending',
      requestDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    LeaveRequest(
      id: '3',
      employeeId: '3',
      employeeName: 'Mike Johnson',
      leaveType: 'Annual Leave',
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now().subtract(const Duration(days: 8)),
      reason: 'Personal matters',
      status: 'Approved',
      requestDate: DateTime.now().subtract(const Duration(days: 15)),
      approvedBy: 'Admin User',
      approvedDate: DateTime.now().subtract(const Duration(days: 14)),
    ),
  ];

  Future<List<LeaveRequest>> getAllLeaveRequests() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_leaveRequests);
  }

  Future<List<LeaveRequest>> getPendingLeaveRequests() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _leaveRequests.where((req) => req.status == 'Pending').toList();
  }

  Future<List<LeaveRequest>> getLeaveRequestsByEmployee(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _leaveRequests.where((req) => req.employeeId == employeeId).toList();
  }

  Future<bool> createLeaveRequest(LeaveRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _leaveRequests.add(request);
    return true;
  }

  Future<bool> approveLeaveRequest(String id, String approvedBy) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _leaveRequests.indexWhere((req) => req.id == id);
    if (index != -1) {
      _leaveRequests[index] = _leaveRequests[index].copyWith(
        status: 'Approved',
        approvedBy: approvedBy,
        approvedDate: DateTime.now(),
      );
      return true;
    }
    return false;
  }

  Future<bool> rejectLeaveRequest(String id, String approvedBy) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _leaveRequests.indexWhere((req) => req.id == id);
    if (index != -1) {
      _leaveRequests[index] = _leaveRequests[index].copyWith(
        status: 'Rejected',
        approvedBy: approvedBy,
        approvedDate: DateTime.now(),
      );
      return true;
    }
    return false;
  }

  Future<bool> deleteLeaveRequest(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _leaveRequests.indexWhere((req) => req.id == id);
    if (index != -1) {
      _leaveRequests.removeAt(index);
      return true;
    }
    return false;
  }
}

