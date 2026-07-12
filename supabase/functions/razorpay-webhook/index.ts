import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  fetchRazorpayPayment,
  getRazorpayCredentials,
  jsonResponse,
  verifyWebhookSignature,
} from "../_shared/razorpay.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const rawBody = await req.text();
    const signature = req.headers.get("x-razorpay-signature") ?? "";
    const credentials = getRazorpayCredentials();

    if (
      !verifyWebhookSignature({
        body: rawBody,
        signature,
        webhookSecret: credentials.webhookSecret,
      })
    ) {
      return jsonResponse({ error: "Invalid webhook signature" }, 400);
    }

    const event = JSON.parse(rawBody) as {
      event?: string;
      payload?: {
        payment?: {
          entity?: Record<string, unknown>;
        };
      };
    };

    const paymentEntity = event.payload?.payment?.entity;
    const orderId = String(paymentEntity?.order_id ?? "");
    const paymentId = String(paymentEntity?.id ?? "");

    if (!orderId || !paymentId) {
      return jsonResponse({ received: true });
    }

    if (event.event !== "payment.captured" && paymentEntity?.status !== "captured") {
      return jsonResponse({ received: true });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: existing } = await adminClient
      .from("chat_payments")
      .select("id, razorpay_webhook_events")
      .eq("razorpay_order_id", orderId)
      .maybeSingle();

    if (!existing) {
      return jsonResponse({ received: true });
    }

    const webhookEvents = Array.isArray(existing.razorpay_webhook_events)
      ? existing.razorpay_webhook_events
      : [];

    let paymentDetails = paymentEntity;
    try {
      paymentDetails = await fetchRazorpayPayment({
        paymentId,
        keyId: credentials.keyId,
        keySecret: credentials.keySecret,
      });
    } catch {
      // Keep webhook entity if fetch fails.
    }

    const paidAt = new Date().toISOString();
    const { data: paymentRow } = await adminClient
      .from("chat_payments")
      .update({
        status: "paid",
        razorpay_payment_id: paymentId,
        razorpay_payment_status: String(paymentDetails.status ?? "captured"),
        payment_method: String(paymentDetails.method ?? ""),
        razorpay_payment_response: paymentDetails,
        razorpay_webhook_events: [
          ...webhookEvents,
          { event: event.event, received_at: paidAt, payload: event },
        ],
        paid_at: paidAt,
      })
      .eq("razorpay_order_id", orderId)
      .neq("status", "paid")
      .select("thread_id")
      .maybeSingle();

    if (paymentRow?.thread_id) {
      await adminClient
        .from("message_threads")
        .update({ flow_step: "awaitingDeliveryChoice" })
        .eq("id", paymentRow.thread_id);
    }

    return jsonResponse({ received: true });
  } catch (error) {
    return jsonResponse({
      error: error instanceof Error ? error.message : "Unknown error",
    }, 500);
  }
});
