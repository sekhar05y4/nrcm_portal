import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  bool _isAcademicsExpanded = true;

  final Color primaryMaroon = const Color(0xff5A1827);

  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = true;
  String _todayStatus = 'Absent';
  String _todayPeriod = '';
  String _todayMarkedBy = '';

  final List<String> _semesterMonths = ['2026-06', '2026-07', '2026-08', '2026-09', '2026-10', '2026-11'];
  final Map<String, String> _monthNames = {
    '2026-06': 'Jun 2026',
    '2026-07': 'Jul 2026',
    '2026-08': 'Aug 2026',
    '2026-09': 'Sep 2026',
    '2026-10': 'Oct 2026',
    '2026-11': 'Nov 2026',
  };
  
  Map<String, Map<String, dynamic>> _monthlyStats = {};
  String _activeMonth = '2026-07';

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

    Map<String, Map<String, dynamic>> stats = {};
    for (var m in _semesterMonths) {
      stats[m] = {'present': 0, 'total': 0, 'percentage': 100.0};
    }
    
    for (var r in records) {
      final date = r['date'] ?? '';
      if (date.length >= 7) {
        final monthKey = date.substring(0, 7);
        if (stats.containsKey(monthKey)) {
          stats[monthKey]!['total'] = stats[monthKey]!['total'] + 1;
          if (r['status'] == 'Present') {
            stats[monthKey]!['present'] = stats[monthKey]!['present'] + 1;
          }
        }
      }
    }
    
    stats.forEach((key, val) {
      int tot = val['total'];
      int pres = val['present'];
      if (tot > 0) {
        val['percentage'] = (pres / tot) * 100.0;
      } else {
        val['percentage'] = 100.0;
      }
    });
    
    setState(() {
      _attendanceRecords = records;
      _todayStatus = status;
      _todayPeriod = period;
      _todayMarkedBy = markedBy;
      _monthlyStats = stats;
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
                          _sidebarTile(
                            Icons.apartment_outlined, 
                            "Academics", 
                            hasArrow: false, 
                            onTapOverride: () {
                              setState(() => _isAcademicsExpanded = !_isAcademicsExpanded);
                            }
                          ),
                          if (_isAcademicsExpanded) ...[
                            _sidebarSubTile("Academic Calendar"),
                            _sidebarSubTile("Attendance"),
                            _sidebarSubTile("Holidays"),
                          ],
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

  Widget _sidebarSubTile(String label) {
    final bool isSelected = _selectedMenu == label;
    if (!_isSidebarExpanded) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.only(left: 32, top: 2, bottom: 2, right: 8),
      child: ListTile(
        selected: isSelected,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        selectedTileColor: const Color(0xffF4F5F7),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryMaroon : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
        onTap: () {
          setState(() => _selectedMenu = label);
        },
      ),
    );
  }

  Widget _sidebarTile(IconData icon, String label, {bool hasArrow = true, bool isLogout = false, VoidCallback? onTapOverride}) {
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
        onTap: onTapOverride ?? () async {
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
      case 'Academic Calendar':
        return _buildGenericPlaceholder("Academic Calendar");
      case 'Attendance':
      case 'Academics':
        return _buildAttendanceContent();
      case 'Holidays':
        return _buildGenericPlaceholder("Institutional Holidays & Vacation Schedules");
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

  Widget _buildAttendanceContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final activeStats = _monthlyStats[_activeMonth] ?? {'present': 0, 'total': 0, 'percentage': 100.0};
    
    final activeRecords = _attendanceRecords.where((r) {
      final date = r['date'] ?? '';
      return date.startsWith(_activeMonth);
    }).toList();

    Map<String, Map<String, String>> gridData = {};
    for (var r in activeRecords) {
      final date = r['date'] ?? '';
      final period = r['period'] ?? '';
      final status = r['status'] == 'Present' ? 'P' : 'A';
      
      String pKey = "";
      if (period.startsWith("Period ")) {
        pKey = "P" + period.substring(7);
      }
      
      if (pKey.isNotEmpty) {
        if (!gridData.containsKey(date)) {
          gridData[date] = {};
        }
        gridData[date]![pKey] = status;
      }
    }

    final sortedDates = gridData.keys.toList()..sort();

    int semesterTotal = 0;
    int semesterPresent = 0;
    _monthlyStats.forEach((key, val) {
      semesterTotal += (val['total'] as int);
      semesterPresent += (val['present'] as int);
    });
    final double semesterPercentage = semesterTotal > 0 ? (semesterPresent / semesterTotal) * 100.0 : 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xff3949AB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Semester Attendance (Month-wise) from June 3, 2026",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "View your attendance records organized by month",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.grey),
                          onPressed: () {},
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _semesterMonths.map((mKey) {
                                final isSel = _activeMonth == mKey;
                                final stats = _monthlyStats[mKey] ?? {'percentage': 100.0};
                                final double percentage = stats['percentage'];
                                final String name = _monthNames[mKey] ?? '';
                                
                                final isLow = percentage < 75.0;
                                final badgeColor = isLow ? Colors.red : Colors.green;
                                
                                return InkWell(
                                  onTap: () {
                                    setState(() => _activeMonth = mKey);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: isSel ? primaryMaroon : Colors.transparent,
                                          width: 2.0,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                            color: isSel ? primaryMaroon : Colors.black87,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: badgeColor,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            "${percentage.toStringAsFixed(0)}%",
                                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.grey),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _metricCard("Present", activeStats['present'].toString(), Colors.green)),
                        const SizedBox(width: 16),
                        Expanded(child: _metricCard("Total Classes", activeStats['total'].toString(), Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(child: _metricCard("Percentage", "${(activeStats['percentage'] as double).toStringAsFixed(2)}%", Colors.teal, valueColor: (activeStats['percentage'] as double) < 75 ? Colors.red : Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (sortedDates.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text("No attendance records for this month", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        ),
                      )
                    else
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1),
                          5: FlexColumnWidth(1),
                          6: FlexColumnWidth(1),
                        },
                        border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xff3966F6)),
                            children: [
                              _gridHeader("Date"),
                              _gridHeader("P1"),
                              _gridHeader("P2"),
                              _gridHeader("P3"),
                              _gridHeader("P4"),
                              _gridHeader("P5"),
                              _gridHeader("P6"),
                            ],
                          ),
                          ...sortedDates.map((date) {
                            final periods = gridData[date] ?? {};
                            DateTime dt = DateTime.parse(date);
                            String dayNum = DateFormat('dd-MM-yyyy').format(dt);
                            String dayName = DateFormat('EEE').format(dt);
                            
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(dayNum, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      Text(dayName, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                _gridCell(periods['P1']),
                                _gridCell(periods['P2']),
                                _gridCell(periods['P3']),
                                _gridCell(periods['P4']),
                                _gridCell(periods['P5']),
                                _gridCell(periods['P6']),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildMonthlySummaryTable(semesterPresent, semesterTotal, semesterPercentage),
        const SizedBox(height: 32),
        _buildSemesterSummary(semesterPresent, semesterTotal, semesterPercentage),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color borderColor, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
          top: BorderSide(color: Colors.grey.shade100),
          right: BorderSide(color: Colors.grey.shade100),
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: valueColor ?? Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _gridHeader(String label) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _gridCell(String? status) {
    Color color = Colors.transparent;
    String label = "";
    if (status == 'P') {
      color = Colors.green;
      label = "P";
    } else if (status == 'A') {
      color = Colors.red;
      label = "A";
    }
    return Container(
      height: 48,
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildMonthlySummaryTable(int semesterPresent, int semesterTotal, double semesterPercentage) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xff3949AB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Text(
              "Monthly Attendance Summary",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            ),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade100)),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xffF8F9FA)),
                children: [
                  _summaryTh("Month"),
                  _summaryTh("Classes Attended"),
                  _summaryTh("Total Classes"),
                  _summaryTh("Percentage"),
                ],
              ),
              ..._semesterMonths.map((mKey) {
                final stats = _monthlyStats[mKey] ?? {'present': 0, 'total': 0, 'percentage': 100.0};
                final double percentage = stats['percentage'];
                final String name = _monthNames[mKey] ?? '';
                return TableRow(
                  children: [
                    _summaryTd(name),
                    _summaryTd(stats['present'].toString()),
                    _summaryTd(stats['total'].toString()),
                    _summaryTd(
                      "${percentage.toStringAsFixed(2)}%", 
                      color: percentage < 75.0 ? Colors.red : Colors.green,
                      isBold: true,
                    ),
                  ],
                );
              }).toList(),
              TableRow(
                decoration: const BoxDecoration(color: Color(0xffEBF3FE)),
                children: [
                  _summaryTd("Semester Total", isBold: true),
                  _summaryTd(semesterPresent.toString(), isBold: true),
                  _summaryTd(semesterTotal.toString(), isBold: true),
                  _summaryTd(
                    "${semesterPercentage.toStringAsFixed(2)}%", 
                    color: semesterPercentage < 75.0 ? Colors.red : Colors.green,
                    isBold: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTh(String label) => Padding(padding: const EdgeInsets.all(12), child: Center(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))));
  Widget _summaryTd(String value, {Color? color, bool isBold = false}) => Padding(
    padding: const EdgeInsets.all(12), 
    child: Center(
      child: Text(
        value, 
        style: TextStyle(
          fontSize: 12, 
          color: color ?? Colors.black87,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal
        ),
      ),
    ),
  );

  Widget _buildSemesterSummary(int semesterPresent, int semesterTotal, double semesterPercentage) {
    final isLow = semesterPercentage < 75.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Semester Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _metricCard("Total Present", semesterPresent.toString(), Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: _metricCard("Total Classes", semesterTotal.toString(), Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _metricCard("Overall Percentage", "${semesterPercentage.toStringAsFixed(2)}%", Colors.teal, valueColor: isLow ? Colors.red : Colors.green)),
          ],
        ),
        if (isLow) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade800, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Warning! Your attendance is below 75%. Regular attendance is important for academic success.",
                    style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
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
            ],
          ),
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: Colors.grey.shade200, width: 1.5),
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
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _todayStatus, 
                      style: TextStyle(
                        color: isPresentToday ? Colors.green : Colors.red, 
                        fontSize: 22, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isPresentToday 
                      ? "Marked by $_todayMarkedBy for $_todayPeriod" 
                      : "Not recognized yet today", 
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
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
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
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
                      _th("Date"), _th("Period"), _th("Status"),
                    ],
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
                      ],
                    )
                  else
                    ..._attendanceRecords.take(5).map((r) {
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
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isPres ? "Present" : "Absent", 
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                ],
              ),
            ],
          ),
        ),
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
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
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