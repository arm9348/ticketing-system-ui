USE helpdesk;

INSERT INTO categories (category_name) VALUES
('Infrastructure'),
('Cloud Infrastructure'),
('Networking'),
('DevOps'),
('Security'),
('IT Support');

INSERT INTO priorities (priority_name, sort_order) VALUES
('Low', 1),
('Medium', 2),
('High', 3),
('Urgent', 4);

INSERT INTO statuses (status_name, is_closed, sort_order) VALUES
('New', 0, 1),
('Assigned', 0, 2),
('In Progress', 0, 3),
('Waiting', 0, 4),
('Resolved', 0, 5),
('Closed', 1, 6);

INSERT INTO users (name, email, role) VALUES
('Riley Requester', 'riley.requester@example.com', 'requester'),
('Avery Agent', 'avery.agent@example.com', 'agent'),
('Morgan Admin', 'morgan.admin@example.com', 'admin');

INSERT INTO tickets (
    title,
    description,
    requester_id,
    assignee_id,
    category_id,
    priority_id,
    status_id,
    created_at,
    updated_at,
    resolved_at
) VALUES
(
    'VPN access is intermittent',
    'User reports the corporate VPN disconnects every 10 minutes during remote work.',
    1,
    2,
    3,
    3,
    3,
    DATE_SUB(NOW(), INTERVAL 2 DAY),
    DATE_SUB(NOW(), INTERVAL 3 HOUR),
    NULL
),
(
    'Server patching completed',
    'Monthly security updates were applied to the shared application server.',
    3,
    2,
    1,
    2,
    5,
    DATE_SUB(NOW(), INTERVAL 5 DAY),
    DATE_SUB(NOW(), INTERVAL 1 DAY),
    DATE_SUB(NOW(), INTERVAL 1 DAY)
),
(
    'Laptop setup for new employee',
    'Prepare laptop, email account, and collaboration tools for the new hire starting Monday.',
    1,
    NULL,
    6,
    2,
    1,
    DATE_SUB(NOW(), INTERVAL 8 HOUR),
    DATE_SUB(NOW(), INTERVAL 8 HOUR),
    NULL
);

INSERT INTO ticket_comments (ticket_id, author_id, comment_text, created_at) VALUES
(
    1,
    2,
    'Checked VPN gateway logs and noticed repeated session resets. Investigating firewall timeouts.',
    DATE_SUB(NOW(), INTERVAL 1 DAY)
),
(
    1,
    1,
    'Issue still happening this morning from home Wi-Fi and mobile hotspot.',
    DATE_SUB(NOW(), INTERVAL 12 HOUR)
),
(
    2,
    3,
    'Patch cycle verified and server health checks passed after restart.',
    DATE_SUB(NOW(), INTERVAL 1 DAY)
);

INSERT INTO ticket_history (
    ticket_id,
    old_status_id,
    new_status_id,
    changed_by,
    changed_at,
    note
) VALUES
(1, NULL, 1, 1, DATE_SUB(NOW(), INTERVAL 2 DAY), 'Ticket submitted'),
(1, 1, 2, 3, DATE_SUB(NOW(), INTERVAL 44 HOUR), 'Assigned to Avery Agent'),
(1, 2, 3, 2, DATE_SUB(NOW(), INTERVAL 30 HOUR), 'Investigation started'),
(2, NULL, 1, 3, DATE_SUB(NOW(), INTERVAL 5 DAY), 'Maintenance ticket created'),
(2, 1, 2, 3, DATE_SUB(NOW(), INTERVAL 116 HOUR), 'Assigned for patch review'),
(2, 2, 3, 2, DATE_SUB(NOW(), INTERVAL 100 HOUR), 'Work started'),
(2, 3, 5, 2, DATE_SUB(NOW(), INTERVAL 1 DAY), 'Resolved after patch verification'),
(3, NULL, 1, 1, DATE_SUB(NOW(), INTERVAL 8 HOUR), 'New employee onboarding request created');
