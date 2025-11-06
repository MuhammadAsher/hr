import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _apiClient = ApiClient();
  bool _isLoading = false;
  String? _resetToken;
  bool _tokenSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _apiClient.initialize();
        final response = await _apiClient.requestPasswordReset(
          _emailController.text.trim(),
        );

        if (response.isSuccess && mounted) {
          setState(() {
            _tokenSent = true;
            _isLoading = false;
          });

          // In development, the API returns the token in the response
          // In production, this would be sent via email
          String? resetToken;
          if (response.data != null) {
            // Response structure: { status: true, message: "...", data: { resetToken: "..." } }
            if (response.data is Map && response.data['resetToken'] != null) {
              resetToken = response.data['resetToken'] as String;
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  resetToken != null
                      ? 'Password reset token generated. Enter it in the dialog below.'
                      : 'Password reset instructions have been sent to your email. Check your email for the reset token.',
                ),
                backgroundColor: Colors.green,
              ),
            );

            // In development with token, auto-navigate or show dialog
            if (resetToken != null) {
              // Auto-navigate to reset screen with token
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ResetPasswordScreen(
                    resetToken: resetToken!,
                  ),
                ),
              );
            } else {
              // In production, show dialog to enter token manually
              _showTokenInputDialog();
            }
          }
        } else if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message ?? 'Failed to send password reset request',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showTokenInputDialog() {
    final tokenController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Reset Token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Check your email for the password reset token, or check the server console logs (in development mode).',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Reset Token',
                hintText: 'Paste the token from email or console',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tokenController.text.isNotEmpty) {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResetPasswordScreen(
                      resetToken: tokenController.text.trim(),
                    ),
                  ),
                );
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_reset,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Forgot Password?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email address and we\'ll send you instructions to reset your password.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  if (!_tokenSent) ...[
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Request Reset Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRequestReset,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Send Reset Instructions',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.green[700],
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Reset Instructions Sent!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please check your email for the password reset token.',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Back to Login Link
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

