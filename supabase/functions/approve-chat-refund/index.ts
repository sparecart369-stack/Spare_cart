import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  corsHeaders,
  createRazorpayRefund,
  getRazorpayCredentials,
  jsonResponse,
} from "../_shared/razorpay.ts";

type ApproveRefundRequest = {
  payment_id?: string;
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

    const { data: profile } = await adminClient
      .from("profiles")
      .select("role")
      .eq("id", authData.user.id)
      .maybeSingle();

    if (profile?.role !== "admin") {
      return jsonResponse({ error: "Admin access required" }, 403);
    }

    const body = (await req.json()) as ApproveRefundRequest;
    const paymentId = String(body.payment_id ?? "").trim();
    if (!paymentId) {
      return jsonResponse({ error: "payment_id is required" }, 400);
    }

    const { data: paymentRow, error: paymentError } = await adminClient
      .from("chat_payments")
      .select("id, status, razorpay_payment_id, amount_paise")
      .eq("id", paymentId)
      .maybeSingle();

    if (paymentError || !paymentRow) {
      return jsonResponse({ error: "Payment not found" }, 404);
    }

    if (paymentRow.status !== "refund_requested") {
      return jsonResponse({ error: "Payment is not awaiting refund approval" }, 400);
    }

    if (!paymentRow.razorpay_payment_id) {
      return jsonResponse({ error: "Missing Razorpay payment id" }, 400);
    }

    const credentials = getRazorpayCredentials();
    const refund = await createRazorpayRefund({
      paymentId: paymentRow.razorpay_payment_id,
      amountPaise: paymentRow.amount_paise,
      keyId: credentials.keyId,
      keySecret: credentials.keySecret,
    });

    const approvedAt = new Date().toISOString();
    const { error: updateError } = await adminClient
      .from("chat_payments")
      .update({
        status: "refunded",
        refund_approved_by: authData.user.id,
        refund_approved_at: approvedAt,
        razorpay_refund_id: refund.id,
        razorpay_refund_response: refund,
      })
      .eq("id", paymentRow.id);

    if (updateError) {
      return jsonResponse({ error: updateError.message }, 500);
    }

    return jsonResponse({
      success: true,
      refund_id: refund.id,
      status: "refunded",
    });
  } catch (error) {
    return jsonResponse({
      error: error instanceof Error ? error.message : "Unknown error",
    }, 500);
  }
});
