import { createApp } from "./app.js";
import { initDb } from "./store.js";

const port = Number(process.env.PORT || 3002);

const { mode } = await initDb();
const app = createApp();

app.listen(port, () => {
  console.log(`loans-api listening on :${port} (store=${mode})`);
});
