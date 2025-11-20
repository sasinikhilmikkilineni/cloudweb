// ESM importer: upserts and always writes importedAt so you'll see a change count
import { MongoClient } from "mongodb";
import fs from "fs";

const file = process.argv[2] || "products.json";
const uri = process.env.MONGO_URI;
if (!uri) { console.error("Set MONGO_URI"); process.exit(1); }

const items = JSON.parse(fs.readFileSync(file, "utf8"));
const docs = items.map(p => ({
  ...p,
  price: Number(p.price),
  countInStock: Number(p.countInStock),
  rating: Number(p.rating ?? 0),
  numReviews: Number(p.numReviews ?? 0),
}));

const client = new MongoClient(uri);
try {
  await client.connect();
  const dbName = new URL(uri).pathname.replace("/", "") || "proshop";
  const col = client.db(dbName).collection("products");

  let inserted = 0, modified = 0;
  for (const d of docs) {
    const r = await col.updateOne(
      { name: d.name },
      { $set: { ...d, importedAt: new Date() } }, // forces a write each run
      { upsert: true }
    );
    if (r.upsertedId) inserted++;
    if (r.modifiedCount) modified++;
  }
  console.log(`Done. inserted=${inserted} modified=${modified}`);
} catch (e) {
  console.error(e);
  process.exit(1);
} finally {
  await client.close();
}
