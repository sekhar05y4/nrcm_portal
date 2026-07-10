import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({Key? key}) : super(key: key);
  @override
  _StudentRegistrationScreenState createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _nameCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  String _dept = 'CSE';
  String _year = 'I';
  String _sec = 'A';
  bool _obscure = true;
  bool _loading = false;

  void _register() async {
    if (_nameCtrl.text.isEmpty || _rollCtrl.text.isEmpty || _passCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields accurately (Password min 6 chars)")));
      return;
    }
    setState(() => _loading = true);
    final payload = {
      'name': _nameCtrl.text.trim(),
      'roll_number': _rollCtrl.text.trim().toUpperCase(),
      'password': _passCtrl.text,
      'dept': _dept,
      'year': _year,
      'section': _sec
    };
    final res = await ApiService.registerStudent(payload);
    setState(() => _loading = false);

    if (res['statusCode'] == 201) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Registration Successful"),
          content: const Text("Your record was safely received. Please wait for official admin approval configuration before logging into portal services."),
          actions: [
            TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("OK"))
          ],
        )
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['body']['error'] ?? 'Registration failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Portal Registration"), backgroundColor: const Color(0xff7A0C2E), foregroundColor: Colors.white),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: _rollCtrl, decoration: const InputDecoration(labelText: "Roll Number (e.g. 24X01A05Y4)", border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: "Password (Min 6 characters)",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _dept,
                  decoration: const InputDecoration(labelText: "Department", border: OutlineInputBorder()),
                  items: ['CSE', 'ECE', 'EEE', 'MECH', 'CIVIL'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _dept = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _year,
                  decoration: const InputDecoration(labelText: "Year", border: OutlineInputBorder()),
                  items: ['I', 'II', 'III', 'IV'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _year = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _sec,
                  decoration: const InputDecoration(labelText: "Section", border: OutlineInputBorder()),
                  items: ['A', 'B', 'C'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _sec = v!),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff7A0C2E)),
                    onPressed: _loading ? null : _register,
                    child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit Registration", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}