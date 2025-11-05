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
        return leaveRequests.map((json) {
          // Convert backend format to UI format if needed
          final mappedJson = Map<String, dynamic>.from(json);
          if (mappedJson.containsKey('leaveType')) {
            mappedJson['leaveType'] = _mapLeaveTypeFromBackend(mappedJson['leaveType'] as String);
          }
          return LeaveRequest.fromJson(mappedJson);
        }).toList();
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
        final json = Map<String, dynamic>.from(response.data['data']);
        // Convert backend format to UI format if needed
        if (json.containsKey('leaveType')) {
          json['leaveType'] = _mapLeaveTypeFromBackend(json['leaveType'] as String);
        }
        return LeaveRequest.fromJson(json);
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

  // Map UI leave type to backend format
  String _mapLeaveTypeToBackend(String uiLeaveType) {
    switch (uiLeaveType.toLowerCase()) {
      case 'annual leave':
        return 'annual';
      case 'sick leave':
        return 'sick';
      case 'casual leave':
        return 'personal';
      case 'maternity leave':
        return 'maternity';
      case 'paternity leave':
        return 'paternity';
      case 'unpaid leave':
        return 'emergency';
      default:
        // If already in backend format, return as is
        return uiLeaveType.toLowerCase();
    }
  }

  // Map backend leave type to UI format
  String _mapLeaveTypeFromBackend(String backendLeaveType) {
    switch (backendLeaveType.toLowerCase()) {
      case 'annual':
        return 'Annual Leave';
      case 'sick':
        return 'Sick Leave';
      case 'personal':
        return 'Casual Leave';
      case 'maternity':
        return 'Maternity Leave';
      case 'paternity':
        return 'Paternity Leave';
      case 'emergency':
        return 'Unpaid Leave';
      default:
        return backendLeaveType;
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
      // Convert UI leave type to backend format
      final backendLeaveType = _mapLeaveTypeToBackend(type);
      
      final body = <String, dynamic>{
        'leaveType': backendLeaveType, // Backend expects 'leaveType', not 'type'
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'reason': reason.trim(),
      };

      if (employeeId != null) body['employeeId'] = employeeId;

      final response = await _apiClient.post('/leave-requests', body: body);
      
      if (!response.isSuccess) {
        throw Exception(response.message ?? 'Failed to submit leave request');
      }
      
      return true;
    } catch (e) {
      rethrow;
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

      if (type != null) body['leaveType'] = _mapLeaveTypeToBackend(type);
      if (startDate != null) body['startDate'] = startDate.toIso8601String();
      if (endDate != null) body['endDate'] = endDate.toIso8601String();
      if (reason != null) body['reason'] = reason.trim();

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
