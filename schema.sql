-- ============================================================
-- Multi-Tenant SaaS Database | Relational Schema Modeling & 3NF
-- Database: MySQL 8.0+
-- WARNING: This script drops tables in saas_db before recreating them.
-- Back up important data before running it on an existing database.
-- ============================================================

CREATE DATABASE IF NOT EXISTS saas_db;
USE saas_db;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS task_assignments;
DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS project_members;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS tenant_users;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS tenants;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Organizations / tenants
CREATE TABLE tenants (
    tenant_id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_name VARCHAR(100) NOT NULL,
    tenant_code VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_tenant_name CHECK (CHAR_LENGTH(TRIM(tenant_name)) > 0)
) ENGINE=InnoDB;

-- 2. Global user identity
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_user_name CHECK (CHAR_LENGTH(TRIM(full_name)) > 0)
) ENGINE=InnoDB;

-- 3. User-to-tenant membership (N:M)
CREATE TABLE tenant_users (
    tenant_id INT NOT NULL,
    user_id INT NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (tenant_id, user_id),
    CONSTRAINT chk_tenant_user_role CHECK (role IN ('OWNER', 'ADMIN', 'MEMBER')),
    CONSTRAINT fk_tenant_users_tenant FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_tenant_users_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 4. Optional one-to-one profile per user
CREATE TABLE user_profiles (
    profile_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    phone VARCHAR(20),
    city VARCHAR(80),
    bio VARCHAR(255),
    CONSTRAINT fk_profiles_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 5. Projects belong to one tenant
CREATE TABLE projects (
    project_id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    project_name VARCHAR(120) NOT NULL,
    description VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_project_status CHECK (status IN ('ACTIVE', 'COMPLETED', 'ARCHIVED')),
    CONSTRAINT chk_project_name CHECK (CHAR_LENGTH(TRIM(project_name)) > 0),
    CONSTRAINT uq_project_tenant_name UNIQUE (tenant_id, project_name),
    -- Required as the referenced key for project_members' composite FK.
    CONSTRAINT uq_project_id_tenant UNIQUE (project_id, tenant_id),
    CONSTRAINT fk_projects_tenant FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 6. Project-to-user membership (N:M), tenant consistency enforced by composite FKs
CREATE TABLE project_members (
    project_id INT NOT NULL,
    user_id INT NOT NULL,
    project_role VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    PRIMARY KEY (project_id, user_id),
    CONSTRAINT chk_project_member_role CHECK (project_role IN ('MANAGER', 'DEVELOPER', 'MEMBER')),
    CONSTRAINT fk_pm_project FOREIGN KEY (project_id)
        REFERENCES projects(project_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pm_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DELIMITER $$
CREATE TRIGGER trg_project_member_before_insert
BEFORE INSERT ON project_members
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM projects AS p
        JOIN tenant_users AS tu ON tu.tenant_id = p.tenant_id
        WHERE p.project_id = NEW.project_id
          AND tu.user_id = NEW.user_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Project member must belong to the project tenant';
    END IF;
END$$

CREATE TRIGGER trg_project_member_before_update
BEFORE UPDATE ON project_members
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM projects AS p
        JOIN tenant_users AS tu ON tu.tenant_id = p.tenant_id
        WHERE p.project_id = NEW.project_id
          AND tu.user_id = NEW.user_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Project member must belong to the project tenant';
    END IF;
END$$
DELIMITER ;

-- 7. Tasks belong to one project
CREATE TABLE tasks (
    task_id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    task_title VARCHAR(150) NOT NULL,
    task_status VARCHAR(20) NOT NULL DEFAULT 'TODO',
    priority VARCHAR(10) NOT NULL DEFAULT 'MEDIUM',
    due_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_task_status CHECK (task_status IN ('TODO', 'IN_PROGRESS', 'DONE')),
    CONSTRAINT chk_task_priority CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH')),
    CONSTRAINT chk_task_title CHECK (CHAR_LENGTH(TRIM(task_title)) > 0),
    CONSTRAINT fk_tasks_project FOREIGN KEY (project_id)
        REFERENCES projects(project_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 8. Task-to-user assignment (N:M)
-- No tenant_id is duplicated here: task_id determines the project's tenant.
-- Triggers enforce that an assignee is a member of the task's project.
CREATE TABLE task_assignments (
    task_id INT NOT NULL,
    user_id INT NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (task_id, user_id),
    CONSTRAINT fk_ta_task FOREIGN KEY (task_id)
        REFERENCES tasks(task_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ta_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DELIMITER $$
CREATE TRIGGER trg_task_assignment_before_insert
BEFORE INSERT ON task_assignments
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM tasks AS tk
        JOIN projects AS p ON p.project_id = tk.project_id
        JOIN project_members AS pm ON pm.project_id = p.project_id
        WHERE tk.task_id = NEW.task_id
          AND pm.user_id = NEW.user_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Assignee must be a member of the task project';
    END IF;
END$$

CREATE TRIGGER trg_task_assignment_before_update
BEFORE UPDATE ON task_assignments
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM tasks AS tk
        JOIN projects AS p ON p.project_id = tk.project_id
        JOIN project_members AS pm ON pm.project_id = p.project_id
        WHERE tk.task_id = NEW.task_id
          AND pm.user_id = NEW.user_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Assignee must be a member of the task project';
    END IF;
END$$
DELIMITER ;

SHOW TABLES;
