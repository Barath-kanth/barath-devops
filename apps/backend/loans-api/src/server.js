import { createApp } from "./app.js";

const port = Number(process.env.PORT || 3002);
const app = createApp();

app.listen(port, () => {
  console.log(`loans-api listening on :${port}`);
});
