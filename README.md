<<<<<<< HEAD
# Student Hub — Student Database Management System

A Bash-powered Student Database Management System with a modern browser-based dashboard. It allows users to manage student records through a clean web interface while keeping Bash as the core database engine.

## Features

- **Add Students:** Register new students with ID, name, age and course.
- **View Students:** Display all student records.
- **Search Students:** Search by student ID or name.
- **Update Records:** Modify existing student information.
- **Delete Records:** Remove student records.
- **Course Filtering:** Filter students based on their course.
- **ID-Based Sorting:** Arrange student records in ascending order of Student ID.
- **Dashboard:** View student statistics and course information.
- **Backup and Restore:** Create database backups and restore saved records.
- **Input Validation:** Prevent invalid entries and duplicate student IDs.

## Technology Stack

| Technology | Purpose |
|---|---|
| Bash Shell Scripting | Core database operations |
| Python | Local HTTP server and backend bridge |
| HTML5 | Webpage structure |
| CSS3 | Dashboard styling |
| JavaScript | Frontend interactions |
| Text File Database | Student record storage |

## Project Structure

```text
StudentDatabase/
│
├── main.sh
├── main_v1_backup.sh
├── backend.sh
├── server.py
├── students.txt
├── students_backup.txt
├── README.md
│
└── static/
    ├── index.html
    ├── style.css
    └── app.js
```

## Installation and Setup

### Requirements

- Windows, Linux or macOS
- Git Bash or a Bash-compatible shell
- Python 3
- Visual Studio Code (recommended)

### Run the Web Application

1. Clone or download the project.
2. Open the project directory in VS Code.
3. Open the terminal.
4. Start the local server:

```bash
python server.py
```

5. Open your browser and visit:

```text
http://127.0.0.1:8000
```

### Run the Terminal Application

Open Git Bash in the project directory and execute:

```bash
./main.sh
```

## Database Format

Student records are stored in `students.txt` using a pipe-separated format:

```text
101|Ronaldo|18|CSE
102|Modric|20|DS
103|Benzema|18|CYBER
```

Each record contains:

- Student ID
- Student Name
- Age
- Course

## How It Works

The browser frontend communicates with the Python HTTP server. The Python server invokes Bash scripts to perform database operations. Bash processes the records stored in the text file and returns the results to the server, which sends responses back to the frontend.

## Security and Usage

This project is designed for local demonstration and educational use. The development server binds to `127.0.0.1` and is not configured for public internet deployment or multi-user production access.

## Learning Outcomes

- Practical implementation of Bash scripting.
- File handling and text processing in Linux.
- Use of shell commands such as `awk`, `sort`, `cp` and `touch`.
- Input validation and conditional statements.
- Integration of Bash with Python.
- Basic client-server communication.
- Development of a browser-based user interface.

## Project Information

**Project:** Student Hub — Student Database Management System  
**Subject:** Linux Programming  
**Core Language:** Bash  
**Interface:** Web-based Dashboard  
**Database:** File-based Storage

---

Developed as an academic project to demonstrate Linux shell programming and integration with a modern web interface.
=======
# student-hub
Student Database Management System using Bash Shell Scripting
>>>>>>> 1adadfd98ceca88bd48590fc0a2fd6d146d73fe1
