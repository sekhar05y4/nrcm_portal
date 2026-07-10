import os
import pymysql
import csv
import io
from datetime import datetime
from flask import Flask, request, jsonify, Response
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
CORS(app)  # Enables cross-origin requests for Flutter Web local development

def get_db_connection():
    conn = pymysql.connect(
        host=os.environ.get('DB_HOST', 'localhost'),
        port=int(os.environ.get('DB_PORT', 3306)),
        user=os.environ.get('DB_USER', 'root'),
        password=os.environ.get('DB_PASS', 'mysqlpass'),
        database=os.environ.get('DB_NAME', 'nrcm_att'),
        cursorclass=pymysql.cursors.DictCursor
    )
    return conn

def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Check if 'users' table exists. If not, drop the old tables so we can create new ones.
    cursor.execute("SHOW TABLES LIKE 'users'")
    if not cursor.fetchone():
        cursor.execute("DROP TABLE IF EXISTS attendance")
        cursor.execute("DROP TABLE IF EXISTS students")
        cursor.execute("DROP TABLE IF EXISTS faculty")
        
    # Create Users Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            userid VARCHAR(100) PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            role VARCHAR(50) NOT NULL,
            dept VARCHAR(100) NOT NULL,
            year VARCHAR(50) DEFAULT NULL,
            section VARCHAR(50) DEFAULT NULL,
            status VARCHAR(50) NOT NULL DEFAULT 'approved'
        )
    ''')
    
    # Create Attendance Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS attendance (
            id INT AUTO_INCREMENT PRIMARY KEY,
            roll_number VARCHAR(100) NOT NULL,
            date VARCHAR(50) NOT NULL,
            period VARCHAR(50) NOT NULL,
            dept VARCHAR(100) NOT NULL,
            year VARCHAR(50) NOT NULL,
            section VARCHAR(50) NOT NULL,
            status VARCHAR(50) NOT NULL,
            marked_by VARCHAR(255) NOT NULL,
            FOREIGN KEY (roll_number) REFERENCES users (userid)
        )
    ''')
    
    # Seed default faculty if empty
    cursor.execute("SELECT * FROM users WHERE userid = 'faculty'")
    if not cursor.fetchone():
        cursor.execute("INSERT INTO users (userid, name, password_hash, role, dept) VALUES (%s, %s, %s, %s, %s)",
                       ('faculty', 'Dr. Satish Kumar', generate_password_hash('faculty123'), 'faculty', 'CSE'))
                       
    # Seed default student Mahadev if empty
    cursor.execute("SELECT * FROM users WHERE userid = '24X01A05AT'")
    if not cursor.fetchone():
        cursor.execute("INSERT INTO users (userid, name, password_hash, role, dept, year, section, status) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
                       ('24X01A05AT', 'Mahadev', generate_password_hash('student123'), 'student', 'CSE', 'III', 'B', 'approved'))
                       
    # Revert fake generated attendance to just single real row
    cursor.execute("DELETE FROM attendance WHERE roll_number = '24X01A05AT' AND (date LIKE '2026-06-%%' OR date <= '2026-07-09')")
    
    cursor.execute("SELECT * FROM attendance WHERE roll_number = '24X01A05AT'")
    if not cursor.fetchone():
        cursor.execute(
            "INSERT INTO attendance (roll_number, date, period, dept, year, section, status, marked_by) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
            ('24X01A05AT', '2026-07-10', 'Period 1', 'CSE', 'III', 'B', 'Present', 'Dr. Satish Kumar')
        )
    
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
        cursor.execute("SELECT * FROM users WHERE userid = %s AND role = 'faculty'", (username,))
        user = cursor.fetchone()
        conn.close()
        if user and check_password_hash(user['password_hash'], password):
            return jsonify({"token": f"mock-faculty-token-{username}", "role": "Faculty", "name": user['name']}), 200
        return jsonify({"error": "Invalid Faculty Credentials"}), 401

    elif role == 'Student/Parent':
        cursor.execute("SELECT * FROM users WHERE userid = %s AND role = 'student'", (username,))
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
        cursor.execute("INSERT INTO users (userid, name, password_hash, role, dept, year, section, status) VALUES (%s, %s, %s, 'student', %s, %s, %s, 'pending')",
                       (roll_number, name, generate_password_hash(password), dept, year, section))
        conn.commit()
    except pymysql.err.IntegrityError:
        return jsonify({"error": "Roll Number already registered"}), 400
    finally:
        conn.close()

    return jsonify({"message": "Registration successful. Pending verification."}), 201

