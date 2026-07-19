import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const productMap = {
  lappo_pro_monthly: {
    kind: 'subscription',
    plan: 'pro',
    period: 'monthly',
    amount: 7900,
  },
  lappo_pro_yearly: {
    kind: 'subscription',
    plan: 'pro',
    period: 'yearly',
    amount: 79900,
  },
  lappo_pro_plus_monthly: {
    kind: 'subscription',
    plan: 'pro_plus',
    period: 'monthly',
    amount: 49900,
  },
  lappo_pro_plus_yearly: {
    kind: 'subscription',
    plan: 'pro_plus',
    period: 'yearly',
    amount: 499900,
  },
  lappo_listing_standard: {
    kind: 'listing',
    tier: 'standard',
    amount: 4000,
  },
  lappo_listing_top_7: {
    kind: 'listing',
    tier: 'top_7',
    amount: 8000,
  },
  lappo_listing_top_15: {
    kind: 'listing',
    tier: 'top_15',
    amount: 15000,
  },
} as const;

type ProductId = keyof typeof productMap;
type StoreSource = 'apple' | 'google';

interface VerifiedPurchase {
  transactionId: string;
  purchasedAt: string;
  expiresAt?: string;
  environment: 'production' | 'sandbox';
  active: boolean;
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') return json({ error: 'METHOD_NOT_ALLOWED' }, 405);

  try {
    const authorization = request.headers.get('Authorization');
    if (!authorization) return json({ error: 'UNAUTHORIZED' }, 401);

    const supabaseUrl = requiredEnv('SUPABASE_URL');
    const anonKey = requiredEnv('SUPABASE_ANON_KEY');
    const serviceRoleKey = requiredEnv('SUPABASE_SERVICE_ROLE_KEY');
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();
    if (userError || !user) return json({ error: 'UNAUTHORIZED' }, 401);

    const body = await request.json();
    const productId = String(body.product_id ?? '') as ProductId;
    const source = String(body.source ?? '') as StoreSource;
    const verificationData = String(body.verification_data ?? '');
    const product = productMap[productId];
    if (!product || !['apple', 'google'].includes(source) || !verificationData) {
      return json({ error: 'INVALID_REQUEST' }, 400);
    }

    const verified = source === 'apple'
      ? await verifyApple(productId, verificationData)
      : await verifyGoogle(productId, verificationData, product.kind);
    if (!verified.active) return json({ error: 'PURCHASE_NOT_ACTIVE' }, 402);

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });
    const { data: existingTransaction, error: existingError } = await admin
      .from('owner_billing_transactions')
      .select('id,user_id')
      .eq('provider', source)
      .eq('provider_transaction_id', verified.transactionId)
      .maybeSingle();
    if (existingError) throw existingError;
    if (existingTransaction && existingTransaction.user_id !== user.id) {
      return json({ error: 'PURCHASE_ALREADY_OWNED' }, 409);
    }

    let transaction = existingTransaction;
    if (!transaction) {
      const { data, error: transactionError } = await admin
        .from('owner_billing_transactions')
        .insert({
          user_id: user.id,
          provider: source,
          provider_transaction_id: verified.transactionId,
          product_id: productId,
          purchase_kind: product.kind,
          status: 'verified',
          amount_minor: product.amount,
          currency: 'UAH',
          purchased_at: verified.purchasedAt,
          verified_at: new Date().toISOString(),
          expires_at: verified.expiresAt ?? null,
          environment: verified.environment,
        })
        .select('id,user_id')
        .single();
      if (transactionError) throw transactionError;
      transaction = data;
    }

    if (product.kind === 'subscription') {
      const now = new Date().toISOString();
      const fallbackExpiry = new Date();
      if (product.period === 'yearly') {
        fallbackExpiry.setFullYear(fallbackExpiry.getFullYear() + 1);
      } else {
        fallbackExpiry.setMonth(fallbackExpiry.getMonth() + 1);
      }
      const { error } = await admin.from('owner_entitlements').upsert({
        user_id: user.id,
        plan_code: product.plan,
        status: 'active',
        billing_period: product.period,
        provider: source,
        product_id: productId,
        provider_entitlement_id: verified.transactionId,
        current_period_start: now,
        current_period_end: verified.expiresAt ?? fallbackExpiry.toISOString(),
        updated_at: now,
      });
      if (error) throw error;
    } else {
      const { error } = await admin.from('owner_listing_credits').upsert(
        {
          user_id: user.id,
          transaction_id: transaction.id,
          tier: product.tier,
          status: 'available',
        },
        { onConflict: 'transaction_id' },
      );
      if (error) throw error;
    }

    await admin.from('platform_analytics_events').insert({
      user_id: user.id,
      event_name: product.kind === 'subscription'
        ? 'subscription_verified'
        : 'listing_credit_purchased',
      entity_type: product.kind,
      properties: {
        product_id: productId,
        provider: source,
        environment: verified.environment,
      },
    });

    return json({
      ok: true,
      kind: product.kind,
      transaction_id: transaction.id,
    });
  } catch (error) {
    console.error(error);
    return json({ error: 'VERIFICATION_FAILED' }, 500);
  }
});

