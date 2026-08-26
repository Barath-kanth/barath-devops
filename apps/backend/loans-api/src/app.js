import cors from "cors";
import express from "express";
import morgan from "morgan";
import { createLoan, listLoans, returnLoan } from "./store.js";

const catalogBaseUrl = process.env.CATALOG_API_URL || "http://localhost:3001";

async function fetchBook(bookId) {
  const res = await fetch(`${catalogBaseUrl}/api/catalog/books/${bookId}`);
  if (res.status === 404) return null;
  if (!res.ok) {
    throw new Error(`catalog-api error: ${res.status}`);
  }
  return res.json();
}

async function setAvailability(bookId, available) {
  const res = await fetch(`${catalogBaseUrl}/api/catalog/books/${bookId}/availability`, {
    method: "PATCH",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ available }),
  });
  if (!res.ok) {
    throw new Error(`failed to update availability: ${res.status}`);
  }
  return res.json();
}

export function createApp() {
  const app = express();

  app.use(morgan("combined"));
  app.use(cors());
  app.use(express.json());

  // Probe endpoints with distinct roles (avoid one /healthz for all three probes)
  app.get("/livez", (_req, res) => {
    res.status(200).json({ status: "alive", service: "loans-api" });
  });

  app.get("/readyz", async (_req, res) => {
    try {
      const upstream = await fetch(`${catalogBaseUrl}/livez`);
      if (!upstream.ok) {
        return res.status(503).json({ status: "not-ready", reason: "catalog unavailable" });
      }
      return res.status(200).json({ status: "ready", service: "loans-api" });
    } catch {
      return res.status(503).json({ status: "not-ready", reason: "catalog unreachable" });
    }
  });

  app.get("/startupz", (_req, res) => {
    res.status(200).json({ status: "started", service: "loans-api" });
  });

  app.get("/api/loans", (_req, res) => {
    res.json({ items: listLoans(), count: listLoans().length });
  });

  app.post("/api/loans", async (req, res) => {
    try {
      const { bookId, borrower } = req.body || {};
      if (!bookId || !borrower) {
        return res.status(400).json({ error: "bookId and borrower are required" });
      }

      const book = await fetchBook(bookId);
      if (!book) {
        return res.status(404).json({ error: "Book not found in catalog" });
      }
      if (!book.available) {
        return res.status(409).json({ error: "Book is not available" });
      }

      await setAvailability(bookId, false);
      const loan = createLoan({ bookId, borrower });
      return res.status(201).json({ loan, book: { ...book, available: false } });
    } catch (err) {
      console.error(err);
      return res.status(502).json({ error: "Upstream catalog failure", detail: String(err.message) });
    }
  });

  app.post("/api/loans/:id/return", async (req, res) => {
    try {
      const loan = returnLoan(req.params.id);
      if (!loan) {
        return res.status(404).json({ error: "Loan not found" });
      }
      if (loan.status === "returned" && loan.returnedAt) {
        await setAvailability(loan.bookId, true);
      }
      return res.json(loan);
    } catch (err) {
      console.error(err);
      return res.status(502).json({ error: "Upstream catalog failure", detail: String(err.message) });
    }
  });

  return app;
}
