import '../models/leave_request.dart';
import 'api_client.dart';

class LeaveService {
  final ApiClient _apiClient = ApiClient();

  // Get all leave requests
  Future<List<LeaveRequest>> getAllLeaveRequests({
    int page = 1,
    int limit = 10,
    String? status,
    String? employeeId,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status != 'all') queryParams['status'] = status;
      if (employeeId != null) queryParams['employeeId'] = employeeId;

      final response = await _apiClient.get(
        '/leave-requests',
        queryParams: queryParams,
      );

      if (response.isSuccess) {
        final responseData = response.data['data'];
        final List<dynamic> leaveRequests = responseData['leaveRequests'] ?? [];
        return leaveRequests
            .map((json) => LeaveRequest.fromJson(json))
            .toList();
      } else {
        throw Exception(response.message ?? 'Failed to fetch leave requests');
      }
    } catch (e) {
      // Fallback to mock data if API fails
      return _getMockLeaveRequests();
    }
  }

  // Get leave request by ID
  Future<LeaveRequest?> getLeaveRequestById(String requestId) async {
    try {
      final response = await _apiClient.get('/leave-requests/$requestId');

      if (response.isSuccess) {
        return LeaveRequest.fromJson(response.data['data']);
      } else {
        throw Exception(response.message ?? 'Failed to fetch leave request');
      }
    } catch (e) {
      // Fallback to mock data
      final mockRequests = _getMockLeaveRequests();
      return mockRequests.firstWhere(
        (request) => request.id == requestId,
        orElse: () => mockRequests.first,
      );
    }
  }

  // Submit new leave request
  Future<bool> submitLeaveRequest({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? employeeId,
  }) async {
    try {
      final body = <String, dynamic>{
        'type': type,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'reason': reason,
      };

      if (employeeId != null) body['employeeId'] = employeeId;

      final response = await _apiClient.post('/leave-requests', body: body);
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Update leave request
  Future<bool> updateLeaveRequest({
    required String requestId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (type != null) body['type'] = type;
      if (startDate != null) body['startDate'] = startDate.toIso8601String();
      if (endDate != null) body['endDate'] = endDate.toIso8601String();
      if (reason != null) body['reason'] = reason;

      final response = await _apiClient.put(
        '/leave-requests/$requestId',
        body: body,
      );
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Approve leave request (Admin only)
  Future<bool> approveLeaveRequest(String requestId, {String? comments}) async {
    try {
      final body = <String, dynamic>{};
      if (comments != null) body['comments'] = comments;

      final response = await _apiClient.post(
        '/leave-requests/$requestId/approve',
        body: body,
      );
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Reject leave request (Admin only)
  Future<bool> rejectLeaveRequest(String requestId, {String? reason}) async {
    try {
      final body = <String, dynamic>{};
      if (reason != null) body['reason'] = reason;

      final response = await _apiClient.post(
        '/leave-requests/$requestId/reject',
        body: body,
      );
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Delete leave request
  Future<bool> deleteLeaveRequest(String requestId) async {
    try {
      final response = await _apiClient.delete('/leave-requests/$requestId');
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Fallback mock data method
  List<LeaveRequest> _getMockLeaveRequests() {
    return [
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
  }

  // Legacy method - now uses API
  Future<List<LeaveRequest>> getLeaveRequests() async {
    return await getAllLeaveRequests();
  }

  // Get pending leave requests
  Future<List<LeaveRequest>> getPendingLeaveRequests() async {
    return await getAllLeaveRequests(status: 'Pending', limit: 100);
  }

  // Get leave requests by employee
  Future<List<LeaveRequest>> getLeaveRequestsByEmployee(
    String employeeId,
  ) async {
    return await getAllLeaveRequests(employeeId: employeeId, limit: 100);
  }

  // Create leave request (legacy method - now uses submitLeaveRequest)
  Future<bool> createLeaveRequest(LeaveRequest request) async {
    return await submitLeaveRequest(
      type: request.leaveType,
      startDate: request.startDate,
      endDate: request.endDate,
      reason: request.reason,
      employeeId: request.employeeId,
    );
  }
}
