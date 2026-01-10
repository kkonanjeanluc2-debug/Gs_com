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
    const provider = new URL(req.url).searchParams.get('provider');

    console.log(`${provider} webhook received:`, payload);

    let transactionId: string | null = null;
    let orderId: string | null = null;
    let amount: number = 0;
    let status: string = '';

    if (provider === 'orange_money') {
      transactionId = payload.transaction_id || payload.id;
      orderId = payload.reference || payload.merchant_reference;
      amount = payload.amount;
      status = payload.status;
    } else if (provider === 'mtn_money') {
      transactionId = payload.financialTransactionId;
      orderId = payload.externalId;
      amount = payload.amount;
      status = payload.status;
    } else if (provider === 'moov_money') {
      transactionId = payload.transaction_id;
      orderId = payload.reference;
      amount = payload.amount;
      status = payload.status;
    }

    if ((status === 'successful' || status === 'success' || status === 'SUCCESSFUL') && orderId) {
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
            amount: amount,
            payment_method: provider || 'mobile_money',
            payment_reference: transactionId,
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
    console.error('Mobile Money webhook error:', error);

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