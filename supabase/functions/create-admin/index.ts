import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
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
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    const { data: existingUser } = await supabaseAdmin.auth.admin.listUsers();
    const adminExists = existingUser?.users?.some(
      (user) => user.email === 'admin@lagrace.ci'
    );

    if (adminExists) {
      return new Response(
        JSON.stringify({ message: 'Admin user already exists' }),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      );
    }

    const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser(
      {
        email: 'admin@lagrace.ci',
        password: 'Admin123!',
        email_confirm: true,
        user_metadata: {
          full_name: 'Administrateur',
          role: 'admin',
          company_name: 'LA GRACE SARL',
        },
      }
    );

    if (createError) {
      throw createError;
    }

    return new Response(
      JSON.stringify({
        message: 'Admin user created successfully',
        email: 'admin@lagrace.ci',
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
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      }
    );
  }
});
