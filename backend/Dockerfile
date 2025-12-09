FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install --production

COPY . .

ENV NODE_ENV=production
ENV PORT=8000
ENV MONGO_URI=mongodb+srv://sasinikhilmikkilineni:JEmaXajfuFiiOnVg@cluster0.rvactvu.mongodb.net/proshop
ENV JWT_SECRET=supersecret_change_me
ENV PAYPAL_CLIENT_ID=AfeI0t5-I4nrBCBl7-s6jD6vC8vRW0b7-dKsO0LG5NwHv5kFJCKeDqmGxT7iJPJF0Ff2gVf04UM0q3Tg

EXPOSE 8000

CMD ["node", "server.js"]
