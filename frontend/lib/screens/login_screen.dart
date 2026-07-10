import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'student_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Student/Parent';
  String _errorMessage = '';
  bool _isLoading = false;

  final Color primaryMaroon = const Color(0xff5A1827);

  void _handleLogin() async {
    setState(() { _errorMessage = ''; _isLoading = true; });
    
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final response = await ApiService.login(
      username,
      password,
      _selectedRole,
    );
    
    setState(() { _isLoading = false; });

    if (response['statusCode'] == 200) {
      final body = response['body'] ?? {};
      final String token = body['token'] ?? '';
      final String name = body['name'] ?? 'User';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('role', _selectedRole);
      await prefs.setString('userid', username);
      await prefs.setString('name', name);
      
      // Update local API service token
      ApiService.token = token;

      if (_selectedRole == 'Admin') {
        Navigator.pushReplacementNamed(
          context,
          '/adminlogin',
          arguments: {
            'rollNumber': username.isNotEmpty ? username : 'ADMIN',
            'studentName': name,
          },
        );
      } else if (_selectedRole == 'Faculty') {
        Navigator.pushReplacementNamed(
          context,
          '/facultylogin',
          arguments: {
            'rollNumber': username.isNotEmpty ? username : 'FACULTY',
            'studentName': name,
          },
        );
      } else {
        final String studentName = (response['body'] != null && response['body']['name'] != null)
            ? response['body']['name']
            : 'SEKHAR';

        Navigator.pushReplacementNamed(
          context,
          '/studentlogin',
          arguments: {
            'rollNumber': username.isNotEmpty ? username.toUpperCase() : "24X01A05Y4",
            'studentName': studentName,
          },
        );
      }
    } else {
      setState(() {
        _errorMessage = response['body']['error'] ?? 'Login initialization failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double paddingValue = MediaQuery.of(context).size.width > 500 ? 24.0 : 16.0;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/college_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withAlpha(40)),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(paddingValue),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Image.asset('assets/nrcm_logo.png', height: 70, errorBuilder: (c, e, s) => Container()),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            "Student / Parent Login",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                          ),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          items: ['Student/Parent', 'Faculty', 'Admin'].map((String val) {
                            return DropdownMenuItem<String>(value: val, child: Text(val));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedRole = val!),
                        ),
                        const SizedBox(height: 16),
                        const Text("Roll Number / Username", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: "Enter your Roll Number",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text("Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          decoration: const InputDecoration(
                            hintText: "Password",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                        ),
                        if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryMaroon,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Login", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationScreen())),
                            child: Text(
                              "New to portal? Register Here",
                              style: TextStyle(color: primaryMaroon, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}