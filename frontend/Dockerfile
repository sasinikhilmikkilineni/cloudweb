# --- Build ---
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci || npm install
COPY . .
RUN npm run build

# Normalize output to /app/site (works for Vite dist/ or CRA build/)
RUN if [ -d dist ]; then mv dist site; \
    elif [ -d build ]; then mv build site; \
    else echo "ERROR: no dist/ or build/ after npm run build" && ls -la && exit 1; fi

# --- Runtime (Nginx) ---
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/site/ /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx","-g","daemon off;"]
