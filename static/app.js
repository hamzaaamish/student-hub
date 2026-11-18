






/* ==========================================
   STUDENT HUB V2.2
   Frontend Application
   Bash Backend Integration
========================================== */

const $ = (selector) => document.querySelector(selector);

let students = [];
let editingId = null;
let currentPage = 1;
const PAGE_SIZE = 10;
let toastTimer;

/* API HELPER */

async function api(url, options = {}) {
    const res = await fetch(url, {
        headers: { "Content-Type": "application/json" },
        ...options
    });

    let data;

    try {
        data = await res.json();
    } catch {
        throw new Error("Invalid server response.");
    }

    if (!res.ok) {
        throw new Error(data.error || "Request failed.");
    }

    return data;
}

/* NOTIFICATIONS */

function toast(message) {
    const el = $("#toast");
    el.textContent = message;
    el.classList.add("show");

    clearTimeout(toastTimer);

    toastTimer = setTimeout(() => {
        el.classList.remove("show");
    }, 2800);
}

/* SECURITY AND HELPERS */

function escapeHtml(value) {
    return String(value).replace(/[&<>"']/g, char => ({
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#39;"
    })[char]);
}

function initials(name) {
    return String(name)
        .trim()
        .split(/\s+/)
        .map(part => part[0])
        .slice(0, 2)
        .join("")
        .toUpperCase();
}

function compareIds(a, b) {
    const x = String(a.id);
    const y = String(b.id);

    try {
        const nx = BigInt(x);
        const ny = BigInt(y);
        return nx < ny ? -1 : nx > ny ? 1 : 0;
    } catch {
        return x.localeCompare(y, undefined, { numeric: true });
    }
}

/* STUDENT TABLE */

function rowHtml(student) {
    const id = escapeHtml(student.id);

    return `
        <tr>
            <td>
                <div class="person">
                    <div class="person-avatar">
                        ${escapeHtml(initials(student.name))}
                    </div>
                    <strong>${escapeHtml(student.name)}</strong>
                </div>
            </td>
            <td>${id}</td>
            <td>${escapeHtml(student.age)}</td>
            <td>
                <span class="tag">${escapeHtml(student.course)}</span>
            </td>
            <td>
                <button class="action-btn" data-profile="${id}">View</button>
                <button class="action-btn" data-edit="${id}">Edit</button>
                <button class="action-btn" data-delete="${id}">Delete</button>
            </td>
        </tr>
    `;
}

/* DASHBOARD REFRESH */

async function refresh() {
    const [studentData, stats] = await Promise.all([
        api("/api/students"),
        api("/api/stats")
    ]);

    students = [...studentData.students].sort(compareIds);

    $("#totalStudents").textContent = stats.total;
    $("#totalCourses").textContent = stats.courses.length;
    $("#averageAge").textContent =
        Number(stats.average_age || 0).toFixed(1);

    $("#analyticsTotal").textContent = stats.total;
    $("#analyticsAverage").textContent =
        Number(stats.average_age || 0).toFixed(1);

    renderRecentStudents();
    renderCourseFilter(stats.courses);
    renderCourseBars(stats.courses);
    renderRows();

    loadIntegrity().catch(error => {
        console.warn("Integrity check unavailable:", error);
        $("#healthStatus").textContent = "Check Unavailable";
        $("#healthMessage").textContent = error.message;
        $("#healthDot").className = "health-status-dot unhealthy";
    }).finally(() => {
        loadActivity().catch(error => {
            console.warn("Activity history unavailable:", error);
            showActivityError(error);
        });
    });
}

/* DATABASE HEALTH - V2.1 */

function renderIntegrityReport(report) {
    $("#healthStatus").textContent = report.status;
    $("#healthChecked").textContent = report.checked;
    $("#healthIssueCount").textContent = report.issue_count;

    $("#healthDot").className =
        "health-status-dot " + (report.healthy ? "healthy" : "unhealthy");

    $("#healthMessage").textContent = report.healthy
        ? "All records passed validation"
        : "Database needs attention";

    const issues = $("#healthIssues");

    if (report.healthy) {
        issues.innerHTML = `
            <div class="health-success">
                ✓ Database integrity check passed. No data issues detected.
            </div>
        `;
        return;
    }

    issues.innerHTML = `
        <h4>Detected Issues</h4>
        ${report.issues.map(issue => `
            <div class="health-issue">
                <strong>Line ${escapeHtml(issue.line)}</strong>
                <span>${escapeHtml(issue.message)}</span>
            </div>
        `).join("")}
    `;
}

