import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const NRCMApp());
}

class NRCMApp extends StatelessWidget {
  const NRCMApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NRCM Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xff5A1827),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff5A1827),
          primary: const Color(0xff5A1827),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}