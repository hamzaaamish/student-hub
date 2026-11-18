
#!/usr/bin/env bash
# Student Hub v2.2 - Bash Database Engine + Audit Trail

DB="${DB_FILE:-students.txt}"
BACKUP="${BACKUP_FILE:-students_backup.txt}"
ACTIVITY_LOG="${ACTIVITY_LOG_FILE:-activity.log}"

PRE_RESTORE="${DB}.pre_restore"
ACTION="${1:-}"
LOG_ID="-"

# ---------------- LOGGING ----------------

safe_field() {
    printf '%s' "${1:-}" | tr '|\r\n' ' / '
}

log_activity() {
    local operation="$1"
    local record_id="${2:--}"
    local details="${3:-}"
    local status="${4:-SUCCESS}"

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    operation=$(safe_field "$operation")
    record_id=$(safe_field "$record_id")
    details=$(safe_field "$details")
    status=$(safe_field "$status")

    # Logging must never interrupt database operations.
    printf '%s|%s|%s|%s|%s\n' \
        "$timestamp" "$operation" "$record_id" \
        "$details" "$status" >> "$ACTIVITY_LOG" 2>/dev/null || true
}

emit_error() {
    log_activity "$ACTION" "$LOG_ID" "$1" "FAILED"
    printf 'ERROR|%s\n' "$1"
    exit 1
}

# ---------------- VALIDATION ----------------

valid_id() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

