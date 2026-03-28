// Supabase Edge Function: notify-investors
// Triggered by a database webhook on INSERT to the transactions table.
// Sends FCM v1 push notifications to co-investors when a new transaction is added.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface TransactionRecord {
  id: string;
  property_id: string;
  type: string;
  category: string;
  amount: number;
  paid_by: string | null;
  is_auto_generated: boolean;
  created_by: string;
}

interface ServiceAccount {
  project_id: string;
  private_key: string;
  client_email: string;
}

/**
 * Create a signed JWT for Google OAuth2 using the service account.
 */
async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const encode = (obj: unknown) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");

  const unsignedToken = `${encode(header)}.${encode(payload)}`;

  // Import the RSA private key
  const pemBody = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const keyData = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedToken)
  );

  const sig = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  const jwt = `${unsignedToken}.${sig}`;

  // Exchange JWT for access token
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenRes.json();
  return tokenData.access_token;
}

serve(async (req: Request) => {
  try {
    const payload = await req.json();
    const transaction: TransactionRecord = payload.record;

    // Skip auto-generated transactions (e.g. mortgage payments from pg_cron)
    if (transaction.is_auto_generated) {
      return new Response(
        JSON.stringify({ skipped: true, reason: "auto_generated" }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Get property name
    const { data: property } = await supabase
      .from("properties")
      .select("name")
      .eq("id", transaction.property_id)
      .single();

    if (!property) {
      return new Response(JSON.stringify({ error: "Property not found" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Get the payer's name (if paid_by is set)
    let paidByName = "Someone";
    if (transaction.paid_by) {
      const { data: investor } = await supabase
        .from("investors")
        .select("name")
        .eq("id", transaction.paid_by)
        .single();
      if (investor) {
        paidByName = investor.name;
      }
    }

    // Get all accepted investors on this property, excluding the creator
    const { data: investors } = await supabase
      .from("investors")
      .select("user_id")
      .eq("property_id", transaction.property_id)
      .eq("invitation_status", "accepted")
      .not("user_id", "is", null)
      .neq("user_id", transaction.created_by);

    if (!investors || investors.length === 0) {
      return new Response(
        JSON.stringify({ sent: 0, reason: "no_recipients" }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    const userIds = investors.map((i: { user_id: string }) => i.user_id);

    // Get FCM tokens for these users
    const { data: tokens } = await supabase
      .from("push_tokens")
      .select("token")
      .in_("user_id", userIds);

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ sent: 0, reason: "no_tokens" }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    // Format category label
    const categoryLabel = transaction.category
      .replace(/-/g, " ")
      .replace(/\b\w/g, (c: string) => c.toUpperCase());

    // Format amount
    const amount = new Intl.NumberFormat("en-CA", {
      style: "currency",
      currency: "CAD",
    }).format(transaction.amount);

    // Get FCM v1 access token from service account
    const serviceAccount: ServiceAccount = JSON.parse(
      Deno.env.get("FCM_SERVICE_ACCOUNT")!
    );
    const accessToken = await getAccessToken(serviceAccount);
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;

    // Send FCM v1 notifications
    const notifications = tokens.map((t: { token: string }) =>
      fetch(fcmUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: t.token,
            notification: {
              title: `New transaction on ${property.name}`,
              body: `${paidByName} added a ${categoryLabel} of ${amount} — check your balance`,
            },
            data: {
              propertyId: transaction.property_id,
              transactionId: transaction.id,
              screen: "balances",
            },
          },
        }),
      })
    );

    const results = await Promise.allSettled(notifications);
    const sent = results.filter((r) => r.status === "fulfilled").length;

    return new Response(JSON.stringify({ sent }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