async function loadIntegrity() {
    const report = await api("/api/integrity");
    renderIntegrityReport(report);
    return report;
}

/* ACTIVITY HISTORY - V2.2 */

function activityOperationClass(operation) {
    const value = String(operation || "").toLowerCase();
    const allowed = ["add", "update", "delete", "backup", "restore", "integrity", "sort"];

    return allowed.includes(value)
        ? "activity-op-" + value
        : "activity-op-default";
}

function showActivityError(error) {
    const container = $("#activityList");
    if (!container) return;

    container.innerHTML = `
        <p class="empty">Could not load activity history: ${escapeHtml(error.message)}</p>
    `;
}

function renderActivity(report) {
    const container = $("#activityList");
    if (!container) return;

    const activities = Array.isArray(report.activities)
        ? report.activities
        : [];

    const total = $("#activityTotal");
    if (total) total.textContent = Number(report.total || 0);

    if (!activities.length) {
        container.innerHTML = `<p class="empty">No activity recorded yet.</p>`;
        return;
    }

    container.innerHTML = activities.map(item => {
        const operation = String(item.operation || "EVENT").toUpperCase();
        const status = String(item.status || "UNKNOWN").toUpperCase();
        const statusClass = status === "SUCCESS"
            ? "success"
            : status === "FAILED" ? "failed" : "warning";

        return `
            <article class="activity-item">
                <div class="activity-icon ${activityOperationClass(operation)}">
                    ${escapeHtml(operation.slice(0, 1))}
                </div>
                <div class="activity-main">
                    <div class="activity-title-row">
                        <strong>${escapeHtml(operation)}</strong>
                        <span class="activity-status ${statusClass}">
                            ${escapeHtml(status)}
                        </span>
                    </div>
                    <p>${escapeHtml(item.details || "Database operation")}</p>
                    <div class="activity-meta">
                        <span>Student ID: ${escapeHtml(item.record_id || "—")}</span>
                        <span>${escapeHtml(item.timestamp || "")}</span>
                    </div>
                </div>
            </article>
        `;
    }).join("");
}

async function loadActivity() {
    if (!$("#activityList")) return;

    const report = await api("/api/activity?limit=20");
    renderActivity(report);
    return report;
}

async function refreshActivity() {
    const button = $("#refreshActivityBtn");
    if (!button) return;

    button.disabled = true;
    button.textContent = "Loading...";

    try {
        await loadActivity();
    } catch (error) {
        showActivityError(error);
        toast("Activity history unavailable: " + error.message);
    } finally {
        button.disabled = false;
        button.textContent = "↻ Refresh";
    }
}

async function runIntegrityCheck() {
    const button = $("#runIntegrityBtn");
    button.disabled = true;
    button.textContent = "Checking...";

    try {
        const report = await loadIntegrity();
        await loadActivity().catch(error => {
            console.warn("Could not refresh activity history:", error);
        });

        toast(
            report.healthy
                ? "Database is healthy!"
                : `${report.issue_count} integrity issue(s) detected.`
        );

    } catch (error) {
        $("#healthStatus").textContent = "Check Failed";
        $("#healthMessage").textContent = error.message;
        $("#healthDot").className = "health-status-dot unhealthy";
        toast("Integrity check failed: " + error.message);

    } finally {
        button.disabled = false;
        button.textContent = "↻ Run Integrity Check";
    }
}

/* RECENT STUDENTS */

function renderRecentStudents() {
    const rows = students.slice(0, 5);

    $("#recentRows").innerHTML = rows.length
        ? rows.map(rowHtml).join("")
        : `
            <tr>
                <td colspan="5" class="empty">
                    No students yet. Add your first student.
                </td>
            </tr>
        `;
}

/* COURSE FILTER */

function renderCourseFilter(courses) {
    const filter = $("#courseFilter");
    const current = filter.value;

    filter.innerHTML = `
        <option value="">All courses</option>
        ${courses.map(course => `
            <option value="${escapeHtml(course.name)}">
                ${escapeHtml(course.name)}
            </option>
        `).join("")}
    `;

    if ([...filter.options].some(option => option.value === current)) {
        filter.value = current;
    }
}

