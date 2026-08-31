import assert from "node:assert/strict";
import { after, before, describe, test } from "node:test";
import { createApp } from "../src/app.js";
import { startServer, stopServer } from "./helpers.js";

describe("loans-api unit", () => {
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
    assert.equal(body.service, "loans-api");
  });

  test("lists loans (empty in memory)", async () => {
    const res = await fetch(`${baseUrl}/api/loans`);
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.ok(Array.isArray(body.items));
  });

  test("rejects loan without borrower", async () => {
    const res = await fetch(`${baseUrl}/api/loans`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ bookId: "b1" }),
    });
    assert.equal(res.status, 400);
  });
});
