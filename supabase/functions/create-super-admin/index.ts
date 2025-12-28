import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
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

    const email = 'superadmin@system.com';
    const password = 'SuperAdmin2024!';

    // Vérifier si l'utilisateur existe déjà
    const { data: existingUser } = await supabaseAdmin.auth.admin.listUsers();
    const userExists = existingUser?.users?.some(
      (user) => user.email === email
    );

    if (userExists) {
      return new Response(
        JSON.stringify({ 
          message: 'Super admin user already exists',
          email: email,
          password: password
        }),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      );
    }

    // Créer le super admin
    const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser(
      {
        email: email,
        password: password,
        email_confirm: true,
        user_metadata: {
          full_name: 'Super Administrateur',
          role: 'super_admin',
        },
      }
    );

    if (createError) {
      throw createError;
    }

    // Créer le profil avec company_id NULL
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .insert({
        id: newUser.user.id,
        email: email,
        full_name: 'Super Administrateur',
        role: 'super_admin',
        company_id: null,
      });

    if (profileError) {
      // Si le profil existe déjà (créé par le trigger), on le met à jour
      await supabaseAdmin
        .from('profiles')
        .update({
          role: 'super_admin',
          company_id: null,
        })
        .eq('id', newUser.user.id);
    }

    return new Response(
      JSON.stringify({
        message: 'Super admin user created successfully',
        email: email,
        password: password,
        user_id: newUser.user.id,
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