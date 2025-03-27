import 'package:flutter/material.dart';
import 'package:pivot/screens/section1/login/login.dart';
import 'package:pivot/screens/section1/first_landing.dart';
import 'package:pivot/screens/section1/signup/signup_page1.dart';
import 'package:pivot/screens/section1/signup/signup_page2.dart';
import 'package:pivot/screens/section2/landing.dart';
import 'package:pivot/screens/section2/models/card_model.dart';
import 'package:pivot/screens/section2/models/category_model.dart';

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
        Login.id: (context) => const Login(),
        Signup_2.id: (context) => const Signup_2(),
        Landing.id: (context) => const Landing(),
      },
      theme: ThemeData(fontFamily: 'NotoSansArabic'),
      debugShowCheckedModeBanner: false,
      home: FirstLanding(),
    );
  }
}
