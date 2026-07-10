import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AttendanceReportsScreen extends StatefulWidget {
  final String dept, year, section;
  const AttendanceReportsScreen({Key? key, required this.dept, required this.year, required this.section}) : super(key: key);

  @override
  _AttendanceReportsScreenState createState() => _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState extends State<AttendanceReportsScreen> {
  String _dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  List _present = [];
  List _absent = [];
  bool _loading = false;

  @override
  void initState() { super.initState(); _loadReport(); }

  void _loadReport() async {
    setState(() => _loading = true);
    final data = await ApiService.getReport(_dateStr, widget.dept, widget.year, widget.section);
    setState(() {
      _present = data['present'] ?? [];
      _absent = data['absent'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Attendance Insights Summary"),
          backgroundColor: const Color(0xff7A0C2E),
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Present (${_present.length})"),
              Tab(text: "Absent (${_absent.length})"),
            ],
          ),
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
                  )
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _buildRosterList(_present),
                        _buildRosterList(_absent),
                      ],
                    ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRosterList(List list) {
    if (list.isEmpty) return const Center(child: Text("No records encountered under this configuration partition."));
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final item = list[idx];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: item['status'] == 'Present' ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(item['status'] == 'Present' ? Icons.check : Icons.close, color: item['status'] == 'Present' ? Colors.green : Colors.red),
            ),
            title: Text(item['name'] ?? ''),
            subtitle: Text(item['roll_number'] ?? ''),
          ),
        );
      },
    );
  }
}