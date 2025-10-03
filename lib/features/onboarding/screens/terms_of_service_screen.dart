import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
            'شروط الخدمة',
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
                    colors: [Colors.green[50]!, Colors.blue[50]!],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.gavel,
                      size:
                          Responsive.text(context, size: TextSize.heading) * 2,
                      color: Colors.green[700],
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Text(
                      'شروط استخدام تطبيق Pivot',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.heading,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    Text(
                      'آخر تحديث: أكتوبر 2025',
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

              // Acceptance
              _buildSection(
                context,
                'الموافقة على الشروط',
                'باستخدام تطبيق Pivot، فإنك توافق على الالتزام بهذه الشروط. '
                    'إذا كنت لا توافق على هذه الشروط، يرجى عدم استخدام التطبيق.',
                Icons.check_circle_outline,
                Colors.green,
              ),

              // User Responsibilities
              _buildSection(
                context,
                'مسؤوليات المستخدم',
                'كمستخدم لتطبيق Pivot، فإنك توافق على:\n\n'
                    '• تقديم معلومات دقيقة وصحيحة عند التسجيل\n'
                    '• الحفاظ على سرية كلمة المرور الخاصة بك\n'
                    '• عدم مشاركة حسابك مع الآخرين\n'
                    '• استخدام التطبيق للأغراض التعليمية فقط\n'
                    '• الالتزام بقوانين الجامعة والقوانين المحلية',
                Icons.person_outline,
                Colors.blue,
              ),

              // User Generated Content
              _buildSection(
                context,
                'المحتوى الذي ينشئه المستخدم',
                'عند نشر محتوى في التطبيق (تعليقات، منشورات، ملفات):\n\n'
                    '• أنت مسؤول بالكامل عن المحتوى الذي تنشره\n'
                    '• يجب ألا يكون المحتوى مسيئاً أو غير قانوني\n'
                    '• لا يجوز نشر محتوى محمي بحقوق النشر بدون إذن\n'
                    '• نحن نحتفظ بالحق في إزالة أي محتوى غير لائق\n'
                    '• قد يتم حظر حسابك في حالة انتهاك الشروط',
                Icons.content_copy,
                Colors.orange,
              ),

              // Acceptable Use
              _buildSection(
                context,
                'السلوك المقبول',
                'يُحظر عند استخدام Pivot:\n\n'
                    '• التنمر أو المضايقة أو التهديد للآخرين\n'
                    '• نشر محتوى كراهية أو تمييزي\n'
                    '• البريد العشوائي أو المحتوى الترويجي غير المصرح به\n'
                    '• انتحال شخصية الآخرين\n'
                    '• محاولة اختراق التطبيق أو إساءة استخدامه\n'
                    '• مشاركة معلومات شخصية للآخرين بدون إذن',
                Icons.block,
                Colors.red,
              ),

              // Academic Integrity
              _buildSection(
                context,
                'النزاهة الأكاديمية',
                'تطبيق Pivot يدعم التعلم الأخلاقي:\n\n'
                    '• لا يجوز استخدام التطبيق للغش في الامتحانات\n'
                    '• مشاركة المواد يجب أن تكون قانونية ومصرح بها\n'
                    '• احترام حقوق الملكية الفكرية للأساتذة والزملاء\n'
                    '• التعاون المشروع مشجع، الغش ممنوع',
                Icons.school,
                Colors.purple,
              ),

              // Account Termination
              _buildSection(
                context,
                'إنهاء الحساب',
                'نحتفظ بالحق في:\n\n'
                    '• تعليق أو إنهاء حسابك في حالة انتهاك الشروط\n'
                    '• إزالة أي محتوى ينتهك هذه الشروط\n'
                    '• الإبلاغ عن الأنشطة غير القانونية للسلطات\n\n'
                    'يمكنك حذف حسابك في أي وقت من إعدادات التطبيق.',
                Icons.cancel,
                Colors.red[700]!,
              ),

              // Liability
              _buildSection(
                context,
                'إخلاء المسؤولية',
                'تطبيق Pivot يُقدم "كما هو" بدون ضمانات:\n\n'
                    '• لا نضمن دقة المحتوى المقدم من المستخدمين\n'
                    '• لسنا مسؤولين عن فقدان البيانات بسبب أعطال تقنية\n'
                    '• التطبيق للاستخدام الشخصي التعليمي فقط\n'
                    '• نحن لسنا مسؤولين عن قرارات تتخذها بناءً على المحتوى',
                Icons.warning_amber,
                Colors.orange,
              ),

              // Changes to Terms
              _buildSection(
                context,
                'التعديلات على الشروط',
                'قد نقوم بتحديث هذه الشروط من وقت لآخر. '
                    'سيتم إخطارك بأي تغييرات مهمة عبر التطبيق أو البريد الإلكتروني. '
                    'استمرارك في استخدام التطبيق بعد التغييرات يعني موافقتك على الشروط الجديدة.',
                Icons.update,
                Colors.blue,
              ),

              // Contact
              _buildSection(
                context,
                'تواصل معنا',
                'لأي استفسارات حول هذه الشروط:\n\n'
                    '📧 البريد الإلكتروني: support@engseif.com',
                Icons.contact_support,
                Colors.teal,
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
                      'باستخدام تطبيق Pivot، فإنك توافق على جميع الشروط المذكورة أعلاه',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
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
