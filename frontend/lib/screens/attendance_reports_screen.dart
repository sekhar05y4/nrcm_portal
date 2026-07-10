import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:js' as js;
import '../services/api_service.dart';

class AttendanceReportsScreen extends StatefulWidget {
  final String dept, year, section;
  const AttendanceReportsScreen({Key? key, required this.dept, required this.year, required this.section}) : super(key: key);

  @override
  _AttendanceReportsScreenState createState() => _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState extends State<AttendanceReportsScreen> {
  String _dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  List _students = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() async {
    setState(() => _loading = true);
    final data = await ApiService.getReport(_dateStr, widget.dept, widget.year, widget.section);
    setState(() {
      _students = data['students'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Insights Summary"),
        backgroundColor: const Color(0xff7A0C2E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text("Reporting Track Target Date: $_dateStr", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() { _dateStr = DateFormat('yyyy-MM-dd').format(picked); });
                      _loadReport();
                    }
                  },
                  child: const Text("Change Date"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    js.context.callMethod('open', [
                      '${ApiService.baseUrl}/faculty/download/report?date=$_dateStr&dept=${widget.dept}&year=${widget.year}&section=${widget.section}',
                      '_blank'
                    ]);
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text("Download CSV"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff7A0C2E),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildRosterTable(),
          )
        ],
      ),
    );
  }

  Widget _buildRosterTable() {
    if (_students.isEmpty) {
      return const Center(child: Text("No records encountered under this configuration partition."));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(0.5), // S.No
          1: FlexColumnWidth(1.5), // Name
          2: FlexColumnWidth(1.5), // Roll No
          3: FlexColumnWidth(0.7), // Dept
          4: FlexColumnWidth(0.5), // Sec
          5: FlexColumnWidth(1.8), // Present Periods
          6: FlexColumnWidth(1.8), // Absent Periods
          7: FlexColumnWidth(2.0), // Faculty
        },
        border: TableBorder.all(color: Colors.grey.shade300, width: 1),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xff7A0C2E)),
            children: [
              _th("S.No", isHeader: true),
              _th("Name", isHeader: true),
              _th("Roll No", isHeader: true),
              _th("Dept", isHeader: true),
              _th("Sec", isHeader: true),
              _th("Present Periods", isHeader: true),
              _th("Absent Periods", isHeader: true),
              _th("Faculty", isHeader: true),
            ],
          ),
          ..._students.asMap().entries.map((entry) {
            int idx = entry.key;
            final student = entry.value;
            
            final List present = student['present_periods'] ?? [];
            final List absent = student['absent_periods'] ?? [];
            
            return TableRow(
              children: [
                _td((idx + 1).toString()),
                _td(student['name'] ?? ''),
                _td(student['roll_number'] ?? ''),
                _td(student['dept'] ?? ''),
                _td(student['section'] ?? ''),
                _td(present.isEmpty ? 'None' : present.join(', '), color: Colors.green),
                _td(absent.isEmpty ? 'None' : absent.join(', '), color: Colors.red),
                _td(student['marked_by'] ?? ''),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _th(String label, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isHeader ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _td(String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            color: color ?? Colors.black87,
            fontSize: 12,
            fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}