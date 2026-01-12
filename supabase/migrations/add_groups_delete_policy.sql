-- ============================================================================
-- Migration: Add DELETE policy for groups table
-- ============================================================================
-- This migration adds a DELETE policy to the groups table to allow:
-- 1. Group creators to delete their own groups when current_members = 0
-- 2. Platform admins to delete any group
--
-- This fixes the issue where group creation payment initialization fails
-- but the group cannot be cleaned up due to missing DELETE policy.
-- ============================================================================

-- Add DELETE policy for groups
CREATE POLICY groups_delete_creator_empty ON groups
  FOR DELETE
  USING (
    (auth.uid() = created_by AND current_members = 0) OR
    is_current_user_admin()
  );

-- Add comment for documentation
COMMENT ON POLICY groups_delete_creator_empty ON groups IS 
  'Allows group creators to delete their own groups when no members have joined (current_members = 0). Platform admins can delete any group.';
