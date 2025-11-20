const express = require('express');
const app = express();
const PORT = process.env.PORT || 5000;
app.get('/', (req,res)=>res.send('OK'));
app.get('/api/health', (req,res)=>res.send('OK'));
app.get('/api/products', (req,res)=>res.json([
  { _id:"1", name:"Sample Product 1", price:19.99, countInStock:10 },
  { _id:"2", name:"Sample Product 2", price:29.99, countInStock:5  }
]));
app.listen(PORT,'0.0.0.0',()=>console.log(`Mock API on :${PORT}`));
