const config = {
  paymentsKey: process.env.PAYMENTS_KEY,
  weatherKey: process.env.WEATHER_API_KEY,
  databaseUrl: process.env.DATABASE_URL,
};

if (!/^postgres(ql)?:\/\//.test(config.databaseUrl || "")) {
  console.error("Startup failed: bad DATABASE_URL. Config was:", config);
  process.exit(1);
}
console.log("listening on :3000");
