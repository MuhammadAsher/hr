import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/employee.dart';
import '../models/leave_request.dart';
import '../models/task.dart';

class EmailService {
  // Email configuration - Gmail SMTP (Free & Reliable)
  // 
  // SETUP INSTRUCTIONS FOR GMAIL (RECOMMENDED):
  // 1. Enable 2-Factor Authentication on your Gmail account
  //    - Go to: https://myaccount.google.com/security
  //    - Click on "2-Step Verification" and enable it
  //
  // 2. Generate an App Password:
  //    - Go to: https://myaccount.google.com/apppasswords
  //    - Select "Mail" from the first dropdown
  //    - Select "Other (Custom name)" from the second dropdown
  //    - Enter "HR App" as the name
  //    - Click "Generate"
  //    - Copy the 16-character password (it will look like: abcd efgh ijkl mnop)
  //    - Remove all spaces when using it
  //
  // 3. Update the credentials below:
  //    - _username: Your Gmail address (e.g., 'yourname@gmail.com')
  //    - _password: The 16-character App Password (without spaces)
  //
  // ALTERNATIVE FREE SMTP OPTIONS:
  // - SendGrid: smtp.sendgrid.net, port 587 (free: 100 emails/day)
  //   Sign up: https://sendgrid.com
  //   Username: 'apikey', Password: your API key
  //
  // - SMTP2GO: smtp.smtp2go.com, port 2525 (free: 1,000 emails/month)
  //   Sign up: https://www.smtp2go.com
  //
  // - Brevo (Sendinblue): smtp.brevo.com, port 587 (free: 300 emails/day)
  //   Sign up: https://www.brevo.com
  //
  // - Mailtrap: sandbox.smtp.mailtrap.io, port 2525 (free: 100 emails/month)
  //   Sign up: https://mailtrap.io (if available)
  
  // Gmail SMTP Configuration (Default - Most Reliable)
  static const String _smtpHost = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  static const String _username = 'your-email@gmail.com'; // Replace with your Gmail address
  static const String _password = 'your-app-password';      // Replace with Gmail App Password (16 chars)
  static const String _companyName = 'HR Management System';
  
  // For production, use environment variables or secure storage
  // Example: static const String _username = String.fromEnvironment('SMTP_USERNAME', defaultValue: '');
  
  late SmtpServer _smtpServer;
  bool _isConfigured = false;

  EmailService() {
    // Check if credentials are configured
    _isConfigured = _username != 'your-email@gmail.com' && 
                    _password != 'your-app-password' &&
                    _username.contains('@') &&
                    _password.length >= 10;
    
    _smtpServer = SmtpServer(
      _smtpHost,
      port: _smtpPort,
      username: _username,
      password: _password,
      allowInsecure: false,
      ssl: false, // Gmail uses STARTTLS (TLS)
      ignoreBadCertificate: false,
    );
  }
  
  // Check if email is properly configured
  bool get isConfigured => _isConfigured;

  // Send leave request notification to manager
  Future<bool> sendLeaveRequestNotification({
    required LeaveRequest leaveRequest,
    required Employee employee,
    required Employee manager,
  }) async {
    try {
      final message = Message()
        ..from = Address(_username, _companyName)
        ..recipients.add(manager.email)
        ..subject = 'Leave Request - ${employee.name}'
        ..html = _buildLeaveRequestEmailTemplate(
          leaveRequest: leaveRequest,
          employee: employee,
          manager: manager,
        );

      final sendReport = await send(message, _smtpServer);
      return true; // For demo purposes, always return success
    } catch (e) {
      print('Error sending leave request notification: $e');
      return false;
    }
  }

  // Send leave approval/rejection notification to employee
  Future<bool> sendLeaveStatusNotification({
    required LeaveRequest leaveRequest,
    required Employee employee,
    required String status,
    String? comments,
  }) async {
    try {
      final message = Message()
        ..from = Address(_username, _companyName)
        ..recipients.add(employee.email)
        ..subject =
            'Leave Request ${status.toUpperCase()} - ${leaveRequest.leaveType}'
        ..html = _buildLeaveStatusEmailTemplate(
          leaveRequest: leaveRequest,
          employee: employee,
          status: status,
          comments: comments,
        );

      final sendReport = await send(message, _smtpServer);
      return true; // For demo purposes, always return success
    } catch (e) {
      print('Error sending leave status notification: $e');
      return false;
    }
  }

  // Send task assignment notification
  Future<bool> sendTaskAssignmentNotification({
    required Task task,
    required Employee assignee,
    required Employee assigner,
  }) async {
    try {
      final message = Message()
        ..from = Address(_username, _companyName)
        ..recipients.add(assignee.email)
        ..subject = 'New Task Assigned - ${task.title}'
        ..html = _buildTaskAssignmentEmailTemplate(
          task: task,
          assignee: assignee,
          assigner: assigner,
        );

      await send(message, _smtpServer);
      return true; // For demo purposes, always return success
    } catch (e) {
      print('Error sending task assignment notification: $e');
      return false;
    }
  }