@app.route('/api/admin/pending', methods=['GET'])
def get_pending_students():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT userid as roll_number, name, dept, year, section FROM users WHERE status = 'pending' AND role = 'student'")
    rows = cursor.fetchall()
    conn.close()
    return jsonify([dict(ix) for ix in rows]), 200

@app.route('/api/admin/approve', methods=['POST'])
def approve_student():
    roll_number = request.get_json().get('roll_number')
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET status = 'approved' WHERE userid = %s AND role = 'student'", (roll_number,))
    conn.commit()
    conn.close()
    return jsonify({"message": f"Student {roll_number} approved successfully."}), 200

@app.route('/api/admin/reject', methods=['POST'])
def reject_student():
    roll_number = request.get_json().get('roll_number')
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM users WHERE userid = %s AND role = 'student'", (roll_number,))
    conn.commit()
    conn.close()
    return jsonify({"message": f"Application {roll_number} removed from database."}), 200

@app.route('/api/admin/stats', methods=['GET'])
def get_admin_stats():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("SELECT COUNT(*) as count FROM users WHERE status = 'approved' AND role = 'student'")
    approved_students = cursor.fetchone()['count']
    
    cursor.execute("SELECT COUNT(*) as count FROM users WHERE status = 'pending' AND role = 'student'")
    pending_students = cursor.fetchone()['count']
    
    cursor.execute("SELECT COUNT(*) as count FROM users WHERE role = 'faculty'")
    total_faculty = cursor.fetchone()['count']
    
    cursor.execute("SELECT COUNT(*) as count FROM attendance")
    total_attendance = cursor.fetchone()['count']
    
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
    
    cursor.execute("SELECT userid, name, role, status, dept, year, section FROM users")
    users = cursor.fetchall()
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
    
    for u in users:
        if u['userid'] == 'admin':
            continue
            
        role = u['role']
        if role == 'faculty':
            users_list.append({
                "user_id": u['userid'],
                "name": u['name'],
                "role": "faculty",
                "is_approved": True,
                "details": u['dept'],
                "dept": u['dept']
            })
        elif role == 'student':
            users_list.append({
                "user_id": u['userid'],
                "name": u['name'],
                "role": "student",
                "is_approved": u['status'] == 'approved',
                "details": f"{u['dept']} ({u['year']} Year - Sec {u['section']})",
                "dept": u['dept'],
                "year": u['year'],
                "section": u['section']
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
                    "UPDATE users SET name = %s, dept = %s, password_hash = %s WHERE userid = %s AND role = 'faculty'",
                    (name, dept, pwd_hash, user_id)
                )
            else:
                cursor.execute(
                    "UPDATE users SET name = %s, dept = %s WHERE userid = %s AND role = 'faculty'",
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
                    "UPDATE users SET name = %s, dept = %s, year = %s, section = %s, password_hash = %s WHERE userid = %s AND role = 'student'",
                    (name, dept, year, section, pwd_hash, user_id)
                )
            else:
                cursor.execute(
                    "UPDATE users SET name = %s, dept = %s, year = %s, section = %s WHERE userid = %s AND role = 'student'",
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
            cursor.execute("DELETE FROM users WHERE userid = %s AND role = 'faculty'", (user_id,))
            conn.commit()
            conn.close()
            return jsonify({"message": f"Faculty {user_id} deleted successfully."}), 200
        elif role == 'student':
            # Delete attendance first
            cursor.execute("DELETE FROM attendance WHERE roll_number = %s", (user_id,))
            # Delete student
            cursor.execute("DELETE FROM users WHERE userid = %s AND role = 'student'", (user_id,))
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
    cursor.execute("SELECT * FROM users WHERE userid = %s", (username,))
    if cursor.fetchone():
        conn.close()
        return jsonify({"error": "Faculty username already exists"}), 400
        
    try:
        cursor.execute("INSERT INTO users (userid, password_hash, name, dept, role, status) VALUES (%s, %s, %s, %s, 'faculty', 'approved')",
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
        JOIN users s ON a.roll_number = s.userid
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


@app.route('/api/faculty/download/report', methods=['GET'])
def download_faculty_report():
    date = request.args.get('date')
    dept = request.args.get('dept')
    year = request.args.get('year')
    section = request.args.get('section')
    
    if not all([date, dept, year, section]):
        return jsonify({"error": "Missing parameters"}), 400
        
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT a.roll_number, s.name, a.status 
        FROM attendance a
        JOIN users s ON a.roll_number = s.userid
        WHERE a.date = %s AND a.dept = %s AND a.year = %s AND a.section = %s
        ORDER BY a.roll_number ASC
    """, (date, dept, year, section))
    rows = cursor.fetchall()
    conn.close()
    
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['Roll Number', 'Student Name', 'Status'])
    for r in rows:
        writer.writerow([r['roll_number'], r['name'], r['status']])
        
    output.seek(0)
    filename = f"Attendance_Report_{dept}_{year}_{section}_{date}.csv"
    return Response(
        output.getvalue(),
        mimetype="text/csv",
        headers={"Content-disposition": f"attachment; filename={filename}"}
    )


@app.route('/api/faculty/students', methods=['GET'])
def get_roster_students():
    dept = request.args.get('dept')
    year = request.args.get('year')
    section = request.args.get('section')
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT userid as roll_number, name FROM users WHERE dept = %s AND year = %s AND section = %s AND status = 'approved' AND role = 'student'", 
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

    # Extract username if it's a mock token and resolve to the faculty name
    if marked_by.startswith("mock-faculty-token-"):
        faculty_username = marked_by.replace("mock-faculty-token-", "")
        cursor.execute("SELECT name FROM users WHERE userid = %s AND role = 'faculty'", (faculty_username,))
        row = cursor.fetchone()
        if row:
            marked_by = row['name']
        else:
            marked_by = faculty_username
    
    for student in records:
        # Clear duplicate attendance entry for same period if accidentally re-submitted
        cursor.execute("""
            DELETE FROM attendance 
            WHERE roll_number = %s AND date = %s AND period = %s
        """, (student['roll_number'], date, period))
        
        cursor.execute("""
            INSERT INTO attendance (roll_number, date, period, dept, year, section, status, marked_by)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
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

    if not all([date, dept, year, section]):
        return jsonify({"error": "Missing parameters"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT a.roll_number, s.name, a.period, a.status, a.marked_by, a.dept, a.year, a.section
        FROM attendance a
        JOIN users s ON a.roll_number = s.userid
        WHERE a.date = %s AND a.dept = %s AND a.year = %s AND a.section = %s
        ORDER BY a.roll_number ASC, a.period ASC
    """, (date, dept, year, section))
    
    rows = cursor.fetchall()
    conn.close()

    students_map = {}
    for r in rows:
        roll = r['roll_number']
        if roll not in students_map:
            students_map[roll] = {
                "roll_number": roll,
                "name": r['name'],
                "dept": r['dept'],
                "year": r['year'],
                "section": r['section'],
                "present_periods": [],
                "absent_periods": [],
                "marked_by_set": set()
            }
        
        p_name = r['period']
        if p_name.startswith("Period "):
            p_name = "P" + p_name.replace("Period ", "")
            
        if r['status'] == 'Present':
            students_map[roll]["present_periods"].append(p_name)
        else:
            students_map[roll]["absent_periods"].append(p_name)
            
        if r['marked_by']:
            students_map[roll]["marked_by_set"].add(r['marked_by'])

    students_list = []
    for roll, info in students_map.items():
        marked_by_str = ", ".join(sorted(list(info["marked_by_set"])))
        students_list.append({
            "roll_number": info["roll_number"],
            "name": info["name"],
            "dept": info["dept"],
            "year": info["year"],
            "section": info["section"],
            "present_periods": info["present_periods"],
            "absent_periods": info["absent_periods"],
            "marked_by": marked_by_str
        })

    return jsonify({"students": students_list}), 200


@app.route('/api/student/attendance', methods=['GET'])
def get_student_attendance():
    auth_header = request.headers.get('Authorization', '')
    if not auth_header.startswith("mock-student-token-"):
        return jsonify({"error": "Unauthorized"}), 401
    
    roll_number = auth_header.replace("mock-student-token-", "")
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT date, period, status, marked_by 
        FROM attendance 
        WHERE roll_number = %s 
        ORDER BY date DESC
    """, (roll_number,))
    rows = cursor.fetchall()
    conn.close()
    
    return jsonify([dict(r) for r in rows]), 200


if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)