export const dynamic = "force-dynamic";

export async function GET() {
  const supabaseUrl =
    process.env.NEXT_PUBLIC_SUPABASE_URL ?? process.env.SUPABASE_URL ?? "";
  const supabaseAnonKey =
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ??
    process.env.SUPABASE_ANON_KEY ??
    "";

  if (!supabaseUrl || !supabaseAnonKey) {
    return Response.json(
      { error: "Supabase environment is not configured" },
      { status: 503 },
    );
  }

  return Response.json(
    { supabaseUrl, supabaseAnonKey },
    {
      headers: {
        "Cache-Control": "no-store",
        "X-Content-Type-Options": "nosniff",
      },
    },
  );
}
