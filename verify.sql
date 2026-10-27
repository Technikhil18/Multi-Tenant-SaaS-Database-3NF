-- Run after schema.sql and seed_data.sql
USE saas_db;

-- 1. Project/task overview
SELECT t.tenant_name, p.project_name, tk.task_title, tk.task_status, tk.priority
FROM tenants AS t
JOIN projects AS p ON p.tenant_id = t.tenant_id
JOIN tasks AS tk ON tk.project_id = p.project_id
ORDER BY t.tenant_id, p.project_id, tk.task_id;

-- 2. Tenant memberships
SELECT t.tenant_name, u.full_name, u.email, tu.role
FROM tenant_users AS tu
JOIN tenants AS t ON t.tenant_id = tu.tenant_id
JOIN users AS u ON u.user_id = tu.user_id
ORDER BY t.tenant_id, u.user_id;

-- 3. Project members
SELECT p.project_name, t.tenant_name, u.full_name, pm.project_role
FROM project_members AS pm
JOIN projects AS p ON p.project_id = pm.project_id
JOIN tenants AS t ON t.tenant_id = p.tenant_id
JOIN users AS u ON u.user_id = pm.user_id;

-- 4. Task assignments
SELECT tk.task_title, t.tenant_name, u.full_name, ta.assigned_at
FROM task_assignments AS ta
JOIN tasks AS tk ON tk.task_id = ta.task_id
JOIN projects AS p ON p.project_id = tk.project_id
JOIN tenants AS t ON t.tenant_id = p.tenant_id
JOIN users AS u ON u.user_id = ta.user_id;

-- 5. Cascading delete test. Changes are rolled back afterwards.
START TRANSACTION;
DELETE FROM tenants WHERE tenant_id = 1;
SELECT COUNT(*) AS projects_remaining_for_tenant_1
FROM projects WHERE tenant_id = 1; -- Expected: 0
SELECT COUNT(*) AS memberships_remaining_for_tenant_1
FROM tenant_users WHERE tenant_id = 1; -- Expected: 0
ROLLBACK;

-- 6. Cascading update test. Changes are rolled back afterwards.
START TRANSACTION;
UPDATE tenants SET tenant_id = 10 WHERE tenant_id = 1;
SELECT tenant_id, project_name FROM projects WHERE tenant_id = 10; -- Expected: 2 rows
SELECT tenant_id, user_id FROM tenant_users WHERE tenant_id = 10; -- Expected: 4 rows
ROLLBACK;

-- 7. Example of a constraint failure (uncomment to test; then rerun valid data if needed):
-- INSERT INTO projects (tenant_id, project_name, status)
-- VALUES (999, 'Invalid Project', 'ACTIVE');

-- 8. Invalid assignment test (should fail with SQLSTATE 45000).
-- User 5 is not a member of project 1, so this should be rejected.
-- INSERT INTO task_assignments (task_id, user_id) VALUES (1, 5);
