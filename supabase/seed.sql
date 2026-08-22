-- ============================================================
-- ICPF BENGALURU
-- LOCAL DEVELOPMENT SEED
-- ============================================================
--
-- This file is ONLY for local development.
-- It must never contain real production data.
--
-- Auth users are intentionally NOT created here.
-- They will be created through Supabase Auth.
-- ============================================================


-- ------------------------------------------------------------
-- Deterministic test IDs
-- ------------------------------------------------------------
-- ============================================================
-- SYSTEM ROLES
-- ============================================================

INSERT INTO public.roles (
    id,
    code,
    name
)
VALUES
(
    '20000000-0000-0000-0000-000000000001',
    'admin',
    'Admin'
),
(
    '20000000-0000-0000-0000-000000000002',
    'camp_coordinator',
    'Camp Coordinator'
),
(
    '20000000-0000-0000-0000-000000000003',
    'cgpf',
    'CGPF'
),
(
    '20000000-0000-0000-0000-000000000004',
    'staff',
    'Staff'
)
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name;

-- Test camps
INSERT INTO public.camps (
    id,
    slug,
    name,
    tagline,
    description,
    start_at,
    end_at,
    timezone,
    venue_name,
    venue_address,
    registration_enabled,
    registration_opens_at,
    registration_closes_at,
    registration_limit,
    base_fee,
    age_restriction_enabled,
    tshirt_enabled,
    google_sheets_enabled,
    content_status,
    operational_registration_status,
    created_at,
    updated_at
)
VALUES
(
    '10000000-0000-0000-0000-000000000001',
    'rls-test-camp-a',
    'RLS Test Camp A',
    'Local security testing camp',
    'Development-only camp used to test camp-scoped authorization.',
    '2030-01-10 09:00:00+05:30',
    '2030-01-12 18:00:00+05:30',
    'Asia/Kolkata',
    'ICPF Test Venue A',
    'Bengaluru, Karnataka',
    false,
    NULL,
    NULL,
    100,
    1500.00,
    false,
    false,
    false,
    'draft',
    'closed',
    now(),
    now()
),
(
    '10000000-0000-0000-0000-000000000002',
    'rls-test-camp-b',
    'RLS Test Camp B',
    'Second local security testing camp',
    'Development-only camp used to verify cross-camp isolation.',
    '2030-02-10 09:00:00+05:30',
    '2030-02-12 18:00:00+05:30',
    'Asia/Kolkata',
    'ICPF Test Venue B',
    'Bengaluru, Karnataka',
    false,
    NULL,
    NULL,
    100,
    1500.00,
    false,
    false,
    false,
    'draft',
    'closed',
    now(),
    now()
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    updated_at = now();


-- ------------------------------------------------------------
-- NOTE:
-- User/profile/role assignment records are NOT seeded here yet.
--
-- Reason:
-- profiles.id references auth.users.id.
--
-- Local Auth users must first be created through Supabase Auth.
-- After that, we will create:
--
--   Admin
--   Camp Coordinator
--   CGPF
--   Staff
--
-- and assign:
--
--   Coordinator → Camp A
--
-- while leaving Camp B unassigned.
-- ------------------------------------------------------------