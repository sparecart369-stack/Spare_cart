import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  corsHeaders,
  createCashfreeOrder,
  getCashfreeCredentials,
  jsonResponse,
  tokenAmountInr,
  tokenAmountPaise,
} from "../_shared/cashfree.ts";

type CreateOrderRequest = {
  thread_id?: string;
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

    const body = (await req.json()) as CreateOrderRequest;
    const threadId = String(body.thread_id ?? "").trim();
    if (!threadId) {
      return jsonResponse({ error: "thread_id is required" }, 400);
    }

    const { data: thread, error: threadError } = await userClient
      .from("message_threads")
      .select(`
        id,
        buyer_id,
        seller_id,
        listing_id,
        agreed_price,
        part_title,
        buyer:profiles!buyer_id (name),
        seller:profiles!seller_id (name)
      `)
      .eq("id", threadId)
      .maybeSingle();

    if (threadError || !thread) {
      return jsonResponse({ error: "Thread not found" }, 404);
    }

    if (thread.buyer_id !== authData.user.id) {
      return jsonResponse({ error: "Only the buyer can create a payment" }, 403);
    }

    const agreedPrice = Number(thread.agreed_price ?? 0);
    if (!Number.isFinite(agreedPrice) || agreedPrice <= 0) {
      return jsonResponse({ error: "Agreed price is not set" }, 400);
    }

    const { data: existingPaid } = await adminClient
      .from("chat_payments")
      .select("id, status, cashfree_order_id, amount_paise, token_amount")
      .eq("thread_id", threadId)
      .eq("status", "paid")
      .maybeSingle();

    if (existingPaid) {
      return jsonResponse({ error: "Payment already completed for this chat" }, 409);
    }

    const amountPaise = tokenAmountPaise(agreedPrice);
    const tokenAmount = tokenAmountInr(agreedPrice);

    const buyerProfile = thread.buyer as Record<string, unknown> | null;
    const sellerProfile = thread.seller as Record<string, unknown> | null;
    const buyerName = String(buyerProfile?.name ?? "");
    const sellerName = String(sellerProfile?.name ?? "");

    const { data: existingPending } = await adminClient
      .from("chat_payments")
      .select(
        "id, cashfree_order_id, cashfree_payment_session_id, amount_paise, token_amount, agreed_price",
      )
      .eq("thread_id", threadId)
      .eq("status", "pending")
      .eq("amount_paise", amountPaise)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    const credentials = getCashfreeCredentials();

    if (existingPending?.cashfree_order_id && existingPending.cashfree_payment_session_id) {
      const { data: buyerProfileRow } = await adminClient
        .from("profiles")
        .select("name, phone")
        .eq("id", thread.buyer_id)
        .maybeSingle();

      return jsonResponse({
        app_id: credentials.appId,
        order_id: existingPending.cashfree_order_id,
        payment_session_id: existingPending.cashfree_payment_session_id,
        amount_paise: existingPending.amount_paise,
        token_amount: existingPending.token_amount,
        agreed_price: existingPending.agreed_price,
        currency: "INR",
        payment_id: existingPending.id,
        token_percent: 0.01,
        description: `Advance token (1%) for ${thread.part_title ?? "item"}`,
        prefill: {
          name: (buyerProfileRow?.name as string | null) ?? buyerName,
          contact: (buyerProfileRow?.phone as string | null) ?? "",
        },
      });
    }

    const orderId = `chat_${threadId.replace(/-/g, "").slice(0, 12)}_${Date.now()}`;
    const orderNote = `Advance token (1%) for ${thread.part_title ?? "item"}`;
    const returnUrl = Deno.env.get("CASHFREE_RETURN_URL") ??
      "https://sparekart.app/payment-return";

    const { data: buyerProfileRow } = await adminClient
      .from("profiles")
      .select("name, phone")
      .eq("id", thread.buyer_id)
      .maybeSingle();

    const customerPhone = String(buyerProfileRow?.phone ?? "").replace(/\D/g, "");
    const normalizedPhone = customerPhone.length >= 10
      ? customerPhone.slice(-10)
      : "9999999999";

    const cashfreeOrder = await createCashfreeOrder({
      orderId,
      amountInr: tokenAmount,
      customerId: thread.buyer_id,
      customerName: String(buyerProfileRow?.name ?? buyerName) || "SpareKart buyer",
      customerPhone: normalizedPhone,
      orderNote,
      returnUrl: `${returnUrl}?order_id=${orderId}`,
      credentials,
    });

    const { data: paymentRow, error: insertError } = await adminClient
      .from("chat_payments")
      .insert({
        thread_id: threadId,
        listing_id: thread.listing_id,
        part_title: thread.part_title ?? "",
        buyer_id: thread.buyer_id,
        seller_id: thread.seller_id,
        buyer_name: buyerName,
        seller_name: sellerName,
        agreed_price: agreedPrice,
        token_amount: tokenAmount,
        token_percent: 0.01,
        amount_paise: amountPaise,
        currency: "INR",
        cashfree_order_id: cashfreeOrder.order_id,
        cashfree_payment_session_id: cashfreeOrder.payment_session_id,
        cashfree_order_note: orderNote,
        cashfree_order_response: cashfreeOrder,
        status: "pending",
      })
      .select(
        "id, cashfree_order_id, cashfree_payment_session_id, amount_paise, token_amount, agreed_price",
      )
      .single();

    if (insertError || !paymentRow) {
      return jsonResponse({ error: insertError?.message ?? "Failed to save payment" }, 500);
    }

    return jsonResponse({
      app_id: credentials.appId,
      order_id: paymentRow.cashfree_order_id,
      payment_session_id: paymentRow.cashfree_payment_session_id,
      amount_paise: paymentRow.amount_paise,
      token_amount: paymentRow.token_amount,
      agreed_price: paymentRow.agreed_price,
      token_percent: 0.01,
      currency: "INR",
      payment_id: paymentRow.id,
      description: orderNote,
      prefill: {
        name: (buyerProfileRow?.name as string | null) ?? buyerName,
        contact: (buyerProfileRow?.phone as string | null) ?? "",
      },
    });
  } catch (error) {
    return jsonResponse({
      error: error instanceof Error ? error.message : "Unknown error",
    }, 500);
  }
});
