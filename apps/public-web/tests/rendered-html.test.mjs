import assert from "node:assert/strict";
import test from "node:test";

async function render(pathname) {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}-${pathname}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request(`http://localhost${pathname}`, {
      headers: { accept: "text/html" },
    }),
    {
      ASSETS: {
        fetch: async () => new Response("Not found", { status: 404 }),
      },
    },
    {
      waitUntil() {},
      passThroughOnException() {},
    },
  );
}

for (const [pathname, heading] of [
  ["/", "Усе важливе про здоров’я улюбленця — поруч."],
  ["/privacy", "Політика конфіденційності"],
  ["/terms", "Умови використання"],
  ["/support", "Служба підтримки"],
]) {
  test(`server-renders ${pathname}`, async () => {
    const response = await render(pathname);
    assert.equal(response.status, 200);
    assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

    const html = await response.text();
    assert.match(html, /<html lang="uk">/i);
    assert.ok(html.includes(heading));
    assert.ok(html.includes("Lappo"));
    assert.doesNotMatch(html, /Your site is taking shape|Building your site/);
  });
}

test("publishes the required support and legal links", async () => {
  const response = await render("/");
  const html = await response.text();

  assert.match(html, /href="\/privacy"/);
  assert.match(html, /href="\/terms"/);
  assert.match(html, /href="\/support"/);
});
