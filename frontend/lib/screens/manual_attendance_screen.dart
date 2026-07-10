import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../services/api_service.dart';

class ManualAttendanceScreen extends StatefulWidget {
  final String period, dept, year, section;
  const ManualAttendanceScreen({Key? key, required this.period, required this.dept, required this.year, required this.section}) : super(key: key);

  @override
  _ManualAttendanceScreenState createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends State<ManualAttendanceScreen> {
  List<AttendanceRecord> _records = [];
  bool _loading = true;
  final String _currentDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() { super.initState(); _loadRoster(); }

  void _loadRoster() async {
    final list = await ApiService.getRoster(widget.dept, widget.year, widget.section);
    setState(() {
      _records = list.map((e) => AttendanceRecord(rollNumber: e['roll_number'], name: e['name'])).toList();
      _loading = false;
    });
  }

  void _setBulkStatus(String status) {
    setState(() {
      for (var record in _records) { record.status = status; }
    });
  }

  void _submit() async {
    setState(() => _loading = true);
    final payload = {
      'date': _currentDateStr,
      'period': widget.period,
      'dept': widget.dept,
      'year': widget.year,
      'section': widget.section,
      'records': _records.map((e) => {'roll_number': e.rollNumber, 'status': e.status}).toList(),
    };
    bool success = await ApiService.submitAttendance(payload);
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "Metrics logged successfully." : "An error occurred.")),
    );
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.dept} - ${widget.year} (${widget.section}) | ${widget.period}"),
        backgroundColor: const Color(0xff7A0C2E),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle, color: Colors.white),
                        label: const Text("All Present"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () => _setBulkStatus('Present'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.remove_circle, color: Colors.white),
                        label: const Text("All Absent"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => _setBulkStatus('Absent'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final item = _records[index];
                      final isPresent = item.status == 'Present';
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(item.rollNumber),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(item.status, style: TextStyle(color: isPresent ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Switch(
                                value: isPresent,
                                activeColor: Colors.green,
                                inactiveThumbColor: Colors.red,
                                onChanged: (val) {
                                  setState(() { item.status = val ? 'Present' : 'Absent'; });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff7A0C2E), padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _records.isEmpty ? null : _submit,
                    child: const Text("Submit Attendance Metrics", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                )
              ],
            ),
    );
  }
}