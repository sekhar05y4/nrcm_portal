import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/faculty_dashboard_screen.dart';
import 'screens/student_dashboard_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final role = prefs.getString('role') ?? '';
  final userid = prefs.getString('userid') ?? '';
  final name = prefs.getString('name') ?? '';

  Widget homeWidget = const LoginScreen();

  if (token.isNotEmpty && role.isNotEmpty && userid.isNotEmpty) {
    ApiService.token = token;
    if (role == 'Admin') {
      homeWidget = AdminDashboardScreen(rollNumber: userid, studentName: name);
    } else if (role == 'Faculty') {
      homeWidget = FacultyDashboardScreen(rollNumber: userid, studentName: name);
    } else if (role == 'Student/Parent') {
      homeWidget = StudentDashboardScreen(rollNumber: userid, studentName: name);
    }
  }

  runApp(NRCMApp(homeWidget: homeWidget));
}

class NRCMApp extends StatelessWidget {
  final Widget homeWidget;
  const NRCMApp({Key? key, required this.homeWidget}) : super(key: key);

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
      home: homeWidget,
    );
  }
}