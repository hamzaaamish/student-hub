
#!/bin/bash

# ==================================================
# STUDENT HUB v3.1
# Student Database Management System
# Developed using Bash Shell Scripting
# ==================================================

DB="students.txt"
BACKUP="students_backup.txt"

touch "$DB"

# ---------------- COLORS ----------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
RESET='\033[0m'

# ---------------- UI FUNCTIONS ----------------

show_header() {
    echo -e "${CYAN}"
    echo "=================================================="
    echo "                                                  "
    echo "                   STUDENT HUB                   "
    echo "                                                  "
    echo "=================================================="
    echo -e "${RESET}"

    echo -e "${YELLOW}       STUDENT DATABASE MANAGEMENT SYSTEM${RESET}"
    echo -e "${MAGENTA}                    VERSION 3.1${RESET}"
    echo "=================================================="
}

pause_screen() {
    echo ""
    read -rp "Press Enter to continue..."
}

show_message() {
    echo -e "${GREEN}$1${RESET}"
}

show_error() {
    echo -e "${RED}$1${RESET}"
}

# ---------------- DASHBOARD ----------------

show_dashboard() {
    local total=0
    local courses=0

    if [[ -s "$DB" ]]; then
        total=$(wc -l < "$DB")
        courses=$(cut -d'|' -f4 "$DB" | sort -u | wc -l)
    fi

    echo -e "${BLUE}                  DASHBOARD${RESET}"
    echo "--------------------------------------------------"
    printf "  Total Students : %s\n" "$total"
    printf "  Total Courses  : %s\n" "$courses"
    echo "--------------------------------------------------"
}

# ---------------- VALIDATION ----------------

validate_id() {
    if [[ -z "$1" || ! "$1" =~ ^[0-9]+$ ]]; then
        show_error "Invalid Student ID! Use numbers only."
        return 1
    fi
    return 0
}

