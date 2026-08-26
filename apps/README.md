# BookShelf apps

Assignment layout:

| Piece | Path | Where it runs |
|-------|------|----------------|
| Static landing | `apps/landing` | **Outside cluster** — S3 + CloudFront (caching / CDN) |
| SPA | `apps/frontend` | Can sit on S3/CloudFront or later behind the gateway |
| Backend 1 | `apps/backend/catalog-api` | EKS |
| Backend 2 | `apps/backend/loans-api` | EKS (calls catalog) |

## Local run

```bash
# terminals
cd apps/backend/catalog-api && npm install && npm run dev   # :3001
cd apps/backend/loans-api && npm install && npm run dev     # :3002
cd apps/frontend && npm install && npm run dev              # :5173
```

Open http://localhost:5173 — Vite proxies `/api/catalog` → 3001 and `/api/loans` → 3002.

Landing page (static): open `apps/landing/index.html` or sync that folder to the S3 bucket CloudFront fronts.
