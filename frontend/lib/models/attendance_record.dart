class AttendanceRecord {
  final String rollNumber;
  final String name;
  String status; // 'Present' or 'Absent'

  AttendanceRecord({required this.rollNumber, required this.name, this.status = 'Absent'});
}