# Multi-Tenant SaaS Database — 3NF Normalization

A MySQL database design for a multi-tenant SaaS project-management application. The schema demonstrates relational modeling, 3NF-oriented table separation, referential integrity, validation constraints, seed data, and cascading actions.

## Tables

1. `tenants` — organizations/tenants
2. `users` — global user identities
3. `tenant_users` — tenant membership and role (many-to-many bridge)
4. `user_profiles` — optional one-to-one user profile
5. `projects` — projects owned by a tenant
6. `project_members` — users assigned to projects (many-to-many bridge)
7. `tasks` — tasks within a project
8. `task_assignments` — users assigned to tasks (many-to-many bridge)

## ER Diagram

See [`ER_Diagram.png`](ER_Diagram.png) or [`ER_Diagram.mmd`](ER_Diagram.mmd).

## Requirements

- MySQL 8.0 or later
- A MySQL client (MySQL Command Line Client, MySQL Workbench, or VS Code with a MySQL extension)

## Run the project

Run these scripts in order from your MySQL client:

1. `schema.sql` — creates the database and tables.
2. `seed_data.sql` — inserts sample rows.
3. `verify.sql` — runs joins and tests cascading delete/update inside transactions that are rolled back.

Example from a command-line shell (not from inside the `mysql>` prompt):

```bash
mysql -u root -p < schema.sql
mysql -u root -p < seed_data.sql
mysql -u root -p < verify.sql
```

If you are already inside the MySQL prompt, use:

```sql
SOURCE /full/path/to/schema.sql;
SOURCE /full/path/to/seed_data.sql;
SOURCE /full/path/to/verify.sql;
```

Replace the paths with the actual file paths on your computer.

## Relationships

- `users` to `user_profiles`: 1:1 (unique `user_id` in `user_profiles`)
- `tenants` to `projects`: 1:N
- `projects` to `tasks`: 1:N
- `tenants` to `users`: N:M through `tenant_users`
- `projects` to `users`: N:M through `project_members`
- `tasks` to `users`: N:M through `task_assignments`

## 3NF notes

- Each table represents one main entity or relationship.
- Bridge tables represent many-to-many relationships.
- User, profile, tenant, project, and task attributes are stored in their relevant tables to avoid unnecessary duplication.
- Composite primary keys prevent duplicate memberships/assignments.
- Foreign keys protect referenced rows; `CHECK`, `UNIQUE`, and `NOT NULL` constraints validate data. Triggers enforce that project members belong to the project tenant and task assignees belong to the project membership.

The schema separates tenant, user, profile, project, task, and bridge-table attributes to avoid storing derived tenant IDs in membership/assignment tables. Triggers enforce cross-table rules that cannot be expressed with these foreign keys alone. In production, tenant isolation must also be enforced by application authorization and appropriate database controls.

## Cascading actions

Foreign keys use `ON DELETE CASCADE` and `ON UPDATE CASCADE` where dependent rows should follow their parent. `verify.sql` tests these actions in transactions and rolls back the test changes.

## Repository contents

- `schema.sql` — DDL and constraints
- `seed_data.sql` — realistic sample data
- `verify.sql` — relationship queries and cascade tests
- `ER_Diagram.png` — ER diagram image
- `ER_Diagram.mmd` — editable Mermaid ER diagram source
- `GITHUB_POST.md` — suggested post caption

## Author

Add your name, course, and institution here before publishing.
