import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
};

interface RegisterCompanyRequest {
  companyName: string;
  companyEmail: string;
  companyPhone?: string;
  adminEmail: string;
  adminPassword: string;
  adminName: string;
}

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
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body: RegisterCompanyRequest = await req.json();
    const { companyName, companyEmail, companyPhone, adminEmail, adminPassword, adminName } = body;

    if (!companyName || !adminEmail || !adminPassword || !adminName) {
      return new Response(
        JSON.stringify({ error: 'Tous les champs obligatoires doivent être remplis' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    if (adminPassword.length < 6) {
      return new Response(
        JSON.stringify({ error: 'Le mot de passe doit contenir au moins 6 caractères' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    if (companyEmail) {
      const { data: existingCompany } = await supabase
        .from('companies')
        .select('id')
        .eq('email', companyEmail)
        .maybeSingle();

      if (existingCompany) {
        return new Response(
          JSON.stringify({ error: 'Cette adresse email est déjà utilisée par une autre entreprise' }),
          {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
      }
    }

    const { data: company, error: companyError } = await supabase
      .from('companies')
      .insert({
        name: companyName,
        email: companyEmail,
        phone: companyPhone || null,
        status: 'active',
        subscription_plan: 'free',
        max_users: 5,
        approved: false,
      })
      .select()
      .single();

    if (companyError || !company) {
      console.error('Error creating company:', companyError);
      return new Response(
        JSON.stringify({ error: 'Erreur lors de la création de l\'entreprise: ' + (companyError?.message || 'Erreur inconnue') }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: adminEmail,
      password: adminPassword,
      email_confirm: true,
      user_metadata: {
        full_name: adminName,
        role: 'admin',
        company_id: company.id,
      },
    });

    if (authError || !authData.user) {
      console.error('Error creating admin user:', authError);
      await supabase.from('companies').delete().eq('id', company.id);
      return new Response(
        JSON.stringify({ error: 'Erreur lors de la création de l\'utilisateur: ' + (authError?.message || 'Erreur inconnue') }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const { error: profileError } = await supabase
      .from('profiles')
      .update({
        full_name: adminName,
        role: 'admin',
        company_id: company.id,
      })
      .eq('id', authData.user.id);

    if (profileError) {
      console.error('Error updating profile:', profileError);
      await supabase.auth.admin.deleteUser(authData.user.id);
      await supabase.from('companies').delete().eq('id', company.id);
      return new Response(
        JSON.stringify({ error: 'Erreur lors de la configuration du profil: ' + (profileError?.message || 'Erreur inconnue') }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Entreprise créée avec succès. Votre compte est en attente d\'approbation par l\'administrateur.',
        company: {
          id: company.id,
          name: company.name,
          email: company.email,
        },
        pending_approval: true,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Unexpected error:', error);
    return new Response(
      JSON.stringify({ error: 'Erreur inattendue: ' + (error?.message || 'Erreur inconnue') }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});