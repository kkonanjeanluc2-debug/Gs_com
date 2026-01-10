import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseKey) {
      throw new Error("Missing Supabase configuration");
    }

    const supabase = createClient(supabaseUrl, supabaseKey);

    const payload = await req.json();

    console.log("PayDunya webhook received:", JSON.stringify(payload, null, 2));

    const invoiceToken = payload.data?.invoice_token || payload.invoice_token;
    const status = payload.data?.status || payload.status;
    const customData = payload.data?.custom_data || payload.custom_data;
    const orderId = customData?.order_id;

    if (!invoiceToken) {
      console.error("Missing invoice token in webhook");
      return new Response(
        JSON.stringify({ error: "Missing invoice token" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { data: transaction, error: transactionError } = await supabase
      .from("payment_transactions")
      .select("*")
      .eq("transaction_id", invoiceToken)
      .maybeSingle();

    if (transactionError) {
      console.error("Error fetching transaction:", transactionError);
      throw transactionError;
    }

    if (!transaction) {
      console.error("Transaction not found for invoice token:", invoiceToken);
      return new Response(
        JSON.stringify({ error: "Transaction not found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    let paymentStatus = "pending";
    if (status === "completed") {
      paymentStatus = "success";
    } else if (status === "cancelled") {
      paymentStatus = "cancelled";
    } else if (status === "failed") {
      paymentStatus = "failed";
    }

    const { error: updateError } = await supabase
      .from("payment_transactions")
      .update({
        status: paymentStatus,
        updated_at: new Date().toISOString(),
        metadata: {
          ...transaction.metadata,
          webhook_payload: payload,
          webhook_received_at: new Date().toISOString(),
        },
      })
      .eq("id", transaction.id);

    if (updateError) {
      console.error("Error updating transaction:", updateError);
      throw updateError;
    }

    if (paymentStatus === "success" && orderId) {
      const { data: order, error: orderError } = await supabase
        .from("orders")
        .select("*, client:clients(name, phone, email)")
        .eq("id", orderId)
        .maybeSingle();

      if (orderError) {
        console.error("Error fetching order:", orderError);
      } else if (order) {
        const { error: paymentError } = await supabase
          .from("order_payments")
          .insert({
            order_id: orderId,
            client_id: order.client_id,
            company_id: transaction.company_id,
            amount: transaction.amount,
            payment_method: "paydunya",
            payment_reference: invoiceToken,
            payment_date: new Date().toISOString(),
            notes: `Paiement PayDunya confirmé`,
            created_by: transaction.created_by || order.created_by,
          });

        if (paymentError) {
          console.error("Error creating payment record:", paymentError);
        } else {
          console.log("Payment record created successfully for order:", orderId);
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Webhook processed successfully",
        status: paymentStatus,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("PayDunya webhook error:", error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Internal server error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
