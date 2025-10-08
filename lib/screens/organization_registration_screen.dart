import 'package:flutter/material.dart';
import '../models/organization.dart';
import '../services/organization_service.dart';

class OrganizationRegistrationScreen extends StatefulWidget {
  const OrganizationRegistrationScreen({super.key});

  @override
  State<OrganizationRegistrationScreen> createState() =>
      _OrganizationRegistrationScreenState();
}

class _OrganizationRegistrationScreenState
    extends State<OrganizationRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _organizationService = OrganizationService();

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _industryController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _websiteController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminNameController = TextEditingController();

  String _selectedPlan = SubscriptionPlan.free;
  bool _isRegistering = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _industryController.dispose();
    _taxIdController.dispose();
    _websiteController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _adminNameController.dispose();
    super.dispose();
  }

  Future<void> _registerOrganization() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRegistering = true);

    try {
      // In production, first create admin user, then create organization
      final adminId = 'admin_${DateTime.now().millisecondsSinceEpoch}';

      final organization = await _organizationService.registerOrganization(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        industry: _industryController.text,
        adminId: adminId,
        subscriptionPlan: _selectedPlan,
        taxId: _taxIdController.text,
        website: _websiteController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Organization "${organization.name}" registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login or admin setup
        Navigator.pop(context);
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
        setState(() => _isRegistering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Your Organization'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _registerOrganization();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _isRegistering ? null : details.onStepContinue,
                    child: _isRegistering
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentStep == 2 ? 'Register' : 'Continue'),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _isRegistering ? null : details.onStepCancel,
                      child: const Text('Back'),
                    ),
                ],
              ),
            );
          },
          steps: [
            // Step 1: Organization Details
            Step(
              title: const Text('Organization Details'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Organization Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter organization name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Organization Email *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _industryController,
                    decoration: const InputDecoration(
                      labelText: 'Industry *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                      hintText: 'e.g., Technology, Healthcare, Finance',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter industry';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _taxIdController,
                    decoration: const InputDecoration(
                      labelText: 'Tax ID (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Website (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.language),
                      hintText: 'www.example.com',
                    ),
                  ),
                ],
              ),
            ),

            // Step 2: Subscription Plan
            Step(
              title: const Text('Choose Plan'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  _buildPlanCard(SubscriptionPlan.free),
                  const SizedBox(height: 12),
                  _buildPlanCard(SubscriptionPlan.basic),
                  const SizedBox(height: 12),
                  _buildPlanCard(SubscriptionPlan.premium),
                  const SizedBox(height: 12),
                  _buildPlanCard(SubscriptionPlan.enterprise),
                ],
              ),
            ),

            // Step 3: Admin Account
            Step(
              title: const Text('Admin Account'),
              isActive: _currentStep >= 2,
              content: Column(
                children: [
                  const Text(
                    'Create an admin account for your organization',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adminNameController,
                    decoration: const InputDecoration(
                      labelText: 'Admin Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter admin name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adminEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Admin Email *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter admin email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adminPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Admin Password *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(String plan) {
    final isSelected = _selectedPlan == plan;
    final price = SubscriptionPlan.monthlyPrices[plan] ?? 0;
    final features = SubscriptionPlan.features[plan] ?? [];
    final employeeLimit = SubscriptionPlan.employeeLimits[plan] ?? 0;

    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedPlan = plan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    plan.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue : Colors.black87,
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.blue, size: 28),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                price == 0 ? 'Free' : '\$${price.toStringAsFixed(2)}/month',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                employeeLimit == -1
                    ? 'Unlimited employees'
                    : 'Up to $employeeLimit employees',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const Divider(height: 24),
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

