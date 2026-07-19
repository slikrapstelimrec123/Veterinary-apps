import assert from "node:assert/strict";
import test from "node:test";

async function render(path = "/") {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);
  return worker.fetch(
    new Request(`http://localhost${path}`, {
      headers: { accept: "text/html" },
    }),
    { ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) } },
    { waitUntil() {}, passThroughOnException() {} },
  );
}

test("renders the protected Lappo admin shell", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  const html = await response.text();
  assert.match(html, /Lappo/);
  assert.match(html, /Панель керування/);
  assert.match(html, /noindex/);
  assert.doesNotMatch(html, /Your site is taking shape/);
});

test("ignores the private Sites token and uses password authentication only", async () => {
  const source = await import("node:fs/promises").then(({ readFile }) =>
    readFile(new URL("../app/page.tsx", import.meta.url), "utf8"),
  );
  assert.match(source, /detectSessionInUrl:\s*false/);
  assert.match(source, /flowType:\s*"pkce"/);
  assert.doesNotMatch(source, /signInWithOAuth/);
  assert.doesNotMatch(source, /Увійти через Google/);
});

test("supports password recovery without exposing the Sites token", async () => {
  const source = await import("node:fs/promises").then(({ readFile }) =>
    readFile(new URL("../app/page.tsx", import.meta.url), "utf8"),
  );
  assert.match(source, /resetPasswordForEmail/);
  assert.match(source, /exchangeCodeForSession/);
  assert.match(source, /updateUser/);
  assert.match(source, /Забули пароль\?/);
});
