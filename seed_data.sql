-- Sample multi-row data for Multi-Tenant SaaS Database
USE saas_db;

INSERT INTO tenants (tenant_id, tenant_name, tenant_code) VALUES
(1, 'TechNova Solutions', 'TECHNOVA'),
(2, 'CloudBridge Systems', 'CLOUDBRIDGE'),
(3, 'DataSphere Analytics', 'DATASPHERE');

INSERT INTO users (user_id, full_name, email) VALUES
(1, 'Amit Sharma', 'amit@example.com'),
(2, 'Priya Verma', 'priya@example.com'),
(3, 'Rahul Patel', 'rahul@example.com'),
(4, 'Sneha Gupta', 'sneha@example.com'),
(5, 'Arjun Singh', 'arjun@example.com'),
(6, 'Neha Jain', 'neha@example.com');

INSERT INTO tenant_users (tenant_id, user_id, role) VALUES
(1, 1, 'OWNER'), (1, 2, 'ADMIN'), (1, 3, 'MEMBER'), (1, 4, 'MEMBER'),
(2, 2, 'OWNER'), (2, 5, 'ADMIN'), (2, 6, 'MEMBER'),
(3, 1, 'ADMIN'), (3, 5, 'OWNER'), (3, 6, 'MEMBER');

INSERT INTO user_profiles (user_id, phone, city, bio) VALUES
(1, '9876543210', 'Raipur', 'Software developer'),
(2, '9876543211', 'Bilaspur', 'Project administrator'),
(3, '9876543212', 'Durg', 'Backend developer'),
(4, '9876543213', 'Raipur', 'Frontend developer'),
(5, '9876543214', 'Bhilai', 'Cloud engineer'),
(6, '9876543215', 'Raipur', 'Data analyst');

INSERT INTO projects (project_id, tenant_id, project_name, description, status) VALUES
(1, 1, 'CRM Platform', 'Customer management application', 'ACTIVE'),
(2, 1, 'E-Commerce App', 'Online shopping platform', 'ACTIVE'),
(3, 2, 'Cloud Migration', 'Cloud infrastructure migration', 'ACTIVE'),
(4, 2, 'Monitoring Tool', 'System monitoring application', 'COMPLETED'),
(5, 3, 'Sales Dashboard', 'Business analytics dashboard', 'ACTIVE');

INSERT INTO project_members (project_id, tenant_id, user_id, project_role) VALUES
(1, 1, 1, 'MANAGER'), (1, 1, 2, 'MEMBER'), (1, 1, 3, 'DEVELOPER'),
(2, 1, 1, 'MANAGER'), (2, 1, 4, 'DEVELOPER'),
(3, 2, 2, 'MANAGER'), (3, 2, 5, 'DEVELOPER'),
(4, 2, 6, 'MEMBER'),
(5, 3, 1, 'MANAGER'), (5, 3, 5, 'DEVELOPER'), (5, 3, 6, 'MEMBER');

INSERT INTO tasks (task_id, project_id, task_title, task_status, priority, due_date) VALUES
(1, 1, 'Design database schema', 'DONE', 'HIGH', '2026-11-05'),
(2, 1, 'Develop login module', 'IN_PROGRESS', 'HIGH', '2026-11-10'),
(3, 1, 'Create customer API', 'TODO', 'MEDIUM', '2026-11-15'),
(4, 2, 'Build product page', 'IN_PROGRESS', 'HIGH', '2026-11-12'),
(5, 2, 'Integrate payment gateway', 'TODO', 'HIGH', '2026-11-20'),
(6, 3, 'Configure cloud server', 'DONE', 'HIGH', '2026-11-08'),
(7, 3, 'Migrate application data', 'IN_PROGRESS', 'MEDIUM', '2026-11-18'),
(8, 4, 'Create monitoring dashboard', 'DONE', 'MEDIUM', '2026-11-09'),
(9, 5, 'Build sales charts', 'TODO', 'HIGH', '2026-11-25'),
(10, 5, 'Prepare analytics report', 'IN_PROGRESS', 'MEDIUM', '2026-11-28');

INSERT INTO task_assignments (task_id, user_id) VALUES
(1, 1), (2, 3), (3, 2), (4, 4), (5, 1),
(6, 5), (7, 2), (8, 6), (9, 5), (10, 6);

SELECT 'tenants' AS table_name, COUNT(*) AS rows_count FROM tenants
UNION ALL SELECT 'users', COUNT(*) FROM users
UNION ALL SELECT 'tenant_users', COUNT(*) FROM tenant_users
UNION ALL SELECT 'user_profiles', COUNT(*) FROM user_profiles
UNION ALL SELECT 'projects', COUNT(*) FROM projects
UNION ALL SELECT 'project_members', COUNT(*) FROM project_members
UNION ALL SELECT 'tasks', COUNT(*) FROM tasks
UNION ALL SELECT 'task_assignments', COUNT(*) FROM task_assignments;
