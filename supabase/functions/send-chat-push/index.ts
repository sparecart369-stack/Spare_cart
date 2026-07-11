import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { JWT } from "https://esm.sh/google-auth-library@9.15.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type PushRequest = {
  thread_id?: string;
  sender_id?: string;
  message_text?: string;
};

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

function parseServiceAccount(raw: string): ServiceAccount {
  const parsed = JSON.parse(raw) as Record<string, unknown>;

  if (
    typeof parsed.private_key === "string" &&
    typeof parsed.client_email === "string" &&
    typeof parsed.project_id === "string"
  ) {
    return {
      project_id: parsed.project_id,
      client_email: parsed.client_email,
      private_key: parsed.private_key,
    };
  }

  if (typeof parsed.privateKeyData === "string") {
    const decoded = atob(parsed.privateKeyData);
    const fromKeyData = JSON.parse(decoded) as ServiceAccount;
    if (
      fromKeyData.private_key && fromKeyData.client_email &&
      fromKeyData.project_id
    ) {
      return fromKeyData;
    }
  }

  throw new Error("Invalid FIREBASE_SERVICE_ACCOUNT_JSON format");
}

async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const client = new JWT({
    email: serviceAccount.client_email,
    key: serviceAccount.private_key,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const credentials = await client.authorize();
  if (!credentials.access_token) {
    throw new Error("Failed to obtain FCM access token");
  }
  return credentials.access_token;
}

async function sendFcmMessage({
  projectId,
  accessToken,
  token,
  title,
  body,
  data,
}: {
  projectId: string;
  accessToken: string;
  token: string;
  title: string;
  body: string;
  data: Record<string, string>;
}) {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data,
          android: {
            priority: "HIGH",
            notification: {
              channel_id: "sparekart_messages",
              sound: "default",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
        },
      }),
    },
  );

  const payload = await response.json();
  return { ok: response.ok, status: response.status, payload };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const firebaseSaJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON") ?? "";

    if (!supabaseUrl || !serviceRoleKey || !firebaseSaJson) {
      return new Response(
        JSON.stringify({ error: "Push service is not configured" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const body = (await req.json()) as PushRequest;
    const threadId = String(body.thread_id ?? "").trim();
    const senderId = String(body.sender_id ?? "").trim();
    const messageText = String(body.message_text ?? "").trim();

    if (!threadId || !senderId) {
      return new Response(
        JSON.stringify({ error: "thread_id and sender_id are required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const { data: thread, error: threadError } = await supabase
      .from("message_threads")
      .select("id, buyer_id, seller_id, part_title")
      .eq("id", threadId)
      .maybeSingle();

    if (threadError || !thread) {
      return new Response(
        JSON.stringify({ error: "Thread not found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const recipientId = thread.buyer_id === senderId
      ? thread.seller_id
      : thread.buyer_id;

    if (!recipientId || recipientId === senderId) {
      return new Response(JSON.stringify({ sent: 0 }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const [{ data: sender }, { data: recipient }] = await Promise.all([
      supabase.from("profiles").select("name, fcm_tokens").eq("id", senderId).maybeSingle(),
      supabase
        .from("profiles")
        .select("fcm_tokens")
        .eq("id", recipientId)
        .maybeSingle(),
    ]);

    const senderTokens = new Set(
      ((sender?.fcm_tokens as string[] | null) ?? []).filter(Boolean),
    );
    const tokens = [
      ...new Set(
        ((recipient?.fcm_tokens as string[] | null) ?? []).filter(Boolean),
      ),
    ].filter((token) => !senderTokens.has(token));

    if (!tokens.length) {
      return new Response(JSON.stringify({ sent: 0, reason: "no_tokens" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const serviceAccount = parseServiceAccount(firebaseSaJson);
    const accessToken = await getAccessToken(serviceAccount);
    const title = (sender?.name as string | null)?.trim() || "New message";
    const preview = messageText ||
      ((thread.part_title as string | null)?.trim()
        ? `Message about ${thread.part_title}`
        : "You have a new message");

    const data = {
      type: "message",
      route: "/messages",
      thread_id: threadId,
      sender_id: senderId,
      recipient_id: String(recipientId),
    };

    const invalidTokens: string[] = [];
    let sent = 0;

    for (const token of tokens) {
      const result = await sendFcmMessage({
        projectId: serviceAccount.project_id,
        accessToken,
        token,
        title,
        body: preview.slice(0, 120),
        data,
      });

      if (result.ok) {
        sent += 1;
        continue;
      }

      const errorCode = (result.payload as { error?: { details?: Array<{ errorCode?: string }> } })
        ?.error?.details?.[0]?.errorCode;
      if (
        errorCode === "UNREGISTERED" ||
        errorCode === "INVALID_ARGUMENT"
      ) {
        invalidTokens.push(token);
      }
    }

    if (invalidTokens.length) {
      const remaining = tokens.filter((token) => !invalidTokens.includes(token));
      await supabase
        .from("profiles")
        .update({ fcm_tokens: remaining })
        .eq("id", recipientId);
    }

    return new Response(JSON.stringify({ sent, invalid: invalidTokens.length }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
