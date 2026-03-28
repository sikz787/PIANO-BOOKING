import sys
import io

# Force stdout to use UTF-8 so emojis don't crash the console
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

from flask import Flask, request, send_from_directory
# ... rest of your imports ...

from flask import Flask, request, send_from_directory
import pyodbc
import sqlite3


app = Flask(__name__)

# --- DATABASE LOGIC ---
def get_db_connection():
    # 1. Try Azure SQL First
    try:
        # We use your existing connection string
        conn_str = (
            "Driver={ODBC Driver 18 for SQL Server};"
            "Server=tcp:piano-db-server-44288.database.windows.net,1433;"
            "Database=pianobookings;"
            "Uid=dbadmin;"
            "Pwd=YourPassword123!;" # Ensure this matches your secret if using Variables
            "Encrypt=yes;"
            "TrustServerCertificate=yes;"
            "Connection Timeout=5;" # Short timeout so tests don't hang
        )
        return pyodbc.connect(conn_str)
    except Exception:
        # 2. FALLBACK: Use SQLite for Testing
        print("⚠️ Azure DB not found. Using local SQLite for this test run...")
        conn = sqlite3.connect('local_test.db')
        # Create the table if it doesn't exist in the local file
        conn.execute('''CREATE TABLE IF NOT EXISTS bookings 
                        (name TEXT, email TEXT, gender TEXT, day TEXT, start_date TEXT)''')
        return conn

@app.route('/')
def home():
    return send_from_directory('.', 'index.html')

@app.route('/book', methods=['POST'])
def book():
    try:
        data = request.json
        conn = get_db_connection()
        cursor = conn.cursor()
        
        query = "INSERT INTO bookings (name, email, gender, day, start_date) VALUES (?, ?, ?, ?, ?)"
        params = (
            data.get('name'), 
            data.get('email'), 
            data.get('gender'), 
            data.get('day'), 
            data.get('start_date')
        )

        # SQLite uses '?' just like pyodbc, so this works for both!
        cursor.execute(query, params)
        
        conn.commit()
        conn.close()
        return "Profile Saved Successfully!"
    except Exception as e:
        return f"❌ Database Error: {str(e)}"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)