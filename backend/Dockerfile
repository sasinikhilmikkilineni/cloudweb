FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev

FROM node:18-alpine
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=8080
RUN apk add --no-cache ca-certificates && update-ca-certificates
COPY --from=deps /app/node_modules ./node_modules
COPY . .
EXPOSE 8080
CMD ["node","server.js"]
