import 'package:flutter/material.dart';
import 'package:pivot/services/notification_service.dart';
import 'package:pivot/responsive.dart';

class NotificationTestWidget extends StatefulWidget {
  const NotificationTestWidget({super.key});

  @override
  State<NotificationTestWidget> createState() => _NotificationTestWidgetState();
}

class _NotificationTestWidgetState extends State<NotificationTestWidget> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  String? _currentToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentToken();
  }

  Future<void> _loadCurrentToken() async {
    final token = await NotificationService().getToken();
    setState(() {
      _currentToken = token;
    });
  }

  Future<void> _sendNotification() async {
    if (_tokenController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a token')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await NotificationService().sendNotification(
        targetToken: _tokenController.text,
        title:
            _titleController.text.isNotEmpty
                ? _titleController.text
                : 'Test Title',
        body:
            _bodyController.text.isNotEmpty
                ? _bodyController.text
                : 'Test Body',
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send notification')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Device Token:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: Responsive.space(context, size: Space.small)),
                    Text(
                      _currentToken ?? 'Loading...',
                      style: const TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: Responsive.space(context, size: Space.small)),
                    ElevatedButton(
                      onPressed: _loadCurrentToken,
                      child: const Text('Refresh Token'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Target FCM Token',
                border: OutlineInputBorder(),
                hintText: 'Enter the FCM token of the target device',
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Notification Title',
                border: OutlineInputBorder(),
                hintText: 'Enter notification title',
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Notification Body',
                border: OutlineInputBorder(),
                hintText: 'Enter notification body',
              ),
              maxLines: 3,
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendNotification,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Send Notification'),
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            const Text(
              '1. Copy the current device token above\n'
              '2. Paste it in the "Target FCM Token" field\n'
              '3. Enter a title and body for the notification\n'
              '4. Press "Send Notification" to test',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tokenController.dispose();
    super.dispose();
  }
}
