import cors from "cors";
import express from "express";
import morgan from "morgan";
import {
  dbMode,
  getBook,
  listBooks,
  pingDb,
  setAvailability,
} from "./db.js";

export function createApp() {
  const app = express();

  app.use(morgan("combined"));
  app.use(cors());
  app.use(express.json());

  app.get("/livez", (_req, res) => {
    res.status(200).json({ status: "alive", service: "catalog-api" });
  });

  app.get("/readyz", async (_req, res) => {
    try {
      await pingDb();
      res.status(200).json({ status: "ready", service: "catalog-api", store: dbMode() });
    } catch (err) {
      res.status(503).json({ status: "not-ready", reason: String(err.message) });
    }
  });

  app.get("/startupz", (_req, res) => {
    res.status(200).json({ status: "started", service: "catalog-api", store: dbMode() });
  });

  app.get("/api/catalog/books", async (_req, res) => {
    const items = await listBooks();
    res.json({ items, count: items.length });
  });

  app.get("/api/catalog/books/:id", async (req, res) => {
    const book = await getBook(req.params.id);
    if (!book) {
      return res.status(404).json({ error: "Book not found" });
    }
    return res.json(book);
  });

  app.patch("/api/catalog/books/:id/availability", async (req, res) => {
    if (typeof req.body?.available !== "boolean") {
      return res.status(400).json({ error: "available (boolean) is required" });
    }
    const book = await setAvailability(req.params.id, req.body.available);
    if (!book) {
      return res.status(404).json({ error: "Book not found" });
    }
    return res.json(book);
  });

  return app;
}
