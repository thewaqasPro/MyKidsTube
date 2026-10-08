-- Migration 0008: Ensure least-privileged default role ('unapproved')
-- Normalizes any legacy or unassigned roles to 'unapproved'
UPDATE user SET role = 'unapproved' WHERE role IS NULL;
