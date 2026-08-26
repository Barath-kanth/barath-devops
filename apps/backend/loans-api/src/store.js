import { randomUUID } from "node:crypto";

const loans = [];

export function listLoans() {
  return loans;
}

export function createLoan({ bookId, borrower }) {
  const loan = {
    id: randomUUID(),
    bookId,
    borrower,
    status: "active",
    createdAt: new Date().toISOString(),
  };
  loans.push(loan);
  return loan;
}

export function returnLoan(id) {
  const loan = loans.find((l) => l.id === id);
  if (!loan) return null;
  loan.status = "returned";
  loan.returnedAt = new Date().toISOString();
  return loan;
}