validate_age() {
    if [[ ! "$1" =~ ^[0-9]+$ ]] || (( 10#$1 < 16 || 10#$1 > 100 )); then
        show_error "Age must be between 16 and 100!"
        return 1
    fi
    return 0
}

validate_text() {
    if [[ -z "$1" || "$1" == *"|"* ]]; then
        show_error "Field cannot be empty or contain | character!"
        return 1
    fi
    return 0
}

student_exists() {
    grep -q "^$1|" "$DB"
}

# ---------------- ADD STUDENT ----------------

add_student() {
    echo ""
    echo -e "${CYAN}========== ADD NEW STUDENT ==========${RESET}"

    read -rp "Enter Student ID: " id
    if ! validate_id "$id"; then return; fi

    if student_exists "$id"; then
        show_error "Student ID already exists!"
        return
    fi

    read -rp "Enter Student Name: " name
    if ! validate_text "$name"; then return; fi

    read -rp "Enter Age: " age
    if ! validate_age "$age"; then return; fi

    read -rp "Enter Course: " course
    if ! validate_text "$course"; then return; fi

    echo "$id|$name|$age|$course" >> "$DB"
    show_message "Student added successfully!"
}

# ---------------- VIEW STUDENTS ----------------

view_students() {
    echo ""
    echo -e "${CYAN}================ STUDENT RECORDS ================${RESET}"

    if [[ ! -s "$DB" ]]; then
        show_error "No student records found!"
        return
    fi

    printf "${YELLOW}%-10s %-22s %-8s %-15s${RESET}\n" \
        "ID" "NAME" "AGE" "COURSE"

    echo "--------------------------------------------------"

    while IFS='|' read -r id name age course; do
        printf "%-10s %-22s %-8s %-15s\n" \
            "$id" "$name" "$age" "$course"
    done < "$DB"

    echo "--------------------------------------------------"
    echo "Total Records: $(wc -l < "$DB")"
}

# ---------------- SEARCH BY ID ----------------

search_student() {
    echo ""
    read -rp "Enter Student ID: " id

    if ! validate_id "$id"; then return; fi

    if student_exists "$id"; then
        show_message "Student Found!"
        grep "^$id|" "$DB" | tr '|' ' '
    else
        show_error "Student not found!"
    fi
}

# ---------------- SEARCH BY NAME ----------------

search_by_name() {
    echo ""
    read -rp "Enter Student Name: " name

    if ! validate_text "$name"; then return; fi

    local result
    result=$(awk -F'|' -v n="$name" '
        tolower($2) ~ tolower(n) {print}
    ' "$DB")

    if [[ -n "$result" ]]; then
        show_message "Matching Students:"
        echo "$result" | tr '|' ' '
    else
        show_error "No matching student found!"
    fi
}

# ---------------- UPDATE STUDENT ----------------

update_student() {
    echo ""
    read -rp "Enter Student ID to update: " id

    if ! validate_id "$id"; then return; fi

    if ! student_exists "$id"; then
        show_error "Student not found!"
        return
    fi

    read -rp "Enter New Name: " name
    if ! validate_text "$name"; then return; fi

    read -rp "Enter New Age: " age
    if ! validate_age "$age"; then return; fi

    read -rp "Enter New Course: " course
    if ! validate_text "$course"; then return; fi

    local temp_file
    temp_file=$(mktemp) || return

    if awk -F'|' -v id="$id" -v name="$name" \
        -v age="$age" -v course="$course" '
        BEGIN {OFS="|"}
        $1 == id {$2=name; $3=age; $4=course}
        {print}
    ' "$DB" > "$temp_file" && mv "$temp_file" "$DB"; then
        show_message "Student updated successfully!"
    else
        rm -f "$temp_file"
        show_error "Update failed!"
    fi
}

# ---------------- DELETE STUDENT ----------------

delete_student() {
    echo ""
    read -rp "Enter Student ID to delete: " id

    if ! validate_id "$id"; then return; fi

    if ! student_exists "$id"; then
        show_error "Student not found!"
        return
    fi

    read -rp "Are you sure? (y/n): " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        local temp_file
        temp_file=$(mktemp) || return

        if grep -v "^$id|" "$DB" > "$temp_file" &&
            mv "$temp_file" "$DB"; then
            show_message "Student deleted successfully!"
        else
            rm -f "$temp_file"
            show_error "Deletion failed!"
        fi
    else
        echo "Deletion cancelled."
    fi
}

# ---------------- SORT STUDENTS ----------------

sort_students() {
    echo ""

    if [[ ! -s "$DB" ]]; then
        show_error "No records to sort!"
        return
    fi

    local temp_file
    temp_file=$(mktemp) || return

    if sort -t'|' -k2,2f "$DB" > "$temp_file"; then
        mv "$temp_file" "$DB"
        show_message "Records sorted alphabetically!"
        view_students
    else
        rm -f "$temp_file"
        show_error "Sorting failed!"
    fi
}

# ---------------- STATISTICS ----------------

student_statistics() {
    echo ""
    echo -e "${CYAN}========== STUDENT STATISTICS ==========${RESET}"

    if [[ ! -s "$DB" ]]; then
        show_error "No records available!"
        return
    fi

    awk -F'|' '
        {
            total++
            sum += $3
            course[$4]++
        }
        END {
            printf "Total Students : %d\n", total
            printf "Average Age    : %.2f\n", sum/total

            print "\nCourse-wise Student Count:"
            for (c in course)
                printf "%-20s : %d\n", c, course[c]
        }
    ' "$DB"
}

# ---------------- COURSE FILTER ----------------

filter_course() {
    echo ""
    read -rp "Enter Course Name: " course

    if ! validate_text "$course"; then return; fi

    local result
    result=$(awk -F'|' -v c="$course" '
        tolower($4) == tolower(c) {print}
    ' "$DB")

    if [[ -n "$result" ]]; then
        show_message "Course Records:"
        echo "$result" | tr '|' ' '
    else
        show_error "No students found in this course!"
    fi
}

# ---------------- STUDENT PROFILE ----------------

student_report() {
    echo ""
    read -rp "Enter Student ID: " id

    if ! validate_id "$id"; then return; fi

    local record
    record=$(awk -F'|' -v id="$id" '$1 == id {print}' "$DB")

    if [[ -z "$record" ]]; then
        show_error "Student not found!"
        return
    fi

    IFS='|' read -r id name age course <<< "$record"

    echo ""
    echo -e "${CYAN}========== STUDENT PROFILE ==========${RESET}"
    echo "Student ID   : $id"
    echo "Student Name : $name"
    echo "Age          : $age"
    echo "Course       : $course"
    echo "====================================="
}

# ---------------- BACKUP ----------------

backup_database() {
    if [[ ! -s "$DB" ]]; then
        show_error "Database is empty. Nothing to backup!"
        return
    fi

    if cp "$DB" "$BACKUP"; then
        show_message "Database backup created successfully!"
    else
        show_error "Backup failed!"
    fi
}

# ---------------- RESTORE ----------------

restore_database() {
    if [[ ! -f "$BACKUP" ]]; then
        show_error "No backup file found!"
        return
    fi

    read -rp "Restore database from backup? (y/n): " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        if cp "$BACKUP" "$DB"; then
            show_message "Database restored successfully!"
        else
            show_error "Restore failed!"
        fi
    else
        echo "Restore cancelled."
    fi
}

# ---------------- MAIN MENU ----------------

while true
do
    clear

    show_header
    show_dashboard

    echo ""
    echo -e "${WHITE}                   MAIN MENU${RESET}"
    echo "=================================================="

    echo -e "${GREEN} 1.${RESET} Add New Student"
    echo -e "${GREEN} 2.${RESET} View All Students"
    echo -e "${GREEN} 3.${RESET} Search Student by ID"
    echo -e "${GREEN} 4.${RESET} Search Student by Name"
    echo -e "${GREEN} 5.${RESET} Update Student"
    echo -e "${GREEN} 6.${RESET} Delete Student"
    echo -e "${GREEN} 7.${RESET} Sort Students"
    echo -e "${GREEN} 8.${RESET} Student Statistics"
    echo -e "${GREEN} 9.${RESET} Backup Database"
    echo -e "${GREEN}10.${RESET} Restore Database"
    echo -e "${GREEN}11.${RESET} Filter by Course"
    echo -e "${GREEN}12.${RESET} Individual Student Report"
    echo -e "${RED}13. Exit${RESET}"

    echo "=================================================="

    read -rp " Enter your choice: " choice

    case "$choice" in
        1) add_student; pause_screen ;;
        2) view_students; pause_screen ;;
        3) search_student; pause_screen ;;
        4) search_by_name; pause_screen ;;
        5) update_student; pause_screen ;;
        6) delete_student; pause_screen ;;
        7) sort_students; pause_screen ;;
        8) student_statistics; pause_screen ;;
        9) backup_database; pause_screen ;;
        10) restore_database; pause_screen ;;
        11) filter_course; pause_screen ;;
        12) student_report; pause_screen ;;
        13)
            show_message "Thank you for using Student Hub!"
            exit 0
            ;;
        *)
            show_error "Invalid choice! Please select 1-13."
            pause_screen
            ;;
    esac
done
