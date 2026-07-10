import 'package:flutter/material.dart';
import '../utils/session_storage.dart';
import 'dart:js' as js;
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

  // New admin variables
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  Map<String, dynamic> _stats = {};
  bool _isStatsLoading = false;
  bool _isUsersLoading = false;

  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _facultyIdController = TextEditingController();
  final _facultyNameController = TextEditingController();
  final _facultyPasswordController = TextEditingController();
  String? _selectedDept;

  final Color primaryMaroon = const Color(0xff5A1827);
  final Color accentPink = const Color(0xffE11D74);

  @override
  void initState() {
    super.initState();
    _fetchPendingStudents();
    _fetchAdminStats();
    _fetchAllUsers();
  }

  Future<void> _fetchAdminStats() async {
    setState(() { _isStatsLoading = true; });
    try {
      final res = await ApiService.getAdminStats();
      setState(() {
        _stats = res;
        _isStatsLoading = false;
      });
    } catch (_) {
      setState(() { _isStatsLoading = false; });
    }
  }

  Future<void> _fetchAllUsers() async {
    setState(() { _isUsersLoading = true; });
    try {
      final res = await ApiService.getAllUsers();
      setState(() {
        _allUsers = res;
        _filteredUsers = res;
        _isUsersLoading = false;
      });
    } catch (_) {
      setState(() { _isUsersLoading = false; });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _allUsers.where((u) {
        final id = (u['user_id'] ?? '').toString().toLowerCase();
        final name = (u['name'] ?? '').toString().toLowerCase();
        return id.contains(query.toLowerCase()) || name.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _deleteUser(String userId, String role) async {
    setState(() { _isLoading = true; });
    try {
      bool success = await ApiService.deleteUser(userId, role);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User deleted successfully"), backgroundColor: Colors.green),
        );
        _fetchAllUsers();
        _fetchAdminStats();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete user"), backgroundColor: Colors.red),
        );
      }
    } catch (_) {}
    setState(() { _isLoading = false; });
  }

  Future<void> _addFaculty() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      final res = await ApiService.addFaculty(
        _facultyIdController.text.trim(),
        _facultyNameController.text.trim(),
        _facultyPasswordController.text,
        _selectedDept ?? 'CSE',
      );
      if (res['statusCode'] == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Faculty member added successfully!"), backgroundColor: Colors.green),
        );
        _facultyIdController.clear();
        _facultyNameController.clear();
        _facultyPasswordController.clear();
        _selectedDept = null;
        _fetchAllUsers();
        _fetchAdminStats();
      } else {
        final err = res['body']?['error'] ?? "Failed to add faculty member.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      }
    } catch (_) {}
    setState(() { _isLoading = false; });
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
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: [
                          _sidebarTile(Icons.dashboard_outlined, "Dashboard", hasArrow: false),
                          _sidebarTile(Icons.how_to_reg_outlined, "Student Approvals", hasArrow: false, badgeCount: _pendingCount),
                          _sidebarTile(Icons.people_outline, "User Records", hasArrow: false),
                          _sidebarTile(Icons.settings_outlined, "System Settings", hasArrow: false),
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
      case 'Student Approvals':
        return _buildApprovalsContent();
      case 'User Records':
        return _buildUserRecordsContent();
      case 'System Settings':
        return _buildSystemSettingsContent();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    final approvedStudents = _stats['approved_students']?.toString() ?? '0';
    final totalFaculty = _stats['total_faculty']?.toString() ?? '0';
    final totalAttendance = _stats['total_attendance']?.toString() ?? '0';

    return SingleChildScrollView(
      child: Column(
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
          _isStatsLoading 
              ? const Center(child: CircularProgressIndicator())
              : GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.8,
                  children: [
                    _statCard(
                      icon: Icons.how_to_reg,
                      title: "Pending Approvals",
                      value: _pendingCount.toString(),
                      color: Colors.orange.shade800,
                      onTap: () => setState(() => _selectedMenu = 'Student Approvals'),
                    ),
                    _statCard(
                      icon: Icons.people,
                      title: "Approved Students",
                      value: approvedStudents,
                      color: Colors.green.shade600,
                      onTap: () => setState(() => _selectedMenu = 'User Records'),
                    ),
                    _statCard(
                      icon: Icons.school,
                      title: "Faculty Members",
                      value: totalFaculty,
                      color: Colors.blue.shade600,
                      onTap: () => setState(() => _selectedMenu = 'User Records'),
                    ),
                    _statCard(
                      icon: Icons.analytics_outlined,
                      title: "Attendance Records",
                      value: totalAttendance,
                      color: Colors.purple.shade600,
                      onTap: () => setState(() => _selectedMenu = 'System Settings'),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildUserRecordsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryMaroon, const Color(0xff8b293e)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Registered Users",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 4),
              Text(
                "Full database of all authorized accounts in the system.",
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Search Bar
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              onChanged: _filterUsers,
              decoration: const InputDecoration(
                hintText: "Search by Name or User ID/Roll Number...",
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                border: InputBorder.none,
                icon: Icon(Icons.search, size: 20, color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Data Table
        Expanded(
          child: Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            child: _isUsersLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Text(
                          "No registered users found matching the query.",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                              columns: const [
                                DataColumn(label: Text("User ID", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Role", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Approved Status", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Details", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: _filteredUsers.map((u) {
                                final String userId = u['user_id'] ?? '';
                                final String name = u['name'] ?? '';
                                final String role = u['role'] ?? 'student';
                                final bool isApproved = u['is_approved'] ?? false;
                                final String details = u['details'] ?? '';

                                return DataRow(cells: [
                                  DataCell(Text(userId, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text(name)),
                                  DataCell(Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: role == 'admin'
                                          ? Colors.purple.shade50
                                          : (role == 'faculty' ? Colors.blue.shade50 : Colors.teal.shade50),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      role.toUpperCase(),
                                      style: TextStyle(
                                        color: role == 'admin'
                                            ? Colors.purple.shade700
                                            : (role == 'faculty' ? Colors.blue.shade700 : Colors.teal.shade700),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )),
                                  DataCell(Icon(
                                    isApproved ? Icons.check_circle : Icons.cancel,
                                    color: isApproved ? Colors.green.shade600 : Colors.red.shade600,
                                    size: 20,
                                  )),
                                  DataCell(Text(details, style: const TextStyle(fontSize: 12, color: Colors.black54))),
                                  DataCell(
                                    role == 'admin'
                                        ? const SizedBox()
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                                onPressed: () => _showEditDialog(u),
                                                tooltip: "Edit Account",
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                onPressed: () => _confirmDelete(userId, role),
                                                tooltip: "Delete Account",
                                              ),
                                            ],
                                          ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
          ),
        )
      ],
    );
  }

  void _confirmDelete(String userId, String role) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Delete User Account?"),
          content: Text("Are you sure you want to permanently delete $role user '$userId'? All linked records/attendance will be deleted."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(ctx).pop();
                _deleteUser(userId, role);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(Map<String, dynamic> user) {
    final String userId = user['user_id'] ?? '';
    final String role = user['role'] ?? 'student';
    final String name = user['name'] ?? '';
    final String dept = user['dept'] ?? 'CSE';
    final String year = user['year'] ?? 'I';
    final String section = user['section'] ?? 'A';

    final nameController = TextEditingController(text: name);
    final passwordController = TextEditingController();
    String selectedDept = dept;
    String selectedYear = year;
    String selectedSection = section;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Edit ${role == 'faculty' ? 'Faculty' : 'Student'} Account"),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: role == 'faculty' ? "Faculty ID" : "Roll Number",
                          border: const OutlineInputBorder(),
                        ),
                        controller: TextEditingController(text: userId),
                        readOnly: true,
                        enabled: false,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "New Password (Optional)",
                          hintText: "Leave blank to keep unchanged",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedDept,
                        decoration: const InputDecoration(
                          labelText: "Department",
                          border: OutlineInputBorder(),
                        ),
                        items: ['CSE', 'ECE', 'EEE', 'MECH', 'CIVIL']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() => selectedDept = val);
                          }
                        },
                      ),
                      if (role == 'student') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedYear,
                          decoration: const InputDecoration(
                            labelText: "Year",
                            border: OutlineInputBorder(),
                          ),
                          items: ['I', 'II', 'III', 'IV']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() => selectedYear = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedSection,
                          decoration: const InputDecoration(
                            labelText: "Section",
                            border: OutlineInputBorder(),
                          ),
                          items: ['A', 'B', 'C', 'D', 'E', 'F', 'G']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() => selectedSection = val);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryMaroon),
                  onPressed: () {
                    final updatedName = nameController.text.trim();
                    if (updatedName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Name cannot be empty"), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    if (passwordController.text.isNotEmpty && passwordController.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Password must be at least 6 characters"), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    Navigator.of(ctx).pop();
                    _updateUser(
                      userId: userId,
                      role: role,
                      name: updatedName,
                      dept: selectedDept,
                      year: selectedYear,
                      section: selectedSection,
                      password: passwordController.text,
                    );
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateUser({
    required String userId,
    required String role,
    required String name,
    required String dept,
    required String year,
    required String section,
    required String password,
  }) async {
    setState(() { _isLoading = true; });
    try {
      final payload = {
        'user_id': userId,
        'role': role,
        'name': name,
        'dept': dept,
      };
      if (role == 'student') {
        payload['year'] = year;
        payload['section'] = section;
      }
      if (password.isNotEmpty) {
        payload['password'] = password;
      }

      bool success = await ApiService.updateUser(payload);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User updated successfully"), backgroundColor: Colors.green),
        );
        _fetchAllUsers();
        _fetchAdminStats();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update user"), backgroundColor: Colors.red),
        );
      }
    } catch (_) {}
    setState(() { _isLoading = false; });
  }

  Widget _buildSystemSettingsContent() {
    final approvedStudents = _stats['approved_students']?.toString() ?? '0';
    final pendingStudents = _stats['pending_students']?.toString() ?? '0';
    final totalFaculty = _stats['total_faculty']?.toString() ?? '0';
    final totalAttendance = _stats['total_attendance']?.toString() ?? '0';

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Panel: System Status & Downloads
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // System Status Info
                Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.insights, color: accentPink),
                            const SizedBox(width: 8),
                            const Text(
                              "System Configuration Status",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _settingsInfoRow("Database Connection", "Online", isBadge: true, badgeColor: Colors.green),
                        _settingsInfoRow("API Server Address", ApiService.baseUrl, isBadge: false),
                        _settingsInfoRow("Student Roster Size", approvedStudents, isBadge: false),
                        _settingsInfoRow("Attendance Log Entries", totalAttendance, isBadge: false),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Data Exports
                Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.download_for_offline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              "Database & Reports Export",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        const Text(
                          "Export full logs of student attendances, details, and metrics recorded on this web server.",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryMaroon,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          icon: const Icon(Icons.file_download, size: 18),
                          label: const Text("Download Master Attendance History (CSV)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            // Direct call to download master attendance CSV
                            js.context.callMethod('open', ['${ApiService.baseUrl}/admin/download/master', '_blank']);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Right Panel: Register Faculty Form
          Expanded(
            child: Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_add, color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            "Register New Faculty",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Faculty ID Input
                      TextFormField(
                        controller: _facultyIdController,
                        decoration: const InputDecoration(
                          labelText: "Faculty ID / Username",
                          hintText: "e.g., faculty_cse",
                          labelStyle: TextStyle(fontSize: 12),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? "Faculty ID is required" : null,
                      ),
                      const SizedBox(height: 16),

                      // Faculty Name Input
                      TextFormField(
                        controller: _facultyNameController,
                        decoration: const InputDecoration(
                          labelText: "Full Name (with Prefix)",
                          hintText: "e.g., Dr. Satish Kumar",
                          labelStyle: TextStyle(fontSize: 12),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? "Faculty name is required" : null,
                      ),
                      const SizedBox(height: 16),

                      // Password Input
                      TextFormField(
                        controller: _facultyPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Temporary Password",
                          labelStyle: TextStyle(fontSize: 12),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.length < 6 ? "Password must be at least 6 characters" : null,
                      ),
                      const SizedBox(height: 16),

                      // Department Selection Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedDept,
                        decoration: const InputDecoration(
                          labelText: "Assigned Department",
                          labelStyle: TextStyle(fontSize: 12),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: "CSE", child: Text("Computer Science (CSE)")),
                          DropdownMenuItem(value: "ECE", child: Text("Electronics & Comm (ECE)")),
                          DropdownMenuItem(value: "EEE", child: Text("Electrical & Elect (EEE)")),
                          DropdownMenuItem(value: "MECH", child: Text("Mechanical Eng (MECH)")),
                          DropdownMenuItem(value: "CIVIL", child: Text("Civil Eng (CIVIL)")),
                        ],
                        onChanged: (val) => setState(() => _selectedDept = val),
                        validator: (value) => value == null ? "Please assign a department" : null,
                      ),
                      const SizedBox(height: 24),

                      // Register Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: _isLoading ? null : _addFaculty,
                        child: const Text("Register Faculty Member", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _settingsInfoRow(String label, String value, {bool isBadge = false, Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          isBadge
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? Colors.grey).withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(color: badgeColor ?? Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                )
              : Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
        ],
      ),
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