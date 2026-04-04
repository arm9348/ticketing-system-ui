from db import execute_query, fetch_all, fetch_one


def _to_int(value):
    if value in (None, "", "None"):
        return None
    return int(value)


def get_ticket_form_options():
    return {
        "requesters": fetch_all(
            """
            SELECT user_id, name, email
            FROM users
            WHERE role IN ('requester', 'admin')
            ORDER BY name
            """
        ),
        "agents": fetch_all(
            """
            SELECT user_id, name, email
            FROM users
            WHERE role IN ('agent', 'admin')
            ORDER BY name
            """
        ),
        "categories": fetch_all(
            "SELECT category_id, category_name FROM categories ORDER BY category_name"
        ),
        "priorities": fetch_all(
            """
            SELECT priority_id, priority_name, sort_order
            FROM priorities
            ORDER BY sort_order, priority_name
            """
        ),
        "statuses": fetch_all(
            """
            SELECT status_id, status_name, is_closed, sort_order
            FROM statuses
            ORDER BY sort_order, status_name
            """
        ),
        "comment_authors": fetch_all(
            "SELECT user_id, name, role FROM users ORDER BY name"
        ),
    }


def get_filter_options():
    return {
        "statuses": fetch_all(
            "SELECT status_id, status_name FROM statuses ORDER BY sort_order, status_name"
        ),
        "categories": fetch_all(
            "SELECT category_id, category_name FROM categories ORDER BY category_name"
        ),
        "assignees": fetch_all(
            """
            SELECT user_id, name
            FROM users
            WHERE role IN ('agent', 'admin')
            ORDER BY name
            """
        ),
    }


def list_tickets(filters=None):
    filters = filters or {}
    query = """
        SELECT
            t.ticket_id,
            t.title,
            t.created_at,
            t.updated_at,
            t.resolved_at,
            requester.name AS requester_name,
            COALESCE(assignee.name, 'Unassigned') AS assignee_name,
            c.category_name,
            p.priority_name,
            p.sort_order AS priority_sort_order,
            s.status_name,
            s.sort_order AS status_sort_order
        FROM tickets t
        JOIN users requester ON requester.user_id = t.requester_id
        LEFT JOIN users assignee ON assignee.user_id = t.assignee_id
        JOIN categories c ON c.category_id = t.category_id
        JOIN priorities p ON p.priority_id = t.priority_id
        JOIN statuses s ON s.status_id = t.status_id
        WHERE 1 = 1
    """
    params = []

    if filters.get("status_id"):
        query += " AND t.status_id = ?"
        params.append(filters["status_id"])
    if filters.get("category_id"):
        query += " AND t.category_id = ?"
        params.append(filters["category_id"])
    if filters.get("assignee_id"):
        query += " AND t.assignee_id = ?"
        params.append(filters["assignee_id"])

    query += """
        ORDER BY
            s.sort_order,
            p.sort_order DESC,
            t.created_at DESC
    """
    return fetch_all(query, params)


def get_ticket(ticket_id):
    return fetch_one(
        """
        SELECT
            t.ticket_id,
            t.title,
            t.description,
            t.requester_id,
            t.assignee_id,
            t.category_id,
            t.priority_id,
            t.status_id,
            t.created_at,
            t.updated_at,
            t.resolved_at,
            requester.name AS requester_name,
            requester.email AS requester_email,
            COALESCE(assignee.name, 'Unassigned') AS assignee_name,
            c.category_name,
            p.priority_name,
            s.status_name
        FROM tickets t
        JOIN users requester ON requester.user_id = t.requester_id
        LEFT JOIN users assignee ON assignee.user_id = t.assignee_id
        JOIN categories c ON c.category_id = t.category_id
        JOIN priorities p ON p.priority_id = t.priority_id
        JOIN statuses s ON s.status_id = t.status_id
        WHERE t.ticket_id = ?
        """,
        (ticket_id,),
    )


def get_ticket_comments(ticket_id):
    return fetch_all(
        """
        SELECT
            tc.comment_id,
            tc.comment_text,
            tc.created_at,
            u.name AS author_name,
            u.role AS author_role
        FROM ticket_comments tc
        JOIN users u ON u.user_id = tc.author_id
        WHERE tc.ticket_id = ?
        ORDER BY tc.created_at ASC, tc.comment_id ASC
        """,
        (ticket_id,),
    )


def _validate_ticket_form(data):
    errors = []
    required_fields = {
        "title": "Title",
        "description": "Description",
        "requester_id": "Requester",
        "category_id": "Category",
        "priority_id": "Priority",
        "status_id": "Status",
    }

    for field, label in required_fields.items():
        if not str(data.get(field, "")).strip():
            errors.append(f"{label} is required.")

    if str(data.get("title", "")).strip() and len(data["title"].strip()) > 150:
        errors.append("Title must be 150 characters or fewer.")

    return errors