valid_age() {
    [[ "$1" =~ ^[0-9]{1,3}$ ]] &&
    (( 10#$1 >= 16 && 10#$1 <= 100 ))
}

valid_text() {
    [[ -n "$1" && "$1" != *"|"* && "$1" != *$'\n'* ]]
}

exists() {
    awk -F'|' -v id="$1" \
        '$1 == id {found=1} END {exit !found}' "$DB"
}

atomic_replace() {
    local source="$1"
    local target="$2"
    local tmp="${target}.tmp.$$"

    if ! cp "$source" "$tmp"; then
        rm -f "$tmp"
        return 1
    fi

    if ! mv "$tmp" "$target"; then
        rm -f "$tmp"
        return 1
    fi
}

touch "$DB" || emit_error "Cannot access database file."

# ---------------- MAIN OPERATIONS ----------------

case "$ACTION" in

    # LIST STUDENTS
    list)
        sort -t'|' -k1,1n "$DB" |
        while IFS='|' read -r id name age course; do
            [[ -n "$id" ]] &&
            printf '%s|%s|%s|%s\n' "$id" "$name" "$age" "$course"
        done
        ;;

    # ADD STUDENT
    add)
        id="${2:-}"
        name="${3:-}"
        age="${4:-}"
        course="${5:-}"
        LOG_ID="$id"

        valid_id "$id" || emit_error "Student ID must contain numbers only."
        valid_text "$name" || emit_error "Name cannot be empty or contain |."
        valid_age "$age" || emit_error "Age must be between 16 and 100."
        valid_text "$course" || emit_error "Course cannot be empty or contain |."

        exists "$id" && emit_error "Student ID already exists."

        printf '%s|%s|%s|%s\n' "$id" "$name" "$age" "$course" >> "$DB" ||
            emit_error "Could not write to database."

        log_activity "ADD" "$id" "Student record added" "SUCCESS"
        printf 'OK|Student added successfully.\n'
        ;;

    # UPDATE STUDENT
    update)
        id="${2:-}"
        name="${3:-}"
        age="${4:-}"
        course="${5:-}"
        LOG_ID="$id"

        valid_id "$id" || emit_error "Invalid student ID."
        exists "$id" || emit_error "Student not found."
        valid_text "$name" || emit_error "Name cannot be empty or contain |."
        valid_age "$age" || emit_error "Age must be between 16 and 100."
        valid_text "$course" || emit_error "Course cannot be empty or contain |."

        tmp="${DB}.tmp.$$"

        awk -F'|' -v OFS='|' \
            -v id="$id" -v n="$name" -v a="$age" -v c="$course" \
            '$1 == id {$2=n; $3=a; $4=c} {print}' "$DB" > "$tmp" ||
            {
                rm -f "$tmp"
                emit_error "Could not update database."
            }

        mv "$tmp" "$DB" || {
            rm -f "$tmp"
            emit_error "Could not save updated database."
        }

        log_activity "UPDATE" "$id" "Student record updated" "SUCCESS"
        printf 'OK|Student updated successfully.\n'
        ;;

    # DELETE STUDENT
    delete)
        id="${2:-}"
        LOG_ID="$id"

        valid_id "$id" || emit_error "Invalid student ID."
        exists "$id" || emit_error "Student not found."

        tmp="${DB}.tmp.$$"

        awk -F'|' -v id="$id" '$1 != id' "$DB" > "$tmp" ||
            {
                rm -f "$tmp"
                emit_error "Could not delete student."
            }

        mv "$tmp" "$DB" || {
            rm -f "$tmp"
            emit_error "Could not save database."
        }

        log_activity "DELETE" "$id" "Student record deleted" "SUCCESS"
        printf 'OK|Student deleted successfully.\n'
        ;;

    # SEARCH BY ID
    search_id)
        id="${2:-}"
        LOG_ID="$id"

        valid_id "$id" || emit_error "Invalid student ID."

        awk -F'|' -v id="$id" \
            '$1 == id {print; found=1} END {if (!found) exit 2}' "$DB" ||
            emit_error "Student not found."
        ;;

    # SEARCH BY NAME
    search_name)
        query="${2:-}"

        [[ -n "$query" ]] || emit_error "Enter a name to search."

        awk -F'|' -v q="$query" \
            'tolower($2) ~ tolower(q) {print}' "$DB"
        ;;

    # PERMANENT SORT
    sort)
        tmp="${DB}.tmp.$$"

        sort -t'|' -k1,1n "$DB" > "$tmp" ||
            {
                rm -f "$tmp"
                emit_error "Could not sort database."
            }

        mv "$tmp" "$DB" ||
            emit_error "Could not save sorted database."

        log_activity "SORT" "-" "Records sorted by Student ID" "SUCCESS"
        printf 'OK|Records sorted by Student ID.\n'
        ;;

    # STATISTICS
    stats)
        awk -F'|' '
            NF == 4 {
                total++
                sum += $3
                courses[$4]++
            }
            END {
                printf "TOTAL|%d\n", total

                if (total)
                    printf "AVERAGE|%.2f\n", sum/total

                for (c in courses)
                    printf "COURSE|%s|%d\n", c, courses[c]
            }
        ' "$DB"
        ;;

    # FILTER BY COURSE
    filter_course)
        course="${2:-}"

        [[ -n "$course" ]] || emit_error "Enter a course name."

        awk -F'|' -v c="$course" \
            'tolower($4) == tolower(c) {print}' "$DB"
        ;;

    # STUDENT PROFILE
    profile)
        id="${2:-}"
        LOG_ID="$id"

        valid_id "$id" || emit_error "Invalid student ID."

        awk -F'|' -v id="$id" \
            '$1 == id {print; found=1} END {if (!found) exit 2}' "$DB" ||
            emit_error "Student not found."
        ;;

    # DATABASE INTEGRITY CHECK
    integrity)
        integrity_output=$(awk -F'|' '
            {
                checked++
                issues = 0

                if (NF != 4) {
                    printf "ISSUE|%d|Record must contain exactly 4 fields\n", NR
                    issues++
                }

                if ($1 == "" || $1 !~ /^[0-9]+$/) {
                    printf "ISSUE|%d|Invalid or missing Student ID\n", NR
                    issues++
                }

                if ($1 != "" && seen[$1]++) {
                    printf "ISSUE|%d|Duplicate Student ID: %s\n", NR, $1
                    issues++
                }

                if ($2 == "") {
                    printf "ISSUE|%d|Student name is missing\n", NR
                    issues++
                }

                if ($3 !~ /^[0-9]+$/ || $3+0 < 16 || $3+0 > 100) {
                    printf "ISSUE|%d|Invalid age: %s\n", NR, $3
                    issues++
                }

                if ($4 == "") {
                    printf "ISSUE|%d|Course is missing\n", NR
                    issues++
                }

                total_issues += issues
            }

            END {
                if (total_issues == 0)
                    print "OK|Database integrity check passed."

                printf "SUMMARY|%d|%d\n", checked, total_issues
            }
        ' "$DB") || emit_error "Integrity check could not run."

        printf '%s\n' "$integrity_output"

        checked=$(printf '%s\n' "$integrity_output" |
            awk -F'|' '$1=="SUMMARY" {print $2}')

        issue_count=$(printf '%s\n' "$integrity_output" |
            awk -F'|' '$1=="SUMMARY" {print $3}')

        if [[ "${issue_count:-0}" =~ ^[0-9]+$ ]] &&
           (( issue_count == 0 )); then
            log_activity "INTEGRITY" "-" \
                "Checked ${checked:-0} records; no issues found" "SUCCESS"
        else
            log_activity "INTEGRITY" "-" \
                "Checked ${checked:-0} records; ${issue_count:-unknown} issues found" "WARNING"
        fi
        ;;

    # CREATE BACKUP
    backup)
        [[ -s "$DB" ]] || emit_error "Database is empty; nothing to back up."

        cp "$DB" "$BACKUP" ||
            emit_error "Backup creation failed."

        log_activity "BACKUP" "-" "Database backup created" "SUCCESS"
        printf 'OK|Backup created successfully.\n'
        ;;

    # SAFE RESTORE
    restore)
        [[ -f "$BACKUP" ]] || emit_error "No backup file exists."

        if [[ -f "$DB" ]]; then
            cp "$DB" "$PRE_RESTORE" ||
                emit_error "Could not create pre-restore backup."
        fi

        atomic_replace "$BACKUP" "$DB" ||
            emit_error "Restore failed. Check the database and backup files."

        log_activity "RESTORE" "-" \
            "Database restored; previous database preserved" "SUCCESS"

        printf 'OK|Database restored successfully. Previous database saved as %s.\n' "$PRE_RESTORE"
        ;;

    # VIEW ACTIVITY LOG
    activity)
        limit="${2:-20}"

        [[ "$limit" =~ ^[0-9]+$ ]] ||
            emit_error "Activity limit must be a positive number."

        (( limit >= 1 && limit <= 500 )) ||
            emit_error "Activity limit must be between 1 and 500."

        if [[ ! -f "$ACTIVITY_LOG" ]]; then
            printf 'EMPTY|No activity recorded yet.\n'
        else
            tail -n "$limit" "$ACTIVITY_LOG"
        fi
        ;;

    # UNKNOWN ACTION
    *)
        emit_error "Unknown action."
        ;;

esac
