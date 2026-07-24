import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  fetchCashfreeOrderPayments,
  getCashfreeCredentials,
  jsonResponse,
  verifyWebhookSignature,
} from "../_shared/cashfree.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const rawBody = await req.text();
    const signature = req.headers.get("x-webhook-signature") ?? "";
    const timestamp = req.headers.get("x-webhook-timestamp") ?? "";
    const credentials = getCashfreeCredentials();

    if (
      !verifyWebhookSignature({
        body: rawBody,
        signature,
        timestamp,
        secretKey: credentials.secretKey,
      })
    ) {
      return jsonResponse({ error: "Invalid webhook signature" }, 400);
    }

    const event = JSON.parse(rawBody) as {
      type?: string;
      data?: {
        order?: Record<string, unknown>;
        payment?: Record<string, unknown>;
      };
    };

    const orderId = String(
      event.data?.order?.order_id ??
        event.data?.payment?.order_id ??
        "",
    );

    if (!orderId) {
      return jsonResponse({ received: true });
    }

    const eventType = String(event.type ?? "").toUpperCase();
    const paymentStatus = String(event.data?.payment?.payment_status ?? "").toUpperCase();
    const isPaidEvent = eventType.includes("SUCCESS") ||
      paymentStatus === "SUCCESS" ||
      paymentStatus === "PAID";

    if (!isPaidEvent) {
      return jsonResponse({ received: true });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: existing } = await adminClient
      .from("chat_payments")
      .select("id, cashfree_webhook_events")
      .eq("cashfree_order_id", orderId)
      .maybeSingle();

    if (!existing) {
      return jsonResponse({ received: true });
    }

    const webhookEvents = Array.isArray(existing.cashfree_webhook_events)
      ? existing.cashfree_webhook_events
      : [];

    let paymentDetails = event.data?.payment ?? {};
    let paymentId = String(paymentDetails.cf_payment_id ?? paymentDetails.payment_id ?? "");
    let paymentMethod = String(
      paymentDetails.payment_group ?? paymentDetails.payment_method ?? "",
    );

    try {
      const payments = await fetchCashfreeOrderPayments({
        orderId,
        credentials,
      });
      const latestPayment = payments.at(-1);
      if (latestPayment) {
        paymentDetails = latestPayment;
        paymentId = String(latestPayment.cf_payment_id ?? latestPayment.payment_id ?? paymentId);
        paymentMethod = String(
          latestPayment.payment_group ?? latestPayment.payment_method ?? paymentMethod,
        );
      }
    } catch {
      // Keep webhook payload if fetch fails.
    }

    const paidAt = new Date().toISOString();
    const { data: paymentRow } = await adminClient
      .from("chat_payments")
      .update({
        status: "paid",
        cashfree_payment_id: paymentId || null,
        cashfree_payment_status: String(paymentDetails.payment_status ?? "PAID"),
        payment_method: paymentMethod,
        cashfree_payment_response: paymentDetails,
        cashfree_webhook_events: [
          ...webhookEvents,
          { event: eventType, received_at: paidAt, payload: event },
        ],
        paid_at: paidAt,
      })
      .eq("cashfree_order_id", orderId)
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