/* COURSE ANALYTICS */

function renderCourseBars(courses) {
    const container = $("#courseBars");

    if (!courses.length) {
        container.innerHTML =
            `<p class="empty">No course data available.</p>`;
        return;
    }

    const max = Math.max(
        1,
        ...courses.map(course => Number(course.count))
    );

    container.innerHTML = courses.map(course => {
        const percentage = Number(course.count) / max * 100;

        return `
            <div class="bar-row">
                <span>${escapeHtml(course.name)}</span>
                <div class="bar-track">
                    <div class="bar-fill" style="width:${percentage}%"></div>
                </div>
                <b>${Number(course.count)}</b>
            </div>
        `;
    }).join("");
}

/* SEARCH, FILTER AND SORT */

function getFilteredStudents() {
    let rows = [...students];

    const query = $("#searchInput").value.trim().toLowerCase();
    const course = $("#courseFilter").value.toLowerCase();
    const sort = $("#sortFilter").value;

    if (query) {
        rows = rows.filter(student =>
            String(student.id).toLowerCase().includes(query) ||
            String(student.name).toLowerCase().includes(query)
        );
    }

    if (course) {
        rows = rows.filter(student =>
            String(student.course).toLowerCase() === course
        );
    }

    if (sort === "desc") {
        rows.sort((a, b) => compareIds(b, a));
    } else if (sort === "name") {
        rows.sort((a, b) =>
            String(a.name).localeCompare(
                String(b.name),
                undefined,
                { sensitivity: "base" }
            )
        );
    } else {
        rows.sort(compareIds);
    }

    return rows;
}

/* PAGINATION AND DIRECTORY */

function renderRows() {
    const rows = getFilteredStudents();

    const totalPages = Math.max(
        1,
        Math.ceil(rows.length / PAGE_SIZE)
    );

    currentPage = Math.min(currentPage, totalPages);

    const start = (currentPage - 1) * PAGE_SIZE;
    const pageRows = rows.slice(start, start + PAGE_SIZE);

    $("#studentRows").innerHTML = pageRows.length
        ? pageRows.map(rowHtml).join("")
        : `
            <tr>
                <td colspan="5" class="empty">
                    No matching students found.
                </td>
            </tr>
        `;

    $("#resultCount").textContent =
        `${rows.length} student${rows.length === 1 ? "" : "s"} found`;

    $("#pageInfo").textContent = rows.length
        ? `Showing ${start + 1}–${Math.min(start + PAGE_SIZE, rows.length)} of ${rows.length}`
        : "No students to display";

    $("#prevPage").disabled = currentPage <= 1;
    $("#nextPage").disabled = currentPage >= totalPages;

    $("#prevPage").style.opacity = currentPage <= 1 ? ".45" : "1";
    $("#nextPage").style.opacity = currentPage >= totalPages ? ".45" : "1";
}

/* VIEW NAVIGATION */

function showView(view) {
    const views = ["dashboard", "students", "analytics"];

    if (!views.includes(view)) return;

    views.forEach(name => {
        $("#" + name + "View").classList.toggle(
            "hidden",
            name !== view
        );
    });

    document.querySelectorAll(".nav[data-view]").forEach(button => {
        button.classList.toggle("active", button.dataset.view === view);
    });

    $("#pageTitle").textContent =
        view === "dashboard" ? "Overview" :
        view === "students" ? "Students" : "Analytics";

    $("#crumb").textContent = view.toUpperCase();

    closeSidebar();
}

/* STUDENT MODAL */

function openModal(student = null) {
    editingId = student ? String(student.id) : null;

    $("#modalTitle").textContent =
        student ? "Edit student" : "Add student";

    const form = $("#studentForm");

    const idInput = form.elements.namedItem("id");
    const nameInput = form.elements.namedItem("name");
    const ageInput = form.elements.namedItem("age");
    const courseInput = form.elements.namedItem("course");

    idInput.value = student?.id || "";
    idInput.readOnly = !!student;

    nameInput.value = student?.name || "";
    ageInput.value = student?.age || "";
    courseInput.value = student?.course || "";

    $("#studentModal").classList.remove("hidden");

    setTimeout(() => nameInput.focus(), 100);
}

