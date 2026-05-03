TYPE=VIEW
query=select `t`.`ticket_id` AS `ticket_id`,`t`.`title` AS `title`,`t`.`created_at` AS `created_at`,`t`.`updated_at` AS `updated_at`,`requester`.`name` AS `requester_name`,coalesce(`assignee`.`name`,\'Unassigned\') AS `assignee_name`,`c`.`category_name` AS `category_name`,`p`.`priority_name` AS `priority_name`,`p`.`sort_order` AS `priority_sort_order`,`s`.`status_name` AS `status_name` from (((((`helpdesk`.`tickets` `t` join `helpdesk`.`users` `requester` on(`requester`.`user_id` = `t`.`requester_id`)) left join `helpdesk`.`users` `assignee` on(`assignee`.`user_id` = `t`.`assignee_id`)) join `helpdesk`.`categories` `c` on(`c`.`category_id` = `t`.`category_id`)) join `helpdesk`.`priorities` `p` on(`p`.`priority_id` = `t`.`priority_id`)) join `helpdesk`.`statuses` `s` on(`s`.`status_id` = `t`.`status_id`)) where `s`.`is_closed` = 0 and `s`.`status_name` <> \'Resolved\'
md5=012d671f3115accf00c4918f8dac4257
updatable=0
algorithm=0
definer_user=helpdesk_user
definer_host=127.0.0.1
suid=2
with_check_option=0
timestamp=0001777237386322121
create-version=2
source=SELECT\n    t.ticket_id,\n    t.title,\n    t.created_at,\n    t.updated_at,\n    requester.name AS requester_name,\n    COALESCE(assignee.name, \'Unassigned\') AS assignee_name,\n    c.category_name,\n    p.priority_name,\n    p.sort_order AS priority_sort_order,\n    s.status_name\nFROM tickets t\nJOIN users requester ON requester.user_id = t.requester_id\nLEFT JOIN users assignee ON assignee.user_id = t.assignee_id\nJOIN categories c ON c.category_id = t.category_id\nJOIN priorities p ON p.priority_id = t.priority_id\nJOIN statuses s ON s.status_id = t.status_id\nWHERE s.is_closed = 0 AND s.status_name <> \'Resolved\'
client_cs_name=utf8mb4
connection_cl_name=utf8mb4_uca1400_ai_ci
view_body_utf8=select `t`.`ticket_id` AS `ticket_id`,`t`.`title` AS `title`,`t`.`created_at` AS `created_at`,`t`.`updated_at` AS `updated_at`,`requester`.`name` AS `requester_name`,coalesce(`assignee`.`name`,\'Unassigned\') AS `assignee_name`,`c`.`category_name` AS `category_name`,`p`.`priority_name` AS `priority_name`,`p`.`sort_order` AS `priority_sort_order`,`s`.`status_name` AS `status_name` from (((((`helpdesk`.`tickets` `t` join `helpdesk`.`users` `requester` on(`requester`.`user_id` = `t`.`requester_id`)) left join `helpdesk`.`users` `assignee` on(`assignee`.`user_id` = `t`.`assignee_id`)) join `helpdesk`.`categories` `c` on(`c`.`category_id` = `t`.`category_id`)) join `helpdesk`.`priorities` `p` on(`p`.`priority_id` = `t`.`priority_id`)) join `helpdesk`.`statuses` `s` on(`s`.`status_id` = `t`.`status_id`)) where `s`.`is_closed` = 0 and `s`.`status_name` <> \'Resolved\'
mariadb-version=120102
