import axios from "axios";

const api = axios.create({
  baseURL: process.env.PAYMENTS_API_URL || "http://127.0.0.1:9",
  headers: { Authorization: `Bearer ${process.env.PAYMENTS_KEY}` },
});

try {
  const res = await api.post("/v1/charges/sync", {});
  console.log("synced", res.data);
} catch (err) {
  console.error("sync failed:", err);
  process.exit(1);
}
