import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
            'سياسة الخصوصية',
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
              // Header Section
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
                      Icons.privacy_tip_outlined,
                      size:
                          Responsive.text(context, size: TextSize.heading) * 2,
                      color: Colors.blue[700],
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Text(
                      'نحن نحترم خصوصيتك',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.heading,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    Text(
                      'آخر تحديث: سبتمبر 2025',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: Responsive.space(context, size: Space.large)),

              // Introduction
              _buildSection(
                context,
                'مقدمة',
                'تطبيق Pivot هو منصة تعليمية مصممة لطلاب الجامعة وأعضاء هيئة التدريس. نحن ملتزمون بحماية خصوصيتك وضمان أمان بياناتك الشخصية.',
                Icons.info_outline,
                Colors.blue,
              ),

              // Data Collection
              _buildSection(
                context,
                'البيانات التي نجمعها',
                'نجمع البيانات التالية لتوفير أفضل تجربة تعليمية:\n\n'
                    '• الاسم والبريد الإلكتروني للتواصل\n'
                    '• المعلومات الأكاديمية (القسم، المستوى، الشعبة)\n'
                    '• صور الملف الشخصي (اختيارية)\n'
                    '• بيانات الاستخدام لتحسين التطبيق\n'
                    '• رموز الإشعارات لإرسال التذكيرات المهمة',
                Icons.data_usage,
              Colors.green,
              ),

              // How We Use Data
              _buildSection(
                context,
                'كيف نستخدم بياناتك',
                'نستخدم بياناتك لـ:\n\n'
                    '• توفير المحتوى التعليمي المخصص\n'
                    '• إدارة الجدول الدراسي والمهام\n'
                    '• إرسال الإشعارات المهمة\n'
                    '• تحسين أداء التطبيق\n'
                    '• التواصل معك حول التحديثات',
                Icons.how_to_reg,
                Colors.orange,
              ),

              // Data Security
              _buildSection(
                context,
                'أمان البيانات',
                'نحن نحمي بياناتك من خلال:\n\n'
                    '• تشفير جميع البيانات المرسلة (HTTPS)\n'
                    '• تخزين آمن باستخدام Firebase\n'
                    '• التحكم في الوصول للبيانات\n'
                    '• ضغط الصور وتخزينها بأمان\n'
                    '• استخدام أحدث أنظمة الحماية',
                Icons.security,
                Colors.red,
              ),

              // Your Rights
              _buildSection(
                context,
                'حقوقك',
                'لديك الحق في:\n\n'
                    '• الوصول لبياناتك الشخصية\n'
                    '• تصحيح المعلومات الخاطئة\n'
                    '• حذف حسابك وبياناتك\n'
                    '• الحصول على نسخة من بياناتك\n'
                    '• إلغاء الاشتراك في الإشعارات',
                Icons.account_balance,
                Colors.purple,
              ),

              // Data Sharing
              _buildSection(
                context,
                'مشاركة البيانات',
                'نحن لا نبيع أو نشارك بياناتك مع أطراف ثالثة إلا:\n\n'
                    '• مقدمي الخدمات الموثوقين (Firebase, Google)\n'
                    '• عند الحاجة القانونية\n'
                    '• لحماية حقوقنا وحقوقك',
                Icons.share,
                Colors.teal,
              ),

              // Contact Information
              _buildSection(
                context,
                'تواصل معنا',
                'لأي استفسارات حول الخصوصية:\n\n'
                    '📧 البريد الإلكتروني: support@engseif.com\n',
                Icons.contact_support,
                Colors.indigo,
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
                      'نحن ملتزمون بحماية خصوصيتك',
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
                      'هذه السياسة متوافقة مع قوانين حماية البيانات المحلية والدولية',
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
