import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'npm:@supabase/supabase-js@2.89.0';

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface UpdateEmailRequest {
  currentPassword: string;
  newEmail: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const authHeader = req.headers.get('Authorization');

    if (!authHeader) {
      throw new Error('Autorisation requise');
    }

    const token = authHeader.replace('Bearer ', '');
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token);
    if (userError || !user) {
      throw new Error('Utilisateur non authentifié');
    }

    const { currentPassword, newEmail }: UpdateEmailRequest = await req.json();

    if (!currentPassword || !newEmail) {
      throw new Error('Mot de passe et nouvel email requis');
    }

    const { error: signInError } = await supabaseAdmin.auth.signInWithPassword({
      email: user.email!,
      password: currentPassword,
    });

    if (signInError) {
      throw new Error('Mot de passe incorrect');
    }

    const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(user.id, {
      email: newEmail,
    });

    if (updateError) {
      throw updateError;
    }

    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .update({ email: newEmail })
      .eq('id', user.id);

    if (profileError) {
      console.error('Error updating profile:', profileError);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Email mis à jour avec succès'
      }),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
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