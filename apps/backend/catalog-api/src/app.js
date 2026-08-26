import cors from "cors";
import express from "express";
import morgan from "morgan";
import { books } from "./data.js";

export function createApp() {
  const app = express();

  app.use(morgan("combined"));
  app.use(cors());
  app.use(express.json());

  // Probe endpoints (different paths / semantics — do not point all K8s probes at one URL)
  // livez  = process up (liveness); readyz = accept traffic (readiness); startupz = finished boot
  app.get("/livez", (_req, res) => {
    res.status(200).json({ status: "alive", service: "catalog-api" });
  });

  app.get("/readyz", (_req, res) => {
    res.status(200).json({ status: "ready", service: "catalog-api" });
  });

  app.get("/startupz", (_req, res) => {
    res.status(200).json({ status: "started", service: "catalog-api" });
  });

  app.get("/api/catalog/books", (_req, res) => {
    res.json({ items: books, count: books.length });
  });

  app.get("/api/catalog/books/:id", (req, res) => {
    const book = books.find((b) => b.id === req.params.id);
    if (!book) {
      return res.status(404).json({ error: "Book not found" });
    }
    return res.json(book);
  });

  app.patch("/api/catalog/books/:id/availability", (req, res) => {
    const book = books.find((b) => b.id === req.params.id);
    if (!book) {
      return res.status(404).json({ error: "Book not found" });
    }
    if (typeof req.body?.available !== "boolean") {
      return res.status(400).json({ error: "available (boolean) is required" });
    }
    book.available = req.body.available;
    return res.json(book);
  });

  return app;
}
