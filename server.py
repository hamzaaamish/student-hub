
#!/usr/bin/env python3
"""Student Hub v2.2 - Local browser bridge.
Bash remains the database engine.
"""

from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.parse import urlparse, parse_qs
import json
import subprocess
import sys
import os

ROOT = Path(__file__).resolve().parent
STATIC = ROOT / "static"
BACKEND = ROOT / "backend.sh"
DB = ROOT / "students.txt"
BACKUP = ROOT / "students_backup.txt"
ACTIVITY_LOG = ROOT / "activity.log"


class Handler(SimpleHTTPRequestHandler):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(STATIC), **kwargs)

    def log_message(self, fmt, *args):
        print("[Student Hub]", fmt % args)

    def send_json(self, status, payload):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    # ---------------- BASH BRIDGE ----------------

    def run_bash(self, action, *args):

        env = {
            "PATH": os.environ.get("PATH", ""),
            "DB_FILE": str(DB),
            "BACKUP_FILE": str(BACKUP),
            "ACTIVITY_LOG_FILE": str(ACTIVITY_LOG),
        }

        result = subprocess.run(
            ["bash", str(BACKEND), action, *[str(x) for x in args]],
            cwd=ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            env=env
        )

        output = result.stdout.strip()

        if result.returncode != 0 or output.startswith("ERROR|"):
            message = (
                output.split("|", 1)[1]
                if "|" in output
                else result.stderr.strip() or "Bash operation failed."
            )
            raise ValueError(message)

        return output

    def records(self, output):

        rows = []

        for line in output.splitlines():
            parts = line.split("|")

            if len(parts) == 4:
                try:
                    rows.append({
                        "id": parts[0],
                        "name": parts[1],
                        "age": int(parts[2]),
                        "course": parts[3]
                    })
                except ValueError:
                    continue

        return rows

    # ---------------- INTEGRITY REPORT ----------------

    def integrity_report(self):

        output = self.run_bash("integrity")

        issues = []
        checked = 0
        issue_count = 0

        for line in output.splitlines():

            parts = line.split("|", 2)

            if parts[0] == "ISSUE" and len(parts) == 3:
                issues.append({
                    "line": int(parts[1]),
                    "message": parts[2]
                })

            elif parts[0] == "SUMMARY" and len(parts) == 3:
                checked = int(parts[1])
                issue_count = int(parts[2])

        return {
            "healthy": issue_count == 0,
            "status": "Healthy" if issue_count == 0 else "Issues Found",
            "checked": checked,
            "issue_count": issue_count,
            "issues": issues
        }

    # ---------------- ACTIVITY REPORT ----------------

    def activity_report(self, limit=20):

        output = self.run_bash("activity", limit)

        activities = []

        if output.startswith("EMPTY|"):
            return {
                "total": 0,
                "activities": []
            }

        for line in output.splitlines():

            parts = line.split("|", 4)

            if len(parts) != 5:
                continue

            timestamp, operation, record_id, details, status = parts

            activities.append({
                "timestamp": timestamp,
                "operation": operation,
                "record_id": record_id,
                "details": details,
                "status": status
            })

        # Backend returns newest entries last.
        activities.reverse()

        return {
            "total": len(activities),
            "activities": activities
        }

    # ---------------- GET REQUESTS ----------------

    def do_GET(self):

        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/api/students":

            try:
                rows = self.records(self.run_bash("list"))
                self.send_json(200, {"students": rows})

            except Exception as e:
                self.send_json(500, {"error": str(e)})

        elif path == "/api/stats":

            try:
                output = self.run_bash("stats")

                stats = {
                    "total": 0,
                    "average_age": 0,
                    "courses": []
                }

                for line in output.splitlines():

                    p = line.split("|")

                    if p[0] == "TOTAL":
                        stats["total"] = int(p[1])

                    elif p[0] == "AVERAGE":
                        stats["average_age"] = float(p[1])

                    elif p[0] == "COURSE":
                        stats["courses"].append({
                            "name": p[1],
                            "count": int(p[2])
                        })

                self.send_json(200, stats)

            except Exception as e:
                self.send_json(500, {"error": str(e)})

        elif path == "/api/integrity":

            try:
                report = self.integrity_report()
                self.send_json(200, report)

            except Exception as e:
                self.send_json(500, {"error": str(e)})

        elif path == "/api/activity":

            try:
                params = parse_qs(parsed.query)
                raw_limit = params.get("limit", ["20"])[0]

                limit = int(raw_limit)

                if not 1 <= limit <= 500:
                    raise ValueError("Limit must be between 1 and 500.")

                report = self.activity_report(limit)
                self.send_json(200, report)

            except ValueError as e:
                self.send_json(400, {"error": str(e)})

            except Exception as e:
                self.send_json(500, {"error": str(e)})

        else:
            return super().do_GET()

    # ---------------- POST REQUESTS ----------------

    def do_POST(self):

        path = urlparse(self.path).path

        try:

            length = int(self.headers.get("Content-Length", "0"))

            if length > 1024 * 1024:
                self.send_json(413, {"error": "Request too large."})
                return

            data = json.loads(self.rfile.read(length) or b"{}")

            if not isinstance(data, dict):
                self.send_json(400, {"error": "Invalid request data."})
                return

            if path == "/api/students":

                output = self.run_bash(
                    "add",
                    data.get("id", ""),
                    data.get("name", ""),
                    data.get("age", ""),
                    data.get("course", "")
                )

            elif path == "/api/update":

                output = self.run_bash(
                    "update",
                    data.get("id", ""),
                    data.get("name", ""),
                    data.get("age", ""),
                    data.get("course", "")
                )

            elif path == "/api/delete":

                output = self.run_bash(
                    "delete",
                    data.get("id", "")
                )

            elif path == "/api/search":

                mode = data.get("mode", "id")
                action = "search_id" if mode == "id" else "search_name"

                output = self.run_bash(action, data.get("query", ""))

                self.send_json(200, {
                    "students": self.records(output)
                })
                return

            elif path == "/api/filter":

                output = self.run_bash(
                    "filter_course",
                    data.get("course", "")
                )

                self.send_json(200, {
                    "students": self.records(output)
                })
                return

            elif path == "/api/profile":

                output = self.run_bash(
                    "profile",
                    data.get("id", "")
                )

                self.send_json(200, {
                    "student": self.records(output)[0]
                })
                return

            elif path == "/api/sort":

                output = self.run_bash("sort")

            elif path == "/api/backup":

                output = self.run_bash("backup")

            elif path == "/api/restore":

                output = self.run_bash("restore")

            else:

                self.send_json(404, {
                    "error": "Unknown API route"
                })
                return

            self.send_json(200, {
                "message": output.split("|", 1)[-1]
            })

        except ValueError as e:

            self.send_json(400, {
                "error": str(e)
            })

        except Exception as e:

            self.send_json(500, {
                "error": str(e)
            })


# ---------------- START SERVER ----------------

if __name__ == "__main__":

    if not BACKEND.exists():
        print("backend.sh is missing.")
        sys.exit(1)

    print("Student Hub v2.2 is running at http://127.0.0.1:8000")
    print("Bash database engine: ACTIVE")
    print("Activity audit trail: ENABLED")
    print("Keep this terminal open while using the website.")
    print("Press Ctrl+C to stop.")

    ThreadingHTTPServer(
        ("127.0.0.1", 8000),
        Handler
    ).serve_forever()
