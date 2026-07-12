import { createHmac } from "node:crypto";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-razorpay-signature",
};

export type RazorpayCredentials = {
  keyId: string;
  keySecret: string;
  webhookSecret: string;
};

export function getRazorpayCredentials(): RazorpayCredentials {
  const keyId = Deno.env.get("RAZORPAY_KEY_ID") ?? "";
  const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET") ?? "";
  const webhookSecret = Deno.env.get("RAZORPAY_WEBHOOK_SECRET") ?? keySecret;

  if (!keyId || !keySecret) {
    throw new Error("Razorpay is not configured");
  }

  return { keyId, keySecret, webhookSecret };
}

export function tokenAmountPaise(agreedPrice: number): number {
  const paise = Math.round(agreedPrice * 0.01 * 100);
  return paise < 100 ? 100 : paise;
}

export function tokenAmountInr(agreedPrice: number): number {
  return tokenAmountPaise(agreedPrice) / 100;
}

export function verifyPaymentSignature({
  orderId,
  paymentId,
  signature,
  keySecret,
}: {
  orderId: string;
  paymentId: string;
  signature: string;
  keySecret: string;
}): boolean {
  const body = `${orderId}|${paymentId}`;
  const expected = createHmac("sha256", keySecret).update(body).digest("hex");
  return expected === signature;
}

export function verifyWebhookSignature({
  body,
  signature,
  webhookSecret,
}: {
  body: string;
  signature: string;
  webhookSecret: string;
}): boolean {
  const expected = createHmac("sha256", webhookSecret).update(body).digest(
    "hex",
  );
  return expected === signature;
}

export async function createRazorpayOrder({
  amountPaise,
  receipt,
  notes,
  keyId,
  keySecret,
}: {
  amountPaise: number;
  receipt: string;
  notes: Record<string, string>;
  keyId: string;
  keySecret: string;
}) {
  const auth = btoa(`${keyId}:${keySecret}`);
  const response = await fetch("https://api.razorpay.com/v1/orders", {
    method: "POST",
    headers: {
      Authorization: `Basic ${auth}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: amountPaise,
      currency: "INR",
      receipt,
      notes,
    }),
  });

  const payload = await response.json();
  if (!response.ok) {
    const message = (payload as { error?: { description?: string } })?.error
      ?.description ?? "Failed to create Razorpay order";
    throw new Error(message);
  }

  return payload as {
    id: string;
    amount: number;
    currency: string;
    receipt: string;
  };
}

export async function createRazorpayRefund({
  paymentId,
  amountPaise,
  keyId,
  keySecret,
}: {
  paymentId: string;
  amountPaise: number;
  keyId: string;
  keySecret: string;
}) {
  const auth = btoa(`${keyId}:${keySecret}`);
  const response = await fetch(
    `https://api.razorpay.com/v1/payments/${paymentId}/refund`,
    {
      method: "POST",
      headers: {
        Authorization: `Basic ${auth}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        amount: amountPaise,
      }),
    },
  );

  const payload = await response.json();
  if (!response.ok) {
    const message = (payload as { error?: { description?: string } })?.error
      ?.description ?? "Failed to create Razorpay refund";
    throw new Error(message);
  }

  return payload as { id: string; status: string };
}

export async function fetchRazorpayPayment({
  paymentId,
  keyId,
  keySecret,
}: {
  paymentId: string;
  keyId: string;
  keySecret: string;
}) {
  const auth = btoa(`${keyId}:${keySecret}`);
  const response = await fetch(
    `https://api.razorpay.com/v1/payments/${paymentId}`,
    {
      headers: {
        Authorization: `Basic ${auth}`,
      },
    },
  );

  const payload = await response.json();
  if (!response.ok) {
    const message = (payload as { error?: { description?: string } })?.error
      ?.description ?? "Failed to fetch Razorpay payment";
    throw new Error(message);
  }

  return payload as Record<string, unknown>;
}

export function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
