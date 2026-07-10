import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/api_service.dart';
import '../models/student.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String studentName; // serves as adminName
  final String rollNumber;   // serves as adminUsername

  const AdminDashboardScreen({
    Key? key, 
    this.studentName = 'Admin User', 
    this.rollNumber = 'ADMIN',
  }) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedMenu = 'Dashboard';
  bool _isSidebarExpanded = true; 
  List<Student> _pendingStudents = [];
  bool _isLoading = false;
  int _pendingCount = 0;

  final Color primaryMaroon = const Color(0xff5A1827);
  final Color accentPink = const Color(0xffE11D74);

  @override
  void initState() {
    super.initState();
    _fetchPendingStudents();
  }

  Future<void> _fetchPendingStudents() async {
    setState(() { _isLoading = true; });
    try {
      final list = await ApiService.getPendingStudents();
      setState(() {
        _pendingStudents = list;
        _pendingCount = list.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch pending students")),
      );
    }
  }

  Future<void> _processApproval(String rollNumber, bool approved) async {
    setState(() { _isLoading = true; });
    try {
      bool success = await ApiService.handleApproval(rollNumber, approved);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved ? "Student approved successfully!" : "Registration request rejected."),
            backgroundColor: approved ? Colors.green.shade600 : Colors.red.shade600,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Action execution failed.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred during transaction.")),
      );
    }
    _fetchPendingStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // --- SIDEBAR NAVIGATION ---
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
                          child: Icon(Icons.admin_panel_settings, color: primaryMaroon, size: 20),
                        ),
                      ),
                    const Divider(height: 20, thickness: 1),
                    
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: [
                          _sidebarTile(Icons.dashboard_outlined, "Dashboard", hasArrow: false),
                          _sidebarTile(Icons.how_to_reg_outlined, "Student Approvals", hasArrow: false, badgeCount: _pendingCount),
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
                              "Admin Portal | $_selectedMenu",
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
                                    widget.studentName.isNotEmpty ? widget.studentName[0].toUpperCase() : 'A',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: Padding(
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
                  decoration: BoxDecoration(
                    color: accentPink, 
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

  Widget _sidebarTile(IconData icon, String label, {bool hasArrow = true, bool isLogout = false, int badgeCount = 0}) {
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
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label, 
                    style: TextStyle(
                      color: isLogout 
                          ? Colors.amber.shade800 
                          : (isSelected ? primaryMaroon : Colors.black87),
                      fontWeight: isSelected || isLogout ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13
                    ),
                  ),
                  if (badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentPink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    )
                ],
              )
            : null,
        trailing: (_isSidebarExpanded && hasArrow && !isLogout)
            ? Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400)
            : null,
        onTap: () {
          if (isLogout) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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
      case 'Student Approvals':
        return _buildApprovalsContent();
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
                "System Access Authorized,",
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
                  "System Administrator",
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // System Status Overview Grid
        Text(
          "System Overview",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.how_to_reg,
                title: "Pending Approvals",
                value: _pendingCount.toString(),
                color: Colors.orange.shade800,
                onTap: () => setState(() => _selectedMenu = 'Student Approvals'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _statCard(
                icon: Icons.dns_outlined,
                title: "Database Ledger Status",
                value: "ONLINE",
                color: Colors.green.shade600,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _statCard(
                icon: Icons.security_outlined,
                title: "Security & Encryption",
                value: "ACTIVE",
                color: Colors.blue.shade600,
                onTap: () {},
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Text(
                    value,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Pending Registration Requests",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: primaryMaroon),
              onPressed: _fetchPendingStudents,
              tooltip: "Refresh list",
            )
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading && _pendingStudents.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _pendingStudents.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _pendingStudents.length,
                      itemBuilder: (context, index) {
                        final student = _pendingStudents[index];
                        return _buildPendingStudentCard(student);
                      },
                    ),
        )
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                "All Caught Up!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                "There are no pending student registration requests waiting for your approval.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingStudentCard(Student student) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: Colors.grey.shade200, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Student avatar placeholder
            CircleAvatar(
              backgroundColor: primaryMaroon.withAlpha(15),
              radius: 22,
              child: Icon(Icons.person_outline, color: primaryMaroon),
            ),
            const SizedBox(width: 16),
            
            // Student details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Roll Number: ${student.rollNumber}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Branch: ${student.dept}  |  Year: ${student.year}  |  Section: ${student.section}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            
            // Approval Actions
            Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: _isLoading ? null : () => _processApproval(student.rollNumber, false),
                  child: const Text("Reject", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: _isLoading ? null : () => _processApproval(student.rollNumber, true),
                  child: const Text("Approve", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}