TYPE=TRIGGERS
triggers='CREATE DEFINER=`helpdesk_user`@`127.0.0.1` TRIGGER tickets_after_update\nAFTER UPDATE ON tickets\nFOR EACH ROW\nBEGIN\n    IF NOT (OLD.status_id <=> NEW.status_id) THEN\n        INSERT INTO ticket_history (\n            ticket_id,\n            old_status_id,\n            new_status_id,\n            changed_by,\n            changed_at,\n            note\n        )\n        VALUES (\n            NEW.ticket_id,\n            OLD.status_id,\n            NEW.status_id,\n            NULL,\n            CURRENT_TIMESTAMP,\n            \'Ticket status updated\'\n        );\n    END IF;\nEND'
sql_modes=1411383296
definers='helpdesk_user@127.0.0.1'
client_cs_names='utf8mb4'
connection_cl_names='utf8mb4_uca1400_ai_ci'
db_cl_names='utf8mb4_general_ci'
created=1777237386518643
