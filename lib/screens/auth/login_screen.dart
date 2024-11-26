import 'dart:developer';
import 'dart:io';
import 'package:chime/api/apis.dart';
import 'package:chime/main.dart';
import 'package:chime/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../utils/dialogs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// user login via google sign in
class _LoginScreenState extends State<LoginScreen> {
  bool _isAnimated = false;

  @override
  // function to animate app icon
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isAnimated = true;
      });
    });
  }

  _handleSignIn() {
    Dialogs.showProgressBar(context);
    _signInWithGoogle().then((user) async {

      if (user != null) {
        if(await Apis.userAlreadyExists() == false){
          await Apis.createUser();
        }
        if(!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      await InternetAddress.lookup("google.com");
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      // Once signed in, return the UserCredential
      return await Apis.auth.signInWithCredential(credential);
    } catch (e) {
      if(!mounted) return null;

      Navigator.pop(context);

      log('error: ${e.toString()}');
      Dialogs.showSnackBar(context, "Something went wrong (check internet!)");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appbar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Welcome to Login"),
      ),
      body: Stack(
        children: [
          // app logo
          AnimatedPositioned(
              right: _isAnimated ? mq.width * .25 : -mq.width * 0.5,
              width: mq.width * 0.5,
              height: mq.height * .15,
              top: mq.height * .10,
              duration: const Duration(seconds: 1),
              child: Image.asset("assets/images/chime_icon.png")),
          // Login with google
          Positioned(
            left: mq.width * .1,
            width: mq.width * 0.8,
            height: mq.height * .06,
            bottom: mq.height * .15,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  backgroundColor: Colors.white70),
              onPressed: _handleSignIn,
              // google icon
              icon: Image.asset(
                "assets/images/google.png",
                height: mq.height * 0.05,
              ),
              label: RichText(
                text: const TextSpan(children: [
                  TextSpan(
                      text: "Continue with",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      )),
                  TextSpan(
                      text: " Google",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold))
                ]),
              ),
            ),
          )
        ],
      ),
    );
  }
}
