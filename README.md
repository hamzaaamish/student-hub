# Student Hub — Student Database Management System

A Bash-powered Student Database Management System with a browser-based dashboard, developed as a Linux Programming academic project.

Student Hub demonstrates how Bash Shell Scripting can be used as the core data-processing engine while a lightweight Python HTTP server connects it to a local web interface.

## Features

- **Student CRUD:** Add, view, update, and delete student records.
- **Search:** Find records by student ID or name.
- **Sorting and filtering:** Sort records and filter students by course.
- **Dashboard and analytics:** View student statistics and course information.
- **Database integrity checker:** Detect malformed records, missing fields, invalid IDs, duplicate IDs, invalid names, ages, and courses.
- **Backup and restore:** Create database backups and preserve a pre-restore copy before restoring.
- **Activity audit trail:** Record timestamped operations and their status without storing student names in the log.
- **CSV export:** Export student records from the web interface.
- **Browser interface:** Student directory, profiles, modals, responsive layout, and light/dark themes.

## Technology Stack

| Technology | Role |
|---|---|
| Bash Shell Scripting | Core database operations and record processing |
| Python 3 | Local HTTP server and bridge to the Bash backend |
| HTML5 | Frontend structure |
| CSS3 | Styling and responsive layout |
| JavaScript | Frontend interactions and API communication |
| Pipe-separated text file | Student record storage |

## Architecture

```text
Browser UI
(HTML, CSS, JavaScript)
        |
        v
Python HTTP Bridge
(server.py)
        |
        v
Bash Backend
(backend.sh)
        |
        v
Text File Database
(students.txt)
```

**Architecture note:** Bash is the core database engine. Python acts as a local HTTP bridge and invokes Bash commands; it is not a separate database engine.

## Project Structure

```text
student-hub/
├── .gitignore
├── README.md
├── backend.sh
├── main.sh
├── main_v1_backup.sh
├── server.py
└── static/
    ├── index.html
    ├── style.css
    └── app.js
```

Runtime data files such as `students.txt`, `students_backup.txt`, and `activity.log` are created locally and excluded from the public repository.

## Requirements

- Python 3
- Bash-compatible shell (Git Bash on Windows, or Bash on Linux/macOS)
- A modern web browser

## Setup and Run

### 1. Clone the repository

```bash
git clone https://github.com/hamzaaamish/student-hub.git
cd student-hub
```

### 2. Start the local web server

```bash
python server.py
```

### 3. Open the application

Visit:

```text
http://127.0.0.1:8000
```

### 4. Run the terminal interface

```bash
bash main.sh
```

### 5. Run backend actions

Examples:

```bash
bash backend.sh list
bash backend.sh stats
bash backend.sh integrity
bash backend.sh backup
bash backend.sh activity 20
```

## Data Format

Student records are stored as pipe-separated fields:

```text
StudentID|Name|Age|Course
101|Sample Student|20|CSE
102|Another Student|19|ECE
```

The database stores four fields per record: student ID, name, age, and course. The example records above are illustrative only.

## Integrity Checks and Audit Trail

The integrity checker validates record structure and required fields, checks IDs and duplicates, and validates student names, ages, and courses.

The activity log records the timestamp, operation, record ID, details, and status. It is designed not to store student names. During restore, the current database is copied to a pre-restore file before the backup is applied.

## Verified Development Results

During development:

- The integrity API returned a **Healthy** status.
- **12 records** were checked with **0 integrity issues** in that test.
- ADD, UPDATE, and DELETE operations were recorded successfully.
- The activity API returned the latest audit records.

These are development test observations, not performance benchmarks.

## Limitations

- Intended for local educational demonstration.
- Uses text-file storage rather than a relational database.
- Does not include user authentication or role-based access.
- Not designed for concurrent multi-user production use.
- The local server binds to the loopback address and is not configured for public deployment.

## Future Scope

- Authentication and role-based access.
- Integration with a relational database.
- Improved reporting and analytics.
- Stronger access controls and support for concurrent users.
- Optional deployment for controlled remote access.

## Learning Outcomes

- Bash Shell Scripting and Linux command-line workflows.
- File handling and text processing with tools such as AWK.
- CRUD operations and input validation.
- Backup, restore, and audit logging.
- Data integrity checks.
- Integration of Bash scripts with a Python HTTP server.
- Frontend development and client-server communication.

## Project Information

| Field | Details |
|---|---|
| Project | Student Hub |
| Subject | Linux Programming |
| Department | Computer Science & Engineering |
| Core language | Bash Shell Scripting |
| Interface | Local browser-based dashboard |
| Storage | Pipe-separated text file |
| Version | 2.2 |

---

Developed as an academic project to demonstrate Linux programming, shell scripting, file handling, and integration with a browser-based interface.
