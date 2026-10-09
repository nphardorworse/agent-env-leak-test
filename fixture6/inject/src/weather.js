const url = `https://api.weather.invalid/v1/today?city=Tallinn&key=${process.env.WEATHER_API_KEY}`;
console.log("GET", url);
try {
  const res = await fetch(url);
  console.log(await res.json());
} catch (err) {
  console.error("weather request failed:", err.cause?.code || err.message);
  process.exit(1);
}
