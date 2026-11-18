
#!/bin/bash

DB="students.txt"

touch "$DB"

# Function 1: Add Student
add_student() {
    echo "Enter Student ID:"
    read id

    if grep -q "^$id|" "$DB"; then
        echo "Student already exists!"
        return
    fi

    echo "Enter Student Name:"
    read name

    echo "Enter Age:"
    read age

    echo "Enter Course:"
    read course

    echo "$id|$name|$age|$course" >> "$DB"

    echo "Student added successfully!"
}

# Function 2: View Students
view_students() {
    if [ ! -s "$DB" ]; then
        echo "No records found!"
        return
    fi

    echo "ID | NAME | AGE | COURSE"

    while IFS='|' read -r id name age course
    do
        echo "$id | $name | $age | $course"
    done < "$DB"
}

# Function 3: Search Student
search_student() {
    echo "Enter Student ID:"
    read id

    if grep -q "^$id|" "$DB"; then
        grep "^$id|" "$DB" | tr '|' ' '
    else
        echo "Student not found!"
    fi
}

# Function 4: Update Student
update_student() {
    echo "Enter Student ID:"
    read id

    if ! grep -q "^$id|" "$DB"; then
        echo "Student not found!"
        return
    fi

    echo "Enter New Name:"
    read name

    echo "Enter New Age:"
    read age

    echo "Enter New Course:"
    read course

    grep -v "^$id|" "$DB" > temp.txt
    echo "$id|$name|$age|$course" >> temp.txt

    mv temp.txt "$DB"

    echo "Student updated successfully!"
}

# Function 5: Delete Student
delete_student() {
    echo "Enter Student ID:"
    read id

    if ! grep -q "^$id|" "$DB"; then
        echo "Student not found!"
        return
    fi

    grep -v "^$id|" "$DB" > temp.txt
    mv temp.txt "$DB"

    echo "Student deleted successfully!"
}

# Main Menu
while true
do
    echo ""
    echo "===== STUDENT DATABASE ====="
    echo "1. Add Student"
    echo "2. View Students"
    echo "3. Search Student"
    echo "4. Update Student"
    echo "5. Delete Student"
    echo "6. Exit"

    echo "Enter your choice:"
    read choice

    case $choice in
        1) add_student ;;
        2) view_students ;;
        3) search_student ;;
        4) update_student ;;
        5) delete_student ;;
        6) echo "Exiting..."; exit ;;
        *) echo "Invalid choice!" ;;
    esac
done
