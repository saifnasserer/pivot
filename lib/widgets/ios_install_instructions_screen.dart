import 'package:flutter/material.dart';
import '../responsive.dart';
import 'package:pivot/responsive.dart';


class IOSInstallInstructionsScreen extends StatelessWidget {
  const IOSInstallInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double iconSize =
        Responsive.text(context, size: TextSize.heading) * 2.8;
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
                // Blue accent bar
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
                      'assets/icon.png', // Replace with your app icon asset path
                      width: appIconInner,
                      height: appIconInner,
                      // fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.large)),
                // Title
                Text(
                  'تثبيت التطبيق',
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
                  'عشان تجربتك تكون بيرفكت، نزّل التطبيق على الشاشة الرئيسية عندك',
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: Responsive.space(context, size: Space.large) * 1.2,
                ),
                // Steps
                _AnimatedStepList(
                  iconSize: iconSize,
                  stepCircle:
                      Responsive.space(context, size: Space.large) +
                      Responsive.space(context, size: Space.small),
                  stepCircleRadius:
                      (Responsive.space(context, size: Space.large) +
                          Responsive.space(context, size: Space.small)) /
                      2,
                ),
                SizedBox(
                  height: Responsive.space(context, size: Space.large) * 1.2,
                ),
                // Notice
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.large),
                    vertical: Responsive.space(context, size: Space.small),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF4FF),
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.medium),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'مش هتقدر تستخدم التطبيق إلا بعد ما تثبته عندك',
                          style: TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize:
                                Responsive.text(context, size: TextSize.small) +
                                1,
                            color: const Color(0xFF1A73E8),
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF1A73E8),
                        size:
                            Responsive.text(context, size: TextSize.medium) + 2,
                      ),
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

class _AnimatedStepList extends StatefulWidget {
  final double iconSize;
  final double stepCircle;
  final double stepCircleRadius;
  const _AnimatedStepList({
    required this.iconSize,
    required this.stepCircle,
    required this.stepCircleRadius,
  });

  @override
  State<_AnimatedStepList> createState() => _AnimatedStepListState();
}

class _AnimatedStepListState extends State<_AnimatedStepList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    _fadeAnimations = List.generate(3, (i) {
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(i * 0.15, 0.5 + i * 0.25, curve: Curves.easeOut),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepData(
        icon: Icons.ios_share,
        title: ' اضغط على زر المشاركة اللي تحت في سفاري 👇',
      ),
      _StepData(
        icon: Icons.add_box_outlined,
        title: 'من القائمة، اختار "إضافة للشاشة الرئيسية"',
      ),
      _StepData(
        icon: Icons.home_outlined,
        title: 'اضغط "إضافة" فوق يمين وخلاص! 🎉',
      ),
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        return FadeTransition(
          opacity: _fadeAnimations[i],
          child: Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.space(context, size: Space.medium),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F7FE),
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.medium),
                ),
              ),
              padding: EdgeInsets.symmetric(
                vertical: Responsive.space(context, size: Space.small),
                horizontal: Responsive.space(context, size: Space.medium),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: widget.iconSize,
                    height: widget.iconSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        widget.iconSize * 0.35,
                      ),
                    ),
                    child: Icon(
                      steps[i].icon,
                      color: Colors.black,
                      size: widget.iconSize * 0.65,
                    ),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  Expanded(
                    child: Text(
                      steps[i].title,
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize:
                            Responsive.text(context, size: TextSize.medium) + 1,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(width: Responsive.space(context, size: Space.small)),
                  Container(
                    width: widget.stepCircle,
                    height: widget.stepCircle,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8),
                      borderRadius: BorderRadius.circular(
                        widget.stepCircleRadius,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (i + 1).toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansArabic',
                          fontSize:
                              Responsive.text(context, size: TextSize.small) +
                              2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _StepData {
  final IconData icon;
  final String title;
  _StepData({required this.icon, required this.title});
}
