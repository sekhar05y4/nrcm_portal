import 'package:flutter/material.dart';
import '../utils/session_storage.dart';
import 'manual_attendance_screen.dart';
import 'attendance_reports_screen.dart';

class FacultyDashboardScreen extends StatefulWidget {
  final String studentName; // serves as facultyName
  final String rollNumber;   // serves as facultyUsername

  const FacultyDashboardScreen({
    Key? key, 
    this.studentName = 'Faculty Member', 
    this.rollNumber = 'FACULTY',
  }) : super(key: key);

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
  String _selectedMenu = 'Dashboard';
  bool _isSidebarExpanded = true; 

  final Color primaryMaroon = const Color(0xff5A1827);
  final Color accentPink = const Color(0xffE11D74);

  // Class configuration dropdown states
  String _selectedPeriod = 'Period 1';
  String _selectedDept = 'CSE';
  String _selectedYear = 'I';
  String _selectedSection = 'A';

  final List<String> _periods = ['Period 1', 'Period 2', 'Period 3', 'Period 4', 'Period 5', 'Period 6'];
  final List<String> _departments = ['CSE', 'ECE', 'EEE', 'MECH', 'CIVIL'];
  final List<String> _years = ['I', 'II', 'III', 'IV'];
  final List<String> _sections = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

  @override
  Widget build(BuildContext context) {
    final bool mobile = MediaQuery.of(context).size.width < 800;
    final double sidebarWidth = 270;
    final double currentSidebarLeft = _isSidebarExpanded 
        ? 0 
        : (mobile ? -sidebarWidth : -sidebarWidth + 70);

    final double mainContentLeft = mobile ? 0 : (_isSidebarExpanded ? 270 : 70);

    return Scaffold(
      body: Stack(
        children: [
          // 1. MAIN CONTENT VIEWPORT (Base Layer)
          Positioned(
            left: mainContentLeft,
            top: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: const Color(0xffF8F9FA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 60,
                    padding: EdgeInsets.only(left: (mobile && !_isSidebarExpanded) ? 54 : 24, right: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Faculty Portal | $_selectedMenu",
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
                                widget.studentName.isNotEmpty ? widget.studentName[0].toUpperCase() : 'F',
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
                      padding: const EdgeInsets.all(24),
                      child: _renderActiveView(),
                    ),
                  )
                ],
              ),
            ),
          ),

          // 2. BACKDROP MASK
          if (mobile && _isSidebarExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isSidebarExpanded = false),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),

          // 3. OVERLAY SIDEBAR DRAWER
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: currentSidebarLeft,
            top: 0,
            bottom: 0,
            width: sidebarWidth,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  if (_isSidebarExpanded)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Image.asset('assets/nrcm_logo.png', height: 60, errorBuilder: (c, e, s) => Container()),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 1),
                  
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      children: [
                        _sidebarTile(Icons.dashboard_outlined, "Dashboard", hasArrow: false),
                        _sidebarTile(Icons.fact_check_outlined, "Mark Attendance", hasArrow: false),
                        _sidebarTile(Icons.assessment_outlined, "View Reports", hasArrow: false),
                        const Divider(height: 20, thickness: 1),
                        _sidebarTile(Icons.logout_outlined, "Logout", hasArrow: false, isLogout: true),
                      ],
                    ),
                  ),

                  // Sidebar Footer: Follow Us & Social Media Icons
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        const Text(
                          "Follow Us",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xffE11D74)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _socialIcon(Icons.facebook, Colors.indigo),
                            _socialIcon(Icons.camera_alt, Colors.pink),
                            _socialIcon(Icons.close, Colors.black),
                            _socialIcon(Icons.link, Colors.blue.shade700),
                            _socialIcon(Icons.play_arrow, Colors.red),
                            _socialIcon(Icons.message, Colors.green),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          // 4. FLOATING PINK TOGGLE BUTTON
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: _isSidebarExpanded ? 252 : (mobile ? 12 : 54),
            top: 28,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentPink, 
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
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

  Widget _socialIcon(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 14),
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
      case 'Mark Attendance':
        return _buildMarkAttendanceContent();
      case 'View Reports':
        return _buildViewReportsContent();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryMaroon, const Color(0xff8b293e)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: primaryMaroon.withAlpha(60),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome Back,",
                style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(200)),
              ),
              const SizedBox(height: 4),
              Text(
                widget.studentName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "Faculty Member | CSE Department",
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Quick Action Shortcuts
        Text(
          "Quick Actions",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                icon: Icons.fact_check_outlined,
                title: "Mark Attendance",
                subtitle: "Configure & take today's attendance roster",
                color: Colors.blue.shade600,
                onTap: () => setState(() => _selectedMenu = 'Mark Attendance'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _quickActionCard(
                icon: Icons.assessment_outlined,
                title: "Attendance Reports",
                subtitle: "Track, filter and analyze previous sheets",
                color: Colors.teal.shade600,
                onTap: () => setState(() => _selectedMenu = 'View Reports'),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkAttendanceContent() {
    return _buildConfigSelector(
      title: "Configure Attendance Session",
      actionText: "Open Attendance Roster",
      icon: Icons.fact_check,
      showPeriod: true,
      onAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ManualAttendanceScreen(
              period: _selectedPeriod,
              dept: _selectedDept,
              year: _selectedYear,
              section: _selectedSection,
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewReportsContent() {
    return _buildConfigSelector(
      title: "Select Roster Report Configuration",
      actionText: "View Attendance Sheets",
      icon: Icons.analytics,
      showPeriod: false,
      onAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceReportsScreen(
              dept: _selectedDept,
              year: _selectedYear,
              section: _selectedSection,
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfigSelector({
    required String title,
    required String actionText,
    required IconData icon,
    required bool showPeriod,
    required VoidCallback onAction,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon, color: primaryMaroon, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                    ),
                  ],
                ),
                const Divider(height: 32, thickness: 1),
                
                if (showPeriod) ...[
                  const Text("Select Period", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => _selectedPeriod = val!),
                  ),
                  const SizedBox(height: 20),
                ],

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Department", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedDept,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                            onChanged: (val) => setState(() => _selectedDept = val!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Academic Year", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedYear,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                            onChanged: (val) => setState(() => _selectedYear = val!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text("Section", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedSection,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _sections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _selectedSection = val!),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryMaroon,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: onAction,
                    child: Text(
                      actionText,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}