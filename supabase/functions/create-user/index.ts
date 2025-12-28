import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Missing Authorization header');
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;

    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: { Authorization: authHeader },
      },
    });

    const { data: { user: currentUser }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !currentUser) {
      throw new Error('Unauthorized');
    }

    const { data: profile } = await supabaseClient
      .from('profiles')
      .select('role, company_id')
      .eq('id', currentUser.id)
      .maybeSingle();

    if (!profile || !['admin', 'superviseur'].includes(profile.role)) {
      throw new Error('Only admins and superviseurs can create users');
    }

    const { email, password, full_name, role, phone, photo_url, zone_affectation } = await req.json();

    if (!email || !password || !full_name || !role) {
      throw new Error('Missing required fields');
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name,
        role,
        company_id: profile.company_id,
      },
    });

    if (createError) {
      if (createError.message.includes('already registered')) {
        throw new Error('User already registered');
      }
      throw createError;
    }

    if ((phone || photo_url || zone_affectation) && newUser.user) {
      const updates: any = {};
      if (phone) updates.phone = phone;
      if (photo_url) updates.photo_url = photo_url;
      if (zone_affectation) updates.zone_affectation = zone_affectation;

      await supabaseAdmin
        .from('profiles')
        .update(updates)
        .eq('id', newUser.user.id);
    }

    return new Response(
      JSON.stringify({
        success: true,
        user: {
          id: newUser.user.id,
          email: newUser.user.email,
        },
      }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: error.message,
      }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      }
    );
  }
});