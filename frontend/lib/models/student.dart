class Student {
  final String rollNumber;
  final String name;
  final String dept;
  final String year;
  final String section;

  Student({required this.rollNumber, required this.name, required this.dept, required this.year, required this.section});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      rollNumber: json['roll_number'] ?? '',
      name: json['name'] ?? '',
      dept: json['dept'] ?? '',
      year: json['year'] ?? '',
      section: json['section'] ?? '',
    );
  }
}