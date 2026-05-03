CREATE DATABASE IF NOT EXISTS helpdesk;
USE helpdesk;

DROP TRIGGER IF EXISTS tickets_after_update;
DROP VIEW IF EXISTS open_ticket_summary;
DROP PROCEDURE IF EXISTS assign_ticket;
DROP FUNCTION IF EXISTS ticket_age_hours;

DROP TABLE IF EXISTS ticket_history;
DROP TABLE IF EXISTS ticket_comments;
DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS statuses;
DROP TABLE IF EXISTS priorities;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    role ENUM('requester', 'agent', 'admin') NOT NULL DEFAULT 'requester',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE priorities (
    priority_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    priority_name VARCHAR(20) NOT NULL UNIQUE,
    sort_order TINYINT UNSIGNED NOT NULL
);

CREATE TABLE statuses (
    status_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    status_name VARCHAR(30) NOT NULL UNIQUE,
    is_closed TINYINT(1) NOT NULL DEFAULT 0,
    sort_order TINYINT UNSIGNED NOT NULL
);

CREATE TABLE tickets (
    ticket_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    requester_id INT UNSIGNED NOT NULL,
    assignee_id INT UNSIGNED NULL,
    category_id INT UNSIGNED NOT NULL,
    priority_id INT UNSIGNED NOT NULL,
    status_id INT UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    resolved_at DATETIME NULL,
    CONSTRAINT fk_tickets_requester
        FOREIGN KEY (requester_id) REFERENCES users(user_id),
    CONSTRAINT fk_tickets_assignee
        FOREIGN KEY (assignee_id) REFERENCES users(user_id),
    CONSTRAINT fk_tickets_category
        FOREIGN KEY (category_id) REFERENCES categories(category_id),
    CONSTRAINT fk_tickets_priority
        FOREIGN KEY (priority_id) REFERENCES priorities(priority_id),
    CONSTRAINT fk_tickets_status
        FOREIGN KEY (status_id) REFERENCES statuses(status_id)
);

CREATE TABLE ticket_comments (
    comment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ticket_id INT UNSIGNED NOT NULL,
    author_id INT UNSIGNED NOT NULL,
    comment_text TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_comments_ticket
        FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id) ON DELETE CASCADE,
    CONSTRAINT fk_comments_author
        FOREIGN KEY (author_id) REFERENCES users(user_id)
);

CREATE TABLE ticket_history (
    history_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ticket_id INT UNSIGNED NOT NULL,
    old_status_id INT UNSIGNED NULL,
    new_status_id INT UNSIGNED NOT NULL,
    changed_by INT UNSIGNED NULL,
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note VARCHAR(255) NULL,
    CONSTRAINT fk_history_ticket
        FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id) ON DELETE CASCADE,
    CONSTRAINT fk_history_old_status
        FOREIGN KEY (old_status_id) REFERENCES statuses(status_id),
    CONSTRAINT fk_history_new_status
        FOREIGN KEY (new_status_id) REFERENCES statuses(status_id),
    CONSTRAINT fk_history_changed_by
        FOREIGN KEY (changed_by) REFERENCES users(user_id)
);

CREATE VIEW open_ticket_summary AS
SELECT
    t.ticket_id,
    t.title,
    t.created_at,
    t.updated_at,
    requester.name AS requester_name,
    COALESCE(assignee.name, 'Unassigned') AS assignee_name,
    c.category_name,
    p.priority_name,
    p.sort_order AS priority_sort_order,
    s.status_name
FROM tickets t
JOIN users requester ON requester.user_id = t.requester_id
LEFT JOIN users assignee ON assignee.user_id = t.assignee_id
JOIN categories c ON c.category_id = t.category_id
JOIN priorities p ON p.priority_id = t.priority_id
JOIN statuses s ON s.status_id = t.status_id
WHERE s.is_closed = 0 AND s.status_name <> 'Resolved';

DELIMITER //

CREATE FUNCTION ticket_age_hours(p_ticket_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_age_hours INT;

    SELECT TIMESTAMPDIFF(
        HOUR,
        created_at,
        COALESCE(resolved_at, CURRENT_TIMESTAMP)
    )
    INTO v_age_hours
    FROM tickets
    WHERE ticket_id = p_ticket_id;

    RETURN COALESCE(v_age_hours, 0);
END //

CREATE PROCEDURE assign_ticket(IN p_ticket_id INT, IN p_assignee_id INT)
BEGIN
    DECLARE v_new_status_id INT;
    DECLARE v_assigned_status_id INT;

    SELECT status_id
    INTO v_new_status_id
    FROM statuses
    WHERE status_name = 'New'
    LIMIT 1;

    SELECT status_id
    INTO v_assigned_status_id
    FROM statuses
    WHERE status_name = 'Assigned'
    LIMIT 1;

    UPDATE tickets
    SET
        assignee_id = p_assignee_id,
        status_id = CASE
            WHEN status_id = v_new_status_id THEN v_assigned_status_id
            ELSE status_id
        END
    WHERE ticket_id = p_ticket_id;
END //

CREATE TRIGGER tickets_after_update
AFTER UPDATE ON tickets
FOR EACH ROW
BEGIN
    IF NOT (OLD.status_id <=> NEW.status_id) THEN
        INSERT INTO ticket_history (
            ticket_id,
            old_status_id,
            new_status_id,
            changed_by,
            changed_at,
            note
        )
        VALUES (
            NEW.ticket_id,
            OLD.status_id,
            NEW.status_id,
            NULL,
            CURRENT_TIMESTAMP,
            'Ticket status updated'
        );
    END IF;
END //

DELIMITER ;