function closeModal() {
    $("#studentModal").classList.add("hidden");
    $("#studentForm").reset();
    editingId = null;
}

/* STUDENT PROFILE */

function openProfile(student) {
    if (!student) return;

    $("#profileContent").innerHTML = `
        <div class="profile-content">
            <div class="person-avatar"
                 style="width:65px;height:65px;font-size:21px">
                ${escapeHtml(initials(student.name))}
            </div>

            <h2>${escapeHtml(student.name)}</h2>
            <p class="muted">Student ID: ${escapeHtml(student.id)}</p>

            <div class="profile-details">
                <div>
                    <small>STUDENT ID</small>
                    <strong>${escapeHtml(student.id)}</strong>
                </div>
                <div>
                    <small>AGE</small>
                    <strong>${escapeHtml(student.age)}</strong>
                </div>
                <div>
                    <small>COURSE</small>
                    <strong>${escapeHtml(student.course)}</strong>
                </div>
            </div>
        </div>
    `;

    $("#profileModal").classList.remove("hidden");
}

function closeProfile() {
    $("#profileModal").classList.add("hidden");
}

/* EDIT AND DELETE ACTIONS */

async function handleTableClick(event) {
    const edit = event.target.closest("[data-edit]");
    const del = event.target.closest("[data-delete]");
    const profile = event.target.closest("[data-profile]");

    if (edit) {
        const student = students.find(
            item => String(item.id) === edit.dataset.edit
        );

        if (student) openModal(student);
        return;
    }

    if (profile) {
        const student = students.find(
            item => String(item.id) === profile.dataset.profile
        );

        openProfile(student);
        return;
    }

    if (del) {
        const id = del.dataset.delete;

        if (!confirm(`Are you sure you want to delete student ${id}?`)) {
            return;
        }

        try {
            await api("/api/delete", {
                method: "POST",
                body: JSON.stringify({ id })
            });

            toast("Student deleted successfully.");
            await refresh();

        } catch (error) {
            toast(error.message);
        }
    }
}

/* CSV EXPORT */

