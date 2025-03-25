
import 'package:flutter/material.dart';

class FirstLanding extends StatelessWidget {
  const FirstLanding({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold
    (
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xff161616),
          // image: DecorationImage(
          //   // image: AssetImage('assets/images/background.png'),
          //   // fit: BoxFit.cover,
          // ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    textAlign: TextAlign.right,
                    'واخيراً\n حياة جامعية منظمة',
                    style: TextStyle(color: Colors.white, fontFamily: 'NotoSansArabic', fontSize: 35),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(width: 20,),
                  ElevatedButton(onPressed: (){}, child: Row(
                    children: [
                      Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
                      Text('التسجيل',style: TextStyle(color: Colors.black,fontSize: 18),),
                    ],
                  ))  ,
                  SizedBox(width: 20,),
                  TextButton(onPressed: (){}, child: Row(
                    children: [
                      Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                      Text('تسجيل الدخول',style: TextStyle(color: Colors.white,fontSize: 18),),
                    ],
                  ))  ,
                ]
              ),
              SizedBox(height: 20), 
            ],
          ),
        ),
      )
            );
  }
}