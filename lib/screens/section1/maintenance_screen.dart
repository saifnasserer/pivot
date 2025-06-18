import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section1/auth_wrapper.dart';

class MaintenanceScreen extends StatelessWidget {
  static const String id = 'maintenance_screen';

  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ابديت'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Navigate back to the auth wrapper, which will then show the login screen.
              Navigator.of(context).pushNamedAndRemoveUntil(
                AuthWrapper.id,
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(
            Responsive.space(context, size: Space.medium),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animation/update.json',
                width: Responsive.space(context, size: Space.large) * 5,
                height: Responsive.space(context, size: Space.large) * 5,
              ),
              SizedBox(height: Responsive.space(context, size: Space.large)),
              Text(
                'الابلكيشن بيتم تحديثة دلوقتي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.large)),
              Text(
                'شغالين عشان نحسين تجربتك\n جرب ادخل تاني كمان شوية',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
