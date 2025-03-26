import 'package:flutter/material.dart';
import 'package:pivot/screens/login/login.dart';
import 'package:pivot/screens/section1/first_landing.dart';
import 'package:pivot/screens/section1/signup_page1.dart';
import 'package:pivot/screens/section1/signup_page2.dart';

void main() {
  runApp(const Pivot());
}

class Pivot extends StatelessWidget {
  const Pivot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        FirstLanding.id: (context) => const FirstLanding(),
        Signup_1.id: (context) => const Signup_1(),
        Signup_2.id: (context) => const Signup_2(),
      },
      theme: ThemeData(fontFamily: 'NotoSansArabic'),
      debugShowCheckedModeBanner: false,
      home: const Login(),
    );
  }
}
