import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, PUT, OPTIONS',
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
      .select('role')
      .eq('id', currentUser.id)
      .maybeSingle();

    if (!profile || !['admin', 'superviseur'].includes(profile.role)) {
      throw new Error('Only admins and superviseurs can update users');
    }

    const { userId, email, password, full_name, role, phone, photo_url } = await req.json();

    if (!userId) {
      throw new Error('Missing userId');
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    const updateData: any = {};
    
    if (email !== undefined) {
      updateData.email = email;
    }
    
    if (password !== undefined && password.length > 0) {
      updateData.password = password;
    }

    if (email !== undefined || password !== undefined) {
      const { error: authUpdateError } = await supabaseAdmin.auth.admin.updateUserById(
        userId,
        updateData
      );

      if (authUpdateError) {
        throw authUpdateError;
      }
    }

    const profileUpdates: any = {};
    if (full_name !== undefined) profileUpdates.full_name = full_name;
    if (role !== undefined) profileUpdates.role = role;
    if (phone !== undefined) profileUpdates.phone = phone;
    if (photo_url !== undefined) profileUpdates.photo_url = photo_url;

    if (Object.keys(profileUpdates).length > 0) {
      profileUpdates.updated_at = new Date().toISOString();
      
      const { error: profileUpdateError } = await supabaseAdmin
        .from('profiles')
        .update(profileUpdates)
        .eq('id', userId);

      if (profileUpdateError) {
        throw profileUpdateError;
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'User updated successfully',
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
