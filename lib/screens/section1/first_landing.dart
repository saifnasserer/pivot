import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/screens/section1/login/login.dart';
import 'package:pivot/screens/section1/signup/signup_page1.dart';
import '../../responsive.dart';

class FirstLanding extends StatelessWidget {
  const FirstLanding({super.key});
  static String id = 'landing1';
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xff161616),
            image: DecorationImage(
              image: AssetImage('assets/images/Group 113.png'),
              // fit: BoxFit.contain,
              opacity: 0.15,
              scale: 1.2,
            ),
          ),
          child: Padding(
            padding: Responsive.paddingHorizontal(context, size: Space.medium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          textAlign: TextAlign.right,
                          '! ... واخيراً',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize:
                                Responsive.text(
                                  context,
                                  size: TextSize.heading,
                                ) *
                                1.5,
                          ),
                        ),
                        Text(
                          textAlign: TextAlign.right,
                          'حياة جامعية منظمة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize:
                                Responsive.text(
                                  context,
                                  size: TextSize.heading,
                                ) *
                                2.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, Signup_1.id);
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                            size: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                          ),
                          Text(
                            ' حساب جديد',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.medium),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, Login.id);
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                          ),
                          Text(
                            ' تسجيل الدخول',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.space(context, size: Space.xlarge)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
