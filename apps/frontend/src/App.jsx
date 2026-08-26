import { useEffect, useState } from "react";

const catalogBase = import.meta.env.VITE_CATALOG_API_URL || "";
const loansBase = import.meta.env.VITE_LOANS_API_URL || "";

async function getJson(url, options) {
  const res = await fetch(url, options);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(data.error || `Request failed (${res.status})`);
  }
  return data;
}

export default function App() {
  const [books, setBooks] = useState([]);
  const [loans, setLoans] = useState([]);
  const [borrower, setBorrower] = useState("alex");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  async function refresh() {
    setLoading(true);
    setError("");
    try {
      const [catalog, loanList] = await Promise.all([
        getJson(`${catalogBase}/api/catalog/books`),
        getJson(`${loansBase}/api/loans`),
      ]);
      setBooks(catalog.items || []);
      setLoans(loanList.items || []);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refresh();
  }, []);

  async function borrow(bookId) {
    setError("");
    try {
      await getJson(`${loansBase}/api/loans`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ bookId, borrower }),
      });
      await refresh();
    } catch (err) {
      setError(err.message);
    }
  }

  async function giveBack(loanId) {
    setError("");
    try {
      await getJson(`${loansBase}/api/loans/${loanId}/return`, { method: "POST" });
      await refresh();
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <div className="page">
      <header>
        <p className="eyebrow">Enterprise demo</p>
        <h1>BookShelf</h1>
        <p className="lede">SPA talking to two Kubernetes-bound APIs (catalog + loans).</p>
      </header>

      <section className="panel">
        <label>
          Borrower name
          <input value={borrower} onChange={(e) => setBorrower(e.target.value)} />
        </label>
        <button type="button" onClick={refresh} disabled={loading}>
          Refresh
        </button>
      </section>

      {error ? <p className="error">{error}</p> : null}
      {loading ? <p>Loading…</p> : null}

      <section>
        <h2>Catalog</h2>
        <ul className="cards">
          {books.map((book) => (
            <li key={book.id}>
              <strong>{book.title}</strong>
              <span>{book.author}</span>
              <span className={book.available ? "ok" : "no"}>
                {book.available ? "Available" : "On loan"}
              </span>
              <button type="button" disabled={!book.available} onClick={() => borrow(book.id)}>
                Borrow
              </button>
            </li>
          ))}
        </ul>
      </section>

      <section>
        <h2>Loans</h2>
        <ul className="cards">
          {loans.length === 0 ? <li>No loans yet.</li> : null}
          {loans.map((loan) => (
            <li key={loan.id}>
              <strong>{loan.bookId}</strong>
              <span>{loan.borrower}</span>
              <span>{loan.status}</span>
              {loan.status === "active" ? (
                <button type="button" onClick={() => giveBack(loan.id)}>
                  Return
                </button>
              ) : null}
            </li>
          ))}
        </ul>
      </section>
    </div>
  );
}
