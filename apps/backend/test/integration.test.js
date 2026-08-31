import assert from "node:assert/strict";
import { after, before, describe, test } from "node:test";
import { createApp as createCatalogApp } from "../catalog-api/src/app.js";
import { startServer, stopServer } from "../catalog-api/test/helpers.js";

describe("catalog + loans integration", () => {
  let catalogServer;
  let loansServer;
  let catalogUrl;
  let loansUrl;

  before(async () => {
    ({ server: catalogServer, baseUrl: catalogUrl } = await startServer(createCatalogApp()));

    process.env.CATALOG_API_URL = catalogUrl;
    const { createApp: createLoansApp } = await import("../loans-api/src/app.js");
    ({ server: loansServer, baseUrl: loansUrl } = await startServer(createLoansApp()));
  });

  after(async () => {
    delete process.env.CATALOG_API_URL;
    await stopServer(loansServer);
    await stopServer(catalogServer);
  });

  test("loans readyz sees catalog", async () => {
    const res = await fetch(`${loansUrl}/readyz`);
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.status, "ready");
  });

  test("loan flow reserves and returns a book", async () => {
    const createRes = await fetch(`${loansUrl}/api/loans`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ bookId: "b4", borrower: "integration-test" }),
    });
    assert.equal(createRes.status, 201);
    const created = await createRes.json();
    assert.equal(created.book.available, false);

    const bookRes = await fetch(`${catalogUrl}/api/catalog/books/b4`);
    const book = await bookRes.json();
    assert.equal(book.available, false);

    const returnRes = await fetch(`${loansUrl}/api/loans/${created.loan.id}/return`, {
      method: "POST",
    });
    assert.equal(returnRes.status, 200);

    const bookAfter = await fetch(`${catalogUrl}/api/catalog/books/b4`);
    assert.equal((await bookAfter.json()).available, true);
  });
});
