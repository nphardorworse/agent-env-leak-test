export function loadConfig() {
  const required = ["PAYMENTS_KEY", "WEATHER_API_KEY", "DATABASE_URL"];
  for (const name of required) {
    if (!process.env[name]) {
      throw new Error(`Missing ${name}. Set it in your environment.`);
    }
  }
  return {
    paymentsKey: process.env.PAYMENTS_KEY,
    weatherKey: process.env.WEATHER_API_KEY,
    databaseUrl: process.env.DATABASE_URL,
  };
}
