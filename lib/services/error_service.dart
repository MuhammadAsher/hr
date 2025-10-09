import 'package:flutter/material.dart';

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  // Global navigator key to show dialogs from anywhere
  static GlobalKey<NavigatorState>? navigatorKey;

  // Show error alert dialog
  static void showErrorAlert({
    required String title,
    required String message,
    String? error,
    int? code,
    VoidCallback? onOk,
  }) {
    final context = navigatorKey?.currentContext;
    if (context == null) {
      // Fallback to console if no context available
      print('ERROR: $title - $message');
      if (error != null) print('Error Type: $error');
      if (code != null) print('Error Code: $code');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
              if (error != null || code != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (error != null)
                        Text(
                          'Error: $error',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      if (code != null)
                        Text(
                          'Code: $code',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOk?.call();
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show error snackbar (less intrusive)
  static void showErrorSnackbar({
    required String message,
    String? error,
    int? code,
    Duration duration = const Duration(seconds: 4),
  }) {
    final context = navigatorKey?.currentContext;
    if (context == null) {
      print('ERROR: $message');
      return;
    }

    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (error != null)
                  Text(
                    error,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red[600],
      duration: duration,
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'DISMISS',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Parse API error response and show appropriate alert
  static void handleApiError({
    required Map<String, dynamic> errorResponse,
    String? fallbackMessage,
    bool useSnackbar = false,
    VoidCallback? onOk,
  }) {
    final message = errorResponse['message'] ?? fallbackMessage ?? 'An error occurred';
    final error = errorResponse['error'];
    final code = errorResponse['code'];

    if (useSnackbar) {
      showErrorSnackbar(
        message: message,
        error: error,
        code: code,
      );
    } else {
      showErrorAlert(
        title: 'Error',
        message: message,
        error: error,
        code: code,
        onOk: onOk,
      );
    }
  }

  // Show network error
  static void showNetworkError({bool useSnackbar = false}) {
    const message = 'Network connection failed. Please check your internet connection and try again.';
    
    if (useSnackbar) {
      showErrorSnackbar(message: message);
    } else {
      showErrorAlert(
        title: 'Network Error',
        message: message,
        error: 'Connection Failed',
      );
    }
  }

  // Show validation error
  static void showValidationError({
    required List<dynamic> validationErrors,
    bool useSnackbar = false,
  }) {
    final errorMessages = validationErrors
        .map((error) => '• ${error['msg'] ?? error['message'] ?? error.toString()}')
        .join('\n');
    
    const title = 'Validation Error';
    final message = 'Please correct the following errors:\n\n$errorMessages';
    
    if (useSnackbar) {
      showErrorSnackbar(message: 'Please check your input and try again');
    } else {
      showErrorAlert(
        title: title,
        message: message,
        error: 'Validation Failed',
        code: 400,
      );
    }
  }
}
