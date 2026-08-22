import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'http://127.0.0.1:54321';

// IMPORTANT:
// This is ONLY for the local Docker Supabase instance.
// Never replace this with a production/dev service-role key.
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_SERVICE_ROLE_KEY) {
  console.error(
    'Missing SUPABASE_SERVICE_ROLE_KEY environment variable.'
  );
  process.exit(1);
}

const supabase = createClient(
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

const TEST_PASSWORD = 'ICPF-Local-Test-2026!';

const users = [
  {
    email: 'admin@icpf.local',
    role: 'admin',
  },
  {
    email: 'coordinator@icpf.local',
    role: 'camp_coordinator',
  },
  {
    email: 'cgpf@icpf.local',
    role: 'cgpf',
  },
  {
    email: 'staff@icpf.local',
    role: 'staff',
  },
];

const CAMP_A_ID =
  '10000000-0000-0000-0000-000000000001';

async function main() {
  console.log('\nICPF local development bootstrap');
  console.log('================================\n');

  const createdUsers = [];

  // ----------------------------------------------------------
  // 1. Create / retrieve Auth users
  // ----------------------------------------------------------

  for (const testUser of users) {
    const { data: existingUsers, error: listError } =
      await supabase.auth.admin.listUsers({
        page: 1,
        perPage: 100,
      });

    if (listError) {
      throw new Error(
        `Unable to list Auth users: ${listError.message}`
      );
    }

    const existing = existingUsers.users.find(
      (user) => user.email === testUser.email
    );

    let user;

    if (existing) {
      user = existing;
      console.log(`✓ Auth exists: ${testUser.email}`);
    } else {
      const { data, error } =
        await supabase.auth.admin.createUser({
          email: testUser.email,
          password: TEST_PASSWORD,
          email_confirm: true,
        });

      if (error) {
        throw new Error(
          `Failed to create ${testUser.email}: ${error.message}`
        );
      }

      user = data.user;

      console.log(`✓ Auth created: ${testUser.email}`);
    }

    createdUsers.push({
      ...testUser,
      id: user.id,
    });
  }

  // ----------------------------------------------------------
  // 2. Verify profiles created by Auth trigger
  // ----------------------------------------------------------

  console.log('\nChecking profiles...');

  for (const testUser of createdUsers) {
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('id, email, full_name, is_active')
      .eq('id', testUser.id)
      .single();

    if (error) {
      throw new Error(
        `Profile missing for ${testUser.email}: ${error.message}`
      );
    }

    console.log(
      `✓ Profile: ${profile.email}`
    );
  }

  // ----------------------------------------------------------
  // 3. Load role IDs
  // ----------------------------------------------------------

  console.log('\nLoading roles...');

  const { data: roles, error: rolesError } =
    await supabase
      .from('roles')
      .select('id, code');

  if (rolesError) {
    throw new Error(
      `Unable to load roles: ${rolesError.message}`
    );
  }

  const roleMap = new Map(
    roles.map((role) => [role.code, role.id])
  );

  for (const testUser of users) {
    if (!roleMap.has(testUser.role)) {
      throw new Error(
        `Required role does not exist: ${testUser.role}`
      );
    }
  }

  // ----------------------------------------------------------
  // 4. Assign roles
  // ----------------------------------------------------------

  console.log('\nAssigning roles...');

  for (const testUser of createdUsers) {
    const roleId = roleMap.get(testUser.role);

    const { error } = await supabase
      .from('user_roles')
      .upsert(
        {
          user_id: testUser.id,
          role_id: roleId,
        },
        {
          onConflict: 'user_id,role_id',
        }
      );

    if (error) {
      throw new Error(
        `Failed to assign ${testUser.role} to ${testUser.email}: ${error.message}`
      );
    }

    console.log(
      `✓ ${testUser.email} → ${testUser.role}`
    );
  }

  // ----------------------------------------------------------
  // 5. Assign coordinator to Camp A
  // ----------------------------------------------------------

  console.log('\nAssigning camp scope...');

  const coordinator = createdUsers.find(
    (user) => user.role === 'camp_coordinator'
  );

  const admin = createdUsers.find(
    (user) => user.role === 'admin'
  );

  if (!coordinator || !admin) {
    throw new Error(
      'Required test users not found.'
    );
  }

  const { error: assignmentError } =
    await supabase
      .from('camp_assignments')
      .upsert(
        {
          user_id: coordinator.id,
          camp_id: CAMP_A_ID,
          assigned_by: admin.id,
          is_active: true,
        },
        {
          onConflict: 'user_id,camp_id',
        }
      );

  if (assignmentError) {
    throw new Error(
      `Failed to assign coordinator to Camp A: ${assignmentError.message}`
    );
  }

  console.log(
    '✓ coordinator@icpf.local → RLS Test Camp A'
  );

  // ----------------------------------------------------------
  // 6. Verify coordinator does NOT have Camp B
  // ----------------------------------------------------------

  const CAMP_B_ID =
    '10000000-0000-0000-0000-000000000002';

  const { data: campBAssignment, error: campBError } =
    await supabase
      .from('camp_assignments')
      .select('id')
      .eq('user_id', coordinator.id)
      .eq('camp_id', CAMP_B_ID)
      .maybeSingle();

  if (campBError) {
    throw new Error(
      `Unable to verify Camp B isolation: ${campBError.message}`
    );
  }

  if (campBAssignment) {
    throw new Error(
      'SECURITY FAILURE: Coordinator has Camp B assignment.'
    );
  }

  console.log(
    '✓ coordinator@icpf.local has NO Camp B assignment'
  );

  // ----------------------------------------------------------
  // 7. Summary
  // ----------------------------------------------------------

  console.log('\n================================');
  console.log('LOCAL BOOTSTRAP COMPLETE');
  console.log('================================\n');

  for (const user of createdUsers) {
    console.log(
      `${user.email} → ${user.role}`
    );
  }

  console.log(
    '\nCoordinator scope: Camp A only'
  );

  console.log(
    '\nNext step: RLS authorization tests.\n'
  );
}

main().catch((error) => {
  console.error('\n❌ Bootstrap failed:\n');
  console.error(error.message);
  process.exit(1);
});