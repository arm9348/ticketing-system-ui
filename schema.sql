CREATE DATABASE IF NOT EXISTS helpdesk;
USE helpdesk;

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
