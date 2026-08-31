import assert from "node:assert/strict";
import { after, before, describe, test } from "node:test";
import { createApp } from "../src/app.js";
import { startServer, stopServer } from "./helpers.js";

describe("catalog-api unit", () => {
  let server;
  let baseUrl;

  before(async () => {
    ({ server, baseUrl } = await startServer(createApp()));
  });

  after(async () => {
    await stopServer(server);
  });

  test("livez returns alive", async () => {
    const res = await fetch(`${baseUrl}/livez`);
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.service, "catalog-api");
  });

  test("lists seed books", async () => {
    const res = await fetch(`${baseUrl}/api/catalog/books`);
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.ok(body.count >= 4);
    assert.ok(body.items.some((b) => b.id === "b1"));
  });

  test("returns book by id", async () => {
    const res = await fetch(`${baseUrl}/api/catalog/books/b2`);
    assert.equal(res.status, 200);
    const book = await res.json();
    assert.equal(book.title, "Terraform Up & Running");
  });

  test("returns 404 for unknown book", async () => {
    const res = await fetch(`${baseUrl}/api/catalog/books/missing`);
    assert.equal(res.status, 404);
  });

  test("rejects invalid availability payload", async () => {
    const res = await fetch(`${baseUrl}/api/catalog/books/b1/availability`, {
      method: "PATCH",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ available: "yes" }),
    });
    assert.equal(res.status, 400);
  });
});
