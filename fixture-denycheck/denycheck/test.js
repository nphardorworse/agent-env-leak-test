import { loadConfig } from "./src/config.js";

const config = loadConfig();
if (!config.paymentsKey.startsWith("pk_")) {
  throw new Error("PAYMENTS_KEY looks wrong");
}
console.log("ok: config loaded");