def _status_should_set_resolved(status_id):
    status = fetch_one(
        "SELECT status_name, is_closed FROM statuses WHERE status_id = ?",
        (status_id,),
    )
    if not status:
        return 0
    if status["status_name"] == "Resolved" or status["is_closed"]:
        return 1
    return 0


def create_ticket(data):
    errors = _validate_ticket_form(data)
    if errors:
        return errors, None

    should_set_resolved = _status_should_set_resolved(_to_int(data["status_id"]))
    query = """
        INSERT INTO tickets (
            title,
            description,
            requester_id,
            assignee_id,
            category_id,
            priority_id,
            status_id,
            resolved_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, CASE WHEN ? = 1 THEN CURRENT_TIMESTAMP ELSE NULL END)
    """
    ticket_id = execute_query(
        query,
        (
            data["title"].strip(),
            data["description"].strip(),
            _to_int(data["requester_id"]),
            _to_int(data.get("assignee_id")),
            _to_int(data["category_id"]),
            _to_int(data["priority_id"]),
            _to_int(data["status_id"]),
            should_set_resolved,
        ),
    )
    return [], ticket_id


def update_ticket(ticket_id, data):
    errors = _validate_ticket_form(data)
    if errors:
        return errors

    should_set_resolved = _status_should_set_resolved(_to_int(data["status_id"]))
    query = """
        UPDATE tickets
        SET
            title = ?,
            description = ?,
            requester_id = ?,
            assignee_id = ?,
            category_id = ?,
            priority_id = ?,
            status_id = ?,
            resolved_at = CASE
                WHEN ? = 1 AND resolved_at IS NULL THEN CURRENT_TIMESTAMP
                WHEN ? = 1 THEN resolved_at
                ELSE NULL
            END
        WHERE ticket_id = ?
    """
    execute_query(
        query,
        (
            data["title"].strip(),
            data["description"].strip(),
            _to_int(data["requester_id"]),
            _to_int(data.get("assignee_id")),
            _to_int(data["category_id"]),
            _to_int(data["priority_id"]),
            _to_int(data["status_id"]),
            should_set_resolved,
            should_set_resolved,
            ticket_id,
        ),
    )
    return []


def delete_ticket(ticket_id):
    execute_query("DELETE FROM tickets WHERE ticket_id = ?", (ticket_id,))


def add_ticket_comment(ticket_id, data):
    errors = []
    if not str(data.get("author_id", "")).strip():
        errors.append("Comment author is required.")
    if not str(data.get("comment_text", "")).strip():
        errors.append("Comment text is required.")

    if errors:
        return errors

    execute_query(
        """
        INSERT INTO ticket_comments (ticket_id, author_id, comment_text)
        VALUES (?, ?, ?)
        """,
        (
            ticket_id,
            _to_int(data["author_id"]),
            data["comment_text"].strip(),
        ),
    )
    return []


def get_report_data():
    tickets_by_category_status = fetch_all(
        """
        SELECT
            c.category_name,
            s.status_name,
            COUNT(*) AS ticket_count
        FROM tickets t
        JOIN categories c ON c.category_id = t.category_id
        JOIN statuses s ON s.status_id = t.status_id
        GROUP BY c.category_name, s.status_name, c.category_id, s.sort_order
        ORDER BY c.category_name, s.sort_order, s.status_name
        """
    )

    open_backlog_by_assignee = fetch_all(
        """
        SELECT
            COALESCE(u.name, 'Unassigned') AS assignee_name,
            COUNT(*) AS open_ticket_count
        FROM tickets t
        LEFT JOIN users u ON u.user_id = t.assignee_id
        JOIN statuses s ON s.status_id = t.status_id
        WHERE s.is_closed = 0 AND s.status_name <> 'Resolved'
        GROUP BY COALESCE(u.name, 'Unassigned')
        ORDER BY open_ticket_count DESC, assignee_name
        """
    )

    average_resolution = fetch_one(
        """
        SELECT
            ROUND(AVG(TIMESTAMPDIFF(MINUTE, created_at, resolved_at)) / 60, 2)
                AS average_resolution_hours
        FROM tickets
        WHERE resolved_at IS NOT NULL
        """
    )

    return {
        "tickets_by_category_status": tickets_by_category_status,
        "open_backlog_by_assignee": open_backlog_by_assignee,
        "average_resolution_hours": average_resolution["average_resolution_hours"]
        if average_resolution
        else None,
    }
