import pg from "pg";
import { randomUUID } from "node:crypto";

const { Pool } = pg;

let pool = null;
let mode = "memory";
const memoryLoans = [];

export function dbMode() {
  return mode;
}

export async function initDb() {
  const url = process.env.DATABASE_URL;
  const host = process.env.PGHOST || process.env.DB_HOST;
  if (!url && !host) {
    mode = "memory";
    console.warn("loans-api: no DATABASE_URL/PGHOST — using in-memory store");
    return { mode };
  }

  pool = url
    ? new Pool({ connectionString: url, max: 5, idleTimeoutMillis: 10_000 })
    : new Pool({
        host,
        port: Number(process.env.PGPORT || process.env.DB_PORT || 5432),
        user: process.env.PGUSER || process.env.DB_USER,
        password: process.env.PGPASSWORD || process.env.DB_PASSWORD,
        database: process.env.PGDATABASE || process.env.DB_NAME || "appdb",
        ssl: process.env.PGSSLMODE === "require" ? { rejectUnauthorized: false } : undefined,
        max: 5,
        idleTimeoutMillis: 10_000,
      });

  await pool.query("select 1");
  await pool.query(`
    create table if not exists loans (
      id text primary key,
      book_id text not null,
      borrower text not null,
      status text not null,
      created_at timestamptz not null default now(),
      returned_at timestamptz
    )
  `);

  mode = "postgres";
  console.log("loans-api: connected to PostgreSQL");
  return { mode };
}

export async function listLoans() {
  if (mode === "memory") return memoryLoans;
  const { rows } = await pool.query(
    `select id, book_id as "bookId", borrower, status,
            created_at as "createdAt", returned_at as "returnedAt"
     from loans order by created_at desc`
  );
  return rows;
}

export async function createLoan({ bookId, borrower }) {
  const loan = {
    id: randomUUID(),
    bookId,
    borrower,
    status: "active",
    createdAt: new Date().toISOString(),
  };
  if (mode === "memory") {
    memoryLoans.push(loan);
    return loan;
  }
  await pool.query(
    `insert into loans (id, book_id, borrower, status, created_at)
     values ($1, $2, $3, $4, $5)`,
    [loan.id, loan.bookId, loan.borrower, loan.status, loan.createdAt]
  );
  return loan;
}

export async function returnLoan(id) {
  if (mode === "memory") {
    const loan = memoryLoans.find((l) => l.id === id);
    if (!loan) return null;
    loan.status = "returned";
    loan.returnedAt = new Date().toISOString();
    return loan;
  }
  const { rows } = await pool.query(
    `update loans set status = 'returned', returned_at = now()
     where id = $1
     returning id, book_id as "bookId", borrower, status,
               created_at as "createdAt", returned_at as "returnedAt"`,
    [id]
  );
  return rows[0] || null;
}

export async function pingDb() {
  if (mode !== "postgres") return true;
  await pool.query("select 1");
  return true;
}
