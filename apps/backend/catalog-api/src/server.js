import { createApp } from "./app.js";
import { initDb } from "./db.js";

const port = Number(process.env.PORT || 3001);

const { mode } = await initDb();
const app = createApp();

app.listen(port, () => {
  console.log(`catalog-api listening on :${port} (store=${mode})`);
});