  // Send welcome email to new employee
  Future<bool> sendWelcomeEmail({
    required Employee employee,
    required String temporaryPassword,
  }) async {
    try {
      final message = Message()
        ..from = Address(_username, _companyName)
        ..recipients.add(employee.email)
        ..subject = 'Welcome to $_companyName'
        ..html = _buildWelcomeEmailTemplate(
          employee: employee,
          temporaryPassword: temporaryPassword,
        );

      await send(message, _smtpServer);
      return true; // For demo purposes, always return success
    } catch (e) {
      print('Error sending welcome email: $e');
      return false;
    }
  }

  // Send payslip notification
  Future<bool> sendPayslipNotification({
    required Employee employee,
    required String payPeriod,
    List<int>? pdfAttachment,
  }) async {
    try {
      final message = Message()
        ..from = Address(_username, _companyName)
        ..recipients.add(employee.email)
        ..subject = 'Payslip for $payPeriod'
        ..html = _buildPayslipEmailTemplate(
          employee: employee,
          payPeriod: payPeriod,
        );

      // Add PDF attachment if provided
      if (pdfAttachment != null) {
        // For demo purposes, skip PDF attachment
        // message.attachments.add(FileAttachment(pdfAttachment));
      }

      await send(message, _smtpServer);
      return true; // For demo purposes, always return success
    } catch (e) {
      print('Error sending payslip notification: $e');
      return false;
    }
  }

  // Send birthday reminder
  Future<bool> sendBirthdayReminder({
    required Employee employee,
    required List<Employee> recipients,
  }) async {
    try {
      final message = Message()
        ..from = Address(_username, _companyName)
        ..recipients.addAll(recipients.map((e) => e.email))
        ..subject = '🎉 Birthday Reminder - ${employee.name}'
        ..html = _buildBirthdayEmailTemplate(employee: employee);

      await send(message, _smtpServer);
      return true; // For demo purposes, always return success
    } catch (e) {
      print('Error sending birthday reminder: $e');
      return false;
    }
  }

  // Email Templates

