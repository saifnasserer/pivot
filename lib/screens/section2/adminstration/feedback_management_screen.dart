import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pivot/responsive.dart';

class FeedbackManagementScreen extends StatefulWidget {
  static const String id = 'feedback_management_screen';

  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() =>
      _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  Future<void> _updateFeedbackStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('feedback').doc(docId).update(
        {'status': status},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feedback marked as $status.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFeedbackDetails(Map<String, dynamic> feedback, String docId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              feedback['type']?.toString().toUpperCase() ?? 'FEEDBACK',
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text(
                    'User: ${feedback['userName'] ?? 'Unknown'} (${feedback['userEmail'] ?? 'No email'})',
                  ),
                  const SizedBox(height: 8),
                  Text('Role: ${feedback['userRole'] ?? 'N/A'}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Feedback:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(feedback['feedback'] ?? 'No feedback content.'),
                  const SizedBox(height: 16),
                  const Text(
                    'Suggestion:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(feedback['suggestion'] ?? 'No suggestion content.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Mark as Read'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _updateFeedbackStatus(docId, 'Read');
                },
              ),
              TextButton(
                child: const Text('Archive'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _updateFeedbackStatus(docId, 'Archived');
                },
              ),
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Management'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('feedback')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No feedback has been submitted yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final feedbackDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.medium),
            ),
            itemCount: feedbackDocs.length,
            itemBuilder: (context, index) {
              final feedback =
                  feedbackDocs[index].data() as Map<String, dynamic>;
              final timestamp = feedback['timestamp'] as Timestamp?;
              final formattedDate =
                  timestamp != null
                      ? DateFormat(
                        'MMM d, yyyy – hh:mm a',
                      ).format(timestamp.toDate())
                      : 'Date not available';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback['type']?.toString().toUpperCase() ??
                            'FEEDBACK',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Divider(height: 20),
                      Text(
                        feedback['feedback'] ?? 'No content provided.',
                        style: const TextStyle(fontSize: 16, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'User ID: ${feedback['userId'] ?? 'Anonymous'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
