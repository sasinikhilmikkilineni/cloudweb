// backend/tools/fixImages.js
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Product from '../models/productModel.js';

dotenv.config();

const slugify = (s) =>
  s.toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')   // non-alphanum -> dash
    .replace(/^-+|-+$/g, '')       // trim dashes
    .slice(0, 40);                  // keep it short

const run = async () => {
  try {
    if (!process.env.MONGO_URI) {
      throw new Error('MONGO_URI missing in .env');
    }
    await mongoose.connect(process.env.MONGO_URI);
    const products = await Product.find({});
    for (const p of products) {
      // only rewrite if external image is missing or from Unsplash/local
      if (!p.image || p.image.startsWith('/images/') || p.image.includes('source.unsplash.com')) {
        const seed = slugify(p.name || 'product');
        p.image = `https://picsum.photos/seed/${seed}/800/600`;
        await p.save();
        console.log('Updated:', p.name, '->', p.image);
      }
    }
    console.log('Done.');
    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
};

run();