async function verifyApple(
  productId: ProductId,
  receiptData: string,
): Promise<VerifiedPurchase> {
  const sharedSecret = requiredEnv('APPLE_SHARED_SECRET');
  let environment: 'production' | 'sandbox' = 'production';
  let response = await postAppleReceipt(
    'https://buy.itunes.apple.com/verifyReceipt',
    receiptData,
    sharedSecret,
  );
  if (response.status === 21007) {
    environment = 'sandbox';
    response = await postAppleReceipt(
      'https://sandbox.itunes.apple.com/verifyReceipt',
      receiptData,
      sharedSecret,
    );
  }
  if (response.status !== 0) throw new Error(`APPLE_STATUS_${response.status}`);

  const entries = [
    ...(Array.isArray(response.latest_receipt_info)
      ? response.latest_receipt_info
      : []),
    ...(Array.isArray(response.receipt?.in_app) ? response.receipt.in_app : []),
  ].filter((item) => item.product_id === productId);
  entries.sort(
    (a, b) =>
      Number(b.expires_date_ms ?? b.purchase_date_ms ?? 0) -
      Number(a.expires_date_ms ?? a.purchase_date_ms ?? 0),
  );
  const item = entries[0];
  if (!item?.transaction_id) throw new Error('APPLE_PRODUCT_NOT_FOUND');
  const expiresAt = item.expires_date_ms
    ? new Date(Number(item.expires_date_ms)).toISOString()
    : undefined;
  const cancelled = Boolean(item.cancellation_date_ms);
  return {
    transactionId: String(item.transaction_id),
    purchasedAt: new Date(Number(item.purchase_date_ms)).toISOString(),
    expiresAt,
    environment,
    active: !cancelled && (!expiresAt || new Date(expiresAt) > new Date()),
  };
}

async function postAppleReceipt(
  url: string,
  receiptData: string,
  password: string,
) {
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      'receipt-data': receiptData,
      password,
      'exclude-old-transactions': true,
    }),
  });
  if (!response.ok) throw new Error('APPLE_NETWORK_ERROR');
  return await response.json();
}

async function verifyGoogle(
  productId: ProductId,
  purchaseToken: string,
  kind: 'subscription' | 'listing',
): Promise<VerifiedPurchase> {
  const accessToken = await googleAccessToken();
  const packageName = Deno.env.get('GOOGLE_PACKAGE_NAME') ?? 'com.lappo.app';
  if (kind === 'subscription') {
    const url =
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`;
    const data = await googleGet(url, accessToken);
    const item = data.lineItems?.find(
      (line: Record<string, unknown>) => line.productId === productId,
    );
    if (!item) throw new Error('GOOGLE_PRODUCT_NOT_FOUND');
    const activeStates = new Set([
      'SUBSCRIPTION_STATE_ACTIVE',
      'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
    ]);
    return {
      transactionId: String(
        data.latestOrderId ?? data.linkedPurchaseToken ?? purchaseToken,
      ),
      purchasedAt: data.startTime ?? new Date().toISOString(),
      expiresAt: item.expiryTime,
      environment: data.testPurchase ? 'sandbox' : 'production',
      active: activeStates.has(data.subscriptionState),
    };
  }

  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/products/${productId}/tokens/${encodeURIComponent(purchaseToken)}`;
  const data = await googleGet(url, accessToken);
  return {
    transactionId: String(data.orderId ?? purchaseToken),
    purchasedAt: new Date(Number(data.purchaseTimeMillis)).toISOString(),
    environment: data.purchaseType === 0 ? 'sandbox' : 'production',
    active: Number(data.purchaseState) === 0,
  };
}

async function googleGet(url: string, accessToken: string) {
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!response.ok) throw new Error(`GOOGLE_STATUS_${response.status}`);
  return await response.json();
}

async function googleAccessToken(): Promise<string> {
  const account = JSON.parse(requiredEnv('GOOGLE_SERVICE_ACCOUNT_JSON'));
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claim = base64Url(
    JSON.stringify({
      iss: account.client_email,
      scope: 'https://www.googleapis.com/auth/androidpublisher',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  );
  const signingInput = `${header}.${claim}`;
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToBytes(account.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(signingInput),
  );
  const assertion = `${signingInput}.${bytesToBase64Url(new Uint8Array(signature))}`;
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!response.ok) throw new Error('GOOGLE_OAUTH_FAILED');
  const data = await response.json();
  return data.access_token;
}

function pemToBytes(pem: string): ArrayBuffer {
  const base64 = pem.replace(/-----[^-]+-----|\s/g, '');
  return Uint8Array.from(atob(base64), (character) =>
    character.charCodeAt(0)
  ).buffer;
}

function base64Url(value: string): string {
  return bytesToBase64Url(new TextEncoder().encode(value));
}

function bytesToBase64Url(bytes: Uint8Array): string {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`MISSING_${name}`);
  return value;
}

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
