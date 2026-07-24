import { createHmac } from "node:crypto";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-webhook-signature, x-webhook-timestamp",
};

export const CASHFREE_API_VERSION = "2023-08-01";

export type CashfreeCredentials = {
  appId: string;
  secretKey: string;
};

export function getCashfreeCredentials(): CashfreeCredentials {
  const appId = Deno.env.get("CASHFREE_APP_ID") ?? "";
  const secretKey = Deno.env.get("CASHFREE_SECRET_KEY") ?? "";

  if (!appId || !secretKey) {
    throw new Error("Cashfree is not configured");
  }

  return { appId, secretKey };
}

export function cashfreeBaseUrl(): string {
  const env = (Deno.env.get("CASHFREE_ENV") ?? "production").toLowerCase();
  return env === "sandbox"
    ? "https://sandbox.cashfree.com/pg"
    : "https://api.cashfree.com/pg";
}

export function tokenAmountPaise(agreedPrice: number): number {
  const paise = Math.round(agreedPrice * 0.01 * 100);
  return paise < 100 ? 100 : paise;
}

export function tokenAmountInr(agreedPrice: number): number {
  return tokenAmountPaise(agreedPrice) / 100;
}

export function verifyWebhookSignature({
  body,
  signature,
  timestamp,
  secretKey,
}: {
  body: string;
  signature: string;
  timestamp: string;
  secretKey: string;
}): boolean {
  const payload = `${timestamp}${body}`;
  const expected = createHmac("sha256", secretKey)
    .update(payload)
    .digest("base64");
  return expected === signature;
}

function cashfreeHeaders(credentials: CashfreeCredentials) {
  return {
    "x-client-id": credentials.appId,
    "x-client-secret": credentials.secretKey,
    "x-api-version": CASHFREE_API_VERSION,
    "Content-Type": "application/json",
    Accept: "application/json",
  };
}

export async function createCashfreeOrder({
  orderId,
  amountInr,
  customerId,
  customerName,
  customerPhone,
  orderNote,
  returnUrl,
  credentials,
}: {
  orderId: string;
  amountInr: number;
  customerId: string;
  customerName: string;
  customerPhone: string;
  orderNote: string;
  returnUrl: string;
  credentials: CashfreeCredentials;
}) {
  const response = await fetch(`${cashfreeBaseUrl()}/orders`, {
    method: "POST",
    headers: cashfreeHeaders(credentials),
    body: JSON.stringify({
      order_id: orderId,
      order_amount: amountInr,
      order_currency: "INR",
      customer_details: {
        customer_id: customerId,
        customer_name: customerName,
        customer_phone: customerPhone,
      },
      order_meta: {
        return_url: returnUrl,
      },
      order_note: orderNote,
    }),
  });

  const payload = await response.json();
  if (!response.ok) {
    const message = (payload as { message?: string })?.message ??
      (payload as { error?: { message?: string } })?.error?.message ??
      "Failed to create Cashfree order";
    throw new Error(message);
  }

  return payload as {
    order_id: string;
    payment_session_id: string;
    order_status: string;
    order_amount: number;
    order_currency: string;
  };
}

export async function fetchCashfreeOrder({
  orderId,
  credentials,
}: {
  orderId: string;
  credentials: CashfreeCredentials;
}) {
  const response = await fetch(`${cashfreeBaseUrl()}/orders/${orderId}`, {
    headers: cashfreeHeaders(credentials),
  });

  const payload = await response.json();
  if (!response.ok) {
    const message = (payload as { message?: string })?.message ??
      "Failed to fetch Cashfree order";
    throw new Error(message);
  }

  return payload as Record<string, unknown>;
}

export async function fetchCashfreeOrderPayments({
  orderId,
  credentials,
}: {
  orderId: string;
  credentials: CashfreeCredentials;
}) {
  const response = await fetch(`${cashfreeBaseUrl()}/orders/${orderId}/payments`, {
    headers: cashfreeHeaders(credentials),
  });

  const payload = await response.json();
  if (!response.ok) {
    const message = (payload as { message?: string })?.message ??
      "Failed to fetch Cashfree payments";
    throw new Error(message);
  }

  return payload as Array<Record<string, unknown>>;
}

export async function createCashfreeRefund({
  orderId,
  refundId,
  amountInr,
  credentials,
}: {
  orderId: string;
  refundId: string;
  amountInr: number;
  credentials: CashfreeCredentials;
}) {
  const response = await fetch(`${cashfreeBaseUrl()}/orders/${orderId}/refunds`, {
    method: "POST",
    headers: cashfreeHeaders(credentials),
    body: JSON.stringify({
      refund_id: refundId,
      refund_amount: amountInr,
      refund_note: "SpareKart chat token refund",
      refund_speed: "STANDARD",
    }),
  });

  const payload = await response.json();
  if (!response.ok) {
    const message = (payload as { message?: string })?.message ??
      "Failed to create Cashfree refund";
    throw new Error(message);
  }

  return payload as { cf_refund_id?: string; refund_id?: string; refund_status?: string };
}

export function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