  String _buildLeaveRequestEmailTemplate({
    required LeaveRequest leaveRequest,
    required Employee employee,
    required Employee manager,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #2196F3; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background-color: #f9f9f9; }
            .details { background-color: white; padding: 15px; margin: 10px 0; border-radius: 5px; }
            .button { display: inline-block; padding: 10px 20px; background-color: #2196F3; color: white; text-decoration: none; border-radius: 5px; margin: 5px; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Leave Request Notification</h1>
            </div>
            <div class="content">
                <p>Dear ${manager.name},</p>
                <p>You have received a new leave request from <strong>${employee.name}</strong>.</p>
                
                <div class="details">
                    <h3>Leave Details:</h3>
                    <p><strong>Employee:</strong> ${employee.name}</p>
                    <p><strong>Department:</strong> ${employee.department}</p>
                    <p><strong>Leave Type:</strong> ${leaveRequest.leaveType}</p>
                    <p><strong>Start Date:</strong> ${leaveRequest.startDate.day}/${leaveRequest.startDate.month}/${leaveRequest.startDate.year}</p>
                    <p><strong>End Date:</strong> ${leaveRequest.endDate.day}/${leaveRequest.endDate.month}/${leaveRequest.endDate.year}</p>
                    <p><strong>Duration:</strong> ${leaveRequest.endDate.difference(leaveRequest.startDate).inDays + 1} days</p>
                    <p><strong>Reason:</strong> ${leaveRequest.reason}</p>
                </div>
                
                <p>Please review and approve/reject this leave request in the HR system.</p>
                
                <div style="text-align: center; margin: 20px 0;">
                    <a href="#" class="button">Review Request</a>
                </div>
            </div>
            <div class="footer">
                <p>This is an automated message from $_companyName</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  String _buildLeaveStatusEmailTemplate({
    required LeaveRequest leaveRequest,
    required Employee employee,
    required String status,
    String? comments,
  }) {
    final statusColor = status.toLowerCase() == 'approved'
        ? '#4CAF50'
        : '#F44336';
    final statusIcon = status.toLowerCase() == 'approved' ? '✅' : '❌';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: $statusColor; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background-color: #f9f9f9; }
            .details { background-color: white; padding: 15px; margin: 10px 0; border-radius: 5px; }
            .status { font-size: 24px; font-weight: bold; text-align: center; margin: 20px 0; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Leave Request Update</h1>
            </div>
            <div class="content">
                <p>Dear ${employee.name},</p>
                
                <div class="status" style="color: $statusColor;">
                    $statusIcon Your leave request has been ${status.toUpperCase()}
                </div>
                
                <div class="details">
                    <h3>Leave Details:</h3>
                    <p><strong>Leave Type:</strong> ${leaveRequest.leaveType}</p>
                    <p><strong>Start Date:</strong> ${leaveRequest.startDate.day}/${leaveRequest.startDate.month}/${leaveRequest.startDate.year}</p>
                    <p><strong>End Date:</strong> ${leaveRequest.endDate.day}/${leaveRequest.endDate.month}/${leaveRequest.endDate.year}</p>
                    <p><strong>Duration:</strong> ${leaveRequest.endDate.difference(leaveRequest.startDate).inDays + 1} days</p>
                    ${comments != null ? '<p><strong>Comments:</strong> $comments</p>' : ''}
                </div>
                
                <p>If you have any questions, please contact your manager or HR department.</p>
            </div>
            <div class="footer">
                <p>This is an automated message from $_companyName</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  String _buildTaskAssignmentEmailTemplate({
    required Task task,
    required Employee assignee,
    required Employee assigner,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #FF9800; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background-color: #f9f9f9; }
            .details { background-color: white; padding: 15px; margin: 10px 0; border-radius: 5px; }
            .priority { padding: 5px 10px; border-radius: 3px; color: white; font-weight: bold; }
            .high { background-color: #F44336; }
            .medium { background-color: #FF9800; }
            .low { background-color: #4CAF50; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>New Task Assignment</h1>
            </div>
            <div class="content">
                <p>Dear ${assignee.name},</p>
                <p>You have been assigned a new task by <strong>${assigner.name}</strong>.</p>
                
                <div class="details">
                    <h3>Task Details:</h3>
                    <p><strong>Title:</strong> ${task.title}</p>
                    <p><strong>Description:</strong> ${task.description}</p>
                    <p><strong>Priority:</strong> <span class="priority ${task.priority.toLowerCase()}">${task.priority}</span></p>
                    <p><strong>Due Date:</strong> ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}</p>
                    <p><strong>Assigned by:</strong> ${assigner.name}</p>
                </div>
                
                <p>Please log into the HR system to view more details and update the task status.</p>
            </div>
            <div class="footer">
                <p>This is an automated message from $_companyName</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  String _buildWelcomeEmailTemplate({
    required Employee employee,
    required String temporaryPassword,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background-color: #f9f9f9; }
            .credentials { background-color: #fff3cd; padding: 15px; margin: 10px 0; border-radius: 5px; border-left: 4px solid #ffc107; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Welcome to $_companyName!</h1>
            </div>
            <div class="content">
                <p>Dear ${employee.name},</p>
                <p>Welcome to our team! We're excited to have you join us in the ${employee.department} department as a ${employee.position}.</p>
                
                <div class="credentials">
                    <h3>Your Login Credentials:</h3>
                    <p><strong>Email:</strong> ${employee.email}</p>
                    <p><strong>Temporary Password:</strong> $temporaryPassword</p>
                    <p><em>Please change your password after your first login.</em></p>
                </div>
                
                <p>You can access the HR system to:</p>
                <ul>
                    <li>View your profile and update personal information</li>
                    <li>Apply for leave</li>
                    <li>View payslips</li>
                    <li>Check attendance records</li>
                    <li>Access team directory</li>
                </ul>
                
                <p>If you have any questions, please don't hesitate to reach out to your manager or the HR team.</p>
                
                <p>Welcome aboard!</p>
            </div>
            <div class="footer">
                <p>This is an automated message from $_companyName</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  String _buildPayslipEmailTemplate({
    required Employee employee,
    required String payPeriod,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #2196F3; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background-color: #f9f9f9; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Payslip Available</h1>
            </div>
            <div class="content">
                <p>Dear ${employee.name},</p>
                <p>Your payslip for <strong>$payPeriod</strong> is now available.</p>
                
                <p>Please find your payslip attached to this email. You can also access it through the HR system.</p>
                
                <p>If you have any questions about your payslip, please contact the HR department.</p>
            </div>
            <div class="footer">
                <p>This is an automated message from $_companyName</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  String _buildBirthdayEmailTemplate({required Employee employee}) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #E91E63; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background-color: #f9f9f9; text-align: center; }
            .birthday { font-size: 48px; margin: 20px 0; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎉 Birthday Celebration! 🎉</h1>
            </div>
            <div class="content">
                <div class="birthday">🎂</div>
                <h2>Happy Birthday ${employee.name}!</h2>
                <p>Today is ${employee.name}'s birthday!</p>
                <p>Let's all wish them a wonderful day and a fantastic year ahead.</p>
                <p>Department: ${employee.department}</p>
            </div>
            <div class="footer">
                <p>This is an automated message from $_companyName</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  // Test email configuration
  Future<bool> testEmailConfiguration() async {
    if (!_isConfigured) {
      print('Email not configured. Please update SMTP credentials in EmailService.');
      return false;
    }
    
    try {
      final message = Message()
        ..from = Address(_username, _companyName)
        ..recipients.add(_username)
        ..subject = 'Email Configuration Test'
        ..text = 'This is a test email to verify email configuration.';

      await send(message, _smtpServer);
      print('Email configuration test successful!');
      return true;
    } catch (e) {
      print('Error testing email configuration: $e');
      print('Please verify your SMTP credentials are correct.');
      return false;
    }
  }
}
