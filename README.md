# Ticketing System

Simple Flask + MariaDB helpdesk project for creating, updating, filtering, and reporting on support tickets.

## Run the project

1. Create the database objects:
```bash
mysql -u root -p < schema.sql
```

2. Load the sample data:
```bash
mysql -u root -p helpdesk < seed.sql
```

3. Install Python dependencies:
```bash
pip install -r requirements.txt
```

4. Configure `.env` with your MariaDB connection values.

5. Start the app:
```bash
python app.py
```

Then open `http://127.0.0.1:5000`.

## Database objects added for the final project

- `ticket_history` table: stores ticket status changes, who changed them, when they changed, and an optional note.
- `open_ticket_summary` view: shows only open tickets and joins tickets with users, categories, priorities, and statuses.
- `ticket_age_hours(p_ticket_id INT)` function: returns the age of a ticket in hours from `created_at` to `resolved_at` or the current time.
- `assign_ticket(p_ticket_id INT, p_assignee_id INT)` procedure: assigns a ticket and automatically changes `New` tickets to `Assigned`.
- `tickets_after_update` trigger: automatically inserts a row into `ticket_history` whenever a ticket status changes.

## App updates

- Ticket detail pages now show a ticket history section.
- Reports now include an open-ticket summary section powered by the database view.
- Existing ticket CRUD, comments, filters, and reports still use parameterized SQL queries.

## How this fits the rubric

This project now includes 7 tables, a view, a stored function, a stored procedure, and a trigger, while still demonstrating a working Flask front end with CRUD operations and database-driven reporting.
