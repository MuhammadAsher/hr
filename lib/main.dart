import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/employee_dashboard.dart';
import 'screens/super_admin_dashboard.dart';
import 'models/user_role.dart';
import 'services/api_client.dart';
import 'services/error_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API client
  await ApiClient().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create global navigator key for error service
    final navigatorKey = GlobalKey<NavigatorState>();
    ErrorService.navigatorKey = navigatorKey;

    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'HR Management',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while checking auth status
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is authenticated, show appropriate dashboard
        if (authProvider.isAuthenticated) {
          final user = authProvider.currentUser!;

          // Check if super admin (platform administrator)
          if (user.isSuperAdmin) {
            return const SuperAdminDashboard();
          }
          // Check role for organization users
          else if (user.role == UserRole.admin) {
            return const AdminDashboard();
          } else {
            return const EmployeeDashboard();
          }
        }

        // If not authenticated, show login screen
        return const LoginScreen();
      },
    );
  }
}
