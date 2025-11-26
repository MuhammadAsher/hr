# Email SMTP Setup Guide

This guide will help you configure free SMTP settings for the HR Management System.

## Quick Setup with Gmail (Recommended - Most Reliable)

Gmail SMTP is free, reliable, and works immediately once configured. Perfect for both development and production use.

### Steps:

1. **Enable 2-Factor Authentication**
   - Go to: https://myaccount.google.com/security
   - Click on **2-Step Verification**
   - Follow the setup process (you'll need your phone)

2. **Generate App Password**
   - Go to: https://myaccount.google.com/apppasswords
   - Select **Mail** from the first dropdown
   - Select **Other (Custom name)** from the second dropdown
   - Enter "HR App" as the name
   - Click **Generate**
   - **Copy the 16-character password** (it will look like: `abcd efgh ijkl mnop`)
   - Remove all spaces when using it

3. **Update EmailService**
   - Open `lib/services/email_service.dart`
   - Replace the placeholder values:
     ```dart
     static const String _username = 'your-email@gmail.com'; // Replace with your Gmail address
     static const String _password = 'your-app-password';      // Replace with the 16-char App Password
     ```
   - Save the file

4. **Test Configuration**
   - Run the app
   - Navigate to **Email Notifications** screen
   - The status should show "Email Configured" if credentials are correct
   - Try sending a test email
   - Check your Gmail inbox (and spam folder) for the test email

## Alternative Free SMTP Services

### Option 1: SendGrid (Free Tier: 100 emails/day)

1. Sign up at https://sendgrid.com (free account)
2. Go to Settings > API Keys
3. Create an API key with "Mail Send" permissions
4. Update EmailService with:
   ```dart
   static const String _smtpHost = 'smtp.sendgrid.net';
   static const int _smtpPort = 587;
   static const String _username = 'apikey';
   static const String _password = 'your-sendgrid-api-key';
   ```

### Option 2: SMTP2GO (Free Tier: 1,000 emails/month)

1. Sign up at https://www.smtp2go.com (free account)
2. Go to Settings > SMTP Users
3. Create a new SMTP user or use default
4. Update EmailService with:
   ```dart
   static const String _smtpHost = 'smtp.smtp2go.com';
   static const int _smtpPort = 2525;
   static const String _username = 'your-smtp2go-username';
   static const String _password = 'your-smtp2go-password';
   ```
   Also change: `allowInsecure: true`

### Option 3: Brevo (Sendinblue) (Free Tier: 300 emails/day)

1. Sign up at https://www.brevo.com (free account)
2. Go to SMTP & API > SMTP
3. Copy your SMTP credentials
4. Update EmailService with:
   ```dart
   static const String _smtpHost = 'smtp.brevo.com';
   static const int _smtpPort = 587;
   static const String _username = 'your-brevo-email';
   static const String _password = 'your-brevo-smtp-key';
   ```

## Production Considerations

For production environments:
- Use environment variables instead of hardcoded credentials
- Store sensitive credentials securely (e.g., using `flutter_dotenv` or secure storage)
- Consider using a dedicated email service (SendGrid, Mailgun, AWS SES, etc.)
- Implement proper error handling and retry logic
- Monitor email delivery rates and bounce rates

## Troubleshooting

### "Email Not Configured" Error
- Verify credentials are correctly updated in `email_service.dart`
- Check that you've replaced both username and password placeholders
- Ensure there are no extra spaces in credentials

### Connection Errors
- Verify SMTP host and port are correct
- Check internet connectivity
- For Mailtrap: Ensure you're using the sandbox SMTP (not production)
- For Gmail: Ensure "Less secure app access" is enabled OR use App Password

### Authentication Errors
- Double-check username and password
- For Gmail: Make sure you're using App Password, not regular password
- For SendGrid: Use 'apikey' as username and your API key as password

## Current Configuration

The app is currently configured to use **Gmail SMTP** by default. This is perfect for:
- Reliable email delivery
- Free unlimited emails (within Gmail limits)
- Works immediately after setup
- Suitable for both development and production
- No third-party service dependencies

**Note**: Gmail SMTP requires 2-Factor Authentication and an App Password. This is a one-time setup that takes about 5 minutes.

To switch to a different service, simply update the SMTP settings in `lib/services/email_service.dart`.

