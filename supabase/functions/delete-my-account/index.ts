import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const privateBuckets = [
  'pet-documents',
  'visit-documents',
  'announcement-media',
] as const;

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return json({ error: 'METHOD_NOT_ALLOWED' }, 405);
  }

  try {
    const authorization = request.headers.get('Authorization');
    if (!authorization) return json({ error: 'UNAUTHORIZED' }, 401);

    const supabaseUrl = requiredEnv('SUPABASE_URL');
    const anonKey = requiredEnv('SUPABASE_ANON_KEY');
    const serviceRoleKey = requiredEnv('SUPABASE_SERVICE_ROLE_KEY');

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();
    if (userError || !user) return json({ error: 'UNAUTHORIZED' }, 401);

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });
    const { data: profile, error: profileError } = await admin
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();
    if (profileError) throw profileError;
    if (profile?.role === 'platform_admin') {
      return json({ error: 'ADMIN_ACCOUNT_PROTECTED' }, 403);
    }

    for (const bucket of privateBuckets) {
      await removeFolder(admin, bucket, user.id);
    }

    const { error: cleanupError } = await admin.rpc(
      'delete_user_account_data',
      { target_user_id: user.id },
    );
    if (cleanupError) throw cleanupError;

    const { error: deleteUserError } = await admin.auth.admin.deleteUser(user.id);
    if (deleteUserError) throw deleteUserError;

    return json({ ok: true });
  } catch (error) {
    console.error('Account deletion failed', error);
    return json({ error: 'ACCOUNT_DELETION_FAILED' }, 500);
  }
});

async function removeFolder(
  admin: ReturnType<typeof createClient>,
  bucket: string,
  folder: string,
): Promise<void> {
  const paths: string[] = [];
  await collectPaths(admin, bucket, folder, paths);
  for (let index = 0; index < paths.length; index += 100) {
    const { error } = await admin.storage
      .from(bucket)
      .remove(paths.slice(index, index + 100));
    if (error) throw error;
  }
}

async function collectPaths(
  admin: ReturnType<typeof createClient>,
  bucket: string,
  folder: string,
  paths: string[],
): Promise<void> {
  let offset = 0;
  const limit = 100;
  while (true) {
    const { data, error } = await admin.storage
      .from(bucket)
      .list(folder, { limit, offset });
    if (error) {
      if (/not found/i.test(error.message)) return;
      throw error;
    }
    if (!data?.length) return;
    for (const entry of data) {
      const path = `${folder}/${entry.name}`;
      if (entry.id) {
        paths.push(path);
      } else {
        await collectPaths(admin, bucket, path, paths);
      }
    }
    if (data.length < limit) return;
    offset += limit;
  }
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`MISSING_${name}`);
  return value;
}

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
