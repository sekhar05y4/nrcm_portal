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

  String initialRoute = '/login';
  Map<String, dynamic>? initialArgs;

  if (token.isNotEmpty && role.isNotEmpty && userid.isNotEmpty) {
    ApiService.token = token;
    initialArgs = {'rollNumber': userid, 'studentName': name};
    if (role == 'Admin') {
      initialRoute = '/adminlogin';
    } else if (role == 'Faculty') {
      initialRoute = '/facultylogin';
    } else if (role == 'Student/Parent') {
      initialRoute = '/studentlogin';
    }
  }

  runApp(NRCMApp(initialRoute: initialRoute, initialArgs: initialArgs));
}

class NRCMApp extends StatelessWidget {
  final String initialRoute;
  final Map<String, dynamic>? initialArgs;
  const NRCMApp({Key? key, required this.initialRoute, this.initialArgs}) : super(key: key);

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
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        final name = settings.name;

        if (name == '/adminlogin') {
          final args = (settings.arguments as Map<String, dynamic>?) ?? initialArgs;
          if (args == null || ApiService.token.isEmpty) {
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
              settings: const RouteSettings(name: '/login'),
            );
          }
          return MaterialPageRoute(
            builder: (_) => AdminDashboardScreen(
              rollNumber: args['rollNumber'] ?? 'ADMIN',
              studentName: args['studentName'] ?? 'Admin User',
            ),
            settings: settings,
          );
        }

        if (name == '/facultylogin') {
          final args = (settings.arguments as Map<String, dynamic>?) ?? initialArgs;
          if (args == null || ApiService.token.isEmpty) {
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
              settings: const RouteSettings(name: '/login'),
            );
          }
          return MaterialPageRoute(
            builder: (_) => FacultyDashboardScreen(
              rollNumber: args['rollNumber'] ?? 'FACULTY',
              studentName: args['studentName'] ?? 'Faculty Member',
            ),
            settings: settings,
          );
        }

        if (name == '/studentlogin') {
          final args = (settings.arguments as Map<String, dynamic>?) ?? initialArgs;
          if (args == null || ApiService.token.isEmpty) {
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
              settings: const RouteSettings(name: '/login'),
            );
          }
          return MaterialPageRoute(
            builder: (_) => StudentDashboardScreen(
              rollNumber: args['rollNumber'] ?? 'STUDENT',
              studentName: args['studentName'] ?? 'Student Name',
            ),
            settings: settings,
          );
        }

        // Default fallback to login
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: const RouteSettings(name: '/login'),
        );
      },
    );
  }
}