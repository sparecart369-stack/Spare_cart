import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  corsHeaders,
  fetchCashfreeOrder,
  fetchCashfreeOrderPayments,
  getCashfreeCredentials,
  jsonResponse,
} from "../_shared/cashfree.ts";

type VerifyPaymentRequest = {
  thread_id?: string;
  cashfree_order_id?: string;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: authData, error: authError } = await userClient.auth.getUser();
    if (authError || !authData.user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const body = (await req.json()) as VerifyPaymentRequest;
    const threadId = String(body.thread_id ?? "").trim();
    const orderId = String(body.cashfree_order_id ?? "").trim();

    if (!threadId || !orderId) {
      return jsonResponse({ error: "Missing payment verification fields" }, 400);
    }

    const credentials = getCashfreeCredentials();

    const { data: paymentRow, error: paymentError } = await adminClient
      .from("chat_payments")
      .select("id, buyer_id, thread_id, status, amount_paise, token_amount, agreed_price")
      .eq("thread_id", threadId)
      .eq("cashfree_order_id", orderId)
      .maybeSingle();

    if (paymentError || !paymentRow) {
      return jsonResponse({ error: "Payment record not found" }, 404);
    }

    if (paymentRow.buyer_id !== authData.user.id) {
      return jsonResponse({ error: "Forbidden" }, 403);
    }

    if (paymentRow.status === "paid") {
      return jsonResponse({
        success: true,
        status: "paid",
        token_amount: paymentRow.token_amount,
        agreed_price: paymentRow.agreed_price,
      });
    }

    const cashfreeOrder = await fetchCashfreeOrder({
      orderId,
      credentials,
    });

    const orderStatus = String(cashfreeOrder.order_status ?? "").toUpperCase();
    if (orderStatus !== "PAID") {
      return jsonResponse({ error: "Payment is not completed yet" }, 400);
    }

    let paymentId = "";
    let paymentMethod = "";
    let paymentStatus = orderStatus;
    let paymentResponse: Record<string, unknown> = cashfreeOrder;

    try {
      const payments = await fetchCashfreeOrderPayments({ orderId, credentials });
      const latestPayment = payments.at(-1);
      if (latestPayment) {
        paymentId = String(latestPayment.cf_payment_id ?? latestPayment.payment_id ?? "");
        paymentMethod = String(latestPayment.payment_group ?? latestPayment.payment_method ?? "");
        paymentStatus = String(latestPayment.payment_status ?? orderStatus);
        paymentResponse = latestPayment;
      }
    } catch {
      // Keep order response if payment fetch fails.
    }

    const paidAt = new Date().toISOString();
    const { error: updateError } = await adminClient
      .from("chat_payments")
      .update({
        status: "paid",
        cashfree_payment_id: paymentId || null,
        cashfree_payment_status: paymentStatus,
        payment_method: paymentMethod,
        cashfree_payment_response: paymentResponse,
        paid_at: paidAt,
      })
      .eq("id", paymentRow.id);

    if (updateError) {
      return jsonResponse({ error: updateError.message }, 500);
    }

    await adminClient
      .from("message_threads")
      .update({ flow_step: "awaitingDeliveryChoice" })
      .eq("id", threadId);

    return jsonResponse({
      success: true,
      status: "paid",
      token_amount: paymentRow.token_amount,
      agreed_price: paymentRow.agreed_price,
      paid_at: paidAt,
    });
  } catch (error) {
    return jsonResponse({
      error: error instanceof Error ? error.message : "Unknown error",
    }, 500);
  }
});
