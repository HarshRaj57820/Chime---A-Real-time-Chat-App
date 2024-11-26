import 'package:chime/firebase_options.dart';
import 'package:chime/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// global object for accessing device screen size
late Size mq;

void main() {

  WidgetsFlutterBinding.ensureInitialized();
  // seeting the full-screen mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // setting the app only for portrait mode
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then((value){
    _initializeFirebase();
  runApp(const MyApp());
  });
  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chime',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // creating common appbar theme for app
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 19, fontStyle: FontStyle.normal), 
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 2,

        )

      ),
    home: const SplashScreen(),
    );
  }
}

// for initializing firebase
Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
}
