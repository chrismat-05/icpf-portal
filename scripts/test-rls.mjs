import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'http://127.0.0.1:54321';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_ANON_KEY) {
  console.error('Missing SUPABASE_ANON_KEY');
  process.exit(1);
}

const users = [
  {
    name: 'Admin',
    email: 'admin@icpf.local',
    password: 'ICPF-Local-Test-2026!',
  },
  {
    name: 'Coordinator',
    email: 'coordinator@icpf.local',
    password: 'ICPF-Local-Test-2026!',
  },
  {
    name: 'CGPF',
    email: 'cgpf@icpf.local',
    password: 'ICPF-Local-Test-2026!',
  },
  {
    name: 'Staff',
    email: 'staff@icpf.local',
    password: 'ICPF-Local-Test-2026!',
  },
];

async function testUser(user) {
  const supabase = createClient(
    SUPABASE_URL,
    SUPABASE_ANON_KEY,
    {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    }
  );

  console.log(`\n=== ${user.name} (${user.email}) ===`);

  const { error: authError } =
    await supabase.auth.signInWithPassword({
      email: user.email,
      password: user.password,
    });

  if (authError) {
    console.error('AUTH FAILED:', authError.message);
    return;
  }

  console.log('✓ Authenticated');

  const {
    data: { user: authUser },
  } = await supabase.auth.getUser();

  console.log(`User ID: ${authUser.id}`);
  const { data: debugData, error: debugError } =
  await supabase.rpc('debug_auth_context');

if (debugError) {
  console.log('Debug RPC ERROR:', debugError.message);
} else {
  console.log('Authorization context:', JSON.stringify(debugData));
}

  const { data: roles, error: rolesError } = await supabase
    .from('user_roles')
    .select(`
      role_id,
      roles (
        code,
        name
      )
    `)
    .eq('user_id', authUser.id);

  if (rolesError) {
    console.log('Roles: QUERY DENIED');
  } else {
    console.log('Roles:', JSON.stringify(roles));
  }

  const { data: assignments, error: assignmentError } =
    await supabase
      .from('camp_assignments')
      .select(`
        camp_id,
        is_active,
        expires_at,
        camps (
          slug,
          name
        )
      `)
      .eq('user_id', authUser.id);

  if (assignmentError) {
    console.log('Camp assignments: QUERY DENIED');
  } else {
    console.log(
      'Camp assignments:',
      JSON.stringify(assignments)
    );
  }

  const { data: camps, error: campsError } = await supabase
    .from('camps')
    .select('id, slug, name')
    .order('slug');

  if (campsError) {
    console.log('Camps: QUERY ERROR:', campsError.message);
  } else {
    console.log('Visible camps:');

    for (const camp of camps) {
      console.log(`  ${camp.slug} → ${camp.name}`);
    }

    if (camps.length === 0) {
      console.log('  (none)');
    }
  }

  await supabase.auth.signOut();
}

for (const user of users) {
  await testUser(user);
}