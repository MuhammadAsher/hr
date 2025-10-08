import '../models/organization.dart';

class OrganizationService {
  // Mock data storage - In production, this would be a database
  static final List<Organization> _organizations = [
    Organization(
      id: 'ORG001',
      name: 'Tech Solutions Inc.',
      email: 'admin@techsolutions.com',
      phone: '+1-555-0101',
      address: '123 Tech Street, Silicon Valley, CA 94025',
      industry: 'Technology',
      logo: 'https://via.placeholder.com/150',
      registeredDate: DateTime(2023, 1, 15),
      subscriptionPlan: SubscriptionPlan.premium,
      isActive: true,
      employeeLimit: 200,
      adminId: 'admin',
      taxId: 'TAX-001-2023',
      website: 'www.techsolutions.com',
      settings: {
        'workingHours': '9:00 AM - 5:00 PM',
        'workingDays': 'Monday - Friday',
        'currency': 'USD',
        'dateFormat': 'MM/DD/YYYY',
        'timeZone': 'PST',
      },
    ),
    Organization(
      id: 'ORG002',
      name: 'Global Marketing Agency',
      email: 'hr@globalmarketing.com',
      phone: '+1-555-0202',
      address: '456 Marketing Ave, New York, NY 10001',
      industry: 'Marketing',
      logo: 'https://via.placeholder.com/150',
      registeredDate: DateTime(2023, 3, 20),
      subscriptionPlan: SubscriptionPlan.basic,
      isActive: true,
      employeeLimit: 50,
      adminId: 'admin2',
      taxId: 'TAX-002-2023',
      website: 'www.globalmarketing.com',
      settings: {
        'workingHours': '8:00 AM - 6:00 PM',
        'workingDays': 'Monday - Saturday',
        'currency': 'USD',
        'dateFormat': 'DD/MM/YYYY',
        'timeZone': 'EST',
      },
    ),
  ];

  // Get all organizations (for super admin)
  Future<List<Organization>> getAllOrganizations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_organizations);
  }

  // Get organization by ID
  Future<Organization?> getOrganizationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _organizations.firstWhere((org) => org.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get active organizations
  Future<List<Organization>> getActiveOrganizations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _organizations.where((org) => org.isActive).toList();
  }

  // Register new organization
  Future<Organization> registerOrganization({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String industry,
    required String adminId,
    String subscriptionPlan = 'Free',
    String? logo,
    String? taxId,
    String? website,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final newOrg = Organization(
      id: _generateOrganizationId(),
      name: name,
      email: email,
      phone: phone,
      address: address,
      industry: industry,
      logo: logo ?? '',
      registeredDate: DateTime.now(),
      subscriptionPlan: subscriptionPlan,
      isActive: true,
      employeeLimit: SubscriptionPlan.employeeLimits[subscriptionPlan] ?? 10,
      adminId: adminId,
      taxId: taxId ?? '',
      website: website ?? '',
      settings: {
        'workingHours': '9:00 AM - 5:00 PM',
        'workingDays': 'Monday - Friday',
        'currency': 'USD',
        'dateFormat': 'MM/DD/YYYY',
        'timeZone': 'UTC',
      },
    );

    _organizations.add(newOrg);
    return newOrg;
  }

  // Update organization
  Future<bool> updateOrganization(Organization organization) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _organizations.indexWhere((org) => org.id == organization.id);
    if (index != -1) {
      _organizations[index] = organization;
      return true;
    }
    return false;
  }

  // Update subscription plan
  Future<bool> updateSubscriptionPlan(String organizationId, String newPlan) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _organizations.indexWhere((org) => org.id == organizationId);
    if (index != -1) {
      final org = _organizations[index];
      _organizations[index] = org.copyWith(
        subscriptionPlan: newPlan,
        employeeLimit: SubscriptionPlan.employeeLimits[newPlan] ?? 10,
      );
      return true;
    }
    return false;
  }

  // Deactivate organization
  Future<bool> deactivateOrganization(String organizationId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _organizations.indexWhere((org) => org.id == organizationId);
    if (index != -1) {
      final org = _organizations[index];
      _organizations[index] = org.copyWith(isActive: false);
      return true;
    }
    return false;
  }

  // Activate organization
  Future<bool> activateOrganization(String organizationId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _organizations.indexWhere((org) => org.id == organizationId);
    if (index != -1) {
      final org = _organizations[index];
      _organizations[index] = org.copyWith(isActive: true);
      return true;
    }
    return false;
  }

  // Delete organization
  Future<bool> deleteOrganization(String organizationId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _organizations.indexWhere((org) => org.id == organizationId);
    if (index != -1) {
      _organizations.removeAt(index);
      return true;
    }
    return false;
  }

  // Get organization statistics
  Future<Map<String, dynamic>> getOrganizationStats(String organizationId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final org = await getOrganizationById(organizationId);
    if (org == null) {
      return {};
    }

    // In production, these would be calculated from actual data
    return {
      'totalEmployees': 45,
      'activeEmployees': 42,
      'departments': 8,
      'pendingLeaves': 5,
      'subscriptionPlan': org.subscriptionPlan,
      'employeeLimit': org.employeeLimit,
      'usagePercentage': (45 / org.employeeLimit * 100).toStringAsFixed(1),
    };
  }

  // Get all organizations statistics (for super admin dashboard)
  Future<Map<String, dynamic>> getPlatformStats() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final activeOrgs = _organizations.where((org) => org.isActive).length;
    final totalOrgs = _organizations.length;

    final planDistribution = <String, int>{};
    for (var org in _organizations) {
      planDistribution[org.subscriptionPlan] = 
          (planDistribution[org.subscriptionPlan] ?? 0) + 1;
    }

    return {
      'totalOrganizations': totalOrgs,
      'activeOrganizations': activeOrgs,
      'inactiveOrganizations': totalOrgs - activeOrgs,
      'planDistribution': planDistribution,
      'totalRevenue': _calculateTotalRevenue(),
      'newOrganizationsThisMonth': _getNewOrganizationsCount(),
    };
  }

  // Search organizations
  Future<List<Organization>> searchOrganizations(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final lowerQuery = query.toLowerCase();
    return _organizations.where((org) {
      return org.name.toLowerCase().contains(lowerQuery) ||
          org.email.toLowerCase().contains(lowerQuery) ||
          org.industry.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Helper methods
  String _generateOrganizationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'ORG${timestamp.toString().substring(7)}';
  }

  double _calculateTotalRevenue() {
    double total = 0;
    for (var org in _organizations.where((o) => o.isActive)) {
      total += SubscriptionPlan.monthlyPrices[org.subscriptionPlan] ?? 0;
    }
    return total;
  }

  int _getNewOrganizationsCount() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    return _organizations
        .where((org) => org.registeredDate.isAfter(firstDayOfMonth))
        .length;
  }

  // Validate if organization can add more employees
  Future<bool> canAddEmployee(String organizationId) async {
    final org = await getOrganizationById(organizationId);
    if (org == null) return false;

    // If unlimited employees (enterprise plan)
    if (org.employeeLimit == -1) return true;

    // In production, get actual employee count from database
    final currentEmployeeCount = 45; // Mock data
    return currentEmployeeCount < org.employeeLimit;
  }
}

