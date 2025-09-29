import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

class UserWelcomeDialog extends StatelessWidget {
  final int userNumber;
  final String userName;

  const UserWelcomeDialog({
    super.key,
    required this.userNumber,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: Responsive.height(context) * 0.8,
            maxWidth: Responsive.width(context) * 0.9,
          ),
          padding: Responsive.padding(context, size: Space.large),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.green[50]!],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration Icon
                Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.large),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.celebration,
                    size: 64,
                    color: Colors.green[600],
                  ),
                ),

                SizedBox(height: Responsive.space(context, size: Space.medium)),

                // Welcome Title
                Text(
                  'مرحباً بك $userName! 🎉',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.heading),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: Responsive.space(context, size: Space.medium)),

                // User Number Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.medium),
                    vertical: Responsive.space(context, size: Space.small),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, color: Colors.white, size: 20),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Flexible(
                        child: Text(
                          'المستخدم رقم #$userNumber',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Responsive.space(context, size: Space.medium)),

                // Milestone Badge
                _buildMilestoneBadge(context),

                SizedBox(height: Responsive.space(context, size: Space.medium)),

                // Welcome Message
                Container(
                  width: double.infinity,
                  padding: Responsive.padding(context, size: Space.medium),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    _getWelcomeMessage(),
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                SizedBox(height: Responsive.space(context, size: Space.large)),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: Responsive.space(context, size: Space.medium),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25), // Round button
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      'ابدأ رحلتك! 🚀',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneBadge(BuildContext context) {
    final milestone = _getUserMilestone();
    final colors = _getMilestoneColors();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      decoration: BoxDecoration(
        color: colors['light'],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors['border']!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getMilestoneIcon(), color: colors['main'], size: 18),
          SizedBox(width: Responsive.space(context, size: Space.small)),
          Flexible(
            child: Text(
              milestone,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                fontWeight: FontWeight.bold,
                color: colors['dark'],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getUserMilestone() {
    if (userNumber <= 100) {
      return 'المؤسسون الأوائل';
    } else if (userNumber <= 500) {
      return 'المبادرون';
    } else if (userNumber <= 1000) {
      return 'الرواد';
    } else if (userNumber <= 5000) {
      return 'المشاركون الأوائل';
    } else {
      return 'عضو';
    }
  }

  Map<String, Color?> _getMilestoneColors() {
    if (userNumber <= 100) {
      return {
        'light': Colors.purple[50],
        'border': Colors.purple[200],
        'main': Colors.purple[600],
        'dark': Colors.purple[700],
      };
    } else if (userNumber <= 500) {
      return {
        'light': Colors.blue[50],
        'border': Colors.blue[200],
        'main': Colors.blue[600],
        'dark': Colors.blue[700],
      };
    } else if (userNumber <= 1000) {
      return {
        'light': Colors.orange[50],
        'border': Colors.orange[200],
        'main': Colors.orange[600],
        'dark': Colors.orange[700],
      };
    } else {
      return {
        'light': Colors.green[50],
        'border': Colors.green[200],
        'main': Colors.green[600],
        'dark': Colors.green[700],
      };
    }
  }

  IconData _getMilestoneIcon() {
    if (userNumber <= 100) {
      return Icons.stars;
    } else if (userNumber <= 500) {
      return Icons.rocket_launch;
    } else if (userNumber <= 1000) {
      return Icons.explore;
    } else {
      return Icons.group;
    }
  }

  String _getWelcomeMessage() {
    if (userNumber <= 100) {
      return 'أنت من المؤسسين الأوائل! 🏆\n'
          'نتمنى أن نضيف قيمة لحياتك الأكاديمية 🎓\n'
          'شكراً لثقتك فينا منذ البداية!';
    } else if (userNumber <= 500) {
      return 'أنت من المبادرين! 🚀\n'
          'نتمنى أن نضيف قيمة لحياتك الأكاديمية 🎓\n'
          'نرحب بك في عائلتنا!';
    } else if (userNumber <= 1000) {
      return 'أنت من الرواد! ⭐\n'
          'نتمنى أن نضيف قيمة لحياتك الأكاديمية 🎓\n'
          'نرحب بك في مجتمعنا!';
    } else {
      return 'نتمنى أن نضيف قيمة لحياتك الأكاديمية 🎓\n'
          'نرحب بك في مجتمعنا!';
    }
  }
}
