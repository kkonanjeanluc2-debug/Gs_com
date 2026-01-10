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
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const payload = await req.json();

    console.log('Wave webhook received:', payload);

    if (payload.type === 'checkout.session.completed') {
      const checkoutId = payload.data.id;
      const orderId = payload.data.metadata?.order_id;
      const amount = payload.data.amount;
      const currency = payload.data.currency;
      const status = payload.data.status;

      if (status === 'complete' && orderId) {
        const { data: order } = await supabase
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .single();

        if (order) {
          const { error: paymentError } = await supabase
            .from('order_payments')
            .insert({
              order_id: orderId,
              company_id: order.company_id,
              amount: amount / 100,
              payment_method: 'wave',
              payment_reference: checkoutId,
              payment_date: new Date().toISOString(),
              created_by: order.commercial_id || order.created_by,
            });

          if (paymentError) {
            console.error('Error creating payment:', paymentError);
          }

          const { data: payments } = await supabase
            .from('order_payments')
            .select('amount')
            .eq('order_id', orderId);

          const totalPaid = payments?.reduce((sum, p) => sum + Number(p.amount), 0) || 0;

          await supabase
            .from('orders')
            .update({ total_paid: totalPaid })
            .eq('id', orderId);
        }
      }
    }

    return new Response(
      JSON.stringify({ success: true }),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    );
  } catch (error) {
    console.error('Wave webhook error:', error);

    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    );
  }
});