import pg from "pg";

const { Pool } = pg;

let pool = null;
let mode = "memory";

export function dbMode() {
  return mode;
}

export function getPool() {
  return pool;
}

/** Build pool from DATABASE_URL or PG* env vars (Secrets Manager / External Secrets). */
export async function initDb() {
  const url = process.env.DATABASE_URL;
  const host = process.env.PGHOST || process.env.DB_HOST;
  if (!url && !host) {
    mode = "memory";
    console.warn("catalog-api: no DATABASE_URL/PGHOST — using in-memory store");
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
    create table if not exists books (
      id text primary key,
      title text not null,
      author text not null,
      available boolean not null default true
    )
  `);

  const { rows } = await pool.query("select count(*)::int as n from books");
  if (rows[0].n === 0) {
    await pool.query(
      `insert into books (id, title, author, available) values
        ('b1', 'Kubernetes in Action', 'Marko Lukša', true),
        ('b2', 'Terraform Up & Running', 'Yevgeniy Brikman', true),
        ('b3', 'Designing Data-Intensive Applications', 'Martin Kleppmann', false),
        ('b4', 'The Phoenix Project', 'Gene Kim', true)`
    );
  }

  mode = "postgres";
  console.log("catalog-api: connected to PostgreSQL");
  return { mode };
}

export async function listBooks() {
  if (mode === "memory") {
    const { books } = await import("./data.js");
    return books;
  }
  const { rows } = await pool.query(
    "select id, title, author, available from books order by id"
  );
  return rows;
}

export async function getBook(id) {
  if (mode === "memory") {
    const { books } = await import("./data.js");
    return books.find((b) => b.id === id) || null;
  }
  const { rows } = await pool.query(
    "select id, title, author, available from books where id = $1",
    [id]
  );
  return rows[0] || null;
}

export async function setAvailability(id, available) {
  if (mode === "memory") {
    const { books } = await import("./data.js");
    const book = books.find((b) => b.id === id);
    if (!book) return null;
    book.available = available;
    return book;
  }
  const { rows } = await pool.query(
    `update books set available = $2 where id = $1
     returning id, title, author, available`,
    [id, available]
  );
  return rows[0] || null;
}

export async function pingDb() {
  if (mode !== "postgres") return true;
  await pool.query("select 1");
  return true;
}
