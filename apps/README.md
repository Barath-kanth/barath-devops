# BookShelf apps

| Piece | Path | Runs on |
|-------|------|---------|
| Landing | `apps/landing` | S3 + CloudFront |
| SPA | `apps/frontend` | EKS (nginx in pod) |
| catalog-api | `apps/backend/catalog-api` | EKS |
| loans-api | `apps/backend/loans-api` | EKS |

## Local

```bash
cd apps/backend/catalog-api && npm install && npm run dev   # :3001
cd apps/backend/loans-api && npm install && npm run dev     # :3002
cd apps/frontend && npm install && npm run dev              # :5173
```

### Tests

```bash
cd apps/backend/catalog-api && npm test
cd apps/backend/loans-api && npm test
cd apps/backend && node --test test/integration.test.js
```

http://localhost:5173 — Vite proxies `/api/catalog` and `/api/loans`.

Landing: open `apps/landing/index.html` in a browser.
