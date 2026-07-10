import 'package:flutter/material.dart';
import '../utils/session_storage.dart';
import '../services/api_service.dart';

class StudentDashboardScreen extends StatefulWidget {
  final String studentName;
  final String rollNumber;

  const StudentDashboardScreen({
    Key? key, 
    required this.studentName, 
    required this.rollNumber
  }) : super(key: key);

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  String _selectedMenu = 'Dashboard';
  bool _isSidebarExpanded = true; 

  final Color primaryMaroon = const Color(0xff5A1827);

  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = true;
  String _todayStatus = 'Absent';
  String _todayPeriod = '';
  String _todayMarkedBy = '';

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  void _loadAttendance() async {
    setState(() { _isLoading = true; });
    final records = await ApiService.getStudentAttendance();
    
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    String status = 'Absent';
    String period = '';
    String markedBy = '';
    
    for (var r in records) {
      if (r['date'] == todayStr) {
        status = r['status'] ?? 'Absent';
        period = r['period'] ?? '';
        markedBy = r['marked_by'] ?? '';
        break;
      }
    }
    
    setState(() {
      _attendanceRecords = records;
      _todayStatus = status;
      _todayPeriod = period;
      _todayMarkedBy = markedBy;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // --- SIDEBAR NAVIGATION (FIXED: Color inside decoration block) ---
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _isSidebarExpanded ? 260 : 70,
                decoration: BoxDecoration(
                  color: Colors.white, 
                  border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    if (_isSidebarExpanded)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            Image.asset('assets/nrcm_logo.png', height: 60, errorBuilder: (c, e, s) => Container()),
                            const SizedBox(height: 12),
                          ],
                        ),
                      )
                    else
                      Center(
                        child: CircleAvatar(
                          backgroundColor: primaryMaroon.withAlpha(20),
                          radius: 20,
                          child: Icon(Icons.school, color: primaryMaroon, size: 20),
                        ),
                      ),
                    const Divider(height: 20, thickness: 1),
                    
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: [
                          _sidebarTile(Icons.home_outlined, "Dashboard", hasArrow: false),
                          _sidebarTile(Icons.apartment_outlined, "Academics"),
                          _sidebarTile(Icons.credit_card_outlined, "Payments"),
                          _sidebarTile(Icons.rate_review_outlined, "Feedback"),
                          _sidebarTile(Icons.assignment_outlined, "Exam Cell"),
                          _sidebarTile(Icons.local_library_outlined, "Library"),
                          _sidebarTile(Icons.cloud_upload_outlined, "Uploads"),
                          _sidebarTile(Icons.settings_outlined, "Account Settings"),
                          _sidebarTile(Icons.fingerprint_outlined, "Biometric", hasArrow: false),
                          _sidebarTile(Icons.cloud_download_outlined, "Downloads"),
                          _sidebarTile(Icons.chat_outlined, "Help", hasArrow: false),
                          const Divider(height: 20, thickness: 1),
                          _sidebarTile(Icons.logout_outlined, "Logout", hasArrow: false, isLogout: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- MAIN CONTENT VIEWPORT ---
              Expanded(
                child: Container(
                  color: const Color(0xffF8F9FA),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedMenu,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryMaroon),
                            ),
                            Row(
                              children: [
                                Text(
                                  widget.rollNumber,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 13),
                                ),
                                const SizedBox(width: 12),
                                CircleAvatar(
                                  backgroundColor: primaryMaroon,
                                  radius: 16,
                                  child: Text(
                                    widget.studentName.isNotEmpty ? widget.studentName[0].toUpperCase() : 'S',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: _renderActiveView(),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- PERSISTENT FLOATING SIDEBAR ANIMATION TOGGLE KEY ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            left: _isSidebarExpanded ? 242 : 52,
            top: 35,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xffE11D74), 
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSidebarExpanded ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _sidebarTile(IconData icon, String label, {bool hasArrow = true, bool isLogout = false}) {
    final bool isSelected = _selectedMenu == label;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        selected: isSelected,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        selectedTileColor: const Color(0xffF4F5F7),
        leading: Icon(
          icon, 
          color: isLogout 
              ? Colors.amber.shade800 
              : (isSelected ? primaryMaroon : Colors.grey.shade600),
          size: 20
        ),
        title: _isSidebarExpanded 
            ? Text(
                label, 
                style: TextStyle(
                  color: isLogout 
                      ? Colors.amber.shade800 
                      : (isSelected ? primaryMaroon : Colors.black87),
                  fontWeight: isSelected || isLogout ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13
                ),
              )
            : null,
        trailing: (_isSidebarExpanded && hasArrow && !isLogout)
            ? Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400)
            : null,
        onTap: () async {
          if (isLogout) {
            await SessionStorage.clear();
            Navigator.pushReplacementNamed(context, '/login');
          } else {
            setState(() => _selectedMenu = label);
          }
        },
      ),
    );
  }

  Widget _renderActiveView() {
    switch (_selectedMenu) {
      case 'Dashboard':
        return _buildDashboardContent();
      case 'Academics':
        return _buildGenericPlaceholder("Academic Performance & Course Outcome Schemas");
      case 'Payments':
        return _buildGenericPlaceholder("Fee Management, Balance Sheets, Ledger Auditing");
      case 'Feedback':
        return _buildGenericPlaceholder("Faculty Evaluation & Institutional Feedback Records");
      case 'Exam Cell':
        return _buildGenericPlaceholder("Hall Tickets, Mid-Term and End-Semester Evaluations");
      case 'Library':
        return _buildGenericPlaceholder("Digital Catalog Access and Borrowed Book Records");
      case 'Uploads':
        return _buildGenericPlaceholder("Assignments Submission, Certificates Archive");
      case 'Account Settings':
        return _buildGenericPlaceholder("Credential Configuration and Profile Management");
      case 'Biometric':
        return _buildGenericPlaceholder("Biometric Ledger Sync Logs");
      case 'Downloads':
        return _buildGenericPlaceholder("Syllabus copies, Regulations sheets, Academic Calendar PDFs");
      case 'Help':
        return _buildGenericPlaceholder("Contact Institutional Support Desk");
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isPresentToday = _todayStatus == 'Present';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: "Welcome, ",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            children: [
              TextSpan(text: widget.studentName, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
            ]
          )
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: Colors.grey.shade200, width: 1.5)
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Status", style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      isPresentToday ? Icons.check_circle : Icons.cancel, 
                      color: isPresentToday ? Colors.green : Colors.red, 
                      size: 24
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _todayStatus, 
                      style: TextStyle(
                        color: isPresentToday ? Colors.green : Colors.red, 
                        fontSize: 22, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isPresentToday 
                      ? "Marked by $_todayMarkedBy for $_todayPeriod" 
                      : "Not recognized yet today", 
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400)
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade200, width: 1.5)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xffF8F9FA),
                width: double.infinity,
                child: const Text("Recent Attendance History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              Table(
                border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade100)),
                children: [
                  TableRow(
                    children: [
                      _th("Date"), _th("Period"), _th("Status")
                    ]
                  ),
                  if (_attendanceRecords.isEmpty)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text("No records found", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        ),
                        const SizedBox(),
                        const SizedBox(),
                      ]
                    )
                  else
                    ..._attendanceRecords.map((r) {
                      final bool isPres = r['status'] == 'Present';
                      return TableRow(
                        children: [
                          _td(r['date'] ?? ''),
                          _td(r['period'] ?? ''),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPres ? Colors.green.shade600 : Colors.red.shade600, 
                                  borderRadius: BorderRadius.circular(4)
                                ),
                                child: Text(
                                  isPres ? "Present" : "Absent", 
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                                ),
                              ),
                            ),
                          )
                        ]
                      );
                    }).toList()
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildGenericPlaceholder(String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200, width: 1.5)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_outlined, size: 48, color: primaryMaroon.withAlpha(120)),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text("Unified database routing linked successfully. No biometric camera data required.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _th(String label) => Padding(padding: const EdgeInsets.all(12), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)));
  Widget _td(String val) => Padding(padding: const EdgeInsets.all(12), child: Text(val, style: const TextStyle(fontSize: 13, color: Colors.black87)));
}