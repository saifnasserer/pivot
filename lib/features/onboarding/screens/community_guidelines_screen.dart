import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'قواعد المجتمع',
            style: TextStyle(
              color: Colors.black,
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.large),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.green[50]!],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size:
                          Responsive.text(context, size: TextSize.heading) * 2,
                      color: Colors.blue[700],
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Text(
                      'معاً نبني مجتمعاً آمناً',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.heading,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: Responsive.space(context, size: Space.large)),

              _buildSection(
                context,
                'كن محترماً',
                'تعامل مع الآخرين باحترام ولطف. التنمر والمضايقة والتهديدات غير مسموح بها.',
                Icons.favorite_outline,
                Colors.red,
              ),

              _buildSection(
                context,
                'لا للكراهية',
                'خطاب الكراهية والتمييز على أساس العرق أو الدين أو الجنس غير مقبول.',
                Icons.heart_broken_outlined,
                Colors.orange,
              ),

              _buildSection(
                context,
                'لا للبريد العشوائي',
                'تجنب إرسال رسائل ترويجية أو غير مرغوب فيها.',
                Icons.mail_outline,
                Colors.purple,
              ),

              _buildSection(
                context,
                'احترم الخصوصية',
                'لا تشارك معلومات شخصية للآخرين بدون إذنهم.',
                Icons.privacy_tip_outlined,
                Colors.green,
              ),

              _buildSection(
                context,
                'النزاهة الأكاديمية',
                'لا تستخدم التطبيق للغش أو انتهاك حقوق النشر.',
                Icons.school_outlined,
                Colors.blue,
              ),

              _buildSection(
                context,
                'أبلغ عن المخالفات',
                'إذا رأيت محتوى ينتهك هذه القواعد، استخدم زر الإبلاغ.',
                Icons.flag_outlined,
                Colors.red[700]!,
              ),

              _buildSection(
                context,
                'عواقب انتهاك القواعد',
                'في حالة انتهاك هذه القواعد قد نتخذ الإجراءات التالية:\n\n'
                    '• حذف المحتوى المخالف\n'
                    '• تعليق الحساب مؤقتاً\n'
                    '• حذف الحساب نهائياً في حالات الانتهاكات الخطيرة',
                Icons.warning_amber,
                Colors.red,
              ),

              SizedBox(height: Responsive.space(context, size: Space.xlarge)),

              // Footer
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.large),
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: Responsive.text(context, size: TextSize.heading),
                      color: Colors.green[600],
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    Text(
                      'معاً نبني مجتمعاً آمناً ومحترماً',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    Text(
                      'شكراً لالتزامك بقواعد المجتمع',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.large),
      ),
      padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.small),
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: Responsive.text(context, size: TextSize.medium),
                ),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.heading),
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          Text(
            content,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
