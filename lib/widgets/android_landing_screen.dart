import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../responsive.dart';
import 'android_landing_screen_web.dart'
    if (dart.library.io) 'android_landing_screen_stub.dart';

class AndroidLandingScreen extends StatelessWidget {
  const AndroidLandingScreen({super.key});

  // Google Play Store URL
  static const String googlePlayUrl =
      'https://play.google.com/store/apps/details?id=com.engseif.pivot';

  Future<void> _launchGooglePlay(BuildContext context) async {
    final uri = Uri.parse(googlePlayUrl);
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يمكن فتح متجر Google Play'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _continueOnWeb(BuildContext context) {
    if (kIsWeb) {
      AndroidLandingScreenHelper.continueOnWeb();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double appIconBox =
        Responsive.space(context, size: Space.xlarge) * 2.2;
    final double appIconRadius =
        Responsive.space(context, size: Space.large) * 1.2;
    final double appIconInner =
        Responsive.space(context, size: Space.xlarge) * 1.1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: Responsive.padding(context, size: Space.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App icon/logo
                Container(
                  width: appIconBox,
                  height: appIconBox,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(appIconRadius),
                    color: const Color(0xFFF2F4F8),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/icon.png',
                      width: appIconInner,
                      height: appIconInner,
                    ),
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.large)),
                // Title
                Text(
                  'مرحباً بك في Pivot',
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontWeight: FontWeight.bold,
                    fontSize:
                        Responsive.text(context, size: TextSize.heading) * 1.15,
                    color: Colors.black,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.space(context, size: Space.small)),
                Container(
                  width: 60,
                  height: 6,
                  margin: EdgeInsets.only(
                    bottom: Responsive.space(context, size: Space.large),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Subtitle
                Text(
                  'لتجربة أفضل، يُنصح بتحميل التطبيق من Google Play',
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: Responsive.space(context, size: Space.large) * 1.5,
                ),

                // Download button - Google Play Badge Style
                _GooglePlayBadge(onTap: () => _launchGooglePlay(context)),

                SizedBox(height: Responsive.space(context, size: Space.medium)),

                // Continue on web button
                _FeatureCard(
                  icon: Icons.public_rounded,
                  title: 'متابعة على المتصفح',
                  subtitle: 'استخدام النسخة الإلكترونية',
                  color: const Color(0xFFF2F7FE),
                  textColor: Colors.black87,
                  iconColor: const Color(0xFF1A73E8),
                  onTap: () => _continueOnWeb(context),
                ),

                SizedBox(
                  height: Responsive.space(context, size: Space.large) * 1.2,
                ),

                // Benefits notice
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.large),
                    vertical: Responsive.space(context, size: Space.medium),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF4FF),
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.medium),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'مميزات التطبيق',
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                              color: const Color(0xFF1A73E8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Icon(
                            Icons.stars_rounded,
                            color: const Color(0xFF1A73E8),
                            size:
                                Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ) +
                                2,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      _BenefitItem('إشعارات فورية'),
                      _BenefitItem('أداء أسرع وأفضل'),
                      _BenefitItem('واجهة محسّنة'),
                      _BenefitItem('إمكانية العمل دون إنترنت'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color? textColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.textColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        Responsive.space(context, size: Space.medium),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.medium),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.small),
              ),
              decoration: BoxDecoration(
                color:
                    iconColor == Colors.white
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white,
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.small),
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: Responsive.text(context, size: TextSize.heading),
              ),
            ),
            SizedBox(width: Responsive.space(context, size: Space.medium)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize:
                          Responsive.text(context, size: TextSize.medium) + 2,
                      color: effectiveTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: effectiveTextColor.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final String text;

  const _BenefitItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            text,
            style: TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: Responsive.text(context, size: TextSize.small),
              color: const Color(0xFF1A73E8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
          SizedBox(width: Responsive.space(context, size: Space.small)),
          Icon(
            Icons.check_circle,
            color: const Color(0xFF1A73E8),
            size: Responsive.text(context, size: TextSize.small) + 2,
          ),
        ],
      ),
    );
  }
}

class _GooglePlayBadge extends StatelessWidget {
  final VoidCallback onTap;

  const _GooglePlayBadge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.large),
          vertical: Responsive.space(context, size: Space.medium) + 4,
        ),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google Play Icon
            FaIcon(FontAwesomeIcons.googlePlay, size: 36, color: Colors.white),
            SizedBox(width: Responsive.space(context, size: Space.medium)),
            // Text section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'متاح على',
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize:
                        Responsive.text(context, size: TextSize.small) - 1,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Google Play',
                      style: TextStyle(
                        fontSize:
                            Responsive.text(context, size: TextSize.medium) + 4,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