function exportCSV() {
    if (!students.length) {
        toast("No student records available to export.");
        return;
    }

    const headers = ["Student ID", "Name", "Age", "Course"];

    const rows = students.map(student => [
        student.id,
        student.name,
        student.age,
        student.course
    ]);

    function csvCell(value) {
        let text = String(value ?? "");

        if (/^[=+\-@\t\r]/.test(text)) {
            text = "'" + text;
        }

        return '"' + text.replace(/"/g, '""') + '"';
    }

    const csv = [headers, ...rows]
        .map(row => row.map(csvCell).join(","))
        .join("\r\n");

    const blob = new Blob(
        ["\uFEFF" + csv],
        { type: "text/csv;charset=utf-8;" }
    );

    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");

    link.href = url;
    link.download = "student-hub-records.csv";

    document.body.appendChild(link);
    link.click();
    link.remove();

    setTimeout(() => URL.revokeObjectURL(url), 1000);

    toast("Student records exported successfully.");
}

/* LIGHT AND DARK THEME */

function applyTheme(theme) {
    const dark = theme === "dark";

    document.body.dataset.theme = dark ? "dark" : "light";
    $("#themeToggle").textContent = dark ? "☀" : "☾";

    document.querySelector('meta[name="theme-color"]')
        ?.setAttribute(
            "content",
            dark ? "#11131d" : "#f5f6fb"
        );

    try {
        localStorage.setItem("studentHubTheme", theme);
    } catch {
        // Theme remains usable for this session.
    }
}

function initializeTheme() {
    let savedTheme = "light";

    try {
        savedTheme = localStorage.getItem("studentHubTheme") || "light";
    } catch {
        savedTheme = "light";
    }

    applyTheme(savedTheme);
}

function toggleTheme() {
    const current = document.body.dataset.theme;
    applyTheme(current === "dark" ? "light" : "dark");
}

/* MOBILE SIDEBAR */

function openSidebar() {
    document.body.classList.add("sidebar-open");
}

function closeSidebar() {
    document.body.classList.remove("sidebar-open");
}

/* FORM SUBMISSION */

async function handleFormSubmit(event) {
    event.preventDefault();

    const form = event.currentTarget;

    const data = {
        id: form.elements.namedItem("id").value.trim(),
        name: form.elements.namedItem("name").value.trim(),
        age: form.elements.namedItem("age").value,
        course: form.elements.namedItem("course").value.trim()
    };

    try {
        const route = editingId ? "/api/update" : "/api/students";

        await api(route, {
            method: "POST",
            body: JSON.stringify(data)
        });

        const wasEditing = Boolean(editingId);

        closeModal();

        toast(
            wasEditing
                ? "Student updated successfully."
                : "Student added successfully."
        );

        await refresh();

    } catch (error) {
        toast(error.message);
    }
}

/* BACKUP */

async function createBackup() {
    try {
        const result = await api("/api/backup", {
            method: "POST",
            body: "{}"
        });

        toast(result.message || "Backup created successfully.");
        await loadActivity().catch(error => {
            console.warn("Could not refresh activity history:", error);
        });

    } catch (error) {
        toast(error.message);
    }
}

/* RESTORE */

async function restoreBackup() {
    if (!confirm(
        "Restore the last backup? Current student data will be replaced."
    )) {
        return;
    }

    try {
        const result = await api("/api/restore", {
            method: "POST",
            body: "{}"
        });

        toast(result.message || "Database restored successfully.");

        currentPage = 1;
        await refresh();

    } catch (error) {
        toast(error.message);
    }
}

/* CLEAR FILTERS */

function clearFilters() {
    $("#searchInput").value = "";
    $("#courseFilter").value = "";
    $("#sortFilter").value = "asc";

    currentPage = 1;
    renderRows();
}

/* EVENT LISTENERS */

document.querySelectorAll(".nav[data-view]").forEach(button => {
    button.addEventListener("click", () => {
        showView(button.dataset.view);
    });
});

$("#addBtn").addEventListener("click", () => openModal());
$("#addFromDash").addEventListener("click", () => openModal());

$("#viewAllStudents").addEventListener("click", () => {
    showView("students");
});

$("#closeModal").addEventListener("click", closeModal);
$("#cancelModal").addEventListener("click", closeModal);
$("#closeProfile").addEventListener("click", closeProfile);

$("#studentModal").addEventListener("click", event => {
    if (event.target.id === "studentModal") closeModal();
});

$("#profileModal").addEventListener("click", event => {
    if (event.target.id === "profileModal") closeProfile();
});

$("#studentRows").addEventListener("click", handleTableClick);
$("#recentRows").addEventListener("click", handleTableClick);

$("#studentForm").addEventListener("submit", handleFormSubmit);

$("#searchInput").addEventListener("input", () => {
    currentPage = 1;
    renderRows();
});

$("#courseFilter").addEventListener("change", () => {
    currentPage = 1;
    renderRows();
});

$("#sortFilter").addEventListener("change", () => {
    currentPage = 1;
    renderRows();
});

$("#clearSearch").addEventListener("click", clearFilters);

$("#prevPage").addEventListener("click", () => {
    if (currentPage > 1) {
        currentPage--;
        renderRows();
    }
});

$("#nextPage").addEventListener("click", () => {
    const totalPages = Math.ceil(
        getFilteredStudents().length / PAGE_SIZE
    );

    if (currentPage < totalPages) {
        currentPage++;
        renderRows();
    }
});

$("#backupBtn").addEventListener("click", createBackup);
$("#restoreBtn").addEventListener("click", restoreBackup);
$("#exportBtn").addEventListener("click", exportCSV);

$("#runIntegrityBtn").addEventListener(
    "click",
    runIntegrityCheck
);

const refreshActivityButton = $("#refreshActivityBtn");
if (refreshActivityButton) {
    refreshActivityButton.addEventListener("click", refreshActivity);
}

$("#themeToggle").addEventListener("click", toggleTheme);

$("#menuToggle").addEventListener("click", openSidebar);
$("#sidebarClose").addEventListener("click", closeSidebar);
$("#sidebarOverlay").addEventListener("click", closeSidebar);

document.addEventListener("keydown", event => {
    if (event.key === "Escape") {
        closeModal();
        closeProfile();
        closeSidebar();
    }
});

/* APPLICATION INITIALIZATION */

async function initializeApp() {
    initializeTheme();

    try {
        await refresh();
    } catch (error) {
        toast("Could not connect to local Bash server: " + error.message);
        console.error(error);
    }
}

initializeApp();





