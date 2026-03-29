import sys
import io
# Portfolio Sync Test - March 2026
# Force stdout to use UTF-8 so emojis don't crash the console
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

from flask import Flask, request, send_from_directory
# ... rest of your imports ...

from flask import Flask, request, send_from_directory
import pyodbc
import sqlite3


app = Flask(__name__)

# --- DATABASE LOGIC ---
import os

def get_db_connection():
    # It will now look for 'DB_SERVER' which we will set in Azure
    server = os.getenv('DB_SERVER')
    
    if server:
        try:
            conn_str = (
                f"Driver={FreeTDS} or Driver={ODBC Driver 17 for SQL Server}};"
                f"Server=tcp:{server},1433;"
                "Database=pianobookings;"
                "Uid=dbadmin;"
                "Pwd=YourPassword123!;"
                "Encrypt=yes;"
                "TrustServerCertificate=yes;"
                "Connection Timeout=30;"
            )
            return pyodbc.connect(conn_str)
        except Exception as e:
            print(f"Cloud DB connection failed: {e}")
    
    # FALLBACK to SQLite (for local testing/pipeline QA)
    print("Using local SQLite...")
    conn = sqlite3.connect('local_test.db')
    conn.execute('CREATE TABLE IF NOT EXISTS bookings (name TEXT, email TEXT, gender TEXT, day TEXT, start_date TEXT)')
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