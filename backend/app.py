import os
import sqlite3
import csv
import io
from datetime import datetime
from flask import Flask, request, jsonify, Response
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
CORS(app)  # Enables cross-origin requests for Flutter Web local development

DB_FILE = "nrcm_database.db"

def get_db_connection():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Students Table (face encoding data columns removed)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS students (
            roll_number TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            dept TEXT NOT NULL,
            year TEXT NOT NULL,
            section TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending'
        )
    ''')
    
    # Faculty Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS faculty (
            username TEXT PRIMARY KEY,
            password_hash TEXT NOT NULL,
            name TEXT NOT NULL,
            dept TEXT NOT NULL
        )
    ''')
    
    # Attendance Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            roll_number TEXT NOT NULL,
            date TEXT NOT NULL,
            period TEXT NOT NULL,
            dept TEXT NOT NULL,
            year TEXT NOT NULL,
            section TEXT NOT NULL,
            status TEXT NOT NULL,
            marked_by TEXT NOT NULL,
            FOREIGN KEY (roll_number) REFERENCES students (roll_number)
        )
    ''')
    
    # Seed a default admin and faculty user for testing if tables are empty
    cursor.execute("SELECT * FROM faculty WHERE username = 'faculty'")
    if not cursor.fetchone():
        cursor.execute("INSERT INTO faculty (username, password_hash, name, dept) VALUES (?, ?, ?, ?)",
                       ('faculty', generate_password_hash('faculty123'), 'Dr. Satish Kumar', 'CSE'))
    
    conn.commit()
    conn.close()

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    username = data.get('username')
    password = data.get('password')
    role = data.get('role') # 'Student/Parent', 'Faculty', 'Admin'

    if not username or not password or not role:
        return jsonify({"error": "Missing required fields"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    if role == 'Admin':
        if username == 'admin' and password == 'admin123':
            conn.close()
            return jsonify({"token": "mock-admin-token", "role": "Admin", "name": "System Admin"}), 200
        else:
            conn.close()
            return jsonify({"error": "Invalid Admin Credentials"}), 401

    elif role == 'Faculty':
        cursor.execute("SELECT * FROM faculty WHERE username = ?", (username,))
        user = cursor.fetchone()
        conn.close()
        if user and check_password_hash(user['password_hash'], password):
            return jsonify({"token": f"mock-faculty-token-{username}", "role": "Faculty", "name": user['name']}), 200
        return jsonify({"error": "Invalid Faculty Credentials"}), 401

    elif role == 'Student/Parent':
        cursor.execute("SELECT * FROM students WHERE roll_number = ?", (username,))
        user = cursor.fetchone()
        conn.close()
        if user:
            if user['status'] == 'pending':
                return jsonify({"error": "Approval pending. Please wait for Admin validation."}), 403
            if check_password_hash(user['password_hash'], password):
                return jsonify({"token": f"mock-student-token-{username}", "role": "Student/Parent", "name": user['name']}), 200
        return jsonify({"error": "Invalid Student Credentials"}), 401

    return jsonify({"error": "Invalid role configuration"}), 400

@app.route('/api/student/register', methods=['POST'])
def register_student():
    data = request.get_json() or {}
    name = data.get('name')
    roll_number = data.get('roll_number')
    password = data.get('password')
    dept = data.get('dept')
    year = data.get('year')
    section = data.get('section')

    if not all([name, roll_number, password, dept, year, section]):
        return jsonify({"error": "All fields are strictly required"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("INSERT INTO students (roll_number, name, password_hash, dept, year, section, status) VALUES (?, ?, ?, ?, ?, ?, ?)",
                       (roll_number, name, generate_password_hash(password), dept, year, section, 'pending'))
        conn.commit()
    except sqlite3.IntegrityError:
        return jsonify({"error": "Roll Number already registered"}), 400
    finally:
        conn.close()

    return jsonify({"message": "Registration successful. Pending verification."}), 201

@app.route('/api/admin/pending', methods=['GET'])
def get_pending_students():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT roll_number, name, dept, year, section FROM students WHERE status = 'pending'")
    rows = cursor.fetchall()
    conn.close()
    return jsonify([dict(ix) for ix in rows]), 200

@app.route('/api/admin/approve', methods=['POST'])
def approve_student():
    roll_number = request.get_json().get('roll_number')
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE students SET status = 'approved' WHERE roll_number = ?", (roll_number,))
    conn.commit()
    conn.close()
    return jsonify({"message": f"Student {roll_number} approved successfully."}), 200

@app.route('/api/admin/reject', methods=['POST'])
def reject_student():
    roll_number = request.get_json().get('roll_number')
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM students WHERE roll_number = ?", (roll_number,))
    conn.commit()
    conn.close()
    return jsonify({"message": f"Application {roll_number} removed from database."}), 200

@app.route('/api/admin/stats', methods=['GET'])
def get_admin_stats():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("SELECT COUNT(*) FROM students WHERE status = 'approved'")
    approved_students = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM students WHERE status = 'pending'")
    pending_students = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM faculty")
    total_faculty = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM attendance")
    total_attendance = cursor.fetchone()[0]
    
    conn.close()
    
    return jsonify({
        "approved_students": approved_students,
        "pending_students": pending_students,
        "total_faculty": total_faculty,
        "total_attendance": total_attendance
    }), 200

@app.route('/api/admin/users', methods=['GET'])
def get_all_users():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # 1. Fetch Faculty
    cursor.execute("SELECT username, name, dept FROM faculty")
    faculties = cursor.fetchall()
    
    # 2. Fetch Students
    cursor.execute("SELECT roll_number, name, dept, year, section, status FROM students")
    students = cursor.fetchall()
    conn.close()
    
    users_list = []
    
    # Add admin
    users_list.append({
        "user_id": "admin",
        "name": "System Admin",
        "role": "admin",
        "is_approved": True,
        "details": "All Departments"
    })
    
    # Add faculties
    for f in faculties:
        users_list.append({
            "user_id": f['username'],
            "name": f['name'],
            "role": "faculty",
            "is_approved": True,
            "details": f['dept'],
            "dept": f['dept']
        })
        
    # Add students
    for s in students:
        users_list.append({
            "user_id": s['roll_number'],
            "name": s['name'],
            "role": "student",
            "is_approved": s['status'] == 'approved',
            "details": f"{s['dept']} ({s['year']} Year - Sec {s['section']})",
            "dept": s['dept'],
            "year": s['year'],
            "section": s['section']
        })
        
    return jsonify(users_list), 200

@app.route('/api/admin/users/update', methods=['POST'])
def update_user_api():
    data = request.get_json() or {}
    user_id = data.get('user_id')
    role = data.get('role')
    name = data.get('name')
    dept = data.get('dept')
    password = data.get('password') # Optional

    # For student only
    year = data.get('year')
    section = data.get('section')

    if not user_id or not role or not name:
        return jsonify({"error": "Missing required fields"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        if role == 'faculty':
            if password:
                pwd_hash = generate_password_hash(password)
                cursor.execute(
                    "UPDATE faculty SET name = ?, dept = ?, password_hash = ? WHERE username = ?",
                    (name, dept, pwd_hash, user_id)
                )
            else:
                cursor.execute(
                    "UPDATE faculty SET name = ?, dept = ? WHERE username = ?",
                    (name, dept, user_id)
                )
            conn.commit()
            return jsonify({"message": f"Faculty {user_id} updated successfully."}), 200

        elif role == 'student':
            if not year or not section or not dept:
                return jsonify({"error": "Missing student details (dept, year, section)"}), 400
            
            if password:
                pwd_hash = generate_password_hash(password)
                cursor.execute(
                    "UPDATE students SET name = ?, dept = ?, year = ?, section = ?, password_hash = ? WHERE roll_number = ?",
                    (name, dept, year, section, pwd_hash, user_id)
                )
            else:
                cursor.execute(
                    "UPDATE students SET name = ?, dept = ?, year = ?, section = ? WHERE roll_number = ?",
                    (name, dept, year, section, user_id)
                )
            conn.commit()
            return jsonify({"message": f"Student {user_id} updated successfully."}), 200

        else:
            return jsonify({"error": "Invalid role or cannot edit admin user"}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()

@app.route('/api/admin/users/delete', methods=['POST'])
def delete_user_api():
    data = request.get_json() or {}
    user_id = data.get('user_id')
    role = data.get('role')
    
    if not user_id or not role:
        return jsonify({"error": "Missing user_id or role"}), 400
        
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        if role == 'faculty':
            cursor.execute("DELETE FROM faculty WHERE username = ?", (user_id,))
            conn.commit()
            conn.close()
            return jsonify({"message": f"Faculty {user_id} deleted successfully."}), 200
        elif role == 'student':
            # Delete attendance first
            cursor.execute("DELETE FROM attendance WHERE roll_number = ?", (user_id,))
            # Delete student
            cursor.execute("DELETE FROM students WHERE roll_number = ?", (user_id,))
            conn.commit()
            conn.close()
            return jsonify({"message": f"Student {user_id} deleted successfully."}), 200
        else:
            conn.close()
            return jsonify({"error": "Cannot delete admin user"}), 400
    except Exception as e:
        conn.close()
        return jsonify({"error": str(e)}), 500

@app.route('/api/admin/faculty/add', methods=['POST'])
def add_faculty_api():
    data = request.get_json() or {}
    username = data.get('username')
    name = data.get('name')
    password = data.get('password')
    dept = data.get('dept')
    
    if not all([username, name, password, dept]):
        return jsonify({"error": "All fields are required"}), 400
        
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Check if username exists in faculty
    cursor.execute("SELECT * FROM faculty WHERE username = ?", (username,))
    if cursor.fetchone():
        conn.close()
        return jsonify({"error": "Faculty username already exists"}), 400
        
    try:
        cursor.execute("INSERT INTO faculty (username, password_hash, name, dept) VALUES (?, ?, ?, ?)",
                       (username, generate_password_hash(password), name, dept))
        conn.commit()
        conn.close()
        return jsonify({"message": f"Faculty member {name} registered successfully."}), 201
    except Exception as e:
        conn.close()
        return jsonify({"error": str(e)}), 500

@app.route('/api/admin/download/master', methods=['GET'])
def download_master_history():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT a.date, a.dept, a.year, a.section, a.roll_number, s.name, a.period, a.status, a.marked_by
        FROM attendance a
        JOIN students s ON a.roll_number = s.roll_number
        ORDER BY a.date DESC, a.section ASC, a.roll_number ASC
    """)
    rows = cursor.fetchall()
    conn.close()
    
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['Date', 'Department', 'Year', 'Section', 'Roll Number', 'Student Name', 'Period', 'Status', 'Marked By'])
    
    for r in rows:
        writer.writerow([r['date'], r['dept'], r['year'], r['section'], r['roll_number'], r['name'], r['period'], r['status'], r['marked_by']])
        
    output.seek(0)
    return Response(
        output.getvalue(),
        mimetype="text/csv",
        headers={"Content-disposition": "attachment; filename=Master_Attendance_Report.csv"}
    )


@app.route('/api/faculty/students', methods=['GET'])
def get_roster_students():
    dept = request.args.get('dept')
    year = request.args.get('year')
    section = request.args.get('section')
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT roll_number, name FROM students WHERE dept = ? AND year = ? AND section = ? AND status = 'approved'", 
                   (dept, year, section))
    rows = cursor.fetchall()
    conn.close()
    return jsonify([dict(ix) for ix in rows]), 200

@app.route('/api/faculty/attendance/mark', methods=['POST'])
def mark_attendance():
    data = request.get_json() or {}
    date = data.get('date')
    period = data.get('period')
    dept = data.get('dept')
    year = data.get('year')
    section = data.get('section')
    records = data.get('records', []) # List of maps containing {'roll_number': '...', 'status': 'Present'/'Absent'}
    marked_by = request.headers.get('Authorization', 'Unknown Faculty')

    conn = get_db_connection()
    cursor = conn.cursor()
    
    for student in records:
        # Clear duplicate attendance entry for same period if accidentally re-submitted
        cursor.execute("""
            DELETE FROM attendance 
            WHERE roll_number = ? AND date = ? AND period = ?
        """, (student['roll_number'], date, period))
        
        cursor.execute("""
            INSERT INTO attendance (roll_number, date, period, dept, year, section, status, marked_by)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (student['roll_number'], date, period, dept, year, section, student['status'], marked_by))
        
    conn.commit()
    conn.close()
    return jsonify({"message": f"Successfully updated metrics for {len(records)} students."}), 201

@app.route('/api/faculty/attendance/report', methods=['GET'])
def get_attendance_report():
    date = request.args.get('date')
    dept = request.args.get('dept')
    year = request.args.get('year')
    section = request.args.get('section')

    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT a.roll_number, s.name, a.status 
        FROM attendance a
        JOIN students s ON a.roll_number = s.roll_number
        WHERE a.date = ? AND a.dept = ? AND a.year = ? AND a.section = ?
    """, (date, dept, year, section))
    
    rows = cursor.fetchall()
    conn.close()

    present_list = []
    absent_list = []
    for r in rows:
        student_obj = {"roll_number": r['roll_number'], "name": r['name'], "status": r['status']}
        if r['status'] == 'Present':
            present_list.append(student_obj)
        else:
            absent_list.append(student_obj)

    return jsonify({"present": present_list, "absent": absent_list}), 200

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)