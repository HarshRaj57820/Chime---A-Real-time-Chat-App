import 'dart:developer';
import 'package:chime/main.dart';
import 'package:chime/screens/auth/login_screen.dart';
import 'package:chime/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/apis.dart';

// splashscreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      // exiting the full-screen mode
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // changing the status bar to transparent
      SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(systemNavigationBarColor: Colors.white, statusBarColor: Colors.white,));
      if (Apis.auth.currentUser != null) {
        log('User : ${Apis.auth.currentUser}');

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));

      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // initializing mediaquery (for getting device screen sizes)
    mq = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [

          // app logo
          Positioned(
              right: mq.width * .15,
              width: mq.width * 0.70,
              height: mq.height * .25,
              top: mq.height * .25,
              child: Image.asset("assets/images/chime_icon.png")),

          // Organisation Name 
          Positioned(
            bottom: mq.height * .10,
            width: mq.width,
            child: const Text(
              "Made by TechGeeks",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: 1.5),
            ),
          )
        ],
      ),
    );
  }
}
